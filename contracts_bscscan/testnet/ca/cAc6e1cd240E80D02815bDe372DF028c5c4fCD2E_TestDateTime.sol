/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

// https://testnet.bscscan.com
//https://solidity-by-example.org/sending-ether/
//decimal variable not supported in solidity
//1.57 ETH is basically 1570000000000000000 Wei (decimal=18)
// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;
//pragma solidity ^0.4.23; //any version above 0.4.23

contract TestDateTime {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint timestamp;
    uint public year_last;
    uint public year_now;
    uint public month_now;
    uint public day_now;
    

    address payable public owner;
    address payable public recipient;   // The account receiving the payments.
    uint256 public withdrawn_amount;   // How much the recipient has already withdrawn.
    

    constructor() { //execute once only during deployment to set owner to the wallet address which deploy this contract
    
    owner = payable(msg.sender);
    recipient = payable(0xc496Eaa1cFb09214F3d3803cC3C11d40053b5a46); //Metamask wallet address
    withdrawn_amount = 0;
    }

    modifier max_amount(uint _maxamount) { //modifier will append the code below to function that call it
    require(msg.value <= _maxamount, "Your amount is over the max of 1ETH.");
    _;
    }

    function deposit() external payable max_amount(1 ether / 2) {  //external function is callable from outside of code but not from inside      
        //recipient.transfer(70000000000000000 wei); //transfer to recipient wallet address with value 0.07 ether
        
        //recipient.transfer(msg.value); //message.value from remix textbox above Deploy button
        (bool sent, bytes memory data) = recipient.call{value: 70000000000000000 wei}("");
    }

       
    // Function to receive Ether. msg.data must be empty
    receive() external payable { //deposit into smart contract address
        //require(msg.value == amount);
        msg.value; //do nothing=default to accept the ether into smart contract address
        
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(uint256 amountAuthorized) public {//public=outside and inside code can call this func, internal=inside code can run only
        require(msg.sender == recipient, "Wrong wallet connected"); //recipient wallet address must match as defined abve        
        require(test(), "You have exceeded 1 withdrawal limit per year");
        // Make sure there's something to withdraw (guards against underflow)
        //require(amountAuthorized > withdrawn_amount);
        uint256 amountToWithdraw = amountAuthorized; //- withdrawn_amount;

        withdrawn_amount += amountToWithdraw;
        //msg.sender.transfer(amountToWithdraw); 
        recipient.transfer(amountToWithdraw); 
    }

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function getYearInternal(uint _timestamp) internal pure returns (uint year, uint month, uint day) {            
            //uint month;
            //uint day;
            (year, month, day) = _daysToDate(_timestamp / SECONDS_PER_DAY);
        }
    

    event YearGreater(uint256 timestamp);//generate event in blockchain Logs
    event YearLess(uint256 timestamp);//generate event in blockchain Logs

    function test() public returns (bool) {
        timestamp = block.timestamp;
        (year_now, month_now, day_now) = getYearInternal(timestamp);
        
        if (year_now > year_last ) {
            emit YearGreater(block.timestamp); //generate blockchain Logs
            year_last = year_now;
            return true;
        }
        else if (year_now < year_last) {
            emit YearLess(block.timestamp); //generate blockchain Logs
            return false;
        }

    }

    // Fallback function is called when msg.data is not empty
    fallback () external payable { //fallback default function call by metamask send to contract address
        //recipient.transfer(msg.value); //message.value from remix textbox above Deploy button
        msg.value;  //do nothing=default to accept the ether into smart contract address
    }
    
}