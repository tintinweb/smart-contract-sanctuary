// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

interface IDparam {
    event FeeRateEvent(uint256 feeRate);
    event LiquidationLineEvent(uint256 liquidationRate);
    event MinMintEvent(uint256 minMint);

    function stakeRate() external view returns (uint256);

    function liquidationLine() external view returns (uint256);

    function feeRate() external view returns (uint256);

    function minMint() external view returns (uint256);

    function setFeeRate(uint256 _feeRate) external;

    function setLiquidationLine(uint256 _liquidationLine) external;

    function setMinMint(uint256 _minMint) external;

    function isLiquidation(uint256 price) external view returns (bool);

    function isNormal(uint256 price) external view returns (bool);
}
