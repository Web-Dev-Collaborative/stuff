package demultiplexer

import (
	"github.com/signalfx/golib/datapoint"
	"github.com/signalfx/golib/datapoint/dpsink"
	"github.com/signalfx/golib/errors"
	"github.com/signalfx/golib/event"
	"golang.org/x/net/context"
)

// Demultiplexer is a sink that forwards points it sees to multiple sinks
type Demultiplexer struct {
	DatapointSinks []dpsink.DSink
	EventSinks     []dpsink.ESink
}

var _ dpsink.Sink = &Demultiplexer{}

// AddDatapoints forwards all points to each sendTo sink.  Returns the error message of the last
// sink to have an error.
func (streamer *Demultiplexer) AddDatapoints(ctx context.Context, points []*datapoint.Datapoint) error {
	if len(points) == 0 {
		return nil
	}
	var errs []error
	for _, sendTo := range streamer.DatapointSinks {
		if err := sendTo.AddDatapoints(ctx, points); err != nil {
			errs = append(errs, err)
		}
	}
	return errors.NewMultiErr(errs)
}

// AddEvents forwards all events to each sendTo sink.  Returns the error message of the last
// sink to have an error.
func (streamer *Demultiplexer) AddEvents(ctx context.Context, points []*event.Event) error {
	if len(points) == 0 {
		return nil
	}
	var errs []error
	for _, sendTo := range streamer.EventSinks {
		if err := sendTo.AddEvents(ctx, points); err != nil {
			errs = append(errs, err)
		}
	}
	return errors.NewMultiErr(errs)
}
