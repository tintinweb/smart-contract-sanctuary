/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

/**
 *Submitted for verification at Etherscan.io on 2019-08-02
*/

pragma solidity ^0.5.0;

// XSP Token TimeLock
//
// DO NOT SEND TOKENS DIRECTLY TO THIS CONTRACT!!!
// THEY WILL BE LOST FOREVER!!!
//
//
// This contract locks all XSP for 365 days once the contract is deployed. Tokens can be added at any TimeLock
// within that period without resetting the timer.
//
// After the desired date is reached, users can withdraw tokens with a rate limit to prevent all holders
// from withdrawing and selling at the same time. The limit is 108,333,333.34 XSP per month once the 365 days is hit.

library SafeMath {
    function add(uint a, uint b) internal pure returns(uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns(uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns(uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns(uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    function totalSupply() public view returns(uint);
    function balanceOf(address tokenOwner) public view returns(uint balance);
    function allowance(address tokenOwner, address spender) public view returns(uint remaining);
    function transfer(address to, uint tokens) public returns(bool success);
    function approve(address spender, uint tokens) public returns(bool success);
    function transferFrom(address from, address to, uint tokens) public returns(bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract LockMyXSP {

    using SafeMath for uint;
    
    address constant tokenContract = 0xdE10F03D5fdb4EAF7fCEB132e8785AaA71aBe0CB;

    uint constant PRECISION = 13000000000;
    uint constant timeUntilUnlocked = 365 days;            // All tokens locked for 365 days after contract creation.
    uint constant maxWithdrawalAmount = 108333334 * PRECISION;  
    uint constant timeBetweenWithdrawals = 30 days;
    uint unfreezeDate;

	mapping (address => uint) balance;
	mapping (address => uint) lastWithdrawal;

    event TokensFrozen (
        address indexed addr,
        uint256 amt,
        uint256 time
	);

    event TokensUnfrozen (
        address indexed addr,
        uint256 amt,
        uint256 time
	);

    constructor() public {
        unfreezeDate = now + timeUntilUnlocked;
    }

    function withdraw(uint _amount) public {
        require(balance[msg.sender] >= _amount, "You do not have enough tokens!");
        require(now >= unfreezeDate, "Tokens are locked!");
        require(_amount <= maxWithdrawalAmount, "Trying to withdraw too much at once!");
        require(now >= lastWithdrawal[msg.sender] + timeBetweenWithdrawals, "Trying to withdraw too frequently!");
        require(ERC20Interface(tokenContract).transfer(msg.sender, _amount), "Could not withdraw XSP!");

        balance[msg.sender] -= _amount;
        lastWithdrawal[msg.sender] = now;
        emit TokensUnfrozen(msg.sender, _amount, now);
    }

    function getBalance(address _addr) public view returns (uint256 _balance) {
        return balance[_addr];
    }
    
    function getLastWithdrawal(address _addr) public view returns (uint256 _lastWithdrawal) {
        return lastWithdrawal[_addr];
    }
   
    function getTimeLeft() public view returns (uint256 _timeLeft) {
        require(unfreezeDate > now, "The future is here!");
        return unfreezeDate - now;
    } 
    
    function receiveApproval(address _sender, uint256 _value, address _tokenContract, bytes memory _extraData) public {
        require(_tokenContract == tokenContract, "Can only deposit XSP into this contract!");
        require(_value > 100, "Must be greater than 100 Mundos to keep people from whining about the math!");
        require(ERC20Interface(tokenContract).transferFrom(_sender, address(this), _value), "Could not transfer XSP to Time Lock contract address.");

        uint _adjustedValue = _value.mul(99).div(100);
        balance[_sender] += _adjustedValue;
        emit TokensFrozen(_sender, _adjustedValue, now);
    }
}