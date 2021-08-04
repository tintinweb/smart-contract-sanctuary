/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 BUSD = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
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

    uint256 public minPeriod = 30 minutes;
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
        : IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
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
        uint256 balanceBefore = BUSD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(BUSD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = BUSD.balanceOf(address(this)).sub(balanceBefore);

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
            BUSD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
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
}

contract DogeCare is IBEP20, Auth {
    using SafeMath for uint256;

    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "DogeCare";
    string constant _symbol = "DOGECARE";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1*10 ** 15 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply / 100; // 1%
    uint256 public _maxHold = _totalSupply / 50; // 2%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isMaxHoldExempt;
    mapping (address => bool) isDividendExempt;

    struct OperationType {
        uint256 buy;
        uint256 sell;
    }

    OperationType distributionFee = OperationType(400, 1000);
    OperationType charityFee = OperationType(400, 400);
    OperationType liquidityFee = OperationType(200, 200);
    OperationType marketingFee = OperationType(200, 200);

    OperationType totalFee;

    uint256 public accDistributionFee;
    uint256 public accCharityFee;
    uint256 public accLiquidityFee;
    uint256 public accMarketingFee;

    uint256 feeDenominator = 10000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public charityFeeReceiver;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    bool public exchangeTxEnabled;

    /********* SELL LIMITS *********/
    mapping (address => bool) private _isExcludedFromPeriodLimit;
    mapping (address => uint256) accountLastPeriodSellVolume;
    uint256 restrictionPeriod = 24 hours;
    struct Sell {
        uint256 time;
        uint256 amount;
    }
    mapping (address => Sell[]) accountSells;

    /****************/

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 20000; // 0.005%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    event AutoLiquify(uint256 amountBNB, uint256 amountToken);
    event SendReward(uint256 amountBUSD, address to);
    event SetRestrictionPeriod(uint256 OldPeriod, uint256 NewPeriod);
    event SetMaxTxAmount(uint256 oldValue, uint256 newValue);
    event SetMaxHold(uint256 oldValue, uint256 newValue);
    event UpdateExchangeTxStatus(bool status);
    event ExcludeFromPeriodLimit(address indexed account, bool isExcluded);

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;


        _isExcludedFromPeriodLimit[address(this)] = true;
        _isExcludedFromPeriodLimit[address(router)] = true;
        _isExcludedFromPeriodLimit[address(pair)] = true;
        _isExcludedFromPeriodLimit[msg.sender] = true;

        distributor = new DividendDistributor(address(router));

        isMaxHoldExempt[address(this)] = true;
        isMaxHoldExempt[address(pair)] = true;
        isMaxHoldExempt[address(router)] = true;
        isMaxHoldExempt[msg.sender] = true;
        isMaxHoldExempt[DEAD] = true;
        isMaxHoldExempt[ZERO] = true;

        isFeeExempt[msg.sender] = true;

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(router)] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[msg.sender] = true;


        isDividendExempt[address(this)] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = 0x32A9D7b3Fc1f1C4631b2994aeB2f9BB59b4f9687;
        charityFeeReceiver = 0xEf42b6c18998aeBD8Aa706E2288BBe156C091AaD;

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
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }



    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        checkPeriodLimit(sender, amount);
        checkTxLimit(sender, amount);
        checkExchangeTx(sender, recipient);
        checkMaxHold(recipient, amount);

        if(shouldSwapBack()){ swapBack(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

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

    function checkPeriodLimit(address sender, uint256 amount) internal {
        if (!_isExcludedFromPeriodLimit[sender]) {
            require(getAccountPeriodSellVolume(sender).add(amount) <= balanceOf(sender).div(2), "Sell limit!");
        }
        accountLastPeriodSellVolume[sender] = accountLastPeriodSellVolume[sender].add(amount);
        Sell memory sell;
        sell.amount = amount;
        sell.time = block.timestamp;
        accountSells[sender].push(sell);
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function checkMaxHold(address to, uint256 amount) internal view {
        require(balanceOf(to).add(amount) <= _maxHold, "Max Hold Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }


    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 forMarketingFee;
        uint256 forCharityFee;
        uint256 forLiquidityFee;
        uint256 forDistributionFee;

        if (receiver == pair) {
            forMarketingFee = amount.mul(marketingFee.sell).div(feeDenominator);
            forCharityFee = amount.mul(charityFee.sell).div(feeDenominator);
            forLiquidityFee = amount.mul(liquidityFee.sell).div(feeDenominator);
            forDistributionFee = amount.mul(distributionFee.sell).div(feeDenominator);
        } else {
            forMarketingFee = amount.mul(marketingFee.buy).div(feeDenominator);
            forCharityFee = amount.mul(charityFee.buy).div(feeDenominator);
            forLiquidityFee = amount.mul(liquidityFee.buy).div(feeDenominator);
            forDistributionFee = amount.mul(distributionFee.buy).div(feeDenominator);
        }

        uint256 totalFeeAmount = forMarketingFee.add(forCharityFee).add(forLiquidityFee).add(forDistributionFee);
        accCharityFee = accCharityFee.add(forCharityFee);
        accMarketingFee = accMarketingFee.add(forMarketingFee);
        accDistributionFee = accDistributionFee.add(forDistributionFee);
        accLiquidityFee = accLiquidityFee.add(forLiquidityFee);

        _balances[address(this)] = _balances[address(this)].add(totalFeeAmount);
        emit Transfer(sender, address(this), totalFeeAmount);
        return amount.sub(totalFeeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapAndSendToMarketingAndCharity(uint256 bnbForMarketing, uint256 bnbForCharity) internal {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(BUSD);
        uint256 bnbAmount = bnbForCharity.add(bnbForMarketing);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmount}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 busdAmount = IBEP20(BUSD).balanceOf(address(this));
        uint256 busdForMarketing = busdAmount.mul(bnbForMarketing).div(bnbAmount);
        uint256 busdForCharity = busdAmount.sub(busdForMarketing);
        IBEP20(BUSD).transfer(marketingFeeReceiver, busdForMarketing);
        IBEP20(BUSD).transfer(charityFeeReceiver, busdForCharity);
    }

    function swapBack() internal swapping {
        uint256 totalAcc = balanceOf(address(this));

        uint256 amountToLiquify = accLiquidityFee.div(2);
        uint256 amountToSwap = totalAcc.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 onePart = address(this).balance.div(amountToSwap);

        uint256 amountBNBLiquidity = onePart.mul(accLiquidityFee.sub(amountToLiquify));
        uint256 amountBNBDistribution = onePart.mul(accDistributionFee);
        uint256 amountBNBMarketing = onePart.mul(accMarketingFee);
        uint256 amountBNBCharity = onePart.mul(accCharityFee);

        try distributor.deposit{value: amountBNBDistribution}() {} catch {}

        swapAndSendToMarketingAndCharity(amountBNBMarketing, amountBNBCharity);

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

    function checkExchangeTx(address from, address to) internal view {
        if (!exchangeTxEnabled) {
            require(from != pair && to != pair, "Exchanger Tx is disabled.");
        }
    }

    function updateExchangeTx(bool status) external authorized {
        require(exchangeTxEnabled != status, "Provide different status from current");
        exchangeTxEnabled = status;
        emit UpdateExchangeTxStatus(status);
    }

    function setTxLimit(uint256 amount) external authorized {
        emit SetMaxTxAmount(_maxTxAmount, amount);
        _maxTxAmount = amount;
    }

    function setMaxHoldPercent(uint256 amount) external authorized {
        require(_maxHold > _totalSupply.div(1000));
        emit SetMaxHold(_maxHold, amount);
        _maxHold = amount;
    }


    function setRestrictionPeriod(uint256 _newPeriodHours) external authorized {
        emit SetRestrictionPeriod(restrictionPeriod, _newPeriodHours);
        restrictionPeriod = _newPeriodHours * 1 hours;
    }

    function getAccountPeriodSellVolume(address account) public returns(uint256) {
        uint256 offset;
        for (uint256 i = 0; i < accountSells[account].length-1; i++) {
            if (block.timestamp.sub(accountSells[account][i].time) <= restrictionPeriod) {
                break;
            }
            accountLastPeriodSellVolume[account] = accountLastPeriodSellVolume[account].sub(accountSells[account][i].amount);
            offset++;
        }
        if (offset > 0) {
            removeAccSells(account, offset);
        }
        return accountLastPeriodSellVolume[account];
    }

    function removeAccSells(address account, uint256 offset) private {
        require(offset <= accountSells[account].length);
        for (uint256 i = 0; i < accountSells[account].length-1; i++) {
            accountSells[account][i] = accountSells[account][i+offset];
        }
        for (uint256 i = 0; i < offset; i++) {
            accountSells[account].pop();
        }
    }

    function excludeFromPeriodLimit(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromPeriodLimit[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromPeriodLimit[account] = excluded;

        emit ExcludeFromPeriodLimit(account, excluded);
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

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsMaxHoldExempt(address holder, bool exempt) external authorized {
        isMaxHoldExempt[holder] = exempt;
    }

    function setBuyFees(uint256 _liquidityFee, uint256 _distributionFee, uint256 _marketingFee, uint256 _charityFee) external authorized {
        liquidityFee.buy = _liquidityFee;
        distributionFee.buy = _distributionFee;
        marketingFee.buy = _marketingFee;
        charityFee.buy = _charityFee;
        totalFee.buy = _liquidityFee.add(_distributionFee).add(_marketingFee).add(_charityFee);
        require(totalFee.buy <= 4000, "Too big amount of fee. Please provide less than 40% in sum.");
    }

    function setSellFees(uint256 _liquidityFee, uint256 _distributionFee, uint256 _marketingFee, uint256 _charityFee) external authorized {
        liquidityFee.sell = _liquidityFee;
        distributionFee.sell = _distributionFee;
        marketingFee.sell = _marketingFee;
        charityFee.sell = _charityFee;
        totalFee.sell = _liquidityFee.add(_distributionFee).add(_marketingFee).add(_charityFee);
        require(totalFee.sell <= 4000, "Too big amount of fee. Please provide less than 40% in sum.");
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _charityFeeReceiver) external authorized {
        require(_marketingFeeReceiver != address(0), "Marketing wallet should be real address");
        require(_charityFeeReceiver != address(0), "Charity wallet should be real address");
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        charityFeeReceiver = _charityFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
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

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
}