/**
 *Submitted for verification at polygonscan.com on 2021-07-14
*/

// File: contracts/BalanceChecker.sol

pragma solidity ^0.6.0;

// ERC20 contract interface
abstract contract Token {
  function balanceOf(address) external virtual returns (uint);
  function blockedBalanceOf(address) external virtual returns (uint);
}

contract BalanceChecker {
  /**
   * @dev Check the token balance of a wallet in a token contract
   * @param user address of user from whom you need to fetch the balance of token
   * @param token address of token contract
   * Returns the balance of the token for user. Avoids possible errors:
      - return 0 on non-contract address 
      - returns 0 if the contract doesn't implement balanceOf
  */
  function tokenBalance(address user, address token) public returns (uint) {
    // check if token is actually a contract
    uint256 tokenCode;
    assembly { tokenCode := extcodesize(token) } // contract code size
  
    // is it a contract and does it implement balanceOf 
    (bool success, bytes memory data) = token.call(abi.encodeWithSignature("balanceOf(address)", user));
    if (tokenCode > 0 && success) {  
      return Token(token).balanceOf(user);
    } else {
      return 0;
    }
  }

  /**
   * @dev Check the token balances of a wallet for multiple tokens.
   * @param users array of addresses of users from whom you need to fetch the balance of tokens array.
   * @param tokens array of addresses of token contracts
   * @dev Pass 0x0 as a "token" address to get ETH balance.

   * Possible error throws:
      - extremely large arrays for user and or tokens (gas cost too high) 
          
   * Returns a one-dimensional that's user.length * tokens.length long. The
    array is ordered by all of the 0th users token balances, then the 1th
    user, and so on.
  */
  function balances(address[] calldata users, address[] calldata tokens) external returns (uint[] memory) {
    uint[] memory addrBalances = new uint[](tokens.length * users.length);
    
    for(uint i = 0; i < users.length; i++) {
      for (uint j = 0; j < tokens.length; j++) {
        uint addrIdx = j + tokens.length * i;
        if (tokens[j] != address(0x0)) { 
          addrBalances[addrIdx] = tokenBalance(users[i], tokens[j]);
        } else {
          addrBalances[addrIdx] = users[i].balance; // ETH balance    
        }
      }  
    }
  
    return addrBalances;
  }


  /*
    Checks the blocked balance of a wallet in a token contract

    Returns the balance of the token for user. Avoids possible errors:
      - return 0 on non-contract address 
      - returns 0 if the contract doesn't implement balanceOf
  */
  function blockedBalance(address user, address token) public returns (uint) {
    // check if token is actually a contract
    uint256 tokenCode;
    assembly { tokenCode := extcodesize(token) } // contract code size
  
    // is it a contract and does it implement balanceOf 
    (bool success, bytes memory data) = token.call(abi.encodeWithSignature("blockedBalanceOf(address)", user));
    if (tokenCode > 0 && success) {  
      return Token(token).blockedBalanceOf(user);
    } 
    else {
      return 0;
    }
  }

  /*
    Check the blocked balances of a wallet for multiple tokens.
    If the token address passed 0x0 , then we get ETH balance.

    Possible error throws:
      - extremely large arrays for user and or tokens (gas cost too high) 
          
    Returns a one-dimensional that's user.length * tokens.length long. The
    array is ordered by all of the 0th users token balances, then the 1th
    user, and so on.
  */

  function blockedBalances(address[] calldata users, address[] calldata tokens) external returns (uint[] memory) {
    uint[] memory addrBalances = new uint[](tokens.length * users.length);
    
    for(uint i = 0; i < users.length; i++) {
      for (uint j = 0; j < tokens.length; j++) {
        uint addrIdx = j + tokens.length * i;
        if (tokens[j] != address(0x0)) { 
          addrBalances[addrIdx] = blockedBalance(users[i], tokens[j]);
        } 
        else {
          addrBalances[addrIdx] = users[i].balance; // ETH balance    
        }
      }  
    }
  
    return addrBalances;
  }
}