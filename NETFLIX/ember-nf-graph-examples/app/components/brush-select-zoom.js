import Ember from 'ember';
import { dataGenerator } from '../services/data-generator';
import { format } from '../helpers/format-hour-minute';

export default Ember.Component.extend({

  // Start and end dates for filtering the graph data.
  // These are the initial values and will change when brush actions
  // are executed below
  startTime: 0,
  endTime: Number.MAX_VALUE,


  // Domain values for right and left brush markers. These are modified
  // when the user drags with the mouse.
  selectLeft: undefined,
  selectRight: undefined,


  // Original graph data (no zoom or filter)
  graphData: function() {
    return dataGenerator.simpleTimeSeries();
  }.property(),


  // Graph data filtered by zoom extents. Filtered to include only data points
  // falling within the zoom start and end dates
  zoomData: function() {
    var self = this;

    return this.get('graphData').filter(function(d) {
      return d.x >= self.get('startTime') && d.x <= self.get('endTime');
    });
  }.property('graphData', 'startTime', 'endTime'),


  // Formats the text shown on the brush selection markers.
  // This is using the format code imported from helper:format-hour-minute
  selectionDisplayFormatter: function(ms) {
    return format(ms);
  },


  actions: {

    brushEnd: function(e) {
      // Now that the brush drag is finished set new
      // zoom values for filtering the main graph data
      this.set('startTime', Ember.get(e, 'left.x'));
      this.set('endTime', Ember.get(e, 'right.x'));

    },

    reset: function() {
      // Reset teh zoom extents
      this.set("startTime", 0);
      this.set("endTime", Number.MAX_VALUE);
    }
  },

});