/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: MIT

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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
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
library SafeERC20 {
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

contract StorageBuffer {

    // Reserved storage space to allow for layout changes in the future.
    uint256[20] private _gap;

    function getStore(uint a) internal view returns(uint) {
        require(a < 20, "Not allowed");
        return _gap[a];
    }

    function setStore(uint a, uint val) internal {
        require(a < 20, "Not allowed");
        _gap[a] = val;
    }
}

// This contract is dedicated to process LP tokens of the users. More precisely, this allows Popsicle to track how much tokens
// the user has deposited and indicate how much he is eligible to withdraw 
abstract contract LPTokenWrapper is StorageBuffer {
    using SafeERC20 for IERC20;

// Address of ICE token
    IERC20 public immutable ice;
    // Address of LP token
    IERC20 public immutable lpToken;

// Amount of Lp tokens deposited
    uint256 private _totalSupply;
    // A place where user token balance is stored
    mapping(address => uint256) private _balances;

// Function modifier that calls update reward function
    modifier updateReward(address account) {
        _updateReward(account);
        _;
    }

    constructor(address _ice, address _lpToken) {
        require(_ice != address(0) && _lpToken != address(0), "NULL_ADDRESS");
        ice = IERC20(_ice);
        lpToken = IERC20(_lpToken);
    }
// View function that provides tptal supply for the front end 
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
// View function that provides the LP balance of a user
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
// Fuction that is responsible for the recival of  LP tokens of the user and the update of the user balance 
    function stake(uint256 amount) virtual public {
        _totalSupply += amount;
        _balances[msg.sender] += amount;
        lpToken.safeTransferFrom(msg.sender, address(this), amount);
    }
// Function that is reponsible for releasing LP tokens to the user and for the update of the user balance 
    function withdraw(uint256 amount) virtual public {
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        lpToken.safeTransfer(msg.sender, amount);
    }

//Interface 
    function _updateReward(address account) virtual internal;
}

/**
 * This contract is responsible fpr forwarding LP tokens to Masterchef contract.
 * It calculates ICE rewards and distrubutes both ICE and Sushi
 */
contract PopsicleJointStaking is LPTokenWrapper, Ownable {
    using SafeERC20 for IERC20;
    // Immutable Address of Sushi token
    IERC20 public immutable sushi;
    // Immutable masterchef contract address
    IMasterChef public immutable masterChef;
    uint256 public immutable pid; // sushi pool id

// Reward rate - This is done to set ICE reward rate proportion. 
    uint256 public rewardRate = 2000000;
// Custom divisioner that is implemented in order to give the ability to alter rate reward according to the project needs
    uint256 public constant DIVISIONER = 10 ** 6;

// Set of variables that is storing user Sushi rewards
    uint256 public sushiPerTokenStored;
    // Info of each user.
    struct UserInfo {
        uint256 remainingIceTokenReward; // Remaining Token amount that is owned to the user.
        uint256 sushiPerTokenPaid;
        uint256 sushiRewards;
    }
    
    // Info of each user that stakes ICE tokens.
    mapping(address => UserInfo) public userInfo;
    //mapping(address => uint256) public sushiPerTokenPaid;
    //mapping(address => uint256) public sushiRewards;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event SushiPaid(address indexed user, uint256 reward);

    constructor(
        address _ice,
        address _sushi,
        address _lpToken,
        address _masterChef,
        uint256 _pid
    )
        LPTokenWrapper(_ice, _lpToken)
    {
        require(
           _sushi != address(0) && _masterChef != address(0),
           "NULL_ADDRESSES"
        );
        sushi = IERC20(_sushi);
        masterChef = IMasterChef(_masterChef);
        pid = _pid;
    }
// Function which tracks rewards of a user and harvests all sushi rewards from Masterchef
    function _updateReward(address account) override internal {
        UserInfo storage user = userInfo[msg.sender];
        uint _then = sushi.balanceOf(address(this));
        masterChef.withdraw(pid, 0); // harvests sushi
        sushiPerTokenStored = _sushiPerToken(sushi.balanceOf(address(this)) - _then);

        if (account != address(0)) {
            user.sushiRewards = _sushiEarned(account, sushiPerTokenStored);
            user.sushiPerTokenPaid = sushiPerTokenStored;
        }
    }

// View function which shows sushi rewards amount of our Pool 
    function sushiPerToken() public view returns (uint256) {
        return _sushiPerToken(masterChef.pendingSushi(pid, address(this)));
    }
// Calculates how much sushi is provied per LP token 
    function _sushiPerToken(uint earned_) internal view returns (uint256) {
        uint _totalSupply = totalSupply();
        if (_totalSupply > 0) {
            return sushiPerTokenStored + earned_ * 1e18 / _totalSupply;
        }
        return sushiPerTokenStored;
    }
// View function which shows user ICE reward for displayment on frontend
    function earned(address account) public view returns (uint256) {
        UserInfo memory user = userInfo[account];
        return _sushiEarned(account, sushiPerToken()) * rewardRate / DIVISIONER + user.remainingIceTokenReward;
    }
// View function which shows user Sushi reward for displayment on frontend
    function sushiEarned(address account) public view returns (uint256) {
        return _sushiEarned(account, sushiPerToken());
    }
// Calculates how much sushi is entitled for a particular user
    function _sushiEarned(address account, uint256 sushiPerToken_) internal view returns (uint256) {
        UserInfo memory user = userInfo[account];
        return
            balanceOf(account) * (sushiPerToken_ - user.sushiPerTokenPaid) / 1e18 + user.sushiRewards;
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    //Recieves users LP tokens and deposits them to Masterchef contract
    function stake(uint256 amount) override public updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        lpToken.approve(address(masterChef), amount);
        masterChef.deposit(pid, amount);
        emit Staked(msg.sender, amount);
    }
// Recieves Lp tokens from Masterchef and give it out to the user
    function withdraw(uint256 amount) override public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        masterChef.withdraw(pid, amount); // harvests sushi
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    // "Go home" function which withdraws all Funds and distributes all rewards to the user
    function exit() external {
        require(msg.sender != address(0));
        
        UserInfo storage user = userInfo[msg.sender];
        uint _then = sushi.balanceOf(address(this));
        uint256 amount = balanceOf(msg.sender);
        require(amount > 0, "Cannot withdraw 0");
        
        masterChef.withdraw(pid, amount); // harvests sushi
        sushiPerTokenStored = _sushiPerToken(sushi.balanceOf(address(this)) - _then);
        
        user.sushiRewards = _sushiEarned(msg.sender, sushiPerTokenStored);
        user.sushiPerTokenPaid = sushiPerTokenStored;
        
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
        
        uint256 reward = user.sushiRewards;
        if (reward > 0) {
            user.sushiRewards = 0;
            sushi.safeTransfer(msg.sender, reward);
            emit SushiPaid(msg.sender, reward);
        }
        reward = reward * rewardRate / DIVISIONER + user.remainingIceTokenReward;
        if (reward > 0)
        {
            user.remainingIceTokenReward = safeRewardTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
        
    }
    // Changes rewards rate of ICE token
    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }
// Harvests rewards to the user but leaves the Lp tokens deposited
    function getReward() public updateReward(msg.sender) {
        UserInfo storage user = userInfo[msg.sender];
        uint256 reward = user.sushiRewards;
        if (reward > 0) {
            user.sushiRewards = 0;
            sushi.safeTransfer(msg.sender, reward);
            emit SushiPaid(msg.sender, reward);
        }
        reward = reward * rewardRate / DIVISIONER + user.remainingIceTokenReward;
        if (reward > 0)
        {
            user.remainingIceTokenReward = safeRewardTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }
    
    // Safe token distribution
    function safeRewardTransfer(address _to, uint256 _amount) internal returns(uint256) {
        uint256 rewardTokenBalance = ice.balanceOf(address(this));
        if (rewardTokenBalance == 0) { //save some gas fee
            return _amount;
        }
        if (_amount > rewardTokenBalance) { //save some gas fee
            ice.transfer(_to, rewardTokenBalance);
            return _amount - rewardTokenBalance;
        }
        ice.transfer(_to, _amount);
        return 0;
    }
}
// Implemented to call functions of masterChef
interface IMasterChef {
    function deposit(uint256 pid, uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function pendingSushi(uint256 pid, address user) external view returns(uint);
}