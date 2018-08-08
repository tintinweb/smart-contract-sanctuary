pragma solidity ^0.4.21;

/* 
    Contract for DeltaBalances.github.io V2
    Check balances for multiple ERC20 tokens in 1 batched request.
    For the previous version, see 0x3150954EAE1a8a5e5EE1F1B8E8444Fe16EA9F94C
    
    // address 0x0 is used to indicate ETH
*/

// Exchange contract Interface for EtherDelta and forks
contract Exchange {
  function balanceOf(address /*token*/, address /*user*/) public view returns (uint);
}

// ERC20 contract interface
contract Token {
  function balanceOf(address /*tokenOwner*/) public view returns (uint /*balance*/);
  function transfer(address /*to*/, uint /*tokens*/) public returns (bool /*success*/);
}

contract DeltaBalances {
    
  address public admin; 

  function DeltaBalances() public {
    admin = msg.sender;
  }

  // Fallback function, don&#39;t accept any ETH
  function() public payable {
    revert();
  }

  // Limit withdrawals to the contract creator
  modifier isAdmin() {
    require(msg.sender == admin);
    _;
  }

  // Backup withdraw, in case ETH gets in here
  function withdraw() external isAdmin {
    admin.transfer(address(this).balance);
  }

  // Backup withdraw, in case ERC20 tokens get in here
  function withdrawToken(address token, uint amount) external isAdmin {
    require(token != address(0x0) && Token(token).transfer(msg.sender, amount));
  }

  /* Get multiple token balances on EtherDelta (or similar exchange)
    Possible error throws:
        - invalid exchange contract 
        - using an extremely large array (gas cost too high?)
        
    Returns array of token balances in wei units. */
  function deltaBalances(address exchange, address user,  address[] tokens) external view returns (uint[]) {
    Exchange ex = Exchange(exchange);
    uint[] memory balances = new uint[](tokens.length);
    
    for(uint i = 0; i < tokens.length; i++) {
      balances[i] = ex.balanceOf(tokens[i], user);
    }    
    return balances;
  }

  /* Get multiple token balances on EtherDelta (or similar exchange)
    Possible error throws:
        - invalid exchange contract 
        - using extremely large arrays (gas cost too high?)
        
    Returns array of token balances in wei units.
    Balances in token-first order [token0ex0, token0ex1, token0ex2, token1ex0, token1ex1 ...] */
  function multiDeltaBalances(address[] exchanges, address user,  address[] tokens) external view returns (uint[]) {
    uint[] memory balances = new uint[](tokens.length * exchanges.length);
    
    for(uint i = 0; i < exchanges.length; i++) {
      Exchange ex = Exchange(exchanges[i]);
        
      for(uint j = 0; j < tokens.length; j++) {
        balances[(j * exchanges.length) + i] = ex.balanceOf(tokens[j], user);
      }
    }
    return balances;
  }

 /* Check the token balance of a wallet in a token contract
    Avoids possible errors:
    - returns 0 on invalid exchange contract 
    - return 0 on non-contract address 
    
    Mainly for internal use, but public for anyone who thinks it is useful    */
  function tokenBalance(address user, address token) public view returns (uint) {
    // check if token is actually a contract
    uint256 tokenCode;
    assembly { tokenCode := extcodesize(token) } // contract code size
   
   // is it a contract and does it implement balanceOf
    if(tokenCode > 0 && token.call(bytes4(keccak256("balanceOf(address)")), user)) {
      return Token(token).balanceOf(user);
    } else {
      return 0; // not a valid token, return 0 instead of error
    }
  }

 /* Check the token balances of a wallet for multiple tokens
    Uses tokenBalance() to be able to return, even if a token isn&#39;t valid 
    Possible error throws:
        - extremely large arrays (gas cost too high) 
        
    Returns array of token balances in wei units. */
  function walletBalances(address user,  address[] tokens) external view returns (uint[]) {
    require(tokens.length > 0);
    uint[] memory balances = new uint[](tokens.length);
    
    for(uint i = 0; i < tokens.length; i++) {
      if(tokens[i] != address(0x0)) { 
        balances[i] = tokenBalance(user, tokens[i]);
      } else {
        balances[i] = user.balance; // ETH balance    
      }
    }    
    return balances;
  }

 /* Combine walletBalances() and deltaBalances() to get both exchange and wallet balances for multiple tokens.
    Possible error throws:
        - extremely large arrays (gas cost too high) 
        
    Returns array of token balances in wei units, 2* input length.
    even index [0] is exchange balance, odd [1] is wallet balance
    [tok0ex, tok0, tok1ex, tok1, .. ] */
  function allBalances(address exchange, address user,  address[] tokens) external view returns (uint[]) {
    Exchange ex = Exchange(exchange);
    uint[] memory balances = new uint[](tokens.length * 2);
    
    for(uint i = 0; i < tokens.length; i++) {
      uint j = i * 2;
      balances[j] = ex.balanceOf(tokens[i], user);
      if(tokens[i] != address(0x0)) {
        balances[j + 1] = tokenBalance(user, tokens[i]);
      } else {
        balances[j + 1] = user.balance; // ETH balance    
      }
    }
    return balances; 
  }
  
}