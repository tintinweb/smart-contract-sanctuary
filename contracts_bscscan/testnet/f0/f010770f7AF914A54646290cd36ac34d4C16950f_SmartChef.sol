/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-24
*/

//SPDX-License-Identifier: UNLICENSED


pragma solidity 0.6.12;

//import "@nomiclabs/buidler/console.sol";





pragma solidity >=0.4.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



pragma solidity >=0.4.0;

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
    constructor() internal {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity >=0.4.0;

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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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




pragma solidity ^0.6.0;

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
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
        assembly {
            codehash := extcodehash(account)
        }
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

pragma solidity >=0.6.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}


contract SmartChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that CAKEs distribution occurs.
        uint256 accCakePerShare; // Accumulated CAKEs per share, times 1e12. See below.
    }

    // The CAKE TOKEN!
    IBEP20 public syrup;
    IBEP20 public rewardToken;
    
    // used for random algorithm
    AggregatorInterface public oracleBNB;
    AggregatorInterface public oracleETHBNB;
    AggregatorInterface public oracleCAKEUSD;
    AggregatorInterface public oracleADABNB;
    // uint256 public maxStaking;

    // CAKE tokens created per block.
    uint256 public rewardPerBlock;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 private totalAllocPoint = 0;
    // to be ignored 
    uint256 public startBlock;
    // to be ignored 
    uint256 public bonusEndBlock;
    
    // when addresses over 10k holders 
    bool public tenThousandPerraholders = false;
    
    address[] public holdersAmount; 

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        IBEP20 _syrup,
        IBEP20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        syrup = _syrup;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        // oracleBNB = AggregatorInterface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE); // get oracle for BNB data
        // oracleETHBNB = AggregatorInterface(0x63D407F32Aa72E63C7209ce1c2F5dA40b3AaE726); // get oracle for ETHBNB data
        // oracleCAKEUSD = AggregatorInterface(0xB6064eD41d4f67e353768aA239cA86f4F73665a1); // get oracle for CAKE USD 
        // oracleADABNB = AggregatorInterface(0x2d5Fc41d1365fFe13d03d91E82e04Ca878D69f4B); // get oracle for ADA BNB 
        oracleBNB = AggregatorInterface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526); // get oracle for BNB data
        oracleETHBNB = AggregatorInterface(0x0630521aC362bc7A19a4eE44b57cE72Ea34AD01c); // get oracle for ETHBNB data
        oracleCAKEUSD = AggregatorInterface(0x81faeDDfeBc2F8Ac524327d70Cf913001732224C); // get oracle for CAKE USD 
        oracleADABNB = AggregatorInterface(0x1a602D4928faF0A153A520f58B332f9CAFF320f7); // get oracle for ADA BNB 

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _syrup,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accCakePerShare: 0
        }));

        totalAllocPoint = 1000;
        // maxStaking = 50000000000000000000;

    }

    function stopReward() public onlyOwner {
        bonusEndBlock = block.number;
    }
    
    
    function changeHolderStatus(bool _status) public onlyOwner {
        tenThousandPerraholders = _status;
    }


    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accCakePerShare = pool.accCakePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 cakeReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCakePerShare = accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accCakePerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 cakeReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accCakePerShare = pool.accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    // Stake SYRUP tokens to SmartChef
    function deposit(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        require(_amount >= 10 ether, "minimum 10 perra stake");
        require(tenThousandPerraholders == false, '10k already reached');
        // require (_amount.add(user.amount) <= maxStaking, 'exceed max stake');

        updatePool(0);
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            // for each 10 PERRA, 1 entry 
            uint256 entries = _amount.div(10000000000000000000);
            for(uint i=0; i< entries; i++){
                holdersAmount.push(msg.sender);
            }
        }
        emit Deposit(msg.sender, _amount);
    }
    
    
    address public winnerFistPrize;
    uint256 public firstA =  300000000000000000000000; // 300k PERRA
    address public winnerSecondPrize;
    uint256 public secondA = 150000000000000000000000; // 150k PERRA
    address public winnerThirdPrize;
    uint256 public thirdA =  100000000000000000000000; // 100k PERRA
    address public winnerFourthPrize;
    uint256 public fourthA =  50000000000000000000000; // 50k PERRA
    address public winnerFifthPrize;
    uint256 public fifthA =   30000000000000000000000; // 30k PERRA
    address public winnerSixtPrize;
    uint256 public sixthA =   20000000000000000000000; // 20k PERRA
    address public winnerSeventhPrize;
    uint256 public seventhA = 10000000000000000000000; // 10k PERRA
    address public winnerEightPrize;
    uint256 public eightA =    5000000000000000000000; // 5k PERRA
    address public winnerNinethPrize;
    uint256 public ninthA =    3000000000000000000000; // 3k PERRA
    address public winnerTenthPrize;
    uint256 public tenthA =    2000000000000000000000; // 2k PERRA
    
    
    address[] public otherWinners; 
    
    function withdrawZwinners() public onlyOwner{
        require(tenThousandPerraholders == true, '10k already reached');
        require(otherWinners.length < 660);
        uint myN;
        uint256 layer1 = randomNumber();
        // double layer random algorithm, L1 low difficulty, L2 exponentially higher with random oracles
        if(layer1 % 2 == 0){
        myN = randomSelector(uint256(oracleETHBNB.latestAnswer()), uint256(oracleBNB.latestAnswer()));
        } else {
        myN = randomSelector(uint256(oracleADABNB.latestAnswer()), uint256(oracleCAKEUSD.latestAnswer()));
        }
        uint256 playerLen = holdersAmount.length;
        uint randomnumber = uint(keccak256(abi.encodePacked(myN, msg.sender, now))) % playerLen;
        if(playerLen.sub(randomnumber) > 60){
            for(uint i=0; i<60; i++ ){
                otherWinners.push(holdersAmount[randomnumber.add(i)]);
            }
        } else {
            for(uint i=0; i<60; i++ ){
                otherWinners.push(holdersAmount[randomnumber.sub(i)]);
            }
        }
    }
    
    
    
    // withdraws winners for first, second, third... tenth prize
    // distributing
    // 300k, 150k, 100k, 50k, 30k, 20k, 10k, 5k, 3k, 2k PERRA 
    function withdrawPrize() public onlyOwner{
        require(tenThousandPerraholders == true, '10k already reached');
        uint myN;
        uint256 layer1 = randomNumber();
        // double layer random algorithm, L1 low difficulty, L2 exponentially higher with random oracles
        if(layer1 % 2 == 0){
        myN = randomSelector(uint256(oracleETHBNB.latestAnswer()), uint256(oracleBNB.latestAnswer()));
        } else {
        myN = randomSelector(uint256(oracleADABNB.latestAnswer()), uint256(oracleCAKEUSD.latestAnswer()));
        }
        
        // get round players lenght
        uint256 playerLen = holdersAmount.length;
        uint randomnumber = uint(keccak256(abi.encodePacked(myN, msg.sender, now))) % playerLen;
        if(playerLen.sub(randomnumber) > 10){
            winnerFistPrize = holdersAmount[randomnumber]; 
            rewardToken.safeTransfer(winnerFistPrize, firstA);
            
            winnerSecondPrize = holdersAmount[randomnumber.add(1)];
            rewardToken.safeTransfer(winnerSecondPrize, secondA);
            
            winnerThirdPrize = holdersAmount[randomnumber.add(2)];
            rewardToken.safeTransfer(winnerThirdPrize, thirdA);
            
            winnerFourthPrize = holdersAmount[randomnumber.add(3)];
            rewardToken.safeTransfer(winnerFourthPrize, fourthA);
            
            winnerFifthPrize = holdersAmount[randomnumber.add(4)];
            rewardToken.safeTransfer(winnerFifthPrize, fifthA);
            
            winnerSixtPrize = holdersAmount[randomnumber.add(5)];
            rewardToken.safeTransfer(winnerSixtPrize, sixthA);
            
            winnerSeventhPrize = holdersAmount[randomnumber.add(6)];
            rewardToken.safeTransfer(winnerSeventhPrize, seventhA);
            
            winnerEightPrize = holdersAmount[randomnumber.add(7)];
            rewardToken.safeTransfer(winnerEightPrize, eightA);
            
            winnerNinethPrize = holdersAmount[randomnumber.add(8)];
            rewardToken.safeTransfer(winnerNinethPrize, ninthA);
            
            winnerTenthPrize = holdersAmount[randomnumber.add(9)];
            rewardToken.safeTransfer(winnerTenthPrize, tenthA);
        } else {
            winnerFistPrize = holdersAmount[randomnumber]; 
            rewardToken.safeTransfer(winnerFistPrize, firstA);
            
            winnerSecondPrize = holdersAmount[randomnumber.sub(1)];
            rewardToken.safeTransfer(winnerSecondPrize, secondA);
            
            winnerThirdPrize = holdersAmount[randomnumber.sub(2)];
            rewardToken.safeTransfer(winnerThirdPrize, thirdA);
            
            winnerFourthPrize = holdersAmount[randomnumber.sub(3)];
            rewardToken.safeTransfer(winnerFourthPrize, fourthA);
            
            winnerFifthPrize = holdersAmount[randomnumber.sub(4)];
            rewardToken.safeTransfer(winnerFifthPrize, fifthA);
            
            winnerSixtPrize = holdersAmount[randomnumber.sub(5)];
            rewardToken.safeTransfer(winnerSixtPrize, sixthA);
            
            winnerSeventhPrize = holdersAmount[randomnumber.sub(6)];
            rewardToken.safeTransfer(winnerSeventhPrize, seventhA);
            
            winnerEightPrize = holdersAmount[randomnumber.sub(7)];
            rewardToken.safeTransfer(winnerEightPrize, eightA);
            
            winnerNinethPrize = holdersAmount[randomnumber.sub(8)];
            rewardToken.safeTransfer(winnerNinethPrize, ninthA);
            
            winnerTenthPrize = holdersAmount[randomnumber.sub(9)];
            rewardToken.safeTransfer(winnerTenthPrize, tenthA);
        }

    }

    
        function randomSelector (uint256 _externalRandomNumber, uint256 _secondN) internal returns(uint256){
        
        // let's waste some gas here
        for (uint i = 0; i < 10; i++) {
            wasteGas(i);
        }
        bytes32 _structHash;
        uint256 theGasLeft = gasleft();
        bytes32 _blockhash = blockhash(block.number-1);

        // 1
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                0,
                theGasLeft,
                _externalRandomNumber,
                _secondN
            )
        );
    uint256 _randomNumber  = uint256(_structHash);
    return _randomNumber;
}   

function wasteGas(uint _par) internal returns (uint256) {
    uint someRandomData = uint(keccak256(abi.encodePacked(block.difficulty, now, _par)));
    if (someRandomData % 2 == 0){
        return someRandomData;
    }  else {
        return someRandomData*block.difficulty/now;
    }
}



    // redundant 
    function withdraw(uint256 _amount) public {
        
        require(1 == 2, "ignore function");
        emit Withdraw(msg.sender, _amount);
    }
    
    
    function randomNumber() private view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, now)));
    } 
    
    

    // Withdraw reward by OWNER (IF ANY)
    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
        require(_amount < rewardToken.balanceOf(address(this)), 'not enough token');
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }
    
    function emergencySyrupWithdraw(uint256 _amount) public onlyOwner{
        require(_amount < syrup.balanceOf(address(this)), 'not enough tokens');
        syrup.safeTransfer(address(msg.sender), _amount);
    }
    
    

}