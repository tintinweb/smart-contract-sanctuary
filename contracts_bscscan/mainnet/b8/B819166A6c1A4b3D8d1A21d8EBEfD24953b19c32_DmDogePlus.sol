pragma solidity ^0.7.4;
// SPDX-License-Identifier: Unlicensed
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Auth.sol";
import "./DividendDistributor.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract DmDogePlus is IERC20, Auth {
    using SafeMath for uint256;

    address USDT = 0x55d398326f99059fF775485246999027B3197955;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "DiamondDoge plus";
    string constant _symbol = "DMDOGE";
    uint256 constant _decimals = 9;

    uint256 _totalSupply = 1000000000000000 * (10 ** _decimals);
    uint256 public _maxSellTxAmount = 12 * 10 ** 17; // 1.2WETH

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
    mapping(address => bool) isDividendExempt;
    mapping(address => bool) isBlacklisted;
    mapping(address => uint) sellNumberList;
    mapping(address => bool) isSellFeeMax;

    uint256 basicFee = 10000;
    uint256 maxFee = 300000;
    uint256 liquidityFee = 10000;
    uint256 buybackFee = 50000;
    uint256 reflectionFee = 80000;
    uint256 marketingFee = 20000;
    uint256 totalFee = 160000;
    uint256 feeDenominator = 1000000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IUniswapV2Router02 public router;
    address public pair;

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

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 20000; // 0.005%
    bool inSwap;
    bool rewardEnabled = true;
    modifier swapping() {inSwap = true;
        _;
        inSwap = false;}

    constructor (address _marketingFeeReceiver) Auth(msg.sender) {
        router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IUniswapV2Factory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(- 1);

        distributor = new DividendDistributor(address(router));

        isFeeExempt[owner] = true;
        isTxLimitExempt[owner] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(router)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;


        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = _marketingFeeReceiver;

        _balances[owner] = _totalSupply;

        emit Transfer(address(0), owner, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {return _totalSupply;}

    function decimals() external pure returns (uint) {return _decimals;}

    function symbol() external pure returns (string memory) {return _symbol;}

    function name() external pure returns (string memory) {return _name;}

    function getOwner() external view returns (address) {return owner;}

    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}

    function allowance(address holder, address spender) external view override returns (uint256) {return _allowances[holder][spender];}

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(- 1));
    }

    function transferMultiple(address[] calldata recipients, uint256 amount) public returns (bool) {
        for (uint256 i = 0; i < recipients.length; i++) {
            require(_transferFrom(msg.sender, recipients[i], amount));
        }
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != uint256(- 1)) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(!isBlacklisted[sender]);
        if (inSwap) {return _basicTransfer(sender, recipient, amount);}

        checkTxLimit(sender, recipient, amount);

        if (shouldSwapBack(recipient)) {swapBack();}
        if (shouldAutoBuyback(recipient)) {triggerAutoBuyback();}

        if (!launched() && recipient == pair) {require(_balances[sender] > 0);
            launch();}

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (rewardEnabled && !isDividendExempt[sender]) {try distributor.setShare(sender, _balances[sender]) {} catch {}}
        if (rewardEnabled && !isDividendExempt[recipient]) {try distributor.setShare(recipient, _balances[recipient]) {} catch {}}

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

    function checkTxLimit(address sender, address recipient, uint256 amount) public view {
        //sell and normal tx
        if (launchedAt > 0 && balanceOf(pair) > 0 && block.number > launchedAt + 3 && recipient == pair) {
            require(tokenWethValue(amount) <= _maxSellTxAmount ||
            isTxLimitExempt[sender] || isTxLimitExempt[recipient], "TX Limit Exceeded");}
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function tokenWethValue(uint256 amount) internal view returns (uint value){
        value = 0;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        uint[] memory amounts = router.getAmountsOut(amount, path);
        if (amounts.length > 0) {
            value = amounts[amounts.length - 1];
        }
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if (launchedAt + 3 > block.number) {return feeDenominator.sub(1);}
        if (selling && buybackMultiplierTriggeredAt.add(buybackMultiplierLength) > block.timestamp) {return getMultipliedFee();}
        return totalFee;
    }

    function getMultipliedFee() public view returns (uint256) {
        uint256 remainingTime = buybackMultiplierTriggeredAt.add(buybackMultiplierLength).sub(block.timestamp);
        uint256 feeIncrease = totalFee.mul(buybackMultiplierNumerator).div(buybackMultiplierDenominator).sub(totalFee);
        return totalFee.add(feeIncrease.mul(remainingTime).div(buybackMultiplierLength));
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        bool selling = receiver == pair;
        uint fee = getTotalFee(selling);
        if (selling) {
            if (isSellFeeMax[sender]) {
                fee = maxFee;
            } else {
                uint afterFee = fee.add(sellNumberList[sender].mul(basicFee));
                if (afterFee >= maxFee) {
                    fee = maxFee;
                    isSellFeeMax[sender] = true;
                } else {
                    fee = afterFee;
                }
            }
        }
        uint256 feeAmount = amount.mul(fee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if (selling && !isSellFeeMax[sender]) sellNumberList[sender] += 1;
        return amount.sub(feeAmount);
    }

    function shouldSwapBack(address to) internal view returns (bool) {
        return to == pair
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

        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);

        try distributor.deposit{value : amountBNBReflection}() {} catch {}
        payable(marketingFeeReceiver).call{value : amountBNBMarketing, gas : 30000}("");

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value : amountBNBLiquidity}(
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

    function shouldAutoBuyback(address to) internal view returns (bool) {
        return to == pair
        && !inSwap
        && autoBuybackEnabled
        && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number
        && address(this).balance >= autoBuybackAmount;
    }

    function DOGGYSTYLE(uint256 amount, bool triggerBuybackMultiplier) external authorized {
        buyTokens(amount, DEAD);
        if (triggerBuybackMultiplier) {
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }

    function setMaxFee(uint fee) external authorized {
        maxFee = fee;
    }

    function clearBuybackMultiplier() external authorized {
        buybackMultiplierTriggeredAt = 0;
    }

    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if (autoBuybackAccumulator > autoBuybackCap) {autoBuybackEnabled = false;}
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value : amount}(
            0,
            path,
            to,
            block.timestamp
        );
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

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function setSellTxLimit(uint256 amount) external authorized {
        _maxSellTxAmount = amount;
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

    function setIsBlacklisted(address[] calldata accounts, bool flag) external authorized {
        for (uint256 i = 0; i < accounts.length; i++) {
            isBlacklisted[accounts[i]] = flag;
        }
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsExempts(address[] calldata accounts, bool exempt) external authorized {
        for (uint256 i = 0; i < accounts.length; i++) {
            isTxLimitExempt[accounts[i]] = exempt;
            isFeeExempt[accounts[i]] = exempt;
        }
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

    function setRewardEnabled(bool _enabled) external authorized {
        rewardEnabled = _enabled;
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

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
}