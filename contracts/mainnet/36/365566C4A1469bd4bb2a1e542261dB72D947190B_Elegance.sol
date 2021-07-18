pragma solidity ^0.4.23;

import "./Token.sol";

/**
 * @dev This is the smart contract implementation of Elegance coin.
 */
contract Elegance is Token {

  constructor()
    public
  {
    tokenName = "Elegance";
    tokenSymbol = "LGX";
    tokenDecimals = 18;
    tokenTotalSupply = 100000000000000000000000000;
    balances[msg.sender] = tokenTotalSupply;
  }
}