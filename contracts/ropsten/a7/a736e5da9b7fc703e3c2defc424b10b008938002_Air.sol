/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;


contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract Air is Owned{
    string[] private _promoCodes;
    mapping(address => bool) public isAdmin;
    
    constructor() public {}
    
    function setAdmin(address admin, bool approved) public onlyOwner {
        isAdmin[admin] = approved;
    }
    function setPromoCodes(string[] memory promoCodes) public returns(bool){
        require(isAdmin[msg.sender]);
        uint256 len = promoCodes.length;
        for (uint i=0;i<len;++i) {
            _promoCodes.push(promoCodes[i]);
        }
    }
    function indexOf(string memory code) public view returns(uint256){
        uint256 len = _promoCodes.length;
        for (uint i=0;i<len;++i) {
            if(keccak256(abi.encodePacked(_promoCodes[i])) == keccak256(abi.encodePacked(code))){
                return i;
            }
        }
    }
    function isPromoCode(string memory code, uint256 index) public view returns(bool b){
        if(keccak256(abi.encodePacked(_promoCodes[index])) == keccak256(abi.encodePacked(code))){
            b = true;
        }
    }
}