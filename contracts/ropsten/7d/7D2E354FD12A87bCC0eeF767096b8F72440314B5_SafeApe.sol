/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

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

pragma solidity >=0.4.0;

interface IERC20 {
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
     * @dev Returns the erc token owner.
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeERC20: decreased allowance below zero'
        );
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

        bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
        }
    }
}


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
    address private _operator;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OperatorshipTransferred(address indexed previousOperator, address indexed newOperator);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        _operator = msgSender;

        emit OwnershipTransferred(address(0), msgSender);
        emit OperatorshipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender() || _operator == _msgSender(), 'Ownable: caller is not the owner');
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
     * Can only be called by the current owner.
     */
    function transferOperatorship(address newOperator) public onlyOwner {
        _transferOperatorship(newOperator);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        _operator = newOwner;
    }

    /**
     * @dev Transfers operatorship of the contract to a new account (`newOwner`).
     */
    function _transferOperatorship(address newOperator) internal {
        require(newOperator != address(0), 'Ownable: new operator is the zero address');
        emit OperatorshipTransferred(_operator, newOperator);
        _operator = newOperator;
    }
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

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

// File: contracts/SafeApe.sol

pragma solidity 0.6.12;

contract SafeApe is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 stakeAmount;
        uint256 claimeAmount;
        bool claimed;
    }

    struct PoolInfo {
        IERC20  apeToken;
        address lpAddress;
        uint256 assignedAmount;
        uint256 stakeAmount;
        uint256 startTime;
        uint256 apingTime;
        uint256 endTime;
        uint256 endPrice;
        uint256 feeRate;
        bool finalized;
    }

    struct FeeInfo {
        address wallet;
        uint256 feeRate;
    }

    IERC20 public stakingToken;
    IERC20 public wethToken;
    address public stableLPAddress;

    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    FeeInfo[] public feeInfo;

    event SetInitialInfo();
    event AddPoolInfo();
    event SetPoolInfo(uint256 pid);
    event AddFeeInfo(address wallet, uint256 feeRate);
    event SetFeeInfo(uint256 fid, address wallet, uint256 feeRate);
    event Stake(address indexed user, uint256 pid, uint256 amount);
    event FinalizedApe(uint256 pid);
    event Claim(address indexed user, uint256 amount);
    event DivideFee();
    
    constructor() public {
    }

    function setInitialInfo(IERC20 _stakingToken, IERC20 _wethToken,  address _stableLp) public onlyOwner {
        stakingToken = _stakingToken;
        wethToken = _wethToken;
        stableLPAddress = _stableLp;

        emit SetInitialInfo();
    }

    function stake(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        require( pool.apingTime > now, "stake: stake is finished");
        require( pool.startTime < now, "stake: stake is not started");

        if(_amount > 0) {
            stakingToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.stakeAmount = user.stakeAmount.add(_amount); 
        }
        
        pool.stakeAmount = pool.stakeAmount.add(_amount);
        emit Stake(msg.sender, _pid, _amount);
    }

    function addFee(address _wallet, uint256 _feeRate) public onlyOwner {
        require(_feeRate > 0, "addFee: invalid feeRate");
        
        feeInfo.push(FeeInfo({
            wallet: _wallet,
            feeRate: _feeRate
        }));

        emit AddFeeInfo(_wallet, _feeRate);
    }

    function setFee(uint256 _fid, address _wallet, uint256 _feeRate) public onlyOwner {
        require(_feeRate > 0, "addFee: invalid feeRate");
        require(_fid < feeInfo.length, "addFee: invalid _fid");
        feeInfo[_fid].wallet = _wallet;
        feeInfo[_fid].feeRate = _feeRate;

        emit SetFeeInfo(_fid, _wallet, _feeRate);
    }

    function add(IERC20 _apeToken,  address _lpAddress, uint256 _assignedAmount, uint256 _startTime, uint256 _apingTime, uint256 _endTime, uint256 _endPrice, uint256 _feeRate) public onlyOwner {
        require(_endTime > _startTime && _endTime >  now, "add: invalid endTime");
        require(_apingTime > _startTime && _apingTime < _endTime && _apingTime > now, "add: invalid apingTime");

        require(_assignedAmount > 0, "add: invalid assignedAmount");
        require(_endPrice > 0, "add: invalid endPrice");
        require(_feeRate > 0 && _feeRate <= 1000, "add: invalid endPrice");

        poolInfo.push(PoolInfo({
            apeToken: _apeToken,
            lpAddress: _lpAddress,
            assignedAmount: _assignedAmount,
            stakeAmount: 0,    
            startTime: _startTime,
            apingTime: _apingTime,
            endTime: _endTime,
            endPrice: _endPrice,
            feeRate: _feeRate,
            finalized: false
        }));

        emit AddPoolInfo();
    }

    function set(uint256 _pid, IERC20 _apeToken,  address _lpAddress, uint256 _assignedAmount, uint256 _startTime, uint256 _apingTime, uint256 _endTime, uint256 _endPrice, uint256 _feeRate) public onlyOwner {
        require(_endTime > _startTime && _endTime >  now, "add: invalid endTime");
        require(_apingTime > _startTime && _apingTime < _endTime && _apingTime > now, "add: invalid apingTime");

        require(_assignedAmount > 0, "add: invalid assignedAmount");
        require(_endPrice > 0, "add: invalid endPrice");
        require(_feeRate > 0 && _feeRate <= 1000, "add: invalid feeRate");
        
        poolInfo[_pid].apeToken = _apeToken;
        poolInfo[_pid].lpAddress = _lpAddress;
        poolInfo[_pid].assignedAmount = _assignedAmount;

        poolInfo[_pid].startTime = _startTime;
        poolInfo[_pid].apingTime = _apingTime;
        poolInfo[_pid].endTime = _endTime;
        poolInfo[_pid].endPrice = _endPrice;
        poolInfo[_pid].feeRate = _feeRate;

        emit SetPoolInfo(_pid);
    }

    function endApe(uint256 _pid, bool _isStable) external onlyOwner {
        uint256 price = getTokenPrice(_pid, _isStable);
        require (price >= poolInfo[_pid].endPrice || poolInfo[_pid].endTime < now, "endApe: Ape can't be finished.");

        poolInfo[_pid].finalized = true;
        emit FinalizedApe(_pid);
    }

    function getTokenPrice(uint256 _pid, bool _isStable) public view returns (uint256) {
        uint256 baseValue = 10**18;
        uint256 apeTokenRate = getTokenRateFromLiquidity(poolInfo[_pid].lpAddress, poolInfo[_pid].apeToken);
        if(_isStable)
            return apeTokenRate;
        uint256 wethTokenRate = getTokenRateFromLiquidity(stableLPAddress, wethToken);
        
        return apeTokenRate.mul(wethTokenRate).div(baseValue);
    }

    function getTokenRateFromLiquidity(address _lpAddress, IERC20 _nativeToken) public view returns (uint256) {
        uint256 rate;
        uint256 baseValue = 10**18;
        IUniswapV2Pair pair = IUniswapV2Pair(_lpAddress);
        (uint Res0, uint Res1,) = pair.getReserves();
        IERC20 tokenA = IERC20(pair.token0());
        IERC20 tokenB = IERC20(pair.token1());

        if (tokenA == _nativeToken){
            uint256 ratio = baseValue.mul(tokenB.decimals()).div(tokenA.decimals());
            rate = ratio.mul(Res1).div(Res0);
            
        }else if ( tokenB == _nativeToken){
            uint256 ratio = baseValue.mul(tokenA.decimals()).div(tokenB.decimals());
            rate = ratio.mul(Res0).div(Res1);
        }

        return rate;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function feeLength() external view returns (uint256) {
        return feeInfo.length;
    }

    function recoverERC20(IERC20 recoverToken, uint256 tokenAmount, address _recoveryAddress) external onlyOwner {
        recoverToken.approve(address(this), tokenAmount);
        recoverToken.transfer(_recoveryAddress, tokenAmount);
    }

    // Claim new tokens.
    function claim(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(pool.finalized , "claim: It is not distribution status.");
        require(user.stakeAmount > 0, "claim: there was no your stake.");

        uint256 claim_amount = pool.assignedAmount.mul(user.stakeAmount).div(pool.stakeAmount);
        if(claim_amount > 0) {
            if (pool.apeToken.balanceOf(address(this)) < claim_amount)
                claim_amount = pool.apeToken.balanceOf(address(this));
            if (stakingToken.balanceOf(address(this)) < user.stakeAmount)
                claim_amount = pool.apeToken.balanceOf(address(this));                
            pool.apeToken.safeTransfer(address(msg.sender), claim_amount);
            stakingToken.safeTransfer(address(msg.sender), user.stakeAmount);
            user.stakeAmount = 0;
            user.claimeAmount = claim_amount;
            user.claimed = true;
        }

        emit Claim(address(msg.sender), claim_amount);
    }

    function divideFee(uint256 _pid, uint256 _amount) external onlyOwner {
        uint256 length = feeInfo.length;
        for (uint256 fid = 0; fid < length; ++fid) {
            FeeInfo storage fee = feeInfo[fid];
            uint256 feeAmount = _amount.mul(fee.feeRate).div(10000);
            uint256 balanceApe = poolInfo[_pid].apeToken.balanceOf(address(this));
            if (balanceApe > 0){
                if (balanceApe < feeAmount)
                    poolInfo[_pid].apeToken.transfer(fee.wallet, balanceApe);
                else
                    poolInfo[_pid].apeToken.transfer(fee.wallet, feeAmount);
            }            
        }

        emit DivideFee();
    }

    function getApeStatus(uint256 _pid, bool _isStable) public view returns (uint256) {
        uint256 status;
        uint256 price = getTokenPrice(_pid, _isStable);

        if (now < poolInfo[_pid].startTime)
            status = 0;
        else if (now < poolInfo[_pid].apingTime)
            status = 1;
        else if (now < poolInfo[_pid].endTime)
            status = 2;
        else
            status = 3;
        
        if(price >= poolInfo[_pid].endPrice)
            status = 3;
        
        return status;
    }

    function hasEnded(uint256 _pid, bool _isStable) public view returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 price = getTokenPrice(_pid, _isStable);
        return pool.finalized || now >= pool.endTime || price >= pool.endPrice;
    }
}