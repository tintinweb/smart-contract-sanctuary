pragma solidity 0.4.25;

// File: contracts/sogur/interfaces/IPriceBandCalculator.sol

/**
 * @title Price Band Calculator Interface.
 */
interface IPriceBandCalculator {
    /**
     * @dev Deduct price-band from a given amount of SDR.
     * @param _sdrAmount The amount of SDR.
     * @param _sgrTotal The total amount of SGR.
     * @param _alpha The alpha-value of the current interval.
     * @param _beta The beta-value of the current interval.
     * @return The amount of SDR minus the price-band.
     */
    function buy(uint256 _sdrAmount, uint256 _sgrTotal, uint256 _alpha, uint256 _beta) external pure returns (uint256);

    /**
     * @dev Deduct price-band from a given amount of SDR.
     * @param _sdrAmount The amount of SDR.
     * @param _sgrTotal The total amount of SGR.
     * @param _alpha The alpha-value of the current interval.
     * @param _beta The beta-value of the current interval.
     * @return The amount of SDR minus the price-band.
     */
    function sell(uint256 _sdrAmount, uint256 _sgrTotal, uint256 _alpha, uint256 _beta) external pure returns (uint256);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: contracts/sogur/PriceBandCalculator.sol

/**
 * Details of usage of licenced software see here: https://www.sogur.com/software/readme_v1
 */

/**
 * @title Price Band Calculator.
 */
contract PriceBandCalculator is IPriceBandCalculator {
    string public constant VERSION = "1.0.1";

    using SafeMath for uint256;

    // Auto-generated via 'AutoGenerate/PriceBandCalculator/PrintConstants.py'
    uint256 public constant ONE = 1000000000;
    uint256 public constant GAMMA = 165000000000000000000000000000000000000000;
    uint256 public constant DELTA = 15000000;

    /**
     * Denote r = sdrAmount
     * Denote n = sgrTotal
     * Denote a = alpha / A_B_SCALE
     * Denote b = beta  / A_B_SCALE
     * Denote c = GAMMA / ONE / A_B_SCALE
     * Denote d = DELTA / ONE
     * Denote w = c / (a - b * n) - d
     * Return r / (1 + w)
     */
    function buy(uint256 _sdrAmount, uint256 _sgrTotal, uint256 _alpha, uint256 _beta) external pure returns (uint256) {
        uint256 reserveRatio = calcReserveRatio(_alpha, _beta, _sgrTotal);
        return  (_sdrAmount.mul(reserveRatio).mul(ONE)).div((reserveRatio.mul(ONE.sub(DELTA))).add(GAMMA));
    }

    /**
     * Denote r = sdrAmount
     * Denote n = sgrTotal
     * Denote a = alpha / A_B_SCALE
     * Denote b = beta  / A_B_SCALE
     * Denote c = GAMMA / ONE / A_B_SCALE
     * Denote d = DELTA / ONE
     * Denote w = c / (a - b * n) - d
     * Return r * (1 - w)
     */
    function sell(uint256 _sdrAmount, uint256 _sgrTotal, uint256 _alpha, uint256 _beta) external pure returns (uint256) {
        uint256 reserveRatio = calcReserveRatio(_alpha, _beta, _sgrTotal);
        return (_sdrAmount.mul((reserveRatio.mul(ONE.add(DELTA))).sub(GAMMA))).div(reserveRatio.mul(ONE));
    }

    function calcReserveRatio(uint256 _alpha, uint256 _beta, uint256 _sgrTotal) public pure returns (uint256){
        return _alpha.sub(_beta.mul(_sgrTotal));
    }
}