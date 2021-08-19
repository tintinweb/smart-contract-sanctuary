// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract TommyDeployer {
	address public controller = 0xdC7C7F0bEA8444c12ec98Ec626ff071c6fA27a19;

  event Deployed(address addr, bytes32 salt);

  function deploy(bytes memory code, bytes32 salt) public onlyController {
    address addr;
    assembly {
      addr := create2(0, add(code, 0x20), mload(code), salt)
      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }
    emit Deployed(addr, salt);
  }

	function updateController(address _controller) public onlyController {
		controller = _controller;
	}

	function execute(address _to, uint256 _value, bytes calldata _data) external onlyController returns (bool, bytes memory) {
		(bool success, bytes memory result) = _to.call{value:_value}(_data);
		return (success, result);
	}

	modifier onlyController() {
		require(controller == msg.sender, "!controller");
		_;
	}


}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}