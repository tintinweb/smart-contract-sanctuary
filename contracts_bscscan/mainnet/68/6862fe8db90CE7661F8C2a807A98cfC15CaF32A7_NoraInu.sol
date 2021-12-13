/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IDexRouter {

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

interface IDexFactory {

    function createPair(address tokenA, address tokenB) external returns (address pair);

}

contract NoraInu is Context, IERC20, Ownable {

    using SafeMath for uint256;
    using Address for address;

    // events for extra rewards and lottery
    event ExtraRewards(address indexed from, address indexed to, uint256 value);
    event LotteryWin(address indexed from, address indexed to, uint256 value);

    // balances of token and reflection
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    // fee and rewards excludion
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromRewards;
    address[] private _excludedFromRewards;

    // total token and reflection
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = (100 * 1000 ** 3) * 10 ** 9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Nora Inu";
    string private _symbol = "NINU";
    uint8 private _decimals = 9;
    
    // fees
    uint256 public taxFee = 2;
    uint256 private _previousTaxFee = taxFee;
    uint256 public liquidityFee = 2;
    uint256 private _previousLiquidityFee = liquidityFee;
    uint256 public lotteryFee = 1;
    uint256 private _previousLotteryFee = lotteryFee;

    // 30% of total supply goes to extra reward pot to booster the daily rewards a little
    uint256 public rExtraRewardsPot;

    // timestamp of last extra rewards added
    uint256 public lastExtraRewardsDonated;

    // standard pot if enough tokens available
    uint256 public tExtraRewardsStandardPot = _tTotal.div(10000);

    // define time between extra rewards
    uint256 public timeBetweenExtraRewards = 77777;

    // 10% of total supply goes for boostering the lottery rewards (and increasing with fee)
    uint256 public rLotteryPot;

    // timestamp of last lottery round
    uint256 public lastLotteryRound;

    // entry amount for lottery (100 tokens) 
    uint256 public tLotteryEntryAmount = 100 * 10 ** 9;

    // standard pot if enough tokens available
    uint256 public tLotteryStandardPot = _tTotal.div(10000);

    // define time between lottery rounds
    uint256 public timeBetweenLotteryRounds = 86400;

    // lottery players (everyone with amount > 100 tokens and not excluded from reward or banned)
    address[] private _lotteryPlayers;
    mapping (address => bool) private _isLotteryPlayer;

    // certain accounts will never receive lottery rewards (black hole, team or dex)
    mapping (address => bool) private _isBannedFromLottery;

    IDexRouter public iDexRouter;
    address public iDexPair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public maxTxAmount = (500 * 1000 ** 2) * 10 ** 9;
    uint256 public numTokensSellToAddToLiquidity = (50 * 1000 ** 2) * 10 ** 9;
    
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () public {

        _rOwned[_msgSender()] = _rTotal.div(10);
        
        // create pair on pancakeswap
        setRouterAddress(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // send 50% of tokens to black hole
        _rOwned[0x000000000000000000000000000000000000dEaD] = _rTotal.div(2);

        // distribute lottery and extra rewards
        rLotteryPot = _rTotal.div(10);
        rExtraRewardsPot = _rTotal.div(100).mul(30);

        // send events
        emit Transfer(address(0), 0x000000000000000000000000000000000000dEaD, _tTotal.div(2)); // black hole
        emit Transfer(address(0), address(this), _tTotal.div(10)); // lottery pot
        emit Transfer(address(0), _msgSender(), _tTotal.div(10)); // team, support, charity, liqudity
    }

    // BEGIN IERC20 implementation

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
        if (_isExcludedFromRewards[account]) return _tOwned[account];
        return convertReflectionToToken(_rOwned[account]);
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }    

    // END IERC20 implementation

    // BEGIN dex

    receive() external payable {}

    function setRouterAddress(address router) public onlyOwner() {
        IDexRouter _iDexRouter = IDexRouter(router);
        iDexPair = IDexFactory(_iDexRouter.factory()).createPair(address(this), _iDexRouter.WETH());
        iDexRouter = _iDexRouter;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current BNB balance
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to swap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the swap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = iDexRouter.WETH();

        _approve(address(this), address(iDexRouter), tokenAmount);

        // make the swap
        iDexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(iDexRouter), tokenAmount);

        // add the liquidity
        iDexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    // END dex

    // BEGIN reflection

    function donateToRewards(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcludedFromRewards[sender], "excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function convertReflectionToToken(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function convertTokenToReflection(uint256 tAmount) public view returns(uint256) {
        require(tAmount <= _tTotal, "amount must be less than total tokens");
        uint256 currentRate =  _getRate();
        return tAmount.mul(currentRate);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tLottery) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tLottery, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tLottery);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tLottery = calculateLotteryFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tLottery);
        return (tTransferAmount, tFee, tLiquidity, tLottery);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tLottery, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rLottery = tLottery.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rLottery);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excludedFromRewards.length; i++) {
            if (_rOwned[_excludedFromRewards[i]] > rSupply || _tOwned[_excludedFromRewards[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excludedFromRewards[i]]);
            tSupply = tSupply.sub(_tOwned[_excludedFromRewards[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    // END reflection

    // BEGIN rewards exclusion

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromRewards[account];
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcludedFromRewards[account], "account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = convertReflectionToToken(_rOwned[account]);
        }
        _isExcludedFromRewards[account] = true;
        _excludedFromRewards.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromRewards[account], "account is not excluded");
        for (uint256 i = 0; i < _excludedFromRewards.length; i++) {
            if (_excludedFromRewards[i] == account) {
                _excludedFromRewards[i] = _excludedFromRewards[_excludedFromRewards.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromRewards[account] = false;
                _excludedFromRewards.pop();
                break;
            }
        }
    }

    // END rewards exclusion

    // BEGIN fees

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function setTaxFeePercent(uint256 newTaxFee) external onlyOwner() {
        taxFee = newTaxFee;
    }
    
    function setLiquidityFeePercent(uint256 newLiquidityFee) external onlyOwner() {
        liquidityFee = newLiquidityFee;
    }

    function setLotteryFeePercent(uint256 newLotteryFee) external onlyOwner() {
        lotteryFee = newLotteryFee;
    }
   
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
    }

    function setNumTokensSellToAddToLiquidity(uint256 tAmount) public onlyOwner() {
        numTokensSellToAddToLiquidity = tAmount;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(taxFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(liquidityFee).div(10**2);
    }

    function calculateLotteryFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(lotteryFee).div(10**2);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcludedFromRewards[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function _takeLottery(uint256 tLottery) private {
        uint256 currentRate =  _getRate();
        uint256 rLottery = tLottery.mul(currentRate);
        rLotteryPot = rLotteryPot.add(rLottery);
    }

    function removeAllFee() private {
        if (taxFee == 0 && liquidityFee == 0 && lotteryFee == 0) return;
        
        _previousTaxFee = taxFee;
        _previousLiquidityFee = liquidityFee;
        _previousLotteryFee = lotteryFee;
        
        taxFee = 0;
        liquidityFee = 0;
        lotteryFee = 0;
    }
    
    function restoreAllFee() private {
        taxFee = _previousTaxFee;
        liquidityFee = _previousLiquidityFee;
        lotteryFee = _previousLotteryFee;
    }

    // END fees

    // BEGIN transfer

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner()) {
            require(amount <= maxTxAmount, "exceeding maxTxAmount (anti whale protection)");
        }

        // has contract enough tokens to swap?
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        
        // swap only if enough tokens, no loquidity lock and we are not actually receiving from the pool
        if (overMinTokenBalance && !inSwapAndLiquify && from != iDexPair && swapAndLiquifyEnabled) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
    
        // if any account belongs to _isExcludedFromFee account then remove the fee
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);

        // update status in lottery for both parties after transfer
        _updateLotteryPlayer(from);
        _updateLotteryPlayer(to);

        // starting lottery
        if (rLotteryPot > 0 && _canLotteryStartNow()) {
            _startLottery();
        }

        // donating extra rewards
        if (rExtraRewardsPot > 0 && _canDonateExtraRewardsNow()) {
            _donateExtraRewards();
        }

        _updateSenderReflections(from);

    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {

        if(!takeFee)
            removeAllFee();
        
        if (_isExcludedFromRewards[sender] && !_isExcludedFromRewards[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromRewards[sender] && _isExcludedFromRewards[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromRewards[sender] && !_isExcludedFromRewards[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedFromRewards[sender] && _isExcludedFromRewards[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
                
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tLottery) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeLottery(tLottery);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tLottery) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _takeLottery(tLottery);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tLottery) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _takeLottery(tLottery);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tLottery) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _takeLottery(tLottery);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _updateSenderReflections(address sender) private {
        uint256 rOwned = _rOwned[sender];
        uint256 tOwned = convertReflectionToToken(rOwned);
        
        // donating dust 
        if (tOwned == 0 && rOwned > 0) {
            _rTotal = _rTotal.sub(rOwned);
            _rOwned[sender] = 0;
        }
    }

    // END transfer

    // BEGIN extra rewards

    function setTimeBetweenExtraRewards(uint256 timeInSeconds) public onlyOwner {
        timeBetweenExtraRewards = timeInSeconds;
    }

    function setExtraRewardsStandardPot(uint256 tPot) public onlyOwner {
        tExtraRewardsStandardPot = tPot;
    }

    function _canDonateExtraRewardsNow() private view returns(bool) {
        if (block.timestamp - lastExtraRewardsDonated >= timeBetweenExtraRewards) {
            return true;
        }
        return false;
    }

    function calculateExtraRewards() public view returns(uint256) {
        uint256 rStandardPot = convertTokenToReflection(tExtraRewardsStandardPot); 
        if (rExtraRewardsPot >= rStandardPot) {
            return rStandardPot;
        }
        return rExtraRewardsPot;
    }

    function _donateExtraRewards() private {
        uint256 rPot = calculateExtraRewards();
        uint256 tPot = convertReflectionToToken(rPot);

        // donating extra rewards
        if (tPot > 0) {         
            rExtraRewardsPot = rExtraRewardsPot.sub(rPot);
            _rTotal = _rTotal.sub(rPot);
            _tFeeTotal = _tFeeTotal.add(tPot);
            emit ExtraRewards(address(0), address(this), tPot);
        }

        // donating dust 
        if (tPot == 0 && rPot > 0) {
            _rTotal = _rTotal.sub(rExtraRewardsPot);
            rExtraRewardsPot = 0;
        }

        lastExtraRewardsDonated = block.timestamp;        
    }

    // END extra rewards

    // BEGIN lottery

    function setLotteryEntryAmount(uint256 tAmount) public onlyOwner {
        tLotteryEntryAmount = tAmount;
    }

    function setLotteryStandardPot(uint256 tPot) public onlyOwner {
        tLotteryStandardPot = tPot;
    }

    function setTimeBetweenLotteryRounds(uint256 timeInSeconds) public onlyOwner {
        timeBetweenLotteryRounds = timeInSeconds;
    }

    function availableTokensForLottery() public view returns(uint256) {
        return convertReflectionToToken(rLotteryPot);
    }

    function availableTokensForExtraRewards() public view returns(uint256) {
        return convertReflectionToToken(rExtraRewardsPot);
    }

    // LOTTERY rights management: always keeping a clean record of who can play the lottery or not

    function _updateLotteryPlayer(address account) private {
        uint256 rLotteryEntryAmount = convertTokenToReflection(tLotteryEntryAmount);
        if (_rOwned[account] >= rLotteryEntryAmount) {
            _includeForLottery(account);
        } else if (_isExcludedFromRewards[account] || _rOwned[account] < rLotteryEntryAmount) {
            _excludeFromLottery(account);
        }     
    }

    function _includeForLottery(address account) private {
        if (!_isExcludedFromRewards[account] && !_isLotteryPlayer[account] && !_isBannedFromLottery[account]) {
            _isLotteryPlayer[account] = true;
            _lotteryPlayers.push(account);
        }
    }

    function _excludeFromLottery(address account) private {
        if (_isLotteryPlayer[account]) {
            for (uint256 i = 0; i < _lotteryPlayers.length; i++) {
                if (_lotteryPlayers[i] == account) {
                    _lotteryPlayers[i] = _lotteryPlayers[_lotteryPlayers.length - 1];
                    _isLotteryPlayer[account] = false;
                    _lotteryPlayers.pop();
                    break;
                }
            }
        }
    }

    // LOTTERY bans: it would be highly unfair if certain addresses could participate in the lottery (black hole, team, dexes..)

    function banFromLottery(address account) public onlyOwner {
        _excludeFromLottery(account);
        _isBannedFromLottery[account] = true;
    }

    function unBanFromLottery(address account) public onlyOwner {
        _isBannedFromLottery[account] = false;
        _updateLotteryPlayer(account);
    }   

    // LOTTERY round: all about drawing a lucky winner and sending the prize

    function _canLotteryStartNow() private view returns(bool) {
        if (block.timestamp - lastLotteryRound >= timeBetweenLotteryRounds) {
            return true;
        }
        return false;
    }

    function _drawWinner() private view returns(address) {
        uint256 random = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _lotteryPlayers)));
        uint256 index = random % _lotteryPlayers.length;
        return _lotteryPlayers[index];
    }

    function _startLottery() private {
        if (_lotteryPlayers.length >= 2) {
            uint256 rPot = calculateLotteryPot();
            uint256 tPot = convertReflectionToToken(rPot);
            address winner = _drawWinner();
            _rOwned[winner] = _rOwned[winner].add(rPot);
            rLotteryPot = rLotteryPot.sub(rPot);
            lastLotteryRound = block.timestamp;
            emit LotteryWin(address(this), winner, tPot);
        } 
    }

    function calculateLotteryPot() public view returns(uint256) {
        uint256 rStandardPot = convertTokenToReflection(tLotteryStandardPot); 
        if (rLotteryPot >= rStandardPot) {
            return rStandardPot;
        }
        return rLotteryPot;
    }

    function countLotteryPlayers() public view returns(uint256) {
        return _lotteryPlayers.length;
    }

    // END lottery    

}