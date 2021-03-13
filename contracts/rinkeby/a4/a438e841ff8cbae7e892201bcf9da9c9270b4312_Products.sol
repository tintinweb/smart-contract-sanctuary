pragma solidity ^0.7.3;

import './libraries/SafeMathExt.sol';

contract Products {

    struct Product {
        uint256 maxLeverage;
        uint256 spread; // in basis points. 1 UNIT = 100%
        uint256 fundingRate;  // per block, in basis points. 1 UNIT = 100%. 5760 blocks in a day for 15s blocks
        bool isDisabled;
    }

    mapping(bytes32 => Product) private products;

    address public owner;
    bool private initialized;

    event ProductRegistered(bytes32 symbol, uint256 leverage, uint256 spread, uint256 fundingRate);
    event NewLeverage(bytes32 symbol, uint256 newLeverage);
    event NewSpread(bytes32 symbol, uint256 newSpread);
    event NewFundingRate(bytes32 symbol, uint256 newFundingRate);

    function initialize() public {
        require(!initialized, '!initialized');
        initialized = true;
        owner = msg.sender;
    }

    function getMaxLeverage(
        bytes32 symbol,
        bool checkDisabled
    ) external view returns (uint256) {
        Product storage product = products[symbol];
        uint256 maxLeverage = product.maxLeverage;
        _validateProduct(maxLeverage);
        require(!checkDisabled || !product.isDisabled, '!disabled');
        return maxLeverage;
    }

    function getSpread(bytes32 symbol) external view returns (uint256) {
        Product storage product = products[symbol];
        _validateProduct(product.maxLeverage);
        return product.spread;
    }

    function getFundingRate(bytes32 symbol) external view returns (uint256) {
        Product storage product = products[symbol];
        _validateProduct(product.maxLeverage);
        return product.fundingRate;
    }

    function getInfo(
        bytes32 symbol,
        bool checkDisabled
    ) external view returns (uint256 maxLeverage, uint256 spread, uint256 fundingRate) {
        Product memory product = products[symbol];
        _validateProduct(product.maxLeverage);
        require(!checkDisabled || !product.isDisabled, '!disabled');
        return (product.maxLeverage, product.spread, product.fundingRate);
    }

    function disable(bytes32 symbol) external onlyOwner {
        Product storage product = products[symbol];
        _validateProduct(product.maxLeverage);
        product.isDisabled = true;
    }

    function register(
        bytes32[] calldata symbols,
        uint256[] calldata maxLeverages,
        uint256[] calldata spreads,
        uint256[] calldata fundingRates
    ) external onlyOwner {

        require(symbols.length <= 10, '!max_length');
        require(symbols.length == maxLeverages.length && maxLeverages.length == spreads.length && spreads.length == fundingRates.length, 'Products: WRONG_LENGTH');

        for (uint256 i = 0; i < symbols.length; i++) {

            bytes32 symbol = symbols[i];
            uint256 maxLeverage = maxLeverages[i];
            uint256 spread = spreads[i];
            uint256 fundingRate = fundingRates[i];

            require(spread > 0, '!spread');
            require(maxLeverage >= SafeMathExt.UNIT8, '!leverage');
            require(symbol != bytes32(0) && symbol == bytes32(bytes12(symbol)), '!symbol');
            require(products[symbol].maxLeverage == 0, '!duplicate');

            // Set product
            products[symbol] = Product(
                maxLeverage,
                spread,
                fundingRate,
                false
            );

            // Emit event
            emit ProductRegistered(
                symbol, 
                maxLeverage, 
                spread, 
                fundingRate
            );

        }

    }

    function setLeverage(bytes32 symbol, uint256 newLeverage) external onlyOwner {
        require(newLeverage >= SafeMathExt.UNIT8, '!leverage');
        Product storage product = products[symbol];
        _validateProduct(product.maxLeverage);
        product.maxLeverage = newLeverage;
        emit NewLeverage(symbol, newLeverage);
    }

    function updateSpread(bytes32 symbol, uint256 newSpread) external onlyOwner {
        require(newSpread > 0, '!spread');
        Product storage product = products[symbol];
        _validateProduct(product.maxLeverage);
        product.spread = newSpread;
        emit NewSpread(symbol, newSpread);
    }

    function updateFundingRate(bytes32 symbol, uint256 newFundingRate) external onlyOwner {
        Product storage product = products[symbol];
        _validateProduct(product.maxLeverage);
        product.fundingRate = newFundingRate;
        emit NewFundingRate(symbol, newFundingRate);
    }

    function _validateProduct(uint256 leverage) internal pure {
        require(leverage > 0, '!found');
    }

    /* Modifiers */

    modifier onlyOwner() {
        require(msg.sender == owner, '!authorized');
        _;
    }

}

pragma solidity ^0.7.3;

import '@openzeppelin/contracts/math/SafeMath.sol';

library SafeMathExt {

    using SafeMath for uint256;

    uint256 public constant UNIT8 = 1e8;
    uint256 public constant UNIT18 = 1e18;

    function base10pow(uint8 exponent) internal pure returns (uint256) {
        // very common
        if (exponent == 18) return 1e18;
        if (exponent == 6) return 1e6;

        uint256 result = 1;

        while (exponent >= 10) {
            result = result.mul(uint256(1e10));
            exponent -= 10;
        }

        while (exponent > 0) {
            result = result.mul(uint256(10));
            exponent--;
        }

        return result;
    }

    function mulDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(y) / UNIT18;
    }

    function divDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(UNIT18).div(y);
    }

    function mulDecimal8(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(y) / UNIT8;
    }

    function divDecimal8(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(UNIT8).div(y);
    }

    function safeUint64(uint256 x) internal pure returns (uint64) {
        require(x <= uint64(-1), 'SafeMath: cast overflow');
        return uint64(x);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}