// SPDX-License-Identifier: GPL-3.0-or-later

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import '../GSN/Context.sol';

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0-or-later

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "./libs/ReentrancyGuard.sol";
import './libs/AddrArrayLib.sol';
import './libs/IFarm.sol';
import "./Token.sol";

contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    using AddrArrayLib for AddrArrayLib.Addresses;
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastDepositTime;
        uint256 rewardLockedUp;
        uint256 nextHarvestUntil;
    }

    struct PoolInfo {
        IBEP20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
        uint16 taxWithdraw;
        uint16 taxWithdrawBeforeLock;
        uint256 withdrawLockPeriod;
        uint256 lock;
        uint16 depositFee;
        uint256 cake_pid;
        uint16 harvestFee;
    }

    Token public immutable token;
    address payable public devaddr;
    address payable public taxLpAddress;
    uint16 public reserveFee = 901;
    uint16 public devFee = 1500;
    uint256 totalLockedUpRewards;

    uint256 public constant MAX_PERFORMANCE_FEE = 1500; // 15%
    uint256 public constant MAX_CALL_FEE = 100; // 1%
    uint256 public performanceFee = 1500; // 15%
    uint256 public callFee = 1; // 0.01%
    // 0: stake it, 1: send to reserve address
    uint256 public harvestProcessProfitMode = 0;
    event Earn(address indexed sender, uint256 pid, uint256 balance, uint256 performanceFee, uint256 callFee);

    uint256 public tokenPerBlock;
    uint256 public bonusMultiplier = 1;

    PoolInfo[] public poolInfo;
    uint256[] public poolsList;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => AddrArrayLib.Addresses) private addressByPid;
    mapping(uint256 => uint[]) public userPoolByPid;

    mapping(address => bool) private _authorizedCaller;
    mapping(uint256 => uint256) public deposits;
    uint256 public totalAllocPoint = 0;
    uint256 public immutable startBlock;
    address payable public reserveAddress; // receive farmed asset
    address payable public taxAddress; // receive fees

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 received);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawWithTax(address indexed user, uint256 indexed pid, uint256 sent, uint256 burned);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Transfer(address indexed to, uint256 requsted, uint256 sent);
    event TokenPerBlockUpdated(uint256 tokenPerBlock);
    event UpdateEmissionSettings(address indexed from, uint256 depositAmount, uint256 endBlock);
    event UpdateMultiplier(uint256 multiplierNumber);
    event SetDev(address indexed prevDev, address indexed newDev);
    event SetTaxAddr(address indexed prevAddr, address indexed newAddr);
    event SetReserveAddr(address indexed prevAddr, address indexed newAddr);
    event SetAuthorizedCaller(address indexed caller, bool _status);
    modifier validatePoolByPid(uint256 _pid) {
        require(_pid < poolInfo.length, "pool id not exisit");
        _;
    }
    IFarm public mc;
    IBEP20 public cake;

    uint256 totalProfit; // hold total asset generated by this vault

    constructor(
        Token _token,
        address payable _devaddr,
        address payable _reserveAddress,
        uint256 _tokenPerBlock,
        uint256 _startBlock,
        address _mc, address _cake
    ) public {
        token = _token;
        devaddr = _devaddr;
        taxLpAddress = _devaddr;
        reserveAddress = _reserveAddress;
        taxAddress = _reserveAddress;
        tokenPerBlock = _tokenPerBlock;
        startBlock = _startBlock;
        reflectSetup(_mc, _cake);
    }

    function updateTokenPerBlock(uint256 _tokenPerBlock) external onlyOwner {
        tokenPerBlock = _tokenPerBlock;
        emit TokenPerBlockUpdated(_tokenPerBlock);
    }

    function updateMultiplier(uint256 multiplierNumber) external onlyOwner {
        bonusMultiplier = multiplierNumber;
        emit UpdateMultiplier(multiplierNumber);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(
        uint256 _allocPoint,
        address _lpToken,
        uint16 _taxWithdraw,
        uint16 _taxWithdrawBeforeLock,
        uint256 _withdrawLockPeriod,
        uint256 _lock,
        uint16 _depositFee,
        bool _withUpdate,
        uint256 _cake_pid,
        uint16 _harvestFee
    ) external onlyOwner {
        require(_depositFee <= 1000, "err1");
        require(_taxWithdraw <= 1000, "err2");
        require(_taxWithdrawBeforeLock <= 2500, "err3");
        require(_withdrawLockPeriod <= 30 days, "err4");

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
        block.number > startBlock ? block.number : startBlock;

        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo(
            {
            lpToken : IBEP20(_lpToken),
            allocPoint : _allocPoint,
            lastRewardBlock : lastRewardBlock,
            accTokenPerShare : 0,
            taxWithdraw : _taxWithdraw,
            taxWithdrawBeforeLock : _taxWithdrawBeforeLock,
            withdrawLockPeriod : _withdrawLockPeriod,
            lock : _lock,
            depositFee : _depositFee,
            cake_pid : _cake_pid,
            harvestFee: _harvestFee
            })
        );

        poolsList.push(poolInfo.length);

        if (_cake_pid > 0) {
            require(_lpToken == getLpOf(_cake_pid), "src/lp!=dst/lp");
            IBEP20(_lpToken).safeApprove(address(mc), 0);
            IBEP20(_lpToken).safeApprove(address(mc), uint256(- 1));
        }

    }
    function set_locks(uint256 _pid,
        uint16 _taxWithdraw,
        uint16 _taxWithdrawBeforeLock,
        uint256 _withdrawLockPeriod,
        uint256 _lock,
        uint16 _depositFee,
        uint16 _harvestFee) external onlyOwner validatePoolByPid(_pid) {
        require(_depositFee <= 1000, "err1");
        require(_taxWithdraw <= 1000, "err2");
        require(_taxWithdrawBeforeLock <= 2500, "err3");
        require(_withdrawLockPeriod <= 30 days, "err4");
        poolInfo[_pid].taxWithdraw = _taxWithdraw;
        poolInfo[_pid].taxWithdrawBeforeLock = _taxWithdrawBeforeLock;
        poolInfo[_pid].withdrawLockPeriod = _withdrawLockPeriod;
        poolInfo[_pid].lock = _lock;
        poolInfo[_pid].depositFee = _depositFee;
        poolInfo[_pid].harvestFee = _harvestFee;
    }
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate,
        uint256 _cake_pid
    ) external onlyOwner validatePoolByPid(_pid) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(
                _allocPoint
            );
        }
        IBEP20 lp = poolInfo[_pid].lpToken;
        if (_cake_pid > 0 && poolInfo[_pid].cake_pid == 0) {
            require(address(lp) == getLpOf(_cake_pid), "src/lp!=dst/lp");
            lp.safeApprove(address(mc), 0);
            lp.safeApprove(address(mc), uint256(- 1));
            mc.deposit(_cake_pid,  lp.balanceOf(address(this)) );
        } else if (_cake_pid == 0 && poolInfo[_pid].cake_pid > 0) {
            uint256 amount = balanceOf(_pid);
            if (amount > 0)
                mc.withdraw(poolInfo[_pid].cake_pid, amount);
            lp.safeApprove(address(mc), 0);
        }
        poolInfo[_pid].cake_pid = _cake_pid;
    }

    function getMultiplier(uint256 _from, uint256 _to)
    public
    view
    returns (uint256)
    {
        return _to.sub(_from).mul(bonusMultiplier);
    }

    function pendingReward(uint256 _pid, address _user)
    public
    view
    validatePoolByPid(_pid)
    returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = deposits[_pid];
        uint256 tokenPendingReward;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accTokenPerShare = accTokenPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        }
        tokenPendingReward = user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
        return tokenPendingReward.add(user.rewardLockedUp);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
        harvestAll();
    }

    function updatePool(uint256 _pid) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = deposits[_pid];
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        uint256 fee = tokenReward.mul(reserveFee).div(10000); // 9.1%
        token.mint(devaddr, fee);
        token.mint(address(this), tokenReward);
        pool.accTokenPerShare = pool.accTokenPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }
    function deposit(uint256 _pid, uint256 _amount) external {
        depositFor(msg.sender, _pid, _amount);
    }
    function depositFor(address recipient, uint256 _pid, uint256 _amount)
    public validatePoolByPid(_pid) nonReentrant notContract notBlacklisted {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][recipient];
        updatePool(_pid);
        _payRewardByPid(_pid, recipient);
        if (_amount > 0) {
            if (pool.depositFee > 0) {
                uint256 tax = _amount.mul(pool.depositFee).div(10000);
                uint256 received = _amount.sub(tax);
                pool.lpToken.safeTransferFrom(address(msg.sender), taxAddress, tax);
                uint256 oldBalance = pool.lpToken.balanceOf(address(this));
                pool.lpToken.safeTransferFrom(address(msg.sender), address(this), received);
                uint256 newBalance = pool.lpToken.balanceOf(address(this));
                received = newBalance.sub(oldBalance);
                deposits[_pid] = deposits[_pid].add(received);
                user.amount = user.amount.add(received);
                userPool(_pid, recipient);
                emit Deposit(recipient, _pid, _amount, received);
                if (pool.cake_pid > 0){
                    mc.deposit(pool.cake_pid, received);
                }
            } else {
                uint256 oldBalance = pool.lpToken.balanceOf(address(this));
                pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
                uint256 newBalance = pool.lpToken.balanceOf(address(this));
                _amount = newBalance.sub(oldBalance);
                deposits[_pid] = deposits[_pid].add(_amount);
                user.amount = user.amount.add(_amount);
                userPool(_pid, recipient);
                emit Deposit(recipient, _pid, _amount);
                if (pool.cake_pid > 0){
                    mc.deposit(pool.cake_pid, _amount);
                }
            }
            user.lastDepositTime = block.timestamp;
            if( user.nextHarvestUntil == 0 && pool.lock > 0 ){
                user.nextHarvestUntil = block.timestamp.add(pool.lock);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        // _harvestAll();
    }


    event withdrawTax( uint256 tax );
    function withdraw(uint256 _pid, uint256 _amount) external validatePoolByPid(_pid)
    nonReentrant notContract {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.amount >= _amount && pool.cake_pid > 0 ) {
            mc.withdraw(pool.cake_pid, _amount);
        }
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        _payRewardByPid(_pid, msg.sender);
        if (_amount > 0) {
            if (pool.withdrawLockPeriod > 0 ) {
                uint256 tax = 0;
                if(block.timestamp < user.lastDepositTime + pool.withdrawLockPeriod) {
                    if( pool.taxWithdrawBeforeLock > 0 ){
                        tax = _amount.mul(pool.taxWithdrawBeforeLock).div(10000);
                    }
                }else{
                    if( pool.taxWithdraw > 0 ){
                        tax = _amount.mul(pool.taxWithdraw).div(10000);
                    }
                }
                if( tax > 0 ){
                    deposits[_pid] = deposits[_pid].sub(tax);
                    user.amount = user.amount.sub(tax);
                    _amount = _amount.sub(tax);
                    pool.lpToken.safeTransfer(taxLpAddress, tax );
                    emit withdrawTax(tax);
                }
            }
            _withdraw(_pid, _amount);
        }
        // _harvestAll();
    }

    function _withdraw( uint256 _pid, uint256 _amount ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        deposits[_pid] = deposits[_pid].sub(_amount);
        user.amount = user.amount.sub(_amount);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
    }

    function emergencyWithdraw(uint256 _pid) external validatePoolByPid(_pid) nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        reflectEmergencyWithdraw(_pid, user.amount);
        deposits[_pid] = deposits[_pid].sub(user.amount);
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        deposits[_pid] = deposits[_pid].sub(user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        userPool(_pid, msg.sender);
    }

    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 balance = token.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > balance) {
            transferSuccess = token.transfer(_to, balance);
        } else {
            transferSuccess = token.transfer(_to, _amount);
        }
        emit Transfer(_to, _amount, balance);
        require(transferSuccess, "SAFE TOKEN TRANSFER FAILED");
    }

    function setMultiplier(uint256 val) external onlyAdmin {
        bonusMultiplier = val;
    }
    function dev(address payable _devaddr) external onlyAdmin {
        emit SetDev(devaddr, _devaddr);
        devaddr = _devaddr;
    }
    function setReserveFee(uint16 val) external onlyAdmin {
        reserveFee = val;
    }
    function setDevFee(uint16 val) external onlyAdmin {
        devFee = val;
    }

    function adminSetReserveAddr(address payable _addr) external onlyAdmin {
        emit SetReserveAddr(reserveAddress, _addr);
        reserveAddress = _addr;
    }

    function adminSetTaxLpAddress(address payable _addr) external onlyAdmin {
        taxLpAddress = _addr;
    }

    function adminSetTaxAddr(address payable _addr) external onlyAdmin {
        emit SetTaxAddr(taxAddress, _addr);
        taxAddress = _addr;
    }

    function getTotalPoolUsers(uint256 _pid) external virtual view returns (uint256) {
        return addressByPid[_pid].getAllAddresses().length;
    }

    function getAllPoolUsers(uint256 _pid) public virtual view returns (address[] memory) {
        return addressByPid[_pid].getAllAddresses();
    }

    function userPoolBalances(uint256 _pid) external virtual view returns (UserInfo[] memory) {
        address[] memory list = getAllPoolUsers(_pid);
        UserInfo[] memory balances = new UserInfo[](list.length);
        for (uint i = 0; i < list.length; i++) {
            address addr = list[i];
            balances[i] = userInfo[_pid][addr];
        }
        return balances;
    }

    function userPool(uint256 _pid, address _user) internal {
        AddrArrayLib.Addresses storage addresses = addressByPid[_pid];
        uint256 amount = userInfo[_pid][_user].amount;
        if (amount > 0) {
            addresses.pushAddress(_user);
        } else if (amount == 0) {
            addresses.removeAddress(_user);
        }
    }

    function adminSetTokenTaxAddr(address payable _taxTo) external onlyAdmin {
        token.setTaxAddr(_taxTo);
    }

    function adminSetTax(uint16 _tax) external onlyAdmin {
        token.setTax(_tax);
    }

    function adminSetWhiteList(address _addr, bool _status) external onlyAdmin {
        token.setWhiteList(_addr, _status);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyAdmin {
        token.setSwapAndLiquifyEnabled(_enabled);
    }

    function reflectSetup(address _mc, address _cake) internal {
        mc = IFarm(_mc);
        cake = IBEP20(_cake);
        cake.safeApprove(_mc, 0);
        cake.safeApprove(_mc, uint256(- 1));
    }

    function setPerformanceFee(uint256 _performanceFee) external onlyAdmin {
        require(_performanceFee <= MAX_PERFORMANCE_FEE, "performanceFee cannot be more than MAX_PERFORMANCE_FEE");
        performanceFee = _performanceFee;
    }

    function setCallFee(uint256 _callFee) external onlyAdmin {
        require(_callFee <= MAX_CALL_FEE, "callFee cannot be more than MAX_CALL_FEE");
        callFee = _callFee;
    }

    function setHarvestProcessProfitMode(uint16 mode) external onlyAdmin {
        harvestProcessProfitMode = mode;
    }

    function getLpOf(uint256 pid) public view returns (address) {
        (address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accCakePerShare) = mc.poolInfo(pid);
        return lpToken;
    }
    function balanceOf(uint256 pid) public view returns (uint256) {
        (uint256 amount,) = mc.userInfo(pid, address(this));
        return amount;
    }

    function pendingCake(uint256 pid) public view returns (uint256) {
        return mc.pendingCake(pid, address(this));

    }

    function calculateHarvestRewards(uint256 pid) external view returns (uint256) {
        return pendingCake(pid).mul(callFee).div(10000);
    }

    mapping(address => bool) public contractAllowed;
    mapping(address => bool) public blacklist;
    modifier notContract() {
        if (contractAllowed[msg.sender] == false) {
            require(!_isContract(msg.sender), "CnA");
            require(msg.sender == tx.origin, "PCnA");
        }
        _;
    }
    modifier notBlacklisted() {
        require(blacklist[msg.sender] == false, "BLK");
        _;
    }
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function setContractAllowed(bool status) external onlyAdmin {
        contractAllowed[msg.sender] = status;
    }

    function setBlaclisted(address addr, bool status) external onlyAdmin {
        blacklist[addr] = status;
    }

    function reflectHarvest(uint256 pid) internal {
        if( balanceOf(pid) == 0 || pid == 0 ){
            return;
        }
        mc.deposit(pid, 0);
        harvestProcessProfit(pid);
    }

    event EnterStaking(uint256 amount);
    event TransferToReserve(address to, uint256 amount);
    function harvestProcessProfit( uint256 pid) internal{
        uint256 balance = cake.balanceOf(address(this));
        totalProfit = totalProfit.add(balance);
        if( balance > 0 ){
            uint256 currentPerformanceFee = balance.mul(performanceFee).div(10000);
            uint256 currentCallFee = balance.mul(callFee).div(10000);
            cake.safeTransfer(devaddr, currentPerformanceFee);
            cake.safeTransfer(msg.sender, currentCallFee);
            uint256 reserveAmount = cake.balanceOf(address(this));
            emit Earn(msg.sender, pid, balance, currentPerformanceFee, currentCallFee);
            if( reserveAmount > 0 ){
                if( harvestProcessProfitMode == 0 ){
                    mc.enterStaking(reserveAmount);
                    emit EnterStaking(reserveAmount);
                }else{
                    cake.safeTransfer(reserveAddress, reserveAmount);
                    emit TransferToReserve(reserveAddress, reserveAmount);
                }
            }
        }
    }

    function adminProcessReserve() external onlyAdmin {
        uint256 reserveAmount = balanceOf(0);
        if( reserveAmount > 0 ){
            mc.leaveStaking(reserveAmount);
            cake.safeTransfer(reserveAddress, reserveAmount);
        }
    }

    function harvestAll() public nonReentrant {
        _harvestAll();
    }

    function _harvestAll() internal {
        for (uint256 i = 0; i < poolsList.length; ++i) {
            uint256 pid = poolsList[i];
            if( pid == 0 ){
                continue;
            }
            reflectHarvest(pid);
        }
    }

    function inCaseTokensGetStuck(address _token, address to) external onlyAdmin {
        require(_token != address(cake), "!cake");
        require(_token != address(token), "!token");
        for (uint256 i = 0; i < poolsList.length; ++i) {
            uint256 pid = poolsList[i];
            require(address(poolInfo[pid].lpToken) != _token, "!pool asset");
        }
        uint256 amount = IBEP20(_token).balanceOf(address(this));
        IBEP20(token).safeTransfer(to, amount);
    }
    function reflectEmergencyWithdraw(uint256 _pid, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.cake_pid == 0) return;
        mc.withdraw(pool.cake_pid, _amount);
    }
    function adminEmergencyWithdraw(uint256 _pid) external onlyAdmin {
        mc.emergencyWithdraw(poolInfo[_pid].cake_pid);
    }
    function panicAll() external onlyAdmin {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            panic(pid);
        }
    }
    function panic( uint256 pid) public onlyAdmin {
        PoolInfo storage pool = poolInfo[pid];
        if( pool.cake_pid != 0 ){
            mc.emergencyWithdraw(pool.cake_pid);
            pool.lpToken.safeApprove(address(mc), 0);
            pool.cake_pid = 0;
        }
    }
    modifier onlyAdmin() {
        // does not manipulate user funds and allow fast actions to stop/panic withdraw
        require(msg.sender == owner() || msg.sender == devaddr, "access denied");
        _;
    }


    function payAllReward() public {
        for (uint256 i = 0; i < poolsList.length; ++i) {
            uint256 pid = poolsList[i];
            _payRewardByPid(pid, msg.sender);
        }
        _harvestAll();
    }
    function payRewardByPid( uint256 pid ) public {
        _payRewardByPid(pid, msg.sender);
        _harvestAll();
    }

    function canHarvest(uint256 pid, address recipient ) public view returns(bool){
        // PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][recipient];
        // return pool.lock == 0 || block.timestamp >= user.lastDepositTime + pool.lock;
        return block.timestamp >= user.nextHarvestUntil;
    }
    function _payRewardByPid( uint256 pid, address recipient ) public {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][recipient];
        uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
        if ( canHarvest(pid, recipient) ) {
            uint256 totalRewards = pending.add(user.rewardLockedUp);
            if (totalRewards > 0) {
                uint256 fee = 0;
                if(pool.harvestFee > 0){
                    fee = totalRewards.mul(pool.harvestFee).div(10000);
                    safeTokenTransfer(taxAddress, fee);
                }
                safeTokenTransfer(recipient, totalRewards.sub(fee));
                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp);
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(pool.lock);
            }
        }else{
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
        }
        // emit PayReward(recipient, pid, status, user.amount, pending, user.rewardDebt);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol";

import "./interfaces.sol";


contract Token is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;


    uint256 public tax;
    address payable public taxToAddrAddress;
    uint256 public constant maxTax = 100;
    mapping(address => bool) whitelist;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;

    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;

    event transferInsufficient(address indexed from, address indexed to, uint256 total, uint256 balance);
    event whitelistedTransfer(address indexed from, address indexed to, uint256 total);
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqiudity
    );
    event SetTaxAddr(address indexed taxTo);
    event SetTax(uint256 tax);
    event SetWhiteList(address indexed addr, bool status);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(address payable _taxToAddrAddress, uint256 _tax)
    public
    {
        require(_tax <= maxTax, "INVALID TAX");
        require(_taxToAddrAddress != address(0), "Zero Address");
        _name = 'SuperCake';
        _symbol = 'SPK';
        _decimals = 18;
        taxToAddrAddress = _taxToAddrAddress;
        tax = _tax;
    }

    function init_router(address router) external onlyOwner {
        require(router != address(0), "SuperCake.init_router: Zero Address");
        // TESTER: moving to a separate function to avoid breaking tests.
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        whitelist[uniswapV2Pair] = true;
    }

    function getOwner() external override view returns (address) {
        return owner();
    }
    function name() public override view returns (string memory) {
        return _name;
    }
    function decimals() external override view returns (uint8) {
        return _decimals;
    }
    function symbol() external override view returns (string memory) {
        return _symbol;
    }
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }
    function allowance(address owner, address spender) external override view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    // ----------------------------------------------------------------
    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setTaxAddr(address payable _taxToAddrAddress) external onlyOwner {
        require(_taxToAddrAddress != address(0), "SuperCake.setTaxAddr: Zero Address");
        taxToAddrAddress = _taxToAddrAddress;
        emit SetTaxAddr(_taxToAddrAddress);
    }

    function setTax(uint256 _tax) external onlyOwner {
        require(_tax <= maxTax, "INVALID TAX");
        tax = _tax;
        emit SetTax(_tax);
    }

    function setWhiteList(address _addr, bool _status) external onlyOwner {
        require(_addr != address(0), "SuperCake.setWhiteList: Zero Address");
        whitelist[_addr] = _status;
        emit SetWhiteList(_addr, _status);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (whitelist[recipient] || whitelist[msg.sender]) {
            _transfer(msg.sender, recipient, amount);
            _moveDelegates(_delegates[msg.sender], _delegates[recipient], amount);
            emit whitelistedTransfer(msg.sender, recipient, amount);
        } else {
            (uint256 _amount, uint256 _tax, uint256 _liquidity) = getTax(amount);
            if (!inSwapAndLiquify && _msgSender() != uniswapV2Pair
            && swapAndLiquifyEnabled && _liquidity > 0
            ) {
                _transfer(msg.sender, address(this), _liquidity);
                swapAndLiquify(_liquidity);
            }
            if (_tax > 0) {
                _transfer(msg.sender, taxToAddrAddress, _tax);
                _moveDelegates(_delegates[msg.sender], _delegates[taxToAddrAddress], _tax);
            }
            _transfer(msg.sender, recipient, _amount);
            _moveDelegates(_delegates[msg.sender], _delegates[recipient], _amount);
        }
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        if (whitelist[recipient] || whitelist[sender]) {
            _transfer(sender, recipient, amount);
            _moveDelegates(_delegates[sender], _delegates[recipient], amount);
            emit whitelistedTransfer(sender, recipient, amount);
        } else {
            (uint256 _amount, uint256 _tax, uint256 _liquidity) = getTax(amount);
            if (!inSwapAndLiquify && sender != uniswapV2Pair
            && swapAndLiquifyEnabled && _liquidity > 0
            ) {
                //add liquidity
                swapAndLiquify(_liquidity);
            }
            if (_tax > 0) {
                _transfer(sender, taxToAddrAddress, _tax);
                _moveDelegates(_delegates[sender], _delegates[taxToAddrAddress], _tax);
            }
            _transfer(sender, recipient, _amount);
            _moveDelegates(_delegates[sender], _delegates[recipient], _amount);
        }
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');
        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        (uint amountToken, uint amountETH, uint liquidity) = uniswapV2Router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
        require(amountToken > 0 && amountETH > 0 && liquidity > 0);
        uint256 bnbAmount = address(this).balance;
        taxToAddrAddress.call{value : bnbAmount}("");
    }
    receive() external payable {}
    function getTax(uint256 _total) private view returns (uint256 _amount, uint256 _amount_tax, uint256 _amount_liquidity){
        if (tax == 0) {
            return (_total, 0, 0);
        }
        if (tax > 0) {
            _amount_tax = _total.mul(tax).div(1000);
            _amount = _total.sub(_amount_tax);

            if (swapAndLiquifyEnabled) {
                _amount_liquidity = _amount_tax.div(2);
                _amount_tax = _amount_tax.sub(_amount_liquidity);
            }
        }
        return (_amount, _amount_tax, _amount_liquidity);
    }
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }
    mapping(address => address) internal _delegates;

    /// @dev A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @dev A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @dev The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @dev The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @dev The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @dev A record of states for signing / validating signatures
    mapping(address => uint) public nonces;

    /// @dev An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @dev An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @dev Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
    external
    view
    returns (address)
    {
        return _delegates[delegator];
    }

    /**
     * @dev Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @dev Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "CAKE::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "CAKE::delegateBySig: invalid nonce");
        require(now <= expiry, "CAKE::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @dev Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
    external
    view
    returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @dev Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
    external
    view
    returns (uint256)
    {
        require(blockNumber < block.number, "CAKE::getPriorVotes: not yet determined");

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
            uint32 center = upper - (upper - lower) / 2;
            // ceil, avoiding overflow
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

    function _delegate(address delegator, address delegatee)
    internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator);
        // balance of underlying CAKEs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
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
    )
    internal
    {
        uint32 blockNumber = safe32(block.number, "CAKE::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2 ** 32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly {chainId := chainid()}
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/*
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library AddrArrayLib {
    using AddrArrayLib for Addresses;

    struct Addresses {
        address[]  _items;
    }

    /**
     * @notice push an address to the array
     * @dev if the address already exists, it will not be added again
     * @param self Storage array containing address type variables
     * @param element the element to add in the array
     */
    function pushAddress(Addresses storage self, address element) internal {
        if (!exists(self, element)) {
            self._items.push(element);
        }
    }

    /**
     * @notice remove an address from the array
     * @dev finds the element, swaps it with the last element, and then deletes it;
     *      returns a boolean whether the element was found and deleted
     * @param self Storage array containing address type variables
     * @param element the element to remove from the array
     */
    function removeAddress(Addresses storage self, address element) internal returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                self._items[i] = self._items[self.size() - 1];
                self._items.pop();
                return true;
            }
        }
        return false;
    }

    /**
     * @notice get the address at a specific index from array
     * @dev revert if the index is out of bounds
     * @param self Storage array containing address type variables
     * @param index the index in the array
     */
    function getAddressAtIndex(Addresses storage self, uint256 index) internal view returns (address) {
        require(index < size(self), "the index is out of bounds");
        return self._items[index];
    }

    /**
     * @notice get the size of the array
     * @param self Storage array containing address type variables
     */
    function size(Addresses storage self) internal view returns (uint256) {
        return self._items.length;
    }

    /**
     * @notice check if an element exist in the array
     * @param self Storage array containing address type variables
     * @param element the element to check if it exists in the array
     */
    function exists(Addresses storage self, address element) internal view returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice get the array
     * @param self Storage array containing address type variables
     */
    function getAllAddresses(Addresses storage self) internal view returns(address[] memory) {
        return self._items;
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IFarm {
    function deposit(uint256 _pid, uint256 _amount) external;
    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function poolInfo(uint256 _pid) external view returns (address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accEggPerShare);
    function emergencyWithdraw(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


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
abstract contract ReentrancyGuard {
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

