/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.6;



// Part: BetaRunnerWithCallback

contract BetaRunnerWithCallback {
  address private constant NO_CALLER = address(42); // nonzero so we don't repeatedly clear storage
  address private caller = NO_CALLER;

  modifier withCallback() {
    require(caller == NO_CALLER);
    caller = msg.sender;
    _;
    caller = NO_CALLER;
  }

  modifier isCallback() {
    require(caller == tx.origin);
    _;
  }
}

// Part: BytesLib

library BytesLib {
  function slice(
    bytes memory _bytes,
    uint _start,
    uint _length
  ) internal pure returns (bytes memory) {
    require(_length + 31 >= _length, 'slice_overflow');
    require(_start + _length >= _start, 'slice_overflow');
    require(_bytes.length >= _start + _length, 'slice_outOfBounds');

    bytes memory tempBytes;

    assembly {
      switch iszero(_length)
      case 0 {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
        tempBytes := mload(0x40)

        // The first word of the slice result is potentially a partial
        // word read from the original array. To read it, we calculate
        // the length of that partial word and start copying that many
        // bytes into the array. The first word we copy will start with
        // data we don't care about, but the last `lengthmod` bytes will
        // land at the beginning of the contents of the new array. When
        // we're done copying, we overwrite the full first word with
        // the actual length of the slice.
        let lengthmod := and(_length, 31)

        // The multiplication in the next line is necessary
        // because when slicing multiples of 32 bytes (lengthmod == 0)
        // the following copy loop was copying the origin's length
        // and then ending prematurely not copying everything it should.
        let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
        let end := add(mc, _length)

        for {
          // The multiplication in the next line has the same exact purpose
          // as the one above.
          let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
        } lt(mc, end) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          mstore(mc, mload(cc))
        }

        mstore(tempBytes, _length)

        //update free-memory pointer
        //allocating the array padded to 32 bytes like the compiler does now
        mstore(0x40, and(add(mc, 31), not(31)))
      }
      //if we want a zero-length slice let's just return a zero-length array
      default {
        tempBytes := mload(0x40)
        //zero out the 32 bytes slice we are about to return
        //we need to do it because Solidity does not garbage collect
        mstore(tempBytes, 0)

        mstore(0x40, add(tempBytes, 0x20))
      }
    }

    return tempBytes;
  }

  function toAddress(bytes memory _bytes, uint _start) internal pure returns (address) {
    require(_start + 20 >= _start, 'toAddress_overflow');
    require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
    address tempAddress;

    assembly {
      tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
    }

    return tempAddress;
  }

  function toUint24(bytes memory _bytes, uint _start) internal pure returns (uint24) {
    require(_start + 3 >= _start, 'toUint24_overflow');
    require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
    uint24 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x3), _start))
    }

    return tempUint;
  }
}

// Part: IBetaBank

interface IBetaBank {
  /// @dev Returns the address of BToken of the given underlying token, or 0 if not exists.
  function bTokens(address _underlying) external view returns (address);

  /// @dev Returns the address of the underlying of the given BToken, or 0 if not exists.
  function underlyings(address _bToken) external view returns (address);

  /// @dev Returns the address of the oracle contract.
  function oracle() external view returns (address);

  /// @dev Returns the address of the config contract.
  function config() external view returns (address);

  /// @dev Returns the interest rate model smart contract.
  function interestModel() external view returns (address);

  /// @dev Returns the position's collateral token and AmToken.
  function getPositionTokens(address _owner, uint _pid)
    external
    view
    returns (address _collateral, address _bToken);

  /// @dev Returns the debt of the given position. Can't be view as it needs to call accrue.
  function fetchPositionDebt(address _owner, uint _pid) external returns (uint);

  /// @dev Returns the LTV of the given position. Can't be view as it needs to call accrue.
  function fetchPositionLTV(address _owner, uint _pid) external returns (uint);

  /// @dev Opens a new position in the Beta smart contract.
  function open(
    address _owner,
    address _underlying,
    address _collateral
  ) external returns (uint pid);

  /// @dev Borrows tokens on the given position.
  function borrow(
    address _owner,
    uint _pid,
    uint _amount
  ) external;

  /// @dev Repays tokens on the given position.
  function repay(
    address _owner,
    uint _pid,
    uint _amount
  ) external;

  /// @dev Puts more collateral to the given position.
  function put(
    address _owner,
    uint _pid,
    uint _amount
  ) external;

  /// @dev Takes some collateral out of the position.
  function take(
    address _owner,
    uint _pid,
    uint _amount
  ) external;

  /// @dev Liquidates the given position.
  function liquidate(
    address _owner,
    uint _pid,
    uint _amount
  ) external;
}

// Part: IUniswapV3Pool

interface IUniswapV3Pool {
  function mint(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    uint128 amount,
    bytes calldata data
  ) external returns (uint amount0, uint amount1);

  function swap(
    address recipient,
    bool zeroForOne,
    int amountSpecified,
    uint160 sqrtPriceLimitX96,
    bytes calldata data
  ) external returns (int amount0, int amount1);

  function initialize(uint160 sqrtPriceX96) external;
}

// Part: IUniswapV3SwapCallback

interface IUniswapV3SwapCallback {
  function uniswapV3SwapCallback(
    int amount0Delta,
    int amount1Delta,
    bytes calldata data
  ) external;
}

// Part: IWETH

interface IWETH {
  function deposit() external payable;

  function withdraw(uint wad) external;

  function approve(address guy, uint wad) external returns (bool);
}

// Part: OpenZeppelin/[email protected]/Address

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// Part: OpenZeppelin/[email protected]/Context

/*
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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/Math

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
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// Part: SafeCast

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
  /// @notice Cast a uint256 to a uint160, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint160
  function toUint160(uint y) internal pure returns (uint160 z) {
    require((z = uint160(y)) == y);
  }

  /// @notice Cast a int256 to a int128, revert on overflow or underflow
  /// @param y The int256 to be downcasted
  /// @return z The downcasted integer, now type int128
  function toInt128(int y) internal pure returns (int128 z) {
    require((z = int128(y)) == y);
  }

  /// @notice Cast a uint256 to a int256, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt256(uint y) internal pure returns (int z) {
    require(y < 2**255);
    z = int(y);
  }
}

// Part: OpenZeppelin/[email protected]/Ownable

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Part: OpenZeppelin/[email protected]/SafeERC20

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

// Part: Path

/// @title Functions for manipulating path data for multihop swaps
library Path {
  using BytesLib for bytes;

  /// @dev The length of the bytes encoded address
  uint private constant ADDR_SIZE = 20;
  /// @dev The length of the bytes encoded fee
  uint private constant FEE_SIZE = 3;

  /// @dev The offset of a single token address and pool fee
  uint private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
  /// @dev The offset of an encoded pool key
  uint private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
  /// @dev The minimum length of an encoding that contains 2 or more pools
  uint private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

  /// @notice Returns true iff the path contains two or more pools
  /// @param path The encoded swap path
  /// @return True if path contains two or more pools, otherwise false
  function hasMultiplePools(bytes memory path) internal pure returns (bool) {
    return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
  }

  /// @notice Decodes the first pool in path
  /// @param path The bytes encoded swap path
  /// @return tokenA The first token of the given pool
  /// @return tokenB The second token of the given pool
  /// @return fee The fee level of the pool
  function decodeFirstPool(bytes memory path)
    internal
    pure
    returns (
      address tokenA,
      address tokenB,
      uint24 fee
    )
  {
    tokenA = path.toAddress(0);
    fee = path.toUint24(ADDR_SIZE);
    tokenB = path.toAddress(NEXT_OFFSET);
  }

  /// @notice Decodes the last pool in path
  /// @param path The bytes encoded swap path
  /// @return tokenA The first token of the given pool
  /// @return tokenB The second token of the given pool
  /// @return fee The fee level of the pool
  function decodeLastPool(bytes memory path)
    internal
    pure
    returns (
      address tokenA,
      address tokenB,
      uint24 fee
    )
  {
    tokenB = path.toAddress(path.length - ADDR_SIZE);
    fee = path.toUint24(path.length - NEXT_OFFSET);
    tokenA = path.toAddress(path.length - POP_OFFSET);
  }

  /// @notice Skips a token + fee element from the buffer and returns the remainder
  /// @param path The swap path
  /// @return The remaining token + fee elements in the path
  function skipToken(bytes memory path) internal pure returns (bytes memory) {
    return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
  }
}

// Part: BetaRunnerBase

contract BetaRunnerBase is Ownable {
  using SafeERC20 for IERC20;

  address public immutable betaBank;
  address public immutable weth;

  modifier onlyEOA() {
    require(msg.sender == tx.origin, 'BetaRunnerBase/not-eoa');
    _;
  }

  constructor(address _betaBank, address _weth) {
    address bweth = IBetaBank(_betaBank).bTokens(_weth);
    require(bweth != address(0), 'BetaRunnerBase/no-bweth');
    IERC20(_weth).safeApprove(_betaBank, type(uint).max);
    IERC20(_weth).safeApprove(bweth, type(uint).max);
    betaBank = _betaBank;
    weth = _weth;
  }

  function _borrow(
    address _owner,
    uint _pid,
    address _underlying,
    address _collateral,
    uint _amountBorrow,
    uint _amountCollateral
  ) internal {
    if (_pid == type(uint).max) {
      _pid = IBetaBank(betaBank).open(_owner, _underlying, _collateral);
    } else {
      (address collateral, address bToken) = IBetaBank(betaBank).getPositionTokens(_owner, _pid);
      require(_collateral == collateral, '_borrow/collateral-not-_collateral');
      require(_underlying == IBetaBank(betaBank).underlyings(bToken), '_borrow/bad-underlying');
    }
    _approve(_collateral, betaBank, _amountCollateral);
    IBetaBank(betaBank).put(_owner, _pid, _amountCollateral);
    IBetaBank(betaBank).borrow(_owner, _pid, _amountBorrow);
  }

  function _repay(
    address _owner,
    uint _pid,
    address _underlying,
    address _collateral,
    uint _amountRepay,
    uint _amountCollateral
  ) internal {
    (address collateral, address bToken) = IBetaBank(betaBank).getPositionTokens(_owner, _pid);
    require(_collateral == collateral, '_repay/collateral-not-_collateral');
    require(_underlying == IBetaBank(betaBank).underlyings(bToken), '_repay/bad-underlying');
    _approve(_underlying, bToken, _amountRepay);
    IBetaBank(betaBank).repay(_owner, _pid, _amountRepay);
    IBetaBank(betaBank).take(_owner, _pid, _amountCollateral);
  }

  function _transferIn(
    address _token,
    address _from,
    uint _amount
  ) internal {
    if (_token == weth) {
      require(_from == msg.sender, '_transferIn/not-from-sender');
      require(_amount <= msg.value, '_transferIn/insufficient-eth-amount');
      IWETH(weth).deposit{value: _amount}();
      if (msg.value > _amount) {
        (bool success, ) = _from.call{value: msg.value - _amount}(new bytes(0));
        require(success, '_transferIn/eth-transfer-failed');
      }
    } else {
      IERC20(_token).safeTransferFrom(_from, address(this), _amount);
    }
  }

  function _transferOut(
    address _token,
    address _to,
    uint _amount
  ) internal {
    if (_token == weth) {
      IWETH(weth).withdraw(_amount);
      (bool success, ) = _to.call{value: _amount}(new bytes(0));
      require(success, '_transferOut/eth-transfer-failed');
    } else {
      IERC20(_token).safeTransfer(_to, _amount);
    }
  }

  /// @dev Approves infinite on the given token for the given spender if current approval is insufficient.
  function _approve(
    address _token,
    address _spender,
    uint _minAmount
  ) internal {
    uint current = IERC20(_token).allowance(address(this), _spender);
    if (current < _minAmount) {
      if (current != 0) {
        IERC20(_token).safeApprove(_spender, 0);
      }
      IERC20(_token).safeApprove(_spender, type(uint).max);
    }
  }

  /// @dev Caps repay amount by current position's debt.
  function _capRepay(
    address _owner,
    uint _pid,
    uint _amountRepay
  ) internal returns (uint) {
    return Math.min(_amountRepay, IBetaBank(betaBank).fetchPositionDebt(_owner, _pid));
  }

  /// @dev Recovers lost tokens for whatever reason by the owner.
  function recover(address _token, uint _amount) external onlyOwner {
    if (_amount == type(uint).max) {
      _amount = IERC20(_token).balanceOf(address(this));
    }
    IERC20(_token).safeTransfer(msg.sender, _amount);
  }

  /// @dev Recovers lost ETH for whatever reason by the owner.
  function recoverETH(uint _amount) external onlyOwner {
    if (_amount == type(uint).max) {
      _amount = address(this).balance;
    }
    (bool success, ) = msg.sender.call{value: _amount}(new bytes(0));
    require(success, 'recoverETH/eth-transfer-failed');
  }

  /// @dev Override Ownable.sol renounceOwnership to prevent accidental call
  function renounceOwnership() public override onlyOwner {
    revert('renounceOwnership/disabled');
  }

  receive() external payable {
    require(msg.sender == weth, 'receive/not-weth');
  }
}

// File: BetaRunnerUniswapV3.sol

contract BetaRunnerUniswapV3 is BetaRunnerBase, BetaRunnerWithCallback, IUniswapV3SwapCallback {
  using SafeERC20 for IERC20;
  using Path for bytes;
  using SafeCast for uint;

  /// @dev Constants from Uniswap V3 to be used for swap
  /// (https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/TickMath.sol)
  uint160 internal constant MIN_SQRT_RATIO = 4295128739;
  uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

  address public immutable factory;
  bytes32 public immutable codeHash;

  constructor(
    address _betaBank,
    address _weth,
    address _factory,
    bytes32 _codeHash
  ) BetaRunnerBase(_betaBank, _weth) {
    factory = _factory;
    codeHash = _codeHash;
  }

  struct ShortData {
    uint pid;
    uint amountBorrow;
    uint amountPutExtra;
    bytes path;
    uint amountOutMin;
  }

  struct CloseData {
    uint pid;
    uint amountRepay;
    uint amountTake;
    bytes path;
    uint amountInMax;
  }

  struct CallbackData {
    uint pid;
    address path0;
    uint amount0;
    int memo; // positive if short (extra collateral) | negative if close (amount to take)
    bytes path;
  }

  /// @dev Borrows the asset using the given collateral, and swaps it using the given path.
  function short(ShortData calldata _data) external payable onlyEOA withCallback {
    (, address collateral, ) = _data.path.decodeLastPool();
    _transferIn(collateral, msg.sender, _data.amountPutExtra);
    (address tokenIn, address tokenOut, uint24 fee) = _data.path.decodeFirstPool();
    bool zeroForOne = tokenIn < tokenOut;
    CallbackData memory cb = CallbackData({
      pid: _data.pid,
      path0: tokenIn,
      amount0: _data.amountBorrow,
      memo: _data.amountPutExtra.toInt256(),
      path: _data.path
    });
    (int amount0, int amount1) = IUniswapV3Pool(_poolFor(tokenIn, tokenOut, fee)).swap(
      address(this),
      zeroForOne,
      _data.amountBorrow.toInt256(),
      zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
      abi.encode(cb)
    );
    uint amountReceived = amount0 > 0 ? uint(-amount1) : uint(-amount0);
    require(amountReceived >= _data.amountOutMin, '!slippage');
  }

  /// @dev Swaps the collateral to the underlying asset using the given path, and repays it to the pool.
  function close(CloseData calldata _data) external payable onlyEOA withCallback {
    uint amountRepay = _capRepay(msg.sender, _data.pid, _data.amountRepay);
    (address tokenOut, address tokenIn, uint24 fee) = _data.path.decodeFirstPool();
    bool zeroForOne = tokenIn < tokenOut;
    CallbackData memory cb = CallbackData({
      pid: _data.pid,
      path0: tokenOut,
      amount0: amountRepay,
      memo: -_data.amountTake.toInt256(),
      path: _data.path
    });
    (int amount0, int amount1) = IUniswapV3Pool(_poolFor(tokenIn, tokenOut, fee)).swap(
      address(this),
      zeroForOne,
      -amountRepay.toInt256(),
      zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
      abi.encode(cb)
    );
    uint amountPaid = amount0 > 0 ? uint(amount0) : uint(amount1);
    require(amountPaid <= _data.amountInMax, '!slippage');
  }

  /// @dev Continues the action through uniswapv3
  function uniswapV3SwapCallback(
    int _amount0Delta,
    int _amount1Delta,
    bytes calldata _data
  ) external override isCallback {
    CallbackData memory data = abi.decode(_data, (CallbackData));
    (uint amountToPay, uint amountReceived) = _amount0Delta > 0
      ? (uint(_amount0Delta), uint(-_amount1Delta))
      : (uint(_amount1Delta), uint(-_amount0Delta));
    if (data.memo > 0) {
      _shortCallback(amountToPay, amountReceived, data);
    } else {
      _closeCallback(amountToPay, amountReceived, data);
    }
  }

  function _shortCallback(
    uint _amountToPay,
    uint _amountReceived,
    CallbackData memory data
  ) internal {
    (address tokenIn, address tokenOut, uint24 prevFee) = data.path.decodeFirstPool();
    require(msg.sender == _poolFor(tokenIn, tokenOut, prevFee), '_shortCallback/bad-caller');
    if (data.path.hasMultiplePools()) {
      data.path = data.path.skipToken();
      (, address tokenNext, uint24 fee) = data.path.decodeFirstPool();
      bool zeroForOne = tokenOut < tokenNext;
      IUniswapV3Pool(_poolFor(tokenOut, tokenNext, fee)).swap(
        address(this),
        zeroForOne,
        _amountReceived.toInt256(),
        zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
        abi.encode(data)
      );
    } else {
      uint amountPut = _amountReceived + uint(data.memo);
      _borrow(tx.origin, data.pid, data.path0, tokenOut, data.amount0, amountPut);
    }
    IERC20(tokenIn).safeTransfer(msg.sender, _amountToPay);
  }

  function _closeCallback(
    uint _amountToPay,
    uint,
    CallbackData memory data
  ) internal {
    (address tokenOut, address tokenIn, uint24 prevFee) = data.path.decodeFirstPool();
    require(msg.sender == _poolFor(tokenIn, tokenOut, prevFee), '_closeCallback/bad-caller');
    if (data.path.hasMultiplePools()) {
      data.path = data.path.skipToken();
      (, address tokenNext, uint24 fee) = data.path.decodeFirstPool();
      bool zeroForOne = tokenNext < tokenIn;
      IUniswapV3Pool(_poolFor(tokenIn, tokenNext, fee)).swap(
        msg.sender,
        zeroForOne,
        -_amountToPay.toInt256(),
        zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
        abi.encode(data)
      );
    } else {
      uint amountTake = uint(-data.memo);
      _repay(tx.origin, data.pid, data.path0, tokenIn, data.amount0, amountTake);
      IERC20(tokenIn).safeTransfer(msg.sender, _amountToPay);
      _transferOut(tokenIn, tx.origin, IERC20(tokenIn).balanceOf(address(this)));
    }
  }

  function _poolFor(
    address tokenA,
    address tokenB,
    uint24 fee
  ) internal view returns (address) {
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    bytes32 salt = keccak256(abi.encode(token0, token1, fee));
    return address(uint160(uint(keccak256(abi.encodePacked(hex'ff', factory, salt, codeHash)))));
  }
}