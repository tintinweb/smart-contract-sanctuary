// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { BoringMath, BoringMath128 } from "./libraries/boring/BoringMath.sol";
import { BoringOwnable } from "./libraries/boring/BoringOwnable.sol";
import { BoringERC20 } from "./libraries/boring/BoringERC20.sol";

import { IRewarder } from "./interfaces/sushi/IRewarder.sol";
import { IMasterChefV2 } from "./interfaces/sushi/IMasterChefV2.sol";

import "hardhat/console.sol";

contract ALCXRewarder is IRewarder, BoringOwnable {
	using BoringMath for uint256;
	using BoringMath128 for uint128;
	using BoringERC20 for IERC20;

	IERC20 private immutable rewardToken;
	IMasterChefV2 private immutable MC_V2;

	/// @notice Info of each MCV2 user.
	/// `amount` LP token amount the user has provided.
	/// `rewardDebt` The amount of SUSHI entitled to the user.
	struct UserInfo {
		uint256 amount;
		uint256 rewardDebt;
	}

	/// @notice Info of each MCV2 pool.
	/// `allocPoint` The amount of allocation points assigned to the pool.
	/// Also known as the amount of SUSHI to distribute per block.
	struct PoolInfo {
		uint128 accTokenPerShare;
		uint64 lastRewardBlock;
		uint64 allocPoint;
	}

	uint256[] public poolIds;
	/// @notice Info of each pool.
	mapping(uint256 => PoolInfo) public poolInfo;
	/// @notice Info of each user that stakes LP tokens.
	mapping(uint256 => mapping(address => UserInfo)) public userInfo;
	/// @dev Total allocation points. Must be the sum of all allocation points in all pools.
	uint256 totalAllocPoint;

	uint256 public tokenPerBlock;
	uint256 private constant ACC_TOKEN_PRECISION = 1e12;

	event PoolAdded(uint256 indexed pid, uint256 allocPoint);
	event PoolSet(uint256 indexed pid, uint256 allocPoint);
	event PoolUpdated(uint256 indexed pid, uint64 lastRewardBlock, uint256 lpSupply, uint256 accTokenPerShare);
	event OnReward(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
	event RewardRateUpdated(uint256 oldRate, uint256 newRate);

	modifier onlyMCV2 {
		require(msg.sender == address(MC_V2), "ALCXRewarder::onlyMCV2: only MasterChef V2 can call this function.");
		_;
	}

	constructor(
		IERC20 _rewardToken,
		uint256 _tokenPerBlock,
		IMasterChefV2 _MCV2
	) public {
		require(Address.isContract(address(_rewardToken)), "ALCXRewarder: reward token must be a valid contract");
		require(Address.isContract(address(_MCV2)), "ALCXRewarder: MasterChef V2 must be a valid contract");

		rewardToken = _rewardToken;
		tokenPerBlock = _tokenPerBlock;
		MC_V2 = _MCV2;
	}

	/// @notice Add a new LP to the pool. Can only be called by the owner.
	/// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
	/// @param allocPoint AP of the new pool.
	/// @param _pid Pid on MCV2
	function addPool(uint256 _pid, uint256 allocPoint) public onlyOwner {
		require(poolInfo[_pid].lastRewardBlock == 0, "ALCXRewarder::add: cannot add existing pool");

		uint256 lastRewardBlock = block.number;
		totalAllocPoint = totalAllocPoint.add(allocPoint);

		poolInfo[_pid] = PoolInfo({
			allocPoint: allocPoint.to64(),
			lastRewardBlock: lastRewardBlock.to64(),
			accTokenPerShare: 0
		});
		poolIds.push(_pid);

		emit PoolAdded(_pid, allocPoint);
	}

	/// @notice Update the given pool's SUSHI allocation point and `IRewarder` contract. Can only be called by the owner.
	/// @param _pid The index of the pool. See `poolInfo`.
	/// @param _allocPoint New AP of the pool.
	function setPool(uint256 _pid, uint256 _allocPoint) public onlyOwner {
		totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
		poolInfo[_pid].allocPoint = _allocPoint.to64();

		emit PoolSet(_pid, _allocPoint);
	}

	/// @notice Update reward variables of the given pool.
	/// @param pid The index of the pool. See `poolInfo`.
	/// @return pool Returns the pool that was updated.
	function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
		pool = poolInfo[pid];

		if (block.number > pool.lastRewardBlock) {
			uint256 lpSupply = MC_V2.lpToken(pid).balanceOf(address(MC_V2));

			if (lpSupply > 0) {
				uint256 blocks = block.number.sub(pool.lastRewardBlock);
				uint256 tokenReward = blocks.mul(tokenPerBlock).mul(pool.allocPoint) / totalAllocPoint;
				pool.accTokenPerShare = pool.accTokenPerShare.add(
					(tokenReward.mul(ACC_TOKEN_PRECISION) / lpSupply).to128()
				);
			}

			pool.lastRewardBlock = block.number.to64();
			poolInfo[pid] = pool;

			emit PoolUpdated(pid, pool.lastRewardBlock, lpSupply, pool.accTokenPerShare);
		}
	}

	/// @notice Update reward variables for all pools
	/// @dev Be careful of gas spending!
	/// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
	function massUpdatePools(uint256[] calldata pids) public {
		uint256 len = pids.length;
		for (uint256 i = 0; i < len; ++i) {
			updatePool(pids[i]);
		}
	}

	/// @dev Sets the distribution reward rate. This will also update all of the pools.
	/// @param _tokenPerBlock The number of tokens to distribute per block
	function setRewardRate(uint256 _tokenPerBlock, uint256[] calldata _pids) external onlyOwner {
		massUpdatePools(_pids);

		uint256 oldRate = tokenPerBlock;
		tokenPerBlock = _tokenPerBlock;

		emit RewardRateUpdated(oldRate, _tokenPerBlock);
	}

	function onSushiReward(
		uint256 pid,
		address _user,
		address to,
		uint256,
		uint256 lpToken
	) external override onlyMCV2 {
		PoolInfo memory pool = updatePool(pid);
		UserInfo storage user = userInfo[pid][_user];
		uint256 pending;
		// if user had deposited
		if (user.amount > 0) {
			pending = (user.amount.mul(pool.accTokenPerShare) / ACC_TOKEN_PRECISION).sub(user.rewardDebt);
			rewardToken.safeTransfer(to, pending);
		}

		user.amount = lpToken;
		user.rewardDebt = user.rewardDebt.add(pending);

		emit OnReward(_user, pid, pending, to);
	}

	function pendingTokens(
		uint256 pid,
		address user,
		uint256
	) external view override returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts) {
		IERC20[] memory _rewardTokens = new IERC20[](1);
		_rewardTokens[0] = (rewardToken);

		uint256[] memory _rewardAmounts = new uint256[](1);
		_rewardAmounts[0] = pendingToken(pid, user);

		return (_rewardTokens, _rewardAmounts);
	}

	/// @notice View function to see pending Token
	/// @param _pid The index of the pool. See `poolInfo`.
	/// @param _user Address of user.
	/// @return pending SUSHI reward for a given user.
	function pendingToken(uint256 _pid, address _user) public view returns (uint256 pending) {
		PoolInfo memory pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][_user];

		uint256 accTokenPerShare = pool.accTokenPerShare;
		uint256 lpSupply = MC_V2.lpToken(_pid).balanceOf(address(MC_V2));

		if (block.number > pool.lastRewardBlock && lpSupply != 0) {
			uint256 blocks = block.number.sub(pool.lastRewardBlock);
			uint256 tokenReward = blocks.mul(tokenPerBlock).mul(pool.allocPoint) / totalAllocPoint;
			accTokenPerShare = accTokenPerShare.add(tokenReward.mul(ACC_TOKEN_PRECISION) / lpSupply);
		}

		pending = (user.amount.mul(accTokenPerShare) / ACC_TOKEN_PRECISION).sub(user.rewardDebt);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		require((c = a + b) >= b, "BoringMath::add: Add Overflow");
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
		require((c = a - b) <= a, "BoringMath::sub: Underflow");
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		require(b == 0 || (c = a * b) / b == a, "BoringMath::mul: Mul Overflow");
	}

	function to128(uint256 a) internal pure returns (uint128 c) {
		require(a <= uint128(-1), "BoringMath::to128: uint128 Overflow");
		c = uint128(a);
	}

	function to64(uint256 a) internal pure returns (uint64 c) {
		require(a <= uint64(-1), "BoringMath::to64: uint64 Overflow");
		c = uint64(a);
	}

	function to32(uint256 a) internal pure returns (uint32 c) {
		require(a <= uint32(-1), "BoringMath::to32: uint32 Overflow");
		c = uint32(a);
	}
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
	function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
		require((c = a + b) >= b, "BoringMath128::add: Add Overflow");
	}

	function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
		require((c = a - b) <= a, "BoringMath128::sub: Underflow");
	}
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
	function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
		require((c = a + b) >= b, "BoringMath64::add: Add Overflow");
	}

	function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
		require((c = a - b) <= a, "BoringMath64::sub: Underflow");
	}
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
	function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
		require((c = a + b) >= b, "BoringMath32::add: Add Overflow");
	}

	function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
		require((c = a - b) <= a, "BoringMath32::sub: Underflow");
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract BoringOwnableData {
	address public owner;
	address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/// @notice `owner` defaults to msg.sender on construction.
	constructor() public {
		owner = msg.sender;
		emit OwnershipTransferred(address(0), msg.sender);
	}

	/// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
	/// Can only be invoked by the current `owner`.
	/// @param newOwner Address of the new owner.
	/// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
	/// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
	function transferOwnership(
		address newOwner,
		bool direct,
		bool renounce
	) public onlyOwner {
		if (direct) {
			// Checks
			require(newOwner != address(0) || renounce, "BoringOwnable::transferOwnership: zero address");

			// Effects
			emit OwnershipTransferred(owner, newOwner);
			owner = newOwner;
			pendingOwner = address(0);
		} else {
			// Effects
			pendingOwner = newOwner;
		}
	}

	/// @notice Needs to be called by `pendingOwner` to claim ownership.
	function claimOwnership() public {
		address _pendingOwner = pendingOwner;

		// Checks
		require(msg.sender == _pendingOwner, "BoringOwnable::claimOwnership: caller != pending owner");

		// Effects
		emit OwnershipTransferred(owner, _pendingOwner);
		owner = _pendingOwner;
		pendingOwner = address(0);
	}

	/// @notice Only allows the `owner` to execute the function.
	modifier onlyOwner() {
		require(msg.sender == owner, "BoringOwnable::onlyOwner: caller is not the owner");
		_;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// solhint-disable avoid-low-level-calls
library BoringERC20 {
	bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
	bytes4 private constant SIG_NAME = 0x06fdde03; // name()
	bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
	bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
	bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

	function returnDataToString(bytes memory data) internal pure returns (string memory) {
		if (data.length >= 64) {
			return abi.decode(data, (string));
		} else if (data.length == 32) {
			uint8 i = 0;
			while (i < 32 && data[i] != 0) {
				i++;
			}
			bytes memory bytesArray = new bytes(i);
			for (i = 0; i < 32 && data[i] != 0; i++) {
				bytesArray[i] = data[i];
			}
			return string(bytesArray);
		} else {
			return "???";
		}
	}

	/// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
	/// @param token The address of the ERC-20 token contract.
	/// @return (string) Token symbol.
	function safeSymbol(IERC20 token) internal view returns (string memory) {
		(bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
		return success ? returnDataToString(data) : "???";
	}

	/// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
	/// @param token The address of the ERC-20 token contract.
	/// @return (string) Token name.
	function safeName(IERC20 token) internal view returns (string memory) {
		(bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
		return success ? returnDataToString(data) : "???";
	}

	/// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
	/// @param token The address of the ERC-20 token contract.
	/// @return (uint8) Token decimals.
	function safeDecimals(IERC20 token) internal view returns (uint8) {
		(bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
		return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
	}

	/// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
	/// Reverts on a failed transfer.
	/// @param token The address of the ERC-20 token.
	/// @param to Transfer tokens to.
	/// @param amount The token amount.
	function safeTransfer(
		IERC20 token,
		address to,
		uint256 amount
	) internal {
		(bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
		require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20::safeTransfer: transfer failed");
	}

	/// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
	/// Reverts on a failed transfer.
	/// @param token The address of the ERC-20 token.
	/// @param from Transfer tokens from.
	/// @param to Transfer tokens to.
	/// @param amount The token amount.
	function safeTransferFrom(
		IERC20 token,
		address from,
		address to,
		uint256 amount
	) internal {
		(bool success, bytes memory data) =
			address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
		require(
			success && (data.length == 0 || abi.decode(data, (bool))),
			"BoringERC20::safeTransferFrom: transfer failed"
		);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../../libraries/boring/BoringERC20.sol";

interface IRewarder {
	using BoringERC20 for IERC20;

	function onSushiReward(
		uint256 pid,
		address user,
		address recipient,
		uint256 sushiAmount,
		uint256 newLpAmount
	) external;

	function pendingTokens(
		uint256 pid,
		address user,
		uint256 sushiAmount
	) external view returns (IERC20[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../libraries/boring/BoringERC20.sol";

interface IMasterChefV2 {
	using BoringERC20 for IERC20;

	struct UserInfo {
		uint256 amount; // How many LP tokens the user has provided.
		uint256 rewardDebt; // Reward debt. See explanation below.
	}

	struct PoolInfo {
		IERC20 lpToken; // Address of LP token contract.
		uint256 allocPoint; // How many allocation points assigned to this pool. SUSHI to distribute per block.
		uint256 lastRewardBlock; // Last block number that SUSHI distribution occurs.
		uint256 accSushiPerShare; // Accumulated SUSHI per share, times 1e12. See below.
	}

	function lpToken(uint256 pid) external view returns (IERC20);

	function poolInfo(uint256 pid) external view returns (PoolInfo memory);

	function totalAllocPoint() external view returns (uint256);

	function deposit(uint256 _pid, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import { StakingPools } from "./StakingPools.sol";
import { FixedPointMath } from "./libraries/math/FixedPointMath.sol";
import { IMintableERC20 } from "./interfaces/token/ERC20/IMintableERC20.sol";
import { Pool } from "./libraries/pools/Pool.sol";
import { Stake } from "./libraries/pools/Stake.sol";

import "hardhat/console.sol";

/// @title StakingPools
//    ___    __        __                _               ___                              __         _
//   / _ |  / / ____  / /  ___   __ _   (_) __ __       / _ \  ____ ___   ___ ___   ___  / /_  ___  (_)
//  / __ | / / / __/ / _ \/ -_) /  ' \ / /  \ \ /      / ___/ / __// -_) (_-</ -_) / _ \/ __/ (_-< _
// /_/ |_|/_/  \__/ /_//_/\__/ /_/_/_//_/  /_\_\      /_/    /_/   \__/ /___/\__/ /_//_/\__/ /___/(_)
//
//      _______..___________.     ___       __  ___  __  .__   __.   _______    .______     ______     ______    __           _______.
//     /       ||           |    /   \     |  |/  / |  | |  \ |  |  /  _____|   |   _  \   /  __  \   /  __  \  |  |         /       |
//    |   (----``---|  |----`   /  ^  \    |  '  /  |  | |   \|  | |  |  __     |  |_)  | |  |  |  | |  |  |  | |  |        |   (----`
//     \   \        |  |       /  /_\  \   |    <   |  | |  . `  | |  | |_ |    |   ___/  |  |  |  | |  |  |  | |  |         \   \
// .----)   |       |  |      /  _____  \  |  .  \  |  | |  |\   | |  |__| |    |  |      |  `--'  | |  `--'  | |  `----..----)   |
// |_______/        |__|     /__/     \__\ |__|\__\ |__| |__| \__|  \______|    | _|       \______/   \______/  |_______||_______/
///
/// @dev A contract which allows users to stake to farm tokens.
///
/// This contract was inspired by Chef Nomi's 'MasterChef' contract which can be found in this
/// repository: https://github.com/sushiswap/sushiswap.
contract StakingPools is ReentrancyGuard {
	using FixedPointMath for FixedPointMath.uq192x64;
	using Pool for Pool.Data;
	using Pool for Pool.List;
	using SafeERC20 for IERC20;
	using SafeMath for uint256;
	using Stake for Stake.Data;

	event PendingGovernanceUpdated(address pendingGovernance);

	event GovernanceUpdated(address governance);

	event RewardRateUpdated(uint256 rewardRate);

	event PoolRewardWeightUpdated(uint256 indexed poolId, uint256 rewardWeight);

	event PoolCreated(uint256 indexed poolId, IERC20 indexed token);

	event TokensDeposited(address indexed user, uint256 indexed poolId, uint256 amount);

	event TokensWithdrawn(address indexed user, uint256 indexed poolId, uint256 amount);

	event TokensClaimed(address indexed user, uint256 indexed poolId, uint256 amount);

	/// @dev The token which will be minted as a reward for staking.
	IMintableERC20 public reward;

	/// @dev The address of the account which currently has administrative capabilities over this contract.
	address public governance;

	address public pendingGovernance;

	/// @dev Tokens are mapped to their pool identifier plus one. Tokens that do not have an associated pool
	/// will return an identifier of zero.
	mapping(IERC20 => uint256) public tokenPoolIds;

	/// @dev The context shared between the pools.
	Pool.Context private _ctx;

	/// @dev A list of all of the pools.
	Pool.List private _pools;

	/// @dev A mapping of all of the user stakes mapped first by pool and then by address.
	mapping(address => mapping(uint256 => Stake.Data)) private _stakes;

	constructor(IMintableERC20 _reward, address _governance) public {
		require(_governance != address(0), "StakingPools: governance address cannot be 0x0");

		reward = _reward;
		governance = _governance;
	}

	/// @dev A modifier which reverts when the caller is not the governance.
	modifier onlyGovernance() {
		require(msg.sender == governance, "StakingPools: only governance");
		_;
	}

	/// @dev Sets the governance.
	///
	/// This function can only called by the current governance.
	///
	/// @param _pendingGovernance the new pending governance.
	function setPendingGovernance(address _pendingGovernance) external onlyGovernance {
		require(_pendingGovernance != address(0), "StakingPools: pending governance address cannot be 0x0");
		pendingGovernance = _pendingGovernance;

		emit PendingGovernanceUpdated(_pendingGovernance);
	}

	function acceptGovernance() external {
		require(msg.sender == pendingGovernance, "StakingPools: only pending governance");

		address _pendingGovernance = pendingGovernance;
		governance = _pendingGovernance;

		emit GovernanceUpdated(_pendingGovernance);
	}

	/// @dev Sets the distribution reward rate.
	///
	/// This will update all of the pools.
	///
	/// @param _rewardRate The number of tokens to distribute per second.
	function setRewardRate(uint256 _rewardRate) external onlyGovernance {
		_updatePools();

		_ctx.rewardRate = _rewardRate;

		emit RewardRateUpdated(_rewardRate);
	}

	/// @dev Creates a new pool.
	///
	/// The created pool will need to have its reward weight initialized before it begins generating rewards.
	///
	/// @param _token The token the pool will accept for staking.
	///
	/// @return the identifier for the newly created pool.
	function createPool(IERC20 _token) external onlyGovernance returns (uint256) {
		require(tokenPoolIds[_token] == 0, "StakingPools: token already has a pool");

		uint256 _poolId = _pools.length();

		_pools.push(
			Pool.Data({
				token: _token,
				totalDeposited: 0,
				rewardWeight: 0,
				accumulatedRewardWeight: FixedPointMath.uq192x64(0),
				lastUpdatedBlock: block.number
			})
		);

		tokenPoolIds[_token] = _poolId + 1;

		emit PoolCreated(_poolId, _token);

		return _poolId;
	}

	/// @dev Sets the reward weights of all of the pools.
	///
	/// @param _rewardWeights The reward weights of all of the pools.
	function setRewardWeights(uint256[] calldata _rewardWeights) external onlyGovernance {
		require(_rewardWeights.length == _pools.length(), "StakingPools: weights length mismatch");

		_updatePools();

		uint256 _totalRewardWeight = _ctx.totalRewardWeight;
		for (uint256 _poolId = 0; _poolId < _pools.length(); _poolId++) {
			Pool.Data storage _pool = _pools.get(_poolId);

			uint256 _currentRewardWeight = _pool.rewardWeight;
			if (_currentRewardWeight == _rewardWeights[_poolId]) {
				continue;
			}

			// FIXME
			_totalRewardWeight = _totalRewardWeight.sub(_currentRewardWeight).add(_rewardWeights[_poolId]);
			_pool.rewardWeight = _rewardWeights[_poolId];

			emit PoolRewardWeightUpdated(_poolId, _rewardWeights[_poolId]);
		}

		_ctx.totalRewardWeight = _totalRewardWeight;
	}

	/// @dev Stakes tokens into a pool.
	///
	/// @param _poolId        the pool to deposit tokens into.
	/// @param _depositAmount the amount of tokens to deposit.
	function deposit(uint256 _poolId, uint256 _depositAmount) external nonReentrant {
		Pool.Data storage _pool = _pools.get(_poolId);
		_pool.update(_ctx);

		Stake.Data storage _stake = _stakes[msg.sender][_poolId];
		_stake.update(_pool, _ctx);

		_deposit(_poolId, _depositAmount);
	}

	/// @dev Withdraws staked tokens from a pool.
	///
	/// @param _poolId          The pool to withdraw staked tokens from.
	/// @param _withdrawAmount  The number of tokens to withdraw.
	function withdraw(uint256 _poolId, uint256 _withdrawAmount) external nonReentrant {
		Pool.Data storage _pool = _pools.get(_poolId);
		_pool.update(_ctx);

		Stake.Data storage _stake = _stakes[msg.sender][_poolId];
		_stake.update(_pool, _ctx);

		_claim(_poolId);
		_withdraw(_poolId, _withdrawAmount);
	}

	/// @dev Claims all rewarded tokens from a pool.
	///
	/// @param _poolId The pool to claim rewards from.
	///
	/// @notice use this function to claim the tokens from a corresponding pool by ID.
	function claim(uint256 _poolId) external nonReentrant {
		Pool.Data storage _pool = _pools.get(_poolId);
		_pool.update(_ctx);

		Stake.Data storage _stake = _stakes[msg.sender][_poolId];
		_stake.update(_pool, _ctx);

		_claim(_poolId);
	}

	/// @dev Claims all rewards from a pool and then withdraws all staked tokens.
	///
	/// @param _poolId the pool to exit from.
	function exit(uint256 _poolId) external nonReentrant {
		Pool.Data storage _pool = _pools.get(_poolId);
		_pool.update(_ctx);

		Stake.Data storage _stake = _stakes[msg.sender][_poolId];
		_stake.update(_pool, _ctx);

		_claim(_poolId);
		_withdraw(_poolId, _stake.totalDeposited);
	}

	/// @dev Gets the rate at which tokens are minted to stakers for all pools.
	///
	/// @return the reward rate.
	function rewardRate() external view returns (uint256) {
		return _ctx.rewardRate;
	}

	/// @dev Gets the total reward weight between all the pools.
	///
	/// @return the total reward weight.
	function totalRewardWeight() external view returns (uint256) {
		return _ctx.totalRewardWeight;
	}

	/// @dev Gets the number of pools that exist.
	///
	/// @return the pool count.
	function poolCount() external view returns (uint256) {
		return _pools.length();
	}

	/// @dev Gets the token a pool accepts.
	///
	/// @param _poolId the identifier of the pool.
	///
	/// @return the token.
	function getPoolToken(uint256 _poolId) external view returns (IERC20) {
		Pool.Data storage _pool = _pools.get(_poolId);
		return _pool.token;
	}

	/// @dev Gets the total amount of funds staked in a pool.
	///
	/// @param _poolId the identifier of the pool.
	///
	/// @return the total amount of staked or deposited tokens.
	function getPoolTotalDeposited(uint256 _poolId) external view returns (uint256) {
		Pool.Data storage _pool = _pools.get(_poolId);
		return _pool.totalDeposited;
	}

	/// @dev Gets the reward weight of a pool which determines how much of the total rewards it receives per block.
	///
	/// @param _poolId the identifier of the pool.
	///
	/// @return the pool reward weight.
	function getPoolRewardWeight(uint256 _poolId) external view returns (uint256) {
		Pool.Data storage _pool = _pools.get(_poolId);
		return _pool.rewardWeight;
	}

	/// @dev Gets the amount of tokens per block being distributed to stakers for a pool.
	///
	/// @param _poolId the identifier of the pool.
	///
	/// @return the pool reward rate.
	function getPoolRewardRate(uint256 _poolId) external view returns (uint256) {
		Pool.Data storage _pool = _pools.get(_poolId);
		return _pool.getRewardRate(_ctx);
	}

	/// @dev Gets the number of tokens a user has staked into a pool.
	///
	/// @param _account The account to query.
	/// @param _poolId  the identifier of the pool.
	///
	/// @return the amount of deposited tokens.
	function getStakeTotalDeposited(address _account, uint256 _poolId) external view returns (uint256) {
		Stake.Data storage _stake = _stakes[_account][_poolId];
		return _stake.totalDeposited;
	}

	/// @dev Gets the number of unclaimed reward tokens a user can claim from a pool.
	///
	/// @param _account The account to get the unclaimed balance of.
	/// @param _poolId  The pool to check for unclaimed rewards.
	///
	/// @return the amount of unclaimed reward tokens a user has in a pool.
	function getStakeTotalUnclaimed(address _account, uint256 _poolId) external view returns (uint256) {
		Stake.Data storage _stake = _stakes[_account][_poolId];
		return _stake.getUpdatedTotalUnclaimed(_pools.get(_poolId), _ctx);
	}

	/// @dev Updates all of the pools.
	function _updatePools() internal {
		for (uint256 _poolId = 0; _poolId < _pools.length(); _poolId++) {
			Pool.Data storage _pool = _pools.get(_poolId);
			_pool.update(_ctx);
		}
	}

	/// @dev Stakes tokens into a pool.
	///
	/// The pool and stake MUST be updated before calling this function.
	///
	/// @param _poolId        the pool to deposit tokens into.
	/// @param _depositAmount the amount of tokens to deposit.
	function _deposit(uint256 _poolId, uint256 _depositAmount) internal {
		Pool.Data storage _pool = _pools.get(_poolId);
		Stake.Data storage _stake = _stakes[msg.sender][_poolId];

		_pool.totalDeposited = _pool.totalDeposited.add(_depositAmount);
		_stake.totalDeposited = _stake.totalDeposited.add(_depositAmount);

		_pool.token.safeTransferFrom(msg.sender, address(this), _depositAmount);

		emit TokensDeposited(msg.sender, _poolId, _depositAmount);
	}

	/// @dev Withdraws staked tokens from a pool.
	///
	/// The pool and stake MUST be updated before calling this function.
	///
	/// @param _poolId          The pool to withdraw staked tokens from.
	/// @param _withdrawAmount  The number of tokens to withdraw.
	function _withdraw(uint256 _poolId, uint256 _withdrawAmount) internal {
		Pool.Data storage _pool = _pools.get(_poolId);
		Stake.Data storage _stake = _stakes[msg.sender][_poolId];

		_pool.totalDeposited = _pool.totalDeposited.sub(_withdrawAmount);
		_stake.totalDeposited = _stake.totalDeposited.sub(_withdrawAmount);

		_pool.token.safeTransfer(msg.sender, _withdrawAmount);

		emit TokensWithdrawn(msg.sender, _poolId, _withdrawAmount);
	}

	/// @dev Claims all rewarded tokens from a pool.
	///
	/// The pool and stake MUST be updated before calling this function.
	///
	/// @param _poolId The pool to claim rewards from.
	///
	/// @notice use this function to claim the tokens from a corresponding pool by ID.
	function _claim(uint256 _poolId) internal {
		Stake.Data storage _stake = _stakes[msg.sender][_poolId];

		uint256 _claimAmount = _stake.totalUnclaimed;
		_stake.totalUnclaimed = 0;

		reward.mint(msg.sender, _claimAmount);

		emit TokensClaimed(msg.sender, _poolId, _claimAmount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
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

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

library FixedPointMath {
	uint256 public constant DECIMALS = 18;
	uint256 public constant SCALAR = 10**DECIMALS;

	struct uq192x64 {
		uint256 x;
	}

	function fromU256(uint256 value) internal pure returns (uq192x64 memory) {
		uint256 x;
		require(value == 0 || (x = value * SCALAR) / SCALAR == value);
		return uq192x64(x);
	}

	function maximumValue() internal pure returns (uq192x64 memory) {
		return uq192x64(uint256(-1));
	}

	function add(uq192x64 memory self, uq192x64 memory value) internal pure returns (uq192x64 memory) {
		uint256 x;
		require((x = self.x + value.x) >= self.x);
		return uq192x64(x);
	}

	function add(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
		return add(self, fromU256(value));
	}

	function sub(uq192x64 memory self, uq192x64 memory value) internal pure returns (uq192x64 memory) {
		uint256 x;
		require((x = self.x - value.x) <= self.x);
		return uq192x64(x);
	}

	function sub(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
		return sub(self, fromU256(value));
	}

	function mul(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
		uint256 x;
		require(value == 0 || (x = self.x * value) / value == self.x);
		return uq192x64(x);
	}

	function div(uq192x64 memory self, uint256 value) internal pure returns (uq192x64 memory) {
		require(value != 0);
		return uq192x64(self.x / value);
	}

	function cmp(uq192x64 memory self, uq192x64 memory value) internal pure returns (int256) {
		if (self.x < value.x) {
			return -1;
		}

		if (self.x > value.x) {
			return 1;
		}

		return 0;
	}

	function decode(uq192x64 memory self) internal pure returns (uint256) {
		return self.x / SCALAR;
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import { IDetailedERC20 } from "./IDetailedERC20.sol";

interface IMintableERC20 is IDetailedERC20 {
	function mint(address _recipient, uint256 _amount) external;

	function burnFrom(address account, uint256 amount) external;

	function lowerHasMinted(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { FixedPointMath } from "../math/FixedPointMath.sol";
import { IDetailedERC20 } from "../../interfaces/token/ERC20/IDetailedERC20.sol";

import "hardhat/console.sol";

/// @title Pool
///
/// @dev A library which provides the Pool data struct and associated functions.
library Pool {
	using FixedPointMath for FixedPointMath.uq192x64;
	using Pool for Pool.Data;
	using Pool for Pool.List;
	using SafeMath for uint256;

	struct Context {
		uint256 rewardRate;
		uint256 totalRewardWeight;
	}

	struct Data {
		IERC20 token;
		uint256 totalDeposited;
		uint256 rewardWeight;
		FixedPointMath.uq192x64 accumulatedRewardWeight;
		uint256 lastUpdatedBlock;
	}

	struct List {
		Data[] elements;
	}

	/// @dev Updates the pool.
	///
	/// @param _ctx the pool context.
	function update(Data storage _data, Context storage _ctx) internal {
		_data.accumulatedRewardWeight = _data.getUpdatedAccumulatedRewardWeight(_ctx);
		_data.lastUpdatedBlock = block.number;
	}

	/// @dev Gets the rate at which the pool will distribute rewards to stakers.
	///
	/// @param _ctx the pool context.
	///
	/// @return the reward rate of the pool in tokens per block.
	function getRewardRate(Data storage _data, Context storage _ctx) internal view returns (uint256) {
		// console.log("get reward rate");
		// console.log(uint(_data.rewardWeight));
		// console.log(uint(_ctx.totalRewardWeight));
		// console.log(uint(_ctx.rewardRate));
		return _ctx.rewardRate.mul(_data.rewardWeight).div(_ctx.totalRewardWeight);
	}

	/// @dev Gets the accumulated reward weight of a pool.
	///
	/// @param _ctx the pool context.
	///
	/// @return the accumulated reward weight.
	function getUpdatedAccumulatedRewardWeight(Data storage _data, Context storage _ctx)
		internal
		view
		returns (FixedPointMath.uq192x64 memory)
	{
		if (_data.totalDeposited == 0) {
			return _data.accumulatedRewardWeight;
		}

		uint256 _elapsedTime = block.number.sub(_data.lastUpdatedBlock);
		if (_elapsedTime == 0) {
			return _data.accumulatedRewardWeight;
		}

		uint256 _rewardRate = _data.getRewardRate(_ctx);
		uint256 _distributeAmount = _rewardRate.mul(_elapsedTime);

		if (_distributeAmount == 0) {
			return _data.accumulatedRewardWeight;
		}

		FixedPointMath.uq192x64 memory _rewardWeight =
			FixedPointMath.fromU256(_distributeAmount).div(_data.totalDeposited);
		return _data.accumulatedRewardWeight.add(_rewardWeight);
	}

	/// @dev Adds an element to the list.
	///
	/// @param _element the element to add.
	function push(List storage _self, Data memory _element) internal {
		_self.elements.push(_element);
	}

	/// @dev Gets an element from the list.
	///
	/// @param _index the index in the list.
	///
	/// @return the element at the specified index.
	function get(List storage _self, uint256 _index) internal view returns (Data storage) {
		return _self.elements[_index];
	}

	/// @dev Gets the last element in the list.
	///
	/// This function will revert if there are no elements in the list.
	///ck
	/// @return the last element in the list.
	function last(List storage _self) internal view returns (Data storage) {
		return _self.elements[_self.lastIndex()];
	}

	/// @dev Gets the index of the last element in the list.
	///
	/// This function will revert if there are no elements in the list.
	///
	/// @return the index of the last element.
	function lastIndex(List storage _self) internal view returns (uint256) {
		uint256 _length = _self.length();
		return _length.sub(1, "Pool.List: list is empty");
	}

	/// @dev Gets the number of elements in the list.
	///
	/// @return the number of elements.
	function length(List storage _self) internal view returns (uint256) {
		return _self.elements.length;
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { FixedPointMath } from "../math/FixedPointMath.sol";
import { IDetailedERC20 } from "../../interfaces/token/ERC20/IDetailedERC20.sol";
import { Pool } from "./Pool.sol";

import "hardhat/console.sol";

/// @title Stake
///
/// @dev A library which provides the Stake data struct and associated functions.
library Stake {
	using FixedPointMath for FixedPointMath.uq192x64;
	using Pool for Pool.Data;
	using SafeMath for uint256;
	using Stake for Stake.Data;

	struct Data {
		uint256 totalDeposited;
		uint256 totalUnclaimed;
		FixedPointMath.uq192x64 lastAccumulatedWeight;
	}

	function update(
		Data storage _self,
		Pool.Data storage _pool,
		Pool.Context storage _ctx
	) internal {
		_self.totalUnclaimed = _self.getUpdatedTotalUnclaimed(_pool, _ctx);
		_self.lastAccumulatedWeight = _pool.getUpdatedAccumulatedRewardWeight(_ctx);
	}

	function getUpdatedTotalUnclaimed(
		Data storage _self,
		Pool.Data storage _pool,
		Pool.Context storage _ctx
	) internal view returns (uint256) {
		FixedPointMath.uq192x64 memory _currentAccumulatedWeight = _pool.getUpdatedAccumulatedRewardWeight(_ctx);
		FixedPointMath.uq192x64 memory _lastAccumulatedWeight = _self.lastAccumulatedWeight;

		if (_currentAccumulatedWeight.cmp(_lastAccumulatedWeight) == 0) {
			return _self.totalUnclaimed;
		}

		uint256 _distributedAmount =
			_currentAccumulatedWeight.sub(_lastAccumulatedWeight).mul(_self.totalDeposited).decode();

		return _self.totalUnclaimed.add(_distributedAmount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDetailedERC20 is IERC20 {
	function name() external returns (string memory);

	function symbol() external returns (string memory);

	function decimals() external returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../../Domain.sol";
import "../../../interfaces/token/ERC20/IDetailedERC20.sol";

import "hardhat/console.sol";

// solhint-disable no-inline-assembly
// solhint-disable not-rely-on-time

// Data part taken out for building of contracts that receive delegate calls
contract ERC20Data {
	/// @notice owner > balance mapping.
	mapping(address => uint256) public balanceOf;
	/// @notice owner > spender > allowance mapping.
	mapping(address => mapping(address => uint256)) public allowance;
	/// @notice owner > nonce mapping. Used in `permit`.
	mapping(address => uint256) public nonces;

	string public name;
	string public symbol;
	uint256 public decimals;
}

contract ERC20 is ERC20Data, Domain {
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	/**
	 * @dev Sets the values for {name} and {symbol}.
	 *
	 * The defaut value of {decimals} is 18. To select a different value for
	 * {decimals} you should overload it.
	 *
	 * All two of these values are immutable: they can only be set once during
	 * construction.
	 */
	constructor(string memory name_, string memory symbol_) public {
		name = name_;
		symbol = symbol_;
		decimals = 18;
	}

	/// @notice Transfers `amount` tokens from `msg.sender` to `to`.
	/// @param to The address to move the tokens.
	/// @param amount of the tokens to move.
	/// @return (bool) Returns True if succeeded.
	function transfer(address to, uint256 amount) public returns (bool) {
		// If `amount` is 0, or `msg.sender` is `to` nothing happens
		if (amount != 0) {
			uint256 srcBalance = balanceOf[msg.sender];
			require(srcBalance >= amount, "ERC20::transfer: balance too low");
			if (msg.sender != to) {
				require(to != address(0), "ERC20::transfer: no zero address"); // Moved down so low balance calls safe some gas

				balanceOf[msg.sender] = srcBalance - amount; // Underflow is checked
				balanceOf[to] += amount; // Can't overflow because totalSupply would be greater than 2^256-1
			}
		}
		emit Transfer(msg.sender, to, amount);
		return true;
	}

	/// @notice Transfers `amount` tokens from `from` to `to`. Caller needs approval for `from`.
	/// @param from Address to draw tokens from.
	/// @param to The address to move the tokens.
	/// @param amount The token amount to move.
	/// @return (bool) Returns True if succeeded.
	function transferFrom(
		address from,
		address to,
		uint256 amount
	) public returns (bool) {
		// If `amount` is 0, or `from` is `to` nothing happens
		if (amount != 0) {
			uint256 srcBalance = balanceOf[from];
			require(srcBalance >= amount, "ERC20::transferFrom: balance too low");

			if (from != to) {
				uint256 spenderAllowance = allowance[from][msg.sender];

				// If allowance is infinite, don't decrease it to save on gas (breaks with EIP-20).
				if (spenderAllowance != type(uint256).max) {
					require(spenderAllowance >= amount, "ERC20::transferFrom: allowance too low");
					allowance[from][msg.sender] = spenderAllowance - amount; // Underflow is checked
				}
				require(to != address(0), "ERC20::transferFrom: no zero address"); // Moved down so other failed calls safe some gas

				balanceOf[from] = srcBalance - amount; // Underflow is checked
				balanceOf[to] += amount; // Can't overflow because totalSupply would be greater than 2^256-1
			}
		}
		emit Transfer(from, to, amount);
		return true;
	}

	/// @notice Approves `amount` from sender to be spend by `spender`.
	/// @param spender Address of the party that can draw from msg.sender's account.
	/// @param amount The maximum collective amount that `spender` can draw.
	/// @return (bool) Returns True if approved.
	function approve(address spender, uint256 amount) public returns (bool) {
		allowance[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}

	// solhint-disable-next-line func-name-mixedcase
	function DOMAIN_SEPARATOR() external view returns (bytes32) {
		return _domainSeparator();
	}

	// keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
	bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

	/// @notice Approves `value` from `owner_` to be spend by `spender`.
	/// @param owner_ Address of the owner.
	/// @param spender The address of the spender that gets approved to draw from `owner_`.
	/// @param value The maximum collective amount that `spender` can draw.
	/// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
	function permit(
		address owner_,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external {
		require(owner_ != address(0), "ERC20::permit: Owner cannot be 0");
		require(block.timestamp < deadline, "ERC20: Expired");
		require(
			ecrecover(
				_getDigest(
					keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owner_, spender, value, nonces[owner_]++, deadline))
				),
				v,
				r,
				s
			) == owner_,
			"ERC20::permit: Invalid Signature"
		);
		allowance[owner_][spender] = value;
		emit Approval(owner_, spender, value);
	}
}

// SPDX-License-Identifier: MIT
// Based on code and smartness by Ross Campbell and Keno
// Uses immutable to store the domain separator to reduce gas usage
// If the chain id changes due to a fork, the forked chain will calculate on the fly.
pragma solidity 0.6.12;

// solhint-disable no-inline-assembly

contract Domain {
	bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH =
		keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
	// See https://eips.ethereum.org/EIPS/eip-191
	string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";

	// solhint-disable var-name-mixedcase
	bytes32 private immutable _DOMAIN_SEPARATOR;
	uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;

	/// @dev Calculate the DOMAIN_SEPARATOR
	function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
		return keccak256(abi.encode(DOMAIN_SEPARATOR_SIGNATURE_HASH, chainId, address(this)));
	}

	constructor() public {
		uint256 chainId;
		assembly {
			chainId := chainid()
		}
		_DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = chainId);
	}

	/// @dev Return the DOMAIN_SEPARATOR
	// It's named internal to allow making it public from the contract that uses it by creating a simple view function
	// with the desired public name, such as DOMAIN_SEPARATOR or domainSeparator.
	// solhint-disable-next-line func-name-mixedcase
	function _domainSeparator() internal view returns (bytes32) {
		uint256 chainId;
		assembly {
			chainId := chainid()
		}
		return chainId == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
	}

	function _getDigest(bytes32 dataHash) internal view returns (bytes32 digest) {
		digest = keccak256(abi.encodePacked(EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA, _domainSeparator(), dataHash));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../libraries/tokens/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
	uint256 public totalSupply;

	constructor(
		string memory _name,
		string memory _symbol,
		uint256 _initialAmount
	) public ERC20(_name, _symbol) {
		// Give the creator all initial tokens
		balanceOf[msg.sender] = _initialAmount;
		// Update total supply
		totalSupply = _initialAmount;
	}

	function mint(address account, uint256 amount) external {
		require(account != address(0), "MockERC20::mint: mint to the zero address");

		totalSupply += amount;
		balanceOf[account] += amount;

		emit Transfer(address(0), account, amount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./SushiToken.sol";

import "hardhat/console.sol";

interface IMigratorChef {
	// Perform LP token migration from legacy UniswapV2 to SushiSwap.
	// Take the current LP token address and return the new LP token address.
	// Migrator should have full access to the caller's LP token.
	// Return the new LP token address.
	//
	// XXX Migrator must have allowance access to UniswapV2 LP tokens.
	// SushiSwap must mint EXACTLY the same amount of SushiSwap LP tokens or
	// else something bad will happen. Traditional UniswapV2 does not
	// do that so be careful!
	function migrate(IERC20 token) external returns (IERC20);
}

// MasterChef is the master of Sushi. He can make Sushi and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SUSHI is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	// Info of each user.
	struct UserInfo {
		uint256 amount; // How many LP tokens the user has provided.
		uint256 rewardDebt; // Reward debt. See explanation below.
		//
		// We do some fancy math here. Basically, any point in time, the amount of SUSHIs
		// entitled to a user but is pending to be distributed is:
		//
		//   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
		//
		// Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
		//   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
		//   2. User receives the pending reward sent to his/her address.
		//   3. User's `amount` gets updated.
		//   4. User's `rewardDebt` gets updated.
	}
	// Info of each pool.
	struct PoolInfo {
		IERC20 lpToken; // Address of LP token contract.
		uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
		uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.
		uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
	}
	// The SUSHI TOKEN!
	SushiToken public sushi;
	// Dev address.
	address public devaddr;
	// Block number when bonus SUSHI period ends.
	uint256 public bonusEndBlock;
	// SUSHI tokens created per block.
	uint256 public sushiPerBlock;
	// Bonus muliplier for early sushi makers.
	uint256 public constant BONUS_MULTIPLIER = 10;
	// The migrator contract. It has a lot of power. Can only be set through governance (owner).
	IMigratorChef public migrator;
	// Info of each pool.
	PoolInfo[] public poolInfo;
	// Info of each user that stakes LP tokens.
	mapping(uint256 => mapping(address => UserInfo)) public userInfo;
	// Total allocation poitns. Must be the sum of all allocation points in all pools.
	uint256 public totalAllocPoint = 0;
	// The block number when SUSHI mining starts.
	uint256 public startBlock;
	event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
	event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
	event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

	constructor(
		SushiToken _sushi,
		address _devaddr,
		uint256 _sushiPerBlock,
		uint256 _startBlock,
		uint256 _bonusEndBlock
	) public {
		sushi = _sushi;
		devaddr = _devaddr;
		sushiPerBlock = _sushiPerBlock;
		bonusEndBlock = _bonusEndBlock;
		startBlock = _startBlock;
	}

	function poolLength() external view returns (uint256) {
		return poolInfo.length;
	}

	// Add a new lp to the pool. Can only be called by the owner.
	// XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
	function add(
		uint256 _allocPoint,
		IERC20 _lpToken,
		bool _withUpdate
	) public onlyOwner {
		if (_withUpdate) {
			massUpdatePools();
		}
		uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
		totalAllocPoint = totalAllocPoint.add(_allocPoint);
		poolInfo.push(
			PoolInfo({ lpToken: _lpToken, allocPoint: _allocPoint, lastRewardBlock: lastRewardBlock, accSushiPerShare: 0 })
		);
	}

	// Update the given pool's SUSHI allocation point. Can only be called by the owner.
	function set(
		uint256 _pid,
		uint256 _allocPoint,
		bool _withUpdate
	) public onlyOwner {
		if (_withUpdate) {
			massUpdatePools();
		}
		totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
		poolInfo[_pid].allocPoint = _allocPoint;
	}

	// Set the migrator contract. Can only be called by the owner.
	function setMigrator(IMigratorChef _migrator) public onlyOwner {
		migrator = _migrator;
	}

	// Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
	function migrate(uint256 _pid) public {
		require(address(migrator) != address(0), "migrate: no migrator");
		PoolInfo storage pool = poolInfo[_pid];
		IERC20 lpToken = pool.lpToken;
		uint256 bal = lpToken.balanceOf(address(this));
		lpToken.safeApprove(address(migrator), bal);
		IERC20 newLpToken = migrator.migrate(lpToken);
		require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
		pool.lpToken = newLpToken;
	}

	// Return reward multiplier over the given _from to _to block.
	function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
		if (_to <= bonusEndBlock) {
			return _to.sub(_from).mul(BONUS_MULTIPLIER);
		} else if (_from >= bonusEndBlock) {
			return _to.sub(_from);
		} else {
			return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(_to.sub(bonusEndBlock));
		}
	}

	// View function to see pending SUSHIs on frontend.
	function pendingSushi(uint256 _pid, address _user) external view returns (uint256) {
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][_user];
		uint256 accSushiPerShare = pool.accSushiPerShare;
		uint256 lpSupply = pool.lpToken.balanceOf(address(this));
		if (block.number > pool.lastRewardBlock && lpSupply != 0) {
			uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
			uint256 sushiReward = multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
			accSushiPerShare = accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupply));
		}
		return user.amount.mul(accSushiPerShare).div(1e12).sub(user.rewardDebt);
	}

	// Update reward vairables for all pools. Be careful of gas spending!
	function massUpdatePools() public {
		uint256 length = poolInfo.length;
		for (uint256 pid = 0; pid < length; ++pid) {
			updatePool(pid);
		}
	}

	// Update reward variables of the given pool to be up-to-date.
	function updatePool(uint256 _pid) public {
		PoolInfo storage pool = poolInfo[_pid];
		if (block.number <= pool.lastRewardBlock) {
			return;
		}
		uint256 lpSupply = pool.lpToken.balanceOf(address(this));
		if (lpSupply == 0) {
			pool.lastRewardBlock = block.number;
			return;
		}
		uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
		uint256 sushiReward = multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
		sushi.mint(devaddr, sushiReward.div(10));
		sushi.mint(address(this), sushiReward);
		pool.accSushiPerShare = pool.accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupply));
		pool.lastRewardBlock = block.number;
	}

	// Deposit LP tokens to MasterChef for SUSHI allocation.
	function deposit(uint256 _pid, uint256 _amount) public {
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];
		updatePool(_pid);
		if (user.amount > 0) {
			uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
			safeSushiTransfer(msg.sender, pending);
		}
		pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
		user.amount = user.amount.add(_amount);
		user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
		emit Deposit(msg.sender, _pid, _amount);
	}

	// Withdraw LP tokens from MasterChef.
	function withdraw(uint256 _pid, uint256 _amount) public {
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];
		require(user.amount >= _amount, "withdraw: not good");
		updatePool(_pid);
		uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
		safeSushiTransfer(msg.sender, pending);
		user.amount = user.amount.sub(_amount);
		user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
		pool.lpToken.safeTransfer(address(msg.sender), _amount);
		emit Withdraw(msg.sender, _pid, _amount);
	}

	// Withdraw without caring about rewards. EMERGENCY ONLY.
	function emergencyWithdraw(uint256 _pid) public {
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];
		pool.lpToken.safeTransfer(address(msg.sender), user.amount);
		emit EmergencyWithdraw(msg.sender, _pid, user.amount);
		user.amount = 0;
		user.rewardDebt = 0;
	}

	// Safe sushi transfer function, just in case if rounding error causes pool to not have enough SUSHIs.
	function safeSushiTransfer(address _to, uint256 _amount) internal {
		uint256 sushiBal = sushi.balanceOf(address(this));
		if (_amount > sushiBal) {
			sushi.transfer(_to, sushiBal);
		} else {
			sushi.transfer(_to, _amount);
		}
	}

	// Update dev address by the previous dev.
	function dev(address _devaddr) public {
		require(msg.sender == devaddr, "dev: wut?");
		devaddr = _devaddr;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// SushiToken with Governance.
contract SushiToken is ERC20("SushiToken", "SUSHI"), Ownable {
	/// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
	function mint(address _to, uint256 _amount) public onlyOwner {
		_mint(_to, _amount);
		_moveDelegates(address(0), _delegates[_to], _amount);
	}

	// Copied and modified from YAM code:
	// https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
	// https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
	// Which is copied and modified from COMPOUND:
	// https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

	/// @notice A record of each accounts delegate
	mapping(address => address) internal _delegates;

	/// @notice A checkpoint for marking number of votes from a given block
	struct Checkpoint {
		uint32 fromBlock;
		uint256 votes;
	}

	/// @notice A record of votes checkpoints for each account, by index
	mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

	/// @notice The number of checkpoints for each account
	mapping(address => uint32) public numCheckpoints;

	/// @notice The EIP-712 typehash for the contract's domain
	bytes32 public constant DOMAIN_TYPEHASH =
		keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

	/// @notice The EIP-712 typehash for the delegation struct used by the contract
	bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

	/// @notice A record of states for signing / validating signatures
	mapping(address => uint256) public nonces;

	/// @notice An event thats emitted when an account changes its delegate
	event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

	/// @notice An event thats emitted when a delegate account's vote balance changes
	event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

	/**
	 * @notice Delegate votes from `msg.sender` to `delegatee`
	 * @param delegator The address to get delegatee for
	 */
	function delegates(address delegator) external view returns (address) {
		return _delegates[delegator];
	}

	/**
	 * @notice Delegate votes from `msg.sender` to `delegatee`
	 * @param delegatee The address to delegate votes to
	 */
	function delegate(address delegatee) external {
		return _delegate(msg.sender, delegatee);
	}

	/**
	 * @notice Delegates votes from signatory to `delegatee`
	 * @param delegatee The address to delegate votes to
	 * @param nonce The contract state required to match the signature
	 * @param expiry The time at which to expire the signature
	 * @param v The recovery byte of the signature
	 * @param r Half of the ECDSA signature pair
	 * @param s Half of the ECDSA signature pair
	 */
	function delegateBySig(
		address delegatee,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external {
		bytes32 domainSeparator =
			keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this)));

		bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));

		bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

		address signatory = ecrecover(digest, v, r, s);
		require(signatory != address(0), "SUSHI::delegateBySig: invalid signature");
		require(nonce == nonces[signatory]++, "SUSHI::delegateBySig: invalid nonce");
		require(now <= expiry, "SUSHI::delegateBySig: signature expired");
		return _delegate(signatory, delegatee);
	}

	/**
	 * @notice Gets the current votes balance for `account`
	 * @param account The address to get votes balance
	 * @return The number of current votes for `account`
	 */
	function getCurrentVotes(address account) external view returns (uint256) {
		uint32 nCheckpoints = numCheckpoints[account];
		return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
	}

	/**
	 * @notice Determine the prior number of votes for an account as of a block number
	 * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
	 * @param account The address of the account to check
	 * @param blockNumber The block number to get the vote balance at
	 * @return The number of votes the account had as of the given block
	 */
	function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256) {
		require(blockNumber < block.number, "SUSHI::getPriorVotes: not yet determined");

		uint32 nCheckpoints = numCheckpoints[account];
		if (nCheckpoints == 0) {
			return 0;
		}

		// First check most recent balance
		if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
			return checkpoints[account][nCheckpoints - 1].votes;
		}

		// Next check implicit zero balance
		if (checkpoints[account][0].fromBlock > blockNumber) {
			return 0;
		}

		uint32 lower = 0;
		uint32 upper = nCheckpoints - 1;
		while (upper > lower) {
			uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
			Checkpoint memory cp = checkpoints[account][center];
			if (cp.fromBlock == blockNumber) {
				return cp.votes;
			} else if (cp.fromBlock < blockNumber) {
				lower = center;
			} else {
				upper = center - 1;
			}
		}
		return checkpoints[account][lower].votes;
	}

	function _delegate(address delegator, address delegatee) internal {
		address currentDelegate = _delegates[delegator];
		uint256 delegatorBalance = balanceOf(delegator); // balance of underlying SUSHIs (not scaled);
		_delegates[delegator] = delegatee;

		emit DelegateChanged(delegator, currentDelegate, delegatee);

		_moveDelegates(currentDelegate, delegatee, delegatorBalance);
	}

	function _moveDelegates(
		address srcRep,
		address dstRep,
		uint256 amount
	) internal {
		if (srcRep != dstRep && amount > 0) {
			if (srcRep != address(0)) {
				// decrease old representative
				uint32 srcRepNum = numCheckpoints[srcRep];
				uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
				uint256 srcRepNew = srcRepOld.sub(amount);
				_writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
			}

			if (dstRep != address(0)) {
				// increase new representative
				uint32 dstRepNum = numCheckpoints[dstRep];
				uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
				uint256 dstRepNew = dstRepOld.add(amount);
				_writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
			}
		}
	}

	function _writeCheckpoint(
		address delegatee,
		uint32 nCheckpoints,
		uint256 oldVotes,
		uint256 newVotes
	) internal {
		uint32 blockNumber = safe32(block.number, "SUSHI::_writeCheckpoint: block number exceeds 32 bits");

		if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
			checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
		} else {
			checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
			numCheckpoints[delegatee] = nCheckpoints + 1;
		}

		emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
	}

	function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
		require(n < 2**32, errorMessage);
		return uint32(n);
	}

	function getChainId() internal pure returns (uint256) {
		uint256 chainId;
		assembly {
			chainId := chainid()
		}
		return chainId;
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakingPools {
	function reward() external view returns (IERC20);

	function rewardRate() external view returns (uint256);

	function totalRewardWeight() external view returns (uint256);

	function getPoolToken(uint256 _poolId) external view returns (IERC20);

	function getStakeTotalUnclaimed(address _account, uint256 _poolId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { BoringMath, BoringMath128 } from "./libraries/boring/BoringMath.sol";
import { BoringOwnable } from "./libraries/boring/BoringOwnable.sol";
import { BoringERC20, IERC20 } from "./libraries/boring/BoringERC20.sol";
import { SignedSafeMath } from "./libraries/math/SignedSafeMath.sol";

import { IRewarder } from "./interfaces/sushi/IRewarder.sol";
import { IMasterChef } from "./interfaces/sushi/IMasterChef.sol";

import "hardhat/console.sol";

interface IMigratorChef {
	// Take the current LP token address and return the new LP token address.
	// Migrator should have full access to the caller's LP token.
	function migrate(IERC20 token) external returns (IERC20);
}

/// @notice The (older) MasterChef contract gives out a constant number of SUSHI tokens per block.
/// It is the only address with minting rights for SUSHI.
/// The idea for this MasterChef V2 (MCV2) contract is therefore to be the owner of a dummy token
/// that is deposited into the MasterChef V1 (MCV1) contract.
/// The allocation point for this pool on MCV1 is the total allocation point for all pools that receive double incentives.
contract MasterChefV2 is BoringOwnable {
	using BoringMath for uint256;
	using BoringMath128 for uint128;
	using BoringERC20 for IERC20;
	using SignedSafeMath for int256;

	/// @notice Info of each MCV2 user.
	/// `amount` LP token amount the user has provided.
	/// `rewardDebt` The amount of SUSHI entitled to the user.
	struct UserInfo {
		uint256 amount;
		int256 rewardDebt;
	}

	/// @notice Info of each MCV2 pool.
	/// `allocPoint` The amount of allocation points assigned to the pool.
	/// Also known as the amount of SUSHI to distribute per block.
	struct PoolInfo {
		uint128 accSushiPerShare;
		uint64 lastRewardBlock;
		uint64 allocPoint;
	}

	/// @notice Address of MCV1 contract.
	IMasterChef public immutable MASTER_CHEF;
	/// @notice Address of SUSHI contract.
	IERC20 public immutable SUSHI;
	/// @notice The index of MCV2 master pool in MCV1.
	uint256 public immutable MASTER_PID;
	// @notice The migrator contract. It has a lot of power. Can only be set through governance (owner).
	IMigratorChef public migrator;

	/// @notice Info of each MCV2 pool.
	PoolInfo[] public poolInfo;
	/// @notice Address of the LP token for each MCV2 pool.
	IERC20[] public lpToken;
	/// @notice Address of each `IRewarder` contract in MCV2.
	IRewarder[] public rewarder;

	/// @notice Info of each user that stakes LP tokens.
	mapping(uint256 => mapping(address => UserInfo)) public userInfo;
	/// @dev Total allocation points. Must be the sum of all allocation points in all pools.
	uint256 public totalAllocPoint;

	uint256 private constant MASTERCHEF_SUSHI_PER_BLOCK = 1e20;
	uint256 private constant ACC_SUSHI_PRECISION = 1e12;

	event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
	event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
	event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
	event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
	event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, IRewarder indexed rewarder);
	event LogSetPool(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder, bool overwrite);
	event LogUpdatePool(uint256 indexed pid, uint64 lastRewardBlock, uint256 lpSupply, uint256 accSushiPerShare);
	event LogInit();

	/// @param _MASTER_CHEF The SushiSwap MCV1 contract address.
	/// @param _sushi The SUSHI token contract address.
	/// @param _MASTER_PID The pool ID of the dummy token on the base MCV1 contract.
	constructor(
		IMasterChef _MASTER_CHEF,
		IERC20 _sushi,
		uint256 _MASTER_PID
	) public {
		MASTER_CHEF = _MASTER_CHEF;
		SUSHI = _sushi;
		MASTER_PID = _MASTER_PID;
	}

	/// @notice Deposits a dummy token to `MASTER_CHEF` MCV1. This is required because MCV1 holds the minting rights for SUSHI.
	/// Any balance of transaction sender in `dummyToken` is transferred.
	/// The allocation point for the pool on MCV1 is the total allocation point for all pools that receive double incentives.
	/// @param dummyToken The address of the ERC-20 token to deposit into MCV1.
	function init(IERC20 dummyToken) external {
		uint256 balance = dummyToken.balanceOf(msg.sender);
		require(balance != 0, "MasterChefV2: Balance must exceed 0");
		dummyToken.safeTransferFrom(msg.sender, address(this), balance);
		dummyToken.approve(address(MASTER_CHEF), balance);
		MASTER_CHEF.deposit(MASTER_PID, balance);
		emit LogInit();
	}

	/// @notice Returns the number of MCV2 pools.
	function poolLength() public view returns (uint256 pools) {
		pools = poolInfo.length;
	}

	/// @notice Add a new LP to the pool. Can only be called by the owner.
	/// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
	/// @param allocPoint AP of the new pool.
	/// @param _lpToken Address of the LP ERC-20 token.
	/// @param _rewarder Address of the rewarder delegate.
	function add(
		uint256 allocPoint,
		IERC20 _lpToken,
		IRewarder _rewarder
	) public onlyOwner {
		uint256 lastRewardBlock = block.number;
		totalAllocPoint = totalAllocPoint.add(allocPoint);
		lpToken.push(_lpToken);
		rewarder.push(_rewarder);

		poolInfo.push(
			PoolInfo({ allocPoint: allocPoint.to64(), lastRewardBlock: lastRewardBlock.to64(), accSushiPerShare: 0 })
		);
		emit LogPoolAddition(lpToken.length.sub(1), allocPoint, _lpToken, _rewarder);
	}

	/// @notice Update the given pool's SUSHI allocation point and `IRewarder` contract. Can only be called by the owner.
	/// @param _pid The index of the pool. See `poolInfo`.
	/// @param _allocPoint New AP of the pool.
	/// @param _rewarder Address of the rewarder delegate.
	/// @param overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
	function set(
		uint256 _pid,
		uint256 _allocPoint,
		IRewarder _rewarder,
		bool overwrite
	) public onlyOwner {
		totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
		poolInfo[_pid].allocPoint = _allocPoint.to64();
		if (overwrite) {
			rewarder[_pid] = _rewarder;
		}
		emit LogSetPool(_pid, _allocPoint, overwrite ? _rewarder : rewarder[_pid], overwrite);
	}

	/// @notice Set the `migrator` contract. Can only be called by the owner.
	/// @param _migrator The contract address to set.
	function setMigrator(IMigratorChef _migrator) public onlyOwner {
		migrator = _migrator;
	}

	/// @notice Migrate LP token to another LP contract through the `migrator` contract.
	/// @param _pid The index of the pool. See `poolInfo`.
	function migrate(uint256 _pid) public {
		require(address(migrator) != address(0), "MasterChefV2: no migrator set");
		IERC20 _lpToken = lpToken[_pid];
		uint256 bal = _lpToken.balanceOf(address(this));
		_lpToken.approve(address(migrator), bal);
		IERC20 newLpToken = migrator.migrate(_lpToken);
		require(bal == newLpToken.balanceOf(address(this)), "MasterChefV2: migrated balance must match");
		lpToken[_pid] = newLpToken;
	}

	/// @notice View function to see pending SUSHI on frontend.
	/// @param _pid The index of the pool. See `poolInfo`.
	/// @param _user Address of user.
	/// @return pending SUSHI reward for a given user.
	function pendingSushi(uint256 _pid, address _user) external view returns (uint256 pending) {
		PoolInfo memory pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][_user];
		uint256 accSushiPerShare = pool.accSushiPerShare;
		uint256 lpSupply = lpToken[_pid].balanceOf(address(this));
		if (block.number > pool.lastRewardBlock && lpSupply != 0) {
			uint256 blocks = block.number.sub(pool.lastRewardBlock);
			uint256 sushiReward = blocks.mul(sushiPerBlock()).mul(pool.allocPoint) / totalAllocPoint;
			accSushiPerShare = accSushiPerShare.add(sushiReward.mul(ACC_SUSHI_PRECISION) / lpSupply);
		}
		pending = int256(user.amount.mul(accSushiPerShare) / ACC_SUSHI_PRECISION).sub(user.rewardDebt).toUInt256();
	}

	/// @notice Update reward variables for all pools. Be careful of gas spending!
	/// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
	function massUpdatePools(uint256[] calldata pids) external {
		uint256 len = pids.length;
		for (uint256 i = 0; i < len; ++i) {
			updatePool(pids[i]);
		}
	}

	/// @notice Calculates and returns the `amount` of SUSHI per block.
	function sushiPerBlock() public view returns (uint256 amount) {
		amount =
			uint256(MASTERCHEF_SUSHI_PER_BLOCK).mul(MASTER_CHEF.poolInfo(MASTER_PID).allocPoint) /
			MASTER_CHEF.totalAllocPoint();
	}

	/// @notice Update reward variables of the given pool.
	/// @param pid The index of the pool. See `poolInfo`.
	/// @return pool Returns the pool that was updated.
	function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
		pool = poolInfo[pid];
		if (block.number > pool.lastRewardBlock) {
			uint256 lpSupply = lpToken[pid].balanceOf(address(this));
			if (lpSupply > 0) {
				uint256 blocks = block.number.sub(pool.lastRewardBlock);
				uint256 sushiReward = blocks.mul(sushiPerBlock()).mul(pool.allocPoint) / totalAllocPoint;
				pool.accSushiPerShare = pool.accSushiPerShare.add(
					(sushiReward.mul(ACC_SUSHI_PRECISION) / lpSupply).to128()
				);
			}
			pool.lastRewardBlock = block.number.to64();
			poolInfo[pid] = pool;
			emit LogUpdatePool(pid, pool.lastRewardBlock, lpSupply, pool.accSushiPerShare);
		}
	}

	/// @notice Deposit LP tokens to MCV2 for SUSHI allocation.
	/// @param pid The index of the pool. See `poolInfo`.
	/// @param amount LP token amount to deposit.
	/// @param to The receiver of `amount` deposit benefit.
	function deposit(
		uint256 pid,
		uint256 amount,
		address to
	) public {
		PoolInfo memory pool = updatePool(pid);
		UserInfo storage user = userInfo[pid][to];

		// Effects
		user.amount = user.amount.add(amount);
		user.rewardDebt = user.rewardDebt.add(int256(amount.mul(pool.accSushiPerShare) / ACC_SUSHI_PRECISION));

		// Interactions
		IRewarder _rewarder = rewarder[pid];
		if (address(_rewarder) != address(0)) {
			_rewarder.onSushiReward(pid, to, to, 0, user.amount);
		}

		lpToken[pid].safeTransferFrom(msg.sender, address(this), amount);

		emit Deposit(msg.sender, pid, amount, to);
	}

	/// @notice Withdraw LP tokens from MCV2.
	/// @param pid The index of the pool. See `poolInfo`.
	/// @param amount LP token amount to withdraw.
	/// @param to Receiver of the LP tokens.
	function withdraw(
		uint256 pid,
		uint256 amount,
		address to
	) public {
		PoolInfo memory pool = updatePool(pid);
		UserInfo storage user = userInfo[pid][msg.sender];

		// Effects
		user.rewardDebt = user.rewardDebt.sub(int256(amount.mul(pool.accSushiPerShare) / ACC_SUSHI_PRECISION));
		user.amount = user.amount.sub(amount);

		// Interactions
		IRewarder _rewarder = rewarder[pid];
		if (address(_rewarder) != address(0)) {
			_rewarder.onSushiReward(pid, msg.sender, to, 0, user.amount);
		}

		lpToken[pid].safeTransfer(to, amount);

		emit Withdraw(msg.sender, pid, amount, to);
	}

	/// @notice Harvest proceeds for transaction sender to `to`.
	/// @param pid The index of the pool. See `poolInfo`.
	/// @param to Receiver of SUSHI rewards.
	function harvest(uint256 pid, address to) public {
		PoolInfo memory pool = updatePool(pid);
		UserInfo storage user = userInfo[pid][msg.sender];
		int256 accumulatedSushi = int256(user.amount.mul(pool.accSushiPerShare) / ACC_SUSHI_PRECISION);
		uint256 _pendingSushi = accumulatedSushi.sub(user.rewardDebt).toUInt256();

		// Effects
		user.rewardDebt = accumulatedSushi;

		// Interactions
		if (_pendingSushi != 0) {
			SUSHI.safeTransfer(to, _pendingSushi);
		}

		IRewarder _rewarder = rewarder[pid];
		if (address(_rewarder) != address(0)) {
			_rewarder.onSushiReward(pid, msg.sender, to, _pendingSushi, user.amount);
		}

		emit Harvest(msg.sender, pid, _pendingSushi);
	}

	/// @notice Withdraw LP tokens from MCV2 and harvest proceeds for transaction sender to `to`.
	/// @param pid The index of the pool. See `poolInfo`.
	/// @param amount LP token amount to withdraw.
	/// @param to Receiver of the LP tokens and SUSHI rewards.
	function withdrawAndHarvest(
		uint256 pid,
		uint256 amount,
		address to
	) public {
		PoolInfo memory pool = updatePool(pid);
		UserInfo storage user = userInfo[pid][msg.sender];
		int256 accumulatedSushi = int256(user.amount.mul(pool.accSushiPerShare) / ACC_SUSHI_PRECISION);
		uint256 _pendingSushi = accumulatedSushi.sub(user.rewardDebt).toUInt256();

		// Effects
		user.rewardDebt = accumulatedSushi.sub(int256(amount.mul(pool.accSushiPerShare) / ACC_SUSHI_PRECISION));
		user.amount = user.amount.sub(amount);

		// Interactions
		SUSHI.safeTransfer(to, _pendingSushi);

		IRewarder _rewarder = rewarder[pid];
		if (address(_rewarder) != address(0)) {
			_rewarder.onSushiReward(pid, msg.sender, to, _pendingSushi, user.amount);
		}

		lpToken[pid].safeTransfer(to, amount);

		emit Withdraw(msg.sender, pid, amount, to);
		emit Harvest(msg.sender, pid, _pendingSushi);
	}

	/// @notice Harvests SUSHI from `MASTER_CHEF` MCV1 and pool `MASTER_PID` to this MCV2 contract.
	function harvestFromMasterChef() public {
		MASTER_CHEF.deposit(MASTER_PID, 0);
	}

	/// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
	/// @param pid The index of the pool. See `poolInfo`.
	/// @param to Receiver of the LP tokens.
	function emergencyWithdraw(uint256 pid, address to) public {
		UserInfo storage user = userInfo[pid][msg.sender];
		uint256 amount = user.amount;
		user.amount = 0;
		user.rewardDebt = 0;

		IRewarder _rewarder = rewarder[pid];
		if (address(_rewarder) != address(0)) {
			_rewarder.onSushiReward(pid, msg.sender, to, 0, 0);
		}

		// Note: transfer can fail or succeed if `amount` is zero.
		lpToken[pid].safeTransfer(to, amount);
		emit EmergencyWithdraw(msg.sender, pid, amount, to);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

library SignedSafeMath {
	int256 private constant _INT256_MIN = -2**255;

	/**
	 * @dev Returns the multiplication of two signed integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `*` operator.
	 *
	 * Requirements:
	 *
	 * - Multiplication cannot overflow.
	 */
	function mul(int256 a, int256 b) internal pure returns (int256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
			return 0;
		}

		require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

		int256 c = a * b;
		require(c / a == b, "SignedSafeMath: multiplication overflow");

		return c;
	}

	/**
	 * @dev Returns the integer division of two signed integers. Reverts on
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
	function div(int256 a, int256 b) internal pure returns (int256) {
		require(b != 0, "SignedSafeMath: division by zero");
		require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

		int256 c = a / b;

		return c;
	}

	/**
	 * @dev Returns the subtraction of two signed integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a - b;
		require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

		return c;
	}

	/**
	 * @dev Returns the addition of two signed integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `+` operator.
	 *
	 * Requirements:
	 *
	 * - Addition cannot overflow.
	 */
	function add(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a + b;
		require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

		return c;
	}

	function toUInt256(int256 a) internal pure returns (uint256) {
		require(a >= 0, "Integer < 0");
		return uint256(a);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { BoringERC20, IERC20 } from "../../libraries/boring/BoringERC20.sol";

interface IMasterChef {
	using BoringERC20 for IERC20;
	struct UserInfo {
		uint256 amount; // How many LP tokens the user has provided.
		uint256 rewardDebt; // Reward debt. See explanation below.
	}

	struct PoolInfo {
		IERC20 lpToken; // Address of LP token contract.
		uint256 allocPoint; // How many allocation points assigned to this pool. SUSHI to distribute per block.
		uint256 lastRewardBlock; // Last block number that SUSHI distribution occurs.
		uint256 accSushiPerShare; // Accumulated SUSHI per share, times 1e12. See below.
	}

	function poolInfo(uint256 pid) external view returns (IMasterChef.PoolInfo memory);

	function totalAllocPoint() external view returns (uint256);

	function deposit(uint256 _pid, uint256 _amount) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
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