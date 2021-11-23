/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

// SPDX-License-Identifier: MIT
// @dev Telegram: defi_guru
pragma solidity >0.8.0 <0.9.0;

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
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
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
}


abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, 'sorry humans only');
        _;
    }
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

contract Eooshi is Context, IERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using TransferHelper for address;

    string private _name = 'Eooshi';
    string private _symbol = 'Eooshi';
    uint8 private _decimals = 18;
    address private constant blackHoleAddress = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _tokenBalance;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal _tokenTotal = 10_000_000_000_000e18;
    uint256 internal _reflectionTotal = (MAX - (MAX % _tokenTotal));
    uint256 internal _initialUse = 50_000_000e18;

    mapping(address => bool) isTaxless;
    mapping(address => bool) internal _isExcluded;
    address[] internal _excluded;

    uint256 public rewardCycleInterval;
    mapping(address => uint256) public nextAvailableClaimDate;

    uint256 public _feeDecimal = 2;
    // index 0 = buy fee, index 1 = sell fee, index 2 = p2p fee
    uint256[] public _taxFee;
    uint256[] public _rewardFee;
    uint256[] public _liqFee;
    uint256[] public _charityFee;
    uint256[] public _inviteFee;
    uint256[] public _parentInviteFee;
    uint256[] public _stakeHolderFee;

    uint256 internal _feeTotal;
    uint256 internal _rewardFeeCollected;
    uint256 internal _liqFeeCollected;
    uint256 internal _charityFeeCollected;
    uint256 internal _stackholderFeeCollected;

    bool public isFeeActive = true; // should be true
    bool private inSwap;
    bool public swapEnabled = true;

    uint256 public maxTxAmount = _tokenTotal.mul(1).div(100); // 1%
    uint256 public minTokensBeforeSwap = 1_000_000e18;

    address public charityWallet;

    address public rewardToken;
    mapping(address => uint256) public lastbuy;

    mapping(address=>address) public invitees;
    mapping(address=>address[]) public invited;
    uint256 public totalPower;
    mapping(address=>uint256) addressPower;

    IUniswapV2Router02 public router;
    address public pair;

    // stackholder
    address[] public stackholders;
    uint256 public maxStackholderCount;
    mapping(address=>bool) public isStackholder;

    mapping(address=>bool) public accountActivated;
    uint256 public activatePrice = 200_000e18;

    mapping(address=>uint256) private miningToBeTaken;
    mapping(address=>uint256) private lastMiningUpdateTimestamp;
    bool private miningStopped = false;
    // mining 1 token for 1 power every day
    uint256 private constant oneToken = 1e18;
    uint256 public tokenPerMS = oneToken.div(24).div(60).div(60);

    event SwapUpdated(bool enabled);
    event Swap(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);
    event AutoLiquify(uint256 bnbAmount, uint256 tokenAmount);
    event RewardClaimedSuccessfully(address indexed recipient, uint256 reward, uint256 nextAvailableClaimDate, uint256 timestamp);
    
    event StackholderAdded(address stackholder);
    event StackholderRemoved(address stackholder);
    event StackholderFeeBurned(uint256 amount);
    event StackhokderFeeDistributed(uint256 amount);

    event InviterSet(address owner, address inviter);
    event PowerUpdated(address owner, uint256 newPower);
    event AccountActivated(address account);

    event MiningTaken(address who, uint256 amount);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address _rewardToken, address _router, uint interval, address _charityWallet) {
        rewardCycleInterval = interval;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        router = _uniswapV2Router;
        rewardToken = _rewardToken;
        charityWallet = _charityWallet;

        isTaxless[owner()] = true;
        isTaxless[charityWallet] = true;
        isTaxless[address(this)] = true;

        excludeAccount(address(pair));
        excludeAccount(address(this));
        excludeAccount(address(charityWallet));
        excludeAccount(address(address(0)));
        excludeAccount(address(address(blackHoleAddress)));

        _reflectionBalance[owner()] = _reflectionTotal;
        emit Transfer(address(0), owner(), _tokenTotal);

        _transfer(owner(), address(this), _tokenTotal.sub(_initialUse));

        _taxFee.push(0);
        _taxFee.push(0);
        _taxFee.push(0);

        _liqFee.push(100);
        _liqFee.push(100);
        _liqFee.push(100);

        _charityFee.push(100);
        _charityFee.push(100);
        _charityFee.push(100);

        _rewardFee.push(100);
        _rewardFee.push(100);
        _rewardFee.push(100);

        _inviteFee.push(100);
        _inviteFee.push(100);
        _inviteFee.push(100);

        _parentInviteFee.push(50);
        _parentInviteFee.push(50);
        _parentInviteFee.push(50);

        _stakeHolderFee.push(50);
        _stakeHolderFee.push(50);
        _stakeHolderFee.push(50);

        maxStackholderCount = 100;
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
        return _tokenTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tokenBalance[account];
        return tokenFromReflection(_reflectionBalance[account]);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'ERC20: decreased allowance below zero')
        );
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tokenAmount) public view returns (uint256) {
        require(tokenAmount <= _tokenTotal, 'Amount must be less than supply');
        return tokenAmount.mul(_getReflectionRate());
    }

    function tokenFromReflection(uint256 reflectionAmount) public view returns (uint256) {
        require(reflectionAmount <= _reflectionTotal, 'Amount must be less than total reflections');
        uint256 currentRate = _getReflectionRate();
        return reflectionAmount.div(currentRate);
    }

    function excludeAccount(address account) public onlyOwner {
        require(account != address(router), 'ERC20: We can not exclude Uniswap router.');
        require(!_isExcluded[account], 'ERC20: Account is already excluded');
        if (_reflectionBalance[account] > 0) {
            _tokenBalance[account] = tokenFromReflection(_reflectionBalance[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner {
        require(_isExcluded[account], 'ERC20: Account is already included');
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
    function getInvitedAccountLength(address who) public view returns (uint256) {
        return invited[who].length;
    }
    function getInvitedAccountWithPaged(
        address who,
        uint256 page,
        uint256 pageCount
    ) public view returns (address[] memory) {
        uint256 invitedCount = getInvitedAccountLength(who);
        uint256 startIndex = page.mul(pageCount);
        require(
            startIndex < invitedCount,
            "getInvitedAccountWithPaged: page parameter error"
        );

        if (startIndex.add(pageCount) > invitedCount) {
            pageCount = invitedCount.sub(startIndex);
        }

        uint256 finishIndex = startIndex.add(pageCount);
        address[] memory result = new address[](pageCount);
        uint256 index = 0;
        for (uint256 i = startIndex; i < finishIndex; i++) {
            result[index++] = invited[who][i];
        }
        return result;
    }

    function setInviter(address inviter) public {
        require(invitees[msg.sender] == address(0x0), "You have already set inviter");
        require(inviter != address(0x0), "inviter address can not be 0x0");
        require(inviter != msg.sender, "You can not set inviter to yourself");
        require(accountActivated[msg.sender], "This address has not been activated yet");
        require(accountActivated[inviter], "The inviter address has not been activated yet");

        invitees[msg.sender] = inviter;
        invited[inviter].push(msg.sender);
        emit InviterSet(msg.sender, inviter);
    }

    function withdrawMining() public payable {
        require(msg.value >= 1e16 wei, "You must provide 0.01 bnb to withdraw earnings");

        _upadteMining(msg.sender);
        uint256 amount = miningToBeTaken[msg.sender];
        if (balanceOf(address(this)) < miningToBeTaken[msg.sender]) {
            amount = balanceOf(address(this));
        }
        _transfer(address(this), msg.sender, amount);
        emit MiningTaken(msg.sender, amount);

        miningToBeTaken[msg.sender] = 0;
        lastMiningUpdateTimestamp[msg.sender] = block.timestamp;
    }

    function getMiningAmount(address who) public view returns (uint256) {
        uint256 calculated = 0;
        if (!miningStopped) {
            calculated = (block.timestamp.sub(lastMiningUpdateTimestamp[who])).mul(tokenPerMS);
        }
        return calculated.add(miningToBeTaken[who]);
    }

    function _upadteMining(address who) internal {
        miningToBeTaken[who] = getMiningAmount(who);
        lastMiningUpdateTimestamp[who] = block.timestamp;
    }

    function activateAccount() public {
        require(accountActivated[msg.sender] == false, "You have already activated this account");
        require(balanceOf(msg.sender) >= activatePrice, "No enough token to activate this account");

        _transferInternal(msg.sender, blackHoleAddress, activatePrice, _getReflectionRate());
        accountActivated[msg.sender] = true;

        totalPower = totalPower.add(100_000);
        addressPower[msg.sender] = addressPower[msg.sender].add(100_000);

        miningToBeTaken[msg.sender] = 0;
        lastMiningUpdateTimestamp[msg.sender] = block.timestamp;
        emit AccountActivated(msg.sender);
        emit PowerUpdated(msg.sender, addressPower[msg.sender]);

        address inviter = invitees[msg.sender];
        if (inviter == address(0x0)) {
            return;
        }
        totalPower = totalPower.add(20_000);
        addressPower[inviter] = addressPower[inviter].add(20_000);
        _upadteMining(inviter);
        emit PowerUpdated(inviter, addressPower[inviter]);

        address parentInviter = invitees[inviter];
        if (parentInviter == address(0x0)) {
            return;
        }
        totalPower = totalPower.add(10_000);
        addressPower[parentInviter] = addressPower[parentInviter].add(10_000);
        _upadteMining(parentInviter);
        emit PowerUpdated(parentInviter, addressPower[parentInviter]);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), 'ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20: transfer to the zero address');
        require(amount > 0, 'Transfer amount must be greater than zero');

        require(isTaxless[sender] || isTaxless[recipient] || amount <= maxTxAmount, 'Max Transfer Limit Exceeds!');

        if (swapEnabled && !inSwap && sender != pair) {
            swap();
        }
        
        topUpClaimCycleAfterTransfer(sender, recipient, amount);

        uint256 transferAmount = amount;
        uint256 rate = _getReflectionRate();
        address inviter = invitees[sender];
        if (sender == pair) {
            inviter = invitees[recipient];
        }
        if (recipient == pair) {
            inviter = invitees[sender];
        }

        if (isFeeActive && !isTaxless[sender] && !isTaxless[recipient] && !inSwap) {
            transferAmount = collectFee(sender, inviter, amount, rate, recipient == pair, sender != pair && recipient != pair);
        }

        //transfer reflection
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(transferAmount.mul(rate));
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(transferAmount.mul(rate));

        //if any account belongs to the excludedAccount transfer token
        if (_isExcluded[sender]) {
            _tokenBalance[sender] = _tokenBalance[sender].sub(transferAmount);
        }
        if (_isExcluded[recipient]) {
            _tokenBalance[recipient] = _tokenBalance[recipient].add(transferAmount);
        }

        if(sender == pair) lastbuy[recipient] = block.timestamp;

        emit Transfer(sender, recipient, transferAmount);
    }

    function calculateFee(uint256 feeIndex, uint256 amount) internal returns(uint256 totalFee) {
        uint256 taxFee = amount.mul(_taxFee[feeIndex]).div(10**(_feeDecimal + 2));
        uint256 liqFee = amount.mul(_liqFee[feeIndex]).div(10**(_feeDecimal + 2));
        uint256 charityFee = amount.mul(_charityFee[feeIndex]).div(10**(_feeDecimal + 2));
        uint256 rewardFee = amount.mul(_rewardFee[feeIndex]).div(10**(_feeDecimal + 2));
        uint256 stackholderFee = amount.mul(_stakeHolderFee[feeIndex]).div(10**(_feeDecimal + 2));
        
        _liqFeeCollected = _liqFeeCollected.add(liqFee);
        _charityFeeCollected = _charityFeeCollected.add(charityFee);
        _rewardFeeCollected = _rewardFeeCollected.add(rewardFee);
        _stackholderFeeCollected = _stackholderFeeCollected.add(stackholderFee);
        return taxFee.add(liqFee).add(charityFee).add(rewardFee).add(stackholderFee);
    }

    function collectFee(
        address account,
        address inviter,
        uint256 amount,
        uint256 rate,
        bool sell,
        bool p2p
    ) private returns (uint256) {
        uint256 feeIndex = p2p ? 2 : sell ? 1 : 0;
        uint256 inviteFee = amount.mul(_inviteFee[feeIndex]).div(10**(_feeDecimal + 2));
        uint256 parentInviteFee = amount.mul(_parentInviteFee[feeIndex]).div(10**(_feeDecimal + 2));

        uint256 totalFee = calculateFee(feeIndex, amount);
        amount = amount.sub(inviteFee).sub(parentInviteFee).sub(totalFee);

        if(totalFee != 0) {
            _transferInternal(account, address(this), totalFee, rate);
        }

        address recipient;
        if (inviteFee != 0) {
            recipient = address(blackHoleAddress);

            if (inviter != address(0x0)) {
                recipient = inviter;
            }
           _transferInternal(account, recipient, inviteFee, rate);
        }

        if (parentInviteFee != 0) {
            recipient = address(blackHoleAddress);

            if (inviter != address(0x0) && invitees[inviter] != address(0x0)) {
                recipient = invitees[inviter];
            }
           _transferInternal(account, recipient, parentInviteFee, rate);
        }
        return amount;
    }

    function swap() private lockTheSwap {
        uint256 totalFee = getTotalFee();
        if(minTokensBeforeSwap > totalFee) return;

        uint256 amountToLiquify = totalFee.mul(_liqFeeCollected).div(totalFee).div(2);
        uint256 amountToSwap = totalFee.sub(amountToLiquify);

        address[] memory sellPath = new address[](2);
        sellPath[0] = address(this);
        sellPath[1] = router.WETH();       

        uint256 balanceBefore = address(this).balance;

        _approve(address(this), address(router), totalFee);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            sellPath,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(_liqFeeCollected.div(2));
        
        uint256 amountBNBLiquidity = amountBNB.mul(_liqFeeCollected).div(totalBNBFee).div(2);
        uint256 amountBNBCharity = amountBNB.mul(_charityFeeCollected).div(totalBNBFee);
        uint256 amountBNBReward = amountBNB.mul(_rewardFeeCollected).div(totalBNBFee);

        if(amountToLiquify > 0) {
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                owner(),
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }

        // if(amountBNBCharity > 0) payable(charityWallet).transfer(amountBNBCharity);
        uint256 amountSwapToRewardToken = amountBNBReward.add(amountBNBCharity);
        uint256 rewardTokenBalanceBefore = IERC20(rewardToken).balanceOf(address(this));
        swapRewardToken(amountSwapToRewardToken);
        uint256 swappedRewardTokenAmount = IERC20(rewardToken).balanceOf(address(this)).sub(rewardTokenBalanceBefore);
        uint256 amountRewardTokenCharity = swappedRewardTokenAmount.mul(amountBNBCharity).div(amountSwapToRewardToken);
        rewardToken.safeTransfer(charityWallet, amountRewardTokenCharity);
        
        _liqFeeCollected = 0;
        _charityFeeCollected = 0;
        _rewardFeeCollected = 0;
    }

    function swapRewardToken(uint256 rewardAmount) internal {
        if(rewardAmount > 0) {
            address[] memory buyPath = new address[](2);
            buyPath[0] = router.WETH();
            buyPath[1] = rewardToken;

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: rewardAmount}(
                0,
                buyPath,
                address(this),
                block.timestamp
            );
        }
    }

    function getExcludedBalance() public view returns (uint256) {
        uint256 excludedAmount;
        for (uint256 i = 0; i < _excluded.length; i++) {
            excludedAmount = excludedAmount.add(balanceOf(_excluded[i]));
        }
        return totalSupply().sub(excludedAmount);
    }

    function calculateReward(address account) public view returns (uint256) {
        uint256 excludedAmount;
        for (uint256 i = 0; i < _excluded.length; i++) {
            excludedAmount = excludedAmount.add(balanceOf(_excluded[i]));
        }
        uint256 _totalSupply = totalSupply().sub(excludedAmount);

        uint256 currentBalance = balanceOf(address(account));
        uint256 pool = IERC20(rewardToken).balanceOf(address(this));

        // now calculate reward
        uint256 reward = pool.mul(currentBalance).div(_totalSupply);

        return reward;
    }

    function claimReward() public isHuman nonReentrant lockTheSwap {
        require(nextAvailableClaimDate[msg.sender] <= block.timestamp, 'Error: Reward Claim unavailable!');
        require(balanceOf(msg.sender) >= 0, 'Error: Must be a holder to claim  rewards!');

        uint256 reward = calculateReward(msg.sender);

        // update rewardCycleBlock
        nextAvailableClaimDate[msg.sender] = block.timestamp + rewardCycleInterval;
        rewardToken.safeTransfer(msg.sender, reward);

        emit RewardClaimedSuccessfully(msg.sender, reward, nextAvailableClaimDate[msg.sender], block.timestamp);
    }
    
    function _claimRewardForAddress(address owner) private nonReentrant lockTheSwap returns (bool) {
        if (nextAvailableClaimDate[owner] > block.timestamp) {
            // Error: Reward Claim unavailable!
            return false;
        }
        if (balanceOf(owner) == 0) {
            // Must be a holder to claim  rewards!
            return false;
        }

        uint256 reward = calculateReward(owner);
        // update rewardCycleBlock
        nextAvailableClaimDate[owner] = block.timestamp + rewardCycleInterval;
        rewardToken.safeTransfer(owner, reward);

        emit RewardClaimedSuccessfully(owner, reward, nextAvailableClaimDate[owner], block.timestamp);
        return true;
    }

    function topUpClaimCycleAfterTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 currentSenderBalance = balanceOf(sender);

        if (recipient == pair && currentSenderBalance == amount) {
            // initate claim date when sell entire token
            nextAvailableClaimDate[sender] = 0;
        } else {
            nextAvailableClaimDate[recipient] = block.timestamp + rewardCycleInterval;
        }
    }

    function _getReflectionRate() private view returns (uint256) {
        uint256 reflectionSupply = _reflectionTotal;
        uint256 tokenSupply = _tokenTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_reflectionBalance[_excluded[i]] > reflectionSupply || _tokenBalance[_excluded[i]] > tokenSupply)
                return _reflectionTotal.div(_tokenTotal);
            reflectionSupply = reflectionSupply.sub(_reflectionBalance[_excluded[i]]);
            tokenSupply = tokenSupply.sub(_tokenBalance[_excluded[i]]);
        }
        if (reflectionSupply < _reflectionTotal.div(_tokenTotal)) return _reflectionTotal.div(_tokenTotal);
        return reflectionSupply.div(tokenSupply);
    }

    function setPairRouterRewardToken(address _pair, IUniswapV2Router02 _router, address _rewardToken) external onlyOwner {
        pair = _pair;
        router = _router;
        rewardToken = _rewardToken;
    }

    function setTaxless(address account, bool value) external onlyOwner {
        isTaxless[account] = value;
    }

    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
        emit SwapUpdated(enabled);
    }

    function setFeeActive(bool value) external onlyOwner {
        isFeeActive = value;
    }

    function setTaxFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
        _taxFee[0] = buy;
        _taxFee[1] = sell;
        _taxFee[2] = p2p;
    }

    function setNormalRewardFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
        _rewardFee[0] = buy;
        _rewardFee[1] = sell;
        _rewardFee[2] = p2p;
    }

    function setChairtyFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
        _charityFee[0] = buy;
        _charityFee[1] = sell;
        _charityFee[2] = p2p;
    }


    function setLiquidityFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
        _liqFee[0] = buy;
        _liqFee[1] = sell;
        _liqFee[2] = p2p;
    }

    function setCharityWallet(address wallet)  external onlyOwner {
        charityWallet = wallet;
    }

    function setMaxTxAmount(uint256 amount) external onlyOwner {
        maxTxAmount = amount;
    }

    function setMinTokensBeforeSwap(uint256 amount) external onlyOwner {
        minTokensBeforeSwap = amount;
    }

    function setRewardCycleInterval(uint256 interval) external onlyOwner {
        rewardCycleInterval = interval;
    }

    function setActivatePrice(uint256 price) public onlyOwner {
        activatePrice = price;
    }

    function stopMining() public onlyOwner {
        miningStopped = true;
    }

    function getTotalFee() public view returns (uint256) {
        return _liqFeeCollected
            .add(_charityFeeCollected)
            .add(_rewardFeeCollected);
    }

    function setMaxStackholderCount(uint256 count) public onlyOwner {
        maxStackholderCount = count;
    }

    function addStackholder(address stackholder) public onlyOwner {
        require(stackholders.length < maxStackholderCount, "stackholder seat full");
        require(!isStackholder[stackholder], "this stackholder already added");

        stackholders.push(stackholder);
        isStackholder[stackholder] = true;
        
        emit StackholderAdded(stackholder);
    }

    function addMultiStackholder(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            addStackholder(addresses[i]);
        }
    }

    function removeStackholder(address stackholder) public onlyOwner {
        require(isStackholder[stackholder], "this stackholder not added");

        isStackholder[stackholder] = false;
        for (uint256 i = 0; i < stackholders.length; i++) {
            if (stackholders[i] == stackholder) {
                stackholders[i] = stackholders[stackholders.length-1];
                stackholders.pop();
                emit StackholderRemoved(stackholder);
                break;
            }
        }
    }

    function getAddedStackholderCount() public view returns (uint256) {
        return stackholders.length;
    }

    function distributeStack() public onlyOwner {
        uint256 rate = _getReflectionRate();

        // if stackholder not full, burn the fee
        if (stackholders.length != maxStackholderCount) {
            _transferInternal(address(this), blackHoleAddress, _stackholderFeeCollected, rate);
            emit StackholderFeeBurned(_stackholderFeeCollected);
        } else {
            // distribute to all stackholders
            uint256 piece = _stackholderFeeCollected.div(stackholders.length);
            for (uint256 i = 0; i < stackholders.length; i++) {
                _transferInternal(address(this), stackholders[i], piece, rate);
            }

            emit StackhokderFeeDistributed(_stackholderFeeCollected);
        }

        _stackholderFeeCollected = 0;
    }

    function _transferInternal(
        address from,
        address to,
        uint256 amount,
        uint256 rate
    ) internal {
         _reflectionBalance[from] = _reflectionBalance[from].sub(amount.mul(rate));
        _reflectionBalance[to] = _reflectionBalance[to].add(amount.mul(rate));

        //if any account belongs to the excludedAccount transfer token
        if (_isExcluded[from]) {
            _tokenBalance[from] = _tokenBalance[from].sub(amount);
        }
        if (_isExcluded[to]) {
            _tokenBalance[to] = _tokenBalance[to].add(amount);
        }
        emit Transfer(from, to, amount);
    }

    function withdrawEarningFee(address payable to) public onlyOwner {
        uint amount = address(this).balance;
        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed to send BNB");
    }

    receive() external payable {}
}