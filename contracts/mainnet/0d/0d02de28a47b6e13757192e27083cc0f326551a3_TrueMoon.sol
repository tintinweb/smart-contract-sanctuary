/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

/**
 * SPDX-License-Identifier: Unlicensed
*/

/*
 * TrueMoon-FRS (TRUE) Powered by DailyLaunchpad.io
 * 
 * There is 30% INCOME ( from FEE TICKETS ) you can generate FOREVER.
 * IF someone purchase with your REFerral link.
 *
 * For more information, you can join our tg group : https://t.me/dailylaunchpad
 *
 */
pragma solidity ^0.6.7;

contract TrueMoon {

    string public constant name = "TrueMoon-FRS";
    string public constant symbol = "TRUE";
    uint8 public constant decimals = 0;  
    uint256 constant totalSupply_ = 1000000000000000000;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    


    using SafeMath for uint256;


   constructor(address _poolAddr) public {  
    	balances[_poolAddr] = totalSupply_;
    	emit Transfer(address(0), _poolAddr, totalSupply_);
    }  

    function totalSupply() public pure returns (uint256) {
    	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        Transfer(owner, buyer, numTokens);
        return true;
    }
}

library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}