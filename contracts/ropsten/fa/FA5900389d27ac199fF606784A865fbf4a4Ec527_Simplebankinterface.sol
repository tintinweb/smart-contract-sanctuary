/**
 *Submitted for verification at Etherscan.io on 2021-08-29
*/

pragma solidity 0.5.16;

interface bankrequirements {
    function deposit() external payable;
    function withdraw(uint amount) external returns(string memory);
}

contract Simplebankinterface is bankrequirements {
    
    event edeposit(address from, uint value); // makes an event that will emit whenever someone deposits value
    event ewithdraw(address to, uint value); // makes an event that will emit whenvere someones withdraws value
    
    mapping(address=> uint) public deposits;
    uint public totalDeposits = 0;
    
    function deposit() public payable { //allows users to deposit value and adds that info to an array "deposits"
        require(msg.value > 0, "your deposit amount must be greater than zero");
        deposits[msg.sender] = deposits[msg.sender] + msg.value;
        totalDeposits = totalDeposits + msg.value;
        emit edeposit(msg.sender, msg.value); // emits an event that shows who deposited and how much they deposited
    }
    
    function contractBalance() public view returns (uint){ //gets contracts balance
        return address(this).balance;
    }
    
    function userBalance(address _user) public view returns (uint){ //gets users balance
        return address(_user).balance;
    }
    
    function withdraw(uint amount) public returns(string memory){ //checks if the user has enough funds to withdraw and then sends their funds after subtracting from their total deposits and updating totalDeposits
            require(amount <= deposits[msg.sender], "insufficient funds");
            deposits[msg.sender] -= amount;
            totalDeposits -= amount;
            msg.sender.transfer(amount);
            emit ewithdraw(msg.sender, amount); //emits an event that shows who withdrew and how much value was withdrawn 

    } 
}