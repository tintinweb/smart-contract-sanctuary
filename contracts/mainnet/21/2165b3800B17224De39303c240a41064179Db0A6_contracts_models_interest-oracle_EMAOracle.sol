pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../moneymarkets/IMoneyMarket.sol";
import "../../libs/DecMath.sol";
import "./IInterestOracle.sol";

contract EMAOracle is IInterestOracle {
    using SafeMath for uint256;
    using DecMath for uint256;

    uint256 internal constant PRECISION = 10**18;

    /**
        Immutable parameters
     */
    uint256 public UPDATE_INTERVAL;
    uint256 public UPDATE_MULTIPLIER;
    uint256 public ONE_MINUS_UPDATE_MULTIPLIER;

    /**
        Public variables
     */
    uint256 public emaStored;
    uint256 public lastIncomeIndex;
    uint256 public lastUpdateTimestamp;

    /**
        External contracts
     */
    IMoneyMarket public moneyMarket;

    constructor(
        uint256 _emaInitial,
        uint256 _updateInterval,
        uint256 _smoothingFactor,
        uint256 _averageWindowInIntervals,
        address _moneyMarket
    ) public {
        emaStored = _emaInitial;
        UPDATE_INTERVAL = _updateInterval;
        lastUpdateTimestamp = now;

        uint256 updateMultiplier = _smoothingFactor.div(_averageWindowInIntervals.add(1));
        UPDATE_MULTIPLIER = updateMultiplier;
        ONE_MINUS_UPDATE_MULTIPLIER = PRECISION.sub(updateMultiplier);

        moneyMarket = IMoneyMarket(_moneyMarket);
        lastIncomeIndex = moneyMarket.incomeIndex();
    }

    function updateAndQuery() public returns (bool updated, uint256 value) {
        uint256 timeElapsed = now - lastUpdateTimestamp;
        if (timeElapsed < UPDATE_INTERVAL) {
            return (false, emaStored);
        }

        // save gas by loading storage variables to memory
        uint256 _lastIncomeIndex = lastIncomeIndex;
        uint256 _emaStored = emaStored;

        uint256 newIncomeIndex = moneyMarket.incomeIndex();
        uint256 incomingValue = newIncomeIndex.sub(_lastIncomeIndex).decdiv(_lastIncomeIndex).div(timeElapsed);

        updated = true;
        value = incomingValue.mul(UPDATE_MULTIPLIER).add(_emaStored.mul(ONE_MINUS_UPDATE_MULTIPLIER)).div(PRECISION);
        emaStored = value;
        lastIncomeIndex = newIncomeIndex;
        lastUpdateTimestamp = now;
    }

    function query() public view returns (uint256 value) {
        return emaStored;
    }
}
