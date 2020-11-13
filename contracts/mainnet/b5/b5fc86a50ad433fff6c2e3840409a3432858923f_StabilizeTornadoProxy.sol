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
// The only fee check this contract does is for 10 stablecoins going to the sender of the message

contract StabilizeTornadoProxy is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    address public treasuryAddress; // Address of the treasury
    uint256 constant minStablecoinFee = 10; // Absolute minimum amount that goes to msg.sender

    // Info of each Tornado mixer
    struct MixerInfo {
        IERC20 token; // Reference of Stablecoin
        uint256 denomination; // The units to deposit and withdraw
        TornadoContract mixer; // Reference to the mixer
        uint256 totalDeposits; // The current pool size
        uint256 depositSinceWithdraw; // The number of deposits since the last withdraw
        uint256 lastDeposit; // Time of last deposit
        uint256 decimals; // Decimals of token
    }
    
    // Each coin type is in a separate mixer field
    MixerInfo[] private daiMixers;
    MixerInfo[] private usdcMixers;
    MixerInfo[] private usdtMixers;

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
        TornadoContract _tor = TornadoContract(address(0xD4B88Df4D29F5CedD6857912842cff3b20C8Cfa3)); // DAI 100
        daiMixers.push(
            MixerInfo({
                token: _token,
                mixer: _tor,
                denomination: _tor.denomination(),
                decimals: _token.decimals(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            })
        );   
        _tor = TornadoContract(address(0xFD8610d20aA15b7B2E3Be39B396a1bC3516c7144)); // DAI 1000
        daiMixers.push(
            MixerInfo({
                token: _token,
                mixer: _tor,
                denomination: _tor.denomination(),
                decimals: _token.decimals(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            })
        );
        
        // USDC
        _token = IERC20(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48));
        _tor = TornadoContract(address(0xd96f2B1c14Db8458374d9Aca76E26c3D18364307)); // USDC 100
        usdcMixers.push(
            MixerInfo({
                token: _token,
                mixer: _tor,
                denomination: _tor.denomination(),
                decimals: _token.decimals(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            })
        );   
        _tor = TornadoContract(address(0x4736dCf1b7A3d580672CcE6E7c65cd5cc9cFBa9D)); // USDC 1000
        usdcMixers.push(
            MixerInfo({
                token: _token,
                mixer: _tor,
                denomination: _tor.denomination(),
                decimals: _token.decimals(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            })
        );  
        
        // USDT
        _token = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
        _tor = TornadoContract(address(0x169AD27A470D064DEDE56a2D3ff727986b15D52B)); // USDT 100
        usdtMixers.push(
            MixerInfo({
                token: _token,
                mixer: _tor,
                denomination: _tor.denomination(),
                decimals: _token.decimals(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            })
        );
        _tor = TornadoContract(address(0x0836222F2B2B24A3F36f98668Ed8F0B38D1a872f)); // USDT 1000
        usdtMixers.push(
            MixerInfo({
                token: _token,
                mixer: _tor,
                denomination: _tor.denomination(),
                decimals: _token.decimals(),
                totalDeposits: 0,
                depositSinceWithdraw: 0,
                lastDeposit: 0
            })
        );
    }
    
    function getPoolsInfo(uint256 _type) public view returns (uint256, uint256, uint256, uint256, uint256) {
        // Returns everything about the pool in one call
        require(_type < 3,"Type out of range");
        if(_type == 0){ // We want DAI info
            return(
                daiMixers[0].totalDeposits.add(daiMixers[1].totalDeposits), // Total balance in both DAI pools
                daiMixers[0].depositSinceWithdraw, // Pool 0 number of deposits
                daiMixers[1].depositSinceWithdraw, // Pool 1
                daiMixers[0].lastDeposit, // Pool 0 last withdraw time
                daiMixers[1].lastDeposit
                );  
        }else if(_type == 1){ // USDC
            return(
                usdcMixers[0].totalDeposits.add(usdcMixers[1].totalDeposits), // Total balance in both USDC pools
                usdcMixers[0].depositSinceWithdraw, // Pool 0 number of deposits
                usdcMixers[1].depositSinceWithdraw, // Pool 1
                usdcMixers[0].lastDeposit, // Pool 0 last withdraw time
                usdcMixers[1].lastDeposit
                );             
        }else{
            return(
                usdtMixers[0].totalDeposits.add(usdtMixers[1].totalDeposits), // Total balance in both USDT pools
                usdtMixers[0].depositSinceWithdraw, // Pool 0 number of deposits
                usdtMixers[1].depositSinceWithdraw, // Pool 1
                usdtMixers[0].lastDeposit, // Pool 0 last withdraw time
                usdtMixers[1].lastDeposit
                );             
        }
    }
    
    // Deposit methods
    function depositDAI(bytes32 _commitment, uint256 amount) external {
        require(amount == daiMixers[0].denomination || amount == daiMixers[1].denomination, "Can only deposit either 100 or 1000 DAI");
        uint256 _ind = 0; // 100 Pool
        if(amount == daiMixers[1].denomination){
            _ind = 1; // Set to 1000 Pool
        }
        daiMixers[_ind].token.safeTransferFrom(_msgSender(), address(this), amount); // Pull from the user
        daiMixers[_ind].token.safeApprove(address(daiMixers[_ind].mixer), amount); // Approve the DAI here to send to Tornado
        daiMixers[_ind].mixer.deposit(_commitment); // Now deposit the DAI
        daiMixers[_ind].lastDeposit = now; // Metrics, last deposit time
        daiMixers[_ind].totalDeposits = daiMixers[_ind].totalDeposits.add(amount); // Add to the deposit amount
        daiMixers[_ind].depositSinceWithdraw = daiMixers[_ind].depositSinceWithdraw.add(1); // Total deposits since withdraw
    }
    
    function depositUSDC(bytes32 _commitment, uint256 amount) external {
        require(amount == usdcMixers[0].denomination || amount == usdcMixers[1].denomination, "Can only deposit either 100 or 1000 USDC");
        uint256 _ind = 0; // 100 Pool
        if(amount == usdcMixers[1].denomination){
            _ind = 1; // Set to 1000 Pool
        }
        usdcMixers[_ind].token.safeTransferFrom(_msgSender(), address(this), amount); // Pull from the user
        usdcMixers[_ind].token.safeApprove(address(usdcMixers[_ind].mixer), amount); // Approve the USDC here to send to Tornado
        usdcMixers[_ind].mixer.deposit(_commitment); // Now deposit the USDC
        usdcMixers[_ind].lastDeposit = now; // Metrics, last deposit time
        usdcMixers[_ind].totalDeposits = usdcMixers[_ind].totalDeposits.add(amount); // Add to the deposit amount
        usdcMixers[_ind].depositSinceWithdraw = usdcMixers[_ind].depositSinceWithdraw.add(1); // Total deposits since withdraw
    }
    
    function depositUSDT(bytes32 _commitment, uint256 amount) external {
        require(amount == usdtMixers[0].denomination || amount == usdtMixers[1].denomination, "Can only deposit either 100 or 1000 USDT");
        uint256 _ind = 0; // 100 Pool
        if(amount == usdtMixers[1].denomination){
            _ind = 1; // Set to 1000 Pool
        }
        usdtMixers[_ind].token.safeTransferFrom(_msgSender(), address(this), amount); // Pull from the user
        usdtMixers[_ind].token.safeApprove(address(usdtMixers[_ind].mixer), amount); // Approve the USDT here to send to Tornado
        usdtMixers[_ind].mixer.deposit(_commitment); // Now deposit the USDT
        usdtMixers[_ind].lastDeposit = now; // Metrics, last deposit time
        usdtMixers[_ind].totalDeposits = usdtMixers[_ind].totalDeposits.add(amount); // Add to the deposit amount
        usdtMixers[_ind].depositSinceWithdraw = usdtMixers[_ind].depositSinceWithdraw.add(1); // Total deposits since withdraw
    }
    
    // Withdraw functions
    function withdrawDAI(bytes calldata _proof, uint256 amount, bytes32 _root, 
                        bytes32 _nullifierHash, address payable _recipient, 
                        address payable _relayer, uint256 _fee, uint256 _refund) external payable {
                            // The user can send ETH to the recipient
                            require(amount == daiMixers[0].denomination || amount == daiMixers[1].denomination, "Can only withdraw either 100 or 1000 DAI");
                            require(_relayer == address(this), "The relayer must be this contract");
                            uint256 _ind = 0; // 100 Pool
                            if(amount == daiMixers[1].denomination){
                                _ind = 1; // Set to 1000 Pool
                            }
                            // This address should now have the fee
                            uint256 gasCharge = minStablecoinFee.mul(10**daiMixers[_ind].decimals); // Get gas fee in base units
                            require(_fee >= gasCharge, "Fee not enough to pay for minimum fee of 10 tokens");
                            daiMixers[_ind].mixer.withdraw{value: msg.value}(_proof, _root, _nullifierHash, _recipient, _relayer, _fee, _refund); // Now withdraw the DAI
                            _fee = _fee.sub(gasCharge); // The gas charge goes directly to the message sender
                            uint256 treasuryFee = _fee.div(2); // Treasury takes half the withdraw fee
                            _fee = _fee.sub(treasuryFee);
                            daiMixers[_ind].token.safeTransfer(_msgSender(), _fee.add(gasCharge)); // The message sender gets half the fee plus gas charge
                            daiMixers[_ind].token.safeTransfer(treasuryAddress,treasuryFee);
                            daiMixers[_ind].totalDeposits = daiMixers[_ind].totalDeposits.sub(amount); // Take away from deposits
                            daiMixers[_ind].depositSinceWithdraw = 0; // Reset withdraws
                        }
                        
    function withdrawUSDC(bytes calldata _proof, uint256 amount, bytes32 _root, 
                        bytes32 _nullifierHash, address payable _recipient, 
                        address payable _relayer, uint256 _fee, uint256 _refund) external payable {
                            // The user can send ETH to the recipient
                            require(amount == usdcMixers[0].denomination || amount == usdcMixers[1].denomination, "Can only withdraw either 100 or 1000 USDC");
                            require(_relayer == address(this), "The relayer must be this contract");
                            uint256 _ind = 0; // 100 Pool
                            if(amount == usdcMixers[1].denomination){
                                _ind = 1; // Set to 1000 Pool
                            }
                            // This address should now have the fee
                            uint256 gasCharge = minStablecoinFee.mul(10**usdcMixers[_ind].decimals); // Get gas fee in base units
                            require(_fee >= gasCharge, "Fee not enough to pay for minimum fee of 10 tokens");
                            usdcMixers[_ind].mixer.withdraw{value: msg.value}(_proof, _root, _nullifierHash, _recipient, _relayer, _fee, _refund); // Now withdraw the USDC
                            _fee = _fee.sub(gasCharge); // The gas charge goes directly to the message sender
                            uint256 treasuryFee = _fee.div(2); // Treasury takes half the withdraw fee
                            _fee = _fee.sub(treasuryFee);
                            usdcMixers[_ind].token.safeTransfer(_msgSender(), _fee.add(gasCharge)); // The message sender gets half the fee plus gas charge
                            usdcMixers[_ind].token.safeTransfer(treasuryAddress,treasuryFee);
                            usdcMixers[_ind].totalDeposits = usdcMixers[_ind].totalDeposits.sub(amount); // Take away from deposits
                            usdcMixers[_ind].depositSinceWithdraw = 0; // Reset withdraws
                        }
                        
    function withdrawUSDT(bytes calldata _proof, uint256 amount, bytes32 _root, 
                        bytes32 _nullifierHash, address payable _recipient, 
                        address payable _relayer, uint256 _fee, uint256 _refund) external payable {
                            // The user can send ETH to the recipient
                            require(amount == usdtMixers[0].denomination || amount == usdtMixers[1].denomination, "Can only withdraw either 100 or 1000 USDT");
                            require(_relayer == address(this), "The relayer must be this contract");
                            uint256 _ind = 0; // 100 Pool
                            if(amount == usdtMixers[1].denomination){
                                _ind = 1; // Set to 1000 Pool
                            }
                            // This address should now have the fee
                            uint256 gasCharge = minStablecoinFee.mul(10**usdtMixers[_ind].decimals); // Get gas fee in base units
                            require(_fee >= gasCharge, "Fee not enough to pay for minimum fee of 10 tokens");
                            usdtMixers[_ind].mixer.withdraw{value: msg.value}(_proof, _root, _nullifierHash, _recipient, _relayer, _fee, _refund); // Now withdraw the USDT
                            _fee = _fee.sub(gasCharge); // The gas charge directly to the message sender
                            uint256 treasuryFee = _fee.div(2); // Treasury takes half the withdraw fee
                            _fee = _fee.sub(treasuryFee);
                            usdtMixers[_ind].token.safeTransfer(_msgSender(), _fee.add(gasCharge)); // The message sender gets half the fee plus gas charge
                            usdtMixers[_ind].token.safeTransfer(treasuryAddress,treasuryFee);
                            usdtMixers[_ind].totalDeposits = usdtMixers[_ind].totalDeposits.sub(amount); // Take away from deposits
                            usdtMixers[_ind].depositSinceWithdraw = 0; // Reset withdraws
                        }                        

    // Governance functions
    // Timelock variables
    
    uint256 private _timelockStart; // The start of the timelock to change governance variables
    uint256 private _timelockType; // The function that needs to be changed
    uint256 constant _timelockDuration = 86400; // Timelock is 24 hours
    
    // Reusable timelock variables
    address private _timelock_address;
    
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
}