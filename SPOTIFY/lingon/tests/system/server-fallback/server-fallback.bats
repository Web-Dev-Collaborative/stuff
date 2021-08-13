# Test Lingon server fallback feature.

# Before each spec
setup() {
  # cd to the server fallback project
  CWD='tests/system/server-fallback'
  cd $CWD
}

@test "server fallback: non existing paths fall back to catchAll file" {
  # Remove existing tmp/
  if [ -d './tmp' ]; then
    rm -r ./tmp 2> /dev/null
  fi

  # Create tmp/
  mkdir ./tmp

  # Start the http server
  LINGON_JOB="./lingon.js server -p 4567"
  eval ${LINGON_JOB} > /dev/null &
  LINGON_JOB_PID=`ps ax | grep -e "${LINGON_JOB}" | grep -v grep | awk '{print $1}'`

  # Wait a while
  sleep 2

  # Get some files
  server="http://localhost:4567"
  download="curl --silent -o"

  ${download} tmp/index.html $server/
  ${download} tmp/index_querystring.html $server/?foo=bar
  ${download} tmp/fallback.html $server/something/that/does/not/exist
  ${download} tmp/fallback_querystring.html $server/something/that/does/not/exist?foo=bar

  # Terminate server
  kill $LINGON_JOB_PID

  # Did we get everything?
  diff tmp/index.html fixtures/default.html
  [ $? -eq 0 ]
  diff tmp/index_querystring.html fixtures/default.html
  [ $? -eq 0 ]

  diff tmp/fallback.html fixtures/catch-all.html
  [ $? -eq 0 ]
  diff tmp/fallback_querystring.html fixtures/catch-all.html
  [ $? -eq 0 ]
}

@test "server fallback: folder paths fall back to directoryIndex file" {
  # Remove existing tmp/
  if [ -d './tmp' ]; then
    rm -r ./tmp 2> /dev/null
  fi

  # Create tmp/
  mkdir ./tmp

  # Start the http server
  LINGON_JOB="./lingon.js server -p 4567"
  eval ${LINGON_JOB} > /dev/null &
  LINGON_JOB_PID=`ps ax | grep -e "${LINGON_JOB}" | grep -v grep | awk '{print $1}'`

  # Wait a while
  sleep 2

  # Get some files
  server="http://localhost:4567"
  download="curl --silent -o"

  ${download} tmp/default.html $server/
  ${download} tmp/default2.html $server/test/

  # Terminate server
  kill $LINGON_JOB_PID

  # Did we get everything?
  diff tmp/default.html fixtures/default.html
  [ $? -eq 0 ]

  diff tmp/default2.html fixtures/test/default.html
  [ $? -eq 0 ]
}
