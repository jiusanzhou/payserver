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

package utils

import (
	"reflect"
	"testing"
)

func TestGenPriceFloats(t *testing.T) {
	type args struct {
		floor int
		ceil  int
	}
	tests := []struct {
		name string
		args args
		want []int
	}{
		{
			"Simple", args{0, 0}, []int{0},
		},
		{
			"Simple 2", args{1, 0}, []int{0, -1},
		},
		{
			"Simple 3", args{0, 1}, []int{0, 1},
		},
		{
			"Simple 4", args{1, 1}, []int{0, -1, 1},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := GenPriceFloats(tt.args.floor, tt.args.ceil); !reflect.DeepEqual(got, tt.want) {
				t.Errorf("GenPriceFloats() = %v, want %v", got, tt.want)
			}
		})
	}
}
