package hal

/*
 * Copyright 2016-2017 Netflix, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import (
	"testing"
)

func TestLogger(t *testing.T) {
	l := Logger{}

	l.Printf("you SHOULD see this log message on stdout 1/2")
	l.Debugf("you SHOULD see this debug message on stdout 2/2")

	l.DisableDebug()

	l.Debugf("you should NOT see this debug message on stdout 1/1")

	// these would most likely panic if something was wrong
	l.DisableDbgStdout()
	l.DisableLogStdout()

	// should print nothing, manually verifiable
	l.Printf("you should NOT see this log message on stdout 1/2")
	l.Debugf("you should NOT see this debug message on stdout 2/2")

}
