//SourceUnit: Tronat.sol

// SPDX-License-Identifier: none
pragma solidity ^0.8.0;

contract Tronat {
    
    struct Investor {
        bool registered;
        uint investedAt;
        uint setWithdrawable;
        uint tariff;
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

    function deposit(uint tariffPlan) public payable returns (bool) {
        
        address user = msg.sender;
        uint amount = msg.value;
        
        require(amount >= 10000000, "Amount less than 10TRX");
        require(tariffPlan < 2, "Only two plans");
        
        if(investor[user].registered){
            if(investor[user].tariff == 0){
                if(tariffPlan == 1){
                    revert("Cannot change plans");
                }
            }
            else if(investor[user].tariff == 1){
                if(tariffPlan == 0){
                    revert("Cannot change plans");
                }
            }
        }
        
        investor[user].tariff = tariffPlan;
        registerUser(user);
        return true;
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
    
    function withdraw() public returns (bool) {
        require(investor[msg.sender].registered = true, "User not registered yet");
        address payable to = payable(msg.sender);
        uint amount = investor[to].setWithdrawable;
        to.transfer(amount);
        investor[to].setWithdrawable = 0;
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