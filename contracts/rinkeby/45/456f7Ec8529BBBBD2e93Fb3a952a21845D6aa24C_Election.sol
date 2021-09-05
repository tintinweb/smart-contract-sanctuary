/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

contract Election {
    mapping(address => bool) _voters;
    mapping(uint => uint) _candidates;
    address _owner;
    bool _open;

    
    modifier onlyOwner {
        require(_owner == msg.sender , "You are not authorized");
        _;
    }
    
    function open() public onlyOwner{
        _open = true;
    }
    
    function close() public onlyOwner{
        _open = false;
    }
    
    function vote(uint number) public {
       require(_open, "election closed");
       require(!_voters[msg.sender], "You're voted");
       
        _candidates[number]++;
        _voters[msg.sender] = true;
    }
    
    function summary(uint number) public view returns(uint){
        return _candidates[number];
    }
}