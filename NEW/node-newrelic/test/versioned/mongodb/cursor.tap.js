/*
 * Copyright 2020 New Relic Corporation. All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict'

var common = require('./collection-common')
var concat = require('concat-stream')
var helper = require('../../lib/agent_helper')
var mongoPackage = require('mongodb/package.json')
var semver = require('semver')
var tap = require('tap')


common.test('count', function countTest(t, collection, verify) {
  collection.find({}).count(function onCount(err, data) {
    t.notOk(err, 'should not error')
    t.equal(data, 30, 'should have correct result')
    verify(null, [
      'Datastore/statement/MongoDB/testCollection/count',
      'Callback: onCount'
    ], [
      'count'
    ])
  })
})

common.test('explain', function explainTest(t, collection, verify) {
  collection.find({}).explain(function onExplain(err, data) {
    t.error(err)
    // Depending on the version of the mongo server the explain plan is different.
    if (data.hasOwnProperty('cursor')) {
      t.equal(data.cursor, 'BasicCursor', 'should have correct response')
    } else {
      t.ok(data.hasOwnProperty('queryPlanner'), 'should have correct reponse')
    }
    verify(null, [
      'Datastore/statement/MongoDB/testCollection/explain',
      'Callback: onExplain'
    ], [
      'explain'
    ])
  })
})

if (semver.satisfies(mongoPackage.version, '<3')) {
  common.test('nextObject', function nextObjectTest(t, collection, verify) {
    collection.find({}).nextObject(function onNextObject(err, data) {
      t.notOk(err)
      t.equal(data.i, 0)
      verify(null, [
        'Datastore/statement/MongoDB/testCollection/nextObject',
        'Callback: onNextObject'
      ], [
        'nextObject'
      ])
    })
  })
}

common.test('next', function nextTest(t, collection, verify) {
  collection.find({}).next(function onNext(err, data) {
    t.notOk(err)
    t.equal(data.i, 0)
    verify(null, [
      'Datastore/statement/MongoDB/testCollection/next',
      'Callback: onNext'
    ], [
      'next'
    ])
  })
})

common.test('toArray', function toArrayTest(t, collection, verify) {
  collection.find({}).toArray(function onToArray(err, data) {
    t.notOk(err)
    t.equal(data[0].i, 0)
    verify(null, [
      'Datastore/statement/MongoDB/testCollection/toArray',
      'Callback: onToArray'
    ], [
      'toArray'
    ])
  })
})

if (semver.satisfies(mongoPackage.version, '<4')) {
  tap.test('piping cursor stream hides internal calls', function(t) {
    var agent = helper.instrumentMockedAgent()
    var client = null
    var db = null
    var collection = null

    t.teardown(function() {
      return common.close(client, db)
        .then(() => {
          helper.unloadAgent(agent)
          agent = null
        })
    })

    var mongodb = require('mongodb')
    common.dropTestCollections(mongodb, ['testCollection'])
      .then(() => {
        return common.connect(mongodb)
      })
      .then((res) => {
        client = res.client
        db = res.db

        collection = db.collection('testCollection')
        return common.populate(db, collection)
      })
      .then(runTest)

    function runTest() {
      helper.runInTransaction(agent, function(transaction) {
        transaction.name = common.TRANSACTION_NAME
        var destination = concat(function() {})

        destination.on('finish', function() {
          transaction.end()
          t.equal(transaction.trace.root.children[0].name,
            'Datastore/operation/MongoDB/pipe', 'should have pipe segment')
          t.equal(0, transaction.trace.root.children[0].children.length,
            'pipe should not have any children')
          t.end()
        })

        collection
          .find({})
          .pipe(destination)
      })
    }
  })
}
