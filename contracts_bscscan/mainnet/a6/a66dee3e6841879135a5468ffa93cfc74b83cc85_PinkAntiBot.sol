// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.9;

import "./OwnableUpgradeable.sol";

contract PinkAntiBot is OwnableUpgradeable {
  string VERSION;
  address private _linkedOwner;
  mapping(address => bool) private _blacklisted;

  function setTokenOwner(address owner_) external {
    require(owner_ == owner(), "Invalid ownership");
    _linkedOwner = owner_;
  }

  function onPreTransferCheck(
    address sender,
    address recipient,
    uint256 amount
  ) external {
    require(!_blacklisted[sender] && !_blacklisted[recipient], "Blacklisted!");

    // todo: next upgrade should replace below line
    // only able to sell 1 tx per configured time (ex: 1 hour)
    bytes memory unusedForNow = abi.encodePacked(sender, recipient, amount);
  }

  function initialize() public initializer {
    __Ownable_init();
    __AntiBot_init();
  }

  function __AntiBot_init() internal initializer {
    VERSION = "1.0.1";
  }
}