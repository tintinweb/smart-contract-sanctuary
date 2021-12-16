//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";

import "./OpenSeaCompatible.sol";

contract NftyV3 is
  Ownable,
  ERC1155,
  ERC1155Supply,
  ERC1155Burnable,
  OpenSeaCompatible
{
  mapping(uint256 => address) private _uniqueTokenOwners;

  constructor(
    string memory uri_, // https://crypto.lozev.ski/api/crypto/{id}.json
    address proxy_,
    /** 0xa5409ec958c83c3f309868babaca7c86dcb077c1 -> mainnet
        0xf57b2c51ded3a29e6891aba85459d600256cf317 -> rinkeby */
    string memory contractURI_ // https://crypto.lozev.ski/api/crypto/contract.json
  ) ERC1155(uri_) OpenSeaCompatible(proxy_, contractURI_) {}

  modifier revertIfUniqueAndClaimed(uint256 id) {
    require(
      !_isUnique(id) || totalSupply(id) == 0,
      "Token ID has already been claimed"
    );
    _;
  }

  modifier revertIfAnyUniqueAndClaimed(uint256[] memory ids) {
    for (uint256 i = 0; i < ids.length; i++) {
      require(
        !_isUnique(ids[i]) || totalSupply(ids[i]) == 0,
        "Token ID(s) has already been claimed"
      );
    }
    _;
  }

  function _isUnique(uint256 id) internal view returns (bool) {
    return _uniqueTokenOwners[id] != address(0);
  }

  function _setUniqueness(uint256 id, address minter) internal {
    _uniqueTokenOwners[id] = minter;
  }

  function isUnique(uint256 id) public view returns (bool) {
    return _isUnique(id);
  }

  function canChangeTokenUniqueness(address account, uint256 id)
    public
    view
    returns (bool)
  {
    return _canChangeTokenUniqueness(account, id);
  }

  function _canChangeTokenUniqueness(address account, uint256 id)
    internal
    view
    returns (bool)
  {
    return totalSupply(id) == 0 || balanceOf(account, id) == totalSupply(id);
  }

  function setTokenUniqueness(uint256 id, bool isUnique_) external {
    require(
      _canChangeTokenUniqueness(msg.sender, id),
      "Not allowed to change token id uniqueness"
    );
    require(
      !isUnique_ || totalSupply(id) <= 1,
      "Burn tokens before token id unique"
    );
    _setUniqueness(id, isUnique_ ? msg.sender : address(0));
  }

  function mintTo(
    address to,
    uint256 id,
    uint256 amount,
    bool unique,
    bytes memory data
  ) public revertIfUniqueAndClaimed(id) {
    require(!unique || amount > 0, "Must mint at least 1 token");

    if (unique) {
      _setUniqueness(id, to);
    }

    _mint(to, id, amount, data);
  }

  function mintBatchTo(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bool[] memory uniqueIds,
    bytes memory data
  ) public revertIfAnyUniqueAndClaimed(ids) {
    require(
      uniqueIds.length == ids.length,
      "Uniqueness flag array length must align"
    );

    for (uint256 i = 0; i < ids.length; ++i) {
      require(amounts[i] > 0, "Must mint at least 1 token");
      _setUniqueness(ids[i], to);
    }

    _mintBatch(to, ids, amounts, data);
  }

  function mint(
    uint256 id,
    uint256 amount,
    bool unique,
    bytes memory data
  ) external revertIfUniqueAndClaimed(id) {
    mintTo(msg.sender, id, amount, unique, data);
  }

  function mintBatch(
    uint256[] memory ids,
    uint256[] memory amounts,
    bool[] memory uniqueIds,
    bytes memory data
  ) external {
    mintBatchTo(msg.sender, ids, amounts, uniqueIds, data);
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
  {
    // allows gas-less trading on OpenSea
    return super.isApprovedForAll(owner, operator) || isProxy(owner, operator);
  }

  function setContractURI(string memory contractURI_) external onlyOwner {
    _setContractURI(contractURI_);
  }

  function setURI(string memory uri_) external onlyOwner {
    _setURI(uri_);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155, ERC1155Supply) {
    ERC1155Supply._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    for (uint256 i = 0; i < ids.length; ++i) {
      if (_isUnique(ids[i])) {
        _setUniqueness(ids[i], to);
      }
    }
  }
}