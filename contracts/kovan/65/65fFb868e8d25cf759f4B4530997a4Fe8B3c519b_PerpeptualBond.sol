/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

    // @title company
    // @Credit to , kor, tot
    // @disclaimer, this code is for study propose only



/* 'contract' has similarities to 'class' in other languages (class variables,
inheritance, etc.) */
contract PerpeptualBond { // CamelCase
    // Declare state variables outside function, persist through life of contract

    // dictionary that maps addresses to balances
    
    //companyname
    string public companyName;
    
    //government bond yield 5 years
    uint public fixrate;
    
    // expected interest rate
    uint public rate1;
    uint public rate2;
    uint public rate3;
    uint public rate4;
    
     // period of pa
    uint public Period1;
    uint public Period2;
    uint public Period3;
    uint public Period4;
    
 
    //minimum amount requiremet
    uint public minimumamount;
    
    //Minimum Holding Period
    uint public minimumHoldingPeriod;
    
    mapping (address => uint256) private balances;
    
    
    // Users in system
    address[] accounts;
    // Owner of the system
    address public owner;
    // 'public' makes externally readable (not writeable) by users or contracts

    // Events - publicize actions to external listeners
    event principleMade(address indexed accountAddress, uint amount);
    event SellMade(address indexed accountAddress, uint amount);
    
    event SystemprincipleMade(address indexed admin, uint amount);
    event SystemSellMade(address indexed admin, uint amount);

    // Constructor, can receive one or many variables here; only one allowed
    constructor(string memory _companyName, uint _rate1,uint _rate2, uint _rate3, uint _rate4, uint _fixrate,uint _minimumamount, uint _minimumHoldingPeriod, 
    uint _Period1,uint _Period2, uint _Period3, uint _Period4) public {
        // msg provides details about the message that's sent to the contract
        // msg.sender is contract caller (address of contract creator)
        companyName = _companyName;
        rate1 = _rate1 ;
        rate2 = _rate2 + _fixrate;
        rate3 = _rate3 + _fixrate;
        rate4 = _rate4 + _fixrate;
        
        Period1 = now + _Period1 * 365 days;
        Period2 = Period1 + _Period2 * 365 days;
        Period3 = Period2 + _Period3 * 365 days;
        Period4 = Period3 + _Period4 * 365 days;
        
        minimumamount = _minimumamount ;
        minimumHoldingPeriod = now +  _minimumHoldingPeriod *365 days;
        owner = msg.sender;
        
    }
      /// check whether investor have engough money
     /// @notice principle ether into Company
    /// @return The balance of the user after the principle is made
    
    
    function principle() public payable returns (uint256) {
        // Record account in array for looping
        if (0 == balances[msg.sender]) {
            accounts.push(msg.sender);
            
        }
        
        balances[msg.sender] = balances[msg.sender] + msg.value;
        // no "this." or "self." required with state variable
        // all values set to data type's initial value by default

        // Broadcast principle event
        emit principleMade(msg.sender, msg.value); // fire event
        require (msg.value <= minimumamount, 'not have enough money sent');

        return balances[msg.sender];
    }

    /// @notice Sell ether from company
    /// @dev This does not return any excess ether sent to it
    /// @param SellAmount amount you want to Sell
    /// @return remainingBal The balance remaining for the user
        function Sell(uint SellAmount) public returns (uint256 remainingBal) {
        require (now < minimumHoldingPeriod, 'you have to hold this bond as per requiremet please kindly look at public data');
        require(balances[msg.sender] >= SellAmount, "Balance is not enough");
        balances[msg.sender] = balances[msg.sender] - SellAmount;

        // Revert on failed
        msg.sender.transfer(SellAmount);
        
        // Broadcast Sell event
        emit SellMade(msg.sender, SellAmount);
        
        return balances[msg.sender];
    }

    /// @notice Get balance
    /// @return The balance of the user
    // 'constant' prevents function from editing state variables;
    // allows function to run locally/off blockchain
    function balance() public view returns (uint256) {
        return balances[msg.sender];
    }
    
    // @notice Calculate Interests given user
    // @dev Internal use only
    // @param user user address in the system
    // @param _rate interest rate
    // @return Interest earned
    function calculateInterest(address user, uint256 _rate1, uint256 _rate2, uint256 _rate3, uint256 _rate4) private view returns(uint256) {
        if (now< Period1){
        uint256 interest = balances[user] * (_rate1 / 100);
        return interest;}
        
        else if (now < Period1 && now > Period2){
        uint256 interest = balances[user] * (_rate2 / 100);
        return interest;}
        
        else if (now < Period2 && now > Period3){
        uint256 interest = balances[user] * (_rate3/ 100);
        return interest;}
        
        else if (now < Period3 && now > Period4){
        uint256 interest = balances[user] * (_rate4 / 100);
        return interest;}
    }
    
    /// @notice Calculate Interests of all users combined
    /// @dev Public, anyone can lookup
    /// @return Interest earned of all users
   
    function totalInterestPerYear() external view returns(uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 interest = calculateInterest(account,rate1, rate2, rate3,rate4);
            total = total + interest;
        }
        
        return total;
    }
    
    /// @notice Give coupons to all users, caller must provide enough fund
    /// @dev Only owner can use
    function payCouponsPerYear() payable public {
        require(owner == msg.sender, "You are not authorized");
        uint256 totalInterest = 0;
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 interest = calculateInterest(account,rate1,rate2,rate3,rate4);
            balances[account] = balances[account] + interest;
            totalInterest = totalInterest + interest;
        }
        require(msg.value == totalInterest, "Not enough interest to pay!!");
    }
    
    /// @notice company system balance
    /// @return Balances of all users combined
    function systemBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    /// @notice principle ether into company
    /// @return The balance of the user after the principle is made
    function systemprinciple() public payable returns (uint256) {
        require(owner == msg.sender, "You are not authorized");

        // Broadcast principle event
        emit SystemprincipleMade(msg.sender, msg.value); // fire event

        return systemBalance();
    }
    
    /// @notice Sell ether from the system
    /// @param SellAmount amount you want to Sell
    /// @return remainingBal The balance remaining for the system
    function systemSell(uint SellAmount) public returns (uint256 remainingBal) {
        require(owner == msg.sender, "You are not authorized");
        require (now < minimumHoldingPeriod, 'Sorry, you have to hold this bond as per requirement please kindly look at public data');
        require(systemBalance() >= SellAmount, "System balance is not enough");

        // Revert on failed
        msg.sender.transfer(SellAmount);
        
        // Broadcast system Sell event
        emit SystemSellMade(msg.sender, SellAmount);
        
        return systemBalance();
    }
}