// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./BasePool.sol";
import "../AddressBook.sol";

contract DistributionPool is BasePool {
	IERC20 public token; // Token address which is Pool token it is the same token for rewards and stake
	uint256 public totalFees;
	uint256 feeAmount;
	AddressBook public addressBook;
	/**
	 * @dev Emitted when `staker` stake `value` tokens of `token`
	 */
	event Staked(address indexed staker, address token, uint256 value);
	/**
	 * @dev Emitted when `staker` withdraws their stake `value` tokens and contracts balance will
	 * be reduced to`remainingBalance`.
	 */
	event StakeWithdraw(address indexed staker, address token, uint256 value);

	constructor(
		string memory _name,
		string memory _symbol,
		address _token,
		address _swanToken,
		AddressBook _addressBook
	) BasePool(_name, _symbol) {
		__Ownable_init();
		token = IERC20(_token);
		swan = _swanToken;
		_setShareToken(_swanToken);
		addressBook = _addressBook;
		decimals = token.decimals();
		feeAmount = 5;
	}

	function stake(uint256 _amount) external {
		require(
			token.transferFrom(_msgSender(), address(this), _amount),
			"transferFrom failed, make sure you approved token transfer"
		);
		address feeCollector = addressBook.getAddress("FEE_COLLECTOR");
		uint256 stakeAmount = (_amount * (100 - feeAmount)) / 100;
		_mint(_msgSender(), stakeAmount); // mint Staking token for staker
		totalFees += (_amount - stakeAmount);
		token.transfer(feeCollector, (_amount - stakeAmount));
		_increaseProductivity(_msgSender(), stakeAmount);
		emit Staked(_msgSender(), address(token), stakeAmount);
	}

	function withdrawStake(uint256 _amount) external {
		(uint256 userProductivity, ) = getProductivity(_msgSender());
		require(userProductivity >= _amount, "Not enough token staked");
		_burn(_msgSender(), _amount);
		_decreaseProductivity(_msgSender(), _amount);
		_mintReward(_msgSender());
		token.transfer(_msgSender(), _amount);
		emit StakeWithdraw(_msgSender(), address(token), _amount);
	}

	function claimRewards() external {
		_mintReward(_msgSender());
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "../interfaces/Interfaces.sol";
import "../libraries/TransferHelper.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BasePool is OwnableUpgradeable {
	uint256 totalProductivity;

	uint256 accAmountPerShareSwan;

	uint256 public mintedShareSwan;
	uint256 public totalShareSwan;
	uint256 public mintCumulation;

	address public shareToken;
	address public swan;
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;
	uint256 public lastRewardBlock;
	uint256 public rewardsPerBlock;
	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;

	event Mint(address indexed user, uint256 amount);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
	struct UserInfo {
		uint256 amount; // How many tokens the user has provided.
		uint256 rewardEarnSwan; // Reward earn and not minted
		uint256 rewardDebtSwan;
	}

	mapping(address => UserInfo) public users;

	function _setShareToken(address _shareToken) internal {
		shareToken = _shareToken;
	}

	function setRewardsPerBlock(uint256 _rewardsPerBlock) external onlyOwner {
		rewardsPerBlock = _rewardsPerBlock;
	}

	// Update reward variables of the given pool to be up-to-date.
	function _update() internal virtual {
		if (totalProductivity == 0) {
			lastRewardBlock = block.number;
			return;
		}
		uint256 rewardBalance =
			mintedShareSwan +
				IERC20(swan).balanceOf(address(this)) -
				totalShareSwan;

		uint256 multiplier = block.number - lastRewardBlock;
		uint256 rewardsToShare = multiplier * rewardsPerBlock;
		if (rewardsToShare > rewardBalance) {
			rewardsToShare = rewardBalance;
		}
		accAmountPerShareSwan =
			accAmountPerShareSwan +
			((rewardsToShare * 1e27) / totalProductivity);
		totalShareSwan = totalShareSwan + rewardsToShare;
		lastRewardBlock = block.number;
	}

	// Audit user's reward to be up-to-date
	function _audit(address user, uint256 newAmount) internal virtual {
		UserInfo storage userInfo = users[user];
		if (userInfo.amount > 0) {
			uint256 pendingSwans =
				(userInfo.amount * accAmountPerShareSwan) /
					1e27 -
					userInfo.rewardDebtSwan;
			userInfo.rewardEarnSwan = userInfo.rewardEarnSwan + pendingSwans;
		}
		userInfo.amount = newAmount;
		userInfo.rewardDebtSwan =
			(userInfo.amount * accAmountPerShareSwan) /
			1e27;
	}

	// External function call
	// This function increase user's productivity and updates the global productivity.
	// the users' actual share percentage will calculated by:
	// Formula:     user_productivity / global_productivity
	function _increaseProductivity(address user, uint256 value)
		internal
		virtual
		returns (bool)
	{
		require(value > 0, "PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO");
		_update();
		_audit(user, users[user].amount + value);

		totalProductivity = totalProductivity + value;

		return true;
	}

	// External function call
	// This function will decreases user's productivity by value, and updates the global productivity
	// it will record which block this is happenning and accumulates the area of (productivity * time)
	function _decreaseProductivity(address user, uint256 value)
		internal
		virtual
		returns (bool)
	{
		_update();
		_audit(user, users[user].amount - value);
		totalProductivity = totalProductivity - value;

		return true;
	}

	function takeWithAddress(address user) public view returns (uint256) {
		UserInfo memory userInfo = users[user];
		uint256 _accAmountPerShare = accAmountPerShareSwan;
		// uint256 lpSupply = totalProductivity;
		uint256 pending;
		if (totalProductivity != 0) {
			uint256 rewardBalance =
				mintedShareSwan +
					IERC20(swan).balanceOf(address(this)) -
					totalShareSwan;

			uint256 multiplier = block.number - lastRewardBlock;
			uint256 rewardsToShare = multiplier * rewardsPerBlock;
			if (rewardsToShare > rewardBalance) {
				rewardsToShare = rewardBalance;
			}
			_accAmountPerShare =
				_accAmountPerShare +
				((rewardsToShare * 1e27) / totalProductivity);
			pending =
				(userInfo.amount * _accAmountPerShare) /
				1e27 -
				userInfo.rewardDebtSwan;
		}
		return pending + userInfo.rewardEarnSwan;
	}

	// External function call
	// When user calls this function, it will calculate how many token will mint to user from his productivity * time
	// Also it calculates global token supply from last time the user mint to this time.
	function _mintReward(address user) internal virtual returns (uint256) {
		UserInfo storage userInfo = users[user];
		_update();
		_audit(user, userInfo.amount);
		uint256 swanAmount = users[user].rewardEarnSwan;
		if (swanAmount > 0)
			TransferHelper.safeTransfer(swan, msg.sender, swanAmount);
		userInfo.rewardEarnSwan = 0;
		mintedShareSwan += swanAmount;
		return swanAmount;
	}

	// Returns how many productivity a user has and global has.
	function getProductivity(address user)
		public
		view
		virtual
		returns (uint256, uint256)
	{
		return (users[user].amount, totalProductivity);
	}

	// Returns the current gorss product rate.
	function interestsPerBlock() public view virtual returns (uint256) {
		return accAmountPerShareSwan;
	}

	function _mint(address to, uint256 value) internal {
		totalSupply = totalSupply + value;
		balanceOf[to] = balanceOf[to] + value;
		emit Transfer(address(0), to, value);
	}

	constructor(string memory _name, string memory _symbol) {
		name = _name;
		symbol = _symbol;
	}

	receive() external payable {}

	function _burn(address from, uint256 value) internal {
		balanceOf[from] = balanceOf[from] - value;
		totalSupply = totalSupply - value;
		emit Transfer(from, address(0), value);
	}

	function _transfer(
		address from,
		address to,
		uint256 value
	) private {
		require(to != address(0), "Can't transfer to zero address");
		require(balanceOf[from] >= value, "ERC20Token: INSUFFICIENT_BALANCE");
		balanceOf[from] = balanceOf[from] - value;
		balanceOf[to] = balanceOf[to] + value;
		_decreaseProductivity(from, value);
		_increaseProductivity(to, value);
		emit Transfer(from, to, value);
	}

	function approve(address spender, uint256 value) external returns (bool) {
		allowance[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);
		return true;
	}

	function transfer(address to, uint256 value) external returns (bool) {
		_transfer(msg.sender, to, value);
		return true;
	}

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool) {
		require(
			allowance[from][msg.sender] >= value,
			"ERC20Token: INSUFFICIENT_ALLOWANCE"
		);
		allowance[from][msg.sender] = allowance[from][msg.sender] - value;
		_transfer(from, to, value);
		return true;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AddressBook is OwnableUpgradeable {
	mapping(bytes32 => address) public addresses;

	constructor() {
		__Ownable_init();
	}

	function getAddress(string memory name) external view returns (address) {
		return addresses[keccak256(bytes(name))];
	}

	function setAddress(string memory name, address addr) external onlyOwner {
		addresses[keccak256(bytes(name))] = addr;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.1;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function decimals() external view returns (uint8);

	function transfer(address recipient, uint256 amount)
		external
		returns (bool);

	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);

	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}

interface IUniswapV2Pair {
	function getReserves()
		external
		view
		returns (
			uint112 reserve0,
			uint112 reserve1,
			uint32 blockTimestampLast
		);
}

interface IUniswapV2Router01 {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	)
		external
		returns (
			uint256 amountA,
			uint256 amountB,
			uint256 liquidity
		);

	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	)
		external
		payable
		returns (
			uint256 amountToken,
			uint256 amountETH,
			uint256 liquidity
		);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETH(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountToken, uint256 amountETH);

	function removeLiquidityWithPermit(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETHWithPermit(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountToken, uint256 amountETH);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapTokensForExactETH(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapETHForExactTokens(
		uint256 amountOut,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) external pure returns (uint256 amountB);

	function getAmountOut(
		uint256 amountIn,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountOut);

	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountIn);

	function getAmountsOut(uint256 amountIn, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function getAmountsIn(uint256 amountOut, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
	function removeLiquidityETHSupportingFeeOnTransferTokens(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountETH);

	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountETH);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;
}

interface IERC2917 is IERC20 {
	/// @dev This emit when interests amount per block is changed by the owner of the contract.
	/// It emits with the old interests amount and the new interests amount.
	event InterestRatePerBlockChanged(uint256 oldValue, uint256 newValue);

	/// @dev This emit when a users' productivity has changed
	/// It emits with the user's address and the the value after the change.
	event ProductivityIncreased(address indexed user, uint256 value);

	/// @dev This emit when a users' productivity has changed
	/// It emits with the user's address and the the value after the change.
	event ProductivityDecreased(address indexed user, uint256 value);

	/// @dev Return the current contract's interests rate per block.
	/// @return The amount of interests currently producing per each block.
	function interestsPerBlock() external view returns (uint256);

	/// @notice Change the current contract's interests rate.
	/// @dev Note the best practice will be restrict the gross product provider's contract address to call this.
	/// @return The true/fase to notice that the value has successfully changed or not, when it succeed, it will emite the InterestRatePerBlockChanged event.
	function changeInterestRatePerBlock(uint256 value) external returns (bool);

	/// @notice It will get the productivity of given user.
	/// @dev it will return 0 if user has no productivity proved in the contract.
	/// @return user's productivity and overall productivity.
	function getProductivity(address user)
		external
		view
		returns (uint256, uint256);

	/// @notice increase a user's productivity.
	/// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
	/// @return true to confirm that the productivity added success.
	function increaseProductivity(address user, uint256 value)
		external
		returns (bool);

	/// @notice decrease a user's productivity.
	/// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
	/// @return true to confirm that the productivity removed success.
	function decreaseProductivity(address user, uint256 value)
		external
		returns (bool);

	/// @notice take() will return the interests that callee will get at current block height.
	/// @dev it will always calculated by block.number, so it will change when block height changes.
	/// @return amount of the interests that user are able to mint() at current block height.
	function take() external view returns (uint256);

	/// @notice similar to take(), but with the block height joined to calculate return.
	/// @dev for instance, it returns (_amount, _block), which means at block height _block, the callee has accumulated _amount of interests.
	/// @return amount of interests and the block height.
	function takeWithBlock() external view returns (uint256, uint256);

	/// @notice mint the avaiable interests to callee.
	/// @dev once it mint, the amount of interests will transfer to callee's address.
	/// @return the amount of interests minted.
	function mint() external returns (uint256);
}

interface MultiSigWallet {
	function submitTransaction(
		address destination,
		uint256 value,
		bytes calldata data
	) external returns (uint256);

	function addOwner(address owner) external;

	function replaceOwner(address owner, address newOwner) external;

	function changeRequirement(uint256 _required) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
	function safeApprove(
		address token,
		address to,
		uint256 value
	) internal {
		// bytes4(keccak256(bytes('approve(address,uint256)')));
		(bool success, bytes memory data) =
			token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
		require(
			success && (data.length == 0 || abi.decode(data, (bool))),
			"TransferHelper: APPROVE_FAILED"
		);
	}

	function safeTransfer(
		address token,
		address to,
		uint256 value
	) internal {
		// bytes4(keccak256(bytes('transfer(address,uint256)')));
		(bool success, bytes memory data) =
			token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
		require(
			success && (data.length == 0 || abi.decode(data, (bool))),
			"TransferHelper: TRANSFER_FAILED"
		);
	}

	function safeTransferFrom(
		address token,
		address from,
		address to,
		uint256 value
	) internal {
		// bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
		(bool success, bytes memory data) =
			token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
		require(
			success && (data.length == 0 || abi.decode(data, (bool))),
			"TransferHelper: TRANSFER_FROM_FAILED"
		);
	}

	function safeTransferETH(address to, uint256 value) internal {
		(bool success, ) = to.call{ value: value }(new bytes(0));
		require(success, "TransferHelper: ETH_TRANSFER_FAILED");
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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