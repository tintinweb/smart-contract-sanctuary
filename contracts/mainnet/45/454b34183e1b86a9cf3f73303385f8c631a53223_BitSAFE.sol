/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

// SPDX-License-Identifier: MIT
// @dev Telegram: defi_guru
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
    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
}


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function sync() external;
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
}

library SafeCast {

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }
    
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

contract BitSAFE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeCast for int256;
  
    string private _name = "BitSAFE";
    string private _symbol = "SAFE";
    uint8 private _decimals = 5;

    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _tokenBalance;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal _tokenTotal = 10_000_000_000e5;
    uint256 internal _reflectionTotal = (MAX - (MAX % _tokenTotal));

    mapping(address => bool) isTaxless;
    mapping(address => bool) internal _isExcluded;
    address[] internal _excluded;
        
    //all fees
    uint256 public feeDecimal = 2;
    uint256 public teamFee = 250;
    uint256 public liquidityFee = 250;
   
    uint256 public feeTotal;

    address public teamWallet;
    address public interestWallet;
    IERC20 public v1Token;
    
    mapping(address => uint256) public claimCount;
    mapping(address => uint256) public lastClaimed;
    mapping(address => uint256) public amountPerClaim;
    bool public claimEnabled = true;

    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public isFeeActive = true; // should be true
    
    uint256 public maxTxAmount = _tokenTotal.div(1000);// 0.1%
    uint256 public maxPriceImpact = 200; // 2%
    uint256 public minTokensBeforeSwap = 100_000e5;
    
    bool public cooldownEnabled = true;
    
    mapping(address => uint256) public sellCooldown;
    mapping(address => uint256) public buyCooldown;
    mapping(address => uint256) public sellCount;
    mapping(address => uint256) public sellCooldownStart;

    uint256 public buyCooldownTime = 2 minutes;
    uint256[] public sellCooldownTimes;
    uint256 public sellCooldownPeriod = 1 days;
    
    uint256 public lastRewardAt = block.timestamp;

    bool public p2pTaxEnabled = false;

    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;
    
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived, uint256 tokensIntoLiqudity);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() public {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap Router For Ethereum

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
            
        uniswapV2Router = _uniswapV2Router;
        
        address _owner = 0xe6d8Ee28600AD59999028009Fc2055789152d882;
        teamWallet = 0x72C8E1588F1B96a0A8495cC2035A6eDaaDBB1726;
        interestWallet = 0xC3AecD2a92e12A0F7597A7e4d4EdC2fC7fa53Bf7;
        address teamWalletCoin = 0xaF40c8123c9149878bcef9A9Fb0B0b4AebF37981;
        v1Token = IERC20(0xDD63603BFb128f184242B5A8541E9fDf3EB4B20b);

        isTaxless[_owner] = true;
        isTaxless[address(this)] = true;
        isTaxless[teamWallet] = true;
        isTaxless[teamWalletCoin] = true;
        isTaxless[interestWallet] = true;

        sellCooldownTimes.push(1 hours);
        sellCooldownTimes.push(2 hours);
        sellCooldownTimes.push(6 hours);
        sellCooldownTimes.push(sellCooldownPeriod);

        _isExcluded[uniswapV2Pair] = true;
        _excluded.push(uniswapV2Pair);
       
        _isExcluded[interestWallet] = true;
        _excluded.push(interestWallet);
        
         _isExcluded[teamWalletCoin] = true;
        _excluded.push(teamWalletCoin);
        
        _isExcluded[_owner] = true;
        _excluded.push(_owner);

        uint256 interestBalance = reflectionFromToken(300_000_000e5);
        _reflectionBalance[interestWallet] = interestBalance;
        _tokenBalance[interestWallet] = _tokenBalance[interestWallet].add(300_000_000e5);
        emit Transfer(address(0), interestWallet, 300_000_000e5);
        
        uint256 teamCoinsBal = reflectionFromToken(500_000_000e5);
        _reflectionBalance[teamWalletCoin] = teamCoinsBal;
        _tokenBalance[teamWalletCoin] = _tokenBalance[teamWalletCoin].add(500_000_000e5);
        emit Transfer(address(0), teamWalletCoin, 500_000_000e5);
        
        _reflectionBalance[_owner] = _reflectionTotal.sub(interestBalance).sub(teamCoinsBal);
        _tokenBalance[_owner] = _tokenBalance[_owner].add(_tokenTotal.sub(800_000_000e5));
        emit Transfer(address(0), _owner, _tokenTotal.sub(800_000_000e5));
        
        transferOwnership(_owner);
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

    function totalSupply() public override view returns (uint256) {
        return _tokenTotal;
    }

    function balanceOf(address account) public override view returns (uint256) {
        if (_isExcluded[account]) return _tokenBalance[account];
        return tokenFromReflection(_reflectionBalance[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        virtual
        returns (bool)
    {
       _transfer(_msgSender(),recipient,amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override virtual returns (bool) {
        _transfer(sender,recipient,amount);
               
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub( amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tokenAmount)
        public
        view
        returns (uint256)
    {
        require(tokenAmount <= _tokenTotal, "Amount must be less than supply");
        return tokenAmount.mul(_getReflectionRate());
    }

    function tokenFromReflection(uint256 reflectionAmount)
        public
        view
        returns (uint256)
    {
        require(
            reflectionAmount <= _reflectionTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getReflectionRate();
        return reflectionAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(
            account != address(uniswapV2Router),
            "TOKEN: We can not exclude Uniswap router."
        );
        
        require(!_isExcluded[account], "TOKEN: Account is already excluded");
        if (_reflectionBalance[account] > 0) {
            _tokenBalance[account] = tokenFromReflection(
                _reflectionBalance[account]
            );
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "TOKEN: Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tokenBalance[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        require(
            isTaxless[sender] || isTaxless[recipient] || 
            (amount <= maxTxAmount && amount <= balanceOf(uniswapV2Pair).mul(maxPriceImpact).div(10**(feeDecimal + 2))),
            "Max Transfer Limit Exceeds!");
        
        uint256 transferAmount = amount;
        uint256 rate = _getReflectionRate();
        
        //swapAndLiquify
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 teamBal = balanceOf(teamWallet);
        if (!inSwapAndLiquify && sender != uniswapV2Pair && swapAndLiquifyEnabled) {
            if(contractTokenBalance >= minTokensBeforeSwap)
                swapAndLiquify(contractTokenBalance);
            else if(teamBal >= minTokensBeforeSwap) {
                _reflectionBalance[teamWallet] = _reflectionBalance[teamWallet].sub(teamBal.mul(rate));
                _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(teamBal.mul(rate));
                distributeTeam(teamBal);
            }
        }
        
        if(isFeeActive && !isTaxless[sender] && !isTaxless[recipient] && !inSwapAndLiquify) {
            transferAmount = collectFee(sender,recipient,amount,rate);
        }

        //transfer reflection
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(amount.mul(rate));
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(transferAmount.mul(rate));

        //if any account belongs to the excludedAccount transfer token
        if (_isExcluded[sender]) {
            _tokenBalance[sender] = _tokenBalance[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tokenBalance[recipient] = _tokenBalance[recipient].add(transferAmount);
        }

        emit Transfer(sender, recipient, transferAmount);
    }
    
    function validateTradeAndGetFee(address from, address to) private returns(uint256, uint256) {
        // only use Cooldown when buying/selling on exchange
        if(!cooldownEnabled || (from != uniswapV2Pair && to != uniswapV2Pair)) 
            return p2pTaxEnabled ? (teamFee, liquidityFee) : (0,0);
        
        if(to != uniswapV2Pair && !isTaxless[to]) {
            require(buyCooldown[to] <= block.timestamp, "Err: Buy Cooldown");
            buyCooldown[to] = block.timestamp + buyCooldownTime;
        }

        uint256 _teamFee = teamFee;
        uint256 _liquidityFee = liquidityFee;

        if(from != uniswapV2Pair && !isTaxless[from]) {
            require(sellCooldown[from] <= block.timestamp, "Err: Sell Cooldown");
            
            if(sellCooldownStart[from] + sellCooldownPeriod < block.timestamp) {
                sellCount[from] = 0;
                sellCooldownStart[from] = block.timestamp;
            }
          
            for(uint256 i = 0; i < sellCooldownTimes.length; i++) {
                if(sellCount[from] == i) {
                    sellCount[from]++;
                    sellCooldown[from] = block.timestamp + sellCooldownTimes[i];
                    _teamFee = teamFee.mul(i == 0 ? 1 : i + 3);
                    _liquidityFee = liquidityFee.mul(i == 0 ? 1 : i + 3);
                    if(sellCooldownTimes.length == i + 1) sellCooldown[from] = sellCooldownStart[from] + sellCooldownPeriod;
                    break;
                }
            }
        }
        return (_teamFee, _liquidityFee);
    }
    
    function collectFee(address account, address to, uint256 amount, uint256 rate) private returns (uint256) {
        uint256 transferAmount = amount;
        
        (uint256 __teamFee , uint256 __liquidityFee) = validateTradeAndGetFee(account, to);
  
        //take liquidity fee
        if(__liquidityFee != 0){
            uint256 _liquidityFee = amount.mul(__liquidityFee).div(10**(feeDecimal + 2));
            transferAmount = transferAmount.sub(_liquidityFee);
            _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(_liquidityFee.mul(rate));
            if (_isExcluded[address(this)]) {
                _tokenBalance[address(this)] = _tokenBalance[address(this)].add(_liquidityFee);
            }
            feeTotal = feeTotal.add(_liquidityFee);
            emit Transfer(account,address(this),_liquidityFee);
        }
        
        //take team fee
        if(__teamFee != 0){
            uint256 _teamFee = amount.mul(__teamFee).div(10**(feeDecimal + 2));
            transferAmount = transferAmount.sub(_teamFee);
            _reflectionBalance[teamWallet] = _reflectionBalance[teamWallet].add(_teamFee.mul(rate));
            if (_isExcluded[teamWallet]) {
                _tokenBalance[teamWallet] = _tokenBalance[teamWallet].add(_teamFee);
            }
            feeTotal = feeTotal.add(_teamFee);
            emit Transfer(account,teamWallet,_teamFee);
        }

        return transferAmount;
    }

    function _getReflectionRate() private view returns (uint256) {
        uint256 reflectionSupply = _reflectionTotal;
        uint256 tokenSupply = _tokenTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _reflectionBalance[_excluded[i]] > reflectionSupply ||
                _tokenBalance[_excluded[i]] > tokenSupply
            ) return _reflectionTotal.div(_tokenTotal);
            reflectionSupply = reflectionSupply.sub(
                _reflectionBalance[_excluded[i]]
            );
            tokenSupply = tokenSupply.sub(_tokenBalance[_excluded[i]]);
        }
        if (reflectionSupply < _reflectionTotal.div(_tokenTotal))
            return _reflectionTotal.div(_tokenTotal);
        return reflectionSupply.div(tokenSupply);
    }
    
     function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
         if(contractTokenBalance > maxTxAmount)
            contractTokenBalance = maxTxAmount;
            
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

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
   
    function distributeTeam(uint256 amount) private lockTheSwap {
        swapTokensForEth(amount);
        payable(teamWallet).transfer(address(this).balance);
    }
   
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    
    function claimTokens() external {
        require(claimEnabled, "Claimed Period Ended!");
        address sender = interestWallet;
        address recipient = msg.sender;
        if(claimCount[msg.sender] == 0) {
            uint256 bal = v1Token.balanceOf(recipient);
            require(bal > 0, "No claim available!");
            amountPerClaim[msg.sender] = bal.mul(20).div(100);
            v1Token.transferFrom(msg.sender,address(0x000000000000000000000000000000000000dEaD),bal);
        }
        require(claimCount[msg.sender] < 5, "Already claimed!");
        require(lastClaimed[msg.sender] + 7 days < block.timestamp ,"Claim too soon!");
        uint256 amount = amountPerClaim[msg.sender];
        uint256 rate = _getReflectionRate();
        //transfer reflection
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(amount.mul(rate));
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(amount.mul(rate));

        //if any account belongs to the excludedAccount transfer token
        if (_isExcluded[sender]) {
            _tokenBalance[sender] = _tokenBalance[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tokenBalance[recipient] = _tokenBalance[recipient].add(amount);
        }
        emit Transfer(sender,recipient,amount);
        claimCount[msg.sender]++;
        lastClaimed[msg.sender] = block.timestamp;
    }
    
    function rewardHolders(uint256 amount) external onlyOwner {
        uint256 reward = 25_000_000e5;
        if(amount != 0) reward = amount;
        if (_isExcluded[interestWallet]) {
            _tokenBalance[interestWallet] = _tokenBalance[interestWallet].sub(reward);
        }
        uint256 rate = _getReflectionRate();
        _reflectionBalance[interestWallet] = _reflectionBalance[interestWallet].sub(reward.mul(rate));
        _reflectionTotal = _reflectionTotal.sub(reward.mul(rate));
        feeTotal = feeTotal.add(reward);
        emit Transfer(interestWallet,address(this),reward);
        lastRewardAt = block.timestamp;
    }
    
    function deliver(uint256 amount) external {
        require(!_isExcluded[msg.sender],'Excluded cannot call this!');
        uint256 rate = _getReflectionRate();
        _reflectionBalance[msg.sender] = _reflectionBalance[msg.sender].sub(amount.mul(rate));
        _reflectionTotal = _reflectionTotal.sub(amount.mul(rate));
        feeTotal = feeTotal.add(amount);
        emit Transfer(msg.sender,address(this),amount);
    }
    
    function setClaimEnabled(bool value) external onlyOwner {
        claimEnabled = value;
    }

    function setTaxless(address account, bool value) external onlyOwner {
        isTaxless[account] = value;
    }
    
    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner {
        swapAndLiquifyEnabled = enabled;
        SwapAndLiquifyEnabledUpdated(enabled);
    }
    
    function setFeeActive(bool value) external onlyOwner {
        isFeeActive = value;
    }
    
    function setTeamFee(uint256 fee) external onlyOwner {
        teamFee = fee;
    }
    
    function setLiquidityFee(uint256 fee) external onlyOwner {
        liquidityFee = fee;
    }
    
    function setTeamWallet(address wallet) external onlyOwner {
        teamWallet = wallet;
    }
    
    function setInterestWallet(address wallet) external onlyOwner {
        interestWallet = wallet;
    }
    
    function setMaxTransferAndPriceImpact(uint256 maxAmount, uint256 maxImpact) external onlyOwner {
        maxTxAmount = maxAmount;
        maxPriceImpact = maxImpact;
    }
    
    function setMinTokensBeforeSwap(uint256 amount) external onlyOwner {
        minTokensBeforeSwap = amount;
    }
    
    function setCooldonwEnabled(bool value) external onlyOwner {
        cooldownEnabled = value;
    }
    
    function setBuyCooldown(uint256 cooldown) external onlyOwner {
        minTokensBeforeSwap = cooldown;
    }
    
    function setSellCooldown(uint256 cooldownPeriod, uint256[] memory sellTimes) external onlyOwner {
        sellCooldownPeriod = cooldownPeriod;
        sellCooldownTimes = sellTimes;
    }
    
    function setP2pTaxEnabled(bool value) external onlyOwner {
        p2pTaxEnabled = value;
    }
   
    receive() external payable {}
}