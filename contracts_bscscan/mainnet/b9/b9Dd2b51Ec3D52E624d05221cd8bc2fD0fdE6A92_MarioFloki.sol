// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./BEP20.sol";
import "./DividendDistributor.sol";

contract MarioFloki is BEP20 {
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    IDEXRouter public constant ROUTER = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public immutable pair;

    address public marketingWallet = 0x9685842D043E711C0384e11F7E318fcE5E04eF2A;
    address public charityWallet = 0x20f6Ccd6e4F915ED1a4a18d120BaC33742384F9A;

    uint256 public swapThreshold = 100000000 * 10**18;
    bool public swapEnabled = true;
    bool presaleInitialized;
    bool tradingEnabled;
    bool inSwap;

    mapping (address => bool) public isWhitelisted;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) public isMarketMaker;
    mapping (address => bool) public isCEX;

    uint256 public buyTax = 1100;
    uint256 public sellTax = 1600;
    uint256 public transferTax = 0;

    uint256 public rewardShare = 500;
    uint256 public charityShare = 50;
    uint256 public liquidityShare = 150;
    uint256 public marketingShare = 300;
    uint256 totalShares = 1000;
    uint256 constant DENOMINATOR = 10000;

    DividendDistributor public immutable distributor;
    uint256 public minBalanceForDividends = 100000000 * 10**18;
    uint256 public transferGas = 25000;

    event PreparePresale(address presale);
    event RecoverBNB(uint256 amount);
    event RecoverBEP20(address token, uint256 amount);
    event EnableTrading();
    event SetMarketingWallet(address newWallet, address oldWallet);
    event SetCharityWallet(address newWallet, address oldWallet);
    event SetTransferGas(uint256 newGas, uint256 oldGas);
    event SetWhitelisted(address account, bool value);
    event SetCEX(address account, bool value);
    event SetMarketMaker(address account, bool value);
    event SetDividendExempt(address account, bool exempt);
    event SetMinBalanceForDividends(uint256 amount);
    event SetSwapBackSettings(bool enabled, uint256 amount);
    event TriggerSwapBack();
    event SetTaxes(uint256 buyTax, uint256 sellTax, uint256 transferTax);
    event SetTaxShares(uint256 rewardShare, uint256 charityShare, uint256 liquidityShare, uint256 marketingShare);
    event DepositMarketing(address wallet, uint256 amount);
    event DepositCharity(address wallet, uint256 amount);
    event AutoLiquidity(uint256 pairAmount, uint256 tokenAmount);

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() BEP20(marketingWallet) {
        pair = IDEXFactory(ROUTER.factory()).createPair(ROUTER.WETH(), address(this));
        _approve(address(this), address(ROUTER), type(uint256).max);
        isMarketMaker[pair] = true;

        distributor = new DividendDistributor();
        _excludeAccounts();
    }

    // Public

    receive() external payable {}

    function getCirculatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(DEAD);
    }

    // Private

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (!isWhitelisted[sender]) { require(tradingEnabled, "Trading is disabled"); }

        if (inSwap || amount == 0) {
            super._transfer(sender, recipient, amount);
            return;
        }

        if (_shouldSwapBack(recipient)) { _swapBack(); }
        uint256 amountAfterTaxes = _shouldTakeTaxes(sender) ? _takeTax(sender, recipient, amount) : amount;
        super._transfer(sender, recipient, amountAfterTaxes);

        if (_shouldSetShares(sender)) { try distributor.setShare(sender, balanceOf(sender)) {} catch {} }
        if (_shouldSetShares(recipient)) { try distributor.setShare(recipient, balanceOf(recipient)) {} catch {} }
        if (_shouldProcessDividends(sender, recipient)) { try distributor.process() {} catch {} }
    }

    function _shouldSwapBack(address recipient) private view returns (bool) {
        return isMarketMaker[recipient] && swapEnabled && balanceOf(address(this)) >= swapThreshold;
    }

    function _shouldTakeTaxes(address sender) private view returns (bool) {
        return !isWhitelisted[sender];
    }

    function _shouldSetShares(address account) private view returns (bool) {
        return !isDividendExempt[account] && balanceOf(account) >= minBalanceForDividends;
    }

    function _shouldProcessDividends(address sender, address recipient) private view returns (bool) {
        return !isWhitelisted[sender] && !isCEX[sender] && !isCEX[recipient];
    }

    function _swapBack() private swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = ROUTER.WETH();

        uint256 liquidityTokens = swapThreshold * liquidityShare / totalShares / 2;
        uint256 amountToSwap = swapThreshold - liquidityTokens;
        uint256 balanceBefore = address(this).balance;

        ROUTER.swapExactTokensForETH(
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
        uint256 amountBNBCharity = amountBNB * charityShare / totalBNBShares;
        uint256 amountBNBRewards = amountBNB * rewardShare / totalBNBShares;

        try distributor.deposit{value: amountBNBRewards}() {} catch {}
        (bool marketingSuccess,) = payable(marketingWallet).call{value: amountBNBMarketing, gas: transferGas}("");
        if (marketingSuccess) { emit DepositMarketing(marketingWallet, amountBNBMarketing); }
        (bool charitySuccess,) = payable(charityWallet).call{value: amountBNBCharity, gas: transferGas}("");
        if (charitySuccess) { emit DepositCharity(charityWallet, amountBNBCharity); }

        if (liquidityTokens > 0) {
            ROUTER.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                liquidityTokens,
                0,
                0,
                address(this),
                block.timestamp
            );

            emit AutoLiquidity(amountBNBLiquidity, liquidityTokens);
        }
    }

    function _takeTax(address sender, address recipient, uint256 amount) private returns (uint256) {
        uint256 taxAmount = amount * _getTotalTax(sender, recipient) / DENOMINATOR;
        if (taxAmount > 0) { super._transfer(sender, address(this), taxAmount); }
        return amount - taxAmount;
    }

    function _getTotalTax(address sender, address recipient) private view returns (uint256) {
        if (isCEX[recipient]) { return 0; }
        if (isCEX[sender]) { return buyTax; }

        if (isMarketMaker[sender]) {
            return buyTax;
        } else if (isMarketMaker[recipient]) {
            return sellTax;
        } else {
            return transferTax;
        }
    }

    function _excludeAccounts() private {
        isWhitelisted[marketingWallet] = true;
        isDividendExempt[marketingWallet] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[DEAD] = true;
    }

    // Maintenance

    function preparePresale(address presale) external onlyOwner {
        require(!presaleInitialized, "Presale is already initialized");
        isWhitelisted[presale] = true;
        isDividendExempt[presale] = true;
        distributor.setShare(presale, 0);
        presaleInitialized = true;
        emit PreparePresale(presale);
    }

    function recoverBNB() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent,) = payable(marketingWallet).call{value: amount, gas: transferGas}("");
        require(sent, "Tx failed");
        emit RecoverBNB(amount);
    }

    function recoverBEP20(IBEP20 token, address recipient) external onlyOwner {
        require(address(token) != address(this), "Can't withdraw MRFLOKI");
        uint256 amount = token.balanceOf(address(this));
        token.transfer(recipient, amount);
        emit RecoverBEP20(address(token), amount);
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
        emit EnableTrading();
    }

    function setMarketingWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "New marketing wallet is the zero address");
        isWhitelisted[marketingWallet] = false;
        isDividendExempt[marketingWallet] = false;
        isDividendExempt[newWallet] = true;
        emit SetMarketingWallet(newWallet, marketingWallet);
        marketingWallet = newWallet;
    }

    function setCharityWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "New charity wallet is the zero address");
        emit SetCharityWallet(newWallet, charityWallet);
        charityWallet = newWallet;
    }

    function setTransferGas(uint256 gas) external onlyOwner {
        require(gas >= 21000 && gas <= 50000, "Invalid parameter");
        emit SetTransferGas(gas, transferGas);
        transferGas = gas;
    }

    function setIsWhitelisted(address account, bool value) external onlyOwner {
        require(account != pair, "Can't modify pair");
        isWhitelisted[account] = value;
        emit SetWhitelisted(account, value);
    }

    function setIsCEX(address account, bool value) external onlyOwner {
        require(account != pair, "Can't modify pair");
        isCEX[account] = value;
        emit SetCEX(account, value);
    }

    function setIsMarketMaker(address account, bool value) external onlyOwner {
        require(account != pair, "Can't modify pair");
        isMarketMaker[account] = value;
        emit SetMarketMaker(account, value);
    }

    function setIsDividendExempt(address account, bool exempt) external onlyOwner {
        require(account != address(this) && account != pair && account != marketingWallet, "Invalid account");

        isDividendExempt[account] = exempt;
        if (exempt) {
            distributor.setShare(account, 0);
        } else {
            distributor.setShare(account, balanceOf(account));
        }

        emit SetDividendExempt(account, exempt);
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

    function setTaxes(uint256 newBuyTax, uint256 newSellTax, uint256 newTransferTax) external onlyOwner {
        require(newBuyTax <= 3000 && newSellTax <= 3500 && newTransferTax <= 1500, "Too high taxes");
        buyTax = newBuyTax;
        sellTax = newSellTax;
        transferTax = newTransferTax;
        emit SetTaxes(buyTax, sellTax, transferTax);
    }

    function setTaxShares(
        uint256 newRewardShare,
        uint256 newCharityShare,
        uint256 newLiquidityShare,
        uint256 newMarketingShare
    ) external onlyOwner {
        rewardShare = newRewardShare;
        charityShare = newCharityShare;
        liquidityShare = newLiquidityShare;
        marketingShare = newMarketingShare;
        totalShares = rewardShare + charityShare + liquidityShare + marketingShare;
        emit SetTaxShares(rewardShare, charityShare, liquidityShare, marketingShare);
    }

    function setDistributionCriteria(uint256 newPeriod, uint256 newMinDistribution) external onlyOwner {
        distributor.setDistributionCriteria(newPeriod, newMinDistribution);
    }

    function setGasLimit(uint256 newGasLimit) external onlyOwner {
        distributor.setGasLimit(newGasLimit);
    }
}