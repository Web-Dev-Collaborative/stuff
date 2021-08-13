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

import superagent from 'superagent'
import { parse } from 'query-string'
import config from 'config'

/////////////////////////////////////
// window.location handling support

export function pushQueryStringToHistory(targets, chartlist, history) {
  console.log(chartlist)

  const data = targets.map(t => ({
    p: t.protocol,
    h: t.hostname,
    hs: t.hostspec,
    ci: t.containerId,
    cl: chartlist
      .filter(c => matchesTarget(c.context.target, t))
      .map(c => c.chartId)
  }))
  const blob = JSON.stringify(data)
  const encoded = encodeURI(blob)

  // we can kinda do this because the only way you should be able to add charts is when not in embed mode
  history.push(`/?q=${encoded}`)
}

export function getChartsFromLocation({ search, hash }) {
  if (!search && !hash) {
    return { chartlist: [], targets: [] }
  }

  // check for old world urls
  // the links in from legacy are via host= and container=,
  // ignore the charts specifically (too bad)
  if (hash) {
    const queryHash = parse(hash)
    const hostname = queryHash['/?host'] + ':' + config.defaultPort
    const containerId = queryHash.container || '_all'
    return {
      isLegacy: true,
      targets: [{
        protocol: config.defaultProtocol,
        hostname,
        hostspec: 'localhost',
        containerId,
      }],
      chartlist: []
    }
  }

  function uniqueTargetFilter (val, index, array) {
    return array.findIndex(v => matchesTarget(v, val)) === index
  }

  if (search) {
    const query = parse(search)

    const decoded = decodeURI(query['q'])
    const params = JSON.parse(decoded)

    const targets = params
      .map(c => ({
        protocol: 'p' in c ? c.p : config.defaultProtocol,
        hostname: c.h,
        hostspec: c.hs,
        containerId: c.ci
      }))
      .filter(uniqueTargetFilter) // should not be needed, but just in case

    const chartlist = params.map(c =>
      c.cl.map(chartId => ({
        target: {
          protocol: 'p' in c ? c.p : config.defaultProtocol,
          hostname: c.h,
          hostspec: c.hs,
          containerId: c.ci
        },
        chartId: chartId
      }))
    ).reduce(flatten, [])

    return {
      targets,
      chartlist,
    }
  }
}

/////////////////////////////////////
// generic object functions

export function flatten (xs, ys) {
  return xs.concat(ys)
}

export function uniqueFilter (val, index, array) {
  return array.indexOf(val) === index
}

// use as a reducer
export function keyValueArrayToObjectReducer (obj, { key, value }) {
  obj[key] = value
  return obj
}

export function firstValueInObject(obj) {
  return obj[Object.keys(obj)[0]]
}

/////////////////////////////////////
// handling targets and contexts
export function matchesTarget (t1, t2) {
  return !!(t1 && t2 && t1.hostname === t2.hostname && t1.hostspec === t2.hostspec && t1.containerId === t2.containerId)
}

export function isContextLoading (context) {
  return !(context.contextId
    && (Object.keys(context.pmids || {}).length > 0)
    && context.hostname
    && context.containerList)
}

/////////////////////////////////////
// pmwebd connectivity
const PMAPI_POLL_TIMEOUT_SECONDS = 5

export async function fetchContainerList (protocol, hostname, hostport, hostspec) {
  // set up a new context, then fetch container and cgroup details
  const pmapi = `${protocol}://${hostname}:${hostport}/pmapi`

  let res = await superagent
    .get(`${pmapi}/context`)
    .query({ exclusive: 1, hostspec: hostspec, polltimeout: PMAPI_POLL_TIMEOUT_SECONDS })
  const context = res.body.context

  // need to do this second fetch and join to make sure we get genuine containers
  const promisedContainerNames = superagent.get(`${pmapi}/${context}/_fetch?names=containers.name`)
  const promisedCgroups = superagent.get(`${pmapi}/${context}/_fetch?names=containers.cgroup`)

  res = await promisedContainerNames
  const containers = res.body.values.length ? res.body.values[0].instances : []
  res = await promisedCgroups
  const cgroups = res.body.values.length ? res.body.values[0].instances : []

  const containerList = cgroups.map(({ instance, value }) => ({
    instance,
    cgroup: value,
    containerId: containers.find(cont => cont.instance === instance).value
  }))

  return containerList
}

