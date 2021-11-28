//SourceUnit: trxPrimeLive.sol

// SPDX-License-Identifier: none
pragma solidity ^0.8.6;

contract Trxprime {
    
    struct Investor {
        bool registered;
        uint invested;
        uint investedAt;
        uint setWithdrawable;
        uint donateAmt;
    }
    
    address public owner = msg.sender;
    address public withdrawSetter;
    address contractAddr = address(this);
    uint public totalInvestors;
    mapping(address => Investor) investor;
    event PriceSetterChanged(address user);
    event OwnershipTransferred(address);
    event UserRegistered(address user);
    event Received(address, uint);

    function deposit() public payable returns (bool) {
        address user = msg.sender;
        uint amount = msg.value;
        require(amount >= 100000000, "Amount less than 100 TRX");
        investor[user].invested = amount;
        registerUser(user);
        return true;
    }
    
    function reinvest(uint amount) internal {
        investor[msg.sender].invested = amount;
    }
    
    function registerUser(address user) internal {
        if( !investor[user].registered ) {
            investor[msg.sender].registered = true;
            investor[msg.sender].investedAt = block.timestamp;
            totalInvestors++;   
        }
        emit UserRegistered(user);
    }
    
    function setWithdrawSetter(address user) public {  
        require(msg.sender == owner);
        withdrawSetter = user;
        emit PriceSetterChanged(withdrawSetter);
    }
    
    function userWithdrawable(address user, uint amount) public {
        require(msg.sender == owner || msg.sender == withdrawSetter, "You don't have permission");
        require(investor[user].registered = true, "User has not registered");
        investor[user].setWithdrawable = amount;
    }
    
    function withdraw(address payable to) public returns (bool) {
        require(investor[msg.sender].registered = true, "User not registered yet");
        to = payable(msg.sender);
        uint amount = investor[msg.sender].setWithdrawable;
       // uint halfAmt = amount / 2;
        to.transfer(amount);
        ///reinvest(halfAmt);
        investor[msg.sender].invested = investor[msg.sender].invested - amount;
        investor[msg.sender].setWithdrawable = 0;
        return true;
    }
    
    function ownerTrxWithdraw(uint amount) public returns (bool) {
        require(msg.sender == owner, "Only owner");
        address payable to = payable(msg.sender);
        to.transfer(amount);
        return true;
    }
    
    function showWithdrawableAmount(address user) public view returns (uint) {
        uint withdrawableAmount = investor[user].setWithdrawable;
        return withdrawableAmount;
    }
    
    function transferOwnership(address to) public {
        require(msg.sender == owner, "Only owner");
        owner = to;
        emit OwnershipTransferred(to);
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}