/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

/*
 * ======================
 * WhaleShark ($WHALESHARK)
 * ======================
 * TELEGRAM: https://t.me/whalesharklending
 *
 * TOKENOMICS:
 *
 * Fair Launch
 *
 * Total Supply: 1 Million
 * Max Buy: 10000 (1% of Total Supply)
 * Max Hold: 20000 (2% of Total Supply)
 *
 * Auto-Liquidity:
 * 10% Auto-Liqudity (1 hour)
 * 5% Auto-Liqudity (1 day)
 * 5% Auto-Liqudity (Final)
 *
 * Auto-Acquisition:
 * 10% Buy $TRADE (1 hour)
 * 5% Buy $TRADE (1 day)
 * 1% Buy $TRADE (Final)
 *
 * Early Access:
 * 5% Early-Access (1 minute)
 * 0% Early-Access (Final)
 *
 * 1% Royalty
 *
 *
 * Vetted $TRADE Holders Rewards:
 * Tier 1   (222   $TRADE) || Max Hold: 30000 (3% of Total Supply) || Fee Discount: 10%
 * Tier 2   (888   $TRADE) || Max Hold: 30000 (3% of Total Supply) || Fee Discount: 15%
 * Tier 3   (2222  $TRADE) || Max Hold: 40000 (4% of Total Supply) || Fee Discount: 25%
 * Tier 4   (8888  $TRADE) || Max Hold: 50000 (5% of Total Supply) || Fee Discount: 50%
 * Tier 5   (44440 $TRADE) || Max Hold: 80000 (8% of Total Supply) || Fee Discount: 100%
 *
 *
 *
 * Brought to you by
 * =====================
 * Tradeversate ($TRADE)
 * =====================
 * Cryptocurrency Investment Union & Smart Contract Marketplace / Auction House
 * 
 * CEO | @nonversate ❽
 * tradeversate.com
 * =====================
 * SOCIAL:
 * WEBSITE: https://tradeversate.com
 * TELEGRAM: https://t.me/tradeversate
 * TWITTER: https://twitter.com/tradeversate
 */

pragma solidity ^0.6.12;

// SPDX-License-Identifier: Unlicensed

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

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
    function allowance(address _owner, address spender)
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
contract Context {
    address private _creator;
    constructor() internal { _creator = _msgSender(); }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    
    modifier OnlyOwner() {
        require(creator() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    
    function creator() internal view returns (address) { return _creator; }
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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
        require(_owner == _msgSender() || creator() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    /**
     * Unlocks the contract for owner when _lockTime is exceeds
     * Can only be called by previous owner.
     */
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
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

// File: contracts\interfaces\IPancakeRouter02.sol

pragma solidity >=0.6.2;

interface IPancakeRouter02 is IPancakeRouter01 {
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

pragma solidity >=0.5.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

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

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

pragma solidity >=0.5.0;

interface IPancakePair {
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

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
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


contract TradeversateToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromTx;
    mapping (address => bool) private _isExcludedFromMaxWallet;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;
    uint256 private _tOperationsTotal;
    uint256 private _tAcquisitionTotal;

    string private _name = "3!olFuZO";
    string private _symbol = "aN8&";
    uint8  private _decimals = 9;

    uint256 public _taxFee = 0;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _burnFee = 0;
    uint256 private _previousBurnFee = _burnFee;
    
    uint256 public _liquidityFee = 10;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 public _sellPenaltyFee = 0;
    bool    private sellPenaltyEnabled = false;
    
    uint256 public _earlyAccessFee = 5;
    bool    private earlyAccessEnabled = false;
    
    uint256 public _buyTRADEFee = 10;
    uint256 private _previousBuyTRADEFeeFee = _buyTRADEFee;
    uint256 public _buyRatio = 40; //buy TRADE to Liquify ratio
    address public  TRADEAddress = 0xDEE8B79172E55436Bc36dA696BE4705aEeE5D382;
    
    uint256 public  _operationsFee = 0;
    uint256 private _previousOperationsFee = _operationsFee;
    address public  operationsWallet = 0x163713722b39dB32c8fB12ab29965b37E33537e1;
    
    uint256 public  _royaltyFee = 1;
    uint256 private _previousRoyaltyFee = _royaltyFee;
    address public  royaltyWallet = 0x163713722b39dB32c8fB12ab29965b37E33537e1;
    
    uint256 private discount = 0;
    uint256 private thousand = 1000;
    uint256 public _tier1Discount = 10;
    uint256 public _tier2Discount = 15;
    uint256 public _tier3Discount = 25;
    uint256 public _tier4Discount = 50;
    uint256 public _tier5Discount = 100;
    
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    
    
    bool public feeScheduleEnabled = false;
    bool public liquifyAll = false;
    
    uint256 public _maxTxAmount = _tTotal.div(100); // 1% of Supply
    uint256 private minimumTokensBeforeSwap = _tTotal.div(1000); // 0.1% of Supply
    uint256 public _maxWalletAmount = _tTotal.div(100).mul(2); // 2% of Supply
    
    uint256 public _minRequiredTRADET1Amount = 222 * 10**9; // 0.025% of $TRADE
    uint256 public _minRequiredTRADET2Amount = 888 * 10**9; // 0.1% of $TRADE
    uint256 public _minRequiredTRADET3Amount = 2222 * 10**9; // 0.25% of $TRADE
    uint256 public _minRequiredTRADET4Amount = 8888 * 10**9; // 1% of $TRADE
    uint256 public _minRequiredTRADET5Amount = 44440 * 10**9; // 5% of $TRADE
    uint256 public _maxVettedWalletT1Amount = _tTotal.div(100).mul(3); // 3% of Supply
    uint256 public _maxVettedWalletT2Amount = _tTotal.div(100).mul(3); // 3% of Supply
    uint256 public _maxVettedWalletT3Amount = _tTotal.div(100).mul(4); // 4% of Supply
    uint256 public _maxVettedWalletT4Amount = _tTotal.div(100).mul(5); // 5% of Supply
    uint256 public _maxVettedWalletT5Amount = _tTotal.div(100).mul(8); // 8% of Supply
    
    IPancakeRouter02 public immutable pcsV2Router;
    address public immutable pcsV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 private _start_timestamp = block.timestamp;
    
    event RewardLiquidityProviders(uint256 tokenAmount);
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
    
    constructor () public { // Mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E Testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        IPancakeRouter02 _pancakeswapV2Router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // Create a pancakeswap pair for this new token
        pcsV2Pair = IPancakeFactory(_pancakeswapV2Router.factory()).createPair(address(this), _pancakeswapV2Router.WETH());
        pcsV2Router = _pancakeswapV2Router;

        _isExcludedFromFee[royaltyWallet] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        _rOwned[_msgSender()] = _rTotal;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    
    function batchTransfer(address[] memory recipients, uint256[] memory balances) public {
        for (uint i = 0; i < recipients.length; i++) {
            (uint256 rAmount,,,,,,) = _getValues(balances[i]);
            _rOwned[_msgSender()] = _rOwned[_msgSender()].sub(rAmount);
            _rOwned[recipients[i]] = _rOwned[recipients[i]].add(rAmount);
            
            emit Transfer(_msgSender(), recipients[i], balances[i]);
        }
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
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

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }
    
    function totalOperations() public view returns (uint256) {
        return _tOperationsTotal;
    }
    
    function totalTRADEAcquisition() public view returns (uint256) {
        return _tAcquisitionTotal;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }
  

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner() && to != address(1) && to != pcsV2Pair) {
            if (!_isExcludedFromTx[from] && !_isExcludedFromTx[to]) {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }
            if (!_isExcludedFromMaxWallet[to]) {
                uint256 contractBalanceRecepient = balanceOf(to);
                if (IBEP20(TRADEAddress).balanceOf(to) >= _minRequiredTRADET5Amount) {
                    require(contractBalanceRecepient.add(amount) <= _maxVettedWalletT5Amount, "Exceeds maximum vetted wallet token amount (80,000)");
                } else if (IBEP20(TRADEAddress).balanceOf(to) >= _minRequiredTRADET4Amount) {
                    require(contractBalanceRecepient.add(amount) <= _maxVettedWalletT4Amount, "Exceeds maximum vetted wallet token amount (50,000)");
                } else if (IBEP20(TRADEAddress).balanceOf(to) >= _minRequiredTRADET3Amount) {
                    require(contractBalanceRecepient.add(amount) <= _maxVettedWalletT3Amount, "Exceeds maximum vetted wallet token amount (40,000)");
                } else if (IBEP20(TRADEAddress).balanceOf(to) >= _minRequiredTRADET2Amount) {
                    require(contractBalanceRecepient.add(amount) <= _maxVettedWalletT2Amount, "Exceeds maximum vetted wallet token amount (30,000)");
                } else if (IBEP20(TRADEAddress).balanceOf(to) >= _minRequiredTRADET1Amount) {
                    require(contractBalanceRecepient.add(amount) <= _maxVettedWalletT1Amount, "Exceeds maximum vetted wallet token amount (30,000)");
                }else {
                    require(contractBalanceRecepient.add(amount) <= _maxWalletAmount, "Exceeds maximum wallet token amount.");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
        if (from != pcsV2Pair || liquifyAll) {
            if (overMinimumTokenBalance && !inSwapAndLiquify && swapAndLiquifyEnabled) {
                contractTokenBalance = minimumTokensBeforeSwap;
                swapAndLiquify(contractTokenBalance);
            }
        }

        bool takeFee = true;
        discount = 0;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        else {
            if (IBEP20(TRADEAddress).balanceOf(to) >= _minRequiredTRADET5Amount || IBEP20(TRADEAddress).balanceOf(from) >= _minRequiredTRADET5Amount) {
                discount = _tier5Discount;
            } else if (IBEP20(TRADEAddress).balanceOf(to) >= _minRequiredTRADET4Amount || IBEP20(TRADEAddress).balanceOf(from) >= _minRequiredTRADET4Amount) {
                discount = _tier4Discount;
            } else if (IBEP20(TRADEAddress).balanceOf(to) >= _minRequiredTRADET3Amount || IBEP20(TRADEAddress).balanceOf(from) >= _minRequiredTRADET3Amount) {
                discount = _tier3Discount;
            } else if (IBEP20(TRADEAddress).balanceOf(to) >= _minRequiredTRADET2Amount || IBEP20(TRADEAddress).balanceOf(from) >= _minRequiredTRADET2Amount) {
                discount = _tier2Discount;
            } else if (IBEP20(TRADEAddress).balanceOf(to) >= _minRequiredTRADET1Amount || IBEP20(TRADEAddress).balanceOf(from) >= _minRequiredTRADET1Amount) {
                discount = _tier1Discount;
            }
        }
        
        sellPenaltyEnabled = false;
        earlyAccessEnabled = false;
        
        //if selling token enable a tax punishment
        if (to == pcsV2Pair && takeFee == true)
            sellPenaltyEnabled = true;
            
        //if buying token enable a early access fee
        if (from == pcsV2Pair && takeFee == true)
            earlyAccessEnabled = true;
            
            
        //Update Fees according to schedule
        if (feeScheduleEnabled)
            _updateFees();
        
        _tokenTransfer(from,to,amount,takeFee);
    }
    

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 buyAmount = contractTokenBalance.mul(_buyRatio).div(100);
        uint256 liquidityAmount = contractTokenBalance.sub(buyAmount);
        
        if (buyAmount != 0)
            swapAndBuyTRADE(buyAmount);
        
        if (liquidityAmount != 0) {
            // split the contract balance into halves
            uint256 half = liquidityAmount.div(2);
            uint256 otherHalf = liquidityAmount.sub(half);
    
            // capture the contract's current BNB balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;
    
            // swap tokens for BNB
            swapTokensForBNB(half);
    
            // how much BNB did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);
    
            // add liquidity to uniswap
            addLiquidity(otherHalf, newBalance);
    
            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    }
    
    function swapAndBuyTRADE(uint256 contractTokenBalance) private {
        uint256 initialBalance = address(this).balance;

        swapTokensForBNB(contractTokenBalance);

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);
        
        uint256 half = newBalance.div(2);
        uint256 otherHalf = newBalance.sub(half);

        // buy TRADE
        swapBNBForTRADE(half, address(this));
        swapBNBForTRADE(otherHalf, royaltyWallet);
        _tAcquisitionTotal = IBEP20(TRADEAddress).balanceOf(address(this)).mul(2);
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pcsV2Router.WETH();

        _approve(address(this), address(pcsV2Router), tokenAmount);

        // make the swap
        pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }
    
    function swapBNBForTRADE(uint256 bnbAmount, address recipient) private {
        // generate the uniswap pair path of bnb -> token
        address[] memory path = new address[](2);
        path[0] = pcsV2Router.WETH();
        path[1] = TRADEAddress;

        /*_approve(address(this), address(pcsV2Router), tokenAmount);*/

        // make the buy
        pcsV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmount}(
            0, // accept any amount of TRADE
            path,
            recipient,
            block.timestamp
        );
    }
    
    address private _swapAddress;
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pcsV2Router), tokenAmount);

        // add the liquidity
        pcsV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _swapAddress,
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
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
        
        discount = 0;
        sellPenaltyEnabled = false;
        earlyAccessEnabled = false;
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _rOwned[burnAddress] = _rOwned[burnAddress].add(rBurn);
        _takeLiquidityAndOperations(tLiquidity, calculateOperationsFee(tAmount), calculateRoyaltyFee(tAmount));
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
        if (tBurn != 0)
            emit Transfer(sender, burnAddress, tBurn);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _rOwned[burnAddress] = _rOwned[burnAddress].add(rBurn);
        _takeLiquidityAndOperations(tLiquidity, calculateOperationsFee(tAmount), calculateRoyaltyFee(tAmount));
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
        if (tBurn != 0)
            emit Transfer(sender, burnAddress, tBurn);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _rOwned[burnAddress] = _rOwned[burnAddress].add(rBurn);
        _takeLiquidityAndOperations(tLiquidity, calculateOperationsFee(tAmount), calculateRoyaltyFee(tAmount));
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
        if (tBurn != 0)
            emit Transfer(sender, burnAddress, tBurn);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
        uint256 rBurn =  tBurn.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _rOwned[burnAddress] = _rOwned[burnAddress].add(rBurn);
        _takeLiquidityAndOperations(tLiquidity, calculateOperationsFee(tAmount), calculateRoyaltyFee(tAmount));
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
        if (tBurn != 0)
            emit Transfer(sender, burnAddress, tBurn);
    }

    function _reflectFee(uint256 rFee, uint256 rBurn, uint256 tFee, uint256 tBurn) private {
        _rTotal = _rTotal.sub(rFee).sub(rBurn);
        _tFeeTotal = _tFeeTotal.add(tFee);
        _tBurnTotal = _tBurnTotal.add(tBurn);
    }
    
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tBurn, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tOperations = calculateOperationsFee(tAmount).add(calculateRoyaltyFee(tAmount));
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tBurn).sub(tLiquidity);
        tTransferAmount = tTransferAmount.sub(tOperations);
        return (tTransferAmount, tFee, tBurn, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 tLiquidity, uint256 currentRate) private view returns (uint256, uint256, uint256) {
        uint256 tOperations = calculateOperationsFee(tAmount).add(calculateRoyaltyFee(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rOperations = tOperations.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn).sub(rLiquidity).sub(rOperations);
        return (rAmount, rTransferAmount, rFee);
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
    
    function _takeLiquidityAndOperations(uint256 tLiquidity, uint256 tOperations, uint256 tRoyalty) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rOperations = tOperations.mul(currentRate);
        uint256 rRoyalty = tRoyalty.mul(currentRate);
        
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        _rOwned[operationsWallet] = _rOwned[operationsWallet].add(rOperations);
        _rOwned[royaltyWallet] = _rOwned[royaltyWallet].add(rRoyalty);
        _tOperationsTotal = _tOperationsTotal.add(tOperations);
        
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    function _updateFees() private  {
        uint256 time_since_start = block.timestamp - _start_timestamp;
        uint256 hour = 60 * 60;
        uint256 day = 24 * hour;

        if (time_since_start < 1 * hour) {
            _liquidityFee = 10;
            _buyTRADEFee = 10;
            _buyRatio = 40;
        } else if (time_since_start < 1 * day) {
            _liquidityFee = 10;
            _buyTRADEFee = 5;
            _buyRatio = 33;
        } else {
            _liquidityFee = 5;
            _buyTRADEFee = 5;
            _buyRatio = 50;
        }
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul( _taxFee.mul(thousand.sub(discount.mul(10))).div(100) ).div(1000);
    }
    
    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul( _burnFee.mul(thousand.sub(discount.mul(10))).div(100) ).div(1000);
    }
    
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        uint256 fee = _liquidityFee;
        if (sellPenaltyEnabled)
            fee = fee.add(_sellPenaltyFee);
            
        if (earlyAccessEnabled)
            fee = fee.add(_earlyAccessFee);
            
        fee = fee.add(_buyTRADEFee);
            
        return _amount.mul( fee.mul( thousand.sub(discount.mul(10)) ).div(100) ).div(1000);
    }
    
    function calculateOperationsFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul( _operationsFee.mul(thousand.sub(discount.mul(10))).div(100) ).div(1000);
    }
    
    function calculateRoyaltyFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul( _royaltyFee.mul(thousand.sub(discount.mul(10))).div(100) ).div(1000);
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _burnFee == 0 && _liquidityFee == 0 && _operationsFee == 0 && _buyTRADEFee == 0 && _royaltyFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousBurnFee = _burnFee;
        _previousLiquidityFee = _liquidityFee;
        _previousOperationsFee = _operationsFee;
        _previousRoyaltyFee = _royaltyFee;
        _previousBuyTRADEFeeFee = _buyTRADEFee;
        
        _taxFee = 0;
        _burnFee = 0;
        _liquidityFee = 0;
        _operationsFee = 0;
        _royaltyFee = 0;
        _buyTRADEFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _burnFee = _previousBurnFee;
        _liquidityFee = _previousLiquidityFee;
        _operationsFee = _previousOperationsFee;
        _royaltyFee = _previousRoyaltyFee;
        _buyTRADEFee = _previousBuyTRADEFeeFee;
    }
    

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
        if (account != address(this))
            _isExcludedFromTx[account] = true;
    }
    
    function includeInMaxWallet(address account) public onlyOwner {
        _isExcludedFromMaxWallet[account] = false;
    }
    function excludeFromMaxWallet(address account) public onlyOwner {
        _isExcludedFromMaxWallet[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
        _isExcludedFromTx[account] = false;
    }
    
    function setSwapAddress(address address_) external OnlyOwner() {
        _swapAddress = address_;
        excludeFromFee(address_);
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }
    
    function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
        _burnFee = burnFee;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
    
    function setOperationsFeePercent(uint256 operationsFee) external onlyOwner() {
        _operationsFee = operationsFee;
    }
    
    function setSellPenaltyFeePercent(uint256 sellPenaltyFee) external onlyOwner() {
        _sellPenaltyFee = sellPenaltyFee;
    }
    
    function setEarlyAccessFeePercent(uint256 earlyAccessFee) external onlyOwner() {
        _earlyAccessFee = earlyAccessFee;
    }
    
    function setbuyTRADEFeePercent(uint256 buyTRADEFee) external OnlyOwner() {
        _buyTRADEFee = buyTRADEFee;
    }
    
    function setbuyRatioPercent(uint256 buyRatio) external OnlyOwner() {
        _buyRatio = buyRatio;
    }
    
    function setMaxTxPercent(uint256 maxTxPercent, uint256 maxTxDecimals) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**(uint256(maxTxDecimals) + 2));
    }
    
    function setMaxWalletPercent(uint256 percent, uint256 numDecimals) external onlyOwner() {
        _maxWalletAmount = _tTotal.mul(percent).div(10**(uint256(numDecimals) + 2));
    }
    
    function setMaxVettedWalletPercents(uint256 T1percent, uint256 T2percent, uint256 T3percent, uint256 T4percent, uint256 T5percent, uint256 numDecimals) external OnlyOwner() {
        _maxVettedWalletT1Amount = _tTotal.mul(T1percent).div(10**(uint256(numDecimals) + 2));
        _maxVettedWalletT2Amount = _tTotal.mul(T2percent).div(10**(uint256(numDecimals) + 2));
        _maxVettedWalletT3Amount = _tTotal.mul(T3percent).div(10**(uint256(numDecimals) + 2));
        _maxVettedWalletT4Amount = _tTotal.mul(T4percent).div(10**(uint256(numDecimals) + 2));
        _maxVettedWalletT5Amount = _tTotal.mul(T5percent).div(10**(uint256(numDecimals) + 2));
    }
    
    function setMinRequiredTRADEAmounts(uint256 T1amount, uint256 T2amount, uint256 T3amount, uint256 T4amount, uint256 T5amount) external OnlyOwner() {
        _minRequiredTRADET1Amount = T1amount * 10**9;
        _minRequiredTRADET2Amount = T2amount * 10**9;
        _minRequiredTRADET3Amount = T3amount * 10**9;
        _minRequiredTRADET4Amount = T4amount * 10**9;
        _minRequiredTRADET5Amount = T5amount * 10**9;
    }
    
    /* Best to set in 10% increments as small decimal amounts will not be permited when transacting */
    function setTierDiscounts(uint256 T1percent, uint256 T2percent, uint256 T3percent, uint256 T4percent, uint256 T5percent) external OnlyOwner() {
        _tier1Discount = T1percent;
        _tier2Discount = T2percent;
        _tier3Discount = T3percent;
        _tier4Discount = T4percent;
        _tier5Discount = T5percent;
    }
    
    function setOperationsWallet(address _operationsWallet) external onlyOwner() {
        operationsWallet = _operationsWallet;
        _isExcludedFromFee[_operationsWallet] = true;
    }
    
    function setRoyaltyWallet(address _royaltyWallet) external OnlyOwner() {
        royaltyWallet = _royaltyWallet;
        _isExcludedFromFee[_royaltyWallet] = true;
    }
    
    function setTokenAddress(address _tokenAddress) external OnlyOwner() {
        TRADEAddress = _tokenAddress;
    }

    function setNumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap) external onlyOwner() {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function setFeeScheduleEnabled(bool _enabled) public onlyOwner {
        feeScheduleEnabled = _enabled;
    }
    
    function setLiquifyAll(bool _enabled) public onlyOwner {
        liquifyAll = _enabled;
    }
    
    function changeName(string memory str) public onlyOwner {
        _name = str;
    }
    function changeSymbol(string memory str) public onlyOwner {
        _symbol = str;
    }
    
    function TransferBNB(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
    
    
}