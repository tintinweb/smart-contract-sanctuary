// SPDX-License-Identifier: MIT

/**
 * In memory of Selma
 */

pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./DividendDistributor.sol";

contract BabyBanana is IBEP20 {
    struct TokenLock {
        uint256 amount;
        uint256 releaseTime;
    }

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address constant MULTI_SIG_TEAM_WALLET = 0x48e065F5a65C3Ba5470f75B65a386A2ad6d5ba6b;
    address constant MARKETING_WALLET = 0x0426760C100E3be682ce36C01D825c2477C47292;

    IBabyBananaNFT babyBananaNFT = IBabyBananaNFT(0x143Fab4Ddb74Ca18026946D3e67Dd51C201A7657);
    ISelmaNFT selmaNFT = ISelmaNFT(0x824Db8c2Cf7eC655De2A7825f8E9311c8e526523);

    bool public autoBuybackEnabled = false;
    bool public swapEnabled = true;
    bool _inSwap;

    uint8 constant DECIMALS = 18;
    uint256 _totalSupply = 1 * 10**9 * 10**DECIMALS;
    uint256 public swapThreshold = 300000 * 10**DECIMALS;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) _isFeeExempt;
    mapping (address => bool) _isDividendExempt;
    mapping (address => TokenLock) _lockedTokens;

    uint256 _buybackFee = 300;
    uint256 _rewardFee = 100;
    uint256 _marketingFee = 100;
    uint256 _totalFee = 500;
    uint256 constant FEE_DENOMINATOR = 10000;

    IApeRouter public router;
    address public pair;
    uint256 _launchedAt;

    uint256 public lastNftBuyback;
    uint256 public nftBuybackCooldown = 3 days;

    uint256 _autoBuybackCap;
    uint256 _autoBuybackAccumulator;
    uint256 _autoBuybackAmount;
    uint256 _autoBuybackBlockPeriod;
    uint256 _autoBuybackBlockLast;

    DividendDistributor _distributor;
    uint256 _marketingTransferGas = 30000;

    modifier swapping() { 
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier onlyTeam() {
        require(msg.sender == MULTI_SIG_TEAM_WALLET);
        _;
    }

    modifier onlyMarketing() {
        require(msg.sender == MARKETING_WALLET);
        _;
    }

    constructor () {
        router = IApeRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        pair = IApeFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        _distributor = new DividendDistributor();
        excludeAccounts();

        _balances[MULTI_SIG_TEAM_WALLET] = _totalSupply;
        emit Transfer(address(0), MULTI_SIG_TEAM_WALLET, _totalSupply);
    }

    // IBEP20

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return DECIMALS; }
    function symbol() external pure override returns (string memory) { return "BABYBANANA"; }
    function name() external pure override returns (string memory) { return "BabyBanana"; }
    function getOwner() external pure override returns (address) { return MULTI_SIG_TEAM_WALLET; }
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

    function lockedAccountInfo(address account) external view returns (TokenLock memory) {
        return _lockedTokens[account];
    }

    function getTotalFee() public view returns (uint256) {
        if(_launchedAt + 1 >= block.number){ return FEE_DENOMINATOR - 1; }
        return _totalFee;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - _balances[DEAD] - _balances[ZERO];
    }

    function nftBuyback() external {
        uint256 buybackAmount = babyBananaNFT.featureValueOf(0, msg.sender);
        require(buybackAmount > 0, "Can't buyback without amount");
        require(address(this).balance >= buybackAmount, "Insufficient balance");
        require(lastNftBuyback + nftBuybackCooldown <= block.timestamp, "NFT buyback is cooling down");

        babyBananaNFT.consume(0, msg.sender);
        buyTokens(buybackAmount, DEAD);
        lastNftBuyback = block.timestamp;
    }

    // Private

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) private returns (bool) {
        if(_inSwap){ return _basicTransfer(sender, recipient, amount); }

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        if (_lockedTokens[sender].releaseTime > block.timestamp) {
            require(senderBalance - amount >= _lockedTokens[sender].amount, "Tokens are locked");
        }

        if(shouldSwapBack(recipient)){ swapBack(); }
        if(shouldAutoBuyback(recipient)){ triggerAutoBuyback(); }
        if(!launched() && recipient == pair && senderBalance > 0 && amount > 0){ launch(); }

        _balances[sender] = senderBalance - amount;

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] += amountReceived;

        if(!_isDividendExempt[sender]){ try _distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!_isDividendExempt[recipient]){ try _distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try _distributor.process() {} catch {}

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
        bool isSell = recipient == pair;
        bool isBuy = sender == pair;
        if (_isFeeExempt[sender] || recipient == address(router)) { return false; }
        return isBuy || isSell;
    }

    function takeFee(address sender, address recipient, uint256 amount) private returns (uint256) {
        bool isBuy = sender == pair;
        address initiator = isBuy ? recipient : sender;
        
        uint256 discountMultiplier = babyBananaNFT.featureValueOf(3, initiator);

        if (discountMultiplier == 0) {
            if (selmaNFT.balanceOf(initiator, 1) > 0) { discountMultiplier = 2500; }
            if (selmaNFT.balanceOf(initiator, 2) > 0) { discountMultiplier = 5000; }
        }

        uint256 discountedFee = getTotalFee() - getTotalFee() * discountMultiplier / FEE_DENOMINATOR;
        uint256 feeAmount = amount * discountedFee / FEE_DENOMINATOR;

        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function shouldSwapBack(address recipient) private view returns (bool) {
        return recipient == pair
        && !_inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() private swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapThreshold,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance - balanceBefore;
        uint256 amountBNBRewards = amountBNB * _rewardFee / _totalFee;
        uint256 amountBNBMarketing = amountBNB * _marketingFee / _totalFee;

        try _distributor.deposit{value: amountBNBRewards}() {} catch {}
        payable(MARKETING_WALLET).call{value: amountBNBMarketing, gas: _marketingTransferGas}("");
    }

    function shouldAutoBuyback(address recipient) private view returns (bool) {
        return recipient == pair
            && !_inSwap
            && autoBuybackEnabled
            && _autoBuybackBlockLast + _autoBuybackBlockPeriod <= block.number
            && address(this).balance >= _autoBuybackAmount;
    }

    function triggerAutoBuyback() private {
        buyTokens(_autoBuybackAmount, DEAD);
        _autoBuybackBlockLast = block.number;
        _autoBuybackAccumulator += _autoBuybackAmount;
        if(_autoBuybackAccumulator > _autoBuybackCap){ autoBuybackEnabled = false; }
    }

    function buyTokens(uint256 amount, address to) private swapping {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function launched() private view returns (bool) {
        return _launchedAt != 0;
    }

    function launch() private {
        _launchedAt = block.number;
    }

    function excludeAccounts() private {
        _isFeeExempt[MARKETING_WALLET] = true;
        _isDividendExempt[MARKETING_WALLET] = true;

        _isFeeExempt[MULTI_SIG_TEAM_WALLET] = true;
        _isDividendExempt[MULTI_SIG_TEAM_WALLET] = true;

        _isFeeExempt[address(router)] = true;
        _isFeeExempt[address(this)] = true;
        _isDividendExempt[address(this)] = true;

        _isDividendExempt[pair] = true;
        _isDividendExempt[DEAD] = true;
        _isDividendExempt[ZERO] = true;
    }

    // Maintenance

    function updateBabyBananaNFT(address newAddress) external onlyTeam {
		babyBananaNFT = IBabyBananaNFT(newAddress);
        _distributor.updateBabyBananaNFT(newAddress);
	}

    function updateSelmaNFT(address newAddress) external onlyTeam {
		selmaNFT = ISelmaNFT(newAddress);
        _distributor.updateSelmaNFT(newAddress);
	}

    function updateRouter(address newRouter) external onlyTeam {
        router = IApeRouter(newRouter);
        _distributor.updateRouter(address(router));
        _allowances[address(this)][address(router)] = type(uint256).max;

        pair = IApeFactory(router.factory()).createPair(router.WETH(), address(this));
        _isDividendExempt[pair] = true;
    }
    
    function updateDividendAccuracyFactor(uint256 newValue) external onlyTeam {
        _distributor.updateDividendAccuracyFactor(newValue);
    }

    function setMarketingTransferGas(uint256 gas) external onlyTeam {
        require(gas <= 100000);
        _marketingTransferGas = gas;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyTeam {
        require(holder != address(this) && holder != pair);
        _isDividendExempt[holder] = exempt;
        if(exempt){
            _distributor.setShare(holder, 0);
        }else{
            _distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyTeam {
        _isFeeExempt[holder] = exempt;
    }

    function setFees(uint256 buybackFee, uint256 rewardFee, uint256 marketingFee) external onlyTeam {
        _buybackFee = buybackFee;
        _rewardFee = rewardFee;
        _marketingFee = marketingFee;
        _totalFee = buybackFee + rewardFee + marketingFee;
        require(_totalFee <= 1500);
    }

    function setSwapBackSettings(bool enabled, uint256 amount) external onlyTeam {
        uint256 tokenAmount = amount * 10**DECIMALS;
        swapEnabled = enabled;
        swapThreshold = tokenAmount;
    }

    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external onlyTeam {
        autoBuybackEnabled = _enabled;
        _autoBuybackCap = _cap;
        _autoBuybackAccumulator = 0;
        _autoBuybackAmount = _amount;
        _autoBuybackBlockPeriod = _period;
        _autoBuybackBlockLast = block.number;
    }

    function setNftBuybackCooldown(uint256 cooldown) external onlyTeam {
        nftBuybackCooldown = cooldown;
    }

    function triggerBuyback(uint256 amount) external onlyMarketing {
        buyTokens(amount, DEAD);
    }

    function triggerSwapBack() external onlyMarketing {
        swapBack();
    }

    function sendLockedTokens(address recipient, uint256 amount, uint256 releaseTime) external onlyMarketing {
        _lockedTokens[recipient] = TokenLock(amount, releaseTime);
        _transferFrom(msg.sender, recipient, amount);
    }

    function unlockTokens(address account) external onlyTeam {
        _lockedTokens[account].releaseTime = 0;
        _lockedTokens[account].amount = 0;
    }
}