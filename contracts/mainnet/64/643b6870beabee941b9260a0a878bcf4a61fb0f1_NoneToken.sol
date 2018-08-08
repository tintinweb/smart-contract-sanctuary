pragma solidity ^0.4.23;

/**
 * @title NoneToken - ERC-20 token with a totalSupply of 0
 * @author ligi <ligi@ethereum.org>
 *
 * Source + Context:
 * https://github.com/walleth/contracts/NoneToken
 *
 */

contract NoneToken {

    /// @return The balance (always 0 in our case)
    function balanceOf(address) public pure returns (uint256) {
        return 0;
    }

    /// @return Whether the transfer was successful or not (hint: it is not :)
    function transfer(address, uint256) public pure returns (bool) {
        return false; // there are no tokens so there can be no transfer
    }

    /// @return Whether the transfer was successful or not (hint: it is not :)
    function transferFrom(address, address , uint256 ) public pure returns (bool) {
       return false;  // there are no tokens so there can be no transfer
    }

    /// @return Whether the approval was successful or not (hint: it is not :)
    function approve(address, uint256) public pure returns (bool) {
        return false;
    }

    /// @return Amount of remaining tokens allowed to spent (always 0 in our case)
    function allowance(address, address) public pure returns (uint256) {
      return 0;
    }

    /// @return total amount of tokens (0 in our case)
    function totalSupply() public pure returns (uint256) {
      return 0;
    }

    /// @return the name of the token
    function name() public pure returns (string) {
      return "None";
    }

    /// @return the symbol of the token
    function symbol() public pure returns (string) {
      return "NONE";
    }

    /// @return the amount of decimals for the token (0 in our case)
    function decimals() public pure returns (uint8) {
      return 0;
    }

}