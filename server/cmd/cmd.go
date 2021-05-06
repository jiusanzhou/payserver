/*
 * Copyright (c) 2021 wellwell.work, LLC by Zoe
 *
 * Licensed under the Apache License 2.0 (the "License");
 * You may not use this file except in compliance with the License.
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

package cmd

import (
	"go.zoe.im/x/cli"
	"go.zoe.im/x/version"
)

var (
	// root command to contains all sub commands
	cmd = cli.New(
		// set name and description in run function
		cli.Name("payserver"),
		cli.Short("payserver is a server for pay."),
		version.NewOption(true),
	)
)

// Register sub command
func Register(scs ...*cli.Command) {
	cmd.Register(scs...)
}

// Run call the global's command run
func Run(opts ...cli.Option) error {
	return cmd.Run(opts...)
}

// Option reload with options
func Option(opts ...cli.Option) {
	cmd.Option(opts...)
}
