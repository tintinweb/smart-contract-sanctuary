/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

pragma solidity ^0.5.16;



contract wajedTest{
    
    mapping(address => uint256) store;
    
    function setNum(uint256 num) public{
        store[msg.sender] = num;
    }

    function getNum() public view returns(uint256 num){
        num = store[msg.sender];
    }
    
    function getNumForAccount(address account) public view returns(uint256 num){
        num = store[account];
    }
}