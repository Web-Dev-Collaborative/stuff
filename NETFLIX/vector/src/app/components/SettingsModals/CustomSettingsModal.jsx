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
import * as formats from '../../processors/formats'
import memoizeOne from 'memoize-one'

import { Form } from 'semantic-ui-react'

class CustomChartSettingsModal extends React.PureComponent {
  state = {
    metricNames: this.props.metricNames,
    yTickFormat: this.props.yTickFormat,
    lineType: this.props.lineType,
    cumulative: this.props.cumulative,
    converted: this.props.converted,
    conversionFunction: this.props.conversionFunction,
  }

  handleMetricChange = (e, { value }) => this.setState({ metricNames: [value] })
  handleAreaChange = (e, { checked }) => this.setState({ lineType: checked ? 'stackedarea' : 'line'})
  handleCumulativeChange = (e, { checked }) => this.setState({ cumulative: checked })
  handleConvertedChange = (e, { checked }) => this.setState({ converted: checked })
  handleConversionFunctionChange = (e, { value }) => this.setState({ conversionFunction: value })
  handleYTickFormatChange = (e, { value }) => this.setState({ yTickFormat: formats[value] })

  handleSubmit = () => {
    this.props.onNewSettings(this.state)
    this.props.onClose()
  }

  getOptions = memoizeOne(pmids => Object.keys(pmids).map(name => ({ text: name, value: name })))

  render() {
    const options = this.getOptions(this.props.pmids)
    const { metricNames, cumulative, converted, conversionFunction, lineType, yTickFormat } = this.state

    return (
      <Form className='doNotDrag' onSubmit={this.handleSubmit}>
        <Form.Dropdown label='Select metric' placeholder='Select Metric' fluid search selection
          value={metricNames && metricNames.length && metricNames[0]}
          onChange={this.handleMetricChange}
          options={options} />

        <Form.Checkbox label='Stacked Area' checked={lineType === 'stackedarea'} onChange={this.handleAreaChange} />
        <Form.Checkbox label='Cumulative' checked={cumulative} onChange={this.handleCumulativeChange} />
        <Form.Checkbox label='Converted' checked={converted} onChange={this.handleConvertedChange} />

        <Form.Input label='Conversion Function (use "value" as the variable)'
          disabled={!converted}
          value={converted ? conversionFunction: ''}
          onChange={this.handleConversionFunctionChange} />

        <Form.Group inline>
          <label>Format</label>
          <Form.Radio label='Number' name='yTickFormat' value='number'
            checked={yTickFormat === formats.number}
            onChange={this.handleYTickFormatChange} />
          <Form.Radio label='Integer' name='yTickFormat' value='integer'
            checked={yTickFormat === formats.integer}
            onChange={this.handleYTickFormatChange} />
          <Form.Radio label='Percentage' name='yTickFormat' value='percentage'
            checked={yTickFormat === formats.percentage}
            onChange={this.handleYTickFormatChange} />
        </Form.Group>

        <Form.Button type='submit'>OK</Form.Button>
      </Form>
    )
  }
}

CustomChartSettingsModal.propTypes = {
  pmids: PropTypes.object.isRequired,

  metricNames: PropTypes.array.isRequired,
  yTickFormat: PropTypes.func.isRequired,
  lineType: PropTypes.string.isRequired,
  cumulative: PropTypes.bool.isRequired,
  converted: PropTypes.bool.isRequired,
  conversionFunction: PropTypes.string.isRequired,

  onNewSettings: PropTypes.func.isRequired,
  onClose: PropTypes.func.isRequired,
}

export default CustomChartSettingsModal
