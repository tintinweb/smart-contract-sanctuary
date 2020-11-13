pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../libs/DecMath.sol";

contract LinearInterestModel {
    using SafeMath for uint256;
    using DecMath for uint256;

    uint256 public constant PRECISION = 10**18;
    uint256 public IRMultiplier;

    constructor(uint256 _IRMultiplier) public {
        IRMultiplier = _IRMultiplier;
    }

    function calculateInterestAmount(
        uint256 depositAmount,
        uint256 depositPeriodInSeconds,
        uint256 moneyMarketInterestRatePerSecond,
        bool, /*surplusIsNegative*/
        uint256 /*surplusAmount*/
    ) external view returns (uint256 interestAmount) {
        // interestAmount = depositAmount * moneyMarketInterestRatePerSecond * IRMultiplier * depositPeriodInSeconds
        interestAmount = depositAmount
            .mul(PRECISION)
            .decmul(moneyMarketInterestRatePerSecond)
            .decmul(IRMultiplier)
            .mul(depositPeriodInSeconds)
            .div(PRECISION);
    }
}
