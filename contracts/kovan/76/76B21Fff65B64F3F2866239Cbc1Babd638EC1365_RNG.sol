// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract RNG{
    mapping(address => uint) lookup;
    function seed(address _requester) external{
        lookup[_requester] = 5;
    }
    function getRNG(address _requester) external returns(uint){
        return uint(keccak256(abi.encodePacked(lookup[_requester])));
    }
}

