/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

// ERC20 contract interface
abstract contract Token {
    function balanceOf(address) public view virtual returns (uint256);
}

contract BalanceChecker {
    /* Check the token balance of a wallet in a token contract
    Returns the balance of the token for user. Avoids possible errors:
      - return 0 on non-contract address */
    function tokenBalance(address user, address token)
        public
        view
        returns (uint256)
    {
        // check if token is actually a contract
        uint256 tokenCode;
        assembly {
            tokenCode := extcodesize(token)
        }
        return tokenCode > 0 ? Token(token).balanceOf(user) : 0;
    }

    /* Check the token balances of a wallet for multiple tokens.
    Possible error throws:
      - extremely large arrays for user and or tokens (gas cost too high) 
    Returns a one-dimensional that's user.length * tokens.length long. The
    array is ordered by all of the 0th users token balances, then the 1th
    user, and so on. */
    function balances(address[] memory users, address[] memory tokens)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory addrBalances = new uint256[](
            tokens.length * users.length
        );
        for (uint256 i = 0; i < users.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                uint256 addrIdx = j + tokens.length * i;
                addrBalances[addrIdx] = tokenBalance(users[i], tokens[j]);
            }
        }
        return addrBalances;
    }
}