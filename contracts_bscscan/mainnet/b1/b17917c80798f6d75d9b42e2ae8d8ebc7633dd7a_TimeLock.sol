/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract TimeLock {
    IERC20 token;
    address payable owner;
    uint public dateDeposited;
    uint public firstReleaseDate;
    uint public releaseCounter;
    uint public releaseInterval;
    bool firstReleaseCompleted;
    address payable payee1;
    address payable payee2;
    address payable payee3;
    address payable payee4;
    address payable payee5;
    address payable payee6;
    address payable payee7;
    address payable payee8;
    address payable payee9;
    uint256 public firstReleaseAmount;
    uint256 public weeklyReleaseAmount;
    
    event Deposit(address sender, uint amount, uint firstReleaseDate);   
    event Withdrawal(address receiver, uint amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address tokenContract) public {
        token = IERC20(tokenContract);
        owner = msg.sender;
        payee1 = 0xbCae0FD3538744FB6902AF60f1C82a73F82646f0;
        payee2 = 0xfC73BA9E39cEaD06B8AEa28dEF458CA63884c498;
        payee3 = 0x5f20E0d8d42AFD31Ea00dCD5F6589eF951489CCE;
        payee4 = 0xcEDf6E3929F0daffdF3afF93349396cbC80c0034;
        payee5 = 0xB29A26502955d9620307cb0df824e40c7f7B4ab7;
	payee6 = 0xE8684A9E05f9Eb158907400FE16b1F261640C188;
	payee7 = 0x125C1675B1A8c3b5fCa1c3A0770Fee89650a05Ae;
	payee8 = 0xDfE6054026cfD499CA79CfF87B887ad7362f43b1;
	payee9 = 0x1F5eF50e946976f556c6A01602e8FC00d64AD8b3;
    }

    function deposit(uint amount, uint _firstReleaseDate) public returns(bool success) {
        require(token.transferFrom(msg.sender, address(this), amount));
        firstReleaseDate = _firstReleaseDate;
        releaseCounter = 1;
        releaseInterval = 7;
        firstReleaseCompleted = false;
        firstReleaseAmount = 800000000000000000000;
        weeklyReleaseAmount = 100000000000000000000;
        emit Deposit(msg.sender, amount, _firstReleaseDate);
        return true;
    }

    function withdraw() onlyOwner public returns(bool success) {
        if(!firstReleaseCompleted && block.timestamp > firstReleaseDate){
            if(token.balanceOf(address(this)) < firstReleaseAmount){
                revert();
            }
            token.transfer(payee1, firstReleaseAmount/9);
            token.transfer(payee2, firstReleaseAmount/9);
            token.transfer(payee3, firstReleaseAmount/9);
            token.transfer(payee4, firstReleaseAmount/9);
            token.transfer(payee5, firstReleaseAmount/9);
	    token.transfer(payee6, firstReleaseAmount/9);
            token.transfer(payee7, firstReleaseAmount/9);
	    token.transfer(payee8, firstReleaseAmount/9);
	    token.transfer(payee9, firstReleaseAmount/9);
            emit Withdrawal(payee1, firstReleaseAmount/9);
            emit Withdrawal(payee2, firstReleaseAmount/9);
            emit Withdrawal(payee3, firstReleaseAmount/9);
            emit Withdrawal(payee4, firstReleaseAmount/9);
            emit Withdrawal(payee5, firstReleaseAmount/9);
	    emit Withdrawal(payee6, firstReleaseAmount/9);
	    emit Withdrawal(payee7, firstReleaseAmount/9);
	    emit Withdrawal(payee8, firstReleaseAmount/9); 
            emit Withdrawal(payee9, firstReleaseAmount/9);
            firstReleaseCompleted = true;
        }
        else{
            if(token.balanceOf(address(this)) < weeklyReleaseAmount){
                revert();
            }
            uint addedTime = releaseInterval * releaseCounter;
            if(block.timestamp >= firstReleaseDate + addedTime * 24 * 60 * 60){
                token.transfer(payee1, weeklyReleaseAmount/9);
                token.transfer(payee2, weeklyReleaseAmount/9);
                token.transfer(payee3, weeklyReleaseAmount/9);
                token.transfer(payee4, weeklyReleaseAmount/9);
                token.transfer(payee5, weeklyReleaseAmount/9);
		token.transfer(payee6, weeklyReleaseAmount/9);
		token.transfer(payee7, weeklyReleaseAmount/9);
		token.transfer(payee8, weeklyReleaseAmount/9);
		token.transfer(payee9, weeklyReleaseAmount/9);
                emit Withdrawal(payee1, weeklyReleaseAmount/9);
                emit Withdrawal(payee2, weeklyReleaseAmount/9);
                emit Withdrawal(payee3, weeklyReleaseAmount/9);
                emit Withdrawal(payee4, weeklyReleaseAmount/9);
                emit Withdrawal(payee5, weeklyReleaseAmount/9);
		emit Withdrawal(payee6, weeklyReleaseAmount/9);
		emit Withdrawal(payee7, weeklyReleaseAmount/9);
		emit Withdrawal(payee8, weeklyReleaseAmount/9);
		emit Withdrawal(payee9, weeklyReleaseAmount/9);
                releaseCounter = releaseCounter + 1;
            }
        }
        
        return true;
    }    

}