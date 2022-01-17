// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAssetTokenStateProvider {
  function getAssetTokenState(address asset, uint256 tokenId) external view returns (bool);

  function setAssetTokenState(
    address asset,
    uint256 tokenId,
    bool state
  ) external;
}

/// @title AssetTokenStateProvider
/// @notice This AssetTokenStateProvider is only for the test
contract AssetTokenStateProvider is IAssetTokenStateProvider {
  constructor() {}

  enum State {
    VALID,
    INVAILD
  }

  mapping(uint256 => State) public tokenState;

  /// @notice This function always returns false
  function getAssetTokenState(address asset, uint256 tokenId)
    external
    view
    override
    returns (bool)
  {
    asset;
    if (tokenState[tokenId] == State.INVAILD) {
      return false;
    } else {
      return true;
    }
  }

  /// @notice This function always returns false
  function setAssetTokenState(
    address asset,
    uint256 tokenId,
    bool state
  ) external override {
    asset;
    if (state == true) {
      tokenState[tokenId] = State.VALID;
    } else {
      tokenState[tokenId] = State.INVAILD;
    }
  }
}