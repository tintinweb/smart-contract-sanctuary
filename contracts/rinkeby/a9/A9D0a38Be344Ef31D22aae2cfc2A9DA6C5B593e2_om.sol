/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract om {
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    using SafeMath for uint256;

    function senderInfo() public view returns (address) {
        return msg.sender;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
        // return tokenOwner.balance;
    }

    function approve(address delegate, uint numTokens) public  returns (bool) {
        emit Approval(msg.sender, delegate,  numTokens);
        return true;
    }
    
    function allowance(address owner, address delegate) public  view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        // require(numTokens <= balances[owner]);
        // require(numTokens <= allowed[owner][msg.sender]);
        // balances[owner] = balances[owner].sub(numTokens);
        // allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        // balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
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