// Light Lemon Unicorn Contract
// The magical token!
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./INFT.sol";
import "./IDEX.sol";
import "./IBEP20.sol";
import "./DividendDistributor.sol";

contract LightLemonUnicorn is IBEP20 {
    enum TxType {
        BUY,
        SELL,
        TRANSFER
    }

    // Determined Tax Integer Transaction
    struct DTITx {
        uint256 amount;
        TxType txType;
    }

    INFT public nft;
    address immutable owner;
    address public launchpad;
    address public constant MARKETING = 0x7aD1218F29F20a32948aFdccb8e9099d2946e91f;

    int256[] public buyTaxDTIs = [int256(-1000000), 1123596, 2247191, 3370787, 4494382, 6741573, 7865169, 8988764, 10112360, 11235955, 12359551, 13483146, 14606742, 15730337, 40000000];
    uint256[] public buyTaxValues = [0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500];
 
    int256[] public sellTaxDTIs = [int256(-3000000), -2497143, -1912821, -1406637, -912763, -526852, -274328, 26, 711487, 1599122, 3401769, 6109621, 8967018, 13077371, 26112441];
    uint256[] public sellTaxValues = [9000, 8100, 7100, 6100, 5700, 5300, 5100, 4800, 4400, 3900, 3400, 2500, 1900, 1300, 600, 0];

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    uint16 constant FEE_DENOMINATOR = 10000;

    bool public tradingEnabled;
    bool public maxTaxEnabled = true;
    bool public swapEnabled = true;
    bool inSwap;
    bool inBuyback;

    uint8 dtiIndex;
    uint8 constant DECIMALS = 18;
    uint256 constant TOTAL_SUPPLY = 387131517 * 10**DECIMALS;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isWhitelisted;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) public isAutomatedMarketMaker;

    uint256 public maxBuyLimit = 4000000 * 10**DECIMALS;
    uint256 public maxSellLimit = 200000 * 10**DECIMALS;
    uint256 public rewardStorage;

    uint256 public rewardShare = 400;
    uint256 public marketingShare = 300;
    uint256 public buybackShare = 9300;
    uint256 public totalShares = 10000;
    
    DTITx[25] public dtiTransactions;
    DividendDistributor public immutable distributor;
    IDexRouter public constant ROUTER = IDexRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public immutable pair;

    modifier swapping() { 
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier burning() {
        inBuyback = true;
        _;
        inBuyback = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor () {
        owner = msg.sender;
        
        pair = IDexFactory(ROUTER.factory()).createPair(BUSD, address(this));
        _allowances[address(this)][address(ROUTER)] = type(uint256).max;
        isAutomatedMarketMaker[pair] = true;

        distributor = new DividendDistributor();
        excludeAccounts();

        _balances[owner] = TOTAL_SUPPLY;
        emit Transfer(address(0), owner, TOTAL_SUPPLY);
    }

    // IBEP20

    function totalSupply() external pure override returns (uint256) { return TOTAL_SUPPLY; }
    function decimals() external pure override returns (uint8) { return DECIMALS; }
    function symbol() external pure override returns (string memory) { return "LLU"; }
    function name() external pure override returns (string memory) { return "Light Lemon Unicorn"; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address _owner, address spender) external view override returns (uint256) { return _allowances[_owner][spender]; }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transferFrom(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    // IBEP20 Helpers

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    // Public

    receive() external payable {}

    // Private

    function _approve(address _owner, address spender, uint256 amount) private {
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) private returns (bool) {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        if (inSwap || isWhitelisted[sender]) { return _basicTransfer(sender, recipient, amount); }
        
        DTITx memory dtiTx;
        if (inBuyback) {
            dtiTx = DTITx(amount, TxType.BUY);
            updateDTITransactions(dtiTx);
            return _basicTransfer(sender, recipient, amount);
        }

        require(tradingEnabled, "Trading is disabled");

        TxType txType = TxType.TRANSFER;
        if (isAutomatedMarketMaker[sender]) {
            if (!isTxLimitExempt[recipient]) { require(_balances[recipient] + amount <= maxBuyLimit, "Max buy limit"); }
            txType = TxType.BUY;
        }
        if (isAutomatedMarketMaker[recipient]) {
            if (!isTxLimitExempt[sender]) { require(amount <= maxSellLimit, "Max sell limit"); }
            txType = TxType.SELL;
        }

        dtiTx = DTITx(amount, txType);
        updateDTITransactions(dtiTx);
        if (shouldSwapBack(recipient)) { swapBack(); }

        _balances[sender] = senderBalance - amount;
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, dtiTx) : amount;
        _balances[recipient] += amountReceived;

        if (!isDividendExempt[sender]) { try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if (!isDividendExempt[recipient]) { try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process() {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) private returns (bool) {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function updateDTITransactions(DTITx memory dtiTx) private {
        dtiTransactions[dtiIndex] = dtiTx;
        dtiIndex++;
        if (dtiIndex > 24) { dtiIndex = 0; }
    }

    function shouldTakeFee(address sender, address recipient) private view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function takeFee(address sender, DTITx memory dtiTx) private returns (uint256) {
        uint256 tax;
        uint256 discountMultiplier;

        if (dtiTx.txType == TxType.BUY) {
            tax = getBuyTax();
        } else if (dtiTx.txType == TxType.TRANSFER) {
            tax = 1500;
        } else {
            tax = getSellTax();
            discountMultiplier = getDiscountMultiplier(sender);
        }

        if (maxTaxEnabled) { tax = FEE_DENOMINATOR - 100; }

        uint256 discountedFee = tax - tax * discountMultiplier / FEE_DENOMINATOR;
        uint256 feeAmount = dtiTx.amount * discountedFee / FEE_DENOMINATOR;

        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return dtiTx.amount - feeAmount;
    }

    function getBuyDTIValue() public view returns (int256) {
        int256 dtiValue;

        for (uint256 i; i < dtiTransactions.length; i++) {
            DTITx memory dtiTx = dtiTransactions[i];
            if (dtiTx.txType == TxType.BUY) {
                dtiValue += int256(dtiTx.amount / 10**DECIMALS);
            } else if (dtiTx.txType == TxType.SELL) {
                dtiValue -= int256(dtiTx.amount / 10**DECIMALS);
            }
        }

        return dtiValue;
    }

    function getSellDTIValue() public view returns (int256) {
        int256 dtiValue;

        for (uint256 i; i < dtiTransactions.length; i++) {
            DTITx memory dtiTx = dtiTransactions[i];
            if (dtiTx.txType == TxType.BUY) {
                dtiValue += int256(dtiTx.amount / 10**DECIMALS);
            } else if (dtiTx.txType == TxType.SELL) {
                dtiValue -= int256(dtiTx.amount / 10**DECIMALS);
            }
        }

        return dtiValue;
    }

    function getBuyTax() public view returns (uint256) {
        int256 dtiValue = getBuyDTIValue();
        return buyTaxFromDTI(dtiValue);
    }

    function getSellTax() public view returns (uint256) {
        int256 dtiValue = getSellDTIValue();
        return sellTaxFromDTI(dtiValue);
    }

    function buyTaxFromDTI(int256 dtiValue) private view returns (uint256) {
        uint256 currentIndex;
        for (uint256 i; i < buyTaxDTIs.length; i++) {
            if (dtiValue < buyTaxDTIs[i]) {
                return buyTaxValues[currentIndex];
            } else {
                currentIndex++;
            }
        }
        return buyTaxValues[buyTaxValues.length - 1];
    }

    function sellTaxFromDTI(int256 dtiValue) private view returns (uint256) {
        uint256 currentIndex;
        for (uint256 i; i < sellTaxDTIs.length; i++) {
            if (dtiValue < sellTaxDTIs[i]) {
                return sellTaxValues[currentIndex];
            } else {
                currentIndex++;
            }
        }
        return sellTaxValues[sellTaxValues.length - 1];
    }

    function getDiscountMultiplier(address account) private view returns (uint256) {
        uint256 nftDiscountMultiplier;
        if (address(nft) != address(0)) { nftDiscount(account); }
        uint256 secretDiscountMultiplier = secretDiscount(account);

        if (nftDiscountMultiplier >= secretDiscountMultiplier) {
            return nftDiscountMultiplier;
        } else {
            return secretDiscountMultiplier;
        }
    }

    function secretDiscount(address account) private view returns (uint256) {
        IBEP20 secret = IBEP20(0xed763F7fa6eB3800FE87cC31Ac5B03DCeC03A8c9);

        try secret.balanceOf(account) returns (uint256 balance) {
            if (balance >= 5 * 10**6 * 10**8) { return 600; }
        } catch {
            return 0;
        }

        return 0;
    }

    function nftDiscount(address account) private view returns (uint256) {
        try nft.taxDiscount(account) returns (uint256 discountMultiplier) {
            return discountMultiplier > FEE_DENOMINATOR ? FEE_DENOMINATOR : discountMultiplier;
        } catch {
            return 0;
        }
    }

    function shouldSwapBack(address recipient) private view returns (bool) {
        return isAutomatedMarketMaker[recipient]
        && !inSwap
        && swapEnabled
        && _balances[address(this)] > 0;
    }

    function swapBack() private swapping {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = BUSD;
        path[2] = ROUTER.WETH();

        uint256 taxedTokens = _balances[address(this)] - rewardStorage;
        uint256 rewardFee = taxedTokens * rewardShare / totalShares;
        rewardStorage += rewardFee;

        uint256 tokensToSell = taxedTokens - rewardFee;

        if (tokensToSell > 0) {
            uint256 balanceBefore = address(this).balance;

            ROUTER.swapExactTokensForETH(
                tokensToSell,
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 amountBNB = address(this).balance - balanceBefore;
            uint256 marketingBNB = amountBNB * marketingShare / totalShares;

            payable(MARKETING).call{value: marketingBNB, gas: 30000}("");
        }
    }

    function buyback(uint256 amount) private burning {
        address[] memory path = new address[](3);
        path[0] = ROUTER.WETH();
        path[1] = BUSD;
        path[2] = address(this);

        ROUTER.swapExactETHForTokens{value: amount}(
            0,
            path,
            DEAD,
            block.timestamp
        );
    }

    function excludeAccounts() private {
        isWhitelisted[owner] = true;
        isFeeExempt[owner] = true;
        isDividendExempt[owner] = true;
        isTxLimitExempt[owner] = true;

        isFeeExempt[address(this)] = true;
        isDividendExempt[address(this)] = true;
        isTxLimitExempt[address(this)] = true;

        isFeeExempt[address(distributor)] = true;
        isDividendExempt[address(distributor)] = true;
        isTxLimitExempt[address(distributor)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;
    }

    // Owner

    function setAutomatedMarketMaker(address amm, bool exempt) external onlyOwner {
        require(amm != pair);
        isAutomatedMarketMaker[amm] = exempt;
    }

    function setIsDividendExempt(address account, bool exempt) external onlyOwner {
        require(account != address(this) && account != pair && account != DEAD && account != ZERO);

        isDividendExempt[account] = exempt;
        if(exempt){
            distributor.setShare(account, 0);
        }else{
            distributor.setShare(account, _balances[account]);
        }
    }

    function setIsFeeExempt(address account, bool exempt) external onlyOwner {
        require(account != address(this));
        isFeeExempt[account] = exempt;
    }

    function setIsTxLimitExempt(address account, bool exempt) external onlyOwner {
        require(account != address(this));
        isTxLimitExempt[account] = exempt;
    }

    function setMaxBuyLimit(uint256 amount) external onlyOwner {
        require(amount >= 2000000);

        uint256 tokenAmount = amount * 10**DECIMALS;
        maxBuyLimit = tokenAmount;
    }

    function setMaxSellLimit(uint256 amount) external onlyOwner {
        require(amount >= 100000);

        uint256 tokenAmount = amount * 10**DECIMALS;
        maxSellLimit = tokenAmount;
    }

    function setTaxDistribution(uint256 _rewards, uint256 _marketing, uint256 _buyback) external onlyOwner {
        rewardShare = _rewards;
        marketingShare = _marketing;
        buybackShare = _buyback;
        totalShares = rewardShare + marketingShare + buybackShare;
    }

    function setBuyTaxes(int256[] calldata thresholds, uint256[] calldata values) external onlyOwner {
        require(thresholds.length <= 20);
        require(values.length - 1 == thresholds.length);

        buyTaxDTIs = thresholds;
        buyTaxValues = values;
    }
    
    function setSellTaxes(int256[] calldata thresholds, uint256[] calldata values) external onlyOwner {
        require(thresholds.length <= 20);
        require(values.length - 1 == thresholds.length);

        sellTaxDTIs = thresholds;
        sellTaxValues = values;
    }

    function setSwapBackSetting(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function triggerBuyback(uint256 amount) external onlyOwner {
        buyback(amount);
    }

    function triggerSwapBack() external onlyOwner {
        swapBack();
    }

    function updateNFT(address newNFT) external onlyOwner {
        nft = INFT(newNFT);
        nft.taxDiscount(msg.sender);
    }

    function depositRewards(uint256 amount) external onlyOwner {
        require(rewardStorage >= amount);

        rewardStorage -= amount;
        _basicTransfer(address(this), address(distributor), amount);
        distributor.deposit(amount);
    }

    function initLaunchpad(address newPad) external onlyOwner {
        require(launchpad == ZERO, "Launchpad initialised");
        launchpad = newPad;
        isWhitelisted[launchpad] = true;
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }

    function disableMaxTax() external onlyOwner {
        maxTaxEnabled = false;
    }

    // Distributor

    function setGasLimit(uint256 gas) external onlyOwner {
        require(gas <= 750000 && gas >= 100000);
        distributor.setGasLimit(gas);
    }

    function setDistributionCriteria(uint256 minPeriod) external onlyOwner {
        require(minPeriod <= 1 days);
        distributor.setDistributionCriteria(minPeriod);
    }

    function getUnpaidEarnings(address shareholder) external view returns (uint256) {
        return distributor.getUnpaidEarnings(shareholder);
    }

    function claim() external {
        distributor.claimDividend(msg.sender);
    }
}