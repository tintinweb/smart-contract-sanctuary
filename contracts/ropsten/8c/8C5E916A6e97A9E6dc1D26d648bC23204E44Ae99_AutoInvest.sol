/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface IXSPStaking {
    struct Percentage {
        uint256 timestamp;
        uint256 percentPerMonth;
        uint256 percentPerSecond;
    }

    struct Staker {
        uint256 timestamp;
        uint256 amount;
    }

    // public write -----

    // gets value and checks current total staked amount. if more than available to stake then returns back
    function stake(uint256 amount) external returns (uint256 timestamp);

    // dont forget to unpause if its needed
    function unstake(bool reinvestReward) external returns (uint256 timestamp);

    function claimReward() external returns (uint256 claimedAmount, uint256 timestamp);

    function reinvest() external returns (uint256 reinvestedAmount, uint256 timestamp);

    // public view -----
    function claimableReward() external view returns (uint256 reward); //with internal function for reuse in claimReward() and reinvest()

    function percentagePerMonth() external view returns (uint256[] memory, uint256[] memory);


    // for owner
    // pausing staking. unstake is available.
    function pauseStacking(uint256 startTime) external returns (bool); // if 0 => block.timestamp
    function unpauseStacking() external returns (bool);

    // pausing staking, unstaking and sets 0 percent from current time
    function pauseGlobally(uint256 startTime) external returns (bool); // if 0 => block.timestamp
    function unpauseGlobally() external returns (bool);

    function updateMaxTotalAmountToStake(uint256 amount) external returns (uint256 updatedAmount);
    function updateMinAmountToStake(uint256 amount) external returns (uint256 updatedAmount);

    // if 0 => block.timestamp
    function addPercentagePerMonth(uint256 timestamp, uint256 percent) external returns (uint256 index); // require(timestamp > block.timestamp);
    function updatePercentagePerMonth(uint256 timestamp, uint256 percent, uint256 index) external returns (bool);

    function removeLastPercentagePerMonth() external returns (uint256 index);

    event Stake(address account, uint256 stakedAmount);
    event Unstake(address account, uint256 unstakedAmount, bool withReward);
    event ClaimReward(address account, uint256 claimedAmount);
    event Reinvest(address account, uint256 reinvestedAmount, uint256 totalInvested);
    event MaxStakeAmountReached(address account, uint256 changeAmount);

    event StakingPause(uint256 startTime);
    event StakingUnpause(); // check with empty args

    event GlobalPause(uint256 startTime);
    event GlobalUnpause();

    event MaxTotalStakeAmountUpdate(uint256 updateAmount);
    event MinStakeAmountUpdate(uint256 updateAmount);
    event AddPercentagePerMonth(uint256 percent, uint256 index);
    event UpdatePercentagePerMonth(uint256 percent, uint256 index);
    event RemovePercentagePerMonth(uint256 index);
}

contract AutoInvest is Ownable {
    using SafeERC20 for IERC20;

    IXSPStaking public mainContract = IXSPStaking(0x0FDF853774aB1561722E9fF7f6814C4b41bC8A31);


    mapping(address => uint256) public stakers;
    uint256 public totalStaked;
    uint256 public totalPending;
    uint256 private undestributedReward;
    uint256 public minAmountToStake = 3 * 10 ** 6 * 10 ** 18;

    bool public depositsEnabled = true;
    bool public withdrawalsEnabled = false;


    IERC20 public token =  IERC20(0x2Dd9FfF70fDa675291aac6dBef4A27bF1B4735bB);

    address public managerAddress;
    uint256 public withdrawFeePercent = 50;
    uint256 public harvestFeePercent = 10;
    uint256 public denominator = 1000;
    // fee = 50/1000 = 5%
    event StakeSuccessfull(uint256 amount);
    event WithdrawalSuccessfull(uint256 amount);
    event Harvest(uint256 amount);

    modifier onlyManager {
        require(msg.sender == owner() || msg.sender == managerAddress);
        _;
    }

    constructor() {
        token.safeApprove(address(mainContract), ~uint256(0));
    }

    function deposit(uint256 _amount) external {
        require(depositsEnabled);
        token.safeTransferFrom(msg.sender, address(this), _amount);
        totalPending += _amount;

        if (totalPending >= minAmountToStake || totalStaked >= minAmountToStake) {
            mainContract.stake(totalPending);
            totalStaked += totalPending;
            totalPending = 0;
            emit StakeSuccessfull(totalPending);
        }
        stakers[msg.sender] += _amount;
    }

    function isRunning() external view returns(bool) {
        return totalStaked >= minAmountToStake;
    }

    function withdraw() external {
        require(withdrawalsEnabled);
        require(stakers[msg.sender] > 0, "Nothing to unstake");
        harvest();
        uint256 amount = stakers[msg.sender];

        uint256 balanceBefore;
        uint256 balanceAfter;
        if (totalStaked > 0) {
            balanceBefore = token.balanceOf(address(this));
            mainContract.unstake(false);
            balanceAfter = token.balanceOf(address(this));
            totalPending = balanceAfter - balanceBefore - amount;
            totalStaked = 0;
        } else {
            totalPending -= amount;
        }
        _stake();
        
        uint256 fee = amount * withdrawFeePercent / denominator;
        amount -= fee;
        stakers[msg.sender] = 0;
        token.safeTransfer(msg.sender, amount);
        token.safeTransfer(managerAddress, fee);
        emit WithdrawalSuccessfull(amount);
    }

    function _stake() internal {
        if (totalPending >= minAmountToStake) {
            mainContract.stake(totalPending);
            totalStaked += totalPending;
            totalPending = 0;
        }
    }

    function getMyRewardAmount(address _address) public view returns (uint256) {
        if (stakers[_address] == 0) { // If not participated in staking
            return 0; 
        }
        if (totalStaked == 0) { // if the contract has not yet staked anything
            return 0;
        } else {
            uint256 totalReward = mainContract.claimableReward();
            uint256 stakeShare = stakers[_address] * 10**18 / totalStaked;
            return totalReward * stakeShare / 10**18;
        }
    }

    function _rewardAmount(address _address, uint256 _totalReward) internal view returns (uint256) {
        if (totalStaked == 0) {
            return 0;
        } else {
            uint256 stakeShare = stakers[_address] * 10**18 / totalStaked;
            return _totalReward * stakeShare / 10**18;
        }
    }

    function harvest() public {
        require(stakers[msg.sender] > 0);
        (uint256 claimed, ) = mainContract.claimReward();
        undestributedReward += claimed;
        uint256 userReward = _rewardAmount(msg.sender, undestributedReward);
        undestributedReward -= userReward;
        uint256 fee = userReward * harvestFeePercent / denominator;
        userReward -= fee;
        token.safeTransfer(msg.sender, userReward);
        token.safeTransfer(managerAddress, fee);
    }

    function changeWithdrawFee(uint256 _newFee) external onlyManager {
        withdrawFeePercent = _newFee;
    }

    function changeHarvestFee(uint256 _newFee) external onlyManager {
        harvestFeePercent = _newFee;
    }

    function changeManagerAddress(address _newAddress) external onlyManager {
        managerAddress = _newAddress;
    }

    function depositStatus(bool _value) external onlyOwner {
        depositsEnabled = _value;
    }

    function withdrawalStatus(bool _value) external onlyOwner {
        withdrawalsEnabled = _value;
    }

    function withdrawStuckTokens(IERC20 _token, uint256 _amount) external onlyManager {
        _token.safeTransfer(msg.sender, _amount);
    }
}