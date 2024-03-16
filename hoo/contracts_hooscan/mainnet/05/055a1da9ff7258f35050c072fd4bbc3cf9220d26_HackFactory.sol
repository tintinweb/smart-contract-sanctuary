/**
 *Submitted for verification at hooscan.com on 2022-03-27
*/

// File: contracts\Hack.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hack {
    // The address of the smart chef factory
    address public POOL_FACTORY;

    uint256 public startBlock;

    constructor() {
        POOL_FACTORY = msg.sender;
    }

    function initialize(uint256 _startBlock ) external {
        startBlock = _startBlock;
    }
}

contract HackFactory {
    function deployPool(uint256 _startBlock) external {
        bytes memory bytecode = type(Hack).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(_startBlock));

        address syrupPoolAddress;

        assembly {
            syrupPoolAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        Hack(syrupPoolAddress).initialize(
            _startBlock
        );
    }
}