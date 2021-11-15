//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./CryptoStamp.sol";

contract CryptoStampEthereum is CryptoStamp {
  address public predicateProxy;

  function initialize(string calldata _uri, address _predicateProxy) external initializer {
    CryptoStamp.initialize(_uri);
    predicateProxy = _predicateProxy;
  }

  /**
   * @notice See definition of `_mint` in ERC1155 contract
   */
  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) public override {
    require(msg.sender == owner() || msg.sender == predicateProxy, "Only admin or polygon minter can mint new tokens");
    _mint(account, id, amount, data);
  }

  /**
   * @notice See definition of `_mintBatch` in ERC1155 contract
   */
  function mintBatch(
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) public override {
    require(msg.sender == owner() || msg.sender == predicateProxy, "Only admin or polygon minter can mint new tokens");
    _mintBatch(to, ids, amounts, data);
  }
}