/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}


contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

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

contract Ownable is Context {
    address private _owner;

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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

contract REGUDEFI is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    mapping (address => bool) public isSniper;
    bool private _swapping;
    uint256 private _launchTime;

    address public feeWallet;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    
    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;
        
    bool public limitsInEffect = true;
    bool public dynamicFeesInEffect = false;
    bool public tradingActive = false;

    uint256 public fireSaleActive;
    uint256 public fireSaleTimer;
    uint256 public fireSaleAmt;
    uint256 public fireSaleRequirement;

    uint256 public resetRequirement;
    mapping (address => uint256) public userBurned;

    uint256 public buyFeeThreshold;
    uint256 public buyFeeRate;
    uint256 public buyTotalFees;
    uint256 private _buyMarketingFee;
    uint256 private _buyLiquidityFee;
    uint256 private _buyDevFee;
    
    uint256 public sellFeeThreshold;
    uint256 public sellFeeRate;
    uint256 public sellTotalFees;
    uint256 private _sellMarketingFee;
    uint256 private _sellLiquidityFee;
    uint256 private _sellDevFee;
    
    uint256 private _tokensForMarketing;
    uint256 private _tokensForLiquidity;
    uint256 private _tokensForDev;
    
    /******************/

    // exlcude from fees and max transaction amount
    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) public isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event Burn(uint256 burnAmount);
    event FeesReset();
    event FireSaleBy(address user);
    event FireSale();

    constructor() ERC20("Regulated DeFi", "REGU") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        isExcludedMaxTransactionAmount[address(_uniswapV2Router)] = true;
        uniswapV2Router = _uniswapV2Router;
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        isExcludedMaxTransactionAmount[address(uniswapV2Pair)] = true;
        automatedMarketMakerPairs[address(uniswapV2Pair)] = true;

        uint256 totalSupply = 1e9 * 1e9;
        
        _buyMarketingFee = 6;
        _buyLiquidityFee = 2;
        _buyDevFee = 2;
        buyTotalFees = _buyMarketingFee + _buyLiquidityFee + _buyDevFee;
        
        _sellMarketingFee = 6;
        _sellLiquidityFee = 2;
        _sellDevFee = 2;
        sellTotalFees = _sellMarketingFee + _sellLiquidityFee + _sellDevFee;

        buyFeeRate = totalSupply * 5 / 1000;  // 0.5%
        sellFeeRate = totalSupply * 25 / 10000;  // 0.25%

        resetRequirement = totalSupply * 1 / 10000;  // 0.01%
        fireSaleRequirement = totalSupply * 1 / 100;  // 1%

        maxTransactionAmount = totalSupply * 1 / 100; // 1%
        maxWallet = totalSupply * 2 / 100; // 2%
        swapTokensAtAmount = totalSupply * 2 / 1000; // 0.2%
        
        feeWallet = address(owner());

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(burnAddress), true);
        
        isExcludedMaxTransactionAmount[owner()] = true;
        isExcludedMaxTransactionAmount[address(this)] = true;
        isExcludedMaxTransactionAmount[address(burnAddress)] = true;
        
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        _launchTime = block.timestamp + 1; //Let's make sure the snipers don't just set 1 block ahead
    }
    
    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        dynamicFeesInEffect = true;
        fireSaleTimer = block.timestamp + 1 days;
        return true;
    }
    
     // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool) {
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
  	    swapTokensAtAmount = newAmount;
  	    return true;
  	}
    
    function excludeFromFees(address account, bool excluded) public onlyOwner() {
        isExcludedFromFees[account] = excluded;
    }
    
    function updateFeeWallet(address newWallet) external onlyOwner {
        feeWallet = newWallet;
    }
    
    function setSnipers(address[] memory snipers_) external onlyOwner() {
        for (uint i = 0; i < snipers_.length; i++) {
            if (snipers_[i] != uniswapV2Pair && snipers_[i] != address(uniswapV2Router)) {
                isSniper[snipers_[i]] = true;
            }
        }
    }
    
    function delSnipers(address[] memory snipers_) external onlyOwner() {
        for (uint i = 0; i < snipers_.length; i++) {
            isSniper[snipers_[i]] = false;
        }
    }
    
    function setResetRequirement(uint256 requirement) external onlyOwner() {
        require(requirement >= totalSupply() * 1 / 100000, "Burn requirement cannot be lower than 0.001% total supply.");
  	    require(requirement <= totalSupply() * 5 / 1000, "Burn requirement cannot be higher than 0.5% total supply.");
  	    resetRequirement = requirement;
    }

    function setfireSaleRequirement(uint256 requirement) external onlyOwner() {
        require(requirement >= totalSupply() * 1 / 100000, "Burn requirement cannot be lower than 0.001% total supply.");
  	    require(requirement <= totalSupply() * 5 / 1000, "Burn requirement cannot be higher than 0.5% total supply.");
  	    fireSaleRequirement = requirement;
    }

    function _resetFees() private {
        _buyMarketingFee = 6;
        _buyLiquidityFee = 2;
        _buyDevFee = 2;
        buyTotalFees = _buyMarketingFee + _buyLiquidityFee + _buyDevFee;
        
        _sellMarketingFee = 6;
        _sellLiquidityFee = 2;
        _sellDevFee = 2;
        sellTotalFees = _sellMarketingFee + _sellLiquidityFee + _sellDevFee;
    }

    function resetFees() external {
        require(balanceOf(msg.sender) > resetRequirement, "You do not have enough tokens to reset fees!");

        _resetFees();

        fireSaleAmt += resetRequirement;

        transfer(burnAddress, resetRequirement);
        emit FeesReset();
    }

    function fireSale() public {
        require(balanceOf(msg.sender) > fireSaleRequirement, "You do not have enough tokens to start a fire sale!");
        fireSaleActive = block.timestamp + 2 hours;
        fireSaleTimer = block.timestamp + 1 days;
        fireSaleAmt = 0;

        transfer(burnAddress, fireSaleRequirement);
        emit FireSaleBy(msg.sender);
    }

    function _startFireSale() private {
        fireSaleActive = block.timestamp + 2 hours;
        fireSaleTimer = block.timestamp + 1 days;
        fireSaleAmt = 0;
        
        emit FireSale();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!isSniper[from], "Your address has been marked as a sniper, you are unable to transfer or swap.");
        
         if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        if (block.timestamp <= _launchTime) isSniper[to] = true;
        
        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(burnAddress) &&
                !_swapping
            ) {
                if (!tradingActive) require(isExcludedFromFees[from] || isExcludedFromFees[to], "Trading is not active.");
                 
                // when buy
                if (automatedMarketMakerPairs[from] && !isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
                
                // when sell
                else if (automatedMarketMakerPairs[to] && !isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                }
            }
        }
        
		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if (
            canSwap &&
            !_swapping &&
            !automatedMarketMakerPairs[from] &&
            !isExcludedFromFees[from] &&
            !isExcludedFromFees[to]
        ) {
            _swapping = true;
            swapBack();
            _swapping = false;
        }

        
        // dynamic change
        if (dynamicFeesInEffect && block.timestamp > fireSaleActive) {
            // on sell
            if (automatedMarketMakerPairs[to]) {
                sellFeeThreshold += amount;
                
                uint256 feeAdd = sellFeeThreshold.div(sellFeeRate);
                if (feeAdd > 0) {
                    if (_sellLiquidityFee < 12) {
                        if (feeAdd > 10) {
                            _sellLiquidityFee += 10;
                        } else {
                            _sellLiquidityFee += feeAdd;
                        }
                    }

                    sellFeeThreshold -= feeAdd.mul(sellFeeRate);
                }
            } 
            // on buy
            else if (automatedMarketMakerPairs[from]) {
                buyFeeThreshold += amount;
                
                uint256 feeAdd = buyFeeThreshold.div(buyFeeRate);
                if (feeAdd > 0) {
                    if (_buyLiquidityFee > 0) {
                        if (feeAdd > 2) {
                            _buyLiquidityFee -= 2;
                        } else {
                            _buyLiquidityFee -= feeAdd;
                        }
                    }

                    buyFeeThreshold -= feeAdd.mul(buyFeeRate);
                }
            }
        }

        // set new totals
        buyTotalFees = _buyMarketingFee + _buyLiquidityFee + _buyDevFee;
        sellTotalFees = _sellMarketingFee + _sellLiquidityFee + _sellDevFee;

        bool takeFee = !_swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (isExcludedFromFees[from] || isExcludedFromFees[to]) takeFee = false;
        
        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                _tokensForLiquidity += fees * _sellLiquidityFee / sellTotalFees;
                _tokensForDev += fees * _sellDevFee / sellTotalFees;
                _tokensForMarketing += fees * _sellMarketingFee / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
        	    fees = amount.mul(buyTotalFees).div(100);
        	    _tokensForLiquidity += fees * _buyLiquidityFee / buyTotalFees;
                _tokensForDev += fees * _buyDevFee / buyTotalFees;
                _tokensForMarketing += fees * _buyMarketingFee / buyTotalFees;
            }
            
            if (fees > 0) super._transfer(from, address(this), fees);
        	
        	amount -= fees;
        }

        if (block.timestamp > fireSaleActive && fireSaleActive > 0) {
            fireSaleActive = 0;
            _resetFees();
        }

        // reset firesale if time passed
        if (block.timestamp > fireSaleTimer) {
            fireSaleTimer = block.timestamp + 1 days;
            fireSaleAmt = 0;
        }

        // if it's a burn
        if (to == burnAddress) {
            userBurned[msg.sender] += amount;
            fireSaleAmt += amount;

            if (fireSaleAmt >= fireSaleRequirement) _startFireSale();
            
            emit Burn(amount);
        }

        super._transfer(from, to, amount);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
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
    
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
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

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _tokensForLiquidity + _tokensForMarketing + _tokensForDev;
        
        if (contractBalance == 0 || totalTokensToSwap == 0) return;
        if (contractBalance > swapTokensAtAmount * 20) contractBalance = swapTokensAtAmount * 20;
        
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * _tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        
        uint256 initialETHBalance = address(this).balance;

        _swapTokensForEth(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(_tokensForMarketing).div(totalTokensToSwap);
        uint256 ethForDev = ethBalance.mul(_tokensForDev).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDev;
        
        _tokensForLiquidity = 0;
        _tokensForMarketing = 0;
        _tokensForDev = 0;
                
        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, _tokensForLiquidity);
        }
    }

    function withdrawFees() external {
        payable(feeWallet).transfer(address(this).balance);
    }

    receive() external payable {}
}