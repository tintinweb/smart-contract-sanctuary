/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract Ownable {
    address internal owner;
    address private _previousOwner;

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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
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

interface IPair {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function updateRWRD(address token) external;
}

contract DividendDistributor is IDividendDistributor {
    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 RWRD = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
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

    uint256 public minPeriod = 60 minutes;
    uint256 public minDistribution = 5 * (10 ** 18);

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

        totalShares = (totalShares - shares[shareholder].amount) + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = RWRD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(RWRD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = RWRD.balanceOf(address(this))-(balanceBefore);

        totalDividends += amount;
        dividendsPerShare += (dividendsPerShareAccuracyFactor*amount)/(totalShares);
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

            gasUsed += (gasLeft-(gasleft()));
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
            totalDistributed += amount;
            RWRD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised += amount;
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

        return shareholderTotalDividends -shareholderTotalExcluded;
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return (share*(dividendsPerShare))/(dividendsPerShareAccuracyFactor);
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
    
    function updateRWRD(address token) external override{
         RWRD = IBEP20(token);
    }

    function getRWRD() public view returns (address) {
        return address(RWRD);
    }
}

contract ShibaCookieInu is IBEP20, Ownable {

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "ShibaCookieInu";
    string constant _symbol = "ShibaCookieInu";
    uint8 constant _decimals = 2;

    uint256 _totalSupply = 420 * 10**1 * 10**_decimals;

    uint256 public _maxTxAmount = (_totalSupply/50);
    uint256 public _maxWalletToken = (_totalSupply/50);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) public _botList;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isMaxWalletExempt;

    uint256 public liquidityFee    = 0;
    uint256 public reflectionFee   = 3;
    uint256 public marketingFee    = 6;
    uint256 public buyBackFee = 3;
    uint256 public burner = 0;
    uint256 public buyFee = 12;
    uint256 public sellFee = 15;
    uint256 public totalFee        = marketingFee + reflectionFee + liquidityFee + buyBackFee;
    uint256 public feeDenominator  = 100;

    address public buyBackReceiver;
    address public marketingFeeReceiver;

    uint256 targetLiquidity = 90;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    bool public dropIt = true; 
    bool public tradingStarted = false; 
    bool public _botMode = true;
    
    uint256 private badBlocks = 2;
    uint256 public launchedAt = 0;

    DividendDistributor public distributor;
    uint256 distributorGas = 300000;

    bool public swapEnabled = true;
    uint256 public sellThreshold = _totalSupply / 1000;
    uint256 public swapThreshold = _totalSupply / 300;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Ownable(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[msg.sender][address(router)] = type(uint256).max;

        distributor = new DividendDistributor(address(router));

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[DEAD] = true;

        isMaxWalletExempt[pair] = true;
        isMaxWalletExempt[msg.sender] = true;
        isMaxWalletExempt[DEAD] = true;
        isMaxWalletExempt[address(this)] = true;

        buyBackReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;
        
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
            _allowances[sender][msg.sender] -= amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function setMaxWalletPercent_base1000(uint256 maxWallPercent_base1000) external onlyOwner() {
        _maxWalletToken = (_totalSupply * maxWallPercent_base1000 ) / 1000;
    }
    function setMaxTxPercent_base1000(uint256 maxTXPercentage_base1000) external onlyOwner() {
        _maxTxAmount = (_totalSupply * maxTXPercentage_base1000 ) / 1000;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        checkValidity(sender,recipient,amount);
 
        if(shouldSwapBack(amount)){ swapBack(); }

        //Exchange tokens
        _balances[sender] -=amount;

        uint256 amountReceived = (!shouldTakeFee(sender) || !shouldTakeFee(recipient)) ? amount : takeFee(sender, recipient, amount,(recipient == pair));
        _balances[recipient] += amountReceived;

        // Dividend tracker
        if(!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {} 
        }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkValidity(address sender, address recipient, uint256 _amount) internal view {
        require(_amount <= _maxTxAmount || isTxLimitExempt[sender]|| isTxLimitExempt[recipient], "TX Limit Exceeded");
        require((balanceOf(recipient) + _amount) <= _maxWalletToken || isMaxWalletExempt[recipient],"Total Holding is currently limited, you can not buy that much.");
        require(tradingStarted || isTxLimitExempt[sender], "Trading hasn't started yet, seer");
        if (_botMode && sender != pair){
            require(!_botList[sender] || sender == address(this), "Botsi Botsi Boom Boom");
            require(!_botList[msg.sender], "Bota Bota Boom Boom");
        }
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, address recipient, uint256 amount, bool isSell) internal returns (uint256) {
        
        uint256 fee = isSell ? sellFee : buyFee;
        uint256 feeAmount = (amount*fee)/feeDenominator;

        if(dropIt && !isSell && (launchedAt + badBlocks) > block.number){
            _botList[recipient]=true;
            isDividendExempt[recipient] = true;
        }

        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);
        
        return amount-feeAmount;
    }

    function shouldSwapBack(uint256 amount) internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && amount > sellThreshold
        && _balances[address(this)] >= swapThreshold;
    }

    function setDropIt(bool _dropIt) external onlyOwner{
        dropIt = _dropIt;        
    }
    
    function startTrading(uint256 _badBlocks) external onlyOwner {
        launchedAt = block.number;
        badBlocks = _badBlocks;
        tradingStarted = true;
    }
    
    function swapBack() internal swapping {
        uint256 amountToSwap = swapThreshold;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance - (balanceBefore);
        
        uint256 amountBNBReflection = (amountBNB * reflectionFee)/(totalFee);
        uint256 amountBNBMarketing = (amountBNB * marketingFee)/(totalFee);
        uint256 amountBNBBuyBack = (amountBNB * buyBackFee)/(totalFee);
        
        if(reflectionFee>0) {try distributor.deposit{value: amountBNBReflection}() {} catch {}}
        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        (tmpSuccess,) = payable(buyBackReceiver).call{value: amountBNBBuyBack, gas: 30000}("");
        
        // only to supress warning msg
        tmpSuccess = false;
    }
    
    function buyBack(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            DEAD,
            block.timestamp
        );
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _buyBackFee, uint256 _burner, uint256 _buyFee, uint256 _sellFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        buyBackFee = _buyBackFee;
        burner = _burner;
        buyFee = _buyFee;
        sellFee = _sellFee;
        totalFee = _liquidityFee + _reflectionFee + _marketingFee +_buyBackFee;
        feeDenominator = _feeDenominator;
    }

    function setFeeReceivers(address _buyBackReceiver, address _marketingFeeReceiver) external onlyOwner {
        buyBackReceiver = _buyBackReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function updateRWRDToken(address token) external onlyOwner  {
        distributor.updateRWRD(token);
    }

    function getRWRDToken() public view returns (address) {
        return distributor.getRWRD();
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply-(balanceOf(DEAD))-(balanceOf(ZERO));
    }

    function manageBots(address[] calldata addresses, bool status) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
             _botList[addresses[i]] = status;
        }
    }

    function botMode(bool enabled) external onlyOwner{
        _botMode = enabled;
    }

    function rescueBNB() external {
        require (msg.sender==marketingFeeReceiver);
        uint256 amountBNB = address(this).balance;
        payable(marketingFeeReceiver).transfer(amountBNB);
    }
    
    function rescueToken(address tokenAddress, uint256 tokens) external returns (bool success) {
        require (msg.sender==marketingFeeReceiver);
        return IBEP20(tokenAddress).transfer(msg.sender, tokens);
    }
}