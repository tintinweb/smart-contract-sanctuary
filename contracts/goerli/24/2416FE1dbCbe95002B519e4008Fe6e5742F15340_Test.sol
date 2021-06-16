// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Test {
	constructor () {

	}

	function description() public pure returns (string memory) {
		return 'TEST';
	}
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}