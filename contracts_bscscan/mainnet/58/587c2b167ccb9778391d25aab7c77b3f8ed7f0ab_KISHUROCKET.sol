/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

/*
KISHUROCKET

Total Supply         : 100,000,000,000

Taxes:

Buy Tax 10%
    🌀 5% Marketing
    💰 4% Team Wallet
    🥯 1% Auto Liquidity

Sell Tax 14%
    🌀 9% Marketing
    💰 4% Team Wallet
    🥯 1% Auto Liquidity
    
Tokenomics
    💵 1% Max Buy Tx ( 1,000,000,000 KISHURKT )
    💵 1% Max Sell Tx ( 1,000,000,000 KISHURKT )
    💰 1% Max Bag ( 1,000,000,000 KISHURKT )

Degenerate Mode
When degenerate mode is activated: 
    📖 Buy tax to 5% 
    📖 Sell tax to 30% 

Anti-Sniper Protocols
    🌀 Manual Blacklist Function
    😡 Max TX amount 
 *
 */

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Allows for contract ownership for multiple adressess
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address account) public onlyOwner {
        authorizations[account] = true;
    }

    /**
     * Remove address authorization. Owner only
     */
    function unauthorize(address account) public onlyOwner {
        authorizations[account] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address authorization status
     */
    function isAuthorized(address account) public view returns (bool) {
        return authorizations[account];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable account) public onlyOwner {
        owner = account;
        authorizations[account] = true;
        emit OwnershipTransferred(account);
    }

    event OwnershipTransferred(address owner);
}

/* Standard IDEXFactory */
interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

/* Standard IDEXRouter */
interface IDEXRouter {
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

/* Token contract */
contract KISHUROCKET is IBEP20, Auth {
    using SafeMath for uint256;
    
    // Addresses
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    
    // These are owner by default
    address public _autoLiquidityReceiver;
    address public _marketingFeeReceiver;
    address public _buyBackFeeReceiver;
    
    // Name and symbol
    string constant _name = "KISHUROCKET";
    string constant _symbol = "KISHURKT";
    uint8 constant _decimals = 18;
    
    // Total supply
    uint256 _totalSupply = 100_000_000_000 * (10 ** _decimals); // 100Md
    
    // Max wallet and TX
    uint256 public _maxBuyTxAmount = _totalSupply * 100 / 10000; // 1% on launch or 1Md tokens
    uint256 public _maxSellTxAmount = _totalSupply * 100 / 10000; // 1% or 1Md tokens
    uint256 public _maxWalletToken = _totalSupply * 100 / 10000; // 1% or 1Md tokens
    
    // Mappings
    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) _isFeeExempt;
    mapping (address => bool) _isTxLimitExempt;
    mapping (address => bool) _isBlacklisted;
    
    // Buy Fees
    uint256 _liquidityFeeBuy = 100;
    uint256 _buybackFeeBuy = 400;
    uint256 _marketingFeeBuy = 500;
    uint256 _totalFeeBuy = 1000;
    
    uint256 _degenerateLiquidityFeeBuy = 100;
    uint256 _degenerateBuybackFeeBuy = 0;
    uint256 _degenerateMarketingFeeBuy = 400;
    uint256 _degenerateTotalFeeBuy = 500;
    
    // Sell fees
    uint256 _liquidityFeeSell = 100;
    uint256 _buybackFeeSell = 400;
    uint256 _marketingFeeSell = 900;
    uint256 _totalFeeSell = 1500;
    
    uint256 _degenerateLiquidityFeeSell = 300;
    uint256 _degenerateBuybackFeeSell = 1500;
    uint256 _degenerateMarketingFeeSell = 1200;
    uint256 _degenerateTotalFeeSell = 3000;
    
    // Fee variables
    uint256 _liquidityFee;
    uint256 _buybackFee;
    uint256 _marketingFee;
    uint256 _totalFee;
    uint256 _feeDenominator = 10000;
    
    // Degenerate mode
    uint256 _degenerateModeTriggeredAt;
    uint256 _degenerateDuration = 900;
    uint256 _degenerateFeeBuy = 500;
    uint256 _degenerateFeeSell = 3000;
    
    // Sell amount of tokens when a sell takes place
    uint256 public _swapThreshold = _totalSupply * 10 / 10000; // 0.1% of supply
    
    // Other variables
    IDEXRouter public _router;
    address public _pair;
    uint256 public _launchedAt;
    bool public _tradingOpen = false;
    bool public _swapEnabled = true;
    bool _inSwap;
    modifier swapping()
    {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountToken);
    
    /* Token constructor */
    constructor () Auth(msg.sender) {
        _router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _pair = IDEXFactory(_router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(_router)] = type(uint256).max;
        
        // Should be the owner wallet/token distributor
        address presaler = msg.sender;
        _isFeeExempt[presaler] = true;
        _isTxLimitExempt[presaler] = true;
        
        // Set the marketing and liquidity receiver to the owner as default
        _autoLiquidityReceiver = msg.sender;
        _marketingFeeReceiver = msg.sender;
        _buyBackFeeReceiver = msg.sender;
        
        _balances[presaler] = _totalSupply;
        emit Transfer(address(0), presaler, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    // setting the max wallet in percentages
    // NOTE: 1% = 100
     function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletToken = _totalSupply.mul(maxWallPercent).div(10000);
    }

    // Main transfer function
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if ((sender == _pair && recipient == address(_router)) || _inSwap) {
            return basicTransfer(sender, recipient, amount);
        }
        
        // Check if trading is enabled
        if (!authorizations[sender] && !authorizations[recipient]) {
            require(_tradingOpen,"Trading not enabled yet");
        }
        
        // Check if address is blacklisted
        require(!_isBlacklisted[recipient] && !_isBlacklisted[sender], 'Address is blacklisted');
        
        // Check if buying or selling
        bool isSell = recipient == _pair; 
        
        // Check if we are in Degenerate mode
        bool degenerateMode = inDegenerateMode();
        
        // Set buy or sell fees
        setCorrectFees(isSell, degenerateMode);
        
        // Check max wallet
        checkMaxWallet(sender, recipient, amount);
        
        // Checks maxTx
        checkTxLimit(sender, amount, recipient, isSell);
        
        // Check if we should do the swapback
        if (shouldSwapBack()) {
            swapBack(_swapThreshold);
        }
        
        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        
        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    // Do a normal transfer
    function basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    // Set the correct fees for buying or selling
    function setCorrectFees(bool isSell, bool degenerateMode) internal {
        if (isSell) {
            if (degenerateMode) {
                _liquidityFee = _degenerateLiquidityFeeSell;
                _buybackFee = _degenerateBuybackFeeSell;
                _marketingFee = _degenerateMarketingFeeSell;
                _totalFee = _degenerateTotalFeeSell;
            }
            else {
                _liquidityFee = _liquidityFeeSell;
                _buybackFee = _buybackFeeSell;
                _marketingFee = _marketingFeeSell;
                _totalFee = _totalFeeSell;
            }
        }
        else {
            if (degenerateMode) {
                _liquidityFee = _degenerateLiquidityFeeBuy;
                _buybackFee = _degenerateBuybackFeeBuy;
                _marketingFee = _degenerateMarketingFeeBuy;
                _totalFee = _degenerateTotalFeeBuy;
            }
            else {
                _liquidityFee = _liquidityFeeBuy;
                _buybackFee = _buybackFeeBuy;
                _marketingFee = _marketingFeeBuy;
                _totalFee = _totalFeeBuy;
            }
        }
    }
    
    // Check if we are in Degenerate mode
    function inDegenerateMode() public view returns (bool){
        if (_degenerateModeTriggeredAt.add(_degenerateDuration) > block.timestamp) {
            return true;
        }
        else {
            return false;
        }
    }
    
    // Check for maxTX
    function checkTxLimit(address sender, uint256 amount, address recipient, bool isSell) internal view {
        if (recipient != owner) {
            if (isSell) {
                require(amount <= _maxSellTxAmount || _isTxLimitExempt[sender] || _isTxLimitExempt[recipient], "TX Limit Exceeded");
            }
            else {
                require(amount <= _maxBuyTxAmount || _isTxLimitExempt[sender] || _isTxLimitExempt[recipient], "TX Limit Exceeded");
            }
        }
    }
    
    // Check maxWallet
    function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if (!authorizations[sender] &&
            recipient != owner &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != _pair &&
            recipient != _marketingFeeReceiver &&
            recipient != _buyBackFeeReceiver &&
            recipient != _autoLiquidityReceiver) {
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
        }
    }
    
    // Check if sender is not feeExempt
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !_isFeeExempt[sender];
    }
    
    // Take the normal total Fee
    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount;
        
        feeAmount = amount.mul(_totalFee).div(_feeDenominator);
        
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        
        return amount.sub(feeAmount);
    }
    
    // Check if we should sell tokens
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != _pair && !_inSwap && _swapEnabled && _balances[address(this)] >= _swapThreshold;
    }
    
    // switch Trading
    function allowTrading(bool status) public onlyOwner {
        _tradingOpen = status;
        launch();
    }
    
    // Enable Degenerate mode
    function enableDegenerateMode(uint256 durationInSeconds) public authorized {
        _degenerateModeTriggeredAt = block.timestamp;
        _degenerateDuration = durationInSeconds;
    }
    
    // Disable the Degenerate mode
    function disableDegenerateMode() external authorized {
        _degenerateModeTriggeredAt = 0;
    }
    
    // Blacklist/unblacklist an address
    function blacklistAddress(address wallet, bool value) public authorized{
        _isBlacklisted[wallet] = value;
    }
    
    // Main swapBack to sell tokens for WBNB
    function swapBack(uint256 amount) internal swapping {
        require(amount > 0, "nothing to swap back");
        
        uint256 amountToLiquify = amount.mul(_liquidityFee).div(_totalFee).div(2);
        uint256 amountToSwap = amount.sub(amountToLiquify);
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        
        uint256 balanceBefore = address(this).balance;
        
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        
        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        uint256 totalBNBFee = _totalFee.sub(_liquidityFee.div(2));
        uint256 amountBNBLiquidity = amountBNB.mul(_liquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBMarketing = amountBNB.mul(_marketingFee).div(totalBNBFee);
        uint256 amountBNBBuyBack = amountBNB.mul(_buybackFee).div(totalBNBFee);
        
        (bool successMarketing, /* bytes memory data */) = payable(_marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        require(successMarketing, "marketing receiver rejected ETH transfer");
        
        (bool successBuyBack, /* bytes memory data */) = payable(_buyBackFeeReceiver).call{value: amountBNBBuyBack, gas: 30000}("");
        require(successBuyBack, "buy back receiver rejected ETH transfer");
        
        if (amountToLiquify > 0) {
            _router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                _autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }
    
    // Trigger a manual swapBack
    function triggerManualSwapback() external authorized {
        swapBack(_balances[address(this)]);
    }
    
    // Buy amount of tokens with bnb from the contract
    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        _router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }
    
    // Check when the token is launched
    function launched() internal view returns (bool) {
        return _launchedAt != 0;
    }

    // Set the launchedAt to token launch
    function launch() internal {
        _launchedAt = block.number;
    }

    // Set max buy TX 
    function setBuyTxLimitInPercent(uint256 maxBuyTxPercent) external authorized {
        _maxBuyTxAmount = _totalSupply.mul(maxBuyTxPercent).div(10000);
    }

    // Set max sell TX 
    function setSellTxLimitInPercent(uint256 maxSellTxPercent) external authorized {
        _maxSellTxAmount = _totalSupply.mul(maxSellTxPercent).div(10000);
    }
    
    // Exempt from fee
    function setIsFeeExempt(address holder, bool exempt) external authorized {
        _isFeeExempt[holder] = exempt;
    }

    // Exempt from max TX
    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        _isTxLimitExempt[holder] = exempt;
    }
    
    // Set our buy fees
    function setBuyFees(uint256 liquidityFeeBuy, uint256 buybackFeeBuy, uint256 marketingFeeBuy, uint256 feeDenominator) external authorized {
        _liquidityFeeBuy = liquidityFeeBuy;
        _buybackFeeBuy = buybackFeeBuy;
        _marketingFeeBuy = marketingFeeBuy;
        _totalFeeBuy = liquidityFeeBuy.add(buybackFeeBuy).add(marketingFeeBuy);
        _feeDenominator = feeDenominator;
    }
    
    // Set our sell fees
    function setSellFees(uint256 liquidityFeeSell, uint256 buybackFeeSell, uint256 marketingFeeSell, uint256 feeDenominator) external authorized {
        _liquidityFeeSell = liquidityFeeSell;
        _buybackFeeSell = buybackFeeSell;
        _marketingFeeSell = marketingFeeSell;
        _totalFeeSell = liquidityFeeSell.add(buybackFeeSell).add(marketingFeeSell);
        _feeDenominator = feeDenominator;
    }
    
    // Set our Degenerate buy fees
    function setDegenerateBuyFees(uint256 degenerateLiquidityFeeBuy, uint256 degenerateBuybackFeeBuy, uint256 degenerateMarketingFeeBuy) external authorized {
        _degenerateLiquidityFeeBuy = degenerateLiquidityFeeBuy;
        _degenerateBuybackFeeBuy = degenerateBuybackFeeBuy;
        _degenerateMarketingFeeBuy = degenerateMarketingFeeBuy;
        _degenerateTotalFeeBuy = degenerateLiquidityFeeBuy.add(degenerateBuybackFeeBuy).add(degenerateMarketingFeeBuy);
    }
    
    // Set our Degenerate sell fees
    function setDegenerateSellFees(uint256 degenerateLiquidityFeeSell, uint256 degenerateBuybackFeeSell, uint256 degenerateMarketingFeeSell) external authorized {
        _degenerateLiquidityFeeSell = degenerateLiquidityFeeSell;
        _degenerateBuybackFeeSell = degenerateBuybackFeeSell;
        _degenerateMarketingFeeSell = degenerateMarketingFeeSell;
        _degenerateTotalFeeBuy = degenerateLiquidityFeeSell.add(degenerateBuybackFeeSell).add(degenerateMarketingFeeSell);
    }
    
    // Set Degenerate mode fees
    function setDegenerateModeFees(uint256 degenerateFeeBuy, uint256 degenerateFeeSell) external authorized {
        _degenerateFeeBuy = degenerateFeeBuy;
        _degenerateFeeSell = degenerateFeeSell;
    }
    
    // Set the marketing and liquidity receivers
    function setFeeReceivers(address autoLiquidityReceiver, address marketingFeeReceiver, address buyBackFeeReceiver) external authorized {
        _autoLiquidityReceiver = autoLiquidityReceiver;
        _marketingFeeReceiver = marketingFeeReceiver;
        _buyBackFeeReceiver = buyBackFeeReceiver;
    }

    // Set swapBack settings
    function setSwapBackSettings(bool enabled, uint256 amount) external authorized {
        _swapEnabled = enabled;
        _swapThreshold = _totalSupply * amount / 10000; 
    }
    
    // Get the circulatingSupply
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
}