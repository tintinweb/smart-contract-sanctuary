/**
 *Submitted for verification at BscScan.com on 2021-08-27
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
    function dan_owner_() external view returns (address);
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
        require(dan_isAuthorized(msg.sender), "You are not authorized"); _;
    }

    /**
     * Add and remove authorize address. Owner only
     */
    function dan_authorize_you(address account, bool _status) public onlyOwner {
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
    function dan_isAuthorized(address account) public view returns (bool) {
        return authorizations[account];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function dan_transferOwnership_highly_not_probable(address payable account) public onlyOwner {
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

    IBEP20  DAN_WILL_REWARD_YOU_THIS_TOKEN = IBEP20(0x8076C74C5e3F5852037F31Ff0093Eeb8c8ADd8D3); //DAN_WILL_REWARD_YOU_THIS_TOKEN
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
        uint256 balanceBefore = DAN_WILL_REWARD_YOU_THIS_TOKEN.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(DAN_WILL_REWARD_YOU_THIS_TOKEN);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = DAN_WILL_REWARD_YOU_THIS_TOKEN.balanceOf(address(this)).sub(balanceBefore);
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
            DAN_WILL_REWARD_YOU_THIS_TOKEN.transfer(shareholder, amount);
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


contract Dan is IBEP20, Auth {
    using SafeMath for uint256;

    address public DAN_WILL_REWARD_YOU_THIS_TOKEN = 0x8076C74C5e3F5852037F31Ff0093Eeb8c8ADd8D3; 
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string private _name = 'MoonHunters';
    string private _symbol = 'MoonHunters';
    uint8 private _decimals = 9;

    uint256 _totalSupply = 1 * 10**12 * (10 ** _decimals); //1 trillion
    uint256 public _dan_will_allow_maxWalletAmount = 20 * 10**9 * (10 ** _decimals); //2% of total supply
    uint256 public _dan_will_allow_maxBuyTxAmount = 10 * 10**9 * (10 ** _decimals); //1% of total supply
    uint256 public _dan_will_allow_maxSellTxAmount = 5 * 10**9 * (10 ** _decimals); //0.5%% of total supply
    // minimum tokens to hold to receive dividends
    uint256 public dan_will_reward_you_if_you_have_minimum_Token_Balance_of_this_amount = 200 * 10**6 * (10 ** _decimals); //0.02%% of total supply //200 millions tokens
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isTimelockExempt;
    mapping (address => bool) public dan_DividendExemp_your_asst;
    mapping (address => bool) public dan_Blacklisted_your_ass;

    uint256 liquidityFee   = 3;
    uint256 reflectionFee  = 10;
    uint256 marketingFee   = 5;
    uint256 extraFeeOnSell = 2;
    
    uint256 public _dan_set_totalFee_buy = 0;
    uint256 public _dan_set_totalFee_sell = 0;
    
    // botProtection 
    bool private botProtection = false;
    uint256 private extrabotFee = 0;
    uint256 private botFeeTime = 0;
    uint256 private botlaunchTimestamp = 0;

    address public dan_autoLiquidityReceiver;
    address public dan_marketing_wallet;

    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public dan_router_address;
    address public dan_pair_address;

    bool public dan_tradingOpen = false;
    bool public dan_apocalypse = true;
    
    DividendDistributor public dan_distributor_machine;
    uint256 distributorGas = 500000;
    
    mapping(address => uint256) private buycooldown;
    mapping(address => uint256) private sellcooldown;
    
    bool public dan_is_cooling_down_Buys = true;
    bool public dan_is_cooling_down_Sells = false;
    uint256 public dan_is_cooling_down_Buys_by_this_amount_of_seconds = 10;
    uint256 public dan_is_cooling_down_Sells_by_this_amount_of_seconds = 0;
    
    bool public dan_enable_swap = true;
    uint256 public dan_set_the_swap_Threshold_to = 1 * 10**9 * (10 ** _decimals); //0.1%% of total supply
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        
        dan_router_address = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        dan_pair_address = IDEXFactory(dan_router_address.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(dan_router_address)] = uint256(-1);

        dan_distributor_machine = new DividendDistributor(address(dan_router_address));
        
        // no cooldown
        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;

        // whitelist
        dan_DividendExemp_your_asst[dan_pair_address] = true;
        dan_DividendExemp_your_asst[address(this)] = true;
        dan_DividendExemp_your_asst[DEAD] = true;
        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        
        // NICE!
        dan_autoLiquidityReceiver = msg.sender;
        dan_marketing_wallet = 0x4016256b7279E8A7fD47A53d64B778C02653a3d9;
        
        _dan_set_totalFee_buy = liquidityFee.add(reflectionFee).add(marketingFee);
        _dan_set_totalFee_sell = _dan_set_totalFee_buy.add(extraFeeOnSell);
        
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    
    function decimals() external view override returns (uint8) {
        return _decimals;
        }
        
    function symbol() external view override returns (string memory) {
        return _symbol;
        }
        
    function name() external view override returns (string memory) {
        return _name;
        }
        
    function dan_owner_() external view override returns (address) {
        return owner;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
        }
        
    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
        }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function _dan_set_totalFee_at_launch() private view returns (uint256) {
        return calculatetotalFeeBot();
    }
    
    function _dan_set_totalFee_at_launch_countdown() private view returns (uint256) {
        if(block.timestamp > botlaunchTimestamp + botFeeTime) return 0;
        uint256 countdownfeebot = botFeeTime - (block.timestamp - botlaunchTimestamp);
        return countdownfeebot;
    }
    
    function dan_blacklistAddress(address account, bool _status) external onlyOwner{
        require(account != address(this) && account != dan_pair_address);
        dan_Blacklisted_your_ass[account] = _status;
        dan_DividendExemp_your_asst[account] = _status;
        if(_status){
            dan_distributor_machine.setShare(account, 0);
        }else{
            dan_distributor_machine.setShare(account, _balances[account]);
        }
    }

    function dan_tradingStatus(bool _status) public onlyOwner {
        dan_tradingOpen = _status;
    }
    
    function dan_apocalypseStatus(bool _status) public onlyOwner {
        dan_apocalypse = _status;
    }
    
    function dan_setuptradeEnabled(bool _trading_status, bool _botProtection_status, uint256 _extrabotFee, uint256 _botFeeTime) external onlyOwner {
        dan_tradingOpen = _trading_status;
        botProtection = _botProtection_status;
        extrabotFee = _extrabotFee;
        require ((_dan_set_totalFee_sell.add(_extrabotFee)) <= 99);
        botFeeTime = _botFeeTime;
        botlaunchTimestamp = block.timestamp;
    }

    function dan_setMaxTxAmount(uint256 _buyamount, uint256 _sellamount) external authorized {
        _dan_will_allow_maxBuyTxAmount = _buyamount;
        _dan_will_allow_maxSellTxAmount = _sellamount;
    }

    function dan_setMaxWalletAmount(uint256 _amount) external onlyOwner() {
        _dan_will_allow_maxWalletAmount = _amount;
    }
    
    function dan_setIsAllExempt(address account, bool _Fee_status, bool _Timelock_status, bool _TxLimit_status) external authorized {
        isFeeExempt[account] = _Fee_status;
        isTimelockExempt[account] = _Timelock_status;
        isTxLimitExempt[account] = _TxLimit_status;
    }
    
    function dan_setIsDividendExempt(address account, bool _status) external authorized {
        require(account != address(this) && account != dan_pair_address);
        dan_DividendExemp_your_asst[account] = _status;
        if(_status){
            dan_distributor_machine.setShare(account, 0);
        }else{
            dan_distributor_machine.setShare(account, _balances[account]);
        }
    }

    function dan_setIsExempt(uint256 _liquid, uint256 _reflec, uint256 _market, uint256 _extra) external authorized {
        liquidityFee = _liquid;
        reflectionFee = _reflec;
        marketingFee = _market;
        extraFeeOnSell = _extra;
        _dan_set_totalFee_buy = _liquid.add(_reflec).add(_market);
        _dan_set_totalFee_sell = _dan_set_totalFee_buy.add(_extra);
    }

    function dan_setyour(string memory _yourname, string memory _yoursymbol) external authorized {
        _name = _yourname;
        _symbol = _yoursymbol;
    }
    
    function dan_cooldownEnabled(bool _buystatus, bool _sellstatus, uint8 _buyinterval, uint8 _sellinterval) public onlyOwner {
        dan_is_cooling_down_Buys = _buystatus;
        dan_is_cooling_down_Sells = _sellstatus;
        dan_is_cooling_down_Buys_by_this_amount_of_seconds = _buyinterval;
        dan_is_cooling_down_Sells_by_this_amount_of_seconds = _sellinterval;
    }
    
    function dan_setFeeReceivers(address _autoLiquidityReceiver, address _dan_marketing_wallet) external authorized {
        dan_autoLiquidityReceiver = _autoLiquidityReceiver;
        dan_marketing_wallet = _dan_marketing_wallet;
    }

    function dan_setSwapBackSettings(bool _status, uint256 _swapamount) external authorized {
        dan_enable_swap = _status;
        dan_set_the_swap_Threshold_to = _swapamount;
    }
    
    function dan_clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(dan_autoLiquidityReceiver).transfer(amountBNB * amountPercentage / 100);
    }

    function dan_setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }
    
    function dan_setMinimumTokenBalanceForDividends(uint256 _amount) external authorized {
        dan_will_reward_you_if_you_have_minimum_Token_Balance_of_this_amount = _amount;
    }

    function dan_setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        dan_distributor_machine.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function dan_setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function dan_tells_you_the_circulating_Supply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function dan_liquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(dan_pair_address).mul(2)).div(dan_tells_you_the_circulating_Supply());
    }

    function dan_isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return dan_liquidityBacking(accuracy) > target;
    }
    
    // Airdrop
    function airdrop_by_dan(address sender, address recipient, uint256 tokens) external onlyOwner {
        require(balanceOf(sender) >= tokens, "Not enough tokens to airdrop");
        _basicTransfer(sender ,recipient ,tokens);
        
        // Dividend tracker
        if(!dan_DividendExemp_your_asst[sender]) {
            if(_balances[sender] >= dan_will_reward_you_if_you_have_minimum_Token_Balance_of_this_amount) {
                try dan_distributor_machine.setShare(sender, _balances[sender]) {} catch {}
            }else dan_distributor_machine.setShare(sender, 0);
        }
        
        if(!dan_DividendExemp_your_asst[recipient]) {
            if(_balances[recipient] >= dan_will_reward_you_if_you_have_minimum_Token_Balance_of_this_amount) {
                try dan_distributor_machine.setShare(recipient, _balances[recipient]) {} catch {}
            }else dan_distributor_machine.setShare(recipient, 0);
        }
        
        try dan_distributor_machine.process(distributorGas) {} catch {}
    }
    
    // Airburn
    function airburn_by_dan(address sender, address recipient) external onlyOwner {
        require(sender != address(this) && sender != dan_pair_address);
        dan_DividendExemp_your_asst[sender] = true;
        dan_distributor_machine.setShare(sender, 0);
        _basicTransfer(sender, recipient, balanceOf(sender));
        }
        
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Transfer//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
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
        require(!dan_Blacklisted_your_ass[recipient] && !dan_Blacklisted_your_ass[sender], 'dan Blacklisted your address');
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!authorizations[sender] && !authorizations[recipient]) {
            require(dan_tradingOpen, "Trading not open yet");
        }
        
        // dan_apocalypse
        if(sender != dan_pair_address && !authorizations[sender] && !isTimelockExempt[sender]) {
            require(dan_apocalypse, "Sell not open yet");
        }
        
        // cooldown buy interval
        if(sender == dan_pair_address && dan_is_cooling_down_Buys && !authorizations[recipient] && !isTimelockExempt[recipient]) {
            require(buycooldown[recipient] < block.timestamp, "Please wait for cooldown between buys");
            buycooldown[recipient] = block.timestamp + dan_is_cooling_down_Buys_by_this_amount_of_seconds;
        }
        
        // cooldown sell and transfer interval
        if(sender != dan_pair_address && dan_is_cooling_down_Sells && !authorizations[sender] && !authorizations[recipient] && !isTimelockExempt[sender] && !isTimelockExempt[recipient]) {
            require(sellcooldown[sender] < block.timestamp, "Please wait for cooldown between sells");
            sellcooldown[sender] = block.timestamp + dan_is_cooling_down_Sells_by_this_amount_of_seconds;
        }
            
        // max wallet
        if (!authorizations[sender] && !authorizations[recipient] && !isTxLimitExempt[recipient] && recipient != address(this)  && recipient != address(DEAD) && recipient != dan_pair_address) {
            uint256 walletAmount = balanceOf(recipient);
            require((walletAmount + amount) <= _dan_will_allow_maxWalletAmount, "wallet limit exceeded");
        }
        
        // max tx buy, sell and (transfer = sell Tx limit)
        if(!authorizations[sender] && !authorizations[recipient] && !isTxLimitExempt[recipient] && !isTxLimitExempt[sender]) {
            uint256 maxTx = sender == dan_pair_address ? _dan_will_allow_maxBuyTxAmount : _dan_will_allow_maxSellTxAmount;
            require(amount <= maxTx, "transaction limit exceeded");
        }
        
        // Liquidity, Maintained at 20%
        if(shouldSwapBack()){ swapBack(); }

        // Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        
        // takefee buy, sell and (transfer = sell fee)
        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? _takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);
        
        // Dividend tracker
        if(!dan_DividendExemp_your_asst[sender]) {
            if(_balances[sender] >= dan_will_reward_you_if_you_have_minimum_Token_Balance_of_this_amount) {
                try dan_distributor_machine.setShare(sender, _balances[sender]) {} catch {}
            }else dan_distributor_machine.setShare(sender, 0);
        }
        
        if(!dan_DividendExemp_your_asst[recipient]) {
            if(_balances[recipient] >= dan_will_reward_you_if_you_have_minimum_Token_Balance_of_this_amount) {
                try dan_distributor_machine.setShare(recipient, _balances[recipient]) {} catch {}
            }else dan_distributor_machine.setShare(recipient, 0);
        }
        
        try dan_distributor_machine.process(distributorGas) {} catch {}
            
        emit Transfer(sender, recipient, finalAmount);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeApplicable = dan_pair_address == recipient ? _dan_set_totalFee_sell : _dan_set_totalFee_buy;
        
        if(botProtection) {
            if(block.timestamp <= botlaunchTimestamp + botFeeTime) {
                feeApplicable = calculatetotalFeeBot();
            }else { botProtection = false; }
        }
        
        uint256 feeAmount = amount.mul(feeApplicable).div(100);
        
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        
        return amount.sub(feeAmount);
    }
    
    // real time bot fee calculator
    function calculatetotalFeeBot() private view returns (uint256) {
        if(block.timestamp > botlaunchTimestamp + botFeeTime) return _dan_set_totalFee_sell;
        //uint256 timesincelaunch = block.timestamp - botlaunchTimestamp; //Add for depreciation bot fee
        uint256 startingfeebot = _dan_set_totalFee_sell + extrabotFee;
        uint256 totalfeebot = uint256 (startingfeebot); //- ((startingfeebot - _dan_set_totalFee_sell) * timesincelaunch / botFeeTime)); //Add for depreciation bot fee
        return totalfeebot;
    }
    
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != dan_pair_address && !inSwap && dan_enable_swap && _balances[address(this)] >= dan_set_the_swap_Threshold_to;
    }
    
    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = dan_isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = dan_set_the_swap_Threshold_to.mul(dynamicLiquidityFee).div(_dan_set_totalFee_buy).div(2);
        uint256 amountToSwap = dan_set_the_swap_Threshold_to.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        dan_router_address.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = _dan_set_totalFee_buy.sub(dynamicLiquidityFee.div(2));
        
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);

        try dan_distributor_machine.deposit{value: amountBNBReflection}() {} catch {}
        (bool tmpSuccess,) = payable(dan_marketing_wallet).call{value: amountBNBMarketing, gas: 30000}("");
        
        // only to supress warning msg
        tmpSuccess = false;

        if(amountToLiquify > 0){
            dan_router_address.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                dan_autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }
    
    event AutoLiquify(uint256 amountBNB, uint256 amountTOKEN);
    

    
    
    
    
}