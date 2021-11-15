// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./abstracts/core/Tokenomics.sol";
import "./abstracts/core/RFI.sol";
import "./abstracts/features/Liquify.sol";
import "./abstracts/features/Expensify.sol";
import "./abstracts/features/Buyback.sol";
import "./abstracts/features/Collateralize.sol";
import "./abstracts/features/Distribution.sol";
import "./abstracts/features/TxPolice.sol";
import "./abstracts/core/Pancake.sol";
import "./abstracts/helpers/Helpers.sol";



contract FTV2 is 
	IERC20Metadata, 
	Context, 
	Ownable, 
	ReentrancyGuard, 
	Tokenomics, 
	RFI,
	TxPolice,
	Liquify, 
	Expensify, 
	Buyback, 
	Collateralize, 
	Distribution
{
	using SafeMath for uint256;

	constructor() {
		// Set limit exemptions
		LimitExemptions memory exemptions;
		exemptions.all = true;
		limitExemptions[owner()] = exemptions;
		limitExemptions[address(this)] = exemptions;
		// Set special addresses
		specialAddresses[owner()] = true;
		specialAddresses[address(this)] = true;
		specialAddresses[deadAddr] = true;
	}

/* ------------------------------- IERC20 Meta ------------------------------ */

	function name() external pure override returns(string memory) { return NAME;}
	function symbol() external pure override returns(string memory) { return SYMBOL;}
	function decimals() external pure override returns(uint8) { return DECIMALS; }	

/* -------------------------------- Overrides ------------------------------- */

	function beforeTokenTransfer(address from, address to, uint256 amount) 
		internal 
		override 
	{


		// Make sure max transaction and wallet size limits are not exceeded.
		TransactionLimitType[2] memory limits = [
			TransactionLimitType.TRANSACTION, 
			TransactionLimitType.WALLET
		];
		guardMaxLimits(from, to, amount, limits);
		enforceCyclicSellLimit(from, to, amount);
		// Try to execute all our accumulator features.
		triggerFeatures(from);
	}

	function takeFee(address from, address to) 
		internal 
		view 
		override 
		returns(bool) 
	{
		return canTakeFee(from, to);
	}

/* -------------------------- Accumulator Triggers -------------------------- */

	// Will keep track of how often each trigger has been called already.
	uint256[5] internal triggerLog = [0, 0, 0, 0, 0];
	// Will keep track of trigger indexes, which can be triggered during current tx.
	uint8[] internal canTrigger;
	
	/**
	* @notice Returns the smallest trigger log count value.
	*/
	function getSmallestTriggerLogCount() internal view returns(uint256) {
		uint256 smallest = triggerLog[0];
		for (uint8 i = 1; i < triggerLog.length; i++) {
				if (triggerLog[i] < smallest) {
						smallest = triggerLog[i];
				}
		}
		return smallest;
	}

	/**
	* @notice Trigger throttling mechanism. Allows to prioritize and execute only 
	* single trigger per transaction to avoid high gas fees.
	* Idea: the most frequent trigger is the smallest priority, the least frequent
	* is the most priority. If more than one trigger can be called during the tx 
	* we trigger the most priority one and then on the next tx, other one will be 
	* called and so on.
	*/
	function resolveTrigger() internal {
		uint256 smallest = getSmallestTriggerLogCount();

		for (uint8 i = 0; i < canTrigger.length; i++) {
			uint8 index = canTrigger[i];
			if (triggerLog[index] == smallest) {
				if (index == 0) {
					_triggerLiquify();
					delete canTrigger;
					break;
				} else if (index == 1) {
					_triggerExpensify();
					delete canTrigger;
					break;
				} else if (index == 2) {
					_triggerSellForBuyback();
					delete canTrigger;
					break;
				} else if (index == 3) {
					_triggerSellForCollateral();
					delete canTrigger;
					break;
				} else if (index == 4) {
					_triggerSellForDistribution();
					delete canTrigger;
					break;
				}
			}
		}
	}

	/**
	* @notice Populates canTrigger array with the indexes of the the triggers, 
	* which can be triggered during this tx.
	*/
	function resolveWhatCanBeTriggered() internal {
		uint256 contractTokenBalance = balanceOf(address(this));
		if (canLiquify(contractTokenBalance)) {
				canTrigger.push(0);
			}
			if (canExpensify(contractTokenBalance)) {
				canTrigger.push(1);
			}
			if (canSellForBuyback(contractTokenBalance)) {
				canTrigger.push(2);
			}
			if (canSellForCollateral(contractTokenBalance)) {
				canTrigger.push(3);
			}
			if (canSellForDistribution(contractTokenBalance)) {
				canTrigger.push(4);
			}
	}

	/**
	* @notice Convenience wrapper function which tries to trigger our custom 
	* features.
	*/
	function triggerFeatures(address from) private {






		
		// First determine which triggers can be triggered.
		if (!liquidityPools[from]) {
			resolveWhatCanBeTriggered();
		}

		// Avoid falling into a tx loop.
		if (!inTriggerProcess) {
			// Decide which trigger will be triggered and triger it.
			resolveTrigger();
		}
	}

/* ---------------------------- Internal Triggers --------------------------- */

	/**
	* @notice Triggers liquify and updates triggerLog
	*/
	function _triggerLiquify() internal {

		swapAndLiquify(accumulatedForLiquidity);
		triggerLog[0] = triggerLog[0].add(1);
	}

	/**
	* @notice Triggers expensify and updates triggerLog
	*/
	function _triggerExpensify() internal {

		expensify(accumulatedForExpenses);
		triggerLog[1] = triggerLog[1].add(1);
	}

	/**
	* @notice Triggers sell for buyback and updates triggerLog
	*/
	function _triggerSellForBuyback() internal {

		sellForBuyback(accumulatedForBuyback);
		triggerLog[2] = triggerLog[2].add(1);
	}

	/**
	* @notice Triggers sell for collateral and updates triggerLog
	*/
	function _triggerSellForCollateral() internal {

		sellForCollateral(accumulatedForCollateral);
		triggerLog[3] = triggerLog[3].add(1);
	}

	/**
	* @notice Triggers sell for distribution and updates triggerLog
	*/
	function _triggerSellForDistribution() internal {

		sellForDistribution(accumulatedForDistribution);
		triggerLog[4] = triggerLog[4].add(1);
	}

/* ---------------------------- External Triggers --------------------------- */

	/**
	* @notice Allows to trigger liquify manually.
	*/
	function triggerLiquify() external onlyOwner {
		_triggerLiquify();
	}

	/**
	* @notice Allows to trigger expensify manually.
	*/
	function triggerExpensify() external onlyOwner {
		_triggerExpensify();
	}

	/**
	* @notice Allows to trigger sell for buyback manually.
	*/
	function triggerSellForBuyback() external onlyOwner {
		_triggerSellForBuyback();
	}

	/**
	* @notice Allows to trigger sell for collateral manually.
	*/
	function triggerSellForCollateral() external onlyOwner {
		_triggerSellForCollateral();
	}

	/**
	* @notice Allows to sell for distribution manually.
	*/
	function triggerSellForDistribution() external onlyOwner {
		_triggerSellForDistribution();
	}

}

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Tokenomics is IERC20, Ownable {
	using SafeMath for uint256;

/* ---------------------------------- Token --------------------------------- */

	string internal constant NAME = "Ftv2";
	string internal constant SYMBOL = "FTV2";

	uint8 internal constant DECIMALS = 5;
	uint256 internal constant ZEROES = 10 ** DECIMALS;

	uint256 private constant MAX = ~uint256(0);
	uint256 internal constant _tTotal = 8000000000 * ZEROES;
	uint256 internal _rTotal = (MAX - (MAX % _tTotal));

	address public deadAddr = 0x000000000000000000000000000000000000dEaD;

/* ---------------------------------- Fees ---------------------------------- */

	uint256 internal _tFeeTotal;

	// Will be redistributed amongst holders
	uint256 public _taxFee = 1;
	// Used to cache fee when removing fee temporarily.
	uint256 internal _previousTaxFee = _taxFee;
	// Will be used for liquidity
	uint256 public _liquidityFee = 2;
	// Used to cache fee when removing fee temporarily.
	uint256 internal _previousLiquidityFee = _liquidityFee;
	// Will keep tabs on the amount which should be taken from wallet for liquidity.
	uint256 public accumulatedForLiquidity = 0;
	// Will be used for expenses (dev, licensing, marketing)
	uint256 public _expensesFee = 1;
	// Used to cache fee when removing fee temporarily.
	uint256 internal _previousExpensesFee = _expensesFee;
	// Will keep tabs on the amount which should be taken from wallet for expenses.
	uint256 public accumulatedForExpenses = 0;
	// Will be used for buyback
	uint256 public _buybackFee = 4;
	// Used to cache fee when removing fee temporarily.
	uint256 internal _previousBuybackFee = _buybackFee;
	// Will keep tabs on the amount which should be taken from wallet for buyback.
	uint256 public accumulatedForBuyback = 0;
	// Will be sold for BNB and distributed to holders as rewards.
	uint256 public _distributionFee = 2;
	// Used to cache fee when removing fee temporarily.
	uint256 internal _previousDistributionFee = _distributionFee;
	// Will keep tabs on the amount which should be taken from wallet for distribution.
	uint256 public accumulatedForDistribution = 0;
	// Will be sold for BNB and used as a collateral funds.
	uint256 public _collateralFee = 2;
	// Used to cache fee when removing fee temporarily.
	uint256 internal _previousCollateralFee = _collateralFee;
	// Will keep tabs on the amount which should be taken from wallet for collateral.
	uint256 public accumulatedForCollateral = 0;

	/**
	 * @notice Temporarily stops all fees. Caches the fees into secondary variables,
	 * so it can be reinstated later.
	 */
	function removeAllFee() internal {
		if (_taxFee == 0 &&
			_liquidityFee == 0 &&
			_expensesFee == 0 &&
			_buybackFee == 0 &&
			_distributionFee == 0 &&
			_collateralFee == 0
		) return;

		_previousTaxFee = _taxFee;
		_previousLiquidityFee = _liquidityFee;
		_previousExpensesFee = _expensesFee;
		_previousBuybackFee = _buybackFee;
		_previousDistributionFee = _distributionFee;
		_previousCollateralFee = _collateralFee;

		_taxFee = 0;
		_liquidityFee = 0;
		_expensesFee = 0;
		_buybackFee = 0;
		_distributionFee = 0;
		_collateralFee = 0;
	}

	/**
	 * @notice Restores all fees removed previously, using cached variables.
	 */
	function restoreAllFee() internal {
		_taxFee = _previousTaxFee;
		_liquidityFee = _previousLiquidityFee;
		_expensesFee = _previousExpensesFee;
		_buybackFee = _previousBuybackFee;
		_distributionFee = _previousDistributionFee;
		_collateralFee = _previousCollateralFee;
	}

	function calculateTaxFee(
		uint256 amount,
		uint8 multiplier
	) internal view returns(uint256) {
		return amount.mul(_taxFee).mul(multiplier).div(10 ** 2);
	}

	function calculateLiquidityFee(
		uint256 amount,
		uint8 multiplier
	) internal view returns(uint256) {
		return amount.mul(_liquidityFee).mul(multiplier).div(10 ** 2);
	}

	function calculateExpensesFee(
		uint256 amount,
		uint8 multiplier
	) internal view returns(uint256) {
		return amount.mul(_expensesFee).mul(multiplier).div(10 ** 2);
	}

	function calculateBuybackFee(
		uint256 amount,
		uint8 multiplier
	) internal view returns(uint256) {
		return amount.mul(_buybackFee).mul(multiplier).div(10 ** 2);
	}

	function calculateDistributionFee(
		uint256 amount,
		uint8 multiplier
	) internal view returns(uint256) {
		return amount.mul(_distributionFee).mul(multiplier).div(10 ** 2);
	}

	function calculateCollateralFee(
		uint256 amount,
		uint8 multiplier
	) internal view returns(uint256) {
		return amount.mul(_collateralFee).mul(multiplier).div(10 ** 2);
	}

/* --------------------------- Triggers and limits -------------------------- */

	// Once contract accumulates 0.01% of total supply, trigger liquify.
	uint256 public minToLiquify = _tTotal.mul(1).div(10000);
	// One contract accumulates 0.01% of total supply, trigger expenses wallet sendout.
	uint256 public minToExpenses = _tTotal.mul(1).div(10000);
	// One contract accumulates 0.01% of total supply, trigger buyback.
	uint256 public minToBuyback = _tTotal.mul(1).div(10000);
	// One contract accumulates 0.01% of total supply, trigger rewards distribution.
	uint256 public minToDistribution = _tTotal.mul(1).div(10000);
	// One contract accumulates 0.01% of total supply, trigger collateral distribution.
	uint256 public minToCollateral = _tTotal.mul(1).div(10000);

	/**
	@notice External function allowing to set minimum amount of tokens which trigger
	* auto liquification.
	*/
	function setMinToLiquify(uint256 minTokens) 
		external 
		onlyOwner
		supplyBounds(minTokens)
	{
		minToLiquify = minTokens * 10 ** 5;
	}

	/**
	@notice External function allowing to set minimum amount of tokens which trigger
	* expenses send out.
	*/
	function setMinToExpenses(uint256 minTokens) 
		external 
		onlyOwner 
		supplyBounds(minTokens)
	{
		minToExpenses = minTokens * 10 ** 5;
	}

	/**
	@notice External function allowing to set minimum amount of tokens which trigger
	* buyback.
	*/
	function setMinToBuyback(uint256 minTokens) 
		external 
		onlyOwner 
		supplyBounds(minTokens)
	{
		minToBuyback = minTokens * 10 ** 5;
	}

	/**
	@notice External function allowing to set minimum amount of tokens which trigger
	* distribution.
	*/
	function setMinToDistribution(uint256 minTokens) 
		external 
		onlyOwner 
		supplyBounds(minTokens)
	{
		minToDistribution = minTokens * 10 ** 5;
	}

	/**
	@notice External function allowing to set minimum amount of tokens which trigger
	* collateral send out.
	*/
	function setMinToCollateral(uint256 minTokens) 
		external 
		onlyOwner 
		supplyBounds(minTokens)
	{
		minToCollateral = minTokens * 10 ** 5;
	}

/* --------------------------------- IERC20 --------------------------------- */
	function totalSupply() external pure override returns(uint256) {
		return _tTotal;
	}

	function totalFees() external view returns(uint256) { 
		return _tFeeTotal; 
	}

/* -------------------------------- Modifiers ------------------------------- */

	modifier supplyBounds(uint256 minTokens) {
		require(minTokens * 10 ** 5 > 0, "Amount must be more than 0");
		require(minTokens * 10 ** 5 <= _tTotal, "Amount must be not bigger than total supply");
		_;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../core/Tokenomics.sol";
import "../core/Pancake.sol";


abstract contract RFI is IERC20, Ownable, Tokenomics, Pancake {
	using SafeMath for uint256;

	mapping(address => uint256) internal _rOwned;
	mapping(address => uint256) internal _tOwned;
	mapping(address => mapping(address => uint256)) private _allowances;

	struct TValues {
		uint256 tTransferAmount;
		uint256 tFee;
		uint256 tLiquidity;
		uint256 tExpenses;
		uint256 tBuyback;
		uint256 tDistribution;
		uint256 tCollateral;
	}

	struct RValues {
		uint256 rAmount;
		uint256 rTransferAmount;
		uint256 rFee;
	}

	constructor() {
		// Assigns all reflected tokens to the deployer on creation
		_rOwned[_msgSender()] = _rTotal;

		emit Transfer(address(0), _msgSender(), _tTotal);
	}

	/**
	 * @notice Calculates all values for "total" and "reflected" states.
	 * @param tAmount Token amount related to which, all values are calculated.
	 */
	function _getValues(
		uint256 tAmount
	) private view returns(
		TValues memory tValues, RValues memory rValues
	) {
		TValues memory tV = _getTValues(tAmount);
		RValues memory rV = _getRValues(
			tAmount,
			tV.tFee,
			tV.tLiquidity,
			tV.tExpenses,
			tV.tBuyback,
			tV.tDistribution,
			tV.tCollateral,
			_getRate()
		);
		return (tV, rV);
	}

	/**
	 * @notice Calculates values for "total" states.
	 * @param tAmount Token amount related to which, total values are calculated.
	 */
	function _getTValues(
		uint256 tAmount
	) private view returns(TValues memory tValues) {
		TValues memory tV;
		tV.tFee = calculateTaxFee(tAmount, 1);
		tV.tLiquidity = calculateLiquidityFee(tAmount, 1);
		tV.tExpenses = calculateExpensesFee(tAmount, 1);
		tV.tBuyback = calculateBuybackFee(tAmount, 1);
		tV.tDistribution = calculateDistributionFee(tAmount, 1);
		tV.tCollateral = calculateCollateralFee(tAmount, 1);






		uint256 fees = tV.tFee
			.add(tV.tLiquidity)
			.add(tV.tExpenses)
			.add(tV.tBuyback)
			.add(tV.tDistribution)
			.add(tV.tCollateral);
		tV.tTransferAmount = tAmount.sub(fees);
		return tV;
	}

	/**
	 * @notice Calculates values for "reflected" states.
	 * @param tAmount Token amount related to which, reflected values are calculated.
	 * @param tFee Total fee related to which, reflected values are calculated.
	 * @param tLiquidity Total liquidity related to which, reflected values are calculated.
	 * @param currentRate Rate used to calculate reflected values.
	 */
	function _getRValues(
		uint256 tAmount,
		uint256 tFee,
		uint256 tLiquidity,
		uint256 tExpenses,
		uint256 tBuyback,
		uint256 tDistribution,
		uint256 tCollateral,
		uint256 currentRate
	) private pure returns(RValues memory rValues) {
		RValues memory rV;
		rV.rAmount = tAmount.mul(currentRate);
		rV.rFee = tFee.mul(currentRate);
		uint256 rLiquidity = tLiquidity.mul(currentRate);
		uint256 rExpenses = tExpenses.mul(currentRate);
		uint256 rBuyback = tBuyback.mul(currentRate);
		uint256 rDistribution = tDistribution.mul(currentRate);
		uint256 rCollateral = tCollateral.mul(currentRate);
		uint256 fees = rV.rFee + rLiquidity + rExpenses + rBuyback + rDistribution + rCollateral;
		rV.rTransferAmount = rV.rAmount.sub(fees);
		return rV;
	}

	/**
	 * @notice Calculates the rate of total suply to reflected supply.
	 */
	function _getRate() private view returns(uint256) {
		(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
		return rSupply.div(tSupply);
	}

	function _reflectFee(
		uint256 rFee,
		uint256 tFee
	) private {
		_rTotal = _rTotal.sub(rFee);
		_tFeeTotal = _tFeeTotal.add(tFee);
	}

	/**
	 * @notice Returns totals for "total" supply and "reflected" supply.
	 */
	function _getCurrentSupply() private view returns(uint256, uint256) {
		uint256 rSupply = _rTotal;
		uint256 tSupply = _tTotal;
		if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
		return (rSupply, tSupply);
	}

	function reflectionFromToken(
		uint256 tAmount,
		bool deductTransferFee
	) public view returns(uint256) {
		require(tAmount <= _tTotal, "Amount must be less than supply");
		(, RValues memory rV) = _getValues(tAmount);
		if (!deductTransferFee) {
			return rV.rAmount;
		} else {
			return rV.rTransferAmount;
		}
	}

	function tokenFromReflection(
		uint256 rAmount
	) public view returns(uint256) {
		require(rAmount <= _rTotal, "Amount must be less than total reflections");
		uint256 currentRate = _getRate();
		return rAmount.div(currentRate);
	}

/* --------------------------------- Custom --------------------------------- */

	/**
	 * @notice ERC20 token transaction approval with allowance.
	 */
	function rfiApprove(
		address ownr,
		address spender,
		uint256 amount
	) internal {
		require(ownr != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[ownr][spender] = amount;
		emit Approval(ownr, spender, amount);
	}

	function _transfer(
		address from,
		address to,
		uint256 amount
	) internal {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		require(amount > 0, "Transfer amount must be greater than zero");

		// Override this in the main contract to plug your features inside transactions.
		beforeTokenTransfer(from, to, amount);

		// Transfer amount, it will take tax, liquidity fee
		bool take = takeFee(from, to);
		_tokenTransfer(from, to, amount, take);
	}

	/**
	 * @notice Performs token transfer with fees.
	 * @param sender Address of the sender.
	 * @param recipient Address of the recipient.
	 * @param amount Amount of tokens to send.
	 * @param take Toggle on/off fees.
	 */
	function _tokenTransfer(
		address sender,
		address recipient,
		uint256 amount,
		bool take
	) private {

		// Remove fees for this transaction if needed.
		if (!take)
			removeAllFee();

		// Calculate all reflection magic...
		(TValues memory tV, RValues memory rV) = _getValues(amount);

		// Adjust reflection states
		_rOwned[sender] = _rOwned[sender].sub(rV.rAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rV.rTransferAmount);

		// Calcuate fees. If above fees were removed, then these will obviously
		// not take any fees.
		_takeLiquidityFee(tV.tLiquidity);
		_takeExpensesFee(tV.tExpenses);
		_takeBuybackFee(tV.tBuyback);
		_takeDistributionFee(tV.tDistribution);
		_takeCollateralFee(tV.tCollateral);
		_reflectFee(rV.rFee, tV.tFee);

		emit Transfer(sender, recipient, tV.tTransferAmount);

		// Reinstate fees if they were removed for this transaction.
		if (!take)
			restoreAllFee();
	}

	/**
	* @notice Override this function to intercept the transaction and perform 
	* additional checks or perform certain functions before allowing transaction
	* to complete. You can prevent transaction to complete here too.
	*/
	function beforeTokenTransfer(
		address from, 
		address to, 
		uint256 amount
	) virtual internal {


	}

	function takeFee(address from, address to) virtual internal returns(bool) {


		return true;
	}

/* ------------------------------- Custom fees ------------------------------ */
	/**
	* @notice Collects tokens from liquidity fee. Accordingly adjusts "reflected" 
	amounts. 
	*/
	function _takeLiquidityFee(
		uint256 tLiquidity
	) private {
		uint256 currentRate = _getRate();
		uint256 rLiquidity = tLiquidity.mul(currentRate);
		_rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
		// Keep tabs, so when processing is triggered, we know how much should we take.
		accumulatedForLiquidity = accumulatedForLiquidity.add(tLiquidity);
	}

	/**
	* @notice Collects tokens from expeneses fee. Accordingly adjusts "reflected" 
	amounts. 
	*/
	function _takeExpensesFee(
		uint256 tExpenses
	) private {
		uint256 currentRate = _getRate();
		uint256 rExpenses = tExpenses.mul(currentRate);
		_rOwned[address(this)] = _rOwned[address(this)].add(rExpenses);
		// Keep tabs, so when processing is triggered, we know how much should we take.
		accumulatedForExpenses = accumulatedForExpenses.add(tExpenses);
	}

	/**
	* @notice Collects tokens from buyback fee. Accordingly adjusts "reflected" 
	amounts. 
	*/
	function _takeBuybackFee(
		uint256 tBuyback
	) private {
		uint256 currentRate = _getRate();
		uint256 rBuyback = tBuyback.mul(currentRate);
		_rOwned[address(this)] = _rOwned[address(this)].add(rBuyback);
		// Keep tabs, so when processing is triggered, we know how much should we take.
		accumulatedForBuyback = accumulatedForBuyback.add(tBuyback);
	}

	/**
	* @notice Collects tokens from distribution fee. Accordingly adjusts "reflected" 
	amounts. 
	*/
	function _takeDistributionFee(
		uint256 tDistribution
	) private {
		uint256 currentRate = _getRate();
		uint256 rDistribution = tDistribution.mul(currentRate);
		_rOwned[address(this)] = _rOwned[address(this)].add(rDistribution);
		// Keep tabs, so when processing is triggered, we know how much should we take.
		accumulatedForDistribution = accumulatedForDistribution.add(tDistribution);
	}

		/**
	* @notice Collects tokens from collateral fee. Accordingly adjusts "reflected" 
	amounts. 
	*/
	function _takeCollateralFee(
		uint256 tCollateral
	) private {
		uint256 currentRate = _getRate();
		uint256 rCollateral = tCollateral.mul(currentRate);
		_rOwned[address(this)] = _rOwned[address(this)].add(rCollateral);
		// Keep tabs, so when processing is triggered, we know how much should we take.
		accumulatedForCollateral = accumulatedForCollateral.add(tCollateral);
	}

/* --------------------------------- IERC20 --------------------------------- */

	function balanceOf(
		address account
	) public view override returns(uint256) {
		return tokenFromReflection(_rOwned[account]);
	}

	function transfer(
		address recipient,
		uint256 amount
	) public override returns(bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(
		address ownr,
		address spender
	) public view override returns(uint256) {
		return _allowances[ownr][spender];
	}

	function approve(
		address spender,
		uint256 amount
	) public override returns(bool) {
		rfiApprove(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public override returns(bool) {
		_transfer(sender, recipient, amount);
		rfiApprove(
			sender,
			_msgSender(),
			_allowances[sender][_msgSender()].sub(
				amount,
				"ERC20: transfer amount exceeds allowance"
			)
		);
		return true;
	}

	function increaseAllowance(
		address spender,
		uint256 addedValue
	) public virtual returns(bool) {
		rfiApprove(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender].add(addedValue)
		);
		return true;
	}

	function decreaseAllowance(
		address spender,
		uint256 subtractedValue
	) public virtual returns(bool) {
		rfiApprove(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender]
			.sub(subtractedValue, "ERC20: decreased allowance below zero")
		);
		return true;
	}

/* -------------------------------- Modifiers ------------------------------- */

	modifier onlyOwnerOrHolder {
		require(
			owner() == _msgSender() || balanceOf(_msgSender()) > 0, 
			"Only owner and holders can use this feature."
			);
		_;
	}

	modifier onlyHolder {
		require(
			balanceOf(_msgSender()) > 0, 
			"Only holders can use this feature."
			);
		_;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/Tokenomics.sol";
import "../core/RFI.sol";
import "../core/Pancake.sol";
import "../features/TxPolice.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract Liquify is Tokenomics, Pancake, RFI, TxPolice {
	using SafeMath for uint256;

	/** 
	* @notice Checks if all required prerequisites are met for us to trigger 
	* liquidity event.
	*/
	function canLiquify(
		uint256 contractTokenBalance
	) 
		internal 
		view
		returns(bool) 
	{
		return contractTokenBalance >= accumulatedForLiquidity 
			&& accumulatedForLiquidity >= minToLiquify;
	}

	function addInitialLiquidity(
		uint256 tokenAmount,
		uint256 bnbAmount
	) external onlyOwner {
		addLiquidity(tokenAmount, bnbAmount, true);
	}

	/**
	 * @notice Adds LP to Pancakeswap using it's router.
	 * @param tokenAmount Token amount for LP.
	 * @param bnbAmount BNB amount for LP.
	 */
	function addLiquidity(
		uint256 tokenAmount,
		uint256 bnbAmount,
		bool firstTime
	) internal pcsInitialized {

		uint256 amountTokenMin;
		uint256 amountEthMin;
		if (firstTime) {
			amountTokenMin = tokenAmount;
			amountEthMin = bnbAmount;
		}

		// Approve token transfer to cover all possible scenarios
		rfiApprove(address(this), address(uniswapV2Router), tokenAmount);

		// Add the liquidity
		uniswapV2Router.addLiquidityETH {
			value: bnbAmount
		}(
			address(this),
			tokenAmount,
			amountTokenMin,
			amountEthMin,
			owner(),
			block.timestamp
		);

		if (firstTime) {
			IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
		}
	}

	/**
	 * @notice Swaps a piece of tokens for BNB and uses it to add liquidity to PCS.
	 * @param tokenAmount Min amount of tokens from contract that will be swapped.
	 * NOTE: needs to be tested on testnet!!!
	 */
	function swapAndLiquify(
		uint256 tokenAmount
	) internal lockTheProcess {
		// Split tokens for liquidity.
		uint256 half = tokenAmount.div(2);
		uint256 otherHalf = tokenAmount.sub(half);
		// Swap and get how much BNB received.
		// Must approve before swapping.
		rfiApprove(address(this), address(uniswapV2Router), tokenAmount);
		uint256 bnbReceived = swapTokensForBnb(half);
		// Add liquidity to pancake
		addLiquidity(otherHalf, bnbReceived, false);
		// Reset the accumulator
		accumulatedForLiquidity = 0;
		emit SwapAndLiquify(half, bnbReceived, otherHalf);
	}

/* --------------------------------- Events --------------------------------- */

	event SwapAndLiquify(
		uint256 tokensSwapped,
		uint256 ethReceived,
		uint256 tokensIntoLiquidity
	);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../helpers/Helpers.sol";
import "../core/Pancake.sol";
import "../core/Tokenomics.sol";
import "../features/TxPolice.sol";

abstract contract Expensify is Ownable, Helpers, Tokenomics, Pancake, TxPolice {
	using SafeMath for uint256;
	address public licensingWallet;
	address public devWallet;
	address public marketingWallet;
	// Expenses fee accumulated amount will be divided using these.
	uint256 public licensingShare = 30; // 30%
	uint256 public devShare = 30; // 30%
	uint256 public marketingShare = 40; // 40%

	/**
	* @notice External function allowing to set/change licensing wallet.
	* @param wallet: this wallet will receive licensing share.
	* @param share: multiplier will be divided by 100. 30 -> 30%, 3 -> 3% etc.
	*/
	function setLicensingWallet(address wallet, uint256 share) 
		external onlyOwner legitWallet(wallet) 
	{
		licensingWallet = wallet;
		licensingShare = share;
		swapExcludedFromFee(wallet, licensingWallet);
	}

	/**
	* @notice External function allowing to set/change dev wallet.
	* @param wallet: this wallet will receive dev share.
	* @param share: multiplier will be divided by 100. 30 -> 30%, 3 -> 3% etc.
	*/
	function setDevWallet(address wallet, uint256 share) 
		external onlyOwner legitWallet(wallet)
	{
		devWallet = wallet;
		devShare = share;
		swapExcludedFromFee(wallet, devWallet);
	}

	/**
	* @notice External function allowing to set/change marketing wallet.
	* @param wallet: this wallet will receive marketing share.
	* @param share: multiplier will be divided by 100. 30 -> 30%, 3 -> 3% etc.
	*/
	function setMarketingWallet(address wallet, uint256 share) 
		external onlyOwner legitWallet(wallet)
	{
		marketingWallet = wallet;
		marketingShare = share;
		swapExcludedFromFee(wallet, marketingWallet);
	}

	/** 
	* @notice Checks if all required prerequisites are met for us to trigger 
	* expenses send out event.
	*/
	function canExpensify(
		uint256 contractTokenBalance
	) 
		internal 
		view
		returns(bool) 
	{
		return contractTokenBalance >= accumulatedForExpenses 
			&& accumulatedForExpenses >= minToExpenses;
	}

	/**
	* @notice Splits tokens into pieces for licensing, dev and marketing wallets 
	* and sends them out.
	* Note: Shares must add up to 100, otherwise expenses fee will not be 
		distributed properly. And that can invite many other issues.
		So we can't proceed. You will see "Expensify" event triggered on 
		the blockchain with "0, 0, 0" then. This will guide you to check and fix
		your share setup.
		Wallets must be set. But we will not use "require", so not to trigger 
		transaction failure just because someone forgot to set up the wallet 
		addresses. If you see "Expensify" event with "0, 0, 0" values, then 
		check if you have set the wallets.
		@param tokenAmount amount of tokens to take from balance and send out.
	*/
	function expensify(
		uint256 tokenAmount
	) internal lockTheProcess {
		uint256 licensingPiece;
		uint256 devPiece;
		uint256 marketingPiece;

		if (
			licensingShare.add(devShare).add(marketingShare) == 100
			&& licensingWallet != address(0) 
			&& devWallet != address(0)
			&& marketingWallet != address(0)
		) {
			licensingPiece = tokenAmount.mul(licensingShare).div(100);
			devPiece = tokenAmount.mul(devShare).div(100);
			// Make sure all tokens are distributed.
			marketingPiece = tokenAmount.sub(licensingPiece).sub(devPiece);
			_transfer(address(this), licensingWallet, licensingPiece);
			_transfer(address(this), devWallet, devPiece);
			_transfer(address(this), marketingWallet, marketingPiece);
			// Reset the accumulator, only if tokens actually sent, otherwise we keep
			// acumulating until above mentioned things are fixed.
			accumulatedForExpenses = 0;
		}
		
		emit ExpensifyDone(licensingPiece, devPiece, marketingPiece);
	}

/* --------------------------------- Events --------------------------------- */
	event ExpensifyDone(
		uint256 tokensSentToLicensing,
		uint256 tokensSentToDev,
		uint256 tokensSentToMarketing
	);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/Tokenomics.sol";
import "../core/Pancake.sol";
import "../core/RFI.sol";
import "../helpers/Helpers.sol";
import "../features/TxPolice.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Buyback is Ownable, Helpers, Tokenomics, Pancake, RFI, TxPolice {
	using SafeMath for uint256;
	// Will keep tabs on how much BNB from the balance belongs for buyback
	uint256 public bnbAccumulatedForBuyback;

	/** 
	* @notice Checks if all required prerequisites are met for us to trigger 
	* selling of the tokens for later buyback.
	*/
	function canSellForBuyback(
		uint256 contractTokenBalance
	) 
		internal
		view
		returns(bool) 
	{
		return contractTokenBalance >= accumulatedForBuyback 
			&& accumulatedForBuyback >= minToBuyback;
	}

	/**
	* @notice Sells tokens accumulated for buyback. Receives BNB. 
	* Updates the BNB accumulator so we know how much to use for buyback later.
	* NOTE: needs to be tested on testnet!!!
	* @param tokenAmount amount of tokens to take from balance and sell.
	*/
	function sellForBuyback(
		uint256 tokenAmount
	) internal lockTheProcess {
		// Must approve before swapping.
		rfiApprove(address(this), address(uniswapV2Router), tokenAmount);
		uint256 bnbReceived = swapTokensForBnb(tokenAmount);
		// Increment BNB accumulator
		bnbAccumulatedForBuyback = bnbAccumulatedForBuyback.add(bnbReceived);
		// Reset tokens accumulator
		accumulatedForBuyback = 0;
		emit SoldTokensForBuyback(tokenAmount, bnbReceived);
	}

	/**
	* @notice External function, which when called. Will attempt to sell requested 
	* amount of BNB and will send received tokens to a dead address immediately.
	* NOTE: don't forget that bnbAmount passed should be * 10 ** 18
	*/
	function buyback(uint256 bnbAmount) 
		external
		onlyOwner
		onlyIfEnoughBNBAccumulated(bnbAmount, bnbAccumulatedForBuyback)
	{
		address[] memory path = new address[](2);
		path[0] = uniswapV2Router.WETH();
		path[1] = address(this);

		// Make the swap and send to dead address
		uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmount}(
			0,
			path,
			deadAddr,
			block.timestamp
		);

		// Decrement bnb accumulator
		bnbAccumulatedForBuyback = bnbAccumulatedForBuyback.sub(bnbAmount);

		emit BuybackDone(bnbAmount);
	}

/* --------------------------------- Events --------------------------------- */
	event SoldTokensForBuyback(
		uint256 tokensSold,
		uint256 bnbReceived
	);

	event BuybackDone(
		uint256 bnbUsed
	);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../helpers/Helpers.sol";
import "../core/Pancake.sol";
import "../core/RFI.sol";
import "../features/TxPolice.sol";
import "../core/Tokenomics.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract Collateralize is Ownable, Helpers, Tokenomics, Pancake, RFI, TxPolice {
	using SafeMath for uint256;
	// Wallet which will receive BNB tokens for collateral.
	address payable public collateralWallet;
	// Will keep tabs on how much BNB from the balance belongs for collateral.
	uint256 public bnbAccumulatedForCollateral;

	/**
	* @notice External function allowing to set/change collateral wallet.
	* @param wallet: this wallet will receive collateral BNB.
	*/
	function setCollateralWallet(address wallet) 
		external onlyOwner legitWallet(wallet)
	{
		collateralWallet = payable(wallet);
		swapExcludedFromFee(wallet, collateralWallet);
	}

	/** 
	* @notice Checks if all required prerequisites are met for us to trigger 
	* selling of the tokens for later collateralization.
	*/
	function canSellForCollateral(
		uint256 contractTokenBalance
	) 
		internal 
		view
		returns(bool) 
	{
		return contractTokenBalance >= accumulatedForCollateral 
			&& accumulatedForCollateral >= minToCollateral;
	}

	/**
	* @notice Sells tokens accumulated for collateral. Receives BNB.
	* Updates the BNB accumulator so we know how much to use for collateralize later.
	* @param tokenAmount amount of tokens to take from balance and sell.
	* NOTE: needs to be tested on testnet!!!
	* Note: Wallet must be set. But we will not use "require", so not to trigger 
		transaction failure just because someone forgot to set up the wallet address. 
		If you see "SoldTokensForCollateral" event with "0, 0" values, then check if 
		you have set the wallet.
	*/
	function sellForCollateral(
		uint256 tokenAmount
	) internal lockTheProcess {
		uint256 tokensSold;
		uint256 bnbReceived;

		if (collateralWallet != address(0)) {
			// Must approve before swapping.
			rfiApprove(address(this), address(uniswapV2Router), tokenAmount);
			bnbReceived = swapTokensForBnb(tokenAmount);
			tokensSold = tokenAmount;
			// Increment BNB accumulator
			bnbAccumulatedForCollateral = bnbAccumulatedForCollateral.add(bnbReceived);
			// Reset the accumulator, only if tokens actually sold, otherwise we keep
			// acumulating until collateral wallet is set.
			accumulatedForCollateral = 0;
		}
		emit SoldTokensForCollateral(tokensSold, bnbReceived);
	}

	/**
	* @notice External function, which when called. Will attempt to transfer 
	* requested of BNB to collateral wallet.
	* NOTE: don't forget that bnbAmount passed should be * 10 ** 18
	*/
	function collateralize(uint256 bnbAmount)
		external
		onlyOwner
		onlyIfEnoughBNBAccumulated(bnbAmount, bnbAccumulatedForCollateral)
	{
		collateralWallet.transfer(bnbAmount);
		// Decrement bnb accumulator
		bnbAccumulatedForCollateral = bnbAccumulatedForCollateral.sub(bnbAmount);
		emit CollateralizeDone(bnbAmount);
	}

/* --------------------------------- Events --------------------------------- */
	event SoldTokensForCollateral(
		uint256 tokensSold,
		uint256 bnbReceived
	);

	event CollateralizeDone(
		uint256 bnbUsed
	);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../core/Pancake.sol";
import "../core/Tokenomics.sol";
import "../core/RFI.sol";
import "../core/Supply.sol";
import "../features/TxPolice.sol";
import "../libraries/Percent.sol";

abstract contract Distribution is Ownable, Tokenomics, Pancake, RFI, Supply, TxPolice {
	using SafeMath for uint256;
	using Percent for uint256;
	// Will keep tabs on how much BNB from the balance belongs for distribution.
	uint256 public bnbAccumulatedForDistribution;
	// Distribution feature toggle
	bool public isDistributionEnabled;
	// This will hold maximum claimable BNB amount for a distribution cycle.
	uint256 public claimableDistribution;
	// Will show total BNB claimed from the beginning of distribution launch.
	uint256 public totalClaimed;
	// Will show total BNB claimed for teh current cycle.
	uint256 public totalClaimedDuringCycle;
	// Will keep the record about the last claim by holder.
	mapping(address => uint256) internal claimedTimestamp;
	// Record of when was the last cycle set
	uint256 public lastCycleResetTimestamp;
	// Hour multiplier
	uint256 private hour = 60 * 60;
	// Amount of hours for a claim cycle. Cycle will be reset after this passes.
	uint256 public claimCycleHours;

	/** 
	* @notice Checks if all required prerequisites are met for us to trigger 
	* selling of the tokens for later distribution.
	*/
	function canSellForDistribution(
		uint256 contractTokenBalance
	) 
		internal 
		view
		returns(bool) 
	{
		return contractTokenBalance >= accumulatedForDistribution 
			&& accumulatedForDistribution >= minToDistribution;
	}

	/**
	* @notice Sells tokens accumulated for distibution. Receives BNB.
	* Updates the BNB accumulator so we know how much to use for distribution later.
	*	@param tokenAmount amount of tokens to take from balance and sell.
	* NOTE: needs to be tested on testnet!!!
	*/
	function sellForDistribution(
		uint256 tokenAmount
	) internal lockTheProcess {
		// Must approve before swapping.
		rfiApprove(address(this), address(uniswapV2Router), tokenAmount);
		uint256 bnbReceived = swapTokensForBnb(tokenAmount);
		// Increment BNB accumulator
		bnbAccumulatedForDistribution = bnbAccumulatedForDistribution.add(bnbReceived);
		// Reset the accumulator.
		accumulatedForDistribution = 0;
		emit SoldTokensForDistribution(tokenAmount, bnbReceived);
	}

	/**
	* @notice External function allows to enable the reward distribution feature.
	* Some BNB must be already accumulated for this to work.
	* NOTE: Can be used to reset the cycle from the outside too.
	* @param cycleHours set or reset the hours for the distribution cycle
	* @return amount of BNB set as claimable for this cycle
	*/
	function enableRewardDistribution(uint256 cycleHours) 
		external 
		onlyOwner 
		returns(uint256) 
	{
		require(cycleHours > 0, "Cycle hours can't be 0.");
		require(bnbAccumulatedForDistribution > 0, "Don't have BNB for distribution.");
		isDistributionEnabled = true;
		resetClaimDistributionCycle(cycleHours);
		return claimableDistribution;
	}

	/**
	* @notice External function allowing to stop reward distribution.
	* NOTE: must call enableRewardDistribution() to start it again.
	*/
	function disableRewardDistribution() external onlyOwner returns(bool) {
		isDistributionEnabled = false;
		return true;
	}

	/**
	* @notice Tells if reward claim cycle has ended since the last reset.
	*/
	function hasCyclePassed() public view returns(bool) {
		uint256 timeSinceReset = block.timestamp.sub(lastCycleResetTimestamp);
		return timeSinceReset > claimCycleHours.mul(hour);
	}

	/**
	* @notice Tells if the address has already claimed during the current cycle.
	*/
	function hasAlreadyClaimed(address holderAddr) public view returns(bool) {
		uint256 lastClaim = claimedTimestamp[holderAddr];
		uint256 timeSinceLastClaim = block.timestamp.sub(lastClaim);
		return timeSinceLastClaim < claimCycleHours.mul(hour);
	}

	/**
	* @notice Calculates a share of BNB belonging to a holder based on his holdings.
	*/
	function calcClaimableShare(address holderAddr) public view returns(uint256) {
		uint256 circulatingSupply = totalCirculatingSupply();
		uint256 LPTokens = balanceOf(uniswapV2Pair);
		uint256 totalHoldingAmount = circulatingSupply.sub(LPTokens);
		uint256 bnbShare = totalHoldingAmount.percent(balanceOf(holderAddr), 18);
		uint256 bnbToSend = bnbShare.percentOf(claimableDistribution, 1 * 10 ** 18);






		return bnbToSend;
	}

	/**
	* @notice Resets the reward claim cycle with a new hours value. 
	* Assigns new 'claimableDistribution' and resets lastCycleResetTimestamp.
	*/
	function resetClaimDistributionCycle(uint256 cycleHours) 
		internal
	{
		require(cycleHours > 0, "Cycle hours can't be 0.");

		claimCycleHours = cycleHours;
		// Update the total for the historic record
		totalClaimed = totalClaimed.add(totalClaimedDuringCycle);
		// First sync main accumulator


		bnbAccumulatedForDistribution = bnbAccumulatedForDistribution.sub(
			totalClaimedDuringCycle
		);
		// Don't forget to reset total for cycle!
		totalClaimedDuringCycle = 0;
		// Set claimable with the synced main accumulator
		claimableDistribution = bnbAccumulatedForDistribution;

		// Rest time stamp
		lastCycleResetTimestamp = block.timestamp;
	}

	/**
	* Allows any holder to call this function and claim the a share of BNB 
	* belonging to him basec on the holding amount, current claimable amount.
	* Claiming can be done only once per cycle.
	*/
	function claimReward() 
		external
		onlyHolder
		returns(uint256)
	{
		address sender = _msgSender();
		require(isDistributionEnabled, "Distribution is disabled.");
		require(!hasAlreadyClaimed(sender), "Already claimed in the current cycle.");
		if (hasCyclePassed()) {
			// Reset with same cycle hours.
			resetClaimDistributionCycle(claimCycleHours);
		}
		uint256 bnbShare = calcClaimableShare(sender);
		payable(sender).transfer(bnbShare);
		claimedTimestamp[sender] = block.timestamp;
		totalClaimedDuringCycle = totalClaimedDuringCycle.add(bnbShare);
		return bnbShare;
	}

/* --------------------------------- Events --------------------------------- */

	event SoldTokensForDistribution(
		uint256 tokensSold,
		uint256 bnbReceived
	);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../core/Pancake.sol";
import "../core/Tokenomics.sol";
import "../core/RFI.sol";
import "../core/Supply.sol";

abstract contract TxPolice is Tokenomics, Pancake, RFI, Supply {
	using SafeMath for uint256;
	// Wallet hard cap 0.01% of total supply
	uint256 public maxWalletSize = _tTotal.mul(1).div(100);
	// 0.01% per transaction
	uint256 public maxTxAmount = _tTotal.mul(1).div(100);
	// Convenience enum to differentiate transaction limit types.
	enum TransactionLimitType { TRANSACTION, WALLET, SELL }
	// Convenience enum to differentiate transaction types.
	enum TransactionType { REGULAR, SELL, BUY }

	// Global toggle to avoid trigger loops
	bool internal inTriggerProcess;
	modifier lockTheProcess {
		inTriggerProcess = true;
		_;
		inTriggerProcess = false;
	}

	// Sometimes you just have addresses which should be exempt from any 
	// limitations and fees.
	mapping(address => bool) public specialAddresses;

	// Toggle multiple exemptions from transaction limits.
	struct LimitExemptions {
		bool all;
		bool transaction;
		bool wallet;
		bool sell;
		bool fees;
	}

	// Keeps a record of addresses with limitation exemptions
	mapping(address => LimitExemptions) internal limitExemptions;

/* --------------------------- Exemption Utilities -------------------------- */

	/**
	* @notice External function allowing owner to toggle various limit exemptions
	* for any address.
	*/
	function toggleLimitExemptions(
		address addr, 
		bool allToggle, 
		bool txToggle, 
		bool walletToggle, 
		bool sellToggle,
		bool feesToggle
	) 
		public 
		onlyOwner
	{
		LimitExemptions memory ex = limitExemptions[addr];
		ex.all = allToggle;
		ex.transaction = txToggle;
		ex.wallet = walletToggle;
		ex.sell = sellToggle;
		ex.fees = feesToggle;
		limitExemptions[addr] = ex;
	}

	/**
	* @notice External function allowing owner toggle any address as special address.
	*/
	function toggleSpecialWallets(address specialAddr, bool toggle) 
		external 
		onlyOwner 
	{
		specialAddresses[specialAddr] = toggle;
	}

/* ------------------------------- Sell Limit ------------------------------- */
	// Toggle for sell limit feature
	bool public isSellLimitEnabled = true;
	// Sell limit cycle period
	uint256 public sellCycleHours = 24;
	// Hour multiplier
	uint256 private hour = 60 * 60;
	// Changing this you can increase/decrease decimals of your maxSellAllowancePerCycle 
	uint256 public maxSellAllowanceMultiplier = 1000;
	// (address => amount)
	mapping(address => uint256) private cycleSells;
	// (address => lastTimestamp)
	mapping(address => uint256) private lastSellTimestamp;

	/**
	* @notice Tracks and limits sell transactions per user per cycle set.
	* Unless user is a special address or has exemptions.
	*/
	function enforceCyclicSellLimit(address from, address to, uint256 amount) 
		internal 
	{
		// Identify if selling... otherwise quit.
		bool isSell = getTransactionType(from, to) == TransactionType.SELL;

		// Guards
		// Get exemptions if any for tx sender and receiver.
		if (
			limitExemptions[from].all
			|| limitExemptions[from].sell
			|| specialAddresses[from] 
			|| !isSellLimitEnabled
		) { 





			return; 
		}

		if (!isSell) { return; }

		// First check if sell amount doesn't exceed total max allowance.
		uint256 maxAllowance = maxSellAllowancePerCycle();

		require(amount <= maxAllowance, "Can't sell more than cycle allowance!");

		// Then check if sell cycle has passed. If so, just update the maps and quit.
		if (hasSellCycleEnded(from)) {
			lastSellTimestamp[from] = block.timestamp;
			cycleSells[from] = amount;
			return;
		}

		// If cycle has not yet passed... check if combined amount doesn't excceed the max allowance.
		uint256 combinedAmount = amount.add(cycleSells[from]);

		require(combinedAmount <= maxAllowance, "Combined cycle sell amount exceeds cycle allowance!");

		// If all good just increment sells map. (don't update timestamp map, cause then 
		// sell cycle will never end for this poor holder...)
		cycleSells[from] = cycleSells[from].add(amount);
		return;
	}

	/**
	 * @notice Calculates current maximum sell allowance per day based on the 
	 * total circulating supply.
	 */
	function maxSellAllowancePerCycle() public view returns(uint256) {
		// 0.1% of total circulating supply.
		return totalCirculatingSupply().mul(1).div(maxSellAllowanceMultiplier);
	}

	/**
	* @notice Allows to adjust your maxSellAllowancePerCycle.
	* 1000 = 0.1% 
	*/
	function setMaxSellAllowanceMultiplier(uint256 mult) external onlyOwner {
		require(mult > 0, "Multiplier can't be 0.");
		maxSellAllowanceMultiplier = mult;
	}

	function hasSellCycleEnded(address holderAddr) 
		internal 
		view  
		returns(bool) 
	{
		uint256 lastSell = lastSellTimestamp[holderAddr];
		uint256 timeSinceLastSell = block.timestamp.sub(lastSell);
		bool cycleEnded = timeSinceLastSell >= sellCycleHours.mul(hour);



		return cycleEnded;
	}

	/**
	* @notice External functions which allows to set selling limit period.
	*/
	function setSellCycleHours(uint256 hoursCycle) external onlyOwner {
		require(hoursCycle >= 0, "Hours can't be 0.");
		sellCycleHours = hoursCycle;
	}

	/**
	* @notice External functions which allows to disable selling limits.
	*/
	function disableSellLimit() external onlyOwner {
		require(isSellLimitEnabled, "Selling limit already enabled.");
		isSellLimitEnabled = false;
	}

	/**
	* @notice External functions which allows to enable selling limits.
	*/
	function enableSellLimit() external onlyOwner {
		require(!isSellLimitEnabled, "Selling limit already disabled.");
		isSellLimitEnabled = true;
	}

	/**
	* @notice External function which can be called by a holder to see how much 
	* sell allowance is left for the current cycle period.
	*/
	function sellAllowanceLeft() external view returns(uint256) {
		address sender = _msgSender();
		bool isSpecial = specialAddresses[sender];
		bool isExemptFromAll = limitExemptions[sender].all;
		bool isExemptFromSell = limitExemptions[sender].sell;
		bool isExemptFromWallet = limitExemptions[sender].wallet;
		
		// First guard exemptions
		if (
			isSpecial || isExemptFromAll 
			|| (isExemptFromSell && isExemptFromWallet)) 
		{
			return balanceOf(sender);
		} else if (isExemptFromSell && !isExemptFromWallet) {
			return maxWalletSize;
		}

		// Next quard toggle and check cycle
		uint256 maxAllowance = maxWalletSize;
		if (isSellLimitEnabled) {
			maxAllowance = maxSellAllowancePerCycle();
			if (!hasSellCycleEnded(sender)) {
				maxAllowance = maxAllowance.sub(cycleSells[sender]);
			}
		} else if (isExemptFromWallet) {
			maxAllowance = balanceOf(sender);
		}
		return maxAllowance;
	}

/* --------------------------------- Guards --------------------------------- */

	/**
	* @notice Checks passed multiple limitTypes and if required enforces maximum
	* limits.
	* NOTE: extend this function with more limit types if needed.
	*/
	function guardMaxLimits(
		address from, 
		address to, 
		uint256 amount,
		TransactionLimitType[2] memory limitTypes
	) internal view {
		// Get exemptions if any for tx sender and receiver.
		LimitExemptions memory senderExemptions = limitExemptions[from];
		LimitExemptions memory receiverExemptions = limitExemptions[to];

		// First check if any special cases
		if (
			senderExemptions.all && receiverExemptions.all 
			|| specialAddresses[from] 
			|| specialAddresses[to] 
			|| liquidityPools[to]
		) { return; }

		// If no... then go through each limit type and apply if no exemptions.
		for (uint256 i = 0; i < limitTypes.length; i += 1) {
			if (
				limitTypes[i] == TransactionLimitType.TRANSACTION 
				&& !senderExemptions.transaction
			) {
				require(
					amount <= maxTxAmount,
					"Transfer amount exceeds the maxTxAmount."
				);
			}
			if (
				limitTypes[i] == TransactionLimitType.WALLET 
				&& !receiverExemptions.wallet
			) {
				uint256 toBalance = balanceOf(to);
				require(
					toBalance.add(amount) <= maxWalletSize,
					"Exceeds maximum wallet size allowed."
				);
			}
		}
	}

/* ---------------------------------- Fees ---------------------------------- */

function canTakeFee(address from, address to) 
	internal view returns(bool) 
{	
	bool take = true;
	if (
		limitExemptions[from].all 
		|| limitExemptions[to].all
		|| limitExemptions[from].fees 
		|| limitExemptions[to].fees 
		|| specialAddresses[from] 
		|| specialAddresses[to]
	) { take = false; }

	return take;
}

/**
	* @notice Updates old and new wallet fee exemptions.
	*/
	function swapExcludedFromFee(address newWallet, address oldWallet) internal {
		if (oldWallet != address(0)) {
			toggleLimitExemptions(oldWallet, false, false, false, false, false);
		}
		toggleLimitExemptions(newWallet, false, false, false, true, true);
	}

/* --------------------------------- Helpers -------------------------------- */

	/**
	* @notice Helper function to determine what kind of transaction it is.
	* @param from transaction sender
	* @param to transaction receiver
	*/
	function getTransactionType(address from, address to) 
		internal view returns(TransactionType)
	{
		if (liquidityPools[from] && !liquidityPools[to]) {
			// LP -> addr
			return TransactionType.BUY;
		} else if (!liquidityPools[from] && liquidityPools[to]) {
			// addr -> LP
			return TransactionType.SELL;
		}
		return TransactionType.REGULAR;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract Pancake is Ownable {
	using SafeMath for uint256;
	// Using Uniswap lib, because Pancakeswap forks are trash ATM...
	IUniswapV2Router02 internal uniswapV2Router;
	// We will call createPair() when we decide. To avoid snippers and bots.
	address internal uniswapV2Pair;
	// This will be set when we call initDEXRouter().
	address internal routerAddr;
	// To keep track of all LPs.
	mapping(address => bool) public liquidityPools;

	// To receive BNB from pancakeV2Router when swaping
	receive() external payable {}

	/**
	* @notice Initialises PCS router using the address. In addition creates a pair.
	* @param router Pancakeswap router address
	*/
	function initDEXRouter(address router) 
		external
		onlyOwner
	{
		// In case we already have set uniswapV2Pair before, remove it from LPs mapping.
		if (uniswapV2Pair != address(0)) {
			removeAddressFromLPs(uniswapV2Pair);
		}
		routerAddr = router;
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
		uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
			address(this), 
			_uniswapV2Router.WETH()
		);
		uniswapV2Router = _uniswapV2Router;
		addAddressToLPs(uniswapV2Pair);
		emit RouterSet(router, uniswapV2Pair);
	}

	/**
	 * @notice Swaps passed tokens for BNB using Pancakeswap router and returns 
	 * actual amount received.
	 */
	function swapTokensForBnb(
		uint256 tokenAmount
	) internal returns(uint256) {
		uint256 initialBalance = address(this).balance;
		// generate the pancake pair path of token -> wbnb
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();

		// Make the swap
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // accept any amount of BNB
			path,
			address(this),
			block.timestamp
		);

		uint256 bnbReceived = address(this).balance.sub(initialBalance);
		return bnbReceived;
	}

	/**
	* @notice Adds address to a liquidity pool map. Can be called externaly.
	*/
	function addAddressToLPs(address lpAddr) public onlyOwner {
		liquidityPools[lpAddr] = true;
	}

	/**
	* @notice Removes address from a liquidity pool map. Can be called externaly.
	*/
	function removeAddressFromLPs(address lpAddr) public onlyOwner {
		liquidityPools[lpAddr] = false;
	}

/* --------------------------------- Events --------------------------------- */
	event RouterSet(address indexed router, address indexed pair);

/* -------------------------------- Modifiers ------------------------------- */
	modifier pcsInitialized {
		require(routerAddr != address(0), 'Router address has not been set!');
		require(uniswapV2Pair != address(0), 'PCS pair not created yet!');
		_;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



abstract contract Helpers {

/* -------------------------------- Modifiers ------------------------------- */

	modifier legitWallet(address wallet) {
		require(wallet != address(0), "Wallet address must be set!");
		require(wallet != address(this), "Wallet address can't be this contract.");
		_;
	}

	modifier onlyIfEnoughBNBAccumulated(uint256 bnbRequested, uint256 bnbAccumulator) {
		require(bnbRequested <= bnbAccumulator, "Not enough BNB accumulated.");
		// This should not ever happen...
		require(bnbRequested <= address(this).balance, "Not enough BNB in the wallet.");
		_;
	}
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Tokenomics.sol";
import "./RFI.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract Supply is Tokenomics, RFI {
	using SafeMath for uint256;
	/**
	 * @notice Calculates current total circulating supply by substracting "burned"
	 * tokens.
	 */
	function totalCirculatingSupply() public view returns(uint256) {
		return _tTotal.sub(balanceOf(deadAddr));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Percent {
	using SafeMath for uint256;

	/**
	* @dev Returns numerator percentage of denominator. Uses precision for rounding.
	* e.x. 350.percent(150, 3), 4, will retun 4286, which is 42.86%
	* e.x. 350.percent(150, 3), 3 will return 429, which is 42.9%
	* e.x. 350.percent(150, 3), 2 will return 43, which is 43%
	@param denominator number which we calculate percentage of
	@param numerator number we calculate percentage for
	@param precision decimal point shift
	*/
	function percent( 
		uint256 denominator, 
		uint256 numerator,
		uint256 precision
	) 
		internal
		pure 
		returns(uint256) 
	{
		uint256 _numerator = numerator * 10 ** (precision.add(1));
		// with rounding of last digit
		uint256 _quotient = ((_numerator.div(denominator)).add(5)).div(10);
		return ( _quotient);
	}

	/**
	* @dev Returns a number calculated as a percentage y of value x. 
	* Use scale based on the y.
	* e.x 429.percentOf(350, 1000) will return 150
	* e.x 429.percentOf(350, 10000) will return 15
	*/
	function percentOf(
		uint256 y, 
		uint256 x, 
		uint128 scale
	) 
		internal 
		pure 
		returns(uint256) 
	{
		uint256 a = x.div(scale);
		uint256 b = x.mod(scale);
		uint256 c = y.div(scale);
		uint256 d = y.mod(scale);
		
		uint256 piece1 = a.mul(c).mul(scale).add(a);
		uint256 piece2 = piece1.mul(d).add(b).mul(c);
		uint256 piece3 = piece2.add(b).mul(d).div(scale);
		return piece3;
	}
}

