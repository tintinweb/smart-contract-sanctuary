/**
 *Submitted for verification at BscScan.com on 2021-07-30
*/

// SPDX-License-Identifier: MIT
   


pragma solidity ^0.4.25;


contract Token {
    
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function transfer(address to, uint256 value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    function approve(address spender, uint256 value) public returns (bool);
    
}

contract networkpool {

    function donatePool(uint amount) public returns (uint256);
    function buy(uint buy_amount) public returns (uint256);
    function balanceOf(address _customerAddress) public view returns (uint256);
    function transfer(address _toAddress, uint256 _amountOfTokens) public returns (bool);
    
}




/*
 * @dev Stack is a perpetual rewards contract the collects 8% fee on buys/sells for a dividend pool that drips 2% daily.
 * A 2% fee is paid instantly to token holders on buys/sells as well
*/


contract networkPoolProxy  {

    uint256 public constant MAX_UINT = 2**256 - 1;

    address public tokenAddress;

    address public stackAddress;

    networkpool private stack;

    Token private token;


    /*=======================================
    =            PUBLIC FUNCTIONS           =
    =======================================*/

    constructor(address _tokenAddress, address _stackAddress) public {

        tokenAddress = _tokenAddress;
        token = Token(_tokenAddress);

        stackAddress = _stackAddress;
        stack = networkpool(_stackAddress);

    }


    /// @dev This is how you pump pure "drip" dividends into the system
    function donatePool(uint amount) public returns (uint256) {
        require(token.transferFrom(msg.sender, address(this),amount));

        //any residual tokens from a previous tx will be captured in addition to the transfer
        uint _balance = token.balanceOf(address(this));

        //approve tokens to move
        token.approve(stackAddress, _balance);

        return stack.donatePool(_balance);
    }

    /// @dev Converts all incoming eth to tokens for the caller, and passes down the referral addy (if any)
    function buy(uint _buy_amount) public returns (uint256)  {
        return buyFor(msg.sender, _buy_amount);
    }


    /// @dev Converts all incoming eth to tokens for the caller, and passes down the referral addy (if any)
    function buyFor(address _customerAddress, uint _buy_amount) public returns (uint256)  {
        
        //zero check
        require(_buy_amount > 0, "amount must be greater than zero");

        //approval and proper balance required.  USE SENDER'S TOKENS
        require(token.transferFrom(msg.sender, address(this), _buy_amount), "sender requires adequate balance and approvals");
        
        //any residual tokens from a previous tx will be captured in addition to the transfer
        uint _balance = token.balanceOf(address(this));

        //approve tokens to move
        token.approve(stackAddress, _balance);

        //buy tokens
        stack.buy(_balance);

        //get the balance
        uint _stack_balance = stack.balanceOf(address(this));

        //transfer balance 
        require(stack.transfer(_customerAddress, _stack_balance), "Stack transfer failed");


        return _stack_balance;
    }




    /**
     * @dev Fallback function to return any TRX/ETH/BNB accidentally sent to the contract
     */
    function() payable public {
        require(false);
    }

   

}