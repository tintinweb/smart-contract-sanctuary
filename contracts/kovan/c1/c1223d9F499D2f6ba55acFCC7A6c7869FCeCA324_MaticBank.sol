/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

pragma solidity 0.7.5;

contract MaticBank{
    
    mapping(address => uint) balance;
    
    function addBalance() public payable returns(uint){
        balance[msg.sender] += msg.value;
        return balance[msg.sender];
    }
    
    function getBalance() public view returns(uint){
        return balance[msg.sender];
    }
    
    function withdraw(uint amount) public returns(uint){
        require(balance[msg.sender]>= amount, "balance not sufficient");
        uint previousBalance = balance[msg.sender];
        balance[msg.sender] -= amount;
        msg.sender.transfer(amount);
        assert(balance[msg.sender] == previousBalance - amount);
        return balance[msg.sender];
    }
}