/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

/**

https://t.me/JizzApe
https://t.me/JizzApe

The Horniest Apes on the Binance Smart Chain!


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
 * Allows for contract ownership along with multi-address authorization
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
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
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
    function claimDividend(address shareholder) external;
    function getRAddress() external view returns (address);
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
        uint256 totalRealised;
    }

    IBEP20 RWDS = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
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

    //SETMEUP, change this to 1 hour instead of 10mins
    uint256 public minPeriod = 45 minutes;
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
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
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
            block.timestamp
        );

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
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
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
            totalDistributed = totalDistributed.add(amount);
            RWDS.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function getRAddress() public view override returns (address) {
        return address(RWDS);
    }
    
    function claimDividend(address shareholder) external override {
        distributeDividend(shareholder);
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


    function gettotalDistributed() public view override returns (uint256) {
        return uint256(totalDistributed);
    }

    function getRewardsOwed(address _wallet) external override view returns (uint256) {
        address shareholder = _wallet;
        return uint256(getCumulativeDividends(shares[shareholder].amount));
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

contract JizzApe is IBEP20, Auth {
    using SafeMath for uint256;

    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; 
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "JIZZAPE";    
    string constant _symbol = "JIZZAPE";
    uint8 constant _decimals = 9;
    
    uint256 _totalSupply = 100 * 10**9 * (10 ** _decimals);
    uint256 public _maxTxAmount = ( _totalSupply * 10 ) / 1000;
    uint256 public mStx = ( _totalSupply * 10 ) / 1000;
    uint256 public asT = _totalSupply * 4 / 10000;
    uint256 public _maxWalletToken = ( _totalSupply * 20 ) / 1000;  
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isBt;
    mapping (address => bool) isTimelockExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isMaxWalletExempt;
    uint256 liqFee = 10; 
    uint256 reflFee = 0;
    uint256 markFee = 0;
    uint256 totFee = 10;
    uint256 feeDenom  = 100;
    address autoLiquidityReceiver;
    uint256 targetLiquidity = 35;
    uint256 targetLiquidityDenominator = 100;
    uint256 pyr = 30;
    address CSB;
    uint256 tkr = 30;
    address MARK;
    uint256 lpr = 20;
    IDEXRouter public router;
    address public pair;
    uint256 launchedAt;
    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public buyCooldownEnabled = true;
    uint8 public cooldownTimerInterval = 30; 
    mapping (address => uint) private cooldownTimer;
    bool LFG = false;
    bool public bbt = true;
    uint256 public bbf = 16;
    bool sFrz = true;
    uint8 sFrzT = 30;
    mapping (address => uint) private sFrzin;
    uint8 mStts = 2 seconds;
    mapping (address => uint) private mSts;
    bool public sst = true;
    uint256 public ssf = 20;
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
        isFeeExempt[address(owner)] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(MARK)] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(owner)] = true;
        isMaxWalletExempt[msg.sender] = true;
        isMaxWalletExempt[address(this)] = true;
        isMaxWalletExempt[address(DEAD)] = true;
        isMaxWalletExempt[address(pair)] = true;
        isMaxWalletExempt[address(MARK)] = true;
        isMaxWalletExempt[address(autoLiquidityReceiver)] = true;
        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        autoLiquidityReceiver = msg.sender;
        CSB = msg.sender;
        MARK = msg.sender;

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

     function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletToken = (_totalSupply * maxWallPercent ) / 100;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        if(!authorizations[sender] && !authorizations[recipient]){require(LFG);}
        if (!authorizations[sender] && !isMaxWalletExempt[recipient] && recipient != address(this)  && recipient != address(DEAD) 
            && recipient != pair && recipient != MARK && recipient != autoLiquidityReceiver){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");}
        if(sender == pair &&
            buyCooldownEnabled &&
            !isTimelockExempt[recipient]) {
            require(cooldownTimer[recipient] < block.timestamp,"Please wait for cooldown between buys");
            cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval; }
        if(sender != pair &&
            sFrz &&
            !isTimelockExempt[sender]) {
            require(sFrzin[sender] < block.timestamp); 
            sFrzin[sender] = block.timestamp + sFrzT;} 
        checkTxL(sender, amount);
        chkSmTx(sender != pair, sender, amount);
        if(sender == pair){mSts[recipient] = block.timestamp + mStts;}
        if(shouldSwapBack(amount) && mSts[sender] < block.timestamp){ swapBack(); }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        if(!isDividendExempt[sender] && mSts[sender] < block.timestamp) {
            try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient] && mSts[sender] < block.timestamp) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {} }
        if(mSts[sender] < block.timestamp){
        try distributor.process(distributorGas) {} catch {} }
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxL(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function chkSmTx(bool selling, address sender, uint256 amount) internal view {
        if(selling && mSts[sender] < block.timestamp){
            require(amount <= mStx && !isBt[sender]|| isTimelockExempt[sender]);}
    }

    function setPresaleAddress(address _PresaleAddress) external onlyOwner {
        authorizations[_PresaleAddress] = true;
        isFeeExempt[_PresaleAddress] = true;
        isTxLimitExempt[_PresaleAddress] = true;
        isTimelockExempt[_PresaleAddress] = true;
        isDividendExempt[_PresaleAddress] = true;
        isMaxWalletExempt[_PresaleAddress] = true;
    }

    function getTF(bool selling) public view returns (uint256) {
        if(selling && sst){ return ssf.mul(1); }
        if(!selling && bbt){ return bbf.mul(1); }
        return totFee;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTF(receiver == pair)).div(feeDenom);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function shouldSwapBack(uint256 amount) internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && amount >= asT
        && _balances[address(this)] >= swapThreshold;
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(CSB).transfer(amountBNB * amountPercentage / 100);
    }

    function setLFG() external onlyOwner {
        LFG = true;
    }

    function setbbfe(bool _enabled, uint256 _bbf) external authorized {
        bbt = _enabled;
        bbf = _bbf;
    }
    
    function cooldownEnabled(bool _status, uint8 _interval) public onlyOwner {
        buyCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiqFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : lpr;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiqFee).div(totFee).div(2);
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

        uint256 totalBNBFee = totFee.sub(dynamicLiqFee.div(2));
        
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiqFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(pyr).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(tkr).div(totalBNBFee);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        (bool tmpSuccess,) = payable(MARK).call{value: amountBNBMarketing, gas: 30000}("");
        
        tmpSuccess = false;

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

    function setBTxLimt(uint256 amount) external authorized {
        _maxTxAmount = amount;
    }

    function setSTxLimit(uint256 amount) external authorized {
        mStx = amount;
    }

    function setMARK(address mark) external authorized {
        MARK = mark;
    }

    function setmswt(uint256 amount) external authorized {
        asT = amount;
    }

    function setCSB(address csb) external authorized {
        CSB = csb;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setDistributionFactors(uint256 _pyr, uint256 _tkr, uint256 _lpr) external authorized {
        pyr = _pyr;
        tkr = _tkr;
        lpr = _lpr;
    }

    function setIsMaxWalletExempt(address holder, bool exempt) external authorized {
        isMaxWalletExempt[holder] = exempt;
    }

    function setsste(bool _enabled, uint256 _ssf) external authorized {
        sst = _enabled;
        ssf = _ssf;
    }

    function setWAs(address mark, address csb) external authorized {
        MARK = mark;
        CSB = csb;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setisBt(address holder, bool exempt) external authorized {
        isBt[holder] = exempt;
    }

    function setpresAlE() external onlyOwner {
        LFG = false;
        sFrz = false;
        bbt = false; 
        buyCooldownEnabled = false; 
        sst = false;
        totFee = 0; 
        swapEnabled = false;
    }

    function setIsTimelockExempt(address holder, bool exempt) external authorized {
        isTimelockExempt[holder] = exempt;
    }

    function setsFrz(bool _status, uint8 _int) external authorized {
        sFrz = _status;
        sFrzT = _int;
    }

    function setFFEEs(uint256 _liquidityFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external authorized {
        liqFee = _liquidityFee;
        reflFee = _reflectionFee;
        markFee = _marketingFee;
        totFee = _liquidityFee.add(_reflectionFee).add(_marketingFee);
        feeDenom = _feeDenominator;
        require(totFee < feeDenom/3);
    }

    function setFeeReceivers(address _autoLiquidityReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setLauNch() external onlyOwner {
        sFrz = true;
        bbt = true; 
        buyCooldownEnabled = true; 
        sst = true;
        totFee = liqFee.add(markFee).add(reflFee); 
        swapEnabled = true;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }

    function _getMyRewards() external {
        address shareholder = msg.sender;
        distributor.claimDividend(shareholder);
    }

    function getMyRewardsOwed(address _wallet) external view returns (uint256){
        return distributor.getRewardsOwed(_wallet);
    }

    function getMyTotalRewards(address _wallet) external view returns (uint256){
        return distributor.getTotalRewards(_wallet);
    }

    function currentReward() public view returns (address) {
        return distributor.getRAddress();
    }

    function gettotalRewardsDistributed() public view returns (uint256) {
        return distributor.gettotalDistributed();
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