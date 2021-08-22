/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Election {
    mapping(uint => uint) _candidates;
    mapping(address => bool) _voters;
    bool _open;
    address _owner;
    event Vote(address indexed voter, uint indexed number);
    
    constructor() {
        _owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == _owner, "You're not authorized");
        _;
    }
    
    function status() public view returns (string memory) {
        return _open ? 'open' : 'closed';
    }
    
    function open() public onlyOwner {
        _open = true;
    }
    
    function close() public onlyOwner {
        _open = false;
    }
    
    function vote(uint number) public {
        require(_open, 'Election closed');
        //require(!_voters[msg.sender], "You're voted");
        
        _candidates[number]++;
        _voters[msg.sender] = true;
        
        emit Vote(msg.sender, number);
    }
    
    function summary(uint number) public view returns (uint) {
        return _candidates[number];
    }
}