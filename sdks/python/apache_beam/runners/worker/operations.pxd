#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

cimport cython

from apache_beam.runners.common cimport Receiver
from apache_beam.runners.worker cimport opcounters
from apache_beam.utils.windowed_value cimport WindowedValue
from apache_beam.metrics.execution cimport ScopedMetricsContainer


cdef WindowedValue _globally_windowed_value
cdef type _global_window_type

cdef class ConsumerSet(Receiver):
  cdef list consumers
  cdef readonly opcounters.OperationCounters opcounter
  cdef public step_name
  cdef public output_index
  cdef public coder

  cpdef receive(self, WindowedValue windowed_value)
  cpdef update_counters_start(self, WindowedValue windowed_value)
  cpdef update_counters_finish(self)


cdef class Operation(object):
  cdef readonly operation_name
  cdef readonly spec
  cdef object consumers
  cdef readonly counter_factory
  cdef public metrics_container
  cdef public ScopedMetricsContainer scoped_metrics_container
  # Public for access by Fn harness operations.
  # TODO(robertwb): Cythonize FnHarness.
  cdef public list receivers
  cdef readonly bint debug_logging_enabled

  cdef public step_name  # initialized lazily

  cdef readonly object state_sampler

  cdef readonly object scoped_start_state
  cdef readonly object scoped_process_state
  cdef readonly object scoped_finish_state

  cpdef start(self)
  cpdef process(self, WindowedValue windowed_value)
  cpdef finish(self)

  cpdef output(self, WindowedValue windowed_value, int output_index=*)

cdef class ReadOperation(Operation):
  @cython.locals(windowed_value=WindowedValue)
  cpdef start(self)

cdef class DoOperation(Operation):
  cdef object dofn_runner
  cdef Receiver dofn_receiver
  cdef object tagged_receivers

cdef class CombineOperation(Operation):
  cdef object phased_combine_fn

cdef class FlattenOperation(Operation):
  pass

cdef class PGBKCVOperation(Operation):
  cdef public object combine_fn
  cdef public object combine_fn_add_input
  cdef dict table
  cdef long max_keys
  cdef long key_count

  cpdef output_key(self, tuple wkey, value)

