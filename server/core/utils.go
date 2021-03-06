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

package core

type RegisterAgentTicket struct {
	// server information for api
	Name    string `json:"name" yaml:"name"`
	Host    string `json:"host" yaml:"host"`
	Version string `json:"version" yaml:"version"`

	// agent certify
	UID    string `json:"uid,omitempty" yaml:"uid"` // should't offers? deprecated
	Ticket string `json:"ticket" yaml:"ticket"`
}
