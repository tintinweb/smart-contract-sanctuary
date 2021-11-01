// SPDX-License-Identifier: MIT
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

import "./SafeMath.sol";
import "./SafeToken.sol";
import "./IPriceModel.sol";

contract AscendingStepModel is IPriceModel {
  using SafeMath for uint256;

  /// @dev states
  uint256 public immutable override startBlock;
  uint256 public immutable override endBlock;
  uint256 public immutable blockPerStep;
  uint256 public immutable priceStep;

  uint256 public immutable startPrice;
  uint256 public immutable priceCeiling;

  constructor(
    uint256 _startBlock,
    uint256 _endBlock,
    uint256 _blockPerStep,
    uint256 _priceStep,
    uint256 _startPrice,
    uint256 _priceCeiling
  ) public {
    require(_endBlock > _startBlock, "AscendingStepModel::constructor:: end block < start block");
    require(_startPrice < _priceCeiling, "AscendingStepModel::constructor:: floor price > start price");

    startBlock = _startBlock;
    endBlock = _endBlock;
    blockPerStep = _blockPerStep;
    priceStep = _priceStep;
    startPrice = _startPrice;
    priceCeiling = _priceCeiling;
  }

  /// @dev Get current price per token
  function price() external view override returns (uint256) {
    if (block.number <= startBlock) return startPrice;
    // This should prevent overflow
    if (block.number >= endBlock) return priceCeiling;

    uint256 _priceDelta = ((block.number.sub(startBlock)).div(blockPerStep)).mul(priceStep);

    uint256 _updatedPrice = startPrice.add(_priceDelta);

    if (_updatedPrice >= priceCeiling) return priceCeiling;

    return _updatedPrice;
  }
}