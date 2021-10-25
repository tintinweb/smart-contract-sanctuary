// SPDX-License-Identifier: MIT

/**
 * .------..------..------..------..------..------.
 * |N.--. ||E.--. ||V.--. ||A.--. ||D.--. ||A.--. |
 * | :(): || (\/) || :(): || (\/) || :/\: || (\/) |
 * | ()() || :\/: || ()() || :\/: || (__) || :\/: |
 * | '--'N|| '--'E|| '--'V|| '--'A|| '--'D|| '--'A|
 * `------'`------'`------'`------'`------'`------'
 *
 * The first BSC token to feature a reward-based gambling platform.
 *
 * https://nevada.casino
 * https://t.me/NevADAtoken
 * https://twitter.com/NevADAbsc
 * https://www.reddit.com/r/NevADAtoken
 *
 * In memory of Selma
 */

pragma solidity ^0.8.0;

import "./IDex.sol";
import "./IBEP20.sol";
import "./ISelmaNFT.sol";

contract Nevada is IBEP20 {
    address constant OWNER = 0x9aAC06fEE3C393eA0AaC550eF99C42f3E93A768f;
    address constant LOTTERY_WALLET = 0x9aAC06fEE3C393eA0AaC550eF99C42f3E93A768f;
    address constant MARKETING_WALLET = 0x9aAC06fEE3C393eA0AaC550eF99C42f3E93A768f;
    address constant DEVELOPMENT_WALLET = 0x9aAC06fEE3C393eA0AaC550eF99C42f3E93A768f;
    address constant LOCKER = 0xB2c8faaBfC026af5f3C44f46B8454662d03eaDDD;
    ISelmaNFT public constant SELMA_NFT = ISelmaNFT(0x824Db8c2Cf7eC655De2A7825f8E9311c8e526523);

    bool public swapEnabled = true;
    bool public tradingEnabled;
    bool _sniperRekt = true;
    bool _inSwap;

    uint8 constant DECIMALS = 18;
    uint256 constant TOTAL_SUPPLY = 10**9 * 10**DECIMALS;
    uint256 public swapThreshold = 300000 * 10**DECIMALS;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isMarketMaker;

    uint256 public lotteryFee = 300;
    uint256 public liquidityFee = 200;
    uint256 public marketingFee = 200;
    uint256 public developmentFee = 200;
    uint256 _totalFee = 900;
    uint256 constant FEE_DENOMINATOR = 10000;

    uint256 public lotteryShare;
    uint256 public marketingShare;
    uint256 public developmentShare;
    uint256 public transferGas = 25000;

    IDexRouter public constant ROUTER = IDexRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public immutable pair;
    address public presale;

    event Launch(uint256 timestamp);
    event SetFeeExempt(address indexed account, bool indexed exempt);
    event SetMarketMaker(address indexed account, bool indexed isMM);
    event SetFees(uint256 lottery, uint256 liquidity, uint256 marketing, uint256 development);
    event SetSwapBackSettings(bool indexed enabled, uint256 amount);
    event UpdateTransferGas(uint256 gas);
    event TriggerSwapBack();
    event AutoLiquidity(uint256 pair, uint256 tokens);
    event Recover(uint256 amount);
    event ClaimLottery(uint256 amount);
    event ClaimMarketing(uint256 amount);
    event ClaimDevelopment(uint256 amount);
    event InitPresale(address presale);
    event EnableTrading();

    modifier swapping() { 
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier onlyOwner() {
        require(msg.sender == OWNER);
        _;
    }

    constructor () {
        pair = IDexFactory(ROUTER.factory()).createPair(ROUTER.WETH(), address(this));
        _allowances[address(this)][address(ROUTER)] = type(uint256).max;

        isMarketMaker[pair] = true;
        isFeeExempt[OWNER] = true;
        isFeeExempt[MARKETING_WALLET] = true;
        isFeeExempt[LOTTERY_WALLET] = true;
        isFeeExempt[DEVELOPMENT_WALLET] = true;
        isFeeExempt[address(this)] = true;

        _balances[MARKETING_WALLET] = TOTAL_SUPPLY;
        emit Transfer(address(0), MARKETING_WALLET, TOTAL_SUPPLY);
    }

    // IBEP20

    function totalSupply() external pure override returns (uint256) { return TOTAL_SUPPLY; }
    function decimals() external pure override returns (uint8) { return DECIMALS; }
    function symbol() external pure override returns (string memory) { return "NEVADA"; }
    function name() external pure override returns (string memory) { return "Nevada"; }
    function getOwner() external pure override returns (address) { return OWNER; }
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

    function getTotalFee() public view returns (uint256) {
        if(_sniperRekt){ return FEE_DENOMINATOR - 100; }
        return _totalFee;
    }

    // Private

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) private returns (bool) {
        if(isFeeExempt[sender] || isFeeExempt[recipient]){ return _basicTransfer(sender, recipient, amount); }
        require(tradingEnabled, "Trading disabled");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");
        
        if(shouldSwapBack(recipient)){ swapBack(); }

        _balances[sender] = senderBalance - amount;
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] += amountReceived;

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

    function shouldTakeFee(address sender, address recipient) private view returns (bool) {
        bool isSell = isMarketMaker[recipient];
        bool isBuy = isMarketMaker[sender];
        return isBuy || isSell;
    }

    function takeFee(address sender, address recipient, uint256 amount) private returns (uint256) {
        bool isBuy = isMarketMaker[sender];
        address initiator = isBuy ? recipient : sender;
        uint256 discountMultiplier = selmaTaxDiscount(initiator);

        uint256 discountedFee = getTotalFee() - getTotalFee() * discountMultiplier / FEE_DENOMINATOR;
        uint256 feeAmount = amount * discountedFee / FEE_DENOMINATOR;

        if (feeAmount > 0) {
            _balances[address(this)] += feeAmount;
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount - feeAmount;
    }

    function selmaTaxDiscount(address account) private view returns (uint256) {
        uint256 discountMultiplier;

        try SELMA_NFT.balanceOf(account, 1) returns (uint256 platinumBalance) {
            if (platinumBalance > 0) { discountMultiplier = 5000; }
        } catch {}

        try SELMA_NFT.balanceOf(account, 2) returns (uint256 diamondBalance) {
            if (diamondBalance > 0) { discountMultiplier = FEE_DENOMINATOR; }
        } catch {}

        return discountMultiplier;
    }

    function shouldSwapBack(address recipient) private view returns (bool) {
        return isMarketMaker[recipient]
        && !_inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() private swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = ROUTER.WETH();

        uint256 liquidityTokens = swapThreshold * liquidityFee / _totalFee / 2;
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
        uint256 totalBNBFee = _totalFee - liquidityFee / 2;

        uint256 amountBNBLiquidity = amountBNB * liquidityFee / totalBNBFee / 2;
        lotteryShare += amountBNB * lotteryFee / totalBNBFee;
        marketingShare += amountBNB * marketingFee / totalBNBFee;
        developmentShare += amountBNB * developmentFee / totalBNBFee;

        if (liquidityTokens > 0) {
            ROUTER.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                liquidityTokens,
                0,
                0,
                LOCKER,
                block.timestamp
            );

            emit AutoLiquidity(amountBNBLiquidity, liquidityTokens);
        }
    }

    // Claim fees

    function claimMarketing() external {
        require(msg.sender == MARKETING_WALLET, "Unauthorized caller");

        uint256 marketingAmount = marketingShare;
        marketingShare = 0;

        if (marketingAmount > 0) {
            (bool sent,) = payable(MARKETING_WALLET).call{value: marketingAmount, gas: transferGas}("");
            require(sent, "Tx failed");
            
            emit ClaimMarketing(marketingAmount);
        }
    }

    function claimLottery() external {
        require(msg.sender == LOTTERY_WALLET, "Unauthorized caller");

        uint256 lotteryAmount = lotteryShare;
        lotteryShare = 0;

        if (lotteryAmount > 0) {
            (bool sent,) = payable(LOTTERY_WALLET).call{value: lotteryAmount, gas: transferGas}("");
            require(sent, "Tx failed");
            
            emit ClaimLottery(lotteryAmount);
        }
    }

    function claimDevelopment() external {
        require(msg.sender == DEVELOPMENT_WALLET, "Unauthorized caller");

        uint256 developmentAmount = developmentShare;
        developmentShare = 0;

        if (developmentAmount > 0) {
            (bool sent,) = payable(DEVELOPMENT_WALLET).call{value: developmentAmount, gas: transferGas}("");
            require(sent, "Tx failed");
            
            emit ClaimDevelopment(developmentAmount);
        }
    }

    function recover() external onlyOwner {
        uint256 recoverAmount = address(this).balance - lotteryShare - marketingShare - developmentShare;
		(bool sent,) = payable(OWNER).call{value: recoverAmount, gas: transferGas}("");
		require(sent, "Tx failed");

        emit Recover(recoverAmount);
	}

    // Maintenance

    function setIsFeeExempt(address account, bool exempt) external onlyOwner {
        require(account != MARKETING_WALLET && account != OWNER && account != address(this) && !isMarketMaker[account]);
        isFeeExempt[account] = exempt;
        emit SetFeeExempt(account, exempt);
    }

    function setIsMarketMaker(address account, bool isMM) external onlyOwner {
        require(account != pair);
        isMarketMaker[account] = isMM;
        emit SetMarketMaker(account, isMM);
    }

    function setFees(
        uint256 _lotteryFee,
        uint256 _liquidityFee,
        uint256 _marketingFee,
        uint256 _developmentFee
    ) external onlyOwner {
        lotteryFee = _lotteryFee;
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        developmentFee = _developmentFee;
        _totalFee = lotteryFee + liquidityFee + marketingFee + developmentFee;
        require(_totalFee <= 1500);

        emit SetFees(lotteryFee, liquidityFee, marketingFee, developmentFee);
    }

    function setSwapBackSettings(bool enabled, uint256 amount) external onlyOwner {
        uint256 tokenAmount = amount * 10**DECIMALS;
        swapEnabled = enabled;
        swapThreshold = tokenAmount;
        emit SetSwapBackSettings(enabled, amount);
    }

    function updateTransferGas(uint256 newGas) external onlyOwner {
        require(newGas >= 21000 && newGas <= 100000);
        
        transferGas = newGas;
        emit UpdateTransferGas(newGas);
    }

    function triggerSwapBack() external onlyOwner {
        swapBack();
        emit TriggerSwapBack();
    }

    function removeSniperRekt() external onlyOwner {
        _sniperRekt = false;
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
        emit EnableTrading();
    }

    function initPresale(address newPresale) external onlyOwner {
        require(presale == address(0), "Presale is already initialized");

        presale = newPresale;
        isFeeExempt[presale] = true;
        emit InitPresale(presale);
    }
}