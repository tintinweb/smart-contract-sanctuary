// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
    Wrappers over Solidity's arithmetic operations with added overflow
    checks.

    Arithmetic operations in Solidity wrap on overflow. This can easily result
    in bugs, because programmers usually assume that an overflow raises an
    error, which is the standard behavior in high level programming languages.
    `SafeMath` restores this intuition by reverting the transaction when an
    operation overflows.

    Using this library instead of the unchecked operations eliminates an entire
    class of bugs, so it's recommended to use it always.
*/
library SafeMath {
    /**
        @dev Returns the addition of two unsigned integers, reverting on
        overflow.

        Counterpart to Solidity's `+` operator.

        Requirements:
        - Addition cannot overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
        @dev Returns the subtraction of two unsigned integers, reverting on
        overflow (when the result is negative).

        Counterpart to Solidity's `-` operator.

        Requirements:
        - Subtraction cannot overflow.
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
        @dev Returns the subtraction of two unsigned integers, reverting with custom message on
        overflow (when the result is negative).
        
        Counterpart to Solidity's `-` operator.

        Requirements:
        - Subtraction cannot overflow.
    */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
        @dev Returns the multiplication of two unsigned integers, reverting on
        overflow.
        
        Counterpart to Solidity's `*` operator.
        
        Requirements:
        - Multiplication cannot overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
        @dev Returns the integer division of two unsigned integers. Reverts on
        division by zero. The result is rounded towards zero.
        
        Counterpart to Solidity's `/` operator. Note: this function uses a
        `revert` opcode (which leaves remaining gas untouched) while Solidity
        uses an invalid opcode to revert (consuming all remaining gas).
        
        Requirements:
        - The divisor cannot be zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
        @dev Returns the integer division of two unsigned integers. Reverts with custom message on
        division by zero. The result is rounded towards zero.
        
        Counterpart to Solidity's `/` operator. Note: this function uses a
        `revert` opcode (which leaves remaining gas untouched) while Solidity
        uses an invalid opcode to revert (consuming all remaining gas).
        
        Requirements:
        - The divisor cannot be zero.
    */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b    c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
        @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
        Reverts when dividing by zero.
        
        Counterpart to Solidity's `%` operator. This function uses a `revert`
        opcode (which leaves remaining gas untouched) while Solidity uses an
        invalid opcode to revert (consuming all remaining gas).
        
        Requirements:
        - The divisor cannot be zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
        @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
        Reverts with custom message when dividing by zero.
        
        Counterpart to Solidity's `%` operator. This function uses a `revert`
        opcode (which leaves remaining gas untouched) while Solidity uses an
        invalid opcode to revert (consuming all remaining gas).
        
        Requirements:
        - The divisor cannot be zero.
    */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
    Generic BEP20 interface
*/
interface IBEP20 {
    /**
        @dev Returns the amount of tokens in existence.
    */
    function totalSupply() external view returns (uint256);

    /**
        @dev Returns the token decimals.
    */
    function decimals() external view returns (uint8);

    /**
        @dev Returns the token symbol.
    */
    function symbol() external view returns (string memory);

    /**
       @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
        @dev Returns the bep token owner.
    */
    function getOwner() external view returns (address);

    /**
        @dev Returns the amount of tokens owned by `account`.
    */
    function balanceOf(address account) external view returns (uint256);

    /**
        @dev Moves `amount` tokens from the caller's account to `recipient`.
        
        Returns a boolean value indicating whether the operation succeeded.
        
        Emits a {Transfer} event.
    */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
        @dev Returns the remaining number of tokens that `spender` will be
        allowed to spend on behalf of `owner` through {transferFrom}. This is
        zero by default.
        
        This value changes when {approve} or {transferFrom} are called.
    */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
        @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
        
        Returns a boolean value indicating whether the operation succeeded.
        
        IMPORTANT: Beware that changing an allowance with this method brings the risk
        that someone may use both the old and the new allowance by unfortunate
        transaction ordering. One possible solution to mitigate this race
        condition is to first reduce the spender's allowance to 0 and set the
        desired value afterwards:
        https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        
        Emits an {Approval} event.
    */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
        @dev Moves `amount` tokens from `sender` to `recipient` using the
        allowance mechanism. `amount` is then deducted from the caller's
        allowance.
        
        Returns a boolean value indicating whether the operation succeeded.
        
        Emits a {Transfer} event.
    */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
        @dev Emitted when `value` tokens are moved from one account (`from`) to
        another (`to`).
        
        Note that `value` may be zero.
    */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
        @dev Emitted when the allowance of a `spender` for an `owner` is set by
        a call to {approve}. `value` is the new allowance.
    */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
    Provides authorization for methods that are only executable by those authorised to do so.
*/
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
        @dev Function modifier to require caller to be contract owner
    */
    modifier onlyOwner() { require(isOwner(msg.sender), "!O"); _; }

    /**
        @dev Function modifier to require caller to be authorized
    */
    modifier authorized() { require(isAuthorized(msg.sender), "!A"); _; }

    /**
        @dev Authorize an address, callable by contract owner only.
    */
    function authorize(address adr) public onlyOwner { authorizations[adr] = true; }

    /**
        @dev Remove address' authorization, callable by contract owner only.
    */
    function unauthorize(address adr) public onlyOwner { authorizations[adr] = false; }

    /**
        @dev Check if an address is the contract owner.
    */
    function isOwner(address account) public view returns (bool) { return account == owner; }

    /**
        @dev Return address' authorization status.
    */
    function isAuthorized(address adr) public view returns (bool) { return authorizations[adr]; }

    /**
        @dev Transfer ownership to a new address. Caller must be the current owner. Leaves old owner authorized.
    */
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

    IBEP20 BUSD = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
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

    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = IDEXRouter(_router);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0){
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

        while(gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])){
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
        if (shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);

        if (amount > 0){
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
        if (shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

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
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTransactionLimitExempt;
    mapping (address => bool) isDividendExempt;

    // Addresses
    address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private _dead = 0x000000000000000000000000000000000000dEaD;
    address private _zero = 0x0000000000000000000000000000000000000000;

    // Token Details
    string constant _name = "Elf Coin";
    string constant _symbol = "ELFIE";
    uint8 constant _decimals = 9;
    uint256 private _totalSupply = 1_000_000_000_000_000 * (10 ** _decimals); // 1 quintillion
    uint256 public MaxTransactionAmount = _totalSupply.div(400); // 0.25%

    // Token Tax (Fees)
    uint256 public maxFee = 1500;
    uint256 private _liquidityFee = 200;
    uint256 private _buyBackFee = 200;
    uint256 private _reflectionFee = 700;
    uint256 private _marketingFee = 100;
    uint256 private _totalFee = 1200;
    uint256 private _feeDenominator = 10000;

    // Fee receiver and liquidity details
    address public AutoLiquidityReceiver;
    address public MarketingFeeReceiver;
    uint256 private _targetLiquidity = 25;
    uint256 private _targetLiquidityDenominator = 100;

    // BuyBack
    uint256 private _buybackMultiplierNumerator = 200;
    uint256 private _buybackMultiplierDenominator = 100;
    uint256 private _buybackMultiplierTriggeredAt;
    uint256 private _buybackMultiplierLength = 30 minutes;

    // Distribution
    DividendDistributor distributor;
    uint256 private _distributorGas = 500000;

    // Swapping
    bool public SwapEnabled = true;
    uint256 public SwapThreshold = _totalSupply / 2000; // 0.005%
    bool private _inSwap;
    modifier swapping() { _inSwap = true; _; _inSwap = false; }

    constructor (address _dexRouter) Auth(msg.sender) {
        router = IDEXRouter(_dexRouter);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        
        _allowances[address(this)][address(router)] = _totalSupply;
        
        WBNB = router.WETH();

        distributor = new DividendDistributor(_dexRouter);

        isFeeExempt[msg.sender] = true;

        isTransactionLimitExempt[msg.sender] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[_dead] = true;

        AutoLiquidityReceiver = msg.sender;
        MarketingFeeReceiver = msg.sender;

        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);

        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    /**
        @dev Returns the bep token owner.
    */ 
    function getOwner() external view override returns (address) { return owner; }

    /**
        @dev Returns the token decimals.
    */
    function decimals() external pure returns (uint8) { return _decimals; }

    /**
        @dev Returns the token symbol.
    */
    function symbol() external pure returns (string memory) { return _symbol; }

    /**
        @dev Returns the token name.
    */
    function name() external pure returns (string memory) { return _name; }

    /**
        @dev Returns the total supply
    */
    function totalSupply() external view returns (uint256) { return _totalSupply; }

    /**
        @dev Returns "balance of" an account.
    */
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }

    /**
        @dev Returns the allowance of a spender to holder
    */
    function allowance(address owner, address spender) external view returns (uint256) { return _allowances[owner][spender]; }

    /**
        @dev Triggers a BuyBack of specfic amount of tokens and sends to _dead address
    */
    function triggerNiceElfBuyBackAndSendToDeadWallet(uint256 amount) external authorized {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount} (0, path, _dead, block.timestamp);
    }

    /**
        @dev Sets an address to be exempt from fees
    */
    function setIsFeeExempt(address holder, bool exempt) external authorized { isFeeExempt[holder] = exempt; }

    /**
        @dev Sets an address to be exept from transaction limits
    */
    function setIsTransactionLimitExempt(address holder, bool exempt) external authorized { isTransactionLimitExempt[holder] = exempt; }

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
    function setFees(uint256 liquidityFee, uint256 buyBackFee, uint256 reflectionFee, uint256 marketingFee) external authorized {
        _liquidityFee = liquidityFee;
        _buyBackFee = buyBackFee;
        _reflectionFee = reflectionFee;
        _marketingFee = marketingFee;
        _totalFee = liquidityFee.add(buyBackFee).add(reflectionFee).add(marketingFee);
        
        require(_totalFee < maxFee); // 15% max fee
    }

    /**
        @dev Sets criteria for distribution of BUSD reflections
    */
    function setDistributionCriteria(uint256 minPeriod, uint256 minDistribution) external authorized { distributor.setDistributionCriteria(minPeriod, minDistribution); }

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
    function setFeeReceivers(address autoLiquidityReceiver, address marketingFeeReceiver) external authorized {
        require(autoLiquidityReceiver != address(0) && marketingFeeReceiver != address(0));

        AutoLiquidityReceiver = autoLiquidityReceiver;
        MarketingFeeReceiver = marketingFeeReceiver;
    }

    /**
        @dev Sets an address to be exempt from dividends (useful for dev wallet / liquidity wallet
    */
    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);

        isDividendExempt[holder] = exempt;

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
        @dev Approves the total supply to an address
    */
    function approveMax(address spender) external returns (bool) { return approve(spender, _totalSupply); }

    /**
        @dev Transfers an amount from sender to recipient
    */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    /**
        @dev Transfers an amount from sender to recipient
    */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "IA");
        }

        return _transfer(sender, recipient, amount);
    }

    /**
        @dev Internal transfer method, dealing with fees and dividends
    */
    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0) && recipient != address(0), "Tfr to or from 0 address");
        require(amount > 0, "Tfr amt <= 0");
        require(amount <= MaxTransactionAmount || isTransactionLimitExempt[sender], "Tfr amt > MaxTransactionAmount");
        
        if (_inSwap) { return _basicTransfer(sender, recipient, amount); }
        if (_shouldSwapBack()) { _swapBack(); }

        _balances[sender] = _balances[sender].sub(amount, "IB");

        uint256 amountReceived = _takeFeeAndReturnAmount(sender, amount);

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (!isDividendExempt[sender]) { try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if (!isDividendExempt[recipient]) { try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(_distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);

        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "IB");
        _balances[recipient] = _balances[recipient].add(amount);

        return true;
    }

    function _shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
            && !_inSwap
            && SwapEnabled
            && _balances[address(this)] >= SwapThreshold;
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
        uint256 amountBNBReflection = amountBNB.mul(_reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(_marketingFee).div(totalBNBFee);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}

        payable(MarketingFeeReceiver).transfer(amountBNBMarketing);
        
        if (amountToLiquify > 0) {
            uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);

            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                AutoLiquidityReceiver,
                block.timestamp
            );

            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    /**
        @dev Retrieves fee details and returns amount after fees have been taken
    */
    function _takeFeeAndReturnAmount(address sender, uint256 amount) internal returns (uint256) {
        if (isFeeExempt[sender]) { return amount; }

        uint256 feeAmount = amount.mul(_totalFee).div(_feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);

        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    /**
        @dev Retrieves the current circulating upply, removing _zero and _dead wallet balances
    */
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(_dead)).sub(balanceOf(_zero));
    }

    /**
        @dev Retrieves liquidity backing the token
    */
    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    /**
        @dev Retrieves fee details and returns amount after fees have been taken
    */
    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
}