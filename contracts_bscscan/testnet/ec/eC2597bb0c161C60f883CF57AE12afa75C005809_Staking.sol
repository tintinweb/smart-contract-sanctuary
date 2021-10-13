/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// File: openzeppelin-solidity\contracts\GSN\Context.sol

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

// File: node_modules\openzeppelin-solidity\contracts\token\ERC20\IERC20.sol

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

// File: node_modules\openzeppelin-solidity\contracts\math\SafeMath.sol

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

// File: node_modules\openzeppelin-solidity\contracts\utils\Address.sol

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

// File: openzeppelin-solidity\contracts\token\ERC20\SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;




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

// File: contracts\crowdsale\upgredableERC20Crowdsale\Initializable.sol

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
contract Initializable {

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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// File: contracts\utils\TimestampConvertor.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

library TimestampConvertor {
    
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    int constant OFFSET19700101 = 2440588;
    
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }
    
    function testDate() public view returns(uint year, uint month, uint day){
        return timestampToDate(block.timestamp);
    }
    
}

// File: contracts\staking\IStaking.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;


interface IStaking {
    function deposit(address _beneficiary,uint256 _pid, uint256 _amount) external;
}

// File: contracts\crowdsale\upgredableERC20Crowdsale\IStakableCrowdsale.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IStakableCrowdsale{
    function buyTokensAndStake(address _beneficiary, uint256 _weiAmount,uint256 _pid) external;
}

// File: contracts\staking\Staking.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;







contract Staking is Context , Initializable, IStaking {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using TimestampConvertor for uint256;

    address private _owner;

    uint public _claim_opened_from_day;
    uint public _claim_opened_to_day;

    bool public _withdraw_authorized;

    

    event ClaimOpenedFromDay(uint oldValue,uint newValue);
    event ClaimOpenedToDay(uint oldValue,uint newValue);

    event WithdrawAuthorized(bool oldValue,bool newValue);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    struct UserInfo {
        uint256 amount;
        uint256 cumulativeRewards;
        uint256 cumulativeRewardsBlock;
        uint256 totalClaimed;
    }

    struct PoolInfo {
        IERC20 stakedToken;
        IERC20 rewardCoin;
        IStakableCrowdsale crowdsaleContract;
        uint256 totalStaked;
        uint256 rewardRatePerBlock;
        uint256 totalClaimed;
    }

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Deposit(address indexed user,address indexed beneficiary, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);
    event CompoundClaim(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(uint claim_opened_from_day,uint claim_opened_to_day) public {
        address msgSender = _msgSender();
        _owner = msgSender;
        _claim_opened_from_day = claim_opened_from_day;
        _claim_opened_to_day = claim_opened_to_day;
        _withdraw_authorized = false;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function initialize(uint claim_opened_from_day,uint claim_opened_to_day) external initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        _claim_opened_from_day = claim_opened_from_day;
        _claim_opened_to_day = claim_opened_to_day;
        _withdraw_authorized = false;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to.sub(_from);
    }

    function add(
        IERC20 _stakedToken,
        IERC20 _rewardCoin,
        IStakableCrowdsale _crowdsaleContract,
        uint256 _rewardRatePerBlock
    ) public onlyOwner {
        poolInfo.push(
            PoolInfo({
                stakedToken: _stakedToken,
                rewardCoin: _rewardCoin,
                crowdsaleContract: _crowdsaleContract,
                rewardRatePerBlock: _rewardRatePerBlock,
                totalStaked: 0,
                totalClaimed: 0
            })
        );
    }

    function set(
        uint256 _pid,
        IERC20 _stakedToken,
        IERC20 _rewardCoin,
        IStakableCrowdsale _crowdsaleContract,
        uint256 _rewardRatePerBlock
    ) public onlyOwner {
        poolInfo[_pid].stakedToken = _stakedToken;
        poolInfo[_pid].rewardCoin = _rewardCoin;
        poolInfo[_pid].crowdsaleContract = _crowdsaleContract;
        poolInfo[_pid].rewardRatePerBlock = _rewardRatePerBlock;
    }

    function pendingRewardCoin(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        return _pendingRewardCoin(_pid,_user);
    }

    function _pendingRewardCoin(uint256 _pid, address _user)
        internal
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_pid][_user];
        PoolInfo storage pool = poolInfo[_pid];
        uint256 multiplier = getMultiplier(user.cumulativeRewardsBlock, block.number);
        uint256 reward = user
        .amount
        .mul(pool.rewardRatePerBlock)
        .mul(multiplier)
        .div(10**24);
        return user.cumulativeRewards.add(reward);
    }

    function deposit(address _beneficiary,uint256 _pid, uint256 _amount) override external {
        _deposit(_beneficiary, _pid, _amount);
    }

    function _deposit(address _beneficiary,uint256 _pid, uint256 _amount) internal {
        require(_amount > 0, "Staking contract: amount should be > 0");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_beneficiary];

        if (user.amount > 0) {
            uint256 multiplier = getMultiplier(
                user.cumulativeRewardsBlock,
                block.number
            );
            uint256 reward = user
            .amount
            .mul(pool.rewardRatePerBlock)
            .mul(multiplier)
            .div(10**24);
            user.cumulativeRewards = user.cumulativeRewards.add(reward);
        }

        pool.stakedToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);

        pool.totalStaked = pool.totalStaked.add(_amount);

        user.cumulativeRewardsBlock = block.number;
        emit Deposit(msg.sender,_beneficiary, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        require(_withdraw_authorized,"Withdraw is not authorized");
        require(_amount > 0, "Staking contract: amount should be > 0");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        uint256 multiplier = getMultiplier(user.cumulativeRewardsBlock, block.number);
        uint256 reward = user
        .amount
        .mul(pool.rewardRatePerBlock)
        .mul(multiplier)
        .div(10**24);
        user.cumulativeRewards = user.cumulativeRewards.add(reward);

        user.amount = user.amount.sub(_amount);
        pool.stakedToken.safeTransfer(address(msg.sender), _amount);

        pool.totalStaked = pool.totalStaked.sub(_amount);

        user.cumulativeRewardsBlock = block.number;

        emit Withdraw(msg.sender, _pid, _amount);
    }


    function claim(uint256 _pid) public {
        (, ,uint today) = block.timestamp.timestampToDate();
        require(today >= _claim_opened_from_day && today <= _claim_opened_to_day,"Staking contract: claim not authorized");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 rewardValue = _pendingRewardCoin(_pid, msg.sender);
        if (rewardValue > 0) {
            safeRewardCoinTransfer(_pid,msg.sender, rewardValue);
            user.totalClaimed = user.totalClaimed.add(rewardValue);
            pool.totalClaimed = pool.totalClaimed.add(rewardValue);
            user.cumulativeRewards = 0;
            user.cumulativeRewardsBlock = block.number;
            emit Claim(msg.sender, _pid, rewardValue);
        }
    }

    function compoundClaim(uint256 _pid) public {
        (, ,uint today) = block.timestamp.timestampToDate();
        require(today >= _claim_opened_from_day && today <= _claim_opened_to_day,"Staking contract: claim not authorized");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 rewardValue = _pendingRewardCoin(_pid, msg.sender);
        if (rewardValue > 0) {
            pool.rewardCoin.approve(address(pool.crowdsaleContract), rewardValue);
            pool.crowdsaleContract.buyTokensAndStake(msg.sender,rewardValue,_pid);
            user.totalClaimed = user.totalClaimed.add(rewardValue);
            pool.totalClaimed = pool.totalClaimed.add(rewardValue);
            user.cumulativeRewards = 0;
            user.cumulativeRewardsBlock = block.number;
            emit CompoundClaim(msg.sender, _pid, rewardValue);
        }
    }

    function safeRewardCoinTransfer(
        uint256 _pid,
        address _to,
        uint256 _amount
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 rewardCoinBal = pool.rewardCoin.balanceOf(address(this));
        if (_amount > rewardCoinBal) {
            pool.rewardCoin.transfer(_to, rewardCoinBal);
        } else {
            pool.rewardCoin.transfer(_to, _amount);
        }
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function setClaimOpenedFromDay(uint claim_opened_from_day) public onlyOwner {
        emit ClaimOpenedFromDay(_claim_opened_from_day,claim_opened_from_day);
        _claim_opened_from_day = claim_opened_from_day;
    }
    function setClaimOpenedToDay(uint claim_opened_to_day) public onlyOwner {
        emit ClaimOpenedFromDay(_claim_opened_to_day,claim_opened_to_day);
        _claim_opened_to_day = claim_opened_to_day;
    }
    function setWithdrawAuthorized(bool withdraw_authorized) public onlyOwner {
        emit WithdrawAuthorized(_withdraw_authorized,withdraw_authorized);
        _withdraw_authorized = withdraw_authorized;
    }


    function userTotalRewards(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        return _userTotalRewards(_pid,_user);
    }

    function _userTotalRewards(uint256 _pid, address _user)
        internal
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_pid][_user];
        PoolInfo storage pool = poolInfo[_pid];
        uint256 multiplier = getMultiplier(user.cumulativeRewardsBlock, block.number);
        uint256 reward = user
        .amount
        .mul(pool.rewardRatePerBlock)
        .mul(multiplier)
        .div(10**24);
        return user.cumulativeRewards.add(reward).add(user.totalClaimed);
    }
}