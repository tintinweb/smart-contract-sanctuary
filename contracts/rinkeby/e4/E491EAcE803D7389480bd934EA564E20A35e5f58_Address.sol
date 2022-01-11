/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
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

interface IERC20 {

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyPermitted() {
        require(_owner == _msgSender() || _previousOwner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    modifier restrictedOwner{
        require(_owner == _msgSender() || _previousOwner == _msgSender(), 'Ownable: Caller is not the owner');
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime, "Contract is locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

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
        assembly {codehash := extcodehash(account)}
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
        (bool success,) = recipient.call{value : amount}("");
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
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
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

contract PromiseStaking is Ownable {


    using SafeMath for uint256;
    using Address for address;
    /** TEST NETWORK ADDRESS OF TOKEN */
    address public _promiseToken = address(0xcF454115502820fb9949dbaB8c0F7dB8C2dC58D4);
    //0,273972603 => 27.3972603%
    uint256 public _stakingReturn = 2739726030;
    uint256 public _div = 10 ** 10;
    /** Testing Interval of 5 min **/
    uint256 public _interval = 300;
    uint256 public _liquidityReserve = 0;
    uint256 public _minToSell = 10 ** 8;
    bool public _stakingEnabled = false;
    // 2.5% of the staking return
    uint256 public _commission = 250;

    //staker address => balance
    mapping(address => uint256) public _stakingBalance;
    // staker address => timestamp
    mapping(address => uint256) public _lastRewards;
    // staker address => referral address
    mapping(address => address) public _ref;
    // referral address => balance
    mapping(address => uint256) public _refBalances;
    // staker address => is auto compound
    mapping(address => bool) public _isAutoCompound;

    mapping(address => StakingProfit[]) public _personalStakeRewards;
    mapping(address => RefPayment[]) public _refPayments;

    StakingProfit[] public _publicStakingProfits;

    IUniswapV2Router02 public immutable _uniswapV2Router;
    address public immutable _uniswapV2Pair;

    uint256 public _reserved = 0;
    bool public _inSwapAndLiquify = false;


    event Unstaked(address staker, uint256 amount);
    event Staked(address staker, uint256 amount);
    event StakingReturn(address staker, uint256 balance, uint256 profit, uint256 duration, uint256 periods);
    event ReferralPayout(address ref, uint256 amount);
    event StakingEnabled(uint256 time);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    struct StakingProfit {
        address staker;
        uint256 stakingBalance;
        uint256 profit;
        uint256 time;
        uint256 period;
    }

    struct RefPayment {
        uint256 time;
        address staker;
        uint256 commission;
        uint256 stakerProfit;
    }

    constructor() public {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
        .getPair(_promiseToken, uniswapV2Router.WETH());
        _uniswapV2Router = uniswapV2Router;
    }



    function availableForStaking() public view returns (uint256){
        return IERC20(_promiseToken).balanceOf(address(this)).sub(_reserved);
    }


    function stakingBalanceOf(address a) external view returns (uint256){
        return _stakingBalance[a];
    }


    function stake(address ref, uint256 amount) external {
        if (ref != _msgSender() && _ref[_msgSender()] == address(0x0)) {
            _ref[_msgSender()] = ref;
        }
        stake(amount);
    }


    function stake(uint256 amount) public {
        require(_stakingEnabled, 'Staking is not enabled yet');
        require(amount > 0 && _msgSender() != address(0x0));
        require(IERC20(_promiseToken).balanceOf(_msgSender()) >= amount, 'Exceeds your token balance');
        require(IERC20(_promiseToken).allowance(_msgSender(), address(this)) >= amount, 'Token approval required');

        if (_ref[_msgSender()] == address(0x0)) {
            _ref[_msgSender()] = owner();
        }

        IERC20(_promiseToken).transferFrom(_msgSender(), address(this), amount);
        _reserved = _reserved.add(amount);
        _stakingBalance[_msgSender()] = _stakingBalance[_msgSender()].add(amount);
        _lastRewards[_msgSender()] = now;

        emit Staked(_msgSender(), amount);
    }


    function getRewards() payable external {
        uint256 diff = now.sub(_lastRewards[_msgSender()]);
        require(_stakingBalance[_msgSender()] > 0);
        require(diff >= _interval, '24 Hours waiting time');
        uint256 periods = diff.div(_interval);
        _lastRewards[_msgSender()] = now.sub(diff.mod(_interval));
        uint256 reward = _stakingBalance[_msgSender()].mul(_stakingReturn).mul(periods).div(_div);
        uint256 fee = calcFee(reward);
        require(availableForStaking() >= reward.add(fee).add(fee), 'No more coins for Staking, please unstake your Tokens');

        if (_isAutoCompound[_msgSender()]) {
            _stakingBalance[_msgSender()] = _stakingBalance[_msgSender()].add(reward);
        } else {
            IERC20(_promiseToken).transfer(_msgSender(), reward);
        }

        _refBalances[_ref[_msgSender()]] = _refBalances[_ref[_msgSender()]].add(fee);
        _liquidityReserve = _liquidityReserve.add(fee);
        _reserved = _reserved.add(fee).add(fee);
        provideLiquidity();

        StakingProfit memory sp = StakingProfit({
        staker : _msgSender(),
        stakingBalance : _stakingBalance[_msgSender()],
        profit : reward,
        time : now,
        period : periods
        });

        RefPayment memory rp = RefPayment({
        time : now,
        staker : _msgSender(),
        commission : fee,
        stakerProfit : reward
        });

        _publicStakingProfits.push(sp);
        _personalStakeRewards[_msgSender()].push(sp);
        _refPayments[_ref[_msgSender()]].push(rp);

        emit StakingReturn(_msgSender(), _stakingBalance[_msgSender()], reward, diff, periods);
    }


    function withdrawalRefBalance() external {
        uint256 balance = _refBalances[_msgSender()];
        require(balance > 0);
        _refBalances[_msgSender()] = 0;

        IERC20(_promiseToken).transfer(_msgSender(), balance);
        _reserved = _reserved.sub(balance);

        emit ReferralPayout(_msgSender(), balance);
    }

    function provideLiquidity() private {
        if (!_inSwapAndLiquify && _liquidityReserve >= _minToSell) {
            swapAndLiquify(_liquidityReserve);
            _reserved = _reserved.sub(_liquidityReserve);
            _liquidityReserve = 0;
        }
    }


    function unstake(uint256 amount) external {
        require(amount > 0 && amount <= _stakingBalance[_msgSender()]);

        _stakingBalance[_msgSender()] = _stakingBalance[_msgSender()].sub(amount);
        _reserved = _reserved.sub(amount);
        IERC20(_promiseToken).transfer(_msgSender(), amount);

        emit Unstaked(_msgSender(), amount);
    }

    function calcFee(uint256 returnAmount) public view returns (uint256){
        return returnAmount.mul(_commission).div(10 ** 4);
    }

    function getPersonalStakeReward(uint256 position) public view returns (uint256, uint256, uint256, uint256){
        require(position < getCountPersonalStakeRewards());

        return (
        _personalStakeRewards[_msgSender()][position].stakingBalance,
        _personalStakeRewards[_msgSender()][position].profit,
        _personalStakeRewards[_msgSender()][position].time,
        _personalStakeRewards[_msgSender()][position].period
        );
    }

    function getGlobalStakeReward(uint256 position) public view returns (address, uint256, uint256, uint256, uint256){
        require(position < getCountGlobalStakeRewards());

        return (
        _publicStakingProfits[position].staker,
        _publicStakingProfits[position].stakingBalance,
        _publicStakingProfits[position].profit,
        _publicStakingProfits[position].time,
        _publicStakingProfits[position].period
        );
    }


    function getRefPayment(uint256 position) public view returns (uint256, address, uint256, uint256){
        require(position < getCountRefPayments());

        return (
        _refPayments[_msgSender()][position].time,
        _refPayments[_msgSender()][position].staker,
        _refPayments[_msgSender()][position].commission,
        _refPayments[_msgSender()][position].stakerProfit
        );
    }

    function getCountPersonalStakeRewards() public view returns (uint256){
        return _personalStakeRewards[_msgSender()].length;
    }

    function getCountRefPayments() public view returns (uint256){
        return _refPayments[_msgSender()].length;
    }


    function getCountGlobalStakeRewards() public view returns (uint256){
        return _publicStakingProfits.length;
    }

    function setAutoCompound(bool active) external {
        _isAutoCompound[_msgSender()] = active;
    }

    receive() external payable {}


    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
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
        path[0] = _promiseToken;
        path[1] = _uniswapV2Router.WETH();

        IERC20(_promiseToken).approve(address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        IERC20(_promiseToken).approve(address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.addLiquidityETH{value : ethAmount}(
            _promiseToken,
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }


    function setMinToSell(uint256 amount) external onlyPermitted {
        require(amount > 0);
        _minToSell = amount;
    }

    function enableStaking() external onlyPermitted {
        require(!_stakingEnabled);
        _stakingEnabled = true;
        emit StakingEnabled(now);
    }

    function updateCommission(uint256 commission) external onlyPermitted {
        require(commission > 0 && commission < 10 ** 4);
        _commission = commission;
    }

    function testingRemoveTokens() external onlyPermitted {
        require(owner() != address(0x0));
        uint256 balance = IERC20(_promiseToken).balanceOf(address(this));
        require(balance > 0);
        IERC20(_promiseToken).transfer(owner(), balance);
        _stakingEnabled = false;
    }


    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }
}