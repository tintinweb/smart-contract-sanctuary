// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.7.0;

import "./SafeMath.sol";
import "./Owned.sol";
import "./IDparam.sol";
import "./WhiteList.sol";

contract Dparam is Owned, WhiteList, IDparam {
    using SafeMath for uint256;

    /// @notice Subscription ratio token -> coin
    uint256 public stakeRate = 35;
    /// @notice The collateral rate of liquidation
    uint256 public liquidationLine = 110;
    /// @notice Redemption rate 0.3%
    uint256 public feeRate = 3;

    /// @notice Minimum number of COINS for the first time
    uint256 public minMint = 100 * ONE;
    uint256 constant ONE = 1e8;

    /// @notice Reset fee event
    event FeeRateEvent(uint256 feeRate);
    /// @notice Reset liquidationLine event
    event LiquidationLineEvent(uint256 liquidationRate);
    /// @notice Reset minMint event
    event MinMintEvent(uint256 minMint);

    /**
     * @notice Construct a new Dparam, owner by msg.sender
     */
    constructor() public Owned(msg.sender) {}

    /**
     * @notice Reset feeRate
     * @param _feeRate New number of feeRate
     */
    function setFeeRate(uint256 _feeRate) external onlyWhiter {
        feeRate = _feeRate;
        emit FeeRateEvent(feeRate);
    }

    /**
     * @notice Reset liquidationLine
     * @param _liquidationLine New number of liquidationLine
     */
    function setLiquidationLine(uint256 _liquidationLine) external onlyWhiter {
        liquidationLine = _liquidationLine;
        emit LiquidationLineEvent(liquidationLine);
    }

    /**
     * @notice Reset minMint
     * @param _minMint New number of minMint
     */
    function setMinMint(uint256 _minMint) external onlyWhiter {
        minMint = _minMint;
        emit MinMintEvent(minMint);
    }

    /**
     * @notice Check Is it below the clearing line
     * @param price The token/usdt price
     * @return Whether the clearing line has been no exceeded
     */
    function isLiquidation(uint256 price) external view returns (bool) {
        return price.mul(stakeRate).mul(100) <= liquidationLine.mul(ONE);
    }

    /**
     * @notice Determine if the exchange value at the current rate is less than $7
     * @param price The token/usdt price
     * @return The value of Checking
     */
    function isNormal(uint256 price) external view returns (bool) {
        return price.mul(stakeRate) >= ONE.mul(7);
    }
}
