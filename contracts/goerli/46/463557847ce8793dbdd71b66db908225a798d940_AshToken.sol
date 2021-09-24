/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract AshToken {

    string public constant name = "Ash Token";
    string public constant symbol = "ASH";
    uint8 public constant decimals = 9;
    uint256 supply;
    uint256 public scale; 
    
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    using SafeMath for uint256;
    
    constructor() {
        supply = 0;
        scale = block.basefee;
    }
    
    function totalSupply() public view returns (uint256) {
        return supply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }
    
    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    function allowance(address owner, address delegate) public view returns (uint256) {
        return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
        
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function mint() public {
        uint256 minted = calculateMint(block.basefee);
        
        balances[msg.sender] = balances[msg.sender].add(minted);
        supply = supply.add(minted);
        
        scale = calculateNewScale(block.basefee);
    }
    
    function calculateMint(uint256 basefee) public view returns (uint256) {
        if(basefee < scale) {
            return scale;
        }

        return basefee.mul(basefee).div(scale);
    }
    
    function calculateNewScale(uint256 basefee) public view returns (uint256) {
        uint256 limit;
        
        if(basefee > scale) {
            limit = scale.mul(12).div(10);
            
            if(basefee > limit) {
                return limit;
            }
        } else {
            limit = scale.mul(8).div(10);

            if(basefee < limit) {
                return limit;
            }
        }
        
        return basefee;
    }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

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