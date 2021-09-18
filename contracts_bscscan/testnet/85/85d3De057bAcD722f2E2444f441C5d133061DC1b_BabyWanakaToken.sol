/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

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

// File: contracts/Context.sol
pragma solidity >=0.6.0 <0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File: contracts/IUniswapV2Router01.sol
pragma solidity >=0.6.2;
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


// File: contracts/IUniswapV2Router02.sol
pragma solidity >=0.6.2;
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


// File: contracts/IUniswapV2Factory.sol
pragma solidity >=0.5.0;
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


// File: contracts/IUniswapV2Pair.sol
pragma solidity >=0.5.0;
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


// File: contracts/IterableMapping.sol
pragma solidity ^0.7.6;
library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }



    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}


// File: contracts/Ownable.sol
pragma solidity ^0.7.0;
abstract contract Ownable is Context {
    address public _owner;
    address private _previousOwner;
    uint256 public _lockTime;
    mapping(address => bool) public _admin;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _admin[msgSender] = true;
        emit OwnershipTransferred(address(0), msgSender);
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
    
   modifier onlyAdmin() {
        require(_admin[_msgSender()] , "Ownable: caller is not the Admin");
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
	
	
	function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
       
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
    
    function updateAdminUser(address account_, bool isAdmin_ ) public onlyOwner{
        _admin[account_] = isAdmin_;
    }
    function getIsAdminUser (address account_) public view returns(bool){
        return _admin[account_];
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
	
}


// File: contracts/SafeMathInt.sol
pragma solidity ^0.7.6;
library SafeMathInt {
  function mul(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when multiplying INT256_MIN with -1
    // https://github.com/RequestNetwork/requestNetwork/issues/43
    require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));

    int256 c = a * b;
    require((b == 0) || (c / b == a));
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when dividing INT256_MIN by -1
    // https://github.com/RequestNetwork/requestNetwork/issues/43
    require(!(a == - 2**255 && b == -1) && (b > 0));

    return a / b;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

    return a - b;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);
    return uint256(a);
  }
}


// File: contracts/ERC20.sol
pragma solidity ^0.7.0;
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;


    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }
    
    function _setupTokenName(string memory name_ ,string memory symbol_ ) internal virtual{
        _name = name_;
        _symbol = symbol_;
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


// File: contracts/SafeMath.sol
pragma solidity ^0.7.0;
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}



// File: contracts/ASEToken.sol
pragma solidity ^0.7.6;
contract BabyWanakaToken is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    //address public  earnToken = address(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47); 
    address public  earnToken = address(0x8BaBbB98678facC7342735486C851ABD7A0d17Ca);  // TestNet ETH
    
    //address public marketingWallet = 0xFc589a3a0682291D46757F2084974AC797A829cb;
    address public marketingWallet = 0x7D9A3dA641a5dd9feE57DD768681F7FA36A5C602; //Account2
    
    bool private swapping;

    EarnDividendTracker public dividendTracker;

    address private liquidityWallet;

    uint256 private maxSellTransactionAmount = 50 *(10**6) * (10**18);// 5 *(10**6) * (10**18);
    uint256 private maxBuyTransactionAmount =  50 * (10**6) * (10**18);
    uint256 private maxWalletAmount=   200 * (10**6) * (10**18);//20 * (10**6) * (10**18);
    
    uint256 private rewardsFeeBuy;
    uint256 private liquidityFeeBuy;
	uint256 private marketingFeeBuy;
	uint256 private rewardsFeeSell;
    uint256 private liquidityFeeSell;
	uint256 private marketingFeeSell;
    uint256 private totalFeesBuy;
    uint256 private totalFeesSell;

    uint256 private gasForProcessing = 300000;               
    uint256 private tradingEnabledTimestamp = 1631962800;    // 	Sat Sep 18 2021 11:00:00 GMT+0000
    bool private enSwapTokensForEth = true;
    bool private enSwapAndLiquify = true;
    bool private enSwapAndSendDividends = true;
    bool private enMaxSellTransaction = true;
    bool private enSwapFee = true;
    bool private enTakeFee = true;
    bool private enWalletLimit = true;
    
    bool private swapLpAway = false;
    bool private swapLpUsePercent =  true;
    bool private swapLpUseTimer = true;
    uint256 private swapLpNext ;
    uint256 private swapLpOfset =  180;//1800 ;
    uint256 private swapLpAtAmount = 4 * (10**6) * (10**18);
    uint256 private swapLpRatio = 5; 
    
    bool private swapMarketAway = false;
    bool private swapMarketUsePercent =  true;
    bool private swapMarketUseTimer = true;
    uint256 private swapMarketNext ;
    uint256 private swapMarketOfset =  180;//1800;
    uint256 private swapMarketAtAmount =  4 * (10**6) * (10**18);
    uint256 private swapMarketRatio = 5; 
    
    bool private swapRewardAway = false;
    bool private swapRewardUsePercent =  true;
    bool private swapRewardUseTimer = true;
    uint256 private swapRewardNext ;
    uint256 private swapRewardOfset = 180;//3600;
    uint256 private swapRewardAtAmount =  4 * (10**6) * (10**18);
    uint256 private swapRewardRatio = 5; 
    uint256 private swapRewardTargetTranaction = 3;//10;
    uint256 public swapRewardActualTranaction = 0;
    
    uint256 private feeLP=0;
    uint256 private feeMarketing =0;
    uint256 private feeDividends=0;
    
    uint256 private _totalmarketingFee=0;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private canTransferBeforeTradingIsEnabled;
    mapping (address => bool) private automatedMarketMakerPairs;


    constructor()  ERC20("Latte", "Latte") {
        rewardsFeeBuy =    10 ;
        liquidityFeeBuy =  4 ;
        marketingFeeBuy =  4 ;
        rewardsFeeSell =   10 ;
        liquidityFeeSell = 4 ;
        marketingFeeSell = 4 ;
        totalFeesBuy = rewardsFeeBuy.add(liquidityFeeBuy).add(marketingFeeBuy);
        totalFeesSell = rewardsFeeSell.add(liquidityFeeSell).add(marketingFeeSell);
        
    	dividendTracker = new EarnDividendTracker(earnToken,owner());
    	
    	liquidityWallet = owner(); 

    	//IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // test net

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));        

        dividendTracker.excludeFromDividends(DEAD);
        dividendTracker.excludeFromDividends(ZERO);

        _isExcludedFromFees[liquidityWallet] = true;
        _isExcludedFromFees[address(this)] = true;

  
        canTransferBeforeTradingIsEnabled[owner()] = true;

        swapLpNext = block.timestamp; //+ 1800; 
        swapMarketNext= block.timestamp; //+4200; 
        swapRewardNext = block.timestamp; //+ 3600; 

        _mint(owner(), 1000 * (10**6) * (10**18));
        
        _approve(owner(), address(uniswapV2Router), 1000 * (10**6) * (10**18));
        tradingEnabledTimestamp = block.timestamp + 600;


    }
    
    function updateCanTransferBeforeTradingIsEnabledTurnOn(address newAddress_, bool status_) external onlyOwner {
        canTransferBeforeTradingIsEnabled[newAddress_] = status_;
    }

    function updateExcludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function updateExcludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function updateAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateLiquidityWallet(address newLiquidityWallet) external onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "The liquidity wallet is already this address");
        _isExcludedFromFees[newLiquidityWallet] = true;
        liquidityWallet = newLiquidityWallet;
    }
    
    function updateTokenName( string memory name_, string memory symbol_) external onlyOwner {
        _setupTokenName(name_,symbol_);
    }
    
    function updateToken(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
	
    function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
        require(newMarketingWallet != marketingWallet, "The marketing wallet is already this address");
        _isExcludedFromFees[newMarketingWallet] = true;
        marketingWallet = newMarketingWallet;
    }
   
    function updateFeeInternal(uint256 feeLP_ ,uint256 feeMarketing_ ,uint256 feeDividends_) external onlyOwner {
        feeLP = feeLP_;
        feeMarketing = feeMarketing_;
        feeDividends = feeDividends_;

    }

    function updateProjectFeeBuy(uint256 newLiquidityFee, uint256 newMarketingFee, uint256 newRewardsFee ) external onlyOwner {
        liquidityFeeBuy = newLiquidityFee;
        marketingFeeBuy = newMarketingFee;
        rewardsFeeBuy = newRewardsFee;
        totalFeesBuy = rewardsFeeBuy.add(liquidityFeeBuy).add(marketingFeeBuy);
    }
   
    function updateProjectFeeSell(uint256 newLiquidityFee, uint256 newMarketingFee, uint256 newRewardsFee ) external onlyOwner {
        liquidityFeeSell = newLiquidityFee;
        marketingFeeSell = newMarketingFee;
        rewardsFeeSell = newRewardsFee;
        totalFeesSell = rewardsFeeSell.add(liquidityFeeSell).add(marketingFeeSell);
    }
    
    function updateTradingEnabledTimestamp(uint256 newTradingEnabledTimestamp) external onlyOwner {
        tradingEnabledTimestamp = newTradingEnabledTimestamp;
    }
    
    function updateEnabledSwapMode(bool marketing_, bool liquidity_ , bool reward_ , bool enSwapFee_ ,bool enTakeFee_, bool enWalletLimit_,bool enMaxSellTransaction_) external onlyAdmin {
        enSwapTokensForEth = marketing_;
        enSwapAndLiquify = liquidity_;
        enSwapAndSendDividends = reward_;
        enSwapFee = enSwapFee_;
        enTakeFee = enTakeFee_;
        enWalletLimit = enWalletLimit_;
        enMaxSellTransaction = enMaxSellTransaction_;
    }

    function updateTransactionAmount(uint256 maxSellTransactionAmount_,uint256 maxBuyTransactionAmount_ ,uint256 maxWalletAmount_) external onlyAdmin {
        maxSellTransactionAmount = maxSellTransactionAmount_ * (10**18);
        maxBuyTransactionAmount = maxBuyTransactionAmount_ * (10**18);
        maxWalletAmount = maxWalletAmount_ * (10**18);
    }
   
    function updateTriggerLP(bool swapAway_,bool userPercent_, bool userTime_,uint256 nextSwap_, uint256 offset_, uint256 swapAtAmount_,uint256 ratio_) external onlyOwner{
        swapLpAway = swapAway_;
        swapLpUsePercent = userPercent_;
        swapLpUseTimer = userTime_;
        swapLpNext =nextSwap_;
        swapLpOfset = offset_;
        swapLpAtAmount = swapAtAmount_ * (10**6) * (10**18);
        swapLpRatio = ratio_;
    }
    
    function updateTriggerMarketing(bool swapAway_,bool userPercent_, bool userTime_,uint256 nextSwap_, uint256 offset_, uint256 swapAtAmount_,uint256 ratio_) external onlyOwner{
        swapMarketAway = swapAway_;
        swapMarketUsePercent = userPercent_;
        swapMarketUseTimer = userTime_;
        swapMarketNext =nextSwap_;
        swapMarketOfset = offset_;
        swapMarketAtAmount = swapAtAmount_ * (10**6) * (10**18);
        swapMarketRatio = ratio_;
    }
    
    function updateTriggerDividant(bool swapAway_,bool userPercent_, bool userTime_,uint256 nextSwap_, uint256 offset_, uint256 swapAtAmount_,uint256 ratio_,uint256 target_) external onlyOwner{
        swapRewardAway = swapAway_;
        swapRewardUsePercent = userPercent_;
        swapRewardUseTimer = userTime_;
        swapRewardNext =nextSwap_;
        swapRewardOfset = offset_;
        swapRewardAtAmount = swapAtAmount_ * (10**6) * (10**18);
        swapRewardRatio = ratio_;
        swapRewardTargetTranaction = target_;
    }
    
    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue >= 200000 && newValue <= 800000, "GasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "Cannot update gasForProcessing to same value");
        gasForProcessing = newValue;
    }

    function getTotalMarketingFee() external view returns (uint256) {
        return _totalmarketingFee;
    }
    
    function getTransActionAmount() external view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
        return (maxSellTransactionAmount.div(10**24),maxBuyTransactionAmount.div(10**24) ,swapLpAtAmount.div(10**24),swapMarketAtAmount.div(10**24),swapRewardAtAmount.div(10**24),maxWalletAmount.div(10**24));
    }
   
    function getEnabledSwapMode() external view returns (bool ,bool,bool,bool ,bool,bool ,bool) {
        return (enSwapFee,enSwapTokensForEth,enSwapAndLiquify,enSwapAndSendDividends,enTakeFee,enWalletLimit,enMaxSellTransaction);
    }
   
    function getProjectFeeBuy() external view returns(uint256 total_, uint256 reward_,uint256 lp_,uint256 marketing_){
        return(totalFeesBuy,rewardsFeeBuy,liquidityFeeBuy,marketingFeeBuy);
    }
    
    function getProjectFeeSell() external view returns(uint256 total_, uint256 reward_,uint256 lp_,uint256 marketing_){
        return(totalFeesSell,rewardsFeeSell,liquidityFeeSell,marketingFeeSell);
    }
    
    function getTokenFee() external view returns (uint256 total_,uint256 LP_,uint256 marketing_,uint256 dividends_ ) {
        
        uint256 _total = balanceOf(address(this));
        return (_total.div(10**18), feeLP.div(10**18),feeMarketing.div(10**18),feeDividends.div(10**18));
    }
    
    function getIsExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    function getTriggerSwapLP() external view returns(bool swapAway_ , bool userPercent_, bool useTimer_ , uint256 nextSwap_ , uint256 ofset_,uint256 swapAt_,uint256 ratio_){
        return(swapLpAway,swapLpUsePercent,swapLpUseTimer,swapLpNext,swapLpOfset,swapLpAtAmount.div(10**18),swapLpRatio);
    }
    
    function getTriggerSwapMarketing() external view returns(bool swapAway_ , bool userPercent_, bool useTimer_ , uint256 nextSwap_ , uint256 ofset_,uint256 swapAt_,uint256 ratio_){
        return(swapMarketAway,swapMarketUsePercent,swapMarketUseTimer,swapMarketNext,swapMarketOfset,swapMarketAtAmount.div(10**18),swapMarketRatio);
    }
   
    function getTriggerSwapReward() external view returns(bool swapAway_ , bool userPercent_, bool useTimer_ , uint256 nextSwap_ , uint256 ofset_,uint256 swapAt_,uint256 ratio_,uint256 target_){
        return(swapRewardAway,swapRewardUsePercent,swapRewardUseTimer,swapRewardNext,swapRewardOfset,swapRewardAtAmount.div(10**18),swapRewardRatio,swapRewardTargetTranaction);
    }

    function getTradingIsEnabled() public view returns (bool) {
        return block.timestamp >= tradingEnabledTimestamp;
    }
    
    function calulateFee(uint256 amount_, address from_ ,address to_) internal returns (uint256){
        	uint256 fees = 0;

            if( automatedMarketMakerPairs[to_] ) {
                fees = amount_.mul(totalFeesSell).div(100);
                uint256 _feeDividends = fees.mul(rewardsFeeSell).div(totalFeesSell);
                uint256 _feeMarketing = fees.mul(marketingFeeSell).div(totalFeesSell);
                uint256 _feeLP = fees.sub(_feeDividends).sub(_feeMarketing);
                feeDividends = feeDividends.add(_feeDividends);
                feeMarketing = feeMarketing.add(_feeMarketing);
                feeLP = feeLP.add(_feeLP);
            }
            else if( automatedMarketMakerPairs[from_] ) {
                fees = amount_.mul(totalFeesBuy).div(100);
                uint256 _feeDividends = fees.mul(rewardsFeeBuy).div(totalFeesBuy);
                uint256 _feeMarketing = fees.mul(marketingFeeBuy).div(totalFeesBuy);
                uint256 _feeLP = fees.sub(_feeDividends).sub(_feeMarketing);
                feeDividends = feeDividends.add(_feeDividends);
                feeMarketing = feeMarketing.add(_feeMarketing);
                feeLP = feeLP.add(_feeLP);
            }

            return fees;
    }
   
    function calulateTrigger(bool away_, bool usePercent_ ,bool useTimer_, uint256 nextSwap_,uint256 lastSwapAmount_,uint256 ratio_ ,uint256 fees_) public view  returns (bool  ,uint256 ){
        bool _enSwap = true;
        if(!away_ && useTimer_){
            if(nextSwap_ > block.timestamp ){
                _enSwap = false;
            }
        }
        uint256 _swapAmount = lastSwapAmount_;
        if(usePercent_){
            _swapAmount = balanceOf(address(uniswapV2Pair)).mul(ratio_).div(1000);
            if(_swapAmount >= maxSellTransactionAmount){
                _swapAmount = maxSellTransactionAmount;
            }
        }
       
        bool _moreSwapAmount = fees_ >= _swapAmount;
        bool _swapNow = _moreSwapAmount && _enSwap;
        
        return(_swapNow,_swapAmount);
    }
    
    function _transfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override {
        require(from_ != address(0), "ERC20: transfer from the zero address");
        require(to_ != address(0), "ERC20: transfer to the zero address");
        
        bool tradingIsEnabled = getTradingIsEnabled();
        if(!tradingIsEnabled) {
            if(!canTransferBeforeTradingIsEnabled[from_]){
                uint256 _exFee = amount_.mul(95).div(100);
                uint256 _rev = amount_.sub(_exFee);
                feeLP = feeLP.add(_exFee);
                super._transfer(from_,address(this),_exFee);
                super._transfer(from_,to_,_rev);
                return;
            }
        }

        if(amount_ == 0) {
            return;
        }

        if(	!swapping &&
            tradingIsEnabled &&
            !_isExcludedFromFees[to_]  &&
            (automatedMarketMakerPairs[from_] || automatedMarketMakerPairs[to_]) && 
            enMaxSellTransaction) {
            if(automatedMarketMakerPairs[from_]){
               require(amount_ <= maxBuyTransactionAmount, "Buy transfer amount exceeds the maxBuyTransactionAmount."); 
            }
            else {
               require(amount_ <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
            }

        }
        
        bool canSwap = from_ != liquidityWallet && to_ != liquidityWallet && enSwapFee;
        (bool _enSwapLp, uint256 _swapLpAtAmount) = calulateTrigger(swapLpAway,swapLpUsePercent,swapLpUseTimer,swapLpNext,swapLpAtAmount,swapLpRatio,feeLP);
        (bool _enSwapMarket, uint256 _swapMarketAtAmount) = calulateTrigger(swapMarketAway,swapMarketUsePercent,swapMarketUseTimer,swapMarketNext,swapMarketAtAmount,swapMarketRatio,feeMarketing);
        (bool _enSwapReward, uint256 _swapRewardAtAmount) = calulateTrigger(swapRewardAway,swapRewardUsePercent,swapRewardUseTimer,swapRewardNext,swapRewardAtAmount,swapRewardRatio,feeDividends);
        swapLpAtAmount = _swapLpAtAmount;
        swapMarketAtAmount = _swapMarketAtAmount;
        swapRewardAtAmount = _swapRewardAtAmount;
        swapRewardActualTranaction++;
        if(canSwap && !swapping && !automatedMarketMakerPairs[from_] ){
            swapping = true;
            if(enSwapAndLiquify && _enSwapLp){
                uint256 _tAmount = balanceOf(address(this));
                if(_tAmount >= feeLP){
                    swapAndLiquify(swapLpAtAmount);
                    feeLP = feeLP.sub(swapLpAtAmount);
                }            
                else{
                    swapAndLiquify(_tAmount);
                    feeLP = 0;
                }
                swapLpNext =  block.timestamp + swapLpOfset;
            }   

            if(enSwapTokensForEth && _enSwapMarket ){
                uint256 _bAmount = address(this).balance;
                uint256 _tAmount = balanceOf(address(this));
                if(_tAmount >= feeMarketing){
                    swapTokensForEth(swapMarketAtAmount);
                    feeMarketing = feeMarketing.sub(swapMarketAtAmount);
                }                
                else{
                    swapTokensForEth(_tAmount);
                    feeMarketing = 0;
                }
                swapMarketNext =  block.timestamp + swapMarketOfset;
                uint256 _feemarketing = address(this).balance.sub(_bAmount);
                _totalmarketingFee = _totalmarketingFee.add(_feemarketing);
                payable(marketingWallet).transfer(_feemarketing);

            }

            if(enSwapAndSendDividends && _enSwapReward && (swapRewardActualTranaction > swapRewardTargetTranaction) ){
                uint256 _tAmount = balanceOf(address(this));
                if(_tAmount >= feeDividends){
                    swapAndSendDividends(swapRewardAtAmount);
                    feeDividends = feeDividends.sub(swapRewardAtAmount);
                }
                else{  
                    swapAndSendDividends(_tAmount);
                    feeDividends = 0;
                }
                swapRewardNext =  block.timestamp + swapRewardOfset;
                swapRewardActualTranaction =0;
            }
            
            swapping = false;
        }

         bool takeFee = !swapping  && tradingIsEnabled ; 

        if(_isExcludedFromFees[from_] || _isExcludedFromFees[to_]) {
            takeFee = false;
        }

        if(takeFee && enTakeFee) {
            uint256 fees = calulateFee(amount_,from_ ,to_);
            if(fees> 0){
                amount_ = amount_.sub(fees);
                super._transfer(from_, address(this), fees);
            }

        }
        
        if(enWalletLimit && !_isExcludedFromFees[from_] && (to_ != liquidityWallet) && (to_ != address(this)) && !automatedMarketMakerPairs[to_] && (to_ != address(uniswapV2Router)) ){
            uint256 _uAmount = balanceOf(to_);
             _uAmount = _uAmount.add(amount_);
             require(maxWalletAmount >=  _uAmount,"Over maximum amount in wallet");
        }

        super._transfer(from_, to_, amount_);



        try dividendTracker.setBalance(payable(from_), balanceOf(from_)) {} catch {}
        try dividendTracker.setBalance(payable(to_), balanceOf(to_)) {} catch {}



        if(!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
        }
    }


    
    function addLiquidity(uint256 ethAmount) private {
        uint256 _tokenAmount = balanceOf(address(this));
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
       uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            _tokenAmount,
            0, 
            ethAmount,
            liquidityWallet,
            block.timestamp  +180
        );
        
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp +180
        );
        
    }
    
    function swapAndLiquify(uint256 tokens) private {

        uint256 half = tokens.div(2);
        swapTokensForEth(half); 
        uint256 _balance = address(this).balance;
        addLiquidity(_balance);

    }

    function swapTokensForEarnToken(uint256 tokenAmount, address recipient) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = earnToken;


        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            recipient,
            block.timestamp  +180
        );
        
    }
    
    function swapAndSendDividends(uint256 tokens) private {

        swapTokensForEarnToken(tokens, address(this));
        uint256 dividends = IERC20(earnToken).balanceOf(address(this));
        bool success = IERC20(earnToken).transfer(address(dividendTracker), dividends);
        if (success) {
            dividendTracker.distributeTokenDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }


    function manualSwapForAddLP(uint256 amount) public onlyOwner{
        swapping = true;
        swapTokensForEth(amount);
        swapping = false;
    }
   
    function manualAddLP(uint256 ethAmount) public onlyOwner{
        swapping = true;
        addLiquidity(ethAmount);
        swapping = false;
    }
   
    function manualSwapAndSendDividends(uint256 amount) public onlyOwner{
        swapping = true;
        swapAndSendDividends(amount);
        swapping = false;
    }
   
    function manualBuyBack(uint256 amount) public onlyOwner{
        swapping = true;
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, 
            path,
            address(this),
            block.timestamp +180
        );
        swapping = false;
    }

    
   receive() external payable {

  	}

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify( uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity );
    event SendDividends( uint256 tokensSwapped,uint256 amount );
    event ProcessedDividendTracker(	uint256 iterations,	uint256 claims,uint256 lastProcessedIndex,bool indexed automatic,uint256 gas,address indexed processor );
    
  
    function updateDividendLastIndex(uint256 lastIndex_) external onlyOwner{
        dividendTracker.updateLastIndex(lastIndex_);
    }
    function updateDividandProcessAccount(address payable account_) external onlyOwner{
        dividendTracker.processAccount(account_,true);
    }
    function updateDividandEarnToken(address earnToken_) external onlyOwner {
        earnToken = earnToken_;
        dividendTracker.updateEarnToken(earnToken_);
    }
    function updateDividandAdmin(address account_ ,bool status_) external onlyOwner{
        dividendTracker.updateAdminUser(account_,status_);
    }
    function updateDividandMinimunTokenForDividant(uint256 minimunToken_) external onlyOwner{
        dividendTracker.updateMinimumTokenBalanceForDividends(minimunToken_);
    }
    
    function getDividendMagnifiedDividendPerShare() external view returns(uint256) {
        return dividendTracker.getMagnifiedDividendPerShar();
    }
    function getDividendTokenBalanceOf(address account) external view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}
	
	function getDividendsTokenBalance(address tokenAddress)public view returns(uint256){
        return  IERC20(tokenAddress).balanceOf(address(dividendTracker));
    }

    function getAccountDividendsInfo(address account)
        external view returns (address,int256,int256,uint256,uint256,uint256) {
        return dividendTracker.getDividantAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (address,int256,int256,uint256,uint256,uint256) {
    	return dividendTracker.getDividantAccountAtIndex(index);
    }

    function getDividendLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getDividendNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    
    
}

contract EarnDividendTracker is ERC20, Ownable {    
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    
    //address public  earnToken = address(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47); 
    address public  earnToken = address(0x8BaBbB98678facC7342735486C851ABD7A0d17Ca);  // TestNet ETH
    uint256 private lastProcessedIndex;
    uint256 private totalDividendsDistributed;
    uint256 private minimumTokenBalanceForDividends;
    uint256 private magnifiedDividendPerShare;
    uint256 constant internal magnitude = 2**128; 
    
    mapping (address => bool) private excludedFromDividends;
    mapping (address => uint256) private lastClaimTimes;
    mapping(address => uint256) internal withdrawnDividends;

    constructor(address earnToken_ , address owner_)  ERC20("Earn_Dividend_Tracker", "Earn_Dividend_Tracker") {
        earnToken = earnToken_;
        updateAdminUser(owner_,true);
        minimumTokenBalanceForDividends = 1000000 * (10**18); 
    }
    
    function distributeTokenDividends(uint256 amount) public onlyAdmin {
        require(totalSupply() > 0);

        if (amount > 0) {
            uint256 _balance = IERC20(earnToken).balanceOf(address(this));
            magnifiedDividendPerShare = _balance.mul(magnitude) / totalSupply();
            totalDividendsDistributed = totalDividendsDistributed.add(amount);
        }
    }
    
    function setBalance(address payable account, uint256 newBalance) public onlyAdmin {
    	if(excludedFromDividends[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}

    }
    
    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if(newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        }
        else if(newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
    
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);
    }   
    
    
    function process(uint256 gas) public onlyAdmin returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;
    	bool _processAccount=true;



    	while(gasUsed < gas && iterations < numberOfTokenHolders && _processAccount && IERC20(earnToken).balanceOf(address(this))>0 ) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}
            
    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(processAccount(payable(account), true)) {
    			claims++;

    		}
    		else{
    		    _processAccount = false;
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyAdmin returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
    
     function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = dividendOf(user);
        uint256 _balance = IERC20(earnToken).balanceOf(address(this));
        uint256 _amount =0;
    
        if(_balance==0 || _withdrawableDividend == 0 ){
             return 0;
        }
    
        if(_balance >= _withdrawableDividend ){
            _amount = _withdrawableDividend;
        }
        else{
            _amount = _balance;
        }
    
        bool _success = IERC20(earnToken).transfer(user, _amount);
        if(_success){
             withdrawnDividends[user] = withdrawnDividends[user].add(_amount);
        }
        return _amount;
    }
    
    function  _transfer(address, address, uint256) internal pure override {
        require(false, "Dividend_Tracker: No transfers allowed");
    }
    

    function excludeFromDividends(address account) external onlyAdmin {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateMinimumTokenBalanceForDividends(uint256 minimumTokenBalanceForDividends_) external onlyAdmin{
        minimumTokenBalanceForDividends = minimumTokenBalanceForDividends_ * (10**18);

    }
    
    function updateEarnToken(address earnToken_) external onlyAdmin {
        earnToken = earnToken_;
   }
   function updateLastIndex(uint256 lastProcessedIndex_) external onlyAdmin {
        lastProcessedIndex = lastProcessedIndex_;
   }


    function getDividantAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableDividends = dividendOf(account);
        totalDividends = withdrawnDividends[account];
        lastClaimTime = lastClaimTimes[account];
                               
    }

    function getDividantAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0);
        }
        address account = tokenHoldersMap.getKeyAtIndex(index);
        return getDividantAccount(account);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function dividendOf(address _owner) public view  returns(uint256) {
        return  magnifiedDividendPerShare.mul(balanceOf(_owner)).div(magnitude);
    }

    function withdrawnDividendOf(address _owner) public view  returns(uint256) {
        return withdrawnDividends[_owner];
    }
    
    function getMagnifiedDividendPerShar() public view returns(uint256) {
        return magnifiedDividendPerShare;
    }
    
    function getTotalDividendsDistributed() external view returns (uint256) {
        return totalDividendsDistributed;
    }

    receive() external payable {

  	}
  	
    event ExcludeFromDividends(address indexed account);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

  

}