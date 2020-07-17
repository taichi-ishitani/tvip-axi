[![Gitter](https://badges.gitter.im/taichi-ishitani/tvip-axi.svg)](https://gitter.im/taichi-ishitani/tvip-axi?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

# TVIP-AXI

TVIP-AXI is an UVM package of AMBA AXI4 VIP.

## Feature

* Master and slave agent
* Support AXI4 and AXI4-Lite protocols
* Highly configurable
    * address width
    * data width
    * ID width
    * etc.
* Support delayed write data and response
* Support gapped write data and read response
* Response ordering
    * in-order response
    * out of order response
* Support read interleave
* Include UVM RAL adapter and predictor

## Sample Environment

The sample environment is included. The execution procedure is as following.

### Preparation

Before executing the sample environment, you need to clone submodules. Hit command below on the root directory of TVIP-AXI.

    $ ./setup_submodules.sh

### Execution

To execute the sample environment, hit command below on the `sample/work` directory.

    $ make

Then, all sample test cases will be executed by using Synopsys VSC simulator.
If you want to use Cadence Xcelium simulator, hit command below.

    $ make SIMULATOR=xcelium

If you want to execute a test case individually, hit command below.

    $ make NAME_OF_TEST_CASE

Followings are available test cases:

* default
* request_delay
    * sample for delayed request
    * sample for gapped write data
* response_delay
    * sample for delayed response
    * sample for gapped read response
* out_of_order_response
    * sample for out of order response
* read_interleave
    * sample for read interleave

### Supported Simulator

Supported simulators are below:

* Synopsys VCS
* Cadence Xcelium
    * `-warn_multiple_driver` option may be needed to avoid `E,ICDCBA` error

## Contact

If you have any questions, problems, feedbacks, etc., you can post them on following ways:

* [GitHub Issue Tracker](https://github.com/taichi-ishitani/tvip-axi/issues)
* [Chat room](https://gitter.im/taichi-ishitani/tvip-axi)
* [Mail](mailto:taichi730@gmail.com)

## Copyright

Copyright (C) 2018 Taichi Ishitani.
TVIP-AXI is licensed under the Apache-2.0 license. See [LICENSE](LICENSE) for further details.
