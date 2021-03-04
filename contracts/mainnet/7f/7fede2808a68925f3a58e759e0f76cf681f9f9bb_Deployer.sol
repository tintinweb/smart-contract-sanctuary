// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./Ownable.sol";
import "./Creator.sol";

contract Deployer is Ownable, Creator {
    event Creation(address indexed target, address delegatecallTarget);

    bytes constant initBytecode = hex"5863b34a049881526020816004601c335afa508081828384515af43d8083843e9190602657fd5bf3";
    bytes32 constant public initHash = keccak256(initBytecode);
    address public currentDelegatecallTarget;
    address proxyHolder;
    address deployHolder;

    function calculateAddress(bytes32 salt) public view returns (address) {
        return _calculateAddress(address(this), salt, initHash);
    }

    function deploy(bytes32 salt, address delegatecallTarget) external payable returns (address) {
        require(msg.sender == deployHolder, "Deploy: sender not deploy holder");

        currentDelegatecallTarget = delegatecallTarget;
        address target = _deploy(salt, initBytecode);

        // Need to prevent zero length contracts, since the Control Token can't
        // differentiate between a self-destructed contract and a still deployed
        // zero-length contract.
        uint256 codelen;
        assembly {
            codelen := extcodesize(target)
        }
        require(0 != codelen, "Deploy: sz == 0");

        emit Creation(target, delegatecallTarget);
        return target;
    }

    function setProxyHolder(address _proxyHolder) external onlyOwner {
        proxyHolder = _proxyHolder;
    }

    function setDeployHolder(address _deployHolder) external onlyOwner {
        deployHolder = _deployHolder;
    }

    function proxy(address target, bytes memory data) external payable {
        require(msg.sender == proxyHolder, "Deploy: sender not proxy holder");
        assembly {
            let result := call(
                gas(),              // Gas sent with call
                target,             // Contract to call
                callvalue(),        // Wei to send with call
                add(data, 0x20),    // Pointer to calldata
                mload(data),        // Length of call data
                0,                  // Pointer to return buffer
                0                   // Length of return buffer
            )
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }
}