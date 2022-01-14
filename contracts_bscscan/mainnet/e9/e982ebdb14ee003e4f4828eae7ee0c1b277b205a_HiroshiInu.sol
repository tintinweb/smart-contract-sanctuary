/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

/**
 * WELCOME TO HIROSHI INU ! OUR TELEGRAM: https://t.me/HiroshiInuBSC
 */

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

/**
 * BEP20 standard interface
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
 * Basic access control mechanism
 */

abstract contract Ownable {
    address internal owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function OwnershipLock(uint256 time) public virtual onlyOwner {
        _previousOwner = owner;
        owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(owner, address(0));
    }

    function OwnershipUnlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(owner, _previousOwner);
        owner = _previousOwner;
    }
}

/**
 * Router Interfaces
 */

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

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

/**
 * Contract Code
 */

contract HiroshiInu is IBEP20, Ownable {
        
// Events
    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
    event SetSwapBackSettings(bool enabled, uint256 swapThreshold, uint256 maxSwapSize);
    event SetFeeReceivers(address marketing, address team, address liquidity);
    event StuckBalanceSent(uint256 amountBNB, address recipient);
    event ForeignTokenTransfer(address tokenAddress, uint256 quantity);
    event ExcludeFromFee(address Address, bool Excluded);
    event ExcludeFromLimits(address Address, bool Excluded);
    event PresaleAddress(address Address);
    event GasLimitSet(uint256 gas);
    event SetProtectionSettings(bool limits, bool antiGas, bool sameBlock, bool sniperProtection);
    event SetBuyFee(uint256 liquidityFee, uint256 marketingFee, uint256 teamFee);
    event SetSellFee(uint256 liquidityFee, uint256 marketingFee, uint256 teamFee);
    event SetMaxWallet(uint256 percentageBase1000);
    event SetMaxTX(uint256 percentageBase1000);
    event SniperCaught(address sniperAddress);
    event RemovedSniper(address notsniper);

// Mappings
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromLimits;
    mapping(address => bool) public isSniper;
    mapping(address => uint256) private lastTrade;
    
// Basic Contract Info
    string constant _name = "HiroshiInu";
    string constant _symbol = "HINU";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 100000000 * (10 ** _decimals); // 100,000,000, Tokens

    IDEXRouter public router;
    address public pair;

// Transaction Limits
    uint256 private _maxTxAmount = _totalSupply / 1000 * 15; // 1,5%
    uint256 private _maxWalletSize = _totalSupply / 100 * 3; // 3%

// Detailed Fees
    struct BuyFee {
        uint16 liquidityFee;
        uint16 marketingFee;
        uint16 teamFee;
        uint16 totalFee;
    }

    struct SellFee {
        uint16 liquidityFee;
        uint16 marketingFee;
        uint16 teamFee;
        uint16 totalFee;
    }

    BuyFee public buyFee;
    SellFee public sellFee;

    uint16 private _marketingFee;
    uint16 private _liquidityFee;
    uint16 private _teamFee;
    uint16 private _totalFee;

// Fee Receivers
    address private marketingAddress = 0x977cA7ba12b50aa5d456A15C014aa5678B0c6c3a; // Marketing Address
    address private teamAddress = 0x977cA7ba12b50aa5d456A15C014aa5678B0c6c3a;      // Team Address
    address private liquidityAddress = 0x6aEB32B2cbE4a2E988316a3767B8837ed427041a; // Liquidity Address

// AntiBot Functions
    bool public limitsInEffect;    // Control every AntiBot function
    bool public sniperProtection; // If this function is active the snipers will be blacklisted
    bool public sameBlockActive; // Only one transaction per user per block is allowed
    bool public gasLimitActive; // Any transaction above the specified gas will be reverted

    uint256 public tradingActiveBlock; // Launch block
    uint256 public snipeBlocks = 2; // Number of blocks for the antisnipe function, any buy transaction in these blocks will be automatically blacklisted
        
    uint256 public gasPriceLimit = 150 * 1 gwei; // Max gas allowed to buy or sell

    uint256 public launchedAt; //Launch timestamp

    uint256 public snipersPenaltyEnd;

// SwapBack
    bool inSwap;
    bool swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000 * 1; // 0.1%
    uint256 public maxSwapSize = _totalSupply / 100 * 1; //1%
    uint256 public tokensToSell;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor () Ownable(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        buyFee.liquidityFee = 4;
        buyFee.marketingFee = 4;
        buyFee.teamFee = 4;

        sellFee.liquidityFee = 1;
        sellFee.marketingFee = 6;
        sellFee.teamFee = 6;

        _isExcludedFromFee[owner] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromLimits[owner] = true;
        _isExcludedFromLimits[address(this)] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

// Basic contract functions
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
        return _checkTransfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _checkTransfer(sender, recipient, amount);
    }

    function _checkTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        // Only excluded from limit wallets can add initial liquidity
        if(!launched() && recipient == pair){
            require(_isExcludedFromLimits[sender] || _isExcludedFromLimits[recipient], "Trading is not active yet.");
            
        }
        
        if(limitsInEffect){
            if (!_isExcludedFromLimits[sender] || !_isExcludedFromLimits[recipient] &&
                recipient != address(0) && recipient != address(0xdead) && !inSwap){
            // If SniperProtection is active, apply penalty to snipers
            if(sniperProtection && recipient != pair && block.number - tradingActiveBlock < snipeBlocks){
                isSniper[recipient] = true;
                emit SniperCaught(recipient);
                }
            // If GasLimit function is active, check used gas for this transaction
            if (gasLimitActive && sender != pair) {
                require(tx.gasprice <= gasPriceLimit, "Gas price exceeds limit.");
                }
            // If SameBlock function is active, only one transaction per user per block is allowed
            if (sameBlockActive) {
                if (sender == pair){
                    require(lastTrade[recipient] != block.number);
                    lastTrade[recipient] = block.number;}
                else {
                    require(lastTrade[sender] != block.number);
                    lastTrade[sender] = block.number;}
                }
            }
        }
        _tokenTransfer(sender, recipient, amount);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + (amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
       
       //Max transaction limit check
       require(amount <= _maxTxAmount || _isExcludedFromLimits[recipient] || _isExcludedFromLimits[sender], "TX Limit Exceeded");
       
       bool Fees = true;
    
        //Apply Buy Fees
        if(sender == pair){
            buyFees();
        }
        //Apply Sell Fees
        if(recipient == pair){
            sellFees();
        //If seller sniped contract, apply penalty fees
        if(isSniper[sender] && snipersPenaltyEnd <= block.number){
            penaltyFees();
                }
        }
        //Check if should take fees, transfers are not taxed
        if(recipient != pair && sender != pair || _isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            Fees = false;
        }
        //Max Wallet limit check
        if (sender != owner && recipient != owner && recipient != address(this) && recipient != pair){
            uint256 heldTokens = balanceOf(recipient);
            require(_isExcludedFromLimits[recipient] || (heldTokens + amount) <= _maxWalletSize,"Total Holding is currently limited, you can not buy that much.");}
        //Exchange tokens
        if(shouldSwapBack(sender, recipient)){ swapBack(); }

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = Fees ? takeFee(recipient, amount) : amount;
        _balances[recipient] = _balances[recipient] + amountReceived;
            
        emit Transfer(sender, recipient, amountReceived);

        return true;
    }
    // Function calculate fee amount
    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount / 100 * (_totalFee);
        
        _balances[address(this)] = _balances[address(this)] + (feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount - (feeAmount);
    }
    //Fees applied on buys
    function buyFees() private {
        _teamFee = buyFee.teamFee;
        _liquidityFee = buyFee.liquidityFee;
        _marketingFee = buyFee.marketingFee;
        _totalFee = buyFee.teamFee + buyFee.liquidityFee + buyFee.marketingFee;
    }
    //Fees applied on sells
    function sellFees() private {
        _teamFee = sellFee.teamFee;
        _liquidityFee = sellFee.liquidityFee;
        _marketingFee = sellFee.marketingFee;
        _totalFee = sellFee.teamFee + sellFee.liquidityFee + sellFee.marketingFee;
    }
    //Fees applied to snipers, first 72h
    function penaltyFees() private {
        _teamFee = sellFee.teamFee * 3;
        _liquidityFee = sellFee.liquidityFee * 3;
        _marketingFee = sellFee.marketingFee * 3;
        _totalFee = (sellFee.teamFee + sellFee.liquidityFee + sellFee.marketingFee) * 3;
    }
    //Check if is already launched
    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }
    //AntiBots and trading auto-activated when liquidity is added
    function launch() external onlyOwner {
        launchedAt = block.timestamp;
        tradingActiveBlock = block.number;
        limitsInEffect = true;
        sniperProtection = true;
        gasLimitActive = true;
        sameBlockActive = true;
        snipersPenaltyEnd = block.timestamp + 72 hours;
    }
    //Check if contract should swap tokens from fees for marketing, liquidity and team
    function shouldSwapBack(address sender, address recipient) internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && !_isExcludedFromFee[recipient]
        && !_isExcludedFromFee[sender]
        && recipient == pair
        && balanceOf(address(this)) >= swapThreshold;
    }
    //Swap tokens from fees for marketing, liquidity and team
    function swapBack() internal swapping {       
        uint256 contractTokenBalance = balanceOf(address(this));
        if(contractTokenBalance >= maxSwapSize){
            tokensToSell = maxSwapSize;            
        }
        else{
            tokensToSell = contractTokenBalance;
        }

        uint256 amountToLiquify = tokensToSell * _liquidityFee / _totalFee / (2);
        uint256 amountToSwap = tokensToSell - amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountBNB = address(this).balance;
        uint256 totalBNBFee = _totalFee - (_liquidityFee / (2));
        uint256 amountBNBLiquidity = amountBNB * _liquidityFee / totalBNBFee / (2);
        uint256 amountBNBTeam = amountBNB * _teamFee / totalBNBFee;
        uint256 amountBNBMarketing = amountBNB - amountBNBLiquidity - amountBNBTeam;

        if(amountBNBTeam > 0) {payable(teamAddress).transfer(amountBNBTeam);}
        if(amountBNBMarketing > 0) {payable(marketingAddress).transfer(amountBNBMarketing);}        

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidityAddress,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }
   
// External Functions
    // Set excluded from fee wallets
    function excludeFromFee(address account, bool exempt) external onlyOwner {
        _isExcludedFromFee[account] = exempt;
        emit ExcludeFromFee(account, exempt);
    }
    // Set excluded from limits wallets
    function excludeFromLimits(address account, bool exempt) external onlyOwner {
        _isExcludedFromLimits[account] = exempt;
        emit ExcludeFromLimits(account, exempt);
    }
    // Set presale address, exempt from limits and fees
    function presaleAddress(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        _isExcludedFromLimits[account] = true;
        emit PresaleAddress(account);
    }
    // Set if contract should swap tokens from fees and minimum quantity before swap
    function setSwapBackSettings(bool _enabled, uint256 _swapThreshold, uint256 _maxSwapSize) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _swapThreshold;
        maxSwapSize = _maxSwapSize;
        emit SetSwapBackSettings(_enabled, swapThreshold, maxSwapSize);
    }
    // Set receivers
    function setFeeReceiver(address marketing, address team, address liquidity) external onlyOwner {
        marketingAddress = marketing;
        teamAddress = team;
        liquidityAddress = liquidity;
        emit SetFeeReceivers(marketing, team, liquidity);
    }
    // Owner can set fees, maximum fees is 30%
    function setBuyFees(uint16 liq, uint16 market, uint16 team) external onlyOwner {
        require(liq + market + team <= 30, "Total fees must be below 30%");
        buyFee.liquidityFee = liq;
        buyFee.marketingFee = market;
        buyFee.teamFee = team;
        buyFee.totalFee = liq + market + team;
        emit SetBuyFee(liq,market,team);
    }
    // Owner can set fees, maximum fees is 30%
    function setSellFees(uint16 liq, uint16 market, uint16 team) external onlyOwner {
        require(liq + market + team <= 30, "Total fees must be below 30%");
        sellFee.liquidityFee = liq;
        sellFee.marketingFee = market;
        sellFee.teamFee = team;
        sellFee.totalFee = liq + market + team;
        emit SetSellFee(liq,market,team);
    }
    // Use this function to remove wallets from sniper list
    function removeSniper(address account) external onlyOwner {
        isSniper[account] = false;
        emit RemovedSniper(account);
    }
    // AntiBot functions, the owner can activate or deactivate them if necessary
    function setProtectionSettings(bool limits, bool antiGas, bool sameBlock, bool sniperProtect) external onlyOwner() {
        limitsInEffect = limits; // Every antibot function is controlled by this variable
        gasLimitActive = antiGas; // Any transaction above the specified gas will be reverted
        sameBlockActive = sameBlock; // Only one transaction per user per block is allowed
        sniperProtection = sniperProtect; // If this function is active the snipers will be blacklisted
        emit SetProtectionSettings(limits, antiGas, sameBlock, sniperProtect);
    }
    // Maximum gas allowed for a transaction
    function setGasPriceLimit(uint256 gas) external onlyOwner {
        require(gas >= 75); // Set between 75 - 200
        gasPriceLimit = gas * 1 gwei;
        emit GasLimitSet(gas);
    }
    // Use this function to set maxWallet limit, minimum limit is 1%
    function setMaxWalletPercent_base1000(uint256 percentageBase1000) external onlyOwner {
        require(percentageBase1000 * (_totalSupply / 1000) >= _totalSupply / 100, "Can't set MaxWallet lower than 1%");
        _maxWalletSize = percentageBase1000 * (_totalSupply / 1000);
        emit SetMaxWallet(percentageBase1000);
    }
    // Use this function to set max transaction limit, minimum limit is 0.5%
    function setMaxTX(uint256 percentageBase1000) external onlyOwner {
        require(percentageBase1000 * (_totalSupply / 1000) >= _totalSupply / 200, "Can't set TxLimit lower than 0.5%");
        _maxTxAmount = percentageBase1000 * (_totalSupply / 1000);
        emit SetMaxTX(percentageBase1000);
    }

// Stuck Balance Functions
    // Transfer stuck bnb balance from contract to owner wallet
    function ClearStuckBalance() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        payable(msg.sender).transfer(contractBalance);
        emit StuckBalanceSent(contractBalance, msg.sender);
    }
    // Transfer stuck tokens to owner wallet, native token is not allowed
    function transferForeignToken(address _token) public onlyOwner {
        require(_token != address(this), "Can't let you take all native token");
        uint256 _contractBalance = IBEP20(_token).balanceOf(address(this));
        payable(msg.sender).transfer(_contractBalance);
        emit ForeignTokenTransfer(_token, _contractBalance);
    }
}