// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// ERC20 contract interface
interface Token {
  function balanceOf(address) external view returns (uint256);
  function lockedBalanceOf(address) external view returns (uint256);
}

contract LockedBalanceChecker {
  /* Fallback function, don't accept any ETH */
  fallback () external payable {
    revert("no payments");
  }
	/*
    Check the token balance of a wallet in a token contract

    Returns the balance of the token for user. Avoids possible errors:
      - return 0 on non-contract address
      - returns 0 if the contract doesn't implement balanceOf
  */
	function tokenBalance(address user, address token) public view returns (uint) {
    // check if token is actually a contract
    uint256 tokenCode;
    assembly { tokenCode := extcodesize(token) } // contract code size

    // is it a contract and does it implement balanceOf
    if (tokenCode > 0) {
      return Token(token).balanceOf(user);
    } else {
      return 0;
    }
  }
	function lockedTokenBalance(address user, address token) public view returns (uint) {
		// check if token is actually a contract
		uint256 tokenCode;
		assembly { tokenCode := extcodesize(token) } // contract code size

		// is it a contract and does it implement balanceOf
		if (tokenCode > 0) {
			return Token(token).lockedBalanceOf(user);
		} else {
			return 0;
		}
	}

  /*
    Check the token balances of a wallet for multiple tokens.
    Pass 0x0 as a "token" address to get ETH balance.

    Possible error throws:
      - extremely large arrays for user and or tokens (gas cost too high)

    Returns a one-dimensional that's user.length * tokens.length long. The
    array is ordered by all of the 0th users token balances, then the 1th
    user, and so on.
  */
  function balances(address[] memory users, address[] memory tokens) external view returns (uint[] memory) {
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
	function lockedBalances(address[] memory users, address token) external view returns (uint[] memory) {
		uint[] memory addrBalances = new uint[](users.length);
		for(uint i = 0; i < users.length; i++) {
				addrBalances[i] = lockedTokenBalance(users[i], token);
		}
		return addrBalances;
	}

}