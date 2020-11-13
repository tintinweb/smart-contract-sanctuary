pragma solidity 0.5.17;

interface IInterestModel {
    function calculateInterestAmount(
        uint256 depositAmount,
        uint256 depositPeriodInSeconds,
        uint256 moneyMarketInterestRatePerSecond,
        bool surplusIsNegative,
        uint256 surplusAmount
    ) external view returns (uint256 interestAmount);
}
