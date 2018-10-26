# TVIP-AXI

TVIP-AXI is an UVM package of AMBA AXI4 VIP.

## Feature

* Master and slave agent
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

## Sample Environment

The sample environment is included. The execution procedure is as following.

### Preparation

Before executing the sample environment, you need to clone submodules. Hit command below on the root directory of TVIP-AXI.

    $ ./setup_submodules.sh

### Execution

To execute the sample environment, hit commands below on the `sample/work` directory.

    $ make

Then, all sample test cases will be executed.

You want to execute a test case individually, hit command below.

    $ make NAME_OF_TEST_CASE

Followings are available test cases:

* default
* write_data_delay
    * sample for gapped write data
* response_start_delay
    * sample for delayed response
* response_delay
    * sample for gapped read response
* out_of_order_response
    * sample for out of order response
* read_interleave
    * sample for read interleave

### Supported Simulator

Supported simulators are below:

* Synopsys VCS
* Cadence Xcelium
    * Makefile for Xcelium simulator is not available

## Contact

If you have any questions, problems, feedbacks, etc., you can post them on following ways:

* Create an issue on the [issue tracker](https://github.com/taichi-ishitani/tvip-axi/issues)
* Send mail to [taichi730@gmail.com](mailto:taichi730@gmail.com)

## Copyright

Copyright (C) 2018 Taichi Ishitani.
TVIP-AXI is licensed under the Apache-2.0 license. See [LICENSE](LICENSE) for further details.
