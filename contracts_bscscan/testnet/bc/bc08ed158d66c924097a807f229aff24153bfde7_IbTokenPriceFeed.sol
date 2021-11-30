// SPDX-License-Identifier: AGPL-3.0-or-later
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.6.12;

import "./PausableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

import "./IPriceFeed.sol";
import "./IAlpacaOracle.sol";
import "./IAccessControlConfig.sol";

contract IbTokenPriceFeed is PausableUpgradeable, AccessControlUpgradeable, IPriceFeed {
  using SafeMathUpgradeable for uint256;

  IAccessControlConfig public accessControlConfig;

  IPriceFeed public ibInBasePriceFeed;
  IPriceFeed public baseInUsdPriceFeed;

  // --- Init ---
  function initialize(
    address _ibInBasePriceFeed,
    address _baseInUsdPriceFeed,
    address _accessControlConfig
  ) external initializer {
    PausableUpgradeable.__Pausable_init();
    AccessControlUpgradeable.__AccessControl_init();

    ibInBasePriceFeed = IPriceFeed(_ibInBasePriceFeed);
    baseInUsdPriceFeed = IPriceFeed(_baseInUsdPriceFeed);

    accessControlConfig = IAccessControlConfig(_accessControlConfig);
  }

  modifier onlyOwnerOrGov() {
    require(
      accessControlConfig.hasRole(accessControlConfig.GOV_ROLE(), msg.sender) ||
        accessControlConfig.hasRole(accessControlConfig.OWNER_ROLE(), msg.sender),
      "!(ownerRole or govRole)"
    );
    _;
  }

  function pause() external onlyOwnerOrGov {
    _pause();
  }

  function unpause() external onlyOwnerOrGov {
    _unpause();
  }

  function readPrice() external view override returns (bytes32) {
    bytes32 ibInBasePrice = ibInBasePriceFeed.readPrice();
    bytes32 baseInUsdPrice = baseInUsdPriceFeed.readPrice();

    uint256 price = uint256(ibInBasePrice).mul(uint256(baseInUsdPrice)).div(1e18);
    return bytes32(price);
  }

  function peekPrice() external view override returns (bytes32, bool) {
    (bytes32 ibInBasePrice, bool ibInBasePriceOk) = ibInBasePriceFeed.peekPrice();
    (bytes32 baseInUsdPrice, bool baseInUsdPriceOk) = baseInUsdPriceFeed.peekPrice();

    uint256 price = uint256(ibInBasePrice).mul(uint256(baseInUsdPrice)).div(1e18);
    return (bytes32(price), ibInBasePriceOk && baseInUsdPriceOk && !paused());
  }
}