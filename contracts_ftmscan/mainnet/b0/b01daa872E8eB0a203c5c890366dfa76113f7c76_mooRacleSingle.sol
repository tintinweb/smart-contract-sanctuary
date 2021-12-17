/**
 *Submitted for verification at FtmScan.com on 2021-12-17
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File @openzeppelin/contracts/math/[email protected]

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File contracts/PriceSource.sol

pragma solidity ^0.5.0;

interface PriceSource {
	function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
	function decimals() external view returns (uint8);
// source: https://polygonscan.com/address/0xab594600376ec9fd91f8e885dadf0ce036862de0#code
}


// File contracts/oracles/mooRacleSingle.sol

// contracts/mooRacleSingle.sol
// SPDX-License-Identifier: UTD

pragma solidity 0.5.16;

interface IBeefyV6 {
    function getPricePerFullShare() external view returns (uint256 price);
	function decimals() external view returns (uint8);
}

contract mooRacleSingle {

    using SafeMath for uint256;

	// this should just be vieweing a chainlink oracle's price
	// then it would check the balances of that contract in the token that its checking.
	// it should return the price per token based on the camToken's balance

    PriceSource public priceSource;
    address public underlying;
    address public yVault; 

    uint256 public fallbackPrice;

    event FallbackPrice(
         uint80 roundId, 
         int256 price,
         uint256 startedAt,
		 uint256 updatedAt, 
		 uint80 answeredInRound
	);

	// price Source gives underlying price per token

    constructor(address _priceSource, address _underlying, address _yVault) public {
    	priceSource = PriceSource(_priceSource);
    	underlying  = _underlying;
    	yVault 		= _yVault;
    }

    // to integrate we just need to inherit that same interface the other page uses.

	function latestRoundData() public view
		returns 
			(uint80 roundId,
			 int256 answer,
			 uint256 startedAt,
			 uint256 updatedAt, 
			 uint80 answeredInRound
			){
		// we should passthrough all the data from the chainlink call. This would allow for transparency over the information sent.
		// Then we can filter as needed but this could be a cool standard we use for share-based tokens (like the compounding tokens)

		// check how much underlying does the share contract have.
		// underlying.balanceOf(address(shares))

		// then we check how many shares do we have outstanding
		// shares.totalSupply()

		// now we divide the total value of underlying held in the contract by the number of tokens

        (
         uint80 roundId, 
         int256 price,
         uint256 startedAt,
		 uint256 updatedAt, 
		 uint80 answeredInRound
		 ) = priceSource.latestRoundData();

        uint256 _price;

        if(price>0){
        	_price=uint256(price);
        } else {
	    	_price=fallbackPrice;
        }

		IBeefyV6 vault = IBeefyV6(yVault);
		uint256 newPrice = _price.mul(vault.getPricePerFullShare()).div(10 ** uint256(vault.decimals()));
		
		return(roundId, int256(newPrice), startedAt, updatedAt, answeredInRound);
	}

	function updateFallbackPrice() public {
        (
         uint80 roundId, 
         int256 price,
         uint256 startedAt,
		 uint256 updatedAt, 
		 uint80 answeredInRound
		 ) = priceSource.latestRoundData();

		if (price > 0) {
			fallbackPrice = uint256(price);
	        emit FallbackPrice(roundId,price,startedAt,updatedAt,answeredInRound);
        }
 	}
}