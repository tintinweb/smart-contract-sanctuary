/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

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

contract DividendDistributor {
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address tokenAddress=0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;

    
    IBEP20 BUSD = IBEP20(tokenAddress);
    IDEXRouter public ROUTER = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    address token;
    address[] shareHolders;
    uint256 currentIndex;

    mapping (address => Share) public shares;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**18;
    uint256 public gasLimit = 300000;
    uint256 public minPeriod = 1 minutes;
    uint256 public minDistribution = 10;

    event Deposit(uint256 amount);
    event SetShare(address indexed account, uint256 amount);
    event Process();
    event DividendDistributed(address indexed to, uint256 amount);
    event SetDistributionCriteria(uint256 period, uint256 amount);
    event SetGasLimit(uint256 newGas, uint256 oldGas);
    modifier onlyToken() {
        require(msg.sender == token);
        _;
    }

    constructor (address _router, address rewardToken) {
           ROUTER = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        token = msg.sender;
        BUSD = IBEP20(rewardToken);
    }

    function deposit() external payable onlyToken {
        if (msg.value > 0) {
            address[] memory path = new address[](2);
            path[0] = ROUTER.WETH();
            path[1] = address(BUSD);
            uint256 balanceBefore = BUSD.balanceOf(address(this));
            ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
                0,
                path,
                address(this),
                block.timestamp
            );
            uint256 receivedAmount = BUSD.balanceOf(address(this)) - balanceBefore;
            totalDividends += receivedAmount;
            dividendsPerShare += dividendsPerShareAccuracyFactor * receivedAmount / totalShares;
            emit Deposit(msg.value);
        }
    }

    function setShare(address shareholder, uint256 amount) external onlyToken {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }
        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }
        totalShares = totalShares - shares[shareholder].amount + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        emit SetShare(shareholder, amount);
    }

    function process(uint256 gas) external onlyToken {
        uint256 shareholderCount = shareHolders.length;
        if (shareholderCount == 0) { return; }
        uint256 gasLeft = gasleft();
        uint256 gasUsed;
        uint256 iterations;
        while (gasUsed  < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) { currentIndex = 0; }
            if(shouldDistribute(shareHolders[currentIndex])){
                distributeDividend(shareHolders[currentIndex]);
            }
            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) { return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if (shareholderTotalDividends <= shareholderTotalExcluded) { return 0; }
        return shareholderTotalDividends - shareholderTotalExcluded;
    }
    
    function shouldDistribute(address shareholder) private view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) private {
        if (shares[shareholder].amount == 0) { return; }
        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised += amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            totalDistributed += amount;
            BUSD.transfer(shareholder, amount);
            emit DividendDistributed(shareholder, amount);
        }
    }

    function getCumulativeDividends(uint256 share) private view returns (uint256) {
        return share * dividendsPerShare / dividendsPerShareAccuracyFactor;
    }

    function addShareholder(address shareholder) private {
        shareholderIndexes[shareholder] = shareHolders.length;
        shareHolders.push(shareholder);
    }

    function removeShareholder(address shareholder) private {
        shareHolders[shareholderIndexes[shareholder]] = shareHolders[shareHolders.length-1];
        shareholderIndexes[shareHolders[shareHolders.length-1]] = shareholderIndexes[shareholder];
        shareHolders.pop();
    }

    function setDistributionCriteria(uint256 newPeriod, uint256 newMinDistribution) external onlyToken {
        require(newPeriod <= 1 weeks && newMinDistribution <= 1 ether, "Invalid parameters");
        minPeriod = newPeriod;
        minDistribution = newMinDistribution;
        emit SetDistributionCriteria(newPeriod, newMinDistribution);
    }

       function purge(address receiver) external onlyToken {
        uint256 balance = BUSD.balanceOf(address(this));
        BUSD.transfer(receiver, balance);
    }

    function setGasLimit(uint256 newGasLimit) external onlyToken {
        emit SetGasLimit(newGasLimit, gasLimit);
        gasLimit = newGasLimit;
    }

}

contract test3x is IBEP20, Auth {
    using SafeMath for uint256;

    address WBNB = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "ma";
    string constant _symbol = "ma";
    uint8 constant _decimals = 2;

    uint256 _totalSupply = 1225 * 10**10 * 10**_decimals;

    uint256 public _maxWalletToken = _totalSupply;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) public isBlacklisted;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTimelockExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) public isMarketMaker;

    uint256 public buyTax = 1000;
    uint256 public sellTax = 1600;
    uint256 public transferTax = 0;

    uint256 public rewardShare = 500;
    uint256 public buyBackShare = 100;
    uint256 public teamShare = 100;
    uint256 public liquidityShare = 100;
    uint256 public marketingShare = 100;
    uint256 public burnShare = 100;
    uint256 totalShares = 1000;
    uint256 public feeDenominator  = 10000;

    uint256 public inCreaseFactor = 1;
    bool inCreaseFactorEnabled=false;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public teamFeeReceiver;
    address public burnFeeReceiver;
    address public buyBackFeeReceiver;

    IDEXRouter public router;
    address public pair;

    bool public tradingEnabled = false;

    DividendDistributor public distributor;
    uint256 transferGas = 500000;

    bool public buyCooldownEnabled = false;
    uint8 public cooldownTimerInterval = 60;
    mapping (address => uint) private cooldownTimer;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 10 / 10000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    event EnableTrading(bool isEnabled);

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(0);

        distributor = new DividendDistributor(address(router),WBNB);

        isFeeExempt[msg.sender] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isFeeExempt[teamFeeReceiver] = true;
        isFeeExempt[autoLiquidityReceiver] = true;
        isFeeExempt[teamFeeReceiver] = true;
        isFeeExempt[buyBackFeeReceiver] = true;

        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = 0x59a395CAAA08847a8631ECe8b6e2C0756a2a4199;
        teamFeeReceiver = 0x59a395CAAA08847a8631ECe8b6e2C0756a2a4199;
        buyBackFeeReceiver = 0x59a395CAAA08847a8631ECe8b6e2C0756a2a4199;
        burnFeeReceiver = DEAD;
        isMarketMaker[pair] = true;

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
        return approve(spender, uint256(0));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(0)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function setMaxWalletPercent_base1000(uint256 maxWallPercent_base1000) external onlyOwner() {
        _maxWalletToken = (_totalSupply * maxWallPercent_base1000 ) / 1000;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(!isBlacklisted[sender] ,"Blacklisted");    
        if (!authorizations[sender] || !authorizations[recipient]) { require(tradingEnabled, "Trading is disabled"); }

        if(inSwap || amount==0 ){ return _basicTransfer(sender, recipient, amount); }


        if (!authorizations[sender] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != marketingFeeReceiver && recipient != teamFeeReceiver  && recipient != autoLiquidityReceiver && recipient != burnFeeReceiver){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
            }
        
        if (sender == pair &&
            buyCooldownEnabled &&
            !isTimelockExempt[recipient]) {
            require(cooldownTimer[recipient] < block.timestamp,"Please wait for 1min between two buys");
            cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
        }

        if(shouldSwapBack(recipient)){ swapBack(); }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = (!shouldTakeFee(sender) || !shouldTakeFee(recipient)) ? amount : takeFee(sender,recipient, amount);
        _balances[recipient] = _balances[recipient].add(amountReceived);

        // Dividend tracker
        if(!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {} 
        }
        if (shouldProcessDividends(sender)) { 
        try distributor.process(transferGas) {} catch {}
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function shouldProcessDividends(address sender) private view returns (bool) {
        return !isFeeExempt[sender];
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }


    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender,address recipient, uint256 amount) private returns (uint256) {
        uint256 feeAmount = amount.mul(_getTotalTax(sender,recipient)).div(feeDenominator);
        uint256 burnTokens = feeAmount.mul(burnShare).div(_getTotalTax(sender,recipient));
        uint256 contractTokens = feeAmount.sub(burnTokens);

        _balances[address(this)] = _balances[address(this)].add(contractTokens);
        _balances[burnFeeReceiver] = _balances[burnFeeReceiver].add(burnTokens);
        emit Transfer(sender, address(this), contractTokens);
        
        if(burnTokens > 0){
            emit Transfer(sender, burnFeeReceiver, burnTokens);    
        }

        return amount.sub(feeAmount);
    }

    function _getTotalTax(address sender, address recipient) private view returns (uint256) {
        if (isMarketMaker[sender]) {
            return buyTax;
        } else if (isMarketMaker[recipient]) {
            return inCreaseFactorEnabled ? sellTax * inCreaseFactor : sellTax;
        } else {
            return transferTax;
        }
    }

    function shouldSwapBack(address recipient) internal view returns (bool) {
        return msg.sender != pair
        && isMarketMaker[recipient]
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function clearStuckBalance(uint256 amountPercentage) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(marketingFeeReceiver).transfer(amountBNB * amountPercentage / 100);
    }

    function clearStuckBalance_sender(uint256 amountPercentage) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(msg.sender).transfer(amountBNB * amountPercentage / 100);
    }


    // enable cooldown between trades
    function cooldownEnabled(bool status, uint8 timerInterval) public onlyOwner {
        buyCooldownEnabled = status;
        cooldownTimerInterval = timerInterval;
    }

    // new dividend tracker, clear balance
    function purgeBeforeSwitch() public onlyOwner {
        distributor.purge(msg.sender);
    }

    // new dividend tracker
    function switchToken(address rewardToken) public onlyOwner {
        distributor = new DividendDistributor(address(router), rewardToken);
    }     

    // manual claim for the greedy humans
    function claimRewards() public {
        distributor.claimDividend();
        try distributor.process(transferGas) {} catch {}
    }

    // manually clear the queue
    function claimProcess() public {
        try distributor.process(transferGas) {} catch {}
    }

     function enableTrading(bool isEnabled) external onlyOwner {
        tradingEnabled = isEnabled;
        emit EnableTrading(isEnabled);
    }


    function swapBack() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 liquidityTokens = swapThreshold.mul(liquidityShare).div(totalShares).div(2);
        uint256 amountToSwap = swapThreshold.sub(liquidityTokens);
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        uint256 totalBNBShares = totalShares.sub(liquidityShare).div(2);

        uint256 amountBNBLiquidity = amountBNB.mul(liquidityShare).div(totalBNBShares).div(2);
        uint256 amountBNBReflection = amountBNB.mul(rewardShare).div(totalBNBShares);
        uint256 amountBNBMarketing = amountBNB.mul(marketingShare).div(totalBNBShares);
        uint256 amountBNBTeam = amountBNB.mul(teamShare).div(totalBNBShares);
        uint256 amountBNBBuyBack = amountBNB.mul(buyBackShare).div(totalBNBShares);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: transferGas}("");
        (tmpSuccess,) = payable(teamFeeReceiver).call{value: amountBNBTeam, gas: transferGas}("");
        (tmpSuccess,) = payable(buyBackFeeReceiver).call{value: amountBNBBuyBack, gas: transferGas}("");
        
        // only to supress warning msg
        tmpSuccess = false;

        if(liquidityTokens > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                liquidityTokens,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, liquidityTokens);
        }
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

    function manage_blacklist(address[] calldata addresses, bool status) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            isBlacklisted[addresses[i]] = status;
        }
    }


    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTimelockExempt(address holder, bool exempt) external authorized {
        isTimelockExempt[holder] = exempt;
    }

      function setTaxShares(
        uint256 newRewardShare,
        uint256 newbuyBackShare,
        uint256 newTeamShare,
        uint256 newLiquidityShare,
        uint256 newMarketingShare
    ) external onlyOwner {
        rewardShare = newRewardShare;
        buyBackShare = newbuyBackShare;
        teamShare = newTeamShare;
        liquidityShare = newLiquidityShare;
        marketingShare = newMarketingShare;
        totalShares = rewardShare.add(buyBackShare).add(teamShare).add(liquidityShare).add(marketingShare);
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _teamFeeReceiver, address _burnFeeReceiver, address _buyBackFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        teamFeeReceiver = _teamFeeReceiver;
        burnFeeReceiver = _burnFeeReceiver;
        buyBackFeeReceiver = _buyBackFeeReceiver;

        isFeeExempt[autoLiquidityReceiver] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isFeeExempt[teamFeeReceiver] = true;
        isFeeExempt[burnFeeReceiver] = true;
        isFeeExempt[buyBackFeeReceiver] = true;

        isTimelockExempt[autoLiquidityReceiver] = true;
        isTimelockExempt[marketingFeeReceiver] = true;
        isTimelockExempt[teamFeeReceiver] = true;
        isTimelockExempt[burnFeeReceiver] = true;
        isTimelockExempt[buyBackFeeReceiver] = true;

    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }


    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setTransferGasLimit(uint256 gas) external authorized {
        transferGas = gas;
    }

    function setGasLimit(uint256 newGasLimit) external onlyOwner {
        distributor.setGasLimit(newGasLimit);
    }

    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function updateRouter(address newAddress) public onlyOwner {
    require(newAddress != address(router),"The router already");
    router = IDEXRouter(newAddress);
    address _pair = IDEXFactory(router.factory()).createPair(address(this),router.WETH());
    pair = _pair;
    isMarketMaker[pair] = true;
   }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
    for(uint256 i = 0; i < accounts.length; i++) {
        isFeeExempt[accounts[i]] = excluded;
      }
    }

    function multiTransfer(address from, address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {

    require(addresses.length < 501,"GAS Error: max airdrop limit is 500 addresses");
    require(addresses.length == tokens.length,"Mismatch between Address and token count");

    uint256 SCCC = 0;

    for(uint i=0; i < addresses.length; i++){
        SCCC = SCCC + tokens[i];
    }

    require(balanceOf(from) >= SCCC, "Not enough tokens in wallet");

    for(uint i=0; i < addresses.length; i++){
        _basicTransfer(from,addresses[i],tokens[i]);
        if(!isDividendExempt[addresses[i]]) {
            try distributor.setShare(addresses[i], _balances[addresses[i]]) {} catch {} 
        }
    }

    // Dividend tracker
    if(!isDividendExempt[from]) {
        try distributor.setShare(from, _balances[from]) {} catch {}
    }
}

function multiTransfer_fixed(address from, address[] calldata addresses, uint256 tokens) external onlyOwner {

    require(addresses.length < 801,"GAS Error: max airdrop limit is 800 addresses");

    uint256 SCCC = tokens * addresses.length;

    require(balanceOf(from) >= SCCC, "Not enough tokens in wallet");

    for(uint i=0; i < addresses.length; i++){
        _basicTransfer(from,addresses[i],tokens);
        if(!isDividendExempt[addresses[i]]) {
            try distributor.setShare(addresses[i], _balances[addresses[i]]) {} catch {} 
        }
    }

    // Dividend tracker
    if(!isDividendExempt[from]) {
        try distributor.setShare(from, _balances[from]) {} catch {}
    }
}

event AutoLiquify(uint256 amountBNB, uint256 amountBOG);

}