// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
    function decimals() external view returns (uint8);

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

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

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
    address private _governance;

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _governance = msgSender;
        emit GovernanceTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function governance() public view returns (address) {
        return _governance;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGovernance() {
        require(_governance == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferGovernance(address newOwner) internal virtual onlyGovernance {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit GovernanceTransferred(_governance, newOwner);
        _governance = newOwner;
    }
}

// Tornado interfaces

interface TornadoContract {
    function denomination() external view returns (uint256);
    function deposit(bytes32 _commitment) external;
    function withdraw(bytes calldata _proof, bytes32 _root, bytes32 _nullifierHash, address payable _recipient, address payable _relayer, uint256 _fee, uint256 _refund) external payable;
}


// File: contracts/StabilizeTornadoProxy.sol

pragma solidity ^0.6.6;

// The Stabilize Tornado Proxy is a contract that is a front for the Tornado protocol
// It will collect all the relay fees and distribute some to sender and some to the treasury
// For stables, the contract checks if 10 stablecoins are going to the sender of the message
// For non stables, the contract checks that the nonStableFee exists and is split 50/50

contract StabilizeTornadoProxyV2 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    address public treasuryAddress; // Address of the treasury
    uint256 constant minStablecoinFee = 10; // Absolute minimum amount that goes to msg.sender for stables
    
    // Other Variables
    uint256 constant divisionFactor = 100000;
    uint256 public nonStableFee = 1000; // 1000 = 1%, can be modified by governance up to 5% with timelock
    
    struct TokenInfo {
        IERC20 token; // Reference of token
        uint256 decimals; // Decimals of token
        bool isStable; // Whether the token is a stablecoin or not
        uint256 mixerTotal; // Total number of mixers for token
        mapping(uint256 => MixerInfo) mixerData; // Information regarding the mixers
    }

    // Info of each Tornado mixer
    struct MixerInfo {
        TornadoContract mixer; // Reference to the Tornado mixer
        uint256 denomination; // The units to deposit and withdraw
        uint256 totalDeposits; // The current pool size
        uint256 depositSinceWithdraw; // The number of deposits since the last withdraw
        uint256 lastDeposit; // Time of last deposit
    }
    
    // Each coin type is in a separate mixer field
    TokenInfo[] private tokenList;

    constructor(
        address _treasury
    ) public {
        treasuryAddress = _treasury;
        setupTornadoProxies(); // Setup the tornado proxies
    }

    // Initialization functions
    
    function setupTornadoProxies() internal {
        // Setup mixer info
        
        // Start with DAI
        IERC20 _token = IERC20(address(0x6B175474E89094C44Da98b954EedeAC495271d0F));
        tokenList.push(
            TokenInfo({
                token: _token,
                decimals: _token.decimals(),
                isStable: true,
                mixerTotal: 2
            })
        );
        TornadoContract _tor = TornadoContract(address(0xD4B88Df4D29F5CedD6857912842cff3b20C8Cfa3)); // DAI 100
        tokenList[0].mixerData[0] = 
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
        _tor = TornadoContract(address(0xFD8610d20aA15b7B2E3Be39B396a1bC3516c7144)); // DAI 1000
        tokenList[0].mixerData[1] =
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
        
        // USDC
        _token = IERC20(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48));
        tokenList.push(
            TokenInfo({
                token: _token,
                decimals: _token.decimals(),
                isStable: true,
                mixerTotal: 2
            })
        );
        _tor = TornadoContract(address(0xd96f2B1c14Db8458374d9Aca76E26c3D18364307)); // USDC 100
        tokenList[1].mixerData[0] = 
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
        _tor = TornadoContract(address(0x4736dCf1b7A3d580672CcE6E7c65cd5cc9cFBa9D)); // USDC 1000
        tokenList[1].mixerData[1] =
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
        
        // USDT
        _token = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
        tokenList.push(
            TokenInfo({
                token: _token,
                decimals: _token.decimals(),
                isStable: true,
                mixerTotal: 2
            })
        );
        _tor = TornadoContract(address(0x169AD27A470D064DEDE56a2D3ff727986b15D52B)); // USDT 100
        tokenList[2].mixerData[0] = 
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
        _tor = TornadoContract(address(0x0836222F2B2B24A3F36f98668Ed8F0B38D1a872f)); // USDT 1000
        tokenList[2].mixerData[1] =
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
            
        // yUSD
        _token = IERC20(address(0x5dbcF33D8c2E976c6b560249878e6F1491Bca25c));
        tokenList.push(
            TokenInfo({
                token: _token,
                decimals: _token.decimals(),
                isStable: false,
                mixerTotal: 2
            })
        );
        _tor = TornadoContract(address(0x8d28F129B68040aBf99b35E40cdcf74076d5fE6e)); // yUSD 100
        tokenList[3].mixerData[0] = 
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
        _tor = TornadoContract(address(0x111FAc330b27f7C6bf4b9babeD6eb813dd2de53B)); // yUSD 1000
        tokenList[3].mixerData[1] =
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
            
        // LINK
        _token = IERC20(address(0x514910771AF9Ca656af840dff83E8264EcF986CA));
        tokenList.push(
            TokenInfo({
                token: _token,
                decimals: _token.decimals(),
                isStable: false,
                mixerTotal: 2
            })
        );
        _tor = TornadoContract(address(0x7753f5c8b93c3E4f626B0Be6849232f09F8C3112)); // LINK 10
        tokenList[4].mixerData[0] = 
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
        _tor = TornadoContract(address(0x72A6B674C8549cBcCd9CD0c734c60D8947D42473)); // LINK 100
        tokenList[4].mixerData[1] =
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
            
        // wBTC
        _token = IERC20(address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599));
        tokenList.push(
            TokenInfo({
                token: _token,
                decimals: _token.decimals(),
                isStable: false,
                mixerTotal: 3
            })
        );
        _tor = TornadoContract(address(0x81276cFB9c6462CCEfD12D2b4ef0F7Dca48d159A)); // wBTC 0.01
        tokenList[5].mixerData[0] = 
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
        _tor = TornadoContract(address(0x46127457e12839fB1FD2b999d6F9C27aBe561FE5)); // wBTC 0.1
        tokenList[5].mixerData[1] =
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
        _tor = TornadoContract(address(0x1b2e3dC25412Cae71E91F633184eeff55D4170A3)); // wBTC 1
        tokenList[5].mixerData[2] =
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
            
        // renBTC
        _token = IERC20(address(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D));
        tokenList.push(
            TokenInfo({
                token: _token,
                decimals: _token.decimals(),
                isStable: false,
                mixerTotal: 3
            })
        );
        _tor = TornadoContract(address(0xE3470eaDcCC03F6890562271672E083052e0d9bf)); // renBTC 0.01
        tokenList[6].mixerData[0] = 
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
        _tor = TornadoContract(address(0x1B63340AC04f10663A3D1c0fEDCdfa6B79a96465)); // renBTC 0.1
        tokenList[6].mixerData[1] =
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
        _tor = TornadoContract(address(0x13920AecbE854839AB0dc258f3B4907cbFffd538)); // renBTC 1
        tokenList[6].mixerData[2] =
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
            
        // CRV RenWBTC
        _token = IERC20(address(0x49849C98ae39Fff122806C06791Fa73784FB3675));
        tokenList.push(
            TokenInfo({
                token: _token,
                decimals: _token.decimals(),
                isStable: false,
                mixerTotal: 3
            })
        );
        _tor = TornadoContract(address(0xa36D590B200079e91a3FA9802A202d933Be62eef)); // crv renwbtc 0.01
        tokenList[7].mixerData[0] = 
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
        _tor = TornadoContract(address(0xe6F0F739963B623E4BB67CFb284ba7aFECee34De)); // crv renwbtc 0.1
        tokenList[7].mixerData[1] =
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
        _tor = TornadoContract(address(0xb9bF8EE111fAf685DE6cF2c06767240feaa59f9c)); // crv renwbtc 1
        tokenList[7].mixerData[2] =
            MixerInfo({
                mixer: _tor,
                denomination: _tor.denomination(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            });
    }
    
    function getPoolsDetails(uint256 _type) external view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        // Returns everything about the pool except total in one call
        require(_type < tokenList.length,"Type out of range");
        uint256 _3rdDepositSinceWithdraw = 0; // Some tokens don't have 3 pools
        uint256 _3rdLastDeposit = 0;
        if(tokenList[_type].mixerTotal == 3){
            _3rdDepositSinceWithdraw = tokenList[_type].mixerData[2].depositSinceWithdraw;
            _3rdLastDeposit = tokenList[_type].mixerData[2].lastDeposit;
        }
        return(
            tokenList[_type].mixerData[0].depositSinceWithdraw,
            tokenList[_type].mixerData[1].depositSinceWithdraw,
            _3rdDepositSinceWithdraw, // May be 0 if token doesn't have a 3rd pool
            tokenList[_type].mixerData[0].lastDeposit,
            tokenList[_type].mixerData[1].lastDeposit,
            _3rdLastDeposit
            );
    }
    
    function getPoolsTotal(uint256 _type) external view returns (uint256) {
        require(_type < tokenList.length,"Type out of range");
        uint256 _total = 0;
        for(uint256 i = 0; i < tokenList[_type].mixerTotal; i++){
            _total = _total.add(tokenList[_type].mixerData[i].totalDeposits);
        }
        return _total;
    }
    
    
    // Deposit methods
    function _deposit(bytes32 _commitment, uint256 _amount, uint256 _tokenID, uint256 _mixerID) internal {
        tokenList[_tokenID].token.safeTransferFrom(_msgSender(), address(this), _amount); // Pull from the user
        tokenList[_tokenID].token.safeApprove(address(tokenList[_tokenID].mixerData[_mixerID].mixer), _amount); // Approve token to send to Tornado
        tokenList[_tokenID].mixerData[_mixerID].mixer.deposit(_commitment); // Now deposit the token
        tokenList[_tokenID].mixerData[_mixerID].lastDeposit = now; // Metrics, last deposit time
        tokenList[_tokenID].mixerData[_mixerID].totalDeposits = tokenList[_tokenID].mixerData[_mixerID].totalDeposits.add(_amount); // Add to the deposit amount
        tokenList[_tokenID].mixerData[_mixerID].depositSinceWithdraw = tokenList[_tokenID].mixerData[_mixerID].depositSinceWithdraw.add(1); // Total deposits since withdraw
    }
    
    // Token IDs
    // 0 - DAI
    // 1 - USDC
    // 2 - USDT
    // 3 - yUSD
    // 4 - LINK
    // 5 - wBTC
    // 6 - renBTC
    // 7 - crv renwBTC
    function depositDAI(bytes32 _commitment, uint256 amount) external {
        uint256 _tokenID = 0;
        require(amount == tokenList[_tokenID].mixerData[0].denomination || amount == tokenList[_tokenID].mixerData[1].denomination, "Can only deposit either 100 or 1000 DAI");
        if(amount == tokenList[_tokenID].mixerData[0].denomination){
            _deposit(_commitment, amount, _tokenID, 0); // DAI 100 deposit
        }else{
            _deposit(_commitment, amount, _tokenID, 1); // DAI 1000 deposit
        }    
    }
    
    function depositUSDC(bytes32 _commitment, uint256 amount) external {
        uint256 _tokenID = 1;
        require(amount == tokenList[_tokenID].mixerData[0].denomination || amount == tokenList[_tokenID].mixerData[1].denomination, "Can only deposit either 100 or 1000 USDC");
        if(amount == tokenList[_tokenID].mixerData[0].denomination){
            _deposit(_commitment, amount, _tokenID, 0); // USDC 100 deposit
        }else{
            _deposit(_commitment, amount, _tokenID, 1); // USDC 1000 deposit
        }
    }
    
    function depositUSDT(bytes32 _commitment, uint256 amount) external {
        uint256 _tokenID = 2;
        require(amount == tokenList[_tokenID].mixerData[0].denomination || amount == tokenList[_tokenID].mixerData[1].denomination, "Can only deposit either 100 or 1000 USDT");
        if(amount == tokenList[_tokenID].mixerData[0].denomination){
            _deposit(_commitment, amount, _tokenID, 0); // USDT 100 deposit
        }else{
            _deposit(_commitment, amount, _tokenID, 1); // USDT 1000 deposit
        }
    }
    
    function depositYUSD(bytes32 _commitment, uint256 amount) external {
        uint256 _tokenID = 3;
        require(amount == tokenList[_tokenID].mixerData[0].denomination || amount == tokenList[_tokenID].mixerData[1].denomination, "Can only deposit either 100 or 1000 yUSD");
        if(amount == tokenList[_tokenID].mixerData[0].denomination){
            _deposit(_commitment, amount, _tokenID, 0); // yUSD 100 deposit
        }else{
            _deposit(_commitment, amount, _tokenID, 1); // yUSD 1000 deposit
        }
    }
    
    function depositLINK(bytes32 _commitment, uint256 amount) external {
        uint256 _tokenID = 4;
        require(amount == tokenList[_tokenID].mixerData[0].denomination || amount == tokenList[_tokenID].mixerData[1].denomination, "Can only deposit either 10 or 100 LINK");
        if(amount == tokenList[_tokenID].mixerData[0].denomination){
            _deposit(_commitment, amount, _tokenID, 0); // LINK 10 deposit
        }else{
            _deposit(_commitment, amount, _tokenID, 1); // LINK 100 deposit
        }
    }
    
    function depositWBTC(bytes32 _commitment, uint256 amount) external {
        uint256 _tokenID = 5;
        require(amount == tokenList[_tokenID].mixerData[0].denomination 
        || amount == tokenList[_tokenID].mixerData[1].denomination
        || amount == tokenList[_tokenID].mixerData[2].denomination, "Can only deposit either 0.01, 0.1 or 1 wBTC");
        if(amount == tokenList[_tokenID].mixerData[0].denomination){
            _deposit(_commitment, amount, _tokenID, 0); // wBTC 0.01
        }else if(amount == tokenList[_tokenID].mixerData[1].denomination){
            _deposit(_commitment, amount, _tokenID, 1); // wBTC 0.1
        }else{
            _deposit(_commitment, amount, _tokenID, 2); // wBTC 1
        }
    }
    
    function depositRenBTC(bytes32 _commitment, uint256 amount) external {
        uint256 _tokenID = 6;
        require(amount == tokenList[_tokenID].mixerData[0].denomination 
        || amount == tokenList[_tokenID].mixerData[1].denomination
        || amount == tokenList[_tokenID].mixerData[2].denomination, "Can only deposit either 0.01, 0.1 or 1 renBTC");
        if(amount == tokenList[_tokenID].mixerData[0].denomination){
            _deposit(_commitment, amount, _tokenID, 0); // wBTC 0.01
        }else if(amount == tokenList[_tokenID].mixerData[1].denomination){
            _deposit(_commitment, amount, _tokenID, 1); // wBTC 0.1
        }else{
            _deposit(_commitment, amount, _tokenID, 2); // wBTC 1
        }
    }

    function depositCrvRenWBTC(bytes32 _commitment, uint256 amount) external {
        uint256 _tokenID = 7;
        require(amount == tokenList[_tokenID].mixerData[0].denomination 
        || amount == tokenList[_tokenID].mixerData[1].denomination
        || amount == tokenList[_tokenID].mixerData[2].denomination, "Can only deposit either 0.01, 0.1 or 1 CRV renwBTC");
        if(amount == tokenList[_tokenID].mixerData[0].denomination){
            _deposit(_commitment, amount, _tokenID, 0); // wBTC 0.01
        }else if(amount == tokenList[_tokenID].mixerData[1].denomination){
            _deposit(_commitment, amount, _tokenID, 1); // wBTC 0.1
        }else{
            _deposit(_commitment, amount, _tokenID, 2); // wBTC 1
        }
    }
    
    // Withdraw functions
    function _withdraw(bytes memory _proof, uint256 amount, bytes32 _root, 
                        bytes32 _nullifierHash, address payable _recipient, 
                        address payable _relayer, uint256 _fee, uint256 _refund,
                        uint256 _tokenID, uint256 _mixerID) internal {
                            // The sender can send ETH to the recipient
                            require(_relayer == address(this), "The relayer must be this contract");
                            // This address should now have the fee
                            if(tokenList[_tokenID].isStable == true){ // The rules for stablecoins
                                uint256 gasCharge = minStablecoinFee.mul(10**tokenList[_tokenID].decimals); // Get gas fee in base units
                                require(_fee >= gasCharge, "Fee not enough to pay for minimum fee of 10 tokens");
                                tokenList[_tokenID].mixerData[_mixerID].mixer.withdraw{value: msg.value}(_proof, _root, _nullifierHash, _recipient, _relayer, _fee, _refund); // Now withdraw the tokens
                                _fee = _fee.sub(gasCharge); // The gas charge goes directly to the message sender
                                uint256 treasuryFee = _fee.div(2); // Treasury takes half the withdraw fee
                                _fee = _fee.sub(treasuryFee);
                                tokenList[_tokenID].token.safeTransfer(_msgSender(), _fee.add(gasCharge)); // The message sender gets half the fee plus gas charge
                                tokenList[_tokenID].token.safeTransfer(treasuryAddress,treasuryFee);                               
                            }else{ // Rules for non stables
                                uint256 minFee = amount.mul(nonStableFee).div(divisionFactor);
                                require(_fee >= minFee, "Fee not enough to pay minimum of 1%");
                                tokenList[_tokenID].mixerData[_mixerID].mixer.withdraw{value: msg.value}(_proof, _root, _nullifierHash, _recipient, _relayer, _fee, _refund); // Now withdraw the tokens
                                uint256 treasuryFee = _fee.div(2);
                                _fee = _fee.sub(treasuryFee);
                                tokenList[_tokenID].token.safeTransfer(_msgSender(), _fee); // The message sender gets half the fee
                                tokenList[_tokenID].token.safeTransfer(treasuryAddress,treasuryFee); // The treasury gets the other half
                            }
                            if(tokenList[_tokenID].mixerData[_mixerID].totalDeposits >= amount){ // This condition will prevent a malicious withdrawer from locking the proxy
                                tokenList[_tokenID].mixerData[_mixerID].totalDeposits = tokenList[_tokenID].mixerData[_mixerID].totalDeposits.sub(amount); // Take away from deposits
                            }
                            tokenList[_tokenID].mixerData[_mixerID].depositSinceWithdraw = 0; // Reset withdraws                            
                        }

    // Token IDs
    // 0 - DAI
    // 1 - USDC
    // 2 - USDT
    // 3 - yUSD
    // 4 - LINK
    // 5 - wBTC
    // 6 - renBTC
    // 7 - crv renwBTC
    function withdrawDAI(bytes calldata _proof, uint256 amount, bytes32 _root, 
                        bytes32 _nullifierHash, address payable _recipient, 
                        address payable _relayer, uint256 _fee, uint256 _refund) external payable {
                            // The user can send ETH to the recipient
                            uint256 _tokenID = 0;
                            require(amount == tokenList[_tokenID].mixerData[0].denomination || amount == tokenList[_tokenID].mixerData[1].denomination, "Can only withdraw either 100 or 1000 DAI");
                            if(amount == tokenList[_tokenID].mixerData[0].denomination){
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 0); // DAI 100 withdraw
                            }else{
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 1); // DAI 1000 withdraw
                            }                            
                        }
                        
    function withdrawUSDC(bytes calldata _proof, uint256 amount, bytes32 _root, 
                        bytes32 _nullifierHash, address payable _recipient, 
                        address payable _relayer, uint256 _fee, uint256 _refund) external payable {
                            // The user can send ETH to the recipient
                            uint256 _tokenID = 1;
                            require(amount == tokenList[_tokenID].mixerData[0].denomination || amount == tokenList[_tokenID].mixerData[1].denomination, "Can only withdraw either 100 or 1000 USDC");
                            if(amount == tokenList[_tokenID].mixerData[0].denomination){
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 0); // USDC 100 withdraw
                            }else{
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 1); // USDC 1000 withdraw
                            } 
                        }
                        
    function withdrawUSDT(bytes calldata _proof, uint256 amount, bytes32 _root, 
                        bytes32 _nullifierHash, address payable _recipient, 
                        address payable _relayer, uint256 _fee, uint256 _refund) external payable {
                            // The user can send ETH to the recipient
                            uint256 _tokenID = 2;
                            require(amount == tokenList[_tokenID].mixerData[0].denomination || amount == tokenList[_tokenID].mixerData[1].denomination, "Can only withdraw either 100 or 1000 USDT");
                            if(amount == tokenList[_tokenID].mixerData[0].denomination){
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 0); // USDT 100 withdraw
                            }else{
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 1); // USDT 1000 withdraw
                            } 
                        }

    function withdrawYUSD(bytes calldata _proof, uint256 amount, bytes32 _root, 
                        bytes32 _nullifierHash, address payable _recipient, 
                        address payable _relayer, uint256 _fee, uint256 _refund) external payable {
                            // The user can send ETH to the recipient
                            uint256 _tokenID = 3;
                            require(amount == tokenList[_tokenID].mixerData[0].denomination || amount == tokenList[_tokenID].mixerData[1].denomination, "Can only withdraw either 100 or 1000 yUSD");
                            if(amount == tokenList[_tokenID].mixerData[0].denomination){
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 0); // yUSD 100 withdraw
                            }else{
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 1); // yUSD 1000 withdraw
                            } 
                        }
                        
    function withdrawLINK(bytes calldata _proof, uint256 amount, bytes32 _root, 
                        bytes32 _nullifierHash, address payable _recipient, 
                        address payable _relayer, uint256 _fee, uint256 _refund) external payable {
                            // The user can send ETH to the recipient
                            uint256 _tokenID = 4;
                            require(amount == tokenList[_tokenID].mixerData[0].denomination || amount == tokenList[_tokenID].mixerData[1].denomination, "Can only withdraw either 10 or 100 LINK");
                            if(amount == tokenList[_tokenID].mixerData[0].denomination){
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 0); // LINK 10 withdraw
                            }else{
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 1); // LINK 100 withdraw
                            } 
                        }
                        
    function withdrawWBTC(bytes calldata _proof, uint256 amount, bytes32 _root, 
                        bytes32 _nullifierHash, address payable _recipient, 
                        address payable _relayer, uint256 _fee, uint256 _refund) external payable {
                            // The user can send ETH to the recipient
                            uint256 _tokenID = 5;
                            require(amount == tokenList[_tokenID].mixerData[0].denomination 
                            || amount == tokenList[_tokenID].mixerData[1].denomination
                            || amount == tokenList[_tokenID].mixerData[2].denomination, "Can only withdraw either 0.01, 0.1 or 1 wBTC");
                            if(amount == tokenList[_tokenID].mixerData[0].denomination){
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 0); // wBTC 0.01 withdraw
                            }else if(amount == tokenList[_tokenID].mixerData[1].denomination){
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 1); // wBTC 0.1 withdraw
                            }else{
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 2); // wBTC 1 withdraw
                            }
                        }

    function withdrawRenBTC(bytes calldata _proof, uint256 amount, bytes32 _root, 
                        bytes32 _nullifierHash, address payable _recipient, 
                        address payable _relayer, uint256 _fee, uint256 _refund) external payable {
                            // The user can send ETH to the recipient
                            uint256 _tokenID = 6;
                            require(amount == tokenList[_tokenID].mixerData[0].denomination 
                            || amount == tokenList[_tokenID].mixerData[1].denomination
                            || amount == tokenList[_tokenID].mixerData[2].denomination, "Can only withdraw either 0.01, 0.1 or 1 renBTC");
                            if(amount == tokenList[_tokenID].mixerData[0].denomination){
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 0); // renBTC 0.01 withdraw
                            }else if(amount == tokenList[_tokenID].mixerData[1].denomination){
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 1); // renBTC 0.1 withdraw
                            }else{
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 2); // renBTC 1 withdraw
                            }
                        }
                        
    function withdrawCrvRenWBTC(bytes calldata _proof, uint256 amount, bytes32 _root, 
                        bytes32 _nullifierHash, address payable _recipient, 
                        address payable _relayer, uint256 _fee, uint256 _refund) external payable {
                            // The user can send ETH to the recipient
                            uint256 _tokenID = 7;
                            require(amount == tokenList[_tokenID].mixerData[0].denomination 
                            || amount == tokenList[_tokenID].mixerData[1].denomination
                            || amount == tokenList[_tokenID].mixerData[2].denomination, "Can only withdraw either 0.01, 0.1 or 1 CRV renwBTC");
                            if(amount == tokenList[_tokenID].mixerData[0].denomination){
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 0); // Crv renwBTC 0.01 withdraw
                            }else if(amount == tokenList[_tokenID].mixerData[1].denomination){
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 1); // Crv renwBTC 0.1 withdraw
                            }else{
                                _withdraw(_proof, amount, _root, _nullifierHash, _recipient, _relayer, _fee, _refund, _tokenID, 2); // Crv renwBTC 1 withdraw
                            }
                        }

    // Governance functions
    // Timelock variables
    
    uint256 private _timelockStart; // The start of the timelock to change governance variables
    uint256 private _timelockType; // The function that needs to be changed
    uint256 constant _timelockDuration = 86400; // Timelock is 24 hours
    
    // Reusable timelock variables
    address private _timelock_address;
    uint256 private _timelock_data_1;
    
    modifier timelockConditionsMet(uint256 _type) {
        require(_timelockType == _type, "Timelock not acquired for this function");
        _timelockType = 0; // Reset the type once the timelock is used
        require(now >= _timelockStart + _timelockDuration, "Timelock time not met");
        _;
    }
    
    // Change the owner of the token contract
    // --------------------
    function startGovernanceChange(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 1;
        _timelock_address = _address;       
    }
    
    function finishGovernanceChange() external onlyGovernance timelockConditionsMet(1) {
        transferGovernance(_timelock_address);
    }
    // --------------------
    
    // Change the treasury address
    // --------------------
    function startChangeTreasury(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 2;
        _timelock_address = _address;
    }
    
    function finishChangeTreasury() external onlyGovernance timelockConditionsMet(2) {
        treasuryAddress = _timelock_address;
    }
    // --------------------
    
    // Change the non stablecoin fee
    // --------------------
    function startChangeNonStableFee(uint256 _fee) external onlyGovernance {
        require(_fee <= 5000,"Fee can never be greater than 5%");
        _timelockStart = now;
        _timelockType = 3;
        _timelock_data_1 = _fee;
    }
    
    function finishChangeNonStableFee() external onlyGovernance timelockConditionsMet(3) {
        nonStableFee = _timelock_data_1;
    }
    // --------------------
}