//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IUniswapV2ERC20.sol";
import "../interfaces/IVault.sol";
import "../interfaces/ICurvePool.sol";
import "../interfaces/IDistribution.sol";
import "../interfaces/IStrat2.sol";
import "../interfaces/IAaveIncentives.sol";
import "../interfaces/IAToken.sol";
import "../interfaces/IMemory.sol";
import "../interfaces/IFeeManager.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract GeneralAdapter is OwnableUpgradeable {
	using SafeMath for uint256;

	enum VaultType {
		CURVE,
		QUICK,
		MSTABLE
	}

	address public memoryAddress;

	address public incentivesAddress;

	address public feeManager;

	mapping(address => address) public priceFeeds;

	mapping(address => address) public curvePools;

	struct VaultInfo {
		address depositToken;
		address rewardsToken;
		address strategy;
		address distribution;
		address stakingContract;
		uint256 totalDeposits;
		uint256 totalDepositsUSD;
		uint256 ethaRewardsRate;
		uint256 performanceFee;
		uint256 withdrawalFee;
	}

	function initialize(
		address[] memory tokens,
		address[] memory feeds,
		address _memoryAddress,
		address _incentivesAddress,
		address _feeManager
	) public initializer {
		__Ownable_init();

		memoryAddress = _memoryAddress;
		incentivesAddress = _incentivesAddress;
		feeManager = _feeManager;

		for (uint256 i = 0; i < tokens.length; i++) {
			priceFeeds[tokens[i]] = feeds[i];
		}
	}

	function setPriceFeed(address token, address feed) external onlyOwner {
		priceFeeds[token] = feed;
	}

	function setCurvePool(address lpToken, address pool) external onlyOwner {
		curvePools[lpToken] = pool;
	}

	function setMemoryAddress(address _memoryAddress) external onlyOwner {
		memoryAddress = _memoryAddress;
	}

	function setIncentivesAddress(address _incentivesAddress)
		external
		onlyOwner
	{
		incentivesAddress = _incentivesAddress;
	}

	function setFeeManagerAddress(address _feeManager) external onlyOwner {
		feeManager = _feeManager;
	}

	function formatDecimals(address token, uint256 amount)
		public
		view
		returns (uint256)
	{
		uint256 decimals = IERC20Metadata(token).decimals();

		if (decimals == 18) return amount;
		else return amount.mul(1 ether).div(10**decimals);
	}

	function getQuickswapBalance(address _pair, uint256 lpBalance)
		public
		view
		returns (
			uint256 totalSupply,
			uint256 totalMarket,
			uint256 lpValueUSD
		)
	{
		IUniswapV2ERC20 pair = IUniswapV2ERC20(_pair);

		(uint112 _reserve0, uint112 _reserve1, ) = pair.getReserves();

		totalSupply = pair.totalSupply();

		address token0 = pair.token0();
		address token1 = pair.token1();

		(, int256 token0Price, , , ) = AggregatorV3Interface(priceFeeds[token0])
			.latestRoundData();
		(, int256 token1Price, , , ) = AggregatorV3Interface(priceFeeds[token1])
			.latestRoundData();

		totalMarket = uint256(
			formatDecimals(token0, _reserve0).mul(uint256(token0Price)).div(
				10**8
			)
		).add(
				uint256(formatDecimals(token1, _reserve1))
					.mul(uint256(token1Price))
					.div(10**8)
			);

		lpValueUSD = lpBalance.mul(totalMarket).div(totalSupply);
	}

	function getVaultInfo(IVault vault, VaultType vaultType)
		external
		view
		returns (VaultInfo memory info)
	{
		info.depositToken = address(vault.underlying());
		info.rewardsToken = address(vault.target());
		info.strategy = address(vault.strat());
		info.distribution = vault.distribution();
		info.totalDeposits = vault.calcTotalValue();
		info.performanceFee = vault.performanceFee();
		info.withdrawalFee = IFeeManager(feeManager).getVaultFee(
			address(vault)
		);
		IDistribution dist = IDistribution(info.distribution);
		info.ethaRewardsRate = address(dist) == address(0)
			? 0
			: dist.rewardRate();

		if (vaultType == VaultType.CURVE) {
			info.totalDepositsUSD = info
				.totalDeposits
				.mul(
					ICurvePool(curvePools[info.depositToken])
						.get_virtual_price()
				)
				.div(1 ether);

			info.stakingContract = IStrat2(info.strategy).gauge();
		}

		if (vaultType == VaultType.QUICK) {
			(, , uint256 usdValue) = getQuickswapBalance(
				info.depositToken,
				info.totalDeposits
			);
			info.totalDepositsUSD = usdValue;
			info.stakingContract = IStrat2(info.strategy).staking();
		}
	}

	function getAaveRewards(address[] memory _tokens)
		public
		view
		returns (uint256[] memory)
	{
		IAaveIncentives incentives = IAaveIncentives(incentivesAddress);

		uint256[] memory _rewards = new uint256[](_tokens.length);

		for (uint256 i = 0; i < _tokens.length; i++) {
			IAToken aToken = IAToken(
				IMemory(memoryAddress).getAToken(_tokens[i])
			);

			uint256 totalSupply = formatDecimals(
				address(aToken),
				aToken.totalSupply()
			);

			(uint256 emissionPerSecond, , ) = incentives.assets(
				address(aToken)
			);

			(, int256 maticPrice, , , ) = AggregatorV3Interface(
				priceFeeds[0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE]
			).latestRoundData();
			(, int256 tokenPrice, , , ) = AggregatorV3Interface(
				priceFeeds[_tokens[i]]
			).latestRoundData();

			_rewards[i] = emissionPerSecond
				.mul(uint256(maticPrice))
				.mul(365 days)
				.mul(1 ether)
				.div(totalSupply)
				.div(uint256(tokenPrice));
		}

		return _rewards;
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2ERC20 {
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function name() external pure returns (string memory);

	function symbol() external pure returns (string memory);

	function decimals() external pure returns (uint8);

	function totalSupply() external view returns (uint256);

	function getReserves()
		external
		view
		returns (
			uint112 _reserve0,
			uint112 _reserve1,
			uint32 _blockTimestampLast
		);

	function balanceOf(address owner) external view returns (uint256);

	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function PERMIT_TYPEHASH() external pure returns (bytes32);

	function nonces(address owner) external view returns (uint256);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	function token0() external view returns (address);

	function token1() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Detailed is IERC20 {
	function decimals() external view returns (uint8);
}

interface IVault {
	function totalSupply() external view returns (uint256);

	function harvest() external returns (uint256);

	function distribute(uint256 amount) external;

	function rewards() external view returns (IERC20);

	function underlying() external view returns (IERC20Detailed);

	function target() external view returns (IERC20);

	function harvester() external view returns (address);

	function owner() external view returns (address);

	function distribution() external view returns (address);

	function strat() external view returns (address);

	function timelock() external view returns (address payable);

	function claimOnBehalf(address recipient) external;

	function lastDistribution() external view returns (uint256);

	function performanceFee() external view returns (uint256);

	function balanceOf(address) external view returns (uint256);

	function totalYield() external returns (uint256);

	function calcTotalValue() external view returns (uint256);

	function deposit(uint256 amount) external;

	function depositAndWait(uint256 amount) external;

	function withdraw(uint256 amount) external;

	function withdrawPending(uint256 amount) external;

	function changePerformanceFee(uint256 fee) external;

	function claim() external returns (uint256 claimed);

	function unclaimedProfit(address user) external view returns (uint256);

	function pending(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 0x445fe580ef8d70ff569ab36e80c647af338db351

interface ICurvePool {
	event TokenExchangeUnderlying(
		address indexed buyer,
		int128 sold_id,
		uint256 tokens_sold,
		int128 bought_id,
		uint256 tokens_bought
	);

	// solium-disable-next-line mixedcase
	function exchange_underlying(
		int128 i,
		int128 j,
		uint256 dx,
		uint256 minDy
	) external returns (uint256);

	function add_liquidity(
		uint256[3] calldata amounts,
		uint256 min_mint_amount,
		bool use_underlying
	) external returns (uint256);

	function remove_liquidity_imbalance(
		uint256[3] calldata amounts,
		uint256 max_burn_amount,
		bool use_underlying
	) external;

	function remove_liquidity_one_coin(
		uint256 token_amount,
		int128 i,
		uint256 min_amount,
		bool use_underlying
	) external returns (uint256);

	function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
		external
		view
		returns (uint256);

	function calc_token_amount(uint256[3] calldata amounts, bool is_deposit)
		external
		view
		returns (uint256);

	function get_virtual_price() external view returns (uint256);

	function underlying_coins(uint256) external view returns (address);

	function lp_token() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDistribution {
	function stake(address user, uint256 redeemTokens) external;

	function withdraw(address user, uint256 redeemAmount) external;

	function getReward(address user) external;

	function balanceOf(address account) external view returns (uint256);

	function rewardsToken() external view returns (address);

	function earned(address account) external view returns (uint256);

	function rewardPerToken() external view returns (uint256);

	function rewardRate() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrat2 {
	function totalYield() external view returns (uint256);

	function totalYield2() external view returns (uint256);

	function staking() external view returns (address);

	function gauge() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAaveIncentives {
	function REWARD_TOKEN() external view returns (address);

	function getRewardsBalance(address[] calldata _assets, address user)
		external
		view
		returns (uint256);

	function assets(address aToken)
		external
		view
		returns (
			uint128 emissionPerSecond,
			uint128 lastUpdateTimestamp,
			uint256 index
		);

	function getUserUnclaimedRewards(address _user)
		external
		view
		returns (uint256);

	function claimRewards(
		address[] calldata _assets,
		uint256 amount,
		address to
	) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAToken {
	function redeem(uint256 amount) external;

	function principalBalanceOf(address user) external view returns (uint256);

	function balanceOf(address user) external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function transferFrom(
		address,
		address,
		uint256
	) external returns (bool);

	function transfer(address, uint256) external returns (bool);

	function transferAllowed(address from, uint256 amount)
		external
		returns (bool);

	function underlyingAssetAddress() external pure returns (address);

	function UNDERLYING_ASSET_ADDRESS() external pure returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMemory {
	function getUint(uint256) external view returns (uint256);

	function setUint(uint256 id, uint256 value) external;

	function getAToken(address asset) external view returns (address);

	function setAToken(address asset, address _aToken) external;

	function getCrToken(address asset) external view returns (address);

	function setCrToken(address asset, address _crToken) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeManager {
	function MAX_FEE() external view returns (uint256);

	function getVaultFee(address _vault) external view returns (uint256);

	function setVaultFee(address _vault, uint256 _fee) external;

	function getLendingFee(address _asset) external view returns (uint256);

	function setLendingFee(address _asset, uint256 _fee) external;
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}