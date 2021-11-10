// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SM: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SM: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SM: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SM: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SM: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
    Generic BEP20 interface
*/
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }
    
    modifier onlyOwner() { require(isOwner(msg.sender), "!O"); _; }
    modifier authorized() { require(isAuthorized(msg.sender), "!A"); _; }

    function authorize(address adr) public onlyOwner { authorizations[adr] = true; }
    function unauthorize(address adr) public onlyOwner { authorizations[adr] = false; }
    function isOwner(address account) public view returns (bool) { return account == owner; }
    function isAuthorized(address adr) public view returns (bool) { return authorizations[adr]; }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
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

    address WBNB;
    IBEP20 BUSD;
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 18);

    uint256 currentIndex;

    bool initialized;

    modifier initialization() { require(!initialized); _; initialized = true; }
    modifier onlyToken() { require(msg.sender == _token); _; }

    constructor (address _router, address wbnb, address busd) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
        WBNB = wbnb;
        BUSD = IBEP20(busd);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);

        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = BUSD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(BUSD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = BUSD.balanceOf(address(this)).sub(balanceBefore);
        
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount){
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

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
            && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) { return; }

        uint256 amount = getUnpaidEarnings(shareholder);

        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            BUSD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) { return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) { return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract ElfCoin is IBEP20, Auth {
    using SafeMath for uint256;

    IDEXRouter public router;
    address public pair;

    // Mapping
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) _isFeeExempt;
    mapping (address => bool) _isTransactionLimitExempt;
    mapping (address => bool) _isDividendExempt;

    // Addresses
    address public WBNB;
    address public BUSD;
    address private _burn = 0x000000000000000000000000000000000000dEaD;
    address private _zero = 0x0000000000000000000000000000000000000000;

    // Token Details
    string constant _name = "Elf Coin";
    string constant _symbol = "ELFIE";
    uint8 constant _decimals = 9;
    uint256 private _totalSupply = 1_000_000_000_000_000 * (10 ** _decimals); // 1 Quadrillion
    uint256 public MaxTransactionAmount = _totalSupply.div(400); // 0.25%

    // Token Tax (Fees)
    uint256 public maxFee = 1500;
    uint256 private _liquidityFee = 200;
    uint256 private _reflectionFee = 800;
    uint256 private _marketingFee = 400;
    uint256 private _totalFee = _liquidityFee.add(_reflectionFee).add(_marketingFee);
    uint256 private _feeDenominator = 10000;

    // Fee receiver and liquidity details
    address public LiquidityWallet;
    address payable public MarketingWallet = payable(0x4BBdA5E86593Cc60E6eA12faC95Cf383CFF869D4);
    uint256 private _targetLiquidity = 25;
    uint256 private _targetLiquidityDenominator = 100;

    // Distribution
    address public DistributorAddress;
    DividendDistributor distributor;
    uint256 private _distributorGas = 500000;

    // Swapping
    bool public SwapEnabled = true;
    uint256 public SwapThreshold = _totalSupply / 2000; // 0.005%
    bool private _inSwap;
    modifier swapping() { _inSwap = true; _; _inSwap = false; }

    constructor (address _dexRouter, address wbnb, address busd) Auth(msg.sender) {
        WBNB = wbnb;
        BUSD = busd;

        router = IDEXRouter(_dexRouter);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        WBNB = router.WETH();
        distributor = new DividendDistributor(_dexRouter, wbnb, busd);
        DistributorAddress = address(distributor);

        _isFeeExempt[msg.sender] = true;
        _isTransactionLimitExempt[msg.sender] = true;
        _isDividendExempt[pair] = true;
        _isDividendExempt[address(this)] = true;
        _isDividendExempt[_burn] = true;

        LiquidityWallet = msg.sender;

        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);

        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
        emit OwnershipTransferred(msg.sender);
    }

    receive() external payable { }

    function getOwner() external view override returns (address) { return owner; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function totalSupply() external view returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) external view returns (uint256) { return _allowances[owner][spender]; }
    function setIsFeeExempt(address holder, bool exempt) external authorized { _isFeeExempt[holder] = exempt; }
    function setSwapEnabled(bool enabled) external authorized { SwapEnabled = enabled; }
    function setIsTransactionLimitExempt(address holder, bool exempt) external authorized { _isTransactionLimitExempt[holder] = exempt; }
    function setDistributionCriteria(uint256 minPeriod, uint256 minDistribution) external authorized { distributor.setDistributionCriteria(minPeriod, minDistribution); }
    function approveMax(address spender) external returns (bool) { return approve(spender, _totalSupply); }
    function transfer(address recipient, uint256 amount) external override returns (bool) { return _transfer(msg.sender, recipient, amount); }
    function getCirculatingSupply() public view returns (uint256) { return _totalSupply.sub(balanceOf(_burn)).sub(balanceOf(_zero));  }
    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) { return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply()); }
    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) { return getLiquidityBacking(accuracy) > target; }
    function isFeeExempt(address holder) public view returns (bool) { return _isFeeExempt[holder]; }
    function isTransactionLimitExempt(address holder) public view returns (bool) { return _isTransactionLimitExempt[holder]; }
    function isDividendExempt(address holder) public view returns (bool) { return _isDividendExempt[holder]; }

    /**
        @dev Triggers a BuyBack of specfic amount of tokens and sends to _burn address
    */
    function triggerBuyBack(uint256 amount) external authorized {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount} (
            0,
            path,
            _burn,
            block.timestamp
        );
    }

    /**
        @dev Sets MAX transaction limit
    */
    function setTransactionLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        MaxTransactionAmount = amount;
    }

    /**
        @dev Sets the fees
    */
    function setFees(uint256 liquidityFee, uint256 reflectionFee, uint256 marketingFee) external authorized {
        _liquidityFee = liquidityFee;
        _reflectionFee = reflectionFee;
        _marketingFee = marketingFee;
        _totalFee = liquidityFee.add(reflectionFee).add(marketingFee);
        
        require(_totalFee < maxFee); // 15% max fee
    }

    /**
        @dev Sets ditributor gas
    */
    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        _distributorGas = gas;
    }

    /**
        @dev Sets the receivers for liquidity and marketing fees
    */
    function setFeeReceivers(address liquidityWallet, address marketingWallet) external authorized {
        LiquidityWallet = liquidityWallet;
        MarketingWallet = payable(marketingWallet);
    }

    /**
        @dev Sets an address to be exempt from dividends (useful for dev wallet / liquidity wallet
    */
    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);

        _isDividendExempt[holder] = exempt;

        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    /**
        @dev Approves an allowance
    */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }
    
    /**
        @dev Transfers an amount from sender to recipient
    */
    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        if (_allowances[from][msg.sender] != _totalSupply) {
            _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(amount, "IA");
        }

        return _transfer(from, to, amount);
    }

    /**
        @dev Internal transfer method, dealing with fees and dividends
    */
    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        if (_inSwap) { return _basicTransfer(from, to, amount); }
        
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= MaxTransactionAmount || _isTransactionLimitExempt[from], "Transfer amount greater than MaxTransactionAmount");
        
        if (msg.sender != pair
            && !_inSwap
            && SwapEnabled
            && _balances[address(this)] >= SwapThreshold
        ) {
            _swapBack();
        }

        _balances[from] = _balances[from].sub(amount, "IB");

        uint256 amountReceived = _takeFeeAndReturnAmount(from, amount);

        _balances[to] = _balances[to].add(amountReceived);

        if (!_isDividendExempt[from]) { try distributor.setShare(from, _balances[from]) {} catch {} }
        if (!_isDividendExempt[to]) { try distributor.setShare(to, _balances[to]) {} catch {} }

        try distributor.process(_distributorGas) {} catch {}

        emit Transfer(from, to, amountReceived);

        return true;
    }

    function _basicTransfer(address from, address to, uint256 amount) internal returns (bool) {
        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
        return true;
    }

    function _swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(_targetLiquidity, _targetLiquidityDenominator) ? 0 : _liquidityFee;
        uint256 amountToLiquify = SwapThreshold.mul(dynamicLiquidityFee).div(_totalFee).div(2);
        uint256 amountToSwap = SwapThreshold.sub(amountToLiquify);

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
        uint256 totalBNBFee = _totalFee.sub(dynamicLiquidityFee.div(2));
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(_reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.sub(amountBNBLiquidity.add(amountBNBReflection));

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        
        MarketingWallet.transfer(amountBNBMarketing);
        
        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                owner,
                block.timestamp
            );

            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    /**
        @dev Retrieves fee details and returns amount after fees have been taken
    */
    function _takeFeeAndReturnAmount(address sender, uint256 amount) internal returns (uint256) {
        if (_isFeeExempt[sender]) { return amount; }

        uint256 feeAmount = amount.mul(_totalFee).div(_feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
}