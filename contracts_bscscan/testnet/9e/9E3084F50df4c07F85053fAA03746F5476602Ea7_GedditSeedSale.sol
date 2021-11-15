// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IWhitelist {
  function isWhitelisted(address investor) external view returns (bool);
}

contract GedditSeedSale {
  // The token being sold
  IWhitelist  _whitelist;

  constructor(IWhitelist whitelist){
    _whitelist = whitelist;
  }

  function iswhite(address a) public view returns (bool) {
    return IWhitelist(_whitelist).isWhitelisted(a);
  }

}

