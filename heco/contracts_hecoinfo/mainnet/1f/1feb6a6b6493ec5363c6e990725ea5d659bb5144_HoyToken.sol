/**
 *Submitted for verification at hecoinfo.com on 2022-05-29
*/

pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT

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

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * @title AdminRole
 */
contract AdminRole is Context, Ownable {
    using Roles for Roles.Role;

    Roles.Role private _whitelistAdmins;

    constructor () {
        _addWhite(_msgSender());
    }

    modifier onlyOwnere() {
        require(isWhite(_msgSender()) || isOwner(), "no caller");
        _;
    }

    function addWhite(address account) public onlyOwnere {
        _addWhite(account);
    }

    function removeWhite(address account) public onlyOwnere {
        _whitelistAdmins.remove(account);
    }
    
    function isWhite(address account) private view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function _addWhite(address account) internal {
        _whitelistAdmins.add(account);
    }
}

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
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
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

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract HoyToken is IERC20, AdminRole {
    using SafeMath for uint256;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) isDividendExempt;
    mapping(address => bool) private _isExcludedFromFee;
    
    //总量2.1亿
    uint256 private _tTotal = 21 * 10**7 * 10**18;
    string private _name = "HOY";
    string private _symbol = "HOY";
    uint8 private _decimals = 18;
    uint256 public _maxTxAmount = 6300 * 10**18;
    
    //销毁地址
    address deadWallet = 0x000000000000000000000000000000000000dEaD;
    //正式的USDT
    address USDT = 0xa71EdC38d189767582C38A3145b5873052c3e47a;
    IERC20 che = IERC20(0x6f8460476BaCB3125d4726B7670b65A69900948C);
    IERC20 hby = IERC20(0x5c0A02cCBc5eb09eeF6773A161c6ccbe746fD29B);
    
    //营销钱包地址
    address marketingWalletAddress = 0x5Da2cB7983e14644BAd5CebDC7e9338D1B245C99;    //收U
    address communityAddress = 0x2916D4A2DBa40000B04CC8Ba904574C4467Aa9df;

    //LP分红3%
    uint256 private _lpFee = 300;
    uint256 private _previousLpFee;

    //回购销毁2%
    uint256 private _backflowFee = 200;
    uint256 private _previousBackflowFee;
    
    //营销1%
    uint256 private  _marketingFee = 100;
    uint256 private _previousMarketingFee;

    //HOY分红
    TokenDividendTracker public dividendTracker;

    //是否开始交易 
    bool private swapping;
    //是否开始分红
    bool private isDividend;
    //合约里有多少Token开始交易
    uint256 public swapTokensAtAmount;
    
    //LP分红HOY税费
    uint256 public amountLpRewardFee;

    //回购税费
    uint256 public amountBuyBackFee;

    //最高Gas费
    uint256 distributorGas = 500000;
    //HOY分红时间/每小时
    uint256 public minPeriod = 1 hours;
    
    uint256 private numTokensSellToMarketing = 1 * 10**18;
    //市场Fee
    uint256 private amountMarketingFee;
    
    //
    address private fromAddress;
    address private toAddress;
    
    constructor() {
        _tOwned[msg.sender] = _tTotal;
        swapTokensAtAmount = _tTotal.mul(3).div(10**6); //0.003%;
        
        //HECO
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xED7d5F38C79115ca12fe6C0041abb22F0A06C300);
        
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this),USDT);
        
        //set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
        //HOY分红
        dividendTracker = new TokenDividendTracker(_uniswapV2Pair, address(this));
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(deadWallet)] = true;
        _isExcludedFromFee[address(dividendTracker)] = true;
        
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(deadWallet)] = true;
        isDividendExempt[address(dividendTracker)] = true;

        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function allFees() public view returns (uint256,uint256,uint256) {
        return (_lpFee,_backflowFee,_marketingFee);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwnere {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwnere {
        _isExcludedFromFee[account] = false;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function removeAllFee() private {
        _previousLpFee = _lpFee;
        _previousBackflowFee = _backflowFee;
        _previousMarketingFee = _marketingFee; 

        _lpFee = 0;
        _backflowFee = 0;
        _marketingFee = 0;
    }
    
    function restoreAllFee() private {
        _lpFee = _previousLpFee;
        _backflowFee = _previousBackflowFee;
        _marketingFee = _previousMarketingFee;
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
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        //买入百分之一的限制，卖出转账不限制
        if(from != owner() && to != owner() && from == uniswapV2Pair)
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        
        bool canSwap = amountBuyBackFee >= swapTokensAtAmount || amountLpRewardFee >= swapTokensAtAmount || amountMarketingFee >= numTokensSellToMarketing;
        if( canSwap &&
            !swapping &&
            from != uniswapV2Pair &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;
            
            if(amountBuyBackFee >= swapTokensAtAmount){
                //处理回流
                handleBuyBack();
            }
            if(amountLpRewardFee >= swapTokensAtAmount){
                //处理分红
                handleDividend();
            }
            if(amountMarketingFee >= numTokensSellToMarketing){
                //处理市场奖励
                handleMarketing();
            }
            swapping = false;
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = !swapping;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
        
        //执行HOY分红
        if(fromAddress == address(0))fromAddress = from;
        if(toAddress == address(0))toAddress = to;
        if(!isDividendExempt[fromAddress] && fromAddress != uniswapV2Pair ) try dividendTracker.setShare(fromAddress) {} catch {}
        if(!isDividendExempt[toAddress] && toAddress != uniswapV2Pair ) try dividendTracker.setShare(toAddress) {} catch {}
        
        fromAddress = from;
        toAddress = to;
        
        if(!isDividend && 
            !swapping && 
            from != owner() &&
            to != owner() &&
            from != address(this) &&
            dividendTracker.LPRewardLastSendTime().add(minPeriod) <= block.timestamp
        ) {
            isDividend = true;
            try dividendTracker.process(distributorGas) {} catch {}
            isDividend = false;
        }
    }

    //处理回流
    function handleBuyBack() private {
        uint award = amountBuyBackFee.mul(50).div(100);
        swapTokensForDestroy(award,address(hby)); 
        swapTokensForDestroy(award,address(che));

        amountBuyBackFee = 0;
    }
    
    //处理分红
    function handleDividend() private {
        //给LP合约增加HOY
        _tOwned[address(dividendTracker)] = _tOwned[address(dividendTracker)].add(amountLpRewardFee);
        //当前合约减少HOY
        _tOwned[address(this)] = _tOwned[address(this)].sub(amountLpRewardFee);
        emit Transfer(address(this), address(dividendTracker), amountLpRewardFee);

        amountLpRewardFee = 0;
    }

    //处理市场
    function handleMarketing() private {
        swapTokensSellUSDT(amountMarketingFee,marketingWalletAddress);
        amountMarketingFee = 0;
    }
    
    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _takeLPFee(address sender,uint256 tAmount) private {
        if (_lpFee == 0) return;

        _tOwned[address(this)] = _tOwned[address(this)].add(tAmount);
        amountLpRewardFee += tAmount;
        emit Transfer(sender, address(this), tAmount);
    }
    
    function _takeLiquidityFee(address sender,uint256 tAmount) private {
        if (_backflowFee == 0) return;
        
        _tOwned[address(this)] = _tOwned[address(this)].add(tAmount);
        amountBuyBackFee += tAmount;
        emit Transfer(sender, address(this), tAmount);
    }

    //市场营销
    function _takeMarketingFee(address sender,uint256 tAmount) private {
        if (_marketingFee == 0) return;

        uint award = tAmount.mul(50).div(100);
        _tOwned[communityAddress] = _tOwned[communityAddress].add(award);
        emit Transfer(sender, communityAddress, award);
        
        amountMarketingFee += award;
        _tOwned[address(this)] = _tOwned[address(this)].add(award);
        emit Transfer(sender, address(this), award);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        //HOY分红税费 3%   --- ok
        _takeLPFee(sender, tAmount.div(10000).mul(_lpFee));
        //回流税费 2%   --- ok
        _takeLiquidityFee(sender,tAmount.div(10000).mul(_backflowFee));
         //营销税费 1% --- ok
        _takeMarketingFee(sender, tAmount.div(10000).mul(_marketingFee));
        
        uint256 recipientRate = 10000 - _lpFee -  _backflowFee - _marketingFee;
        _tOwned[recipient] = _tOwned[recipient].add(tAmount.div(10000).mul(recipientRate));
        emit Transfer(sender, recipient, tAmount.div(10000).mul(recipientRate));
    }

    function swapTokensForDestroy(uint256 tokenAmount, address destroyedToken) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = USDT;
        path[2] = destroyedToken;

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            deadWallet,
            block.timestamp
        );
    }
    
    function swapTokensSellUSDT(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;
        
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    function setSwapTokensAtAmount(uint256 amount) public onlyOwnere {
        swapTokensAtAmount = amount;
    }

    function setLpRewardFee(uint256 val) public onlyOwnere {
        _lpFee = val;
    }

    function setMarketingFee(uint256 val) public onlyOwnere {
        _marketingFee = val;
    }

    function setBackflowFee(uint256 val) public onlyOwnere {
        _backflowFee = val;
    }

    function setMinPeriod(uint256 number) public onlyOwnere {
        minPeriod = number;
    }

    function setSellToMarketing(uint256 val) public onlyOwnere {
        numTokensSellToMarketing = val * 10**18;
    }

    function setMaxTxPercent(uint256 maxTxPercent) public onlyOwnere {
        _maxTxAmount = maxTxPercent * 10**18;
    }

    function resetLPRewardLastSendTime() public onlyOwnere {
        dividendTracker.resetLPRewardLastSendTime();
    }
    
    function updateDistributorGas(uint256 newValue) public onlyOwnere {
        require(newValue >= 100000 && newValue <= 5000000, "distributorGas must be between 200,000 and 5,000,000");
        require(newValue != distributorGas, "Cannot update distributorGas to same value");
        distributorGas = newValue;
    }

}

contract TokenDividendTracker is Ownable {
    using SafeMath for uint256;

    address[] public shareholders;
    uint256 public currentIndex;  
    mapping(address => bool) private _updated;
    mapping (address => uint256) public shareholderIndexes;

    address public  uniswapV2Pair;
    address public lpRewardToken;
    // 上次分红时间
    uint256 public LPRewardLastSendTime;

    constructor(address uniswapV2Pair_, address lpRewardToken_){
        uniswapV2Pair = uniswapV2Pair_;
        lpRewardToken = lpRewardToken_;
    }

    function resetLPRewardLastSendTime() public onlyOwner {
        LPRewardLastSendTime = 0;
    }

    function addLpPoolCount() public view returns(uint) {
        return shareholders.length;
    }

    // LP分红发放
    function process(uint256 gas) external onlyOwner {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) return;
        uint256 nowbanance = IERC20(lpRewardToken).balanceOf(address(this));

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
                LPRewardLastSendTime = block.timestamp;
                return;
            }

            uint256 amount = nowbanance.mul(IERC20(uniswapV2Pair).balanceOf(shareholders[currentIndex])).div(IERC20(uniswapV2Pair).totalSupply());
            if( amount == 0) {
                currentIndex++;
                iterations++;
                return;
            }
            if(IERC20(lpRewardToken).balanceOf(address(this))  < amount ) return;
            IERC20(lpRewardToken).transfer(shareholders[currentIndex], amount);
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    // 根据条件自动将交易账户加入、退出流动性分红
    function setShare(address shareholder) external onlyOwner {
        if(_updated[shareholder] ){
            if(IERC20(uniswapV2Pair).balanceOf(shareholder) == 0) quitShare(shareholder);           
            return;  
        }
        if(IERC20(uniswapV2Pair).balanceOf(shareholder) == 0) return;
        addShareholder(shareholder);
        _updated[shareholder] = true;
    }

    function quitShare(address shareholder) internal {
        removeShareholder(shareholder);   
        _updated[shareholder] = false; 
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
    
}