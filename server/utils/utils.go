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

// GenPriceFloats TODO: make order method wit arg
// 0, -1, -2, 1, 2
// 0, 1, 2, -1, -2
func GenPriceFloats(floor, ceil int) []int {
	floats := make([]int, 1+floor+ceil)
	floats[0] = 0
	for i := 1; i <= floor; i++ {
		floats[i] = -1 * i
	}
	for i := 1; i <= ceil; i++ {
		floats[floor+i] = i
	}
	return floats
}
