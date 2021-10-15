/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

/*
    Name = XTest
    Symbol = XTest
    Total Supply = 1_000_000_000_000 
    Decimal = 9
    10% TRANSACTION TAX
        3% LP
        2.5% Marketing
        2% Burn
        1.5% Team 
        .5%  Dev 
        .5% Community and Referrals
    2% REFLECTION FEE
*/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/* 
    Interface to implement BEP20 compliant tokens. 
    This will be utilized in primary token contract with full implementations.
*/
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
/*
    Basic solidity library for performing safe math functions internal to the contract.
*/
library SafeMath {

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


/*
 Collection of owner only functions specific to owner responsibilities. 
 These are supposed to be used to minimize usage of other functions within the primary contract
 as well as give the owner a way to transfer ownership and/or renounce ownership of the token if so desired.
 There are some other functions to the main openZepplin ownable contract that were left out of here
 i.e. the burn and mint functions as they pose trust and security risks to the token as they would allow the 
 owner or primary deployer of the token to create new tokens and deposit them to whatever account they desired.
*/
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
 

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (address initialOwner) {
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

 
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

/*
    Name = XTest
    Symbol = XTest
    Total Supply = 1_000_000_000_000 
    Decimal = 9
    10% TRANSACTION TAX
        3% LP
        2.5% Marketing
        2% Burn
        1.5% Team 
        .5%  Dev 
        .5% Community and Referrals
    2% REFLECTION FEE
*/

contract XTest is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromAutoLiquidity;

    address[] private _excluded;
    // TODO: Fix receivers 
    address public _marketingFeeReceiver;
    address public _burnFeeReceiver = 0x000000000000000000000000000000000000dEaD;
    address public _teamFeeReceiver;
    address public _devFeeReceiver;
    address public _communityAndReferralFeeReceiver;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal      = 1000000000000 * 10**9; // 1 Trillion
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name     = "XTest";
    string private _symbol   = "XTest";
    uint8 private  _decimals = 9;
    
    uint256 public _liquidityFee  = 10; 
    uint256 public _taxFee   = 2;
    
    // TODO: ensure all have setters
    uint256 public _percentageOfLiquidityForMarketingFee  = 25; // 2.5% of 10% 
    uint256 public _percentageOfLiquidityForBurnFee       = 20; // 2% of 10%
    uint256 public _percentageOfLiquidityForTeamFee       = 15; // 1.5% of 10% 
    uint256 public _percentageOfLiquidityForDevFee        = 5;  // .5% of 10%
    uint256 public _percentageOfLiquidityForCommunityAndReferralFee = 5;  // .5% of 10%
    // fees total = 70% of total or 7% of 10% fee
    // remainder left to go towards the auto-liquidity = 30% of total or 3% of 10% fee
    
    uint256 public  _maxTxAmount     = 1000000000000 * 10**9; // 1 trillion
    uint256 private _minTokenBalance = 100000 * 10**9;
    
    // auto liquidity
    bool public _swapAndLiquifyEnabled = true;
    bool _inSwapAndLiquify;
    IUniswapV2Router02 public _uniswapV2Router;
    address            public _uniswapV2Pair;
    // Events 
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);
    event MarketingFeeSent(address to, uint256 bnbSent);
    event BurnFeeSent(address to, uint256 bnbSent);
    event TeamFeeSent(address to, uint256 bnbSent);
    event DevFeeSent(address to, uint256 bnbSent);
    event CommunityAndReferralFeeSent(address to, uint256 bnbSent);
    
    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }
    
    constructor (address cOwner,
                address marketingFeeReceiver, 
                address teamFeeReceiver,
                address devFeeReceiver,
                address communityAndReferralFeeReceiver) Ownable(cOwner) {

        // set wallet addresses minus burn address which is hardcoded in contract.
        _marketingFeeReceiver   = marketingFeeReceiver;
        _teamFeeReceiver        = teamFeeReceiver;
        _devFeeReceiver         = devFeeReceiver;
        _communityAndReferralFeeReceiver = communityAndReferralFeeReceiver;
        _rOwned[cOwner] = _rTotal;
        
        // PancakeRouterV2
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Pancakeswap MAINNET BSC
        _uniswapV2Router = uniswapV2Router;
        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        
        // exclude system contracts
        _isExcludedFromFee[owner()]                 = true;
        _isExcludedFromFee[address(this)]           = true;
        _isExcludedFromFee[_marketingFeeReceiver]   = true;
        _isExcludedFromFee[_burnFeeReceiver]        = true;
        _isExcludedFromFee[_teamFeeReceiver]        = true;
        _isExcludedFromFee[_devFeeReceiver]         = true;
        _isExcludedFromFee[_communityAndReferralFeeReceiver] = true;

        _isExcludedFromAutoLiquidity[_uniswapV2Pair]            = true;
        _isExcludedFromAutoLiquidity[address(_uniswapV2Router)] = true;
        
        emit Transfer(address(0), cOwner, _tTotal);
    }

    /**
     * returns the name of the token 
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /*
     * returns the symbol for the token 
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /*
     * returns the decimal count for the token 
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /*
     * returns the total supply of the token
     */
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    /*
     * returns the balance of tokens held by the account requested
     */
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    /*
     * returns boolean
     * transfer amount to recipient
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /*
     * return allowance of spender for owner
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /*
     * returns bool
     * approve spender to spend amount on _msgSender
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /*
     * returns bool
     * transfer amount from sender to rrecipient
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    /*
     * returns bool
     * increase allowance of spender by addedValue
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /*
     * returns bool
     * decrease allowance of spender by addedValue
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    /*
     * returns boolean of whether account is excluded from reward
     */
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    /*
     * returns total fees 
     */
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        (, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        uint256 currentRate = _getRate();

        if (!deductTransferFee) {
            (uint256 rAmount,,) = _getRValues(tAmount, tFee, tLiquidity, currentRate);
            return rAmount;

        } else {
            (, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, tLiquidity, currentRate);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    /*
     * exclude account from reward
     */
    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    /*
     * include account in reward
     */
    function includeInReward(address account) external onlyOwner {
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

    /*
     * set Marketing fee wallet
     */
    function setMarketingFeeWallet(address marketingFeeReceiver) external onlyOwner {
        _marketingFeeReceiver = marketingFeeReceiver;
    }
    
    /*
     * set Team wallet 
     */
    function setTeamWallet(address teamFeeReceiver) external onlyOwner {
        _teamFeeReceiver = teamFeeReceiver;
    }

    /*
     * set Dev wallet 
     */
    function setDevWallet(address devFeeReceiver) external onlyOwner {
        _devFeeReceiver = devFeeReceiver;
    }
    
    /*
     * set Community and Referral wallet
     */
    function setCommunityAndReferralWallet(address communityAndReferralFeeReceiver) external onlyOwner {
        _communityAndReferralFeeReceiver = communityAndReferralFeeReceiver;    
    }
    
    /*
     * set account to either be excluded or not excluded from fee dependant on bool(e) passed in
     */
    function setExcludedFromFee(address account, bool e) external onlyOwner {
        _isExcludedFromFee[account] = e;
    }

    /*
     * set liquidity fee percent i.e. the percentage being split between the sub fees
     */
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
    }

    /*
     * set percentage of liquidity fee for marketing fee wallet 
     */
    function setPercentageOfLiquidityForMarketingFee(uint256 marketingFee) external onlyOwner {
        _percentageOfLiquidityForMarketingFee = marketingFee;
    }
    
    /*
     * set percentage of liquidity fee for team wallet 
     */
    function setPercentageOfLiquidityForTeamFee(uint256 teamFee) external onlyOwner {
        _percentageOfLiquidityForTeamFee = teamFee;
    }

    /*
     * set percentage of liquidity fee for dev wallet 
     */
    function setPercentageOfLiquidityForDevFee(uint256 devFee) external onlyOwner {
        _percentageOfLiquidityForDevFee = devFee;
    }

    /*
     * set max transaction amount
     */
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    /*
     * set swap and liquify to either enabled or disabled dependant on the bool(e) passed in
     */
    function setSwapAndLiquifyEnabled(bool e) public onlyOwner {
        _swapAndLiquifyEnabled = e;
        emit SwapAndLiquifyEnabledUpdated(e);
    }
    
    /*
     * allows the contract to recieve payments 
     */
    receive() external payable {}
    
    // TODO: add withdrawal function

    /*
     * set uniswapV2Router address
     */
    function setUniswapRouter(address r) external onlyOwner {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(r);
        _uniswapV2Router = uniswapV2Router;
    }

    /*
     * set uniswapV2Pair address 
     */
    function setUniswapPair(address p) external onlyOwner {
        _uniswapV2Pair = p;
    }

    /*
     * set address(a) to be either excluded or included in auto liquidity based on bool(b) passed in
     */
    function setExcludedFromAutoLiquidity(address a, bool b) external onlyOwner {
        _isExcludedFromAutoLiquidity[a] = b;
    }

    /*
     * calculate reflection fee and update totals
     */
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal    = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    /*
     * get tValues
     */
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee       = calculateFee(tAmount, _taxFee);
        uint256 tLiquidity = calculateFee(tAmount, _liquidityFee);
        uint256 tTransferAmount = tAmount.sub(tFee);
        tTransferAmount = tTransferAmount.sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    /*
     * get rValues
     */
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount    = tAmount.mul(currentRate);
        uint256 rFee       = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        rTransferAmount = rTransferAmount.sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    /*
     * get the current supply
     */
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

    /*
     * calcs and takes the transaction fee
     */
    function takeTransactionFee(address to, uint256 tAmount, uint256 currentRate) private {
        if (tAmount <= 0) { return; }

        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        if (_isExcluded[to]) {
            _tOwned[to] = _tOwned[to].add(tAmount);
        }
    }
    
    /*
     * calcs fee into .00 format
     */
    function calculateFee(uint256 amount, uint256 fee) private pure returns (uint256) {
        return amount.mul(fee).div(100);
    }
    
    /*
     * returns bool
     * see if account is excluded from fee 
     */
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    /*
     * appove spender for amount on owner 
     * used internal
     */
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /*
     * transfer FROM TO for AMOUNT
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        /*
            - swapAndLiquify will be initiated when token balance of this contract
            has accumulated enough over the minimum number of tokens required.
            - don't get caught in a circular liquidity event.
            - don't swapAndLiquify if sender is uniswap pair.
        */
        uint256 contractTokenBalance = balanceOf(address(this));
        
        // check that there are more or equal tokens in contract than max transaction amount 
        // if true set to max transaction amount
        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }
        
        // boolean condition for SaL to occur
        // must meet below + not be in SaL + not from address not be excluded from SaL + SaL must be enabled
        bool isOverMinTokenBalance = contractTokenBalance >= _minTokenBalance;
        if (
            isOverMinTokenBalance &&
            !_inSwapAndLiquify &&
            !_isExcludedFromAutoLiquidity[from] &&
            _swapAndLiquifyEnabled
        ) {
            swapAndLiquify(contractTokenBalance);
        }

        // dont take fee if from or to is excluded 
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }

    /*
     * locktheswap modifier 
     * read the comments for explanation
     */
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split contract balance into halves
        uint256 half      = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        /*
            capture the contract's current BNB balance.
            this is so that we can capture exactly the amount of BNB that
            the swap creates, and not make the liquidity event include any BNB
            that has been manually sent to the contract.
        */
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBnb(half);
        
        // this is the amount of BNB that we just swapped into
        uint256 newBalance = address(this).balance.sub(initialBalance);
        
        // take marketing fee
        uint256 marketingFee = newBalance.mul(_percentageOfLiquidityForMarketingFee).div(100);
        
        // take team fee
        uint256 teamFee = newBalance.mul(_percentageOfLiquidityForTeamFee).div(100);

        // take dev fee
        uint256 devFee = newBalance.mul(_percentageOfLiquidityForDevFee).div(100);
        
        // take community and referral fees
        uint256 communityAndReferralFee = newBalance.mul(_percentageOfLiquidityForCommunityAndReferralFee).div(100);
        
        // add fees together to get total fees to sub
        uint256 txFees = marketingFee.add(teamFee).add(devFee).add(communityAndReferralFee);
        
        // sub fees to get bnbForLiquidity
        uint256 bnbForLiquidity = newBalance.sub(txFees);
        
        // pay marketing wallet and emit event
        if (marketingFee > 0) {
            payable(_marketingFeeReceiver).transfer(marketingFee);
            emit MarketingFeeSent(_marketingFeeReceiver, marketingFee);
        }
        
        // pay team wallet and emit event
        if (teamFee > 0) {
            payable(_teamFeeReceiver).transfer(teamFee);
            emit TeamFeeSent(_teamFeeReceiver, teamFee);
        }

        // pay dev wallet and emit event
        if (devFee > 0) {
            payable(_devFeeReceiver).transfer(devFee);
            emit DevFeeSent(_devFeeReceiver, devFee);
        }
        
        // pay community and referral wallet and emit event
        if (communityAndReferralFee > 0) {
            payable(_communityAndReferralFeeReceiver).transfer(communityAndReferralFee);
            emit CommunityAndReferralFeeSent(_communityAndReferralFeeReceiver, communityAndReferralFee);
        }

        // add liquidity to uniswap
        addLiquidity(otherHalf, bnbForLiquidity);
        
        emit SwapAndLiquify(half, bnbForLiquidity, otherHalf);
    }
    
    /*
     * swap tokenAmount for bnb
     * used internally in SwapAndLiquify
     */
    function swapTokensForBnb(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    /*
     * add liquidity in amounts passed in using uniswapV2Router addLiquidityETH function
     * used internally in SwapAndLiquify
     */
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    /*
     * internal token transfer function used in _transfer
     */
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        uint256 previousTaxFee       = _taxFee;
        uint256 previousLiquidityFee = _liquidityFee;
        
        // if takeFee is false set fees to 0
        if (!takeFee) {
            _taxFee       = 0;
            _liquidityFee = 0;
        }
        // calc burn amount from fee
        uint256 burnAmount = amount.mul(_percentageOfLiquidityForBurnFee).div(100);
        // calc new amount to transfer by subbing burn amount from amount passed in
        uint256 newAmount = amount.sub(burnAmount);
        
        // burn tokens 
        if(burnAmount > 0) {
            payable(_burnFeeReceiver).transfer(burnAmount);
            emit BurnFeeSent(_burnFeeReceiver, burnAmount);
        }
        
        // sender is excluded 
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, newAmount);
        // recipient is excluded
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, newAmount);
        // neither are excluded 
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, newAmount);
        // both are excluded
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, newAmount);
        // default
        } else {
            _transferStandard(sender, recipient, newAmount);
        }
        // reset fees if bool was met above
        if (!takeFee) {
            _taxFee       = previousTaxFee;
            _liquidityFee = previousLiquidityFee;
        }
    }

    /*
     * standard transfer function called internally when neither sender nor recipient is excluded from fee
     */
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, currentRate);

        _rOwned[sender]    = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /*
     * transfer function called internally when both sender and recipient is excluded from fee
     */
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /*
     * transfer function called internally when only recipient is excluded from fee
     */
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /*
     * transfer function called internally when only sender is excluded from fee
     */
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

}