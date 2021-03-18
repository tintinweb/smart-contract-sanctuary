// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import { BondingCurve } from "./BondingCurve.sol";
import { IERC20 } from "./IERC20.sol";

contract BondingCurveFactory {
  address public feeTo;
  BondingCurve[] public allBondingToken;

  /**
   * @dev Constructor for the factory contract
   * @param _feeTo The receiving address for fees that is generated from withdraw
   */
  constructor(address _feeTo) {
    require(_feeTo != address(0), "Address must not be address(0)");
    feeTo = _feeTo;
  }

  function bondingTokenCount() public view returns (uint256) {
    return allBondingToken.length;
  }

  /**
   * @dev Create new bonding curve token
   * @param _tokenToSell The address for the token to sell
   * @param _token The address for the trading token
   * @param _start The start time of token sale
   * @param _end The end time of token sale
   * @param _redeemInTime Whether the user can redeem immediately after the sale, instead of waiting for the end time.
   * @param _maximumBalance the maximum number of tokens an account can hold
   * @param _cap The amount of to raise 
   * @param _team The address for the token creator team
   * @param _curve curve lib
   * @param _params The params list for curve
   */
  function createBondingCurveToken(IERC20 _tokenToSell, IERC20 _token, uint256 _start, uint256 _end, bool _redeemInTime, uint256 _maximumBalance, uint256 _cap, address _team, address _curve, uint256[] memory _params) external {
    BondingCurve newBondingCurve = new BondingCurve(_tokenToSell, _token, _start, _end, _redeemInTime, _maximumBalance, _cap, _team, _curve, _params);
    bool success = _tokenToSell.transferFrom(msg.sender, address(newBondingCurve), _cap);
    require(success, "Transfer failed");
    newBondingCurve.initialize(this);
    allBondingToken.push(newBondingCurve);
  }
}

// 3570785