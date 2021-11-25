/**
 *Submitted for verification at snowtrace.io on 2021-11-25
*/

/**
 *Submitted for verification at snowtrace.io on 2021-11-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IRewarder {
    function onPefiReward(uint256 pid, address user, address recipient, uint256 pefiAmount, uint256 newShareAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 pefiAmount) external view returns (IERC20[] memory, uint256[] memory);
}

interface IIglooMaster {
    function totalShares(uint256 pid) external view returns (uint256);
}

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
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html
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
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html
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

contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Rewarder_MasterChef_Style is IRewarder, Ownable {
    using SafeERC20 for IERC20;

    /// @notice Info of each user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of rewardToken entitled to the user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    address public immutable rewardToken; // Address of token contract for rewards
    address public immutable iglooMaster; // Address of Igloo Master
    uint256 public immutable PID; // Pool ID in iglooMaster
    uint256 private constant ACC_TOKEN_PRECISION = 1e18;
    uint256 public totalShares; // Total amount of shares in the pool
    uint256 public accRewardPerShare; // Accumulated reward tokens per share, times ACC_TOKEN_PRECISION. See below.
    uint256 public tokensPerSecond; // Reward tokens to distribute per second
    uint256 public totalRewardAmount; // Total amount of reward tokens to distribute all time
    uint256 public rewardDistributed; // Amount of reward tokens distributed to this pool so far
    uint256 public lastRewardTimestamp; // Timestamp of last block that reward token distribution took place.
    address public constant AVAX = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; //placeholder address for native token (AVAX)

    mapping (address => UserInfo) public userInfo;

    event LogOnReward(address indexed user, address indexed to,  uint256 amount);
    event RewardRateUpdated(uint256 oldRate, uint256 newRate);

    modifier onlyIglooMaster {
        require(
            msg.sender == iglooMaster,
            "Only iglooMaster can call this function."
        );
        _;
    }

    constructor (address _rewardToken, address _iglooMaster, uint256 _PID, uint256 _tokensPerSecond, uint256 _rewardStartTimestamp) {
        require(_rewardStartTimestamp > block.timestamp, "rewards must start in future");
        rewardToken = _rewardToken;
        iglooMaster = _iglooMaster;
        PID = _PID;
        tokensPerSecond = _tokensPerSecond;
        emit RewardRateUpdated(0, _tokensPerSecond);
        lastRewardTimestamp = _rewardStartTimestamp;
    }

    //VIEW FUNCTIONS
    function pendingTokens(uint256, address user, uint256)
        override external view
        returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts) {
        IERC20[] memory _rewardTokens = new IERC20[](1);
        _rewardTokens[0] = IERC20(rewardToken);
        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = pendingReward(user);
        return (_rewardTokens, _rewardAmounts);
    }

    function pendingReward(address _user) public view returns(uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShareLocal = accRewardPerShare;
        uint256 amountRemainingToDistribute = rewardsRemaining();
        if (block.timestamp > lastRewardTimestamp && totalShares != 0 && amountRemainingToDistribute > 0) {
            uint256 multiplier = (block.timestamp - lastRewardTimestamp);
            uint256 amountReward = multiplier * tokensPerSecond;
            if (amountReward > amountRemainingToDistribute) {
                amountReward = amountRemainingToDistribute;
            }
            accRewardPerShareLocal += (amountReward * ACC_TOKEN_PRECISION) / totalShares;
        }
        uint256 pending = ((user.amount * accRewardPerShareLocal) / ACC_TOKEN_PRECISION) - user.rewardDebt;
        return pending;
    }

    function rewardsRemaining() public view returns(uint256) {
        uint256 amountRemainingToDistribute = totalRewardAmount - rewardDistributed;
        return amountRemainingToDistribute;
    }

    function distributionTimeRemaining() public view returns(uint256) {
        uint256 amountRemainingToDistribute = rewardsRemaining();
        return amountRemainingToDistribute / tokensPerSecond;
    }

    //EXTERNAL FUNCTIONS
    //simple function to receive AVAX transfers
    receive() external payable {}

    //IGLOO MASTER-ONLY FUNCTIONS
    function onPefiReward(
            uint256,
            address sender,
            address recipient,
            uint256,
            uint256 newShareAmount
        ) onlyIglooMaster override external {
        _updatePool();
        UserInfo storage user = userInfo[sender];
        if (user.amount > 0) {
            uint256 pending = ((user.amount * accRewardPerShare) / ACC_TOKEN_PRECISION) - user.rewardDebt;
            if (pending > 0) {
                _safeRewardTokenTransfer(rewardToken, recipient, pending);
                emit LogOnReward(sender, recipient, pending);
            }
        }
        totalShares -= user.amount;
        user.amount = newShareAmount;
        totalShares += newShareAmount;
        user.rewardDebt = (newShareAmount * accRewardPerShare) / ACC_TOKEN_PRECISION;
    }

    //OWNER-ONLY FUNCTIONS
    function updateRewardStart(uint256 _rewardStartTimestamp) external onlyOwner {
        require(_rewardStartTimestamp > block.timestamp, "rewards must start in future");
        lastRewardTimestamp = _rewardStartTimestamp;
    }

    function updateRewardRate(uint256 _tokensPerSecond) external onlyOwner {
        emit RewardRateUpdated(tokensPerSecond, _tokensPerSecond);
        tokensPerSecond = _tokensPerSecond;
    }

    function updateTotalRewardAmount(uint256 _totalRewardAmount) external onlyOwner {
        require(_totalRewardAmount >= rewardDistributed, "invalid decrease of totalRewardAmount");
        totalRewardAmount = _totalRewardAmount;
    }

    function recoverFunds(address token, address dest, uint256 amount) external onlyOwner {
        _safeRewardTokenTransfer(token, dest, amount);
    }

    //INTERNAL FUNCTIONS
    // Update reward variables to be up-to-date.
    function _updatePool() internal {
        if (block.timestamp <= lastRewardTimestamp) {
            return;
        }
        if (totalShares == 0 || tokensPerSecond == 0 || rewardDistributed == totalRewardAmount) {
            lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 multiplier = (block.timestamp - lastRewardTimestamp);
        uint256 amountReward = multiplier * tokensPerSecond;
        uint256 amountRemainingToDistribute = rewardsRemaining();
        if (amountReward > amountRemainingToDistribute) {
            amountReward = amountRemainingToDistribute;
        }
        rewardDistributed += amountReward;
        accRewardPerShare += (amountReward * ACC_TOKEN_PRECISION) / totalShares;
        lastRewardTimestamp = block.timestamp;
    }

    //internal wrapper function to avoid reverts due to rounding
    function _safeRewardTokenTransfer(address token, address user, uint256 amount) internal {
        if (token == AVAX) {
            uint256 avaxBalance = address(this).balance;
            if (amount > avaxBalance) {
                payable(user).transfer(avaxBalance);
            } else {
                payable(user).transfer(amount);
            }
        } else {
            IERC20 coin = IERC20(token);
            uint256 coinBal = coin.balanceOf(address(this));
            if (amount > coinBal) {
                coin.safeTransfer(user, coinBal);
            } else {
                coin.safeTransfer(user, amount);
            }            
        }
    }

    function _checkBalance(address token) internal view returns (uint256) {
        if (token == AVAX) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }
}