/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identfier: MIT
pragma solidity ^0.7.6;

contract FortKnox {
    uint public matures;
    uint public balance;
    uint public amountIn;
    uint public amountOut;
    uint public amountDeposited;
    uint public amountToppedUp;
    uint public amountTransferred;
    uint public amountWithdrawn;
    uint public toppedUp = 0;
    uint public transferredIn = 0;

    constructor(uint _timeToMaturity) public payable { 
        matures = block.timestamp + _timeToMaturity;
        (msg.sender).transfer(amountDeposited);
        amountDeposited = msg.value;
        amountIn = msg.value;
        balance += msg.value;
    }
    
    receive() payable external{
        require(transferredIn == 0, "Transferred In Already");
        amountTransferred = msg.value;
        amountIn += msg.value;
        balance += msg.value;
        transferredIn = 1;
    }
    
    function topUp() public payable {
        require(toppedUp == 0, "Topped Up Already"); 
        (msg.sender).transfer(amountToppedUp);
        amountToppedUp = msg.value;
        amountIn += msg.value;
        balance += msg.value;
        toppedUp = 1;
    }
    
    function withdraw(uint _amountWithdrawn, address payable _destAddr) public payable {
        amountWithdrawn = _amountWithdrawn;
        require(msg.sender == _destAddr, "Request UnAuthorised");
        require(block.timestamp >= matures, 'Request Before Maturity');
        _destAddr.transfer(_amountWithdrawn);
        amountOut += amountWithdrawn;
        balance -= amountWithdrawn; 
    }
}