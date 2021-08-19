/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

pragma solidity 0.5.16;

contract FirstProject {
    
    mapping(address=> uint) public deposits;
    uint public totalDeposits = 0;
    
    function deposit() public payable { //allows users to deposit value and adds that info to an array "deposits"
       deposits[msg.sender] = deposits[msg.sender] + msg.value;
       totalDeposits = totalDeposits + msg.value;
    }
    
    function contractBalance() public view returns (uint){ //gets contracts balance
        return address(this).balance;
    }
    
    function userBalance(address _user) public view returns (uint){ //gets users balance
        return address(_user).balance;
    }
    
    function withdraw(uint amount) public returns(string memory){ //checks if the user has enough funds to withdraw and then sends their funds after subtracting from their total deposits
        if( amount <= deposits[msg.sender]){
            deposits[msg.sender] -= amount;
            msg.sender.transfer(amount);
        }
        else{
            return "insufficient funds";
        }
    } 
}