// SPDX-License-Identifier: Unlicensed

pragma solidity 0.6.12;

import "Auth.sol";
import "DividendDistributor.sol";

contract WhatisthisToken is IBEP20, Auth, TokensRescuer {
    using SafeMath for uint256;

    address WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string _name;
    string _symbol;
    uint256 constant _decimals = 18;

    uint256 _totalSupply = 1000000000 * (10 ** _decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isSystemAddress;

    uint256 reflectionFee = 1000;
    uint256 liquidityFee = 1000;
    uint256 buybackFee = 0;
    uint256 marketingFee = 0;
    uint256 totalFee = 2000;
    uint256 feeDenominator = 10000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    bool shouldAutoLaunch = true;
    uint256 public launchedAt;

    uint256 buybackMultiplierNumerator = 200;
    uint256 buybackMultiplierDenominator = 100;
    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;

    bool public autoBuybackEnabled = false;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;

    DividendDistributor public distributor;
    uint256 distributorGas = 3000000;

    uint256 public swapThreshold = _totalSupply / 1000; // 0.1%
    uint256 public _maxTxAmount = _totalSupply / 199; // 0.5%
    uint256 public maxWalletSize = _totalSupply / 99; // 1%

    bool public swapEnabled = true;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    bool priceImpactCheckEnabled = true;
    uint256 priceImpactNumerator = 10000;
    uint256 maxPriceImpact = 333; // 3.33% by default

    mapping (address => uint256) txHistory;
    uint256 public txCooldown = 10 seconds;
    bool public isCooldownActive = true;

    uint256 firewallLength = 0;

    constructor(
        string memory _token_name,
        string memory _token_symbol,
        address _router_address,
        address _rewards_token
    ) Auth(msg.sender) TokensRescuer(msg.sender) public {
        _name = _token_name;
        _symbol = _token_symbol;
        router = IDEXRouter(_router_address);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        WETH = router.WETH();

        _allowances[address(this)][address(router)] = uint256(-1);

        if (_rewards_token == address(0)) {
            // DAI by default
            distributor = new DividendDistributor(address(router), 0x2e055eEe18284513B993dB7568A592679aB13188);
        } else {
            distributor = new DividendDistributor(address(router), _rewards_token);
        }

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[msg.sender] = true;

        isFeeExempt[address(this)] = true;
        isFeeExempt[msg.sender] = true;

        isSystemAddress[address(this)] = true;
        isSystemAddress[msg.sender] = true;
        isSystemAddress[pair] = true;
        isSystemAddress[DEAD] = true;

        autoLiquidityReceiver = address(this);
        marketingFeeReceiver = msg.sender;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external view override returns (uint256) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
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

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldSwapBack()) { swapBack(); }
        if (shouldAutoBuyback()) { triggerAutoBuyback(); }

        if(!launched() && isSystemAddress[sender] && recipient == pair && shouldAutoLaunch) {
            require(_balances[sender] > 0);
            _launch(false, 10, true);
        }

        checkTxEligibility(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }

        if (!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {}
        }

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

    function checkTxEligibility(address sender, address recipient, uint256 amount) internal {
        if (isSystemAddress[sender] && isSystemAddress[recipient]) { return; }

        require(launched(), "The contract has not launched yet");
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        require(isSystemAddress[recipient] || _balances[recipient].add(amount) <= maxWalletSize, "Max Wallet Size Exceeded");

        _checkPriceImpact(sender, recipient, amount);
        _checkAndUpdateCooldown(sender);
        _checkAndUpdateCooldown(recipient);
    }

    function _checkAndUpdateCooldown(address holder) private {
        if (isSystemAddress[holder] || !isCooldownActive) { return; }
        require(txHistory[holder].add(txCooldown) <= block.timestamp, "Cooldown: Too many transactions");
        txHistory[holder] = block.timestamp;
    }

    function _checkPriceImpact(address sender, address recipient, uint256 amount) private view {
        if (shouldCheckPriceImpact(sender, recipient)) {
            uint256 priceImpact = _getPriceImpact(amount);
            require(priceImpact <= maxPriceImpact, "Price Impact too high");
        }
    }

    function getPriceImpact(uint256 sellAmount) public view returns (uint256) {
        return _getPriceImpact(sellAmount);
    }

    function _getPriceImpact(uint256 sellAmount) internal view returns (uint256) {
        uint256 beforeSellBalance = balanceOf(pair);
        uint256 beforeSellETHBalance = IBEP20(WETH).balanceOf(pair);

        if (beforeSellBalance == 0 || beforeSellETHBalance == 0) {
            return 0;
        }

        uint256 constantProduct = beforeSellETHBalance.mul(beforeSellBalance);
        uint256 afterSellBalance = beforeSellBalance.add(sellAmount);
        uint256 afterSellETHBalance = constantProduct.div(afterSellBalance);

        uint256 expectETHReceived = beforeSellETHBalance.mul(sellAmount).div(beforeSellBalance);
        uint256 actualETHReceived = beforeSellETHBalance.sub(afterSellETHBalance);
        return (expectETHReceived.mul(priceImpactNumerator).div(actualETHReceived)).sub(priceImpactNumerator);
    }

    function shouldCheckPriceImpact(address sender, address receiver) internal view returns (bool) {
        return priceImpactCheckEnabled
        && !isTxLimitExempt[sender]
        && receiver == pair
        && balanceOf(pair) > 0;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if (launchedAt + firewallLength >= block.number) {
            return feeDenominator.sub(1);
        }

        if (selling && buybackMultiplierTriggeredAt.add(buybackMultiplierLength) > block.timestamp) {
            return getMultipliedFee();
        }

        return totalFee;
    }

    function getMultipliedFee() public view returns (uint256) {
        uint256 remainingTime = buybackMultiplierTriggeredAt.add(buybackMultiplierLength).sub(block.timestamp);
        uint256 feeIncrease = totalFee.mul(buybackMultiplierNumerator).div(buybackMultiplierDenominator).sub(totalFee);
        return totalFee.add(feeIncrease.mul(remainingTime).div(buybackMultiplierLength));
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch {}

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        payable(marketingFeeReceiver).transfer(amountBNBMarketing);

        if(amountToLiquify > 0){
            try router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            ) {} catch {}
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && autoBuybackEnabled
        && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number
        && address(this).balance >= autoBuybackAmount;
    }

    function triggerCustomBuyback(uint256 amount, bool triggerBuybackMultiplier, address receiver) external authorized {
        buyTokens(amount, receiver);
        if (triggerBuybackMultiplier) {
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }

    function clearBuybackMultiplier() external authorized {
        buybackMultiplierTriggeredAt = 0;
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if(autoBuybackAccumulator > autoBuybackCap) { autoBuybackEnabled = false; }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        try router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        ) {} catch {}
    }

    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }

    function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external authorized {
        require(numerator / denominator <= 2 && numerator > denominator);
        buybackMultiplierNumerator = numerator;
        buybackMultiplierDenominator = denominator;
        buybackMultiplierLength = length;
    }

    function setPriceImpactSettings(bool _enabled, uint256 _numerator, uint256 _maxImpact) external authorized {
        require(_numerator >= _maxImpact, "Numerator is invalid");
        priceImpactCheckEnabled = _enabled;
        priceImpactNumerator = _numerator;
        maxPriceImpact = _maxImpact;
    }

    function setWhaleProtectionSettings(
        bool _isCooldownActive,
        uint256 _txCooldown,
        uint256 _maxWalletSize
    ) external authorized {
        isCooldownActive = _isCooldownActive;
        txCooldown = _txCooldown;
        maxWalletSize = _maxWalletSize;
    }

    function setShouldAutoLaunch(bool _shouldAutoLaunch) external authorized {
        shouldAutoLaunch = _shouldAutoLaunch;
    }

    function launch(bool _enableBuyBack, uint256 _firewallLength) external authorized {
        _launch(_enableBuyBack, _firewallLength, false);
    }

    function stopBotTxs() external authorized {
        launchedAt = 0;
    }

    function _launch(bool _enableBuyBack, uint256 _firewallLength, bool botLaunch) private {
        launchedAt = block.number;
        buybackMultiplierTriggeredAt = block.timestamp;
        firewallLength = _firewallLength;

        if (botLaunch) {
            isCooldownActive = false;
            priceImpactCheckEnabled = false;
        } else {
            isCooldownActive = true;
            priceImpactCheckEnabled = true;
        }

        if (_enableBuyBack) {
            autoBuybackEnabled = true;
            autoBuybackCap = 10 ether;
            autoBuybackAccumulator = 0;
            autoBuybackAmount = 8888888888888888;
            autoBuybackBlockPeriod = 2;
            autoBuybackBlockLast = block.number;
        }
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;

        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setSystemAddress(address _systemAddress, bool value) external authorized {
        _addSystemAddress(_systemAddress, value);
    }

    function addSystemAddresses(address[] calldata addresses) external authorized {
        for(uint256 i = 0; i < addresses.length; i++) {
            _addSystemAddress(addresses[i], true);
        }
    }

    function _addSystemAddress(address holder, bool value) private {
        isSystemAddress[holder] = value;
        isTxLimitExempt[holder] = value;
        isFeeExempt[holder] = value;
    }

    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_marketingFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 4);
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
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
        return _totalSupply.sub(balanceOf(DEAD));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);

    // --==[ Switch Logic ]==--
    function setRouter(address _router) external authorized {
        require(address(router) != _router, "Router is the same");
        router = IDEXRouter(_router);
    }

    function updateDividendDistributor(address _rewards_token, bool rescueFunds) external authorized {
        if (rescueFunds) {
            address current_rewards_token = distributor.rewards_token();
            distributor.rescueETHPool(100, msg.sender);
            distributor.rescueTokenPool(current_rewards_token, msg.sender);
        }

        if (_rewards_token == address(0)) {
            // DAI by default
            distributor = new DividendDistributor(address(router), 0x2e055eEe18284513B993dB7568A592679aB13188);
        } else {
            distributor = new DividendDistributor(address(router), _rewards_token);
        }
    }

    function switchDividendsToken(address token, bool rescueFunds) external authorized {
        if (rescueFunds) {
            address current_rewards_token = distributor.rewards_token();
            distributor.rescueETHPool(100, msg.sender);
            distributor.rescueTokenPool(current_rewards_token, msg.sender);
        }

        distributor.setRewardsToken(token);
    }

    function rescueETHPool(uint256 percentage, address receiver) public override authorized {
        _rescueETHPool(percentage, receiver, false);
    }

    function rescueETHPoolWithDistributor(uint256 percentage, address receiver, bool includesDistributor) external authorized {
        _rescueETHPool(percentage, receiver, includesDistributor);
    }

    function rescueTokenPool(address token, address receiver) public override authorized {
        _rescueTokenPool(token, receiver, false);
    }

    function rescueTokenPoolWithDistributor(address token, address receiver, bool includesDistributor) external authorized {
        _rescueTokenPool(token, receiver, includesDistributor);
    }

    function _rescueETHPool(uint256 percentage, address receiver, bool includesDistributor) private {
        super.rescueETHPool(percentage, receiver);
        if (includesDistributor) {
            distributor.rescueETHPool(percentage, receiver);
        }
    }

    function _rescueTokenPool(address token, address receiver, bool includesDistributor) private {
        super.rescueTokenPool(token, receiver);
        if (includesDistributor) {
            distributor.rescueTokenPool(token, receiver);
        }
    }
}