# CramSim - ControlleR And Memory SIMulator
Developed using the Structural Simulation Toolkit

## Table of Contents

- [Prerequisites To Installation](#prerequisites-to-installation)
- [Installation](#installation)
- [When Editing The Simulator](#when-editing-the-simulator)
- [Running A Simulation](#running-a-simulation)
- [Verimem](#verimem)
- [SST Basics](#sst-basics)
- [CramSim.cpp](#cramsim.cpp)
- [Model Overview](#model-overview)
  - [Additional Information](#additional-information)
- [Running A Simulation With CPU Models](#running-a-simulation-with-cpu-models)

## Prerequisites To Installation
  - Boost 1.57
  - OpenMPI 1.8.8
  - SST Release Version

## Installation
  - Once the repo is cloned, change directory to main folder (`sstcramsim`)
  - Run `./autogen.sh`
  - Run `cd sst/elements/CramSim`
  - Run `make`

## When Editing The Simulator
  - If adding a new class:
    - Add class files to `Makefile.am`
    - Change directory to parent directory `sstcramsim`
    - Run `./autogen.sh`
    - Run `cd sst/elements/CramSim`
    - Run `make`
  - If modifying existing files:
    - Run `make`

## Running A Simulation
Syntax:
```shell
sst --lib-path:./libs/ PYTHON_TEST_FILE.py --model-options="--configfile=CONFIG.cfg --tracefile=TRACE.trc cfgOverrideKey=cfgOverrideVal"
```

Python file instantiates SST components and links them together. It also provides the simulator with access to
"parameter knobs". Many different test python files exist in ./tests/ . Here are some highlights. Command-line examples
are found in the "tests/run.py" file.

  - __test_txngen.py__ : Runs simulation using a series of randomly or sequentially generated instructions. "mode" flag
  are required in the `--model-options`
    - seq   : `sst --lib-path=.libs test_txngen.py --model-options="--configfile=CONFIG.cfg mode=seq"`
    - rand  : `sst --lib-path=.libs test_txngen.py --model-options="--configfile=CONFIG.cfg mode=rand"`

  - __test_txntrace.py__: Runs simulation with a commandline-provided trace file and config file. "traceFileType" flag
  are required in the `--model-options`
    - default (dramsim2 type) : `sst --lib-path=.libs test_txntrace.py --model-options="--configfile=CONFIG.cfg traceFileType=DEFAULT traceFile=TRACE.trc"`
    - usimm type              : `sst --lib-path=.libs test_txntrace.py --model-options="--configfile=CONFIG.cfg traceFileType=USIMM traceFile=TRACE.trc"`

  - Both __test_txngen.py__ and __test_txntrace.py__ allow overriding of config parameters in the --model-options. Simply add the config name and value (e.g. `nBL=8`).

    Detailed example : `sst --lib-path=.libs/ tests/test_txngen.py --model-options="--configfile=ddr4.cfg mode=rand nBL=8 nWR=30 dumpConfig=1"`

    The special override `dumpConfig=1` will print all the global config params read from the config files and resulting from overrides to the output

  - Both __test_txngen.py__ and __test_txntrace.py__ also allow multiple config files to be specified in --model-options. Later config files take precedence whenever there is a config conflict.

    Example: `sst --lib-path=.libs/ tests/test_txngen.py --model-options="--configfile=test_system.cfg --configfile=test_device.cfg nBL=8"`
    
  - __test_txntrace4.py__ : Similar to __test_txntrace.py__ but is intended to be used as part of the Verimem test suite


## Verimem
Verimem is a series of traces intended to be run to confirm the validity of the results of a simulator. Verimem's test
traces that apply to the granularity of this simulator are 1, 4, 5, and 6. Suites 2, 3, and 7 require a model that
includes bank rows and columns to provide any insights that 1, 4, 5, and 6 don't already.

NOTE: VeriMem tests will not run without downloading the traces. SST directory structure mandated that the VeriMem
traces cannot be checked in into the sst-elements directory.  The VeriMem traces are currently (01 2017) available
[here](https://github.com/sstsimulator/sst-downloads/releases). The filenames begin with sst-CramSim-trace_verimem in
the SST Test Support Files section.

To run Verimem (from within `/sstcramsim/`):

```shell
python ./tests/VeriMem/test_verimem1.py BOOL_DEBUG_OUTPUT
```

`BOOL_DEBUG_OUTPUT` should be either 0 or 1, depending on if debugging output is wanted or not.

This script runs simulations using a config file (to edit, change the variable `config_file`) and a series of different
trace files specifically structured to test the validity of the simulator's results.

## SST Basics

SST allows the usage of isolated components. Each component has its own internal clockCycle. Every cycle, each component
runs its `clockTic()` method. The simulator is cycle-based in that in a given cycle, all the clockTics are to be seen as
running concurrently. Components can be connected using SST-provided links. A link must be registered (and named) by the
two components it connects. Once both components register the link, SST-provided Event objects can be sent on the link.
The Event class can be subclassed to include specific event types that carry specific payloads (e.g. `c_TxnReqEvent`). The
simulator is event-based in that components respond discretely to events as they arrive.

## CramSim.cpp

This is the factory-pattern class that is used to instantiate SST components. Link names and parameters are explicitly
defined here so that the python file can properly map them together.

## Model Overview

Each SST component listed is connected to the component above it and below it

- Txn Generator (multiple options):
  - `c_TxnGen`
    - Generates Txns in sequential/random-address order
  - `c_TraceFileReader`
    - Reads Txns from a trace file (dramsim2 or usimm trace format)

- Controller : `c_Controller`
  - Receives Txn requests from TxnGen and stores them. Every cycle a txn is removed from the buffer, converted to Cmds, and sent to c_DIMM
  - Receives Cmd responses from c_DIMM and updates the Txn that Cmd "belonged" to. Every cycle a completed txn is removed from the response buffer and returned to TxnGen
  - Subcomponents
    1. `c_AddressHasher` : address mapper that map the physical address to the device address (e.g., channel, rank, bank, and column index)
    2. `c_TxnScheduler` :  transaction scheduler that reorder the transactions
    3. `c_TxnConverter` :  transaction converter that converts read and write trasacntions to memory-specific commands (e.g., READ -> ACT/READ/PRECHARGE) 
    4. `c_CmdScheduler` :  command scheduler that selects a command queue and picks memory commands from the command queue
    5. `c_DeviceDriver` :  device driver that maintains status of memory devices and send commands to the memory devices 

- Memory : `c_DIMM`
  - Receives a Cmd request from Controller and maps it to its particular bank before sending it to that bank.
  - Receives a Cmd response from its internal banks and sends it back to Controller

### Additional Information

- Bank addresses are mapped from the singleton class `c_AddressHasher`.
  - The address hash is highly flexible, and can be specified at the bit granularity. The map string is interpreted as little-endian (MSB first).
  - Checking is done to verify that the structure-level parameters (e.g. numRanksPerChannel) match with the number of bits defined in the address map
  - A simple map is also available. If only one instance of each type is defined the map will be automatically expanded to cover the structure sizes defined by the normal parameters.
  - If the complex address map type is defined and fewer map bits are defined than those defined by the structure parameters (e.g. map contains R:2 and numRanksPerChannel is 8) a warning will be printed but simulation will continue with only a subset of the structures being used (some ranks can never be accessed).
  - If the complex addres map type is defined and more map bits are defined than those defined by the structure parameters (e.g. map contains R:2 and numRanksPerChannel is 1) then the simulation will abort.
  - The underscore `_` can be used as spacers to increase readability of address maps
  - Address map key:
    ```
  	C - Channel
    c - PseudoChannel
  	R - Rank
  	B - BankGroup
  	b - Bank
  	r - Row
  	l - Column
  	h - Cacheline (matches burst size in bytes)
    ```
  - Examples:
    - `_r_l_b_R_B_h_` : simple version, will be expanded as necessary to fill defined structures in the order defined. No 'C' included, so only 1 channel is possible.
    - `__r:15_l:7__bb__R__BB__h:6__` : 15 row bits at MSB, folled by 7 column bits, 2 bank bits, 1 Rank bit, 2 BankGroup bits, and 6 cacheline bits
  - It is highly recommended that simulator output is piped to an external file. There is usually a lot of output to decipher


## Running A Simulation With CPU Models

CramSim can run as a backend of the memoryHierarchy element to communicate with other SST elements. A CramSim backend
is available in the memoryHierarchy directory (`elements/memHierarchy/membackend/cramSimBackend.cc`).

- Prerequisites: set environment variables
```shell
export SST_ELEMENT_HOME="<SST-Element installation directory>"
export SST_CORE_HOME="<SST-Core installation directory>"
export SST_ELEMENT_ROOT="<SST-Element source code directory>"
export SST_CORE_ROOT="<SST-Core source code directory>"
  ```

- Run with Ariel
  - Install
  ```shell
  cd $SST_ELEMENT_ROOT
  ./autogen.sh
  ./configure --prefix=$SST_ELEMENT_HOME --with-sst-core=$SST_CORE_HOME
  make install
  ```

  - Run
  ```shell
  cd $SST_ELEMENT_ROOT/src/tests
  make
  sst ariel_cramsim.py
  ```

- Run with MacSim
  - Install
  ```shell
  cd $SST_ELEMENT_ROOT/src/tests
  ./get_macsim.sh
  cd $SST_ELEMENT_ROOT
  ./autogen.sh
  export PIN_HOME = "PIN tool installation directory"
  ./configure --prefix=$SST_ELEMENT_HOME --with-sst-core=$SST_CORE_HOME --with-pin=$PIN_HOME
  make install
  ```

   - Run
  ```shell
  cd $SST_ELEMENT_ROOT/src/tests
  sst macsim_cramsim.py
  ```
