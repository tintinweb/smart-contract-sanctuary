// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "../interfaces/ILendingPool.sol";
import "../interfaces/IMemory.sol";
import "../interfaces/ICToken.sol";
import "../interfaces/IAaveAddressProvider.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IProtocolDataProvider {
	function getReserveData(address asset)
		external
		view
		returns (
			uint256 availableLiquidity,
			uint256 totalStableDebt,
			uint256 totalVariableDebt,
			uint256 liquidityRate,
			uint256 variableBorrowRate
		);
}

contract ProtocolsData {
	using SafeMath for uint256;

	IMemory memoryContract;

	mapping(address => address) internal cTokens;
	mapping(address => uint256) internal dydxMarkets;

	address internal constant MATIC =
		0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
	address internal constant WMATIC =
		0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

	IProtocolDataProvider aaveDataProviderV2 =
		IProtocolDataProvider(0x7551b5D2763519d4e37e8B81929D336De671d46d);

	struct Data {
		uint256 liquidity;
		uint256 supplyRate;
		uint256 borrowRate;
		uint256 utilizationRate;
	}

	struct DydxData {
		uint256 market;
		uint256 supply;
		uint256 borrow;
	}

	struct Rate {
		uint256 value;
	}

	constructor(IMemory _memoryContract) {
		memoryContract = _memoryContract;
	}

	function getCreamData(address token) public view returns (Data memory) {
		ICToken cToken = ICToken(memoryContract.getCrToken(token));

		uint256 supplyRate = cToken.supplyRatePerBlock();
		uint256 borrowRate = cToken.borrowRatePerBlock();
		uint256 liquidity = cToken.getCash();
		uint256 reserves = cToken.totalReserves();
		uint256 totalBorrows = cToken.totalBorrows();

		uint256 utilizationRate = totalBorrows.mul(1 ether).div(
			liquidity.add(totalBorrows).sub(reserves)
		);

		return Data(liquidity, supplyRate, borrowRate, utilizationRate);
	}

	function getAaveData(address token) public view returns (Data memory) {
		(
			uint256 liquidity,
			,
			uint256 totalBorrows,
			uint256 supplyRate,
			uint256 borrowRate
		) = aaveDataProviderV2.getReserveData(token);

		uint256 utilizationRate = totalBorrows.mul(1 ether).div(
			liquidity.add(totalBorrows)
		);

		return Data(liquidity, supplyRate, borrowRate, utilizationRate);
	}

	function getProtocolsData(address token)
		external
		view
		returns (Data memory aave, Data memory cream)
	{
		aave = getAaveData(token);
		cream = getCreamData(token);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAaveAddressProvider {
	function getLendingPool() external view returns (address);

	function getLendingPoolCore() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICToken {
	function redeem(uint256 redeemTokens) external returns (uint256);

	function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

	function borrow(uint256 borrowAmount) external returns (uint256);

	function liquidateBorrow(
		address borrower,
		uint256 repayAmount,
		address cTokenCollateral
	) external returns (uint256);

	function liquidateBorrow(address borrower, address cTokenCollateral)
		external
		payable;

	function exchangeRateCurrent() external returns (uint256);

	function getCash() external view returns (uint256);

	function totalBorrowsCurrent() external returns (uint256);

	function borrowRatePerBlock() external view returns (uint256);

	function supplyRatePerBlock() external view returns (uint256);

	function totalReserves() external view returns (uint256);

	function totalBorrows() external view returns (uint256);

	function reserveFactorMantissa() external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256 balance);

	function allowance(address, address) external view returns (uint256);

	function approve(address, uint256) external;

	function transfer(address, uint256) external returns (bool);

	function transferFrom(
		address,
		address,
		uint256
	) external returns (bool);

	function getAccountSnapshot(address)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256
		);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILendingPool {
	function deposit(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode
	) external;

	function withdraw(
		address asset,
		uint256 amount,
		address to
	) external returns (uint256);

	function borrow(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		uint16 referralCode,
		address onBehalfOf
	) external;

	function repay(
		address asset,
		uint256 amount,
		uint256 rateMode,
		address onBehalfOf
	) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMemory {
	function getUint() external view returns (uint256);

	function setUint(uint256) external;

	function getAToken(address asset) external view returns (address);

	function setAToken(address asset, address _aToken) external;

	function getCrToken(address asset) external view returns (address);

	function setCrToken(address asset, address _crToken) external;
}