// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

contract Deployer {
    event Deployed(address addr, uint256 salt);
    /**
     * @dev during deployment creates a new contract of Example.sol
     *
     * the create2 function takes in 4 params.
     * 1 - the number of ETH to be send.
     */
    function deploy(bytes memory code, uint256 salt) public {
    address addr;
        assembly {
        addr := create2(0, add(code, 0x20), mload(code), salt)
        if iszero(extcodesize(addr)) {
            revert(0, 0)
        }
        }
        emit Deployed(addr, salt);
    }

}

{
  "optimizer": {
    "enabled": false,
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