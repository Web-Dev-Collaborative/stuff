package fixtures

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path"
	"path/filepath"
	"reflect"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/joho/godotenv"
	"github.com/spf13/afero"
	"github.com/thedevsaddam/gojsonq"

	"github.com/stripe/stripe-cli/pkg/ansi"
	"github.com/stripe/stripe-cli/pkg/requests"
)

// SupportedVersions is the version number of the fixture template the CLI supports
const SupportedVersions = 0

type metaFixture struct {
	Version         int  `json:"template_version"`
	ExcludeMetadata bool `json:"exclude_metadata"`
}

type fixtureFile struct {
	Meta     metaFixture       `json:"_meta"`
	Fixtures []fixture         `json:"fixtures"`
	Env      map[string]string `json:"env"`
}

type fixture struct {
	Name              string      `json:"name"`
	ExpectedErrorType string      `json:"expected_error_type"`
	Path              string      `json:"path"`
	Method            string      `json:"method"`
	Params            interface{} `json:"params"`
}

type fixtureQuery struct {
	Match        string // The substring that matched the query pattern regex
	Name         string
	Query        string
	DefaultValue string
}

// Fixture contains a mapping of an individual fixtures responses for querying
type Fixture struct {
	Fs            afero.Fs
	APIKey        string
	StripeAccount string
	BaseURL       string
	responses     map[string]*gojsonq.JSONQ
	fixture       fixtureFile
}

// NewFixture creates a to later run steps for populating test data
func NewFixture(fs afero.Fs, apiKey, stripeAccount, baseURL, file string) (*Fixture, error) {
	fxt := Fixture{
		Fs:            fs,
		APIKey:        apiKey,
		StripeAccount: stripeAccount,
		BaseURL:       baseURL,
		responses:     make(map[string]*gojsonq.JSONQ),
	}

	var filedata []byte

	var err error

	if _, ok := reverseMap()[file]; ok {
		f, err := triggers.Open(file)
		if err != nil {
			return nil, err
		}

		filedata, err = ioutil.ReadAll(f)
		if err != nil {
			return nil, err
		}
	} else {
		filedata, err = afero.ReadFile(fxt.Fs, file)
		if err != nil {
			return nil, err
		}
	}

	err = json.Unmarshal(filedata, &fxt.fixture)
	if err != nil {
		return nil, err
	}

	if fxt.fixture.Meta.Version > SupportedVersions {
		return nil, fmt.Errorf("Fixture version not supported: %s", fmt.Sprint(fxt.fixture.Meta.Version))
	}

	return &fxt, nil
}

// Execute takes the parsed fixture file and runs through all the requests
// defined to populate the user's account
func (fxt *Fixture) Execute() ([]string, error) {
	requestNames := make([]string, len(fxt.fixture.Fixtures))
	for i, data := range fxt.fixture.Fixtures {
		fmt.Printf("Setting up fixture for: %s\n", data.Name)
		requestNames[i] = data.Name

		resp, err := fxt.makeRequest(data)
		if err != nil && !errWasExpected(err, data.ExpectedErrorType) {
			return nil, err
		}

		fxt.responses[data.Name] = gojsonq.New().FromString(string(resp))
	}

	return requestNames, nil
}

func errWasExpected(err error, expectedErrorType string) bool {
	if rerr, ok := err.(requests.RequestError); ok {
		return rerr.ErrorType == expectedErrorType
	}
	return false
}

// UpdateEnv uses the results of the fixtures command just executed and
// updates a local .env with the resulting data
func (fxt *Fixture) UpdateEnv() error {
	if len(fxt.fixture.Env) > 0 {
		return fxt.updateEnv(fxt.fixture.Env)
	}

	return nil
}

func (fxt *Fixture) makeRequest(data fixture) ([]byte, error) {
	var rp requests.RequestParameters

	if data.Method == "post" && !fxt.fixture.Meta.ExcludeMetadata {
		now := time.Now().String()
		metadata := fmt.Sprintf("metadata[_created_by_fixture]=%s", now)
		rp.AppendData([]string{metadata})
	}

	req := requests.Base{
		Method:         strings.ToUpper(data.Method),
		SuppressOutput: true,
		APIBaseURL:     fxt.BaseURL,
		Parameters:     rp,
	}

	path, err := fxt.parsePath(data)

	if err != nil {
		return make([]byte, 0), err
	}

	params, err := fxt.createParams(data.Params)

	if err != nil {
		return make([]byte, 0), err
	}

	return req.MakeRequest(fxt.APIKey, path, params, true)
}

func (fxt *Fixture) parsePath(http fixture) (string, error) {
	if r, containsQuery := matchFixtureQuery(http.Path); containsQuery {
		var newPath []string

		matches := r.FindAllStringSubmatch(http.Path, -1)
		pathParts := r.Split(http.Path, -1)

		for i, match := range matches {
			value, err := fxt.parseQuery(match[0])

			if err != nil {
				return "", err
			}

			newPath = append(newPath, pathParts[i])
			newPath = append(newPath, value)
		}

		if len(pathParts)%2 == 0 {
			newPath = append(newPath, pathParts[len(pathParts)-1])
		}

		return path.Join(newPath...), nil
	}

	return http.Path, nil
}

func (fxt *Fixture) createParams(params interface{}) (*requests.RequestParameters, error) {
	requestParams := requests.RequestParameters{}
	parsed, err := fxt.parseInterface(params)
	if err != nil {
		return &requestParams, err
	}
	requestParams.AppendData(parsed)

	requestParams.SetStripeAccount(fxt.StripeAccount)

	return &requestParams, nil
}

func (fxt *Fixture) parseInterface(params interface{}) ([]string, error) {
	var data []string

	var cleanData []string

	switch v := reflect.ValueOf(params); v.Kind() {
	case reflect.Map:
		m := params.(map[string]interface{})
		parsed, err := fxt.parseMap(m, "", -1)
		if err != nil {
			return make([]string, 0), err
		}
		data = append(data, parsed...)
	case reflect.Array:
		a := params.([]interface{})
		parsed, err := fxt.parseArray(a, "")
		if err != nil {
			return make([]string, 0), err
		}
		data = append(data, parsed...)
	default:
	}

	for _, d := range data {
		if strings.TrimSpace(d) != "" {
			cleanData = append(cleanData, strings.TrimSpace(d))
		}
	}

	return cleanData, nil
}

func (fxt *Fixture) parseMap(params map[string]interface{}, parent string, index int) ([]string, error) {
	data := make([]string, len(params))

	var keyname string

	for key, value := range params {
		switch {
		case parent != "" && index >= 0:
			// ex: lines[0][id] = "id_0000", lines[1][id] = "id_1234", etc.
			keyname = fmt.Sprintf("%s[%d][%s]", parent, index, key)
		case parent != "":
			// ex: metadata[name] = "blah", metadata[timestamp] = 1231341525, etc.
			keyname = fmt.Sprintf("%s[%s]", parent, key)
		default:
			keyname = key
		}

		switch v := reflect.ValueOf(value); v.Kind() {
		case reflect.String:
			// A string can be a regular value or one we need to look up first, ex: ${product.id}
			parsed, err := fxt.parseQuery(v.String())
			if err != nil {
				return make([]string, 0), err
			}
			data = append(data, fmt.Sprintf("%s=%s", keyname, parsed))
		case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
			data = append(data, fmt.Sprintf("%s=%v", keyname, v.Int()))
		case reflect.Float32, reflect.Float64:
			/*
				When converting fixture values to JSON, numeric values
				reflect as float types. Thus in order to output the correct
				value we should parse as such:

				10 => 10
				3.145 => 3.145
				25.00 => 25
				20.10 => 20.1

				In order to preserve decimal places but strip them when
				unnecessary (i.e 1.0), we must use strconv with the special
				precision value of -1.

				We cannot use %v here because it reverts to %g which uses
				%e (scientific notation) for larger values otherwise %f
				(float), which will not strip the decimal places from 4.00
			*/
			s64 := strconv.FormatFloat(v.Float(), 'f', -1, 64)
			data = append(data, fmt.Sprintf("%s=%s", keyname, s64))
		case reflect.Bool:
			data = append(data, fmt.Sprintf("%s=%t", keyname, v.Bool()))
		case reflect.Map:
			m := value.(map[string]interface{})

			result, err := fxt.parseMap(m, keyname, index)

			if err != nil {
				return make([]string, 0), err
			}

			data = append(data, result...)
		case reflect.Array, reflect.Slice:
			a := value.([]interface{})

			result, err := fxt.parseArray(a, keyname)

			if err != nil {
				return make([]string, 0), err
			}

			data = append(data, result...)
		default:
			continue
		}
	}

	return data, nil
}

// This function interates through each element in the array and handles the parsing accordingly depending on the type of array.
func (fxt *Fixture) parseArray(params []interface{}, parent string) ([]string, error) {
	data := make([]string, len(params))
	// The index is only used for arrays of maps
	index := -1
	for _, value := range params {
		switch v := reflect.ValueOf(value); v.Kind() {
		case reflect.String:
			// A string can be a regular value or one we need to look up first, ex: ${product.id}
			parsed, err := fxt.parseQuery(v.String())
			if err != nil {
				return make([]string, 0), err
			}
			data = append(data, fmt.Sprintf("%s[]=%s", parent, parsed))
		case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
			data = append(data, fmt.Sprintf("%s[]=%v", parent, v.Int()))
		case reflect.Map:
			m := value.(map[string]interface{})
			// When we parse arrays of maps, we want to track the index of the element for the request
			// ex: lines[0][id] = "id_0000", lines[1][id] = "id_1234", etc.
			index++
			parsed, err := fxt.parseMap(m, parent, index)
			if err != nil {
				return make([]string, 0), err
			}
			data = append(data, parsed...)
		case reflect.Array, reflect.Slice:
			a := value.([]interface{})
			parsed, err := fxt.parseArray(a, parent)
			if err != nil {
				return make([]string, 0), err
			}
			data = append(data, parsed...)
		default:
			continue
		}
	}

	return data, nil
}

func normalizeForComparison(x string) string {
	r := strings.NewReplacer("_", "", "-", "")
	return r.Replace(strings.ToLower(x))
}

func findSimilarQueryNames(fxt *Fixture, name string) ([]string, bool) {
	keys := make([]string, 0, len(fxt.responses))
	for k := range fxt.responses {
		a := normalizeForComparison(k)
		b := normalizeForComparison(name)
		isSubstr := strings.Contains(a, b) || strings.Contains(b, a)

		if isSubstr && k != name {
			keys = append(keys, k)
		}
	}

	return keys, len(keys) > 0
}

func (fxt *Fixture) parseQuery(queryString string) (string, error) {
	value := queryString

	if query, isQuery := toFixtureQuery(queryString); isQuery {
		name := query.Name

		// Check if there is a default value specified
		if query.DefaultValue != "" {
			value = query.DefaultValue
		}

		// Catch and insert .env values
		if name == ".env" {
			// Check if env variable is present
			envValue, err := getEnvVar(query)
			if err != nil || envValue == "" {
				return value, nil
			}

			// Handle the case where only a substring of the original queryString was a query.
			// Ex: ${.env:BLAH}/blah/blah
			value = strings.ReplaceAll(queryString, query.Match, envValue)
			return value, nil
		}

		if _, ok := fxt.responses[name]; ok {
			// Reset just in case someone else called a query here
			fxt.responses[name].Reset()
		} else {
			// An undeclared fixture name is being referenced
			var errorStrings []string
			color := ansi.Color(os.Stdout)

			referenceError := fmt.Errorf(
				"%s - an undeclared fixture name was referenced: %s",
				color.Red("✘ Validation error").String(),
				ansi.Bold(name),
			).Error()

			errorStrings = append(errorStrings, referenceError)

			if similar, exists := findSimilarQueryNames(fxt, name); exists {
				suggestions := fmt.Errorf(
					"%s: %v",
					ansi.Italic("Perhaps you meant one of the following"),
					strings.Join(similar, ", "),
				).Error()
				errorStrings = append(errorStrings, suggestions)
			}

			return "", fmt.Errorf(strings.Join(errorStrings, "\n"))
		}

		query := query.Query
		findResult, err := fxt.responses[name].FindR(query)
		if err != nil {
			return value, nil
		}
		findResultString, _ := findResult.String()
		return findResultString, nil
	}

	return value, nil
}

func getEnvVar(query fixtureQuery) (string, error) {
	key := query.Query
	// Check if env variable is present
	envValue := os.Getenv(key)
	if envValue == "" {
		// Try to load from .env file
		dir, err := os.Getwd()
		if err != nil {
			dir = ""
		}
		err = godotenv.Load(path.Join(dir, ".env"))
		if err != nil {
			return "", nil
		}
		envValue = os.Getenv(key)
	}
	if envValue == "" {
		fmt.Printf("No value for env var: %s\n", key)
		return "", nil
	}

	return envValue, nil
}

func (fxt *Fixture) updateEnv(env map[string]string) error {
	dir, err := os.Getwd()
	if err != nil {
		return err
	}

	envFile := filepath.Join(dir, ".env")

	exists, _ := afero.Exists(fxt.Fs, envFile)
	if !exists {
		// If there is no .env in the current directory, return and do nothing
		return nil
	}

	file, err := fxt.Fs.Open(envFile)
	if err != nil {
		return err
	}

	dotenv, err := godotenv.Parse(file)
	if err != nil {
		return err
	}

	for key, value := range env {
		parsed, err := fxt.parseQuery(value)
		if err != nil {
			return err
		}

		dotenv[key] = parsed
	}

	content, err := godotenv.Marshal(dotenv)
	if err != nil {
		return err
	}

	afero.WriteFile(fxt.Fs, envFile, []byte(content), os.ModePerm)

	return nil
}

// toFixtureQuery will parse a string into a fixtureQuery struct, additionally
// returning a bool indicating the value did contain a fixtureQuery.
func toFixtureQuery(value string) (fixtureQuery, bool) {
	var query fixtureQuery
	isQuery := false

	if r, didMatch := matchFixtureQuery(value); didMatch {
		isQuery = true
		match := r.FindStringSubmatch(value)
		query = fixtureQuery{Match: match[0], Name: match[1], Query: match[2], DefaultValue: match[3]}
	}

	return query, isQuery
}

// matchQuery will attempt to find matches for a fixture query pattern
// returning a *Regexp which can be used to further parse and a boolean
// indicating a match was found.
func matchFixtureQuery(value string) (*regexp.Regexp, bool) {
	// Queries will start with `${` and end with `}`. The `:` is a
	// separator for `name:json_path`. Additionally, default value will
	// be specified after the `|`.
	// example: ${name:json_path|default_value}
	r := regexp.MustCompile(`\${([^\|}]+):([^\|}]+)\|?([^/\n]+)?}`)
	if r.Match([]byte(value)) {
		return r, true
	}

	return nil, false
}
