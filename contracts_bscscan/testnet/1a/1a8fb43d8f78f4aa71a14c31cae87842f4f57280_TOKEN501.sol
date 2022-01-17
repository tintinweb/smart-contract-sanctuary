//SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./IBEP20.sol";
import "./Auth.sol";
import "./SafeMath.sol";
import "./IDEX.sol";
import "./DistributorFactory.sol";
import "./DividendDistributor.sol";

contract TOKEN501 is IBEP20, Auth {
    using SafeMath for uint256;

    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "TOKEN501";
    string constant _symbol = "TOKEN501";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100000000000000 * (10 ** _decimals);
    uint256 public _maxBuyTxAmount = 1000000000000 * (10 ** _decimals); // 1%
    uint256 public _maxSellTxAmount = 1000000000000 * (10 ** _decimals); // 1%
    uint256 public _maxWalletAmount = 2000000000000 * (10 ** _decimals); // 2%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public automatedMarketMakerPairs;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isMaxWalletExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;

    uint256 public liquidityFee = 5;
    uint256 public gasWalletFee = 1;
    uint256 public reflectionFee = 10;
    uint256 public marketingFee = 2;
    uint256 public totalFee = 18;
    uint256 feeDenominator = 100;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public gasWalletFeeReceiver;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    DistributorFactory distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 20000; // 0.005%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor() Auth(msg.sender) {
        WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
        address _dexRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        router = IDEXRouter(_dexRouter);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        WBNB = router.WETH();
        distributor = new DistributorFactory();

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isFeeExempt[autoLiquidityReceiver] = true;
        isFeeExempt[gasWalletFeeReceiver] = true;
        
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[autoLiquidityReceiver] = true;
        isTxLimitExempt[gasWalletFeeReceiver] = true;
        
        isMaxWalletExempt[msg.sender] = true;
        isMaxWalletExempt[pair] = true;
        isMaxWalletExempt[address(this)] = true;
        isMaxWalletExempt[DEAD] = true;
        isMaxWalletExempt[marketingFeeReceiver] = true;
        isMaxWalletExempt[autoLiquidityReceiver] = true;
        isMaxWalletExempt[gasWalletFeeReceiver] = true;
        
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[marketingFeeReceiver] = true;
        isDividendExempt[autoLiquidityReceiver] = true;
        isDividendExempt[gasWalletFeeReceiver] = true;

        automatedMarketMakerPairs[pair] = true;

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;
        gasWalletFeeReceiver = msg.sender;

        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function getDistributorFactory()
        external
        view
        returns (DistributorFactory)
    {
        return distributor;
    }

    function addDistributor(
        address _dexRouter,
        address _BEP_TOKEN,
        address _WBNB
    ) external authorized {
        distributor.addDistributor(_dexRouter, _BEP_TOKEN, _WBNB);
    }

    function deleteDistributor(address _BEP_TOKEN) external authorized {
        distributor.deleteDistributor(_BEP_TOKEN);
    }

    function getDistributersBEP20Keys()
        external
        view
        returns (address[] memory)
    {
        return distributor.getDistributorsAddresses();
    }

    function getDistributer(address _BEP_TOKEN)
        external
        view
        returns (DividendDistributor)
    {
        return distributor.getDistributor(_BEP_TOKEN);
    }

    function getTotalDividends(address _BEP_TOKEN)
        external
        view
        returns (uint256)
    {
        DividendDistributor singleDistributor = distributor.getDistributor(
            _BEP_TOKEN
        );
        return singleDistributor.totalDividends();
    }

    /// @dev Setting the version as a function so that it can be overriden
    function version() public pure virtual returns (string memory) {
        return "1";
    }

    function getChainID() external view returns (uint256) {
        return block.chainid;
    }

    receive() external payable {}

    function donate() external payable {}

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
        return approve(spender, type(uint256).max );
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        checkTxLimit(sender, recipient, amount);
    
        if(shouldSwapBack()){
            swapBack();
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

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

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        checkWalletLimit(recipient);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        if (automatedMarketMakerPairs[sender]) {
             if (!isTxLimitExempt[recipient]) {
                require(amount <= _maxBuyTxAmount, "TX Limit Exceeded");
             }
             
             if (!isMaxWalletExempt[recipient]) {
                require((_balances[recipient] + amount) <= _maxWalletAmount, "Wallet Amount Limit Exceeded");
             }
        } else if (automatedMarketMakerPairs[recipient]) {
            if (!isTxLimitExempt[sender]) {
                require(amount <= _maxSellTxAmount, "Max Sell limit exceeded");
            }
        }
    }

    function checkWalletLimit(address recipient) internal view {
        require(_balances[recipient] <= _maxWalletAmount || isMaxWalletExempt[recipient], "Wallet Amount Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(100);
        
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
        uint256 dynamicLiquidityFee = isOverLiquified(
            targetLiquidity,
            targetLiquidityDenominator
        )
            ? 0
            : liquidityFee;
        uint256 amountToLiquify = swapThreshold
            .mul(dynamicLiquidityFee)
            .div(totalFee)
            .div(2);
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

        uint256 amountBNBLiquidity = amountBNB
            .mul(dynamicLiquidityFee)
            .div(totalBNBFee)
            .div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(
            totalBNBFee
        );

        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(
            totalBNBFee
        );
        uint256 amountBNBGasWallet = amountBNB.mul(gasWalletFee).div(
            totalBNBFee
        );

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        payable(marketingFeeReceiver).transfer(amountBNBMarketing);
        payable(gasWalletFeeReceiver).transfer(amountBNBGasWallet);

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountBNBLiquidity}(
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

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, to, block.timestamp);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() public authorized {
        require(launchedAt == 0, "Already launched boi");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }

    function setTxLimits(uint256 maxBuyTxAmount, uint256 maxSellTxAmount) external authorized {
        require(maxBuyTxAmount >= 1000000000000, "Maxbuy cant be below 1%");
        require(maxSellTxAmount >= 1000000000000, "Maxsell cant be below 1%");
        _maxBuyTxAmount = maxBuyTxAmount * (10 ** _decimals);
        _maxSellTxAmount = maxSellTxAmount * (10 ** _decimals);
    }

    function setWalletAmountLimit(uint256 amount) external authorized {
        _maxWalletAmount = amount * (10 ** _decimals);
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

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsMaxWalletExempt(address holder, bool exempt) external authorized {
        isMaxWalletExempt[holder] = exempt;
    }

    function setFees(
        uint256 _liquidityFee,
        uint256 _gasWalletFee,
        uint256 _reflectionFee,
        uint256 _marketingFee,
        uint256 _feeDenominator
    ) external authorized {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        gasWalletFee = _gasWalletFee;
        totalFee = _liquidityFee
            .add(_reflectionFee)
            .add(_marketingFee)
            .add(_gasWalletFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 4);
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _marketingFeeReceiver,
        address _gasWalletReceiver
    ) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        gasWalletFeeReceiver = _gasWalletReceiver;
    }

        function setTargetLiquidity(uint256 _target, uint256 _denominator)
        external
        authorized
    {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount * (10 ** _decimals);
    }

    function setDistributionCriteria(
        address _BEP_TOKEN,
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external authorized {
        distributor.setDistributionCriteria(
            _BEP_TOKEN,
            _minPeriod,
            _minDistribution
        );
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 1000000);
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

    function setAutomatedMarketMakerPair(address _pair, bool value) public onlyOwner {
        require(_pair != pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(_pair, value);
        isMaxWalletExempt[pair] = true;
        isDividendExempt[pair] = true;
    }

    function _setAutomatedMarketMakerPair(address _pair, bool value) private {
        require(automatedMarketMakerPairs[_pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[_pair] = value;

        if(value) {
            isDividendExempt[_pair] = true;
        }

        emit SetAutomatedMarketMakerPair(_pair, value);
    }
    
    function manuallySetPair(address p) public onlyOwner {
        automatedMarketMakerPairs[p] = true;
        isMaxWalletExempt[p] = true;
        isDividendExempt[p] = true;
        pair = p;
    }

    /**
     * @dev Sets the allowance granted to `spender` by `owner`.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function _setAllowance(
        address owner,
        address spender,
        uint256 wad
    ) internal virtual returns (bool) {
        _allowances[owner][spender] = wad;
        emit Approval(owner, spender, wad);

        return true;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
}