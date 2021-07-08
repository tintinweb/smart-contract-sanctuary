// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

interface IBEP20 {
	/**
	 * @dev Returns the amount of tokens in existence.
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @dev Returns the token decimals.
	 */
	function decimals() external view returns (uint8);

	/**
	 * @dev Returns the token symbol.
	 */
	function symbol() external view returns (string memory);

	/**
	 * @dev Returns the token name.
	 */
	function name() external view returns (string memory);

	/**
	 * @dev Returns the bep token owner.
	 */
	function getOwner() external view returns (address);

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
	function allowance(address _owner, address spender) external view returns (uint256);

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

contract DOGGGO is Ownable, IBEP20 {
	using SafeMath for uint256;
	using Math for uint256;

	struct past_tx {
		uint256 cum_transfer;
		uint256 last_timestamp;
		uint256 last_claim;
	}

	struct prop_balances {
		uint256 reward_pool;
		uint256 liquidity_pool;
	}

	mapping(address => uint256) private _balances;
	mapping(address => past_tx) private _last_tx;
	mapping(address => mapping(address => uint256)) private _allowances;
	mapping(address => bool) private excluded;

	uint8 private _decimals = 18;
	uint8 public pcs_pool_to_circ_ratio = 10; // 10%

	uint32 public reset_rate = 1 days;

	uint256 private _totalSupply = 10**14 * 10**_decimals;
	uint256 public swap_for_liquidity_threshold = 10**12 * 10**_decimals; // 1%
	uint256 public swap_for_reward_threshold = 10**12 * 10**_decimals;

	uint8 public charity_fee = 1; // 0.1%
	uint8 public fixed_fee = 50; // 5%
	uint8 public max_daily_sell = 1; // 0.1%

	bool public circuit_breaker;
	bool private liq_swap_reentrancy_guard;
	bool private reward_swap_reentrancy_guard;

	string private _name = "DOGGGO";
	string private _symbol = "DOGGGO";

	address public LP_recipient;
	address public charity_wallet;
	address public reward_wallet;

	IUniswapV2Pair public pair;
	IUniswapV2Router02 public router;

	prop_balances private balancer_balances;

	event AddRewards(string);
	event BalancerPools(uint256, uint256);
	event AddLiq(string);
	event balancerReset(uint256, uint256);
	event TaxRatesChanged();

	constructor(address _router, address _reward_wallet) {
		//create pair to get the pair address
		router = IUniswapV2Router02(_router);
		IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
		pair = IUniswapV2Pair(factory.createPair(address(this), router.WETH()));

		LP_recipient = address(0x000000000000000000000000000000000000dEaD);
		charity_wallet = address(0x8B99F3660622e21f2910ECCA7fBe51d654a1517D);
		reward_wallet = _reward_wallet;

		excluded[msg.sender] = true; //exclude owner address
		excluded[address(this)] = true; //exclude contract address
		excluded[charity_wallet] = true; //exclude charity address from max_tx

		circuit_breaker = true; //ERC20 behavior by default/presale

		_balances[msg.sender] = _totalSupply;
		emit Transfer(address(0), msg.sender, _totalSupply);
	}

	function decimals() external view override returns (uint8) {
		return _decimals;
	}

	function name() external view override returns (string memory) {
		return _name;
	}

	function symbol() external view override returns (string memory) {
		return _symbol;
	}

	function totalSupply() public view override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) external view override returns (uint256) {
		return _balances[account];
	}

	function getOwner() external view override returns (address) {
		return owner();
	}

	function transfer(address recipient, uint256 amount) public override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) external override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external override returns (bool) {
		_transfer(sender, recipient, amount);

		uint256 currentAllowance = _allowances[sender][_msgSender()];
		require(currentAllowance >= amount, "DOGGGO: transfer amount exceeds allowance");
		_approve(sender, _msgSender(), currentAllowance - amount);

		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
		uint256 currentAllowance = _allowances[_msgSender()][spender];
		require(currentAllowance >= subtractedValue, "DOGGGO: decreased allowance below zero");
		_approve(_msgSender(), spender, currentAllowance - subtractedValue);

		return true;
	}

	function _approve(
		address owner,
		address spender,
		uint256 amount
	) private {
		require(owner != address(0), "DOGGGO: approve from the zero address");
		require(spender != address(0), "DOGGGO: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) private {
		require(sender != address(0), "DOGGGO: transfer from the zero address");

		uint256 senderBalance = _balances[sender];
		require(senderBalance >= amount, "DOGGGO: transfer amount exceeds balance");

		// >1 day since last tx
		if (block.timestamp > _last_tx[sender].last_timestamp + 1 days) {
			_last_tx[sender].cum_transfer = 0;
		}

		uint256 sell_tax = 0;
		uint256 charity_tax = 0;
		uint256 balancer_tax = 0;

		if (excluded[sender] == false && excluded[recipient] == false && circuit_breaker == false) {
			(uint112 _reserve0, uint112 _reserve1, ) = pair.getReserves(); // returns reserve0, reserve1, timestamp last tx
			if (address(this) != pair.token0()) {
				// check if token reserves response is inverted
				(_reserve0, _reserve1) = (_reserve1, _reserve0);
			}

			if (recipient == address(pair)) {
				sell_tax = sellingTax(sender, amount, _reserve0); // will update the balancer ledger too
			}

			charity_tax = amount.mul(charity_fee).div(10**3);

			balancer_tax = amount.mul(fixed_fee).div(10**3);
			balancer(balancer_tax, _reserve0);

			//@dev every extra token are collected into address(this), it's the balancer job to then split them
			//between pool and reward, using the dedicated struct
			_balances[address(this)] += sell_tax.add(balancer_tax);
			_balances[charity_wallet] += charity_tax;
		}

		//reward reinit
		_last_tx[recipient].last_timestamp = block.timestamp;

		_balances[sender] = senderBalance.sub(amount);
		_balances[recipient] += amount.sub(sell_tax).sub(charity_tax).sub(balancer_tax);

		emit Transfer(sender, recipient, amount);
		emit Transfer(sender, address(this), sell_tax);
		emit Transfer(sender, address(this), balancer_tax);
		emit Transfer(sender, charity_wallet, charity_tax);
	}

	// @dev take a selling tax based on amount of token dumped
	function sellingTax(
		address sender,
		uint256 amount,
		uint256 pool_balance
	) private returns (uint256 sell_tax) {
		uint256 new_cum_sum = amount.add(_last_tx[sender].cum_transfer);

		if (new_cum_sum > _totalSupply.mul(max_daily_sell).div(10**3) || new_cum_sum > pool_balance.mul(fixed_fee).div(10**3)) {
			revert("DOGGGO: selling amount is above max allowed");
		} else {
			// dynamic sell fee: based on amount of token dumped
			uint256 unwght_circ_supply = totalSupply().sub(_balances[charity_wallet]);
			uint256 sell_fee = new_cum_sum.mul(10**5).ceilDiv(unwght_circ_supply);
			sell_tax = new_cum_sum.mul(sell_fee).div(10**3);
		}

		_last_tx[sender].cum_transfer = new_cum_sum;

		balancer_balances.reward_pool += sell_tax;

		return sell_tax;
	}

	// @dev take the fixed tax as input, split it between reward and liq subpools
	// according to pool condition -> circ-pool/circ supply closer to one implies
	// priority to the reward pool
	function balancer(uint256 amount, uint256 pool_balance) private {
		uint256 unwght_circ_supply = totalSupply().sub(_balances[charity_wallet]);

		// we aim at a set % of liquidity pool (defaut 10% of circ supply), 100% in pancake swap is NOT a good news
		uint256 supply_to_balance = pool_balance < unwght_circ_supply.mul(pcs_pool_to_circ_ratio).div(10**2)
			? unwght_circ_supply.mul(pcs_pool_to_circ_ratio).div(10**2)
			: pool_balance;

		uint256 supply_to_balance_without_pool_balance = supply_to_balance.sub(pool_balance);

		// TODO: testare cosa succede con un numero molto basso. arrotonda male?
		balancer_balances.liquidity_pool += amount.mul(supply_to_balance_without_pool_balance).div(supply_to_balance);
		balancer_balances.reward_pool += amount.mul(supply_to_balance.sub(supply_to_balance_without_pool_balance)).div(supply_to_balance);

		prop_balances memory _balancer_balances = balancer_balances;

		if (_balancer_balances.liquidity_pool >= swap_for_liquidity_threshold && !liq_swap_reentrancy_guard) {
			liq_swap_reentrancy_guard = true;
			uint256 token_out = addLiquidity(_balancer_balances.liquidity_pool);
			balancer_balances.liquidity_pool -= token_out; //not balanceOf, in case addLiq revert
			liq_swap_reentrancy_guard = false;
		}

		if (_balancer_balances.reward_pool >= swap_for_reward_threshold && !reward_swap_reentrancy_guard) {
			reward_swap_reentrancy_guard = true;
			uint256 token_out = sendToRewardAddress(_balancer_balances.reward_pool);
			balancer_balances.reward_pool -= token_out;
			reward_swap_reentrancy_guard = false;
		}

		emit BalancerPools(_balancer_balances.liquidity_pool, _balancer_balances.reward_pool);
	}

	//@dev when triggered, will swap and provide liquidity
	//    BNBfromSwap being the difference between and after the swap, slippage
	//    will result in extra-BNB for the reward pool (free money for the guys:)
	function addLiquidity(uint256 token_amount) private returns (uint256) {
		uint256 BNBfromReward = address(this).balance;

		address[] memory route = new address[](2);
		route[0] = address(this);
		route[1] = router.WETH();

		if (allowance(address(this), address(router)) < token_amount) {
			_allowances[address(this)][address(router)] = type(uint256).max;
			emit Approval(address(this), address(router), type(uint256).max);
		}

		//odd numbers management
		uint256 half = token_amount.div(2);
		uint256 half_2 = token_amount.sub(half);

		try router.swapExactTokensForETHSupportingFeeOnTransferTokens(half, 0, route, address(this), block.timestamp) {
			uint256 BNBfromSwap = address(this).balance.sub(BNBfromReward);
			router.addLiquidityETH{ value: BNBfromSwap }(address(this), half_2, 0, 0, LP_recipient, block.timestamp); //will not be catched
			emit AddLiq("Liquidity increased");
			return token_amount;
		} catch {
			emit AddLiq("Liquidity failed");
			return 0;
		}
	}

	function sendToRewardAddress(uint256 token_amount) private returns (uint256) {
		_balances[reward_wallet] += token_amount;
		emit AddRewards("Rewards increased");
		return token_amount;
	}

	function resetBalancer() external onlyOwner {
		uint256 _contract_balance = _balances[address(this)];
		balancer_balances.reward_pool = _contract_balance.div(2);
		balancer_balances.liquidity_pool = _contract_balance.div(2);
		emit balancerReset(balancer_balances.reward_pool, balancer_balances.liquidity_pool);
	}

	function excludeFromTaxes(address adr) external onlyOwner {
		require(!excluded[adr], "already excluded");
		excluded[adr] = true;
	}

	function includeInTaxes(address adr) external onlyOwner {
		require(excluded[adr], "already taxed");
		excluded[adr] = false;
	}

	function isExcluded(address adr) external view returns (bool) {
		return excluded[adr];
	}

	//@dev frontend integration
	function endOfPeriod() external view returns (uint256) {
		return _last_tx[msg.sender].last_claim + reset_rate;
	}

	//@dev will bypass all the taxes and act as erc20.
	//pools & balancer balances will remain untouched
	function setCircuitBreaker(bool status) external onlyOwner {
		circuit_breaker = status;
	}

	function setSwapForLiqThreshold(uint128 threshold_in_token) external onlyOwner {
		swap_for_liquidity_threshold = threshold_in_token * 10**_decimals;
	}

	function setSwapForRewardThreshold(uint128 threshold_in_token) external onlyOwner {
		swap_for_reward_threshold = threshold_in_token * 10**_decimals;
	}

	function setMaxDailySell(uint8 new_max_daily_sell) external onlyOwner {
		require(new_max_daily_sell >= 1 && new_max_daily_sell <= 10, "already taxed");
		max_daily_sell = new_max_daily_sell;
		emit TaxRatesChanged();
	}

	function setCharityFee(uint8 new_charity_fee) external onlyOwner {
		require(new_charity_fee >= 1 && new_charity_fee <= 10, "new fee out of possible values");
		charity_fee = new_charity_fee;
		emit TaxRatesChanged();
	}

	function setFixedFee(uint8 new_fixed_fee) external onlyOwner {
		require(new_fixed_fee >= 20 && new_fixed_fee <= 50, "new fee out of possible values");
		fixed_fee = new_fixed_fee;
		emit TaxRatesChanged();
	}

	//@dev fallback in order to receive BNB from swapToBNB
	receive() external payable {}
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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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