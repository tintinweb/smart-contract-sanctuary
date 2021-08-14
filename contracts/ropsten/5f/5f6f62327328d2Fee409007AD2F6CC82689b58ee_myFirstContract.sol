/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

pragma solidity 0.5.16;

contract myFirstContract {
    
    mapping(address=> uint) public deposits;
    uint public totalDeposits = 0;
    
    function withdraw(uint amount) public{
        msg.sender.transfer(amount);
    }
    
    function deposit() public payable{
        deposits[msg.sender] = deposits[msg.sender] + msg.value;
        totalDeposits = totalDeposits + msg.value;
    }
    
    function contractBalance() public view returns (uint){
        return address(this).balance;
    }
}