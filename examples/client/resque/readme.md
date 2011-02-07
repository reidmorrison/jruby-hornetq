Overview

This example shows how to use Resque to initiate a Job which in turn submits all
its work to processors.

## Architecture

The architecture for this example uses:
### Initiator

An _initiator_ which enqueues the job to be completed

### Resque Worker

A _resque worker_ which manages the job itself. The _resque worker_ in turn submits
requests to the _task worker_.

### Processor

A _processor_ performs the actual work and receives its requests over a
hornetq queue. It replies back to the _resque worker_ when complete


Requirements

Install the following gems
* resque
* resque-status
** https://github.com/quirkey/resque-status

Start the Resque Job worker

Start the Task workers