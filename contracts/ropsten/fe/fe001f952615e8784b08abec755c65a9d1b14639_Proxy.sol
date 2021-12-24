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
        // Copy msg.data. We take full control of memory in this inline assembly
        // block because it will not return to Solidity code. We overwrite the
        // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

        // Call the implementation.
        // out and outsize are 0 for now, as we don't know the out size yet.
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

        // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
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