/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

//Safe Math Interface

contract SafeMath {

    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


//ERC Token Standard #20 Interface

abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract VHUEStak is SafeMath {
    address owner;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event ContractCreate(string contractName, address owner);
    event StartStake(address staker);
    event RedeemStake(address staker);

    struct StakeTemplate {
        string name;
        uint256 secs;
        uint256 mins;
        uint256 dayz;
        uint256 weekz;
        uint256 aprNumerator;
        uint256 aprDenominator;
        uint256 minimumDSCInvestment;
        string [] otherRewards;
        bool isActive;
        uint256 expirationTimestamp;
        bool isWhitelisted;
    }

   struct Stake {
        string name;
        uint256 secs;
        uint256 mins;
        uint256 dayz;
        uint256 weekz;
        uint256 aprNumerator;
        uint256 aprDenominator;
        uint256 minimumDSCInvestment;
        string [] otherRewards;
        bool isActive;
        uint256 expirationTimestamp;
        bool isWhitelisted;
    }

    string contractName;
 
    constructor() {
        contractName = "Vivihue Staking";
        //one mbllion tokens, dividable to 0.000001
        owner = msg.sender;
        emit ContractCreate(contractName, owner);
    }

}