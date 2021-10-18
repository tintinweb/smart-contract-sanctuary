/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

/**
 *

Name: TOTOTO
Ticker: TOTOTO

This token deploys the following features:
1. Buy tax = 10%
2. Sell tax = 15%
3. Max wallet increases every 24 hours from 0.5% to 2%. 
4. Auto burn of rewards accumulated in contracts to reduce contract dumps and increases price floor.
5. Min amount required to receive rewards = 0.5% supply, 5,000,000.

Tokenomics:
5% rewards
5% marketing

3% marketing farming wallet (will not sell)
3% dev farming wallet (will not sell)

10,000,000 supply
max wallet 200,000 2%
max trx 20,000 0.2%
Cooldown 5s
0.5% - 5,000,000 required for rewards

* 
*/
//SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;


import "./Lib/IBEP20.sol";
import "./Lib/SafeMath.sol";
import "./Lib/Auth.sol";
import "./Lib/IDEX.sol";
import "./Lib/DividendDistributor.sol";


contract TOTOTO is IBEP20, Auth {

    using SafeMath for uint256;

    address BUSD = 0xE0dFffc2E01A7f051069649aD4eb3F518430B6a4;
    address REWARD = 0x7afd064DaE94d73ee37d19ff2D264f5A2903bBB0;
    
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "TOTOTO";
    string constant _symbol = "TOTOTO";
    uint8 constant _decimals = 4;

    // 10M
    uint256 _totalSupply = 1 * 10**7 * (10**_decimals);

    //max tx amount of 0.1% supply
    uint256 public _maxTxAmount = (_totalSupply * 1) / 1000;

    // 0.5%
    uint256 public _startingMaxWalletToken = (_totalSupply * 5) / 1000;
    uint256 public _maxWalletIncrement = _startingMaxWalletToken;
    uint256 _maxWalletTracker;
    uint256 public _maxWalletTrackerTimer = 24 hours;

    //max wallet holding of 2% supply
    uint256 public _maxWalletToken = (_totalSupply * 2) / 100;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
    mapping(address => bool) isTimelockExempt;
    mapping(address => bool) isDividendExempt;

    uint256 reflectionFeeDef = 5;
    uint256 marketingFeeDef = 5;
    uint256 sellFeeDef = 5;

    uint256 public reflectionFee = reflectionFeeDef;
    uint256 public marketingFee = marketingFeeDef;
    uint256 public totalFee = reflectionFeeDef.add(marketingFeeDef);
    uint256 public sellFee = sellFeeDef;
    uint256 public totalSellFee = totalFee.add(sellFeeDef);
    uint256 feeDenominator = 100;

    address public marketingFeeReceiver;

    address public liquidityAddress;
    address public devAddress;
    address public teamAddress;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    // Cooldown & timer functionality
    bool public buyCooldownEnabled = true;
    uint8 public cooldownTimerInterval = 1 minutes;
    mapping(address => uint256) private cooldownTimer;

    bool public swapEnabled = true;
    bool public burnRewardEnabled = true;
    uint256 public swapThreshold = (_totalSupply * 1) / 1000; // 0.1% of supply
    uint256 public maxContractRewardHold = swapThreshold * 5;

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Auth(msg.sender) {
        launchedAt = block.timestamp;

        marketingFeeReceiver = 0xad2805b8113066b4f9859689cB8a3fa360fcA1b3;
        liquidityAddress = 0xad2805b8113066b4f9859689cB8a3fa360fcA1b3;
        devAddress = 0x1C7CB4E5171434cdF832F0A57b7B240dB789DD5A;
        teamAddress = 0x1C7CB4E5171434cdF832F0A57b7B240dB789DD5A;

        //Testnet: 0xCc7aDc94F3D80127849D2b41b6439b7CF1eB4Ae0
        //Mainet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        router = IDEXRouter(0xCc7aDc94F3D80127849D2b41b6439b7CF1eB4Ae0);
        pair = IDEXFactory(router.factory()).createPair(BUSD, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        distributor = new DividendDistributor(address(router), REWARD);

        isFeeExempt[msg.sender] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isFeeExempt[liquidityAddress] = true;
        isFeeExempt[devAddress] = true;
        isFeeExempt[teamAddress] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[ZERO] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[liquidityAddress] = true;
        isTxLimitExempt[devAddress] = true;
        isTxLimitExempt[teamAddress] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;
        isTxLimitExempt[address(this)] = true;

        // No timelock for these people
        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[marketingFeeReceiver] = true;
        isTimelockExempt[liquidityAddress] = true;
        isTimelockExempt[devAddress] = true;
        isTimelockExempt[teamAddress] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[ZERO] = true;
        isTimelockExempt[address(this)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[liquidityAddress] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;

        uint256 totalForTeamWallet = (_totalSupply * 10) / 100;
        uint256 totalForMarketingWallet = (_totalSupply * 5) / 100;
        uint256 totalForLiquidityWallet = (_totalSupply * 10) / 100;
        uint256 totalForDevWallet = (_totalSupply * 5) / 100;
        uint256 totalForSellTeamWallet = (_totalSupply * 70) / 100;

        // Sell Team 70%
        _balances[msg.sender] = totalForSellTeamWallet;
        emit Transfer(address(0), msg.sender, totalForSellTeamWallet);

        // Team 10%
        _balances[teamAddress] = _balances[teamAddress] + totalForTeamWallet;
        emit Transfer(address(0), teamAddress, totalForTeamWallet);

        // Dev 5%
        _balances[devAddress] = _balances[devAddress] + totalForDevWallet;
        emit Transfer(address(0), devAddress, totalForDevWallet);

        // Liquidity 10%
        _balances[liquidityAddress] = _balances[liquidityAddress] + totalForLiquidityWallet;
        emit Transfer(address(0), liquidityAddress, totalForLiquidityWallet);

        // Marketing 5%
        _balances[marketingFeeReceiver] = _balances[marketingFeeReceiver] + totalForMarketingWallet;
        emit Transfer(address(0), marketingFeeReceiver, totalForMarketingWallet);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != uint256(-1)) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    //settting the maximum permitted wallet holding (percent of total supply)
    function setMaxWalletPercent(
        uint256 maxWallPercent,
        uint256 maxWalletIncrement,
        uint256 maxWalletTrackerTimer,
        uint256 startingMaxWalletToken
    ) external authorized {
        _maxWalletToken = (_totalSupply * maxWallPercent) / 100;
        _maxWalletIncrement = maxWalletIncrement;
        _maxWalletTrackerTimer = maxWalletTrackerTimer;
        _startingMaxWalletToken = startingMaxWalletToken;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        //auto update maxwallet from starting maxwallet
        // if (
        //     _maxWalletTracker.add(_maxWalletTrackerTimer) >= block.timestamp &&
        //     _maxWalletToken > _startingMaxWalletToken
        // ) {
        //     _startingMaxWalletToken = _startingMaxWalletToken.add(
        //         _maxWalletIncrement
        //     );
        //     _maxWalletTracker = _maxWalletTracker.add(_maxWalletTrackerTimer);
        // }

        // max wallet code
        if (
            !authorizations[sender] &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != address(ZERO) &&
            recipient != pair &&
            recipient != marketingFeeReceiver &&
            recipient != teamAddress &&
            recipient != devAddress &&
            recipient != liquidityAddress
        ) {
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= _startingMaxWalletToken,
                "Total Holding is currently limited, you can not buy that much."
            );
        }

        // cooldown timer, so a bot doesnt do quick trades!
        if (buyCooldownEnabled && !isTimelockExempt[recipient]) {
            require(
                cooldownTimer[recipient] < block.timestamp,
                "Please wait for cooldown"
            );
            cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
        }

        // Checks max transaction limit
        checkTxLimit(sender, amount);

        if (shouldSwapBack()) {
            swapBack();
            //burn extra rewards
            uint256 rewardsBalanceUnsold = balanceOf(address(this));
            if (rewardsBalanceUnsold > maxContractRewardHold) {
                _basicTransfer(
                    address(this),
                    DEAD,
                    (rewardsBalanceUnsold - maxContractRewardHold)
                );
            }
        }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived = shouldTakeFee(sender)
            ? takeFee(sender, amount)
            : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        // Dividend tracker
        if (!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }

        if (!isDividendExempt[recipient]) {
            try
                distributor.setShare(recipient, _balances[recipient])
            {} catch {}
        }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);

        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 feeAmount;
        if (sender == pair) {
            feeAmount = amount.mul(totalFee).div(feeDenominator);
        } else {
            feeAmount = amount.mul(totalSellFee).div(feeDenominator);
        }

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= 500; //swapThreshold;
    }

    function clearStuckBalance(uint256 amountPercentage) external authorized {
        uint256 amountBUSD = address(this).balance;
        payable(marketingFeeReceiver).transfer(
            (amountBUSD * amountPercentage) / 100
        );
    }

    // enable cooldown between trades
    function cooldownEnabled(bool _status, uint8 _interval) public authorized {
        buyCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }

    function swapBack() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = BUSD;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapThreshold,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBUSD = address(this).balance.sub(balanceBefore);

        uint256 amountBUSDReflection = amountBUSD.mul(reflectionFee).div(totalFee);
        
        uint256 amountBUSDMarketing = amountBUSD.mul(marketingFee).div(totalFee);

        try distributor.deposit{value: amountBUSDReflection}() {} catch {}
        (bool tmpSuccess, ) = payable(marketingFeeReceiver).call{
            value: amountBUSDMarketing,
            gas: 50000
            //gas: 30000
        }("");

        // only to supress warning msg
        tmpSuccess = false;
    }

    function setTxLimit(uint256 amount) external authorized {
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt)
        external
        authorized
    {
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

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        authorized
    {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsTimelockExempt(address holder, bool exempt)
        external
        authorized
    {
        isTimelockExempt[holder] = exempt;
    }

    function setFees(
        uint256 _reflectionFee,
        uint256 _marketingFee,
        uint256 _totalSellFee,
        uint256 _feeDenominator
    ) external authorized {
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFee = _reflectionFee.add(_marketingFee);
        feeDenominator = _feeDenominator;
        totalSellFee = _totalSellFee;
        require(totalFee < feeDenominator / 4);
        require(totalSellFee < feeDenominator / 4);
    }

    //anti snipe, only used when trading starts and that's it.
    function destroySnipes(bool kill) external onlyOwner {
        if (kill) {
            reflectionFee = 5;
            marketingFee = 90;
            totalFee = reflectionFee.add(marketingFee);
            feeDenominator = 100;
        } else {
            reflectionFee = reflectionFeeDef;
            marketingFee = marketingFeeDef;
            totalFee = reflectionFeeDef.add(marketingFeeDef);
            feeDenominator = 100;
        }
    }

    function setFeeReceivers(address _marketingFeeReceiver) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(
        bool _enabled,
        bool _brunReward,
        uint256 _amount,
        uint256 _maxContractRewardHold
    ) external authorized {
        swapEnabled = _enabled;
        burnRewardEnabled = _brunReward;
        swapThreshold = _amount;
        maxContractRewardHold = _maxContractRewardHold;
    }

    function setAllFees(
        uint256 _reflexionFee,
        uint256 _marketingFee,
        uint256 _sellFee
    ) external authorized {
        marketingFeeDef = _marketingFee;
        reflectionFeeDef = _reflexionFee;
        sellFeeDef = _sellFee;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution,
        uint256 _minAmtToQualify
    ) external authorized {
        distributor.setDistributionCriteria(
            _minPeriod,
            _minDistribution,
            _minAmtToQualify
        );
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy)
        public
        view
        returns (uint256)
    {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy)
        public
        view
        returns (bool)
    {
        return getLiquidityBacking(accuracy) > target;
    }

    /* Airdrop Begins */
    function airdrop(
        address from,
        address[] calldata addresses,
        uint256[] calldata tokens
    ) external onlyOwner {
        uint256 SCCC = 0;

        require(
            addresses.length == tokens.length,
            "Mismatch between Address and token count"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            SCCC = SCCC + tokens[i];
        }

        require(balanceOf(from) >= SCCC, "Not enough tokens to airdrop");

        for (uint256 i = 0; i < addresses.length; i++) {
            _basicTransfer(from, addresses[i], tokens[i]);
            if (!isDividendExempt[addresses[i]]) {
                try
                    distributor.setShare(addresses[i], _balances[addresses[i]])
                {} catch {}
            }
        }

        // Dividend tracker
        if (!isDividendExempt[from]) {
            try distributor.setShare(from, _balances[from]) {} catch {}
        }
    }

    function burnContract(uint256 amount) external onlyOwner {
        _basicTransfer(address(this), DEAD, amount);
    }

    function startMaxWalletTrackerTimer() external onlyOwner {
        _maxWalletTracker = block.timestamp;
    }    

    event AutoLiquify(uint256 amountBUSD, uint256 amountBOG);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./IDEX.sol";

interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution,
        uint256 _minAmtToQualify
    ) external;

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


    address BUSD = 0xE0dFffc2E01A7f051069649aD4eb3F518430B6a4;
    
    IBEP20 REWARDS;
    IDEXRouter router;

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    uint256 public minPeriod = 1 minutes;
    uint256 public minDistribution = 0.1 * (10**18);
    //50K required to get rewards
    uint256 public minAmtToQualify = 500 * (10**4);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address _router, address _reward) {
        router = IDEXRouter(_router);
        REWARDS = IBEP20(_reward);
        _token = msg.sender;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution,
        uint256 _minAmtToQualify
    ) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        minAmtToQualify = _minAmtToQualify;
    }


    function setShare(address shareholder, uint256 amount)
        external
        override
        onlyToken
    {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount >= minAmtToQualify && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount < minAmtToQualify && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount);

        if (amount >= minAmtToQualify) {
            totalShares = totalShares.add(amount);
            shares[shareholder].amount = amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
        }
    }

    function deposit() external payable override onlyToken {
        
        uint256 balanceBefore = REWARDS.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = address(REWARDS);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(0, path, address(this), block.timestamp);

        uint256 amount = REWARDS.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(
            dividendsPerShareAccuracyFactor.mul(amount).div(totalShares)
        );
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder)
        internal
        view
        returns (bool)
    {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            REWARDS.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised
                .add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share)
        internal
        view
        returns (uint256)
    {
        return
            share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
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