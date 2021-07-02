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

package msql

import "go.zoe.im/payserver/server/core"

func (d driver) CreateApp(app *core.App) (*core.App, error) {
	return app, d.Create(app).Error
}

func (d driver) GetApp(id string) (*core.App, error) {
	var app core.App
	return &app, d.Where("uid = ?", id).First(&app).Error
}

func (d driver) GetAppByName(name string) (*core.App, error) {
	var app core.App
	return &app, d.Where("name = ?", name).First(&app).Error
}

func (d driver) DeleteApp(id string) error {
	return d.Where("uid = ?", id).Error
}

func (d driver) UpdateApp(app *core.App) (*core.App, error) {
	return app, d.Model(app).Updates(app).Error
}

func (d driver) ListApps(offset, limit int, query ...interface{}) ([]*core.App, error) {
	var apps []*core.App
	return apps, d.Where(query).Offset(offset).Limit(limit).Find(&apps).Error
}
