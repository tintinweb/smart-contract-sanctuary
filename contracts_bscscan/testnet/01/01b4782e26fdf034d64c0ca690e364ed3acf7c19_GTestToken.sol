/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface ERC20 {
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

abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        require(adr != owner, "Cant remove owner");
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface DexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface DexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract GTestToken is ERC20, Auth {
    using SafeMath for uint256;

    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "GTesTToken";
    string constant _symbol = "GTT";
    uint8 constant _decimals = 2;
    uint256 constant _totalSupply = 100_000_000_000 * 10**_decimals;
    
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    uint256 public _maxTxAmount = _totalSupply;
    uint256 public _maxHoldings = _totalSupply;

    bool public lockingEnabled = true;
    mapping(address => bool) public isLocked;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;

    struct FeeMultipliers {
        uint256 buyMultiplier;
        uint256 sellMultiplier;
        uint256 transferMultiplier;
        uint256 divisor;
    }

    struct FeeRatios {
        uint256 liquidity;
        uint256 marketing;
        uint256 dev;
        uint256 total;
        uint256 divisor;
    }

    struct FeeWallets {
        address payable marketing;
        address payable dev;
    }

    FeeRatios public _fees =
        FeeRatios({liquidity: 1, marketing: 3, dev: 2, total: 6, divisor: 100});

    FeeMultipliers public _multipliers =
        FeeMultipliers({
            buyMultiplier: 100,
            sellMultiplier: 150,
            transferMultiplier: 150,
            divisor: 100
        });

    FeeWallets public _feeWallets =
        FeeWallets({
            marketing: payable(0xb81192E27b6ce7127A2e2EBAcAb84F70b6FA84c1),
            dev: payable(0xb81192E27b6ce7127A2e2EBAcAb84F70b6FA84c1)
        });

    address public autoLiquidityReceiver;
    uint256 targetLiquidity = 99;
    uint256 targetLiquidityDenominator = 100;

    uint256 public deadBlocks = 1;
    uint256 public launchBlock = 0;
    bool public tradingOpen;

    bool public swapEnabled = true;
    uint256 public swapThreshold = (_totalSupply * 10) / 10000;
    uint256 public swapTransactionThreshold = (_totalSupply * 5) / 10000;
    bool inSwap;

    modifier swapLock() {
        inSwap = true;
        _;
        inSwap = false;
    }

    DexRouter public router;
    address public pair;

    event AutoLiquify(uint256 amountETH, uint256 amountTokens);

    constructor() Auth(msg.sender) {
        router = DexRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        pair = DexFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        autoLiquidityReceiver = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external pure override returns (uint256) {
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
        return approve(spender, type(uint256).max);
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
        uint256 usrAllowance = _allowances[sender][msg.sender];
        if (usrAllowance != type(uint256).max) {
            usrAllowance = usrAllowance.sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function setMaxHoldingAmount(uint256 percent, uint256 base)
        external
        onlyOwner
    {
        _maxHoldings = (_totalSupply * percent) / base;
    }

    function setMaxTxPercent(uint256 percent, uint256 base) external onlyOwner {
        _maxTxAmount = (_totalSupply * percent) / base;
    }

    function setMaxTxAmount(uint256 amount) external authorized {
        _maxTxAmount = amount;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _transferWithoutFees(sender, recipient, amount);
        }

        if (!authorizations[sender] && !authorizations[recipient]) {
            require(tradingOpen, "Trading is not enabled");

            if (lockingEnabled) {
                require(
                    !isLocked[sender] && !isLocked[recipient],
                    "Wallet is locked"
                );
            }
        }

        if (
            !authorizations[sender] &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != pair
        ) {
            require(
                (amount + balanceOf(recipient)) <= _maxHoldings,
                "Wallet holds maximum allowed"
            );
            require(
                amount <= _maxTxAmount || isTxLimitExempt[sender],
                "Amount greater than Max Transaction Amount."
            );
        }

        if (
            sender != pair &&
            !inSwap &&
            swapEnabled &&
            amount > swapTransactionThreshold &&
            _balances[address(this)] >= swapThreshold
        ) {
            contractSwap();
        }

        if (shouldTakeFee(sender, recipient)) {
            return _transferWithFees(sender, recipient, amount);
        } else {
            return _transferWithoutFees(sender, recipient, amount);
        }

        // uint256 amountReceived = (isFeeExempt[sender] || isFeeExempt[recipient])
        //     ? amount
        //     : takeFee(sender, amount, (recipient == pair));
        // _balances[recipient] = _balances[recipient].add(amountReceived);

        // emit Transfer(sender, recipient, amountReceived);
        // return true;
    }

    function shouldTakeFee(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        return !(isFeeExempt[sender] || isFeeExempt[recipient]);
    }

    function _transferWithoutFees(
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

    function _transferWithFees(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        bool isSell = (recipient == pair);
        bool isBuy = (sender == pair);
        bool isTransfer = (sender != pair && recipient != pair);
        uint256 feeAmount;

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        if (isBuy) {
            if ((launchBlock + deadBlocks) > block.number) {
                feeAmount = amount.mul(99).div(100);
            } else {
                feeAmount = amount
                    .mul(_fees.total)
                    .mul(_multipliers.buyMultiplier)
                    .div(_fees.divisor)
                    .div(_multipliers.divisor);
                }    
        } else if (isSell) {
            feeAmount = amount
                .mul(_fees.total)
                .mul(_multipliers.sellMultiplier)
                .div(_fees.divisor)
                .div(_multipliers.divisor);
        } else if (isTransfer) {
            feeAmount = amount
                .mul(_fees.total)
                .mul(_multipliers.transferMultiplier)
                .div(_fees.divisor)
                .div(_multipliers.divisor);
        }

        uint256 amountAfterFees = amount.sub(feeAmount);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        _balances[recipient] = _balances[recipient].add(amountAfterFees);
        emit Transfer(sender, recipient, amountAfterFees);

        return true;
    }

    function airDrop(
        address from,
        address[] calldata addresses,
        uint256[] calldata tokens
    ) external onlyOwner {
        require(
            addresses.length == tokens.length,
            "Length of addresses and tokens dont match"
        );

        for (uint256 i; i < addresses.length; ++i) {
            _transferWithoutFees(from, addresses[i], tokens[i]);
        }
    }

    // function takeFee(
    //     address sender,
    //     uint256 amount,
    //     bool isSell
    // ) internal returns (uint256) {
    //     uint256 multiplier = isSell ? sellMultiplier : 100;
    //     uint256 feeAmount = amount.mul(totalFee).mul(multiplier).div(
    //         feeDenominator * 100
    //     );

    //     if (!isSell && (launchedAt + deadBlocks) > block.number) {
    //         feeAmount = amount.div(100).mul(99);
    //     }

    //     _balances[address(this)] = _balances[address(this)].add(feeAmount);

    //     emit Transfer(sender, address(this), feeAmount);
    //     return amount.sub(feeAmount);
    // }

    function clearETH(uint256 amountPercentage) external authorized {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer((amountETH * amountPercentage) / 100);
    }

    function setFeeMultipliers(
        uint256 buyMultiplier,
        uint256 sellMultiplier,
        uint256 transferMultiplier,
        uint256 divisor
    ) external onlyOwner {
        _multipliers.buyMultiplier = buyMultiplier;
        _multipliers.sellMultiplier = sellMultiplier;
        _multipliers.transferMultiplier = transferMultiplier;
        _multipliers.divisor = divisor;
    }

    function setFeeRatios(
        uint256 liquidity,
        uint256 marketing,
        uint256 dev
    ) external onlyOwner {
        _fees.liquidity = liquidity;
        _fees.marketing = marketing;
        _fees.dev = dev;
        _fees.total = liquidity + marketing + dev;
        require(
            _fees.total < _fees.divisor / 2,
            "Fees cannot be more than 50%"
        );
    }

    function setFeeWallets(address payable marketing, address payable dev)
        external
        onlyOwner
    {
        _feeWallets.marketing = payable(marketing);
        _feeWallets.dev = payable(dev);
    }

    function setAutoLiquidityReceiver(address _autoLiquidityReceiver)
        external
        onlyOwner
    {
        autoLiquidityReceiver = _autoLiquidityReceiver;
    }

    function tradingStatus(bool _status, uint256 _deadBlocks) public onlyOwner {
        tradingOpen = _status;
        if (tradingOpen && launchBlock == 0) {
            launchBlock = block.number;
            deadBlocks = _deadBlocks;
        }
    }

    function addDeadBlock(uint256 _launchblock, uint256 _deadBlocks)
        public
        onlyOwner
    {
        launchBlock = _launchblock;
        deadBlocks = _deadBlocks;
    }

    function contractSwap() internal swapLock {
        FeeRatios memory fees = _fees;

        uint256 dynamicLiquidityFee = isOverLiquified(
            targetLiquidity,
            targetLiquidityDenominator
        )
            ? 0
            : fees.liquidity;
        uint256 amountToLiquify = swapThreshold
            .mul(dynamicLiquidityFee)
            .div(fees.total)
            .div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceETHBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceETHBefore);

        uint256 totalFees = (fees.total).sub(dynamicLiquidityFee.div(2));

        _feeWallets.marketing.transfer(
            amountETH.mul(fees.marketing).div(totalFees)
        );
        _feeWallets.dev.transfer(amountETH.mul(fees.dev).div(totalFees));

        uint256 amountETHLiquidity = amountETH
            .mul(dynamicLiquidityFee)
            .div(totalFees)
            .div(2);
        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function setLockingMode(bool _status) external onlyOwner {
        lockingEnabled = _status;
    }

    // function enable_blacklist(bool _status) public onlyOwner {
    //     blacklistMode = _status;
    // }
    function setLocks(address[] calldata addresses, bool status)
        external
        onlyOwner
    {
        for (uint256 i; i < addresses.length; ++i) {
            isLocked[addresses[i]] = status;
        }
    }

    // function manage_blacklist(address[] calldata addresses, bool status)
    //     public
    //     onlyOwner
    // {
    //     for (uint256 i; i < addresses.length; ++i) {
    //         isBlacklisted[addresses[i]] = status;
    //     }
    // }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        authorized
    {
        isTxLimitExempt[holder] = exempt;
    }

    // function setFeeReceivers(
    //     address _autoLiquidityReceiver,
    //     address payable _marketingFeeReceiver,
    //     address payable _devFeeReceiver
    // ) external authorized {
    //     autoLiquidityReceiver = _autoLiquidityReceiver;
    //     marketingFeeReceiver = _marketingFeeReceiver;
    //     devFeeReceiver = _devFeeReceiver;
    // }

    function setSwapSettings(
        bool _enabled,
        uint256 _swapThreshold,
        uint256 _swapTransactionThreshold
    ) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _swapThreshold;
        swapTransactionThreshold = _swapTransactionThreshold;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator)
        external
        authorized
    {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));
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
}