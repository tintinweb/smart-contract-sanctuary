pragma solidity ^0.4.13;

// Check balances for multiple ERC20 tokens in 1 batched request
// address 0x0 is used to indicate ETH
// Based on DeltaBalances 0x3e25f0ba291f202188ae9bda3004a7b3a803599a

// Exchange contract Interface
contract Exchange {
  function balanceOf(address /*token*/, address /*user*/) public constant returns (uint);
}

// ERC20 contract interface
contract Token {
  function balanceOf(address /*tokenOwner*/) public constant returns (uint /*balance*/);
  function transfer(address /*to*/, uint /*tokens*/) public returns (bool /*success*/);
}

contract TokenStoreBalances {

  // Fallback function, don&#39;t accept any ETH
  function() public payable {
    revert();
  }

 /* Check the token balance of a wallet in a token contract
    Avoids possible errors:
    - returns 0 on invalid exchange contract
    - return 0 on non-contract address

    Mainly for internal use, but public for anyone who thinks it is useful    */
  function tokenBalance(address user, address token) public constant returns (uint) {
    // check if token is actually a contract
    uint256 tokenCode;
    assembly { tokenCode := extcodesize(token) } // contract code size

   // is it a contract and does it implement balanceOf
    if(tokenCode > 0 && token.call(bytes4(0x70a08231), user)) {    // bytes4(keccak256("balanceOf(address)")) == bytes4(0x70a08231)
      return Token(token).balanceOf(user);
    } else {
      return 0; // not a valid token, return 0 instead of error
    }
  }

 /* get both exchange and wallet balances for multiple tokens
    Possible error throws:
        - extremely large arrays (gas cost too high)

    Returns array of token balances in wei units, 2* input length.
    even index [0] is exchange balance, odd [1] is wallet balance
    [tok0ex, tok0, tok1ex, tok1, .. ] */
  function allBalances(address exchange, address user, address[] tokens) external constant returns (uint[]) {
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