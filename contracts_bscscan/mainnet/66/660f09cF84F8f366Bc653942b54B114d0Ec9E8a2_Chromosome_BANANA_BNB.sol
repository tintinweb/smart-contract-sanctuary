/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 *       $$$$$$_$$__$$__$$$$__$$$$$$
 *       ____$$_$$__$$_$$_______$$
 *       ____$$_$$__$$__$$$$____$$
 *       $$__$$_$$__$$_____$$___$$
 *       _$$$$___$$$$___$$$$____$$
 *
 *       $$__$$_$$$$$$_$$$$$__$$_____$$$$$
 *       _$$$$____$$___$$_____$$_____$$__$$
 *       __$$_____$$___$$$$___$$_____$$__$$
 *       __$$_____$$___$$_____$$_____$$__$$
 *       __$$___$$$$$$_$$$$$__$$$$$$_$$$$$
 *
 *       $$___$_$$$$$$_$$$$$$_$$__$$
 *       $$___$___$$_____$$___$$__$$
 *       $$_$_$___$$_____$$___$$$$$$
 *       $$$$$$___$$_____$$___$$__$$
 *       _$$_$$_$$$$$$___$$___$$__$$
 *
 *       $$__$$_$$$$$__$$
 *       _$$$$__$$_____$$
 *       __$$___$$$$___$$
 *       __$$___$$_____$$
 *       __$$___$$$$$__$$$$$$
 */


library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'math add overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'math sub underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'math mul overflow');
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance.sub(value);
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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
contract OwnableData {
    address public owner;
    address public pendingOwner;
}

abstract contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        owner = 0x4e5b3043FEB9f939448e2F791a66C4EA65A315a8;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {

            require(newOwner != address(0) || renounce, "Ownable: zero address");

            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        } else {
            pendingOwner = newOwner;
        }
    }

    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }
}


// Implemented to call functions of farmContract
interface IFarmContract {
    function deposit(uint256 pid, uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function pendingCake(uint256 pid, address user) external view returns(uint);
}


/**
 * This contract is responsible for forwarding LP tokens to farmContract contract.
 * It calculates YEL rewards and distrubutes both YEL and Token rewards
 */
contract Chromosome_BANANA_BNB is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Immutable Address of reward token
    IERC20 public immutable rewardToken;
    // Immutable farmContract address
    IFarmContract public immutable farmContract;
    IERC20 public immutable lpToken;
    IERC20 public immutable yel;
    uint256 public immutable pid; // rewardToken pool id
    uint256 public totalLP; // how many LP tokens in this SC
    uint256 public yelPerSecond = 100000000000000000; // 0.1 YEL per second
    // Set of variables that is storing user token rewards
    uint256 private rewardTokenPerLPTokenStored;
    uint256 private yelPerShare;
    uint256 public lastRewardTime; // Last timestamp number that YEL distribution occurs.

    // Info of each user.
    struct UserInfo {
        uint256 remainingYelTokenReward; // YEL Tokens that weren't distributed for user
        uint256 rewardTokenPerLPTokenPaid;
        uint256 tokenRewards;
        uint256 amount; // how many LP tokens the user own
        uint256 rewardDebt;
        // the start date for making proper YEL rewarding related to YEL per second
        uint256 startClaimedYEL;
    }

    // Info of each user that stakes YEL tokens.
    mapping(address => UserInfo) public userInfo;

    event Staked(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event YelPaid(address indexed user, uint256 reward);
    event RewardTokenPaid(address indexed user, uint256 reward);
    event YelDebug(address indexed user, uint256 reward, uint256 data);

    constructor(
        address _yel,
        address _rewardToken,
        address _lpToken,
        address _farmContract,
        uint256 _pid
    ) {
        require(
           _rewardToken != address(0) && _farmContract != address(0),
           "rewardToken and farmContract addresses can not be zero addresses"
        );
        rewardToken = IERC20(_rewardToken);
        farmContract = IFarmContract(_farmContract);
        pid = _pid;
        lpToken = IERC20(_lpToken);
        yel = IERC20(_yel);
    }

    /*
    stake visibility is public as overriding LPTokenWrapper's stake() function
    Recieves users LP tokens and deposits them to farmContract
    */
    function stake(uint256 amount) public {
        require(amount > 0, "Cannot stake 0");
        UserInfo storage user = userInfo[msg.sender];
        uint256 currentBalanceLP = user.amount;
        _updateYelCoef(msg.sender);
        // if the user already staked some LPs, the smart contract should just save the amount of YEL
        if (currentBalanceLP != 0) {
            // if the user already staked some LPs it means he has yels already
            uint256 pending =
                user.amount
                .mul(yelPerShare)
                .div(1e12)
                .sub(user.rewardDebt)
                .add(user.remainingYelTokenReward);
            user.remainingYelTokenReward = safeRewardTransfer(msg.sender, pending);
        }
        // start time of YEL rewording is when the user calls this function
        user.startClaimedYEL = block.timestamp;
        updateReward(msg.sender);
        // increase the total amount of LP that staked on this smart contract
        _stake(amount);
        user.rewardDebt = user.amount.mul(yelPerShare).div(1e12);

        // approve for farmContract from SC to use the amount of LP tokens
        lpToken.approve(address(farmContract), amount);

        // deposits LP tokens from this SC to farmContract contract
        farmContract.deposit(pid, amount);
    }

    // Recieves Lp tokens from farmContract and give it out to the user
    function withdraw(uint256 amount) public {
        require(amount > 0, "Cannot withdraw 0");
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= amount, "Current balance of LP should be less or equal then 'amount'");
        _payYels(msg.sender);
        updateReward(msg.sender);
        // withdraw LP from the farmContract to this SC
        farmContract.withdraw(pid, amount);
        _payRewardToken(msg.sender);
        // withdraw LP from this SC to the msg.sender
        _withdraw(amount);
        user.rewardDebt = user.amount.mul(yelPerShare).div(1e12);
    }

    // Harvests rewardToken rewards to the user but leaves the Lp tokens deposited
    function getReward() public {
        _payYels(msg.sender);
        updateReward(msg.sender);
        _payRewardToken(msg.sender);
        UserInfo storage user = userInfo[msg.sender];
        user.rewardDebt = user.amount.mul(yelPerShare).div(1e12);
    }

    // "Go home" function which withdraws all Funds and distributes all rewards to the user
    function exit() external {
        address sender = msg.sender;
        UserInfo storage user = userInfo[sender];
        _payYels(sender);
        uint256 totalAmountRewardToken = rewardToken.balanceOf(address(this));
        uint256 amountLP = user.amount; 
        require(amountLP > 0, "The balance of LP tokens is 0");

        // withdraw all LP from the farmContract to this SC
        farmContract.withdraw(pid, amountLP);

        // as we get all tokens to this SC we should separate tokens for each LP token
        rewardTokenPerLPTokenStored = _rewardTokenPerLPToken(rewardToken.balanceOf(address(this)).sub(totalAmountRewardToken));
        // how much token rewards are entitled for a user
        user.tokenRewards = _rewardTokenEarned(sender, rewardTokenPerLPTokenStored);
        user.rewardTokenPerLPTokenPaid = rewardTokenPerLPTokenStored;

        // withdraw all rewardToken for the sender
        _payRewardToken(sender);
        // withdraw all yels for the sender
        // withdraw all LP from this SC to the msg.sender
        _withdraw(amountLP);
        user.rewardDebt = 0;
    }

    // View function which shows user Yel reward for displayment on frontend
    function pendingYel(address account) public view returns (uint256) {
        UserInfo memory user = userInfo[account];
        uint256 _yelPerShare = yelPerShare;
        if (block.timestamp > lastRewardTime && totalLP != 0) {
            uint256 multiplier = _getMultiplier(lastRewardTime, block.timestamp, user.startClaimedYEL);
            uint256 yelReward = multiplier.mul(yelPerSecond);
            _yelPerShare = yelReward.mul(1e12).div(totalLP).add(_yelPerShare);
        }
        return user.amount.mul(_yelPerShare).div(1e12).sub(user.rewardDebt).add(user.remainingYelTokenReward);
    }

    // View function which shows user token reward for displayment on frontend
    function pendingRewardTokens(address account) public view returns (uint256) {
        return _rewardTokenEarned(account, rewardTokenPerLPToken());
    }

    // Changes YEL per secons parameter
    function setYelPerSecond(uint256 _yelPerSecond,  bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            _updateYelCoef(address(0));
        }
        yelPerSecond = _yelPerSecond;
    }

    // To transfer all YEL rewards we should accumulate YELs and use remainingYelTokenReward
    // IMPORTANT: needs to have YEL tokens on this smart contract
    function _payYels(address account) internal {
        _updateYelCoef(account);
        UserInfo storage user = userInfo[account];
        uint256 pending = user.amount
            .mul(yelPerShare)
            .div(1e12)
            .sub(user.rewardDebt)
            .add(user.remainingYelTokenReward);

        if (pending > 0)
        {
            // yel safe distribution from this SC to the msg.sender
            user.remainingYelTokenReward = safeRewardTransfer(account, pending);
            user.startClaimedYEL = block.timestamp;
            emit YelPaid(account, pending);
        }
    }

    function updateReward(address account) internal {
        UserInfo storage user = userInfo[account];
        uint totalAmoutRewardToken = rewardToken.balanceOf(address(this));
        farmContract.withdraw(pid, 0);
        rewardTokenPerLPTokenStored = _rewardTokenPerLPToken(rewardToken.balanceOf(address(this)).sub(totalAmoutRewardToken));

        if (account != address(0)) {
            user.tokenRewards = _rewardTokenEarned(account, rewardTokenPerLPTokenStored);
            user.rewardTokenPerLPTokenPaid = rewardTokenPerLPTokenStored;
        }
    }

    function _stake(uint256 amount) internal {
        UserInfo storage user = userInfo[msg.sender];
        totalLP = totalLP.add(amount);
        user.amount = user.amount.add(amount);
        lpToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    // Function that is reponsible for releasing LP tokens 
    // to the user and for the update of the user balance 
    function _withdraw(uint256 amount) internal {
        UserInfo storage user = userInfo[msg.sender];
        totalLP = totalLP.sub(amount);
        user.amount = user.amount.sub(amount);
        lpToken.safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updateYelCoef(address account) internal {
        uint256 startClaimedYEL = block.timestamp;
        if(account != address(0)) {
            UserInfo memory user = userInfo[account];
            startClaimedYEL = user.startClaimedYEL;
        }

        require(
            block.timestamp > lastRewardTime,
            "Block timestamp is less than last reward time"
        );

        if (totalLP != 0) {
            uint256 multiplier = _getMultiplier(lastRewardTime, block.timestamp, startClaimedYEL);
            uint256 yelReward = multiplier.mul(yelPerSecond);
            yelPerShare = yelReward.mul(1e12).div(totalLP).add(yelPerShare);
        }
        lastRewardTime = block.timestamp;
    }

    function _payRewardToken(address account) internal {
        UserInfo storage user = userInfo[account];
        uint256 tokenRewards = user.tokenRewards;
        if (tokenRewards > 0) {
            rewardToken.safeTransfer(account, tokenRewards); // token rewards transfer to the msg.sender
            user.tokenRewards = 0;
            emit RewardTokenPaid(account, tokenRewards);
        }
    }

    // returns token rewards amount of our Pool 
    function rewardTokenPerLPToken() internal view returns (uint256) {
        return _rewardTokenPerLPToken(farmContract.pendingCake(pid, address(this)));
    }

    // Safe token distribution
    function safeRewardTransfer(address _to, uint256 _amount) internal returns(uint256) {
        uint256 rewardTokenBalance = yel.balanceOf(address(this));
        if (rewardTokenBalance == 0) {
            return _amount;
        }
        if (_amount > rewardTokenBalance) {
            yel.transfer(_to, rewardTokenBalance);
            return _amount.sub(rewardTokenBalance);
        }
        yel.transfer(_to, _amount);
        return 0;
    }

    // Calculates how much rewardToken is provied per LP token
    function _rewardTokenPerLPToken(uint earned_) internal view returns (uint256) {
        if (totalLP > 0) {
            return rewardTokenPerLPTokenStored.add((earned_ * 1e12).div(totalLP));
        }
        return rewardTokenPerLPTokenStored;
    }

    // Return reward multiplier over the given _from to _to time.
    function _getMultiplier(uint256 _from, uint256 _to, uint256 startTime) internal pure returns (uint256) {
        _from = _from > startTime ? _from : startTime;
        if ( _to < startTime) {
            return 0;
        }
        return _to.sub(_from);
    }

    // Calculates how much rewardToken is entitled for a particular user
    function _rewardTokenEarned(address account, uint256 rewardTokenPerLPToken_) internal view returns (uint256) {
        UserInfo memory user = userInfo[account];
        return (user.amount)
            .mul(rewardTokenPerLPToken_.sub(user.rewardTokenPerLPTokenPaid))
            .div(1e12)
            .add(user.tokenRewards);
    }
}