// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISimpleBond.sol";
import "./interfaces/IUAR.sol";

/// @title Simple Bond
/// @author zapaz.eth
/// @notice SimpleBond is a simple Bond mecanism, allowing to sell tokens bonded and get rewards tokens
/// @notice The reward token is fully claimable only after the vesting period
/// @dev Bond is Ownable, access controled by onlyOwner
/// @dev Use SafeERC20
contract SimpleBond is ISimpleBond, Ownable {
  using SafeERC20 for IERC20;

  struct Bond {
    address token;
    uint256 amount;
    uint256 rewards;
    uint256 claimed;
    uint256 block;
  }

  /// Rewards token address
  address public immutable tokenRewards;

  /// Rewards ratio for token bonded
  /// @dev rewardsRatio is per billion of token bonded
  mapping(address => uint256) public rewardsRatio;

  /// Vesting period
  /// @dev defined in number of block
  uint256 public vestingBlocks;

  /// Bonds for each address
  /// @dev bond index starts at 0 for each address
  mapping(address => Bond[]) public bonds;

  /// Total rewards
  uint256 public totalRewards;

  /// Total rewards claimed
  uint256 public totalClaimedRewards;

  /// Treasury address
  address public treasury;

  /// Simple Bond constructor
  /// @param tokenRewards_ Rewards token address
  /// @param vestingBlocks_ Vesting duration in blocks
  constructor(
    address tokenRewards_,
    uint256 vestingBlocks_,
    address treasury_
  ) {
    require(tokenRewards_ != address(0), "Invalid Reward token");
    tokenRewards = tokenRewards_;
    setVestingBlocks(vestingBlocks_);
    setTreasury(treasury_);
  }

  /// @notice Set Rewards for specific Token
  /// @param token token address
  /// @param tokenRewardsRatio rewardsRatio for this token
  function setRewards(address token, uint256 tokenRewardsRatio) public override onlyOwner {
    require(token != address(0), "Invalid Reward token");
    rewardsRatio[token] = tokenRewardsRatio;

    emit LogSetRewards(token, tokenRewardsRatio);
  }

  /// @notice Set vesting duration
  /// @param vestingBlocks_ vesting duration in blocks
  function setVestingBlocks(uint256 vestingBlocks_) public override onlyOwner {
    require(vestingBlocks_ > 0, "Invalid Vesting blocks number");
    vestingBlocks = vestingBlocks_;
  }

  /// @notice Set treasury address
  /// @param treasury_ treasury address
  function setTreasury(address treasury_) public override onlyOwner {
    require(treasury_ != address(0), "Invalid Treasury address");
    treasury = treasury_;
  }

  /// @notice Bond tokens
  /// @param token bonded token address
  /// @param amount amount of token to bond
  /// @return bondId Bond id
  function bond(address token, uint256 amount) public override returns (uint256 bondId) {
    require(rewardsRatio[token] > 0, "Token not allowed");

    // @dev throws if not enough allowance or tokens for address
    // @dev must set token allowance for this smartcontract previously
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

    Bond memory bnd;
    bnd.token = token;
    bnd.amount = amount;
    bnd.block = block.number;

    uint256 rewards = (amount * rewardsRatio[token]) / 1_000_000_000;
    bnd.rewards = rewards;
    totalRewards += rewards;

    bondId = bonds[msg.sender].length;
    bonds[msg.sender].push(bnd);

    emit LogBond(msg.sender, bnd.token, bnd.amount, bnd.rewards, bnd.block, bondId);
  }

  /// @notice Claim all rewards
  /// @return claimed Rewards claimed succesfully
  function claim() public override returns (uint256 claimed) {
    for (uint256 index = 0; (index < bonds[msg.sender].length); index += 1) {
      claimed += claimBond(index);
    }
  }

  /// @notice Claim bond rewards
  /// @return claimed Rewards claimed succesfully
  function claimBond(uint256 index) public override returns (uint256 claimed) {
    Bond storage bnd = bonds[msg.sender][index];
    uint256 claimAmount = _bondClaimableRewards(bnd);

    if (claimAmount > 0) {
      bnd.claimed += claimAmount;
      totalClaimedRewards += claimAmount;

      assert(bnd.claimed <= bnd.rewards);
      IUAR(tokenRewards).raiseCapital(claimAmount);
      IERC20(tokenRewards).safeTransferFrom(treasury, msg.sender, claimAmount);
    }

    emit LogClaim(msg.sender, index, claimed);
  }

  /// @notice Withdraw token from the smartcontract, only for owner
  /// @param  token token withdraw
  /// @param amount amount withdraw
  function withdraw(address token, uint256 amount) public override onlyOwner {
    IERC20(token).safeTransfer(treasury, amount);
  }

  /// @notice Bond rewards balance: amount and already claimed
  /// @return rewards Amount of rewards
  /// @return rewardsClaimed Amount of rewards already claimed
  /// @return rewardsClaimable Amount of still claimable rewards
  function rewardsOf(address addr)
    public
    view
    override
    returns (
      uint256 rewards,
      uint256 rewardsClaimed,
      uint256 rewardsClaimable
    )
  {
    for (uint256 index = 0; index < bonds[addr].length; index += 1) {
      (uint256 bondRewards, uint256 bondClaimedRewards, uint256 bondClaimableRewards) = rewardsBondOf(addr, index);
      rewards += bondRewards;
      rewardsClaimed += bondClaimedRewards;
      rewardsClaimable += bondClaimableRewards;
    }
  }

  /// @notice Bond rewards balance: amount and already claimed
  /// @return rewards Amount of rewards
  /// @return rewardsClaimed Amount of rewards already claimed
  /// @return rewardsClaimable Amount of still claimable rewards
  function rewardsBondOf(address addr, uint256 index)
    public
    view
    override
    returns (
      uint256 rewards,
      uint256 rewardsClaimed,
      uint256 rewardsClaimable
    )
  {
    Bond memory bnd = bonds[addr][index];
    rewards = bnd.rewards;
    rewardsClaimed = bnd.claimed;
    rewardsClaimable = _bondClaimableRewards(bnd);
  }

  /// @notice Get number of bonds for address
  /// @return number of bonds
  function bondsCount(address addr) public view override returns (uint256) {
    return bonds[addr].length;
  }

  /// @dev calculate claimable rewards during vesting period, or all claimable rewards after, minus already claimed
  function _bondClaimableRewards(Bond memory bnd) internal view returns (uint256 claimable) {
    assert(block.number >= bnd.block);

    uint256 blocks = block.number - bnd.block;
    uint256 totalClaimable;

    if (blocks < vestingBlocks) {
      totalClaimable = (bnd.rewards * blocks) / vestingBlocks;
    } else {
      totalClaimable = bnd.rewards;
    }

    assert(totalClaimable >= bnd.claimed);
    claimable = totalClaimable - bnd.claimed;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISimpleBond {
  event LogSetRewards(address token, uint256 rewardsRatio);

  event LogBond(address addr, address token, uint256 amount, uint256 rewards, uint256 block, uint256 bondId);

  event LogClaim(address addr, uint256 index, uint256 rewards);

  function setRewards(address token, uint256 tokenRewardsRatio) external;

  function setTreasury(address treasury) external;

  function setVestingBlocks(uint256 vestingBlocks_) external;

  function bond(address token, uint256 amount) external returns (uint256 bondId);

  function bondsCount(address token) external returns (uint256 bondNb);

  function claim() external returns (uint256 claimed);

  function claimBond(uint256 index) external returns (uint256 claimed);

  function withdraw(address token, uint256 amount) external;

  function rewardsOf(address addr)
    external
    view
    returns (
      uint256 rewards,
      uint256 rewardsClaimed,
      uint256 rewardsClaimable
    );

  function rewardsBondOf(address addr, uint256 index)
    external
    view
    returns (
      uint256 rewards,
      uint256 rewardsClaimed,
      uint256 rewardsClaimable
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUAR {
  function raiseCapital(uint256 amount) external;
}