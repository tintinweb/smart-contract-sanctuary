//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Proxy.sol";
import "./Ownable.sol";
import "./TokenStorage.sol";

contract SnakeArtifactsNFTProxy is Proxy, Ownable, TokenStorage {

    event ReplaceImplementation(address oldTarget, address newTarget);

    constructor(address target) {
        _implementationAddress = target;
        emit ReplaceImplementation(address(0), target);
    }
    
    function implementation() public view returns (address) { 
        return _implementationAddress; 
    }

    function _implementation() internal view override returns (address) { 
        return _implementationAddress; 
    }

    function replaceImplementation(address newTarget) external onlyOwner {
        require(newTarget != address(0), "SnakeArtifactsNFTProxy: target's address is equal to zero address");
        address oldTarget = _implementationAddress;
        _implementationAddress = newTarget;
        emit ReplaceImplementation(oldTarget, newTarget);
    }
}