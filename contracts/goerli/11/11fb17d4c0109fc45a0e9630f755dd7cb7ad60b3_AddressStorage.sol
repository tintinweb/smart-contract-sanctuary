/**
 *Submitted for verification at Etherscan.io on 2021-07-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract AddressStorage {

    address[] _addresses;
    mapping(address => uint256) public valMap;


    function store(address[] calldata addresses) public {
        _addresses = addresses;
    }

    function retrieve() public view returns (address[] memory){
        return _addresses;
    }
    
    function deposit(address valAdr) external payable{
        valMap[valAdr] += msg.value;
    }
    
    function getVal(address valAdr) public view returns (uint256) {
        return valMap[valAdr];
    }
    
}