//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "./InactaNFT.sol";

contract InactaNFTEthereum is InactaNFT {
  bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

  function initialize(string calldata _uri, address _predicateProxy) external initializer {
    InactaNFT.initialize(_uri);
    _setupRole(PREDICATE_ROLE, _predicateProxy);
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
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(PREDICATE_ROLE, _msgSender()), "Only admin or polygon minter can mint new tokens");
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
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(PREDICATE_ROLE, _msgSender()), "Only admin or polygon minter can mint new tokens");
    _mintBatch(to, ids, amounts, data);
  }
}