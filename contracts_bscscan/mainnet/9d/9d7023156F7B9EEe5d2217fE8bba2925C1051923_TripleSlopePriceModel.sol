// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IOGPriceModel.sol";
import "./Ownable.sol";

contract TripleSlopePriceModel is IOGPriceModel, Ownable {
  using SafeMath for uint256;

  uint256 public constant CEIL_SLOPE_1_BPS = 1e4;
  uint256 public constant CEIL_SLOPE_2_BPS = 5000;
  uint256 public constant CEIL_SLOPE_3_BPS = 2000;

  struct SetPricePerCategoryParams {
    uint256 categoryId;
    uint256 slope;
    uint256 price;
  }

  // categoryId -> slope bps -> price
  mapping(uint256 => mapping(uint256 => uint256)) public price;

  event SetPricePerCategory(uint256 indexed categoryId, uint256 indexed slope, uint256 price);

  constructor(SetPricePerCategoryParams[] memory _params) public {
    _setPricePerCategories(_params);
  }

  /// @dev Return the price based on triple slope
  function getPrice(
    uint256 maxCap,
    uint256 cap,
    uint256 categoryId
  ) external view override returns (uint256) {
    if (maxCap == 0) return 0;
    uint256 capLeftBps = cap.mul(1e4).div(maxCap);
    if (capLeftBps < CEIL_SLOPE_3_BPS) return price[categoryId][CEIL_SLOPE_3_BPS];
    if (capLeftBps < CEIL_SLOPE_2_BPS) return price[categoryId][CEIL_SLOPE_2_BPS];
    return price[categoryId][CEIL_SLOPE_1_BPS];
  }

  function _setPricePerCategories(SetPricePerCategoryParams[] memory _params) internal {
    for (uint256 idx = 0; idx < _params.length; idx++) {
      price[_params[idx].categoryId][_params[idx].slope] = _params[idx].price;
      emit SetPricePerCategory(_params[idx].categoryId, _params[idx].slope, _params[idx].price);
    }
  }
}