/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

pragma solidity ^0.6.2;
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

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

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

// PopsicleStand is a place where you can get beautiful popsicles that consist of ICE.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once ICE is sufficiently
// distributed and the community can show to govern itself.
//
// Give it a read. Contact us at popsicle.finance if you have any suggestions.

pragma solidity ^0.6.2;

contract PopsicleStand is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 lastRewardBlock; // Last block number that tokens distribution occurs.
        uint256 remainingProjectTokenReward; // Tokens that weren't distributed. See the explanation below.
        uint256 remainingIceTokenReward; // Tokens that weren't distributed. See the explanation below.
        //
        // Some formulas. At any point in time, the amount of tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (userShare * blockCount * tokenPerBlock) + user.remainingReward
        //
        //   To calculate the amount owned to a user by a contract we use:
        //
        //   user.remainingReward = pendingReward - transferredReward
        //
        // Whenever a user deposits or withdraws LP tokens to a contract. Here's what happens:
        //   1. The users's `lastRewardBlock` gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `restReward` gets updated.
        //   5. `Supplies` gets updated.
    }
    
    struct Supplies {
        uint256 blockNumber; // Block number in which there were changes to the contract's LP amount.
        uint256 totalSupplied; // Total contract LP amount
    }
    
    uint256 public projectTokenPerBlock; // Project tokens per block
    uint256 public iceTokenPerBlock; // ICE tokens per block
    IERC20 public projectToken; // Project token pointer
    IERC20 public iceToken; // ICE token pointer
    IERC20 public lpToken; // Liquidity Provider token pointer
    uint256 public endBlock; // Block on which the reward calculation should end
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    
    constructor (address _lpTokenAddress, address _projectTokenAddress, address _iceTokenAddress, uint256 _projectTokenPerBlock, uint256 _icePerBlock) public {
        lpToken = IERC20(_lpTokenAddress);
        projectToken = IERC20(_projectTokenAddress);
        iceToken = IERC20(_iceTokenAddress);
        projectTokenPerBlock = _projectTokenPerBlock;
        iceTokenPerBlock = _icePerBlock;
        endBlock = block.number + 1192100; // 1192100(near 6 months) Block in which the contract was deployed plus contract duration block number
    }
    
    
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public usersInfo;
    // Info of each contract state changes
    Supplies[] public supplyAtBlock;
    
    // View function to display pending Tokens on frontend depending on the point in time.
    function getUserReward(address _userAddress, uint256 upperBlockNumber) public view returns(uint256 projectTokenPending, uint256 iceTokenPending) {
        UserInfo memory user = usersInfo[_userAddress];
        if (user.lastRewardBlock == 0 || supplyAtBlock.length == 0) {
            return (0, 0);
        }
        
        uint256 startIndex = findElementIndex(user.lastRewardBlock);
        uint256 endIndex = supplyAtBlock.length - 1;
        uint256 sumProjectToken = 0;
        uint256 sumIceToken = 0;
        for (uint256 i = startIndex; i < endIndex; i++)
        {
            (uint256 projectTokenPerPeriod, uint256 iceTokenPerPeriod) = getUserRewardPerPeriod(i, user.amount);
            sumProjectToken += projectTokenPerPeriod;
            sumIceToken += iceTokenPerPeriod;
        }
        
        uint256 blockCountAtPeriod = upperBlockNumber - supplyAtBlock[endIndex].blockNumber;
        uint256 totalSupplyAtPeriod = supplyAtBlock[endIndex].totalSupplied;
        if (totalSupplyAtPeriod != 0) {
            uint256 userShare = user.amount.mul(1e12).div(totalSupplyAtPeriod);
            sumProjectToken += userShare.mul(blockCountAtPeriod).mul(projectTokenPerBlock);
            sumIceToken += userShare.mul(blockCountAtPeriod).mul(iceTokenPerBlock);
        }
        projectTokenPending = sumProjectToken.div(1e12) + user.remainingProjectTokenReward;
        iceTokenPending = sumIceToken.div(1e12) + user.remainingIceTokenReward;
    }
    
    // View function that calculates user reward at a certain period.
    function getUserRewardPerPeriod(uint256 index, uint256 _userAmount) internal view returns (uint256 projectTokenPerPeriod, uint256 iceTokenPerPeriod) {
        uint256 blockCountAtPeriod = supplyAtBlock[index + 1].blockNumber - supplyAtBlock[index].blockNumber;
        uint256 totalSupplyAtPeriod = supplyAtBlock[index].totalSupplied;
        if (totalSupplyAtPeriod == 0) {
            return (0, 0);
        }
        
        uint256 userShare = _userAmount.mul(1e12).div(totalSupplyAtPeriod);
        projectTokenPerPeriod = userShare.mul(blockCountAtPeriod).mul(projectTokenPerBlock);
        iceTokenPerPeriod = userShare.mul(blockCountAtPeriod).mul(iceTokenPerBlock);
    }
    
    // Deposit LP tokens to PopsicleStand. If previously LPs were deposited by the user, safeRewardTransfer gets triggered for pendingReward
    function deposit(uint256 _amount) external {
        UserInfo storage user = usersInfo[msg.sender];
        uint256 blockNumber = (block.number > endBlock ? endBlock : block.number);
        if (user.amount > 0) {
            (uint256 projectTokenPendingReward, uint256 iceTokenPendingReward) = getUserReward(msg.sender, blockNumber);
            if (projectTokenPendingReward > 0) {
                user.remainingProjectTokenReward = safeRewardTransfer(projectToken, msg.sender, projectTokenPendingReward);
            }
            if (iceTokenPendingReward > 0) {
                user.remainingIceTokenReward = safeRewardTransfer(iceToken, msg.sender, iceTokenPendingReward);
            }
        }
        if (_amount > 0) {
            lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            pushToTotalSupply(lpToken.balanceOf(address(this)), blockNumber);
        }
        user.lastRewardBlock = blockNumber;
        emit Deposit(msg.sender, _amount);
    }
    
    // Withdraw LP tokens from PopsicleStand. SafeRewardTransfer gets triggered for pendingReward
    function withdraw(uint256 _amount) external {
        UserInfo storage user = usersInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not enough amount");
        uint256 blockNumber = (block.number > endBlock ? endBlock : block.number);
        (uint256 projectTokenPendingReward, uint256 iceTokenPendingReward) = getUserReward(msg.sender, blockNumber);
        if (projectTokenPendingReward > 0) {
                user.remainingProjectTokenReward = safeRewardTransfer(projectToken, msg.sender, projectTokenPendingReward);
            }
        if (iceTokenPendingReward > 0) {
            user.remainingIceTokenReward = safeRewardTransfer(iceToken, msg.sender, iceTokenPendingReward);
        }
        if(_amount > 0) {
            lpToken.safeTransfer(address(msg.sender), _amount);
            user.amount = user.amount.sub(_amount);
            pushToTotalSupply(lpToken.balanceOf(address(this)), blockNumber);
        }
        user.lastRewardBlock = blockNumber;
        emit Withdraw(msg.sender, _amount);
    }
    
    // Changes Project token reward per block. Use this function to moderate the `lockup amount`. Essentially this function changes the amount of the reward
    // which is entitled to the user for his LP staking by the time the `endBlock` is passed. However, the reward amount cannot be less than the amount of the previous token reward per block
    // Good to use just before the `endBlock` approaches.
    function changeProjectTokenPerBlock(uint _projectTokenPerBlock) external onlyOwner {
        require(_projectTokenPerBlock > projectTokenPerBlock, "Project Token: New value should be greater than last");
        projectTokenPerBlock = _projectTokenPerBlock;
    }
    
    // Changes Ice token reward per block. Use this function to moderate the `lockup amount`. Essentially this function changes the amount of the reward
    // which is entitled to the user for his LP staking by the time the `endBlock` is passed. However, the reward amount cannot be less than the amount of the previous token reward per block
    // Good to use just before the `endBlock` approaches.
    function changeIcePerBlock(uint _iceTokenPerBlock) external onlyOwner {
        require(_iceTokenPerBlock > iceTokenPerBlock, "ICE Token: New value should be greater than last");
        iceTokenPerBlock = _iceTokenPerBlock;
    }
    
    // Safe token distribution
    function safeRewardTransfer(IERC20 rewardToken, address _to, uint256 _amount) internal returns(uint256) {
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        if (rewardTokenBalance == 0) { //save some gas fee
            return _amount;
        }
        if (_amount > rewardTokenBalance) { //save some gas fee
            rewardToken.transfer(_to, rewardTokenBalance);
            return _amount - rewardTokenBalance;
        }
        rewardToken.transfer(_to, _amount);
        return 0;
    }
    
    // Saves state changes of contract
    function pushToTotalSupply(uint256 _totalSupply, uint256 blockNumber) internal {
        
        if (supplyAtBlock.length == 0) {
            supplyAtBlock.push(Supplies({blockNumber: blockNumber, totalSupplied: _totalSupply}));
        }
        else {
            uint256 index = supplyAtBlock.length -1;
            if (supplyAtBlock[index].blockNumber == blockNumber) {
                supplyAtBlock[index].totalSupplied = _totalSupply;
            }
            else {
                supplyAtBlock.push(Supplies({blockNumber: blockNumber, totalSupplied: _totalSupply}));
            }
        }
    }
    
    // In a case when there are some Project tokens left on a contract this function allows the contract owner to retrieve excess tokens
    function retrieveExcessProjectTokens(uint256 _amount)external onlyOwner returns (uint256){
        return safeRewardTransfer(projectToken, msg.sender, _amount);
    }
    
    // In a case when there are some Ice tokens left on a contract this function allows the contract owner to retrieve excess tokens
    function retrieveExcessIceTokens(uint256 _amount)external onlyOwner returns (uint256){
        return safeRewardTransfer(iceToken, msg.sender, _amount);
    }
    
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findElementIndex(uint256 element) internal view returns (uint256) {
        if (supplyAtBlock.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = supplyAtBlock.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (supplyAtBlock[mid].blockNumber > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && supplyAtBlock[low - 1].blockNumber == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}