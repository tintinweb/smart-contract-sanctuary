// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155Tradable.sol";

/**
 * @title MyCollectible
 * MyCollectible - a contract for my semi-fungible tokens.
 */
contract LoserDaoProposal is ERC1155Tradable {
  constructor(string memory _name, string memory _symbol, address _daoToken,address _lowbToken)
  ERC1155Tradable(
    _name,
    _symbol,
    _daoToken,
    _lowbToken
  ) {
  }

  function contractURI() public pure returns (string memory) {
    return "";
  }
}