/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

// SPDX-License-Identifier: unlicensed

pragma solidity ^0.8.6;

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

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
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
 * Rewards in MATIC Token : 0xCC42724C6683B7E57334c4E856f4c9965ED682bD
 */

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 RWRD = IBEP20(0xCC42724C6683B7E57334c4E856f4c9965ED682bD);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 45 * 60;
    uint256 public minDistribution = 1 * (10 ** 8);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares - (shares[shareholder].amount) + (amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = RWRD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(RWRD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = RWRD.balanceOf(address(this)) - (balanceBefore);

        totalDividends = totalDividends + (amount);
        dividendsPerShare = dividendsPerShare + (dividendsPerShareAccuracyFactor * (amount) / (totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed + (gasLeft - (gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed + amount;
            RWRD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised + (amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends - (shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share * (dividendsPerShare) / (dividendsPerShareAccuracyFactor);
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

/**
 * Contract Code
 */

contract MetaMATIC is IBEP20, Auth {

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "MetaMATIC";
    string constant _symbol = "MMTC";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 10 * 10**10 * 10**_decimals;

    mapping (address => uint256) _balances;
    mapping (address => uint256) public BuyCooldownTimer;
    mapping (address => uint256) public SellCooldownTimer;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) public canAddLiquidityBeforeLaunch;

    // Detailed Fees
    uint256 public liquidityFee;
    uint256 public reflectionFee;
    uint256 public marketingFee;
    uint256 public DevFee;
    uint256 public totalFee;

    uint256 public BuyliquidityFee    = 2;
    uint256 public BuyreflectionFee   = 2;
    uint256 public BuymarketingFee    = 2;
    uint256 public BuyDevFee      = 0;
    uint256 public BuytotalFee        = 6;

    uint256 public SellliquidityFee    = 4;
    uint256 public SellreflectionFee   = 4;
    uint256 public SellmarketingFee    = 4;
    uint256 public SellDevFee      = 0;
    uint256 public SelltotalFee        = 12;

    uint256 public launchedAt = 0;

    // Max wallet & Transaction
    uint256 public _maxBuyTxAmount = _totalSupply / (100) * (2); // 2%
    uint256 public _maxSellTxAmount = _totalSupply / (100) * (1); // 1%
    uint256 public _maxWalletToken = _totalSupply / (100) * (2); // 2%

    // Fees receivers
    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public DevFeeReceiver;

    IDEXRouter public router;
    address public pair;

    bool public tradingOpen = false;
    bool public autoLimits = true;

    DividendDistributor public distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000 * 1; // 0.1%
    uint256 public maxSwapSize = _totalSupply / 100 * 1; //1%
    uint256 public tokensToSell;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
  
    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
                
        distributor = new DividendDistributor(address(router));

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        
        canAddLiquidityBeforeLaunch[msg.sender] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = 0x159B6BaC06A708158714a78E35Def1974436354d ;
        marketingFeeReceiver = 0x309cA0c576D704411788ACb3C329d931151e5429 ;
        DevFeeReceiver = 0x0394DF923e2D3f2FE4BC842670856B3cc487c64D ;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
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
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
    
        // Avoid airdropped from ADD LP before launch
        if(!tradingOpen && recipient == pair && sender == pair){
            require(canAddLiquidityBeforeLaunch[sender]);
        }
        
        if(!authorizations[sender] && !authorizations[recipient]){
            require(tradingOpen,"Trading not open yet");
        }

        if(sender == pair){
            buyFees();
        }

        if(recipient == pair){
            sellFees();
        }

        if (!authorizations[sender] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != marketingFeeReceiver && recipient != DevFeeReceiver  && recipient != autoLiquidityReceiver){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");}

        // Checks max transaction limit
        if(autoLimits){ checkTxLimit();}

        if(sender == pair){
            require(amount <= _maxBuyTxAmount || isTxLimitExempt[recipient], "TX Limit Exceeded");
        }
        
        if(recipient == pair){
            require(amount <= _maxSellTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        }
        //Exchange tokens
        if(shouldSwapBack()){ swapBack(); }

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(recipient, amount) : amount;
        _balances[recipient] = _balances[recipient] + amountReceived;

        // Dividend tracker - Auto wallet to distribute the rewards
        if(!isDividendExempt[sender]) {
            try distributor.setShare(sender, balanceOf(sender)) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, balanceOf(recipient)) {} catch {} 
        }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + (amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Internal Functions - No whaling into the project
   function checkTxLimit() internal{ 
        uint256 time_since_start = block.timestamp - launchedAt; 
        if (time_since_start < 4 minutes ) { 
            _maxBuyTxAmount = _totalSupply / (100) * (1); 
            _maxSellTxAmount = _totalSupply / (1000) * (5); 
            _maxWalletToken = _totalSupply / (100) * (1); 
        } 
        if (time_since_start < 2 minutes ) { 
            _maxBuyTxAmount = _totalSupply / (1000) * (5); 
            _maxSellTxAmount = _totalSupply / (10000) * (25); 
            _maxWalletToken = _totalSupply / (1000) * (5); 
        } 
        if (time_since_start < 1 minutes ) { 
            _maxBuyTxAmount = _totalSupply / (10000) * (25); 
            _maxSellTxAmount = _totalSupply / (10000) * (25); 
            _maxWalletToken = _totalSupply / (10000) * (25); 
        } 
        else { 
            _maxBuyTxAmount = _totalSupply / (100) * (2); 
            _maxSellTxAmount = _totalSupply / (100) * (1); 
            _maxWalletToken = _totalSupply / (100) * (2); 
        } 
    }

    function buyFees() internal{
        liquidityFee    = BuyliquidityFee;
        reflectionFee   = BuyreflectionFee;
        marketingFee    = BuymarketingFee;
        DevFee      = BuyDevFee;
        totalFee        = BuytotalFee;
    }

    function sellFees() internal{
        liquidityFee    = SellliquidityFee;
        reflectionFee   = SellreflectionFee;
        marketingFee    = SellmarketingFee;
        DevFee      = SellDevFee;
        totalFee        = SelltotalFee;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
   
        uint256 feeAmount = amount / 100 * (totalFee);

        _balances[address(this)] = _balances[address(this)] + (feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount - (feeAmount);
    }
  
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = balanceOf(address(this));
        if(contractTokenBalance >= maxSwapSize){
            tokensToSell = maxSwapSize;            
        }
        else{
            tokensToSell = contractTokenBalance;
        }

        uint256 amountToLiquify = tokensToSell / (totalFee) * (liquidityFee) / (2);
        uint256 amountToSwap = tokensToSell - (amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance - (balanceBefore);

        uint256 totalBNBFee = totalFee - (liquidityFee / (2));
        
        uint256 amountBNBLiquidity = amountBNB * (liquidityFee) / (totalBNBFee) / (2);
        uint256 amountBNBReflection = amountBNB * (reflectionFee) / (totalBNBFee);
        uint256 amountBNBMarketing = amountBNB * (marketingFee) / (totalBNBFee);
        uint256 amountBNBDev = amountBNB - amountBNBLiquidity - amountBNBReflection - amountBNBMarketing;

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        (bool MarketingSuccess,) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");
        (bool DevSuccess,) = payable(DevFeeReceiver).call{value: amountBNBDev, gas: 30000}("");
        require(DevSuccess, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    // External Functions
    function checkSwapThreshold() external view returns (uint256) {
        return swapThreshold;
    }
    
    function checkMaxWalletToken() external view returns (uint256) {
        return _maxWalletToken;
    }
    
    function checkMaxBuyTxAmount() external view returns (uint256) {
        return _maxBuyTxAmount;
    }
    
    function checkMaxSellTxAmount() external view returns (uint256) {
        return _maxSellTxAmount;
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    // Only Authorized allowed
    function tradingStatus(bool _status) public authorized {
        tradingOpen = _status;
        if(tradingOpen && launchedAt == 0){
            launchedAt = block.number;
        }
    }

    function setBuyFees(uint256 _liquidityFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _DevFee) external authorized {
        BuyliquidityFee = _liquidityFee;
        BuyreflectionFee = _reflectionFee;
        BuymarketingFee = _marketingFee;
        BuyDevFee = _DevFee;
        BuytotalFee = _liquidityFee + (_reflectionFee) + (_marketingFee) + (_DevFee);
    }

    function setSellFees(uint256 _liquidityFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _DevFee) external authorized {
        SellliquidityFee = _liquidityFee;
        SellreflectionFee = _reflectionFee;
        SellmarketingFee = _marketingFee;
        SellDevFee = _DevFee;
        SelltotalFee = _liquidityFee + (_reflectionFee) + (_marketingFee) + (_DevFee);
    }
    
    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _DevFeeReceiver ) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        DevFeeReceiver = _DevFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _percentage_min_base10000, uint256 _percentage_max_base10000) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _totalSupply / (10000) * (_percentage_min_base10000);
        maxSwapSize = _totalSupply / (10000) * (_percentage_max_base10000);
    }

    function setCanTransferBeforeLaunch(address holder, bool exempt) external authorized {
        canAddLiquidityBeforeLaunch[holder] = exempt; //Presale Address will be added as Exempt
        isTxLimitExempt[holder] = exempt;
        isFeeExempt[holder] = exempt;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, balanceOf(holder));
        }
    }
    
    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }
    
    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }
      
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }
       
    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 900000);
        distributorGas = gas;
    }
    
    function setMaxWalletPercent_base1000(uint256 maxWallPercent_base1000) external onlyOwner() {
        autoLimits = false;
        _maxWalletToken = _totalSupply / (1000) * (maxWallPercent_base1000);
    }

    function setMaxBuyTxPercent_base1000(uint256 maxBuyTXPercentage_base1000) external onlyOwner() {
        autoLimits = false;
        _maxBuyTxAmount = _totalSupply / (1000) * (maxBuyTXPercentage_base1000);
    }

    function setMaxSellTxPercent_base1000(uint256 maxSellTXPercentage_base1000) external onlyOwner() {
        autoLimits = false;
        _maxSellTxAmount = _totalSupply / (1000) * (maxSellTXPercentage_base1000);
    }

    // Stuck Balances Functions
    function rescueToken(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return IBEP20(tokenAddress).transfer(msg.sender, tokens);
    }

    function clearStuckBalance(uint256 amountPercentage) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(marketingFeeReceiver).transfer(amountBNB * amountPercentage / 100);
    }

event AutoLiquify(uint256 amountBNB, uint256 amountTokens);

}
    // Contract Deployer OLEC