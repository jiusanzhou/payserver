package msql

import (
	"go.zoe.im/payserver/server/core"
)

func (d driver) CreateAgent(a *core.Agent) (*core.Agent, error) {
	return a, d.Create(a).Error
}

func (d driver) UpdateAgent(a *core.Agent) (*core.Agent, error) {
	return a, d.Model(a).Updates(a).Error
}

func (d driver) GetAgentByTicket(ticket string) (*core.Agent, error) {
	var a core.Agent
	return &a, d.Where("ticket = ?", ticket).First(&a).Error
}

func (d driver) CountPenddingAgents() (int, error) {
	var count int64
	return int(count), d.Model(&core.Agent{}).
		Where("status = ?", core.AgentStatusPendding).
		Count(&count).Error
}

func (d driver) ListAgents() ([]*core.Agent, error) {
	var as []*core.Agent
	return as, d.Where("delete_at == null").Find(&as).Error
}
