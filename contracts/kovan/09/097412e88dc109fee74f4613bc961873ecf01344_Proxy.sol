/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.10;

contract Proxy {
    fallback() external payable {
        address _implementation = implementation;
        require (_implementation != address(0x0), "MISSING_IMPLEMENTATION");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    address private owner;
    address private implementation;

    constructor() {
        owner = msg.sender;
        implementation = address(0x0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getOwner() public view virtual returns (address) {
        return owner;
    }
    
    function getImplementation() public view virtual returns (address) {
        return implementation;
    }

    function setOwner(address ownerAddress) public onlyOwner{
        owner = ownerAddress;
    }

    function setImplementation(address newImplementation) public onlyOwner{
        implementation = newImplementation;
    }



}