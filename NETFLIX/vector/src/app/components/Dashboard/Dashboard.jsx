/**!
 *
 *  Copyright 2018 Netflix, Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 */

import React from 'react'
import PropTypes from 'prop-types'

import DashPanel from './DashPanel.jsx'
import ErrorPanel from '../ErrorPanel.jsx'
import { Responsive, WidthProvider } from 'react-grid-layout'
import 'react-grid-layout/css/styles.css'
import 'react-resizable/css/styles.css'
import ErrorBoundary from 'react-error-boundary'

import { matchesTarget } from '../../utils'

const GridLayout = WidthProvider(Responsive)

const gridResponsiveCols = { lg: 12, md: 10, sm: 8, xs: 6 }
const gridStyle = { paddingLeft: '15px' }

const dashPanelDivStyle = { position: 'absolute' }

class Dashboard extends React.Component {
  handleCloseClicked = ({ chartIndex }) => {
    this.props.removeChartByIndex(chartIndex)
  }
  handleNewSettings = ({ chartIndex }, settings) => {
    this.props.updateChartSettings(chartIndex, settings)
  }

  calculateGridForIndex = (idx) => {
    return {
      x: (idx % 2) * 5,
      y: Math.floor(idx / 2),
      w: 5,
      h: 9,
      minW: 3,
      minH: 3
    }
  }

  render () {
    const { chartlist, pausedContextDatasets, contextDatasets } = this.props
    const datasets = pausedContextDatasets || contextDatasets
    const chartlistWithGrid = chartlist.map((c, idx) => ({
      ...c,
      chartIndex: idx,
      dataGrid: this.calculateGridForIndex(idx),
      chartKey: `panel-${c.chartId}-${c.context.hostname}-${c.context.contextId}`,
    }))
    // order the chartlist for render by the order of the grid
    // need it reverse ordered so that popups will appear with the right z-index
    const chartlistOrderedForRender = chartlistWithGrid.sort((a, b) => (b.dataGrid.y - a.dataGrid.y))

    console.log(chartlistOrderedForRender)

    return (
      <GridLayout rowHeight={40} cols={gridResponsiveCols} style={gridStyle} clazzName='layout' draggableCancel='.doNotDrag'>
        { chartlistOrderedForRender.map((c) => {
          const ctxds = datasets.find(ctxds => matchesTarget(ctxds.target, c.context.target))
          return (
            <div key={c.chartKey} data-grid={c.dataGrid} style={dashPanelDivStyle}>
              <ErrorBoundary FallbackComponent={ErrorPanel}>
                <DashPanel
                  chartIndex={c.chartIndex}
                  chartInfo={c}
                  datasets={ctxds ? ctxds.datasets : []}
                  onCloseClicked={this.handleCloseClicked}
                  containerList={c.context.containerList || []}
                  instanceDomainMappings={ctxds ? ctxds.instanceDomainMappings : {}}
                  containerId={(c.context.containerId || '_all') === '_all' ? '' : c.context.containerId}
                  settings={c.settings}
                  onNewSettings={this.handleNewSettings}
                  pmids={c.context.pmids || {}}/>
              </ErrorBoundary>
            </div>
          )
        })}
      </GridLayout>
    )
  }
}

Dashboard.propTypes = {
  chartlist: PropTypes.array.isRequired,
  contextDatasets: PropTypes.array.isRequired,
  pausedContextDatasets: PropTypes.array,
  removeChartByIndex: PropTypes.func.isRequired,
  updateChartSettings: PropTypes.func.isRequired,
}

export default Dashboard
