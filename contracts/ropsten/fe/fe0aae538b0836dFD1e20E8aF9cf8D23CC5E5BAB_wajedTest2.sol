/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

pragma solidity ^0.5.16;



contract wajedTest2{
    
    mapping(address => uint256) public store;
    
    address lastSetNumCaller;
    
    function setNum(uint256 num) public{
        lastSetNumCaller = msg.sender;
        store[msg.sender] = num;
    }

    function getNum() public view returns(uint256 num){
        num = store[msg.sender];
    }
    
     function getNum2() public view returns(uint256 num, address caller){
        caller = msg.sender;
        num = store[msg.sender];
    }
    
    function getNumForAccount(address account) public view returns(uint256 num){
        num = store[account];
    }
    
    function getNumForAccount2(address account) public view returns(uint256 num, address iAcount, address caller){
        caller = msg.sender;
        iAcount = account;
        num = store[account];
    }
}