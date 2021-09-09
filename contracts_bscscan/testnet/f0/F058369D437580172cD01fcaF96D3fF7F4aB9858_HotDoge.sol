/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

/*

With a dynamic sell limit based on price impact and increasing sell cooldowns and redistribution taxes on consecutive sells, HotDoge v2 block bots and discourage dumping.

- Token Information
Sell cooldown increases on consecutive sells, 3 sells within a 4 hours period are allowed

Sell restriction ( Protect liquidity ) - 1x fee on the first sell, increases 2x, 3x on consecutive sells

Fee Percentages
1. 1.50% Diamond Hand Corporate Development
2. 1.50% Vip Programs
3. 3.00% HOTDOGE Reflection (auto)
4. 3.00% Astro Buyback
5. 1.50% Treats Bot
6. 2.00% Marketing
7. 2.50% Liquidity

total: 15%

Supply 1,000,000,000,000,000 (1 quadrillion)

SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.4;

/**
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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


///////// PancakeSwap Interfaces ///////////

interface IPancakeswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


interface IPancakeswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

}

interface IPancakeswapV2Router02 is IPancakeswapV2Router01 {
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


contract HotDoge is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10**15 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tRewardTotal;

    string private _name = "HotDoge TEST V3";
    string private _symbol = "HOTDOGE555";
    uint8 private _decimals = 18;
    
    // Fees 15%
    uint256 private _totalFee = 1500;
    uint256 private _previousTotalFee = _totalFee;

    uint256 private _diamondFee = 150;
    uint256 private _previousDiamondFee = _diamondFee;

    uint256 private _vipFee = 150;
    uint256 private _previousVipFee = _vipFee;

    uint256 private _rewardFee = 300; // reflection fee
    uint256 private _previousRewardFee = _rewardFee;

    uint256 private _astroBuyBackFee = 300;
    uint256 private _previousAstroBuyBackFee = _astroBuyBackFee;

    uint256 private _marketingFee = 200;
    uint256 private _previousMarketingFee = _marketingFee;

    uint256 private _volunteerFee = 150;
    uint256 private _previousVolunteerFee = _volunteerFee;

    uint256 private _liquidityFee = 250;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 private _maxTxAmount = 10**14 * 10**18;
    uint256 private numTokensSellToAddToLiquidity = 4 * 10**11 * 10 ** 18;


    //Addresses
    address private _volunteerAddress = 0x4F9e768639d85EB2e569EDcb3a6e5f392D284524;
    address private _diamondHandAddress = 0x0d4cb32BDE8125422927010D23c3E9bc32F0bE77;
    address private _vipAddress = 0xD635793aeA59bE35a04e1E61F5761f4A9305408b;
    address private _marketingAddress = 0x88eB1507Ee468eaA3f73Ec91a74A6B962E4DB33C;
    address private _liquidityAddress = 0xF2F4E0cD8FaC460Aa5aC4a2df6C234E8d83A28f1;
    address private _astroBuyBackAddress = 0x41F71eFb2a6c7ce78b8bf27BfcBe7fB4595F797C;

    mapping(address => bool) private _teamAddresses; // team wallet check list

    // Wallets
    address payable _volunteerWallet;
    address payable _diamondHandWallet;
    address payable _vipWallet;
    address payable _marketingWallet;
    address payable _liquidityWallet;
    address payable _astroBuyBackWallet;

    // Mappings
    mapping(address => bool) private bots; // bots blacklist
    mapping(address => uint256) private buycooldown; // buy cooldown time - 30 minutes
    mapping(address => uint256) private sellcooldown;  // sell cooldown time - 1 hour, 2 hours, 4 hours
    mapping(address => uint256) private firstsell; // first sell time
    mapping(address => uint256) private sellnumber;  // calculate consecutive sells

    IPancakeswapV2Router02 private pancakeswapV2Router;
    address private pancakeswapV2Pair;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) private automatedMarketMakerPairs;
    
    bool inSwapping;
    bool private swapAndLiquifyEnabled = true;
    bool private tradeEnabled = true;
    bool private cooldownEnabled = false;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapping = true;
        _;
        inSwapping = false;
    }
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;        
        
        // IPancakeswapV2Router02 _pancakeswapV2Router = IPancakeswapV2Router02(); // mainnet router
        IPancakeswapV2Router02 _pancakeswapV2Router = IPancakeswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // testnet router
        // Create a pancakeswap pair for this new token
        pancakeswapV2Pair = IPancakeswapV2Factory(_pancakeswapV2Router.factory()).createPair(address(this), _pancakeswapV2Router.WETH());

        // set the rest of the contract variables
        pancakeswapV2Router = _pancakeswapV2Router;

        _setAutomatedMarketMakerPair(pancakeswapV2Pair, true);
        
        //exclude owner, this contract, hero pool from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_volunteerAddress] = _teamAddresses[_volunteerAddress] = true;
        _isExcludedFromFee[_diamondHandAddress] = _teamAddresses[_diamondHandAddress] = true;
        _isExcludedFromFee[_vipAddress] = _teamAddresses[_vipAddress] = true;
        _isExcludedFromFee[_marketingAddress] = _teamAddresses[_marketingAddress] = true;
        _isExcludedFromFee[_liquidityAddress] = _teamAddresses[_liquidityAddress] = true;
        _isExcludedFromFee[_astroBuyBackAddress] = _teamAddresses[_astroBuyBackAddress] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalRewards() public view returns (uint256) {
        return _tRewardTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tRewardTotal = _tRewardTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferReward) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferReward) {
            (uint256 rAmount,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
    

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Pancakeswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
        _previousLiquidityFee = _liquidityFee;
    }

    function setRewardFeePercent(uint256 rewardFee) external onlyOwner() {
        _rewardFee = rewardFee;
        _previousRewardFee = _rewardFee;
    }

    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner() {
        _marketingFee = marketingFee;
        _previousMarketingFee = _marketingFee;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setTradeEnabled(bool _enabled) external onlyOwner {
        tradeEnabled = _enabled;
    }

    function setCooldownEnabled(bool _enabled) external onlyOwner {
        cooldownEnabled = _enabled;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != pancakeswapV2Pair, "HERO: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "HERO: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
    }
    
    // to recieve ETH from pancakeswapV2Router when swaping
    receive() external payable {}

    function _reflectReward(uint256 rReward, uint256 tReward) private {
        _rTotal = _rTotal.sub(rReward);
        _tRewardTotal = _tRewardTotal.add(tReward);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tTotalFeeAmount) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount) = _getRValues(tAmount, tTotalFeeAmount, _getRate());
        return (rAmount, rTransferAmount, tTransferAmount);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tTotalFeeAmount = calculateTotalFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tTotalFeeAmount);
        return (tTransferAmount, tTotalFeeAmount);
    }

    function _getRValues(uint256 tAmount, uint256 tTotalFeeAmount, uint256 currentRate) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTotalFeeAmount = tTotalFeeAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTotalFeeAmount);
        return (rAmount, rTransferAmount);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeDiamondHand(uint256 tAmount, uint256 currentRate) private {
        uint256 tDiamond = calculateDiamondFee(tAmount);
        uint256 rDiamond = tDiamond.mul(currentRate);
        _rOwned[_diamondHandAddress] = _rOwned[_diamondHandAddress].add(rDiamond);
        if(_isExcluded[_diamondHandAddress])
            _tOwned[_diamondHandAddress] = _tOwned[_diamondHandAddress].add(tDiamond);
    }

    function _takeVip(uint256 tAmount, uint256 currentRate) private {
        uint256 tVip = calculateVipFee(tAmount);
        uint256 rVip = tVip.mul(currentRate);
        _rOwned[_vipAddress] = _rOwned[_vipAddress].add(rVip);
        if(_isExcluded[_vipAddress])
            _tOwned[_vipAddress] = _tOwned[_vipAddress].add(tVip);
    }

    function _takeVolunteer(uint256 tAmount, uint256 currentRate) private {
        uint256 tVolunteer = calculateVolunteerFee(tAmount);
        uint256 rVolunteer = tVolunteer.mul(currentRate);
        _rOwned[_volunteerAddress] = _rOwned[_volunteerAddress].add(rVolunteer);
        if(_isExcluded[_volunteerAddress])
            _tOwned[_volunteerAddress] = _tOwned[_volunteerAddress].add(tVolunteer);
    }

    function _takeBuyBack(uint256 tAmount, uint256 currentRate) private {
        uint256 tBuyBack = calculateBuyBackFee(tAmount);
        uint256 rBuyBack = tBuyBack.mul(currentRate);
        _rOwned[_astroBuyBackAddress] = _rOwned[_astroBuyBackAddress].add(rBuyBack);
        if(_isExcluded[_astroBuyBackAddress])
            _tOwned[_astroBuyBackAddress] = _tOwned[_astroBuyBackAddress].add(tBuyBack);
    }
    
    function _takeLiquidity(uint256 tAmount, uint256 currentRate) private {
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[_liquidityAddress] = _rOwned[_liquidityAddress].add(rLiquidity);
        if(_isExcluded[_liquidityAddress])
            _tOwned[_liquidityAddress] = _tOwned[_liquidityAddress].add(tLiquidity);
    }

    function _takeMarketing(uint256 tAmount, uint256 currentRate) private {
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 rMarketing = tMarketing.mul(currentRate);

        _rOwned[_marketingAddress] = _rOwned[_marketingAddress].add(rMarketing);
        if(_isExcluded[address(this)])
            _tOwned[_marketingAddress] = _tOwned[_marketingAddress].add(tMarketing);
    }
    
    function calculateRewardFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_rewardFee).div(
            10**4
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**4
        );
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFee).div(
            10**4
        );
    }

    function calculateVipFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_vipFee).div(
            10**4
        );
    }

    function calculateDiamondFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_diamondFee).div(
            10**4
        );
    }

    function calculateVolunteerFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_volunteerFee).div(
            10**4
        );
    }

    function calculateBuyBackFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_astroBuyBackFee).div(
            10**4
        );
    }

    function calculateTotalFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_totalFee).div(
            10**4
        );
    }
    
    function removeAllFee() private {
        if(_rewardFee == 0 && _diamondFee == 0 && _liquidityFee == 0 && _marketingFee == 0 && _astroBuyBackFee == 0 && _volunteerFee == 0 && _vipFee == 0) return;
        
        // _previousRewardFee = _rewardFee;
        // _previousLiquidityFee = _liquidityFee;
        // _previousMarketingFee = _marketingFee;
        // _previousDiamondFee = _diamondFee;
        // _previousVolunteerFee = _volunteerFee;
        // _previousVipFee = _vipFee;
        
        _rewardFee = 0;
        _liquidityFee = 0;
        _marketingFee = 0;
        _diamondFee = 0;
        _volunteerFee = 0;
        _vipFee = 0;
        _astroBuyBackFee = 0;

        _previousTotalFee = _totalFee;
        _totalFee = 0;
    }
    
    function restoreAllFee() private {
        _rewardFee = _previousRewardFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
        _diamondFee = _previousDiamondFee;
        _volunteerFee = _previousVolunteerFee;
        _vipFee = _previousVipFee;
        _astroBuyBackFee = _previousAstroBuyBackFee;

        _totalFee = _previousTotalFee;
    }

    function setMultiFee(uint256 multiplier) private {
        _rewardFee = _previousRewardFee.mul(multiplier);
        _liquidityFee = _previousLiquidityFee.mul(multiplier);
        _diamondFee = _previousDiamondFee.mul(multiplier);
        _vipFee = _previousVipFee.mul(multiplier);
        _astroBuyBackFee = _previousAstroBuyBackFee.mul(multiplier);
        _volunteerFee = _previousVolunteerFee.mul(multiplier);
        _marketingFee = _previousMarketingFee.mul(multiplier);
        _totalFee = _previousTotalFee.mul(multiplier);
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to pancakeswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();

        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // make the swap
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // add the liquidity
        pancakeswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );

        swapAndLiquifyEnabled = true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancakeswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapping &&
            from != pancakeswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            // uint256 liquidityBalance = contractTokenBalance.mul(_).div(100);
            // swapAndLiquify(liquidityBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        if (takeFee && to == pancakeswapV2Pair) {
            require(sellcooldown[from] < block.timestamp, "Cooldown time is not yet.");

            if((firstsell[from] + (4 hours)) < block.timestamp){
                sellnumber[from] = 0;
            }

            if (sellnumber[from] == 0) {
                sellnumber[from]++;
                firstsell[from] = block.timestamp;
                sellcooldown[from] = block.timestamp + (1 hours);
            }
            else if (sellnumber[from] == 1) {
                sellnumber[from]++;
                sellcooldown[from] = block.timestamp + (2 hours);
            }
            else if (sellnumber[from] == 2) {
                sellnumber[from]++;
                sellcooldown[from] = block.timestamp + (4 hours);
            }

            setMultiFee(sellnumber[from]);
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();        
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount) = _getValues(tAmount);
        uint256 currentRate = _getRate();
        uint256 tReward = calculateRewardFee(tAmount);
        uint256 rReward = tReward.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeDiamondHand(tAmount, currentRate);
        _takeVip(tAmount, currentRate);
        _takeBuyBack(tAmount, currentRate);
        _takeVolunteer(tAmount, currentRate);
        _takeMarketing(tAmount, currentRate);
        _takeLiquidity(tAmount, currentRate);        
        _reflectReward(rReward, tReward);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount) = _getValues(tAmount);
        uint256 currentRate = _getRate();
        uint256 tReward = calculateRewardFee(tAmount);
        uint256 rReward = tReward.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeDiamondHand(tAmount, currentRate);
        _takeVip(tAmount, currentRate);
        _takeBuyBack(tAmount, currentRate);
        _takeVolunteer(tAmount, currentRate);
        _takeMarketing(tAmount, currentRate);
        _takeLiquidity(tAmount, currentRate);
        _reflectReward(rReward, tReward);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount) = _getValues(tAmount);
        uint256 currentRate = _getRate();
        uint256 tReward = calculateRewardFee(tAmount);
        uint256 rReward = tReward.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeDiamondHand(tAmount, currentRate);
        _takeVip(tAmount, currentRate);
        _takeBuyBack(tAmount, currentRate);
        _takeVolunteer(tAmount, currentRate);
        _takeMarketing(tAmount, currentRate);
        _takeLiquidity(tAmount, currentRate);
        _reflectReward(rReward, tReward);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount) = _getValues(tAmount);
        uint256 currentRate = _getRate();
        uint256 tReward = calculateRewardFee(tAmount);
        uint256 rReward = tReward.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeDiamondHand(tAmount, currentRate);
        _takeVip(tAmount, currentRate);
        _takeBuyBack(tAmount, currentRate);
        _takeVolunteer(tAmount, currentRate);
        _takeMarketing(tAmount, currentRate);
        _takeLiquidity(tAmount, currentRate);
        _reflectReward(rReward, tReward);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}