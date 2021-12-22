// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./BEP20.sol";
import "./IDEX.sol";

contract CheemsCat is BEP20 {
    IDEXRouter public constant ROUTER = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public immutable pair;

    address public marketingWallet = 0xEC40191F543137a5273417cb2aC191BD88c78205;
    address public constant BURNER = 0xD58Ca643223E93FDa3390D2dd22ab14A3AD51587;

    uint256 public swapThreshold;
    bool public swapEnabled;
    bool inSwap;

    uint256 public maxBalance = 5 * 10**9 * 10**18;

    mapping (address => bool) public isLimitExempt;
    mapping (address => bool) public isTaxExempt;
    mapping (address => bool) public isMarketMaker;
    mapping (address => bool) public isCEX;

    uint256 public buyTax = 900;
    uint256 public sellTax = 3600;
    uint256 public transferTax = 900;

    uint256 public buybackShare = 500;
    uint256 public liquidityShare = 300;
    uint256 public marketingShare = 200;
    uint256 totalShares = 1000;
    uint256 constant DENOMINATOR = 10000;

    uint256 public transferGas = 25000;

    event RecoverBEP20(address token, uint256 amount);
    event SetTransferGas(uint256 gas, uint256 transferGas);
    event SetMarketingWallet(address newWallet, address marketingWallet);
    event SetLimitExempt(address account, bool value);
    event SetTaxExempt(address account, bool value);
    event SetCEX(address account, bool value);
    event SetMarketMaker(address account, bool value);
    event SetSwapBackSettings(bool enabled, uint256 tokenAmount);
    event TriggerSwapBack();
    event TriggerBuyback(uint256 amount);
    event Burn(uint256 amount);
    event SetMaxBalance(uint256 amount);
    event SetTaxes(uint256 buyTax, uint256 sellTax, uint256 transferTax);
    event SetTaxShares(uint256 buybackShare, uint256 liquidityShare, uint256 marketingShare);
    event DepositMarketing(address marketingWallet, uint256 amountBNBMarketing);
    event AutoLiquidity(uint256 amountBNBLiquidity, uint256 liquidityTokens);

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        pair = IDEXFactory(ROUTER.factory()).createPair(ROUTER.WETH(), address(this));
        _approve(address(this), address(ROUTER), type(uint256).max);
        isMarketMaker[pair] = true;

        isTaxExempt[owner()] = true;
        isLimitExempt[owner()] = true;
        isLimitExempt[BURNER] = true;
        isLimitExempt[DEAD] = true;
        isLimitExempt[pair] = true;
        isLimitExempt[address(ROUTER)] = true;
    }

    receive() external payable {}

    // Private

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (inSwap || amount == 0) {
            super._transfer(sender, recipient, amount);
            return;
        }

        if (!isLimitExempt[recipient]) { require(balanceOf(recipient) + amount <= maxBalance, "Max balance limit"); }
        if (sender == BURNER) { require(recipient == DEAD, "Burn reserves can only burn tokens"); }
        if (_shouldSwapBack(recipient)) { _swapBack(); }

        uint256 amountAfterTaxes = _shouldTakeTaxes(sender, recipient) ? _takeTax(sender, recipient, amount) : amount;
        super._transfer(sender, recipient, amountAfterTaxes);
    }

    function _shouldSwapBack(address recipient) private view returns (bool) {
        return isMarketMaker[recipient] && swapEnabled && balanceOf(address(this)) >= swapThreshold;
    }

    function _shouldTakeTaxes(address sender, address recipient) private view returns (bool) {
        return !isTaxExempt[sender] && !isTaxExempt[recipient];
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

        (bool marketingSuccess,) = payable(marketingWallet).call{value: amountBNBMarketing, gas: transferGas}("");
        if (marketingSuccess) { emit DepositMarketing(marketingWallet, amountBNBMarketing); }

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

    function _buybackAndBurn(uint256 amount) private swapping {
        address[] memory path = new address[](2);
        path[0] = ROUTER.WETH();
        path[1] = address(this);

        ROUTER.swapExactETHForTokens{value: amount}(
            0,
            path,
            DEAD,
            block.timestamp
        );
    }

    // Maintenance

    function recoverBEP20(IBEP20 token, address recipient) external onlyOwner {
        require(address(token) != address(this) && address(token) != ROUTER.WETH(), "Invalid parameter");
        uint256 amount = token.balanceOf(address(this));
        token.transfer(recipient, amount);
        emit RecoverBEP20(address(token), amount);
    }

    function setTransferGas(uint256 gas) external onlyOwner {
        require(gas >= 21000 && gas <= 50000, "Invalid parameter");
        emit SetTransferGas(gas, transferGas);
        transferGas = gas;
    }

    function setMarketingWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "New wallet is the zero address");
        emit SetMarketingWallet(newWallet, marketingWallet);
        marketingWallet = newWallet;
    }

    function setIsLimitExempt(address account, bool value) external onlyOwner {
        require(account != pair, "Can't modify pair");
        isLimitExempt[account] = value;
        emit SetLimitExempt(account, value);
    }

    function setIsTaxExempt(address account, bool value) external onlyOwner {
        isTaxExempt[account] = value;
        emit SetTaxExempt(account, value);
    }

    function setIsCEX(address account, bool value) external onlyOwner {
        isCEX[account] = value;
        emit SetCEX(account, value);
    }

    function setIsMarketMaker(address account, bool value) external onlyOwner {
        require(account != pair, "Can't modify pair");
        isMarketMaker[account] = value;
        emit SetMarketMaker(account, value);
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

    function triggerBuyback(uint256 amount) external onlyOwner {
        _buybackAndBurn(amount);
        emit TriggerBuyback(amount);
    }

    function burn(uint256 amount) external onlyOwner {
        _burnReserves(BURNER, amount);
        emit Burn(amount);
    }

    function setMaxBalance(uint256 amount) external onlyOwner {
        require(amount >= 5 * 10**9 * 10**decimals(), "Max balance too low");
        maxBalance = amount;
        emit SetMaxBalance(amount);
    }

    function setTaxes(uint256 newBuyTax, uint256 newSellTax, uint256 newTransferTax) external onlyOwner {
        require(newBuyTax <= 1500 && newSellTax <= 4000 && newTransferTax <= 2000, "Tax limits exceeded");
        buyTax = newBuyTax;
        sellTax = newSellTax;
        transferTax = newTransferTax;
        emit SetTaxes(buyTax, sellTax, transferTax);
    }

    function setTaxShares(
        uint256 newBuybackShare,
        uint256 newLiquidityShare,
        uint256 newMarketingShare
    ) external onlyOwner {
        buybackShare = newBuybackShare;
        liquidityShare = newLiquidityShare;
        marketingShare = newMarketingShare;
        totalShares = buybackShare + liquidityShare + marketingShare;
        emit SetTaxShares(buybackShare, liquidityShare, marketingShare);
    }
}