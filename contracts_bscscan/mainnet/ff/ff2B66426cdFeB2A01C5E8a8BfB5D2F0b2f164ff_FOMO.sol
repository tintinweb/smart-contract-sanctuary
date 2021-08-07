/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

/*
** This token is rated: (UK)PEGI-16 / (US)R / (AU)MA **
** Contains: degen themes, experimental coarse language **
** Not recommended for apes under the age of 99 without guidance from parents, teachers, or guardians **

Maximum $FOMO

** Read the rules of engagement, for the game has changed **
1. The more you buy, the higher the buy tax (15% - 70%)
2. Prize pool and bonus pool are formed from taxes, this is for entertainment not investing
3. Prize pool claimable every 24 hours, bonus pool claimable every minute if you've -never- claimed prize pool!
4. If you sell you forfeit all unclaimed prizes which go to the bonus pool
5. Token always sells first, flat 5% sell tax up to 1500 tokens then scaling (5% - 42.5%)

Will you play the game, or will you just
______  ___                _____                                 
___   |/  /______ _____  _____(_)_______ ___ ____  _________ ___ 
__  /|_/ / _  __ `/__  |/_/__  / __  __ `__ \_  / / /__  __ `__ \
_  /  / /  / /_/ / __>  <  _  /  _  / / / / // /_/ / _  / / / / /
/_/  /_/   \__,_/  /_/|_|  /_/   /_/ /_/ /_/ \__,_/  /_/ /_/ /_/ 
________                          
___  __/______ _______ ___ ______ 
__  /_  _  __ \__  __ `__ \_  __ \
_  __/  / /_/ /_  / / / / // /_/ /
/_/     \____/ /_/ /_/ /_/ \____/ 



Telegram: t.me/iFOMOed
(if it's been created)

Part of cryptoweb.world | Discounts apply for Babearny and EarnAny holders (up to 7.5%)

Supply: 1,000,000
Initial Max Txn: 10,000
Initial Max Wallet: 20,000
Claims can be done through BSCScan, purchasing 1 token, or the dApp (when available)
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;


library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * C U ON THE MOON
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {

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
    function allowance(address owner, address spender) external view returns (uint256);

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
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
    function initialize() external;
    function setPrimaryDistributor(address distributor) external;
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function claimDividend(address shareholder) external;
    function getUnpaidEarnings(address shareholder) external view returns (uint256);
    function getPaidDividends(address shareholder) external view returns (uint256);
    function getTotalPaid() external view returns (uint256);
    function getClaimTime(address shareholder) external view returns (uint256);
    function getLostRewards(address shareholder, uint256 amount) external view returns (uint256);
    function countShareholders() external view returns (uint256);
}

contract DividendDistributor is IDividendDistributor {

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) public shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public totalSacrificed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 24 hours;
    uint256 public minDistribution = 1 * (10 ** 15);
    
    DividendDistributor primaryDistributor;
    bool isBonusPool = false;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor () {
    }
    
    function initialize() external override initialization {
        _token = msg.sender;
    }
    
    function setPrimaryDistributor(address distributor) external override onlyToken {
        require(!isBonusPool);
        primaryDistributor = DividendDistributor(distributor);
        isBonusPool = true;
        minPeriod = 1 minutes;
    }
    
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
            shares[shareholder].totalExcluded = getCumulativeDividends(amount);
            shareholderClaims[shareholder] = block.timestamp;
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }
        
        bool sharesIncreased = shares[shareholder].amount < amount;
        uint256 unpaid = getUnpaidEarnings(shareholder);
        
        if(sharesIncreased){
            if (shouldDistribute(shareholder, unpaid))
                distributeDividend(shareholder, unpaid);
            
            shares[shareholder].totalExcluded = shares[shareholder].totalExcluded + getCumulativeDividends(amount - shares[shareholder].amount);
        }
        
        totalShares = (totalShares - shares[shareholder].amount) + amount;
        shares[shareholder].amount = amount;
        
        if (!sharesIncreased) {
            if (address(this).balance < unpaid) unpaid = address(this).balance;
            totalSacrificed = totalSacrificed + unpaid;
            payable(_token).transfer(unpaid);
        }
    }

    function deposit() external payable override {
        uint256 amount = msg.value;

        totalDividends = totalDividends + amount;
        dividendsPerShare = dividendsPerShare + ((dividendsPerShareAccuracyFactor * amount) / totalShares);
    }

    function shouldDistribute(address shareholder, uint256 unpaidEarnings) internal view returns (bool) {
	   if(!isBonusPool)
            return shareholderClaims[shareholder] + minPeriod < block.timestamp && unpaidEarnings > minDistribution;
        else {
    	    return getPrimaryRealised(shareholder) == 0 && shareholderClaims[shareholder] + minPeriod < block.timestamp;
        }
            
    }
    
    function getClaimTime(address shareholder) external override view onlyToken returns (uint256) {
        if (shareholderClaims[shareholder] + minPeriod <= block.timestamp || isBonusPool)
            return 0;
        else
            return (shareholderClaims[shareholder] + minPeriod) - block.timestamp;
    }

    function distributeDividend(address shareholder, uint256 unpaidEarnings) internal {
        if(shares[shareholder].amount == 0){ return; }

        if(unpaidEarnings > 0){
            totalDistributed = totalDistributed + unpaidEarnings;
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised + unpaidEarnings;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            payable(shareholder).transfer(unpaidEarnings);
        }
    }

    function claimDividend(address shareholder) external override onlyToken {
        require(shouldDistribute(shareholder, getUnpaidEarnings(shareholder)), "Dividends not available yet");
        distributeDividend(shareholder, getUnpaidEarnings(shareholder));
    }

    function getUnpaidEarnings(address shareholder) public view override onlyToken returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }
    
    function getPaidDividends(address shareholder) external view override onlyToken returns (uint256) {
        return shares[shareholder].totalRealised;
    }
    
    function getTotalPaid() external view override onlyToken returns (uint256) {
        return totalDistributed;
    }
    
    function countShareholders() external view override onlyToken returns (uint256) {
        return shareholders.length;
    }
    
    function getLostRewards(address shareholder, uint256 amount) external view override onlyToken returns (uint256) {
        if (isBonusPool) { 
    	    if (shares[shareholder].amount > 0 && getPrimaryRealised(shareholder) == 0) return 0;
        }
        return getCumulativeDividends(amount) - shares[shareholder].totalRealised;
    }
    
    function getPrimaryRealised(address shareholder) internal view returns (uint256) {
        (
	    uint256 amount,
        uint256 totalExcluded,
        uint256 totalRealised
	    ) = primaryDistributor.shares(shareholder);
	    return totalRealised;
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        if(share == 0){ return 0; }
        return (share * dividendsPerShare) / dividendsPerShareAccuracyFactor;
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

contract FOMO is IERC20, Ownable {
    using Address for address;
    
    address WBNB;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    IERC20[] discountTokens;
    uint256[] discountTokenMaxWallet;

    string constant _name = "Maximum";
    string constant _symbol = "FOMO";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = (_totalSupply * 1) / 100;
    uint256 public _maxWalletSize = (_totalSupply * 2) / 100;

    mapping (address => uint256) _balances;
    mapping (address => uint256) soldAt;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) rewardsClaimed;
    mapping (address => bool) airDropped;
    mapping (address => uint256) airDropVestingPeriod;
    mapping (address => uint256) lastSell;

    uint256 liquidityFee = 200;
    uint256 buybackFee = 150;
    uint256 reflectionFee = 950;
    uint256 bonusPercent = 25;
    uint256 marketingFee = 200;
    uint256 totalFee = 1500;
    uint256 feeDenominator = 10000;
    uint256 public _sellMultiplierNumerator = 33;
    uint256 public _sellMultiplierDenominator = 100;
    uint256 public _dumpProtectionNumerator = 250;
    uint256 public _dumpProtectionDenominator = 100 * _maxTxAmount;
    uint256 public _dumpProtectionThreshold = 3;
    uint256 public _dumpProtectionTimer = 2;
    uint256 public _discountNumerator = 50;
    uint256 public _discountDenominator = 100;
    bool public rewardsActive = true;

    address public autoLiquidityReceiver;
    address payable public marketingFeeReceiver;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address public pair;

    uint256 public launchedAt;
    uint256 public launchedTime;

    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;

    bool public autoBuybackEnabled = false;
    bool public autoBonusDeposit = false;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;

    DividendDistributor public distributor;
    DividendDistributor public bonusDistributor;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 2000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () {
        router = IDEXRouter(routerAddress);
        WBNB = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[msg.sender][routerAddress] = type(uint256).max;
        _allowances[address(this)][routerAddress] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[routerAddress] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[msg.sender] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;
        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = payable(msg.sender);


        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function airdrop(address[] memory addresses, uint256[] memory amounts, bool fromContract) external onlyOwner {
        require(addresses.length > 0 && amounts.length > 0 && addresses.length == amounts.length);
        address from = fromContract ? address(this) : msg.sender;
        for (uint i = 0; i < addresses.length; i++) {
            if(balanceOf(addresses[i]) == 0) {
                isDividendExempt[addresses[i]] = true;
                _allowances[from][addresses[i]] = amounts[i] * (10 ** _decimals);
                _transferFrom(from, addresses[i], amounts[i] * (10 ** _decimals));
            }
        }
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        checkTxLimit(sender, amount);
        
        if (recipient != pair && recipient != DEAD) {
            if (!isTxLimitExempt[recipient]) checkWalletLimit(recipient, amount);
        }

        if(!launched() && recipient == pair){ require(sender == owner(), "Contract not launched yet."); launch(); }

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = !isFeeExempt[sender] ? takeFee(sender, recipient, amount) : amount;
        
        if(shouldSwapBack(recipient)){ swapBack(amount); }
        if(shouldAutoBuyback(recipient)){ triggerAutoBuyback(); }
        
        _balances[recipient] = _balances[recipient] + amountReceived;

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }
        if(!isDividendExempt[sender] && !rewardsClaimed[sender]){ try bonusDistributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient] && !rewardsClaimed[recipient]){ try bonusDistributor.setShare(recipient, _balances[recipient]) {} catch {} }

        emit Transfer(sender, recipient, amountReceived);
        
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function checkWalletLimit(address recipient, uint256 amount) internal view {
        uint256 walletLimit = _maxWalletSize;
        if (_discountNumerator > 0) {
            uint256 discount = getDiscountRate(recipient);
            if (discount > 0)
                walletLimit = walletLimit + (walletLimit * discount) / totalFee;
        }
        require(_balances[recipient] + amount <= walletLimit, "Transfer amount exceeds the bag size.");
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }
    
    function setup() external onlyOwner {
        require(!launched());
        distributor = new DividendDistributor();
        distributor.initialize();
        bonusDistributor = new DividendDistributor();
        bonusDistributor.initialize();
        bonusDistributor.setPrimaryDistributor(address(distributor));
    }
    
    function setDistributors(address _distributor, address _bonusDistributor) external onlyOwner {
        distributor = DividendDistributor(_distributor);
        distributor.initialize();
        bonusDistributor = DividendDistributor(_bonusDistributor);
        bonusDistributor.initialize();
        bonusDistributor.setPrimaryDistributor(_distributor);
    }
    
    function setDiscountToken(address _discountToken, uint256 _discountMaxWallet) external onlyOwner {
        require(_discountToken.isContract());
        discountTokens.push(IERC20(_discountToken));
        discountTokenMaxWallet.push(_discountMaxWallet);
    }
    
    function removeDiscountToken() external onlyOwner {
        discountTokens.pop();
        discountTokenMaxWallet.pop();
    }
    
    function getDiscountRate(address account) internal view returns (uint256) {
        uint256 balance = discountTokens[0].balanceOf(account);
        uint256 discount;
        for (uint i = 0; i < discountTokens.length; i++) {
            balance = discountTokens[i].balanceOf(account);
            if (balance > discountTokenMaxWallet[i]) balance = discountTokenMaxWallet[i];
            if (balance > 0) discount = discount + (totalFee * balance * _discountNumerator) / (_discountDenominator * discountTokenMaxWallet[i]);
        }
        return discount;
    }

    function getTotalFee(bool selling, address sender, address recipient, uint256 amount) public view returns (uint256) {
        if(launchedAt + 3 >= block.number){ return feeDenominator - 1; }
        if(selling){
            if (amount <= swapThreshold * _dumpProtectionThreshold && lastSell[sender] + _dumpProtectionTimer < block.number)
                return (totalFee * _sellMultiplierNumerator) / _sellMultiplierDenominator;
            else
                return (totalFee * _sellMultiplierNumerator) / _sellMultiplierDenominator + (amount * totalFee * _dumpProtectionNumerator) / (_dumpProtectionDenominator);
        }
        uint256 extraFee = (amount * _dumpProtectionThreshold * totalFee * _dumpProtectionNumerator) / (_dumpProtectionDenominator*2);
        if (_discountNumerator == 0 || isDividendExempt[recipient]) 
            return totalFee + extraFee;
        
        return (totalFee - getDiscountRate(recipient)/2) + extraFee; 
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = (amount * getTotalFee(recipient == pair, sender, recipient, amount)) / feeDenominator;
        if (recipient == pair) {
            lastSell[sender] = block.number;
            if (_balances[sender] > soldAt[sender])
                soldAt[sender] = _balances[sender];
            if (!isDividendExempt[sender]){
                isDividendExempt[sender] = true;
                uint256 previousBalance = address(this).balance;
                distributor.setShare(sender, 0);
                bonusDistributor.setShare(sender,0);
                uint256 transferredBalance = address(this).balance - previousBalance;
                if (autoBonusDeposit && transferredBalance > 0)
                    try bonusDistributor.deposit{value: transferredBalance}() {} catch {}
            }
        }

        _balances[address(this)] = _balances[address(this)] + feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function shouldSwapBack(address recipient) internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && recipient == pair
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack(uint256 amount) internal swapping {
        uint256 swapHolderProtection = amount > swapThreshold * _dumpProtectionThreshold ? amount + (_dumpProtectionNumerator * amount * amount) / (_dumpProtectionDenominator*2) : amount;
        if (swapHolderProtection > _maxTxAmount) swapHolderProtection = _maxTxAmount;
        if (_balances[address(this)] < swapHolderProtection) swapHolderProtection = _balances[address(this)];
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = ((swapHolderProtection * dynamicLiquidityFee) / totalFee) / 2;
        uint256 amountToSwap = swapHolderProtection - amountToLiquify;

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

        uint256 amountBNB = address(this).balance - balanceBefore;
        uint256 totalBNBFee = totalFee - dynamicLiquidityFee / 2;

        uint256 amountBNBLiquidity = (amountBNB * dynamicLiquidityFee) / totalBNBFee / 2;
        uint256 amountBNBBonusPool = (amountBNB * reflectionFee * bonusPercent) / (totalBNBFee * 100);
        uint256 amountBNBPrizePool = ((amountBNB * reflectionFee) / totalBNBFee) - amountBNBBonusPool;
        uint256 amountBNBMarketing = amountBNB - (amountBNBLiquidity + amountBNBPrizePool + amountBNBBonusPool + (amountBNB * buybackFee) / totalBNBFee);
        
        if (rewardsActive){
            try distributor.deposit{value: amountBNBPrizePool}() {} catch {}
            try bonusDistributor.deposit{value: amountBNBBonusPool}() {} catch {}
        }
        
        marketingFeeReceiver.transfer(amountBNBMarketing);

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

    function shouldAutoBuyback(address recipient) internal view returns (bool) {
        return msg.sender != pair
            && !inSwap
            && autoBuybackEnabled
            && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number
            && recipient == pair
            && address(this).balance >= autoBuybackAmount;
    }

    function triggerManualBuyback(uint256 amount, bool triggerBuybackMultiplier) external onlyOwner {
        buyTokens(amount, DEAD);
        if(triggerBuybackMultiplier){
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }
    
    function manualDeposit(uint256 amount, bool bonus) external onlyOwner {
        if (bonus)
            bonusDistributor.deposit{value: amount}();
        else
            distributor.deposit{value: amount}();
    }
    
    function manualSell(uint256 amount) external onlyOwner {
        swapBack(amount);
    }
    
    function toggleRewards(bool toggle) external onlyOwner {
        rewardsActive = toggle;
    }

    function clearBuybackMultiplier() external onlyOwner {
        buybackMultiplierTriggeredAt = 0;
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator + autoBuybackAmount;
        if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external onlyOwner {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }
    
    function setAutoBonusDeposit(bool enabled) external onlyOwner {
        autoBonusDeposit = enabled;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
        launchedTime = block.timestamp;
    }

    function setTxLimit(uint256 numerator, uint256 divisor) external onlyOwner {
        require(numerator > 0 && divisor > 0 && divisor <= 10000);
        _maxTxAmount = (_totalSupply * numerator) / divisor;
    }
    
    function setMaxWallet(uint256 numerator, uint256 divisor) external onlyOwner() {
        require(numerator > 0 && divisor > 0 && divisor <= 10000);
        _maxWalletSize = (_totalSupply * numerator) / divisor;
    }
    
    function setSellMultiplier(uint256 numerator, uint256 divisor) external onlyOwner() {
        require(divisor > 0 && numerator / divisor <= 3, "Taxes too high");
        _sellMultiplierNumerator = numerator;
        _sellMultiplierDenominator = divisor;
    }
    
    function setDumpMultiplier(uint256 numerator, uint256 divisor, uint256 dumpThreshold, uint256 dumpTimer) external onlyOwner() {
        require(divisor > 0 && numerator / divisor <= 3 , "Taxes too high");
        _dumpProtectionNumerator = numerator;
        _dumpProtectionDenominator = divisor * _maxTxAmount;
        _dumpProtectionThreshold = dumpThreshold;
        _dumpProtectionTimer = dumpTimer;
    }
    
    function setDiscountMultiplier(uint256 numerator, uint256 divisor) external onlyOwner() {
        require(divisor > 0 && numerator / divisor <= 1);
        _discountNumerator = numerator;
        _discountDenominator = divisor;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair && holder != DEAD && holder != owner());
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
            bonusDistributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
            if (!rewardsClaimed[holder])
                bonusDistributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator, uint256 _bonusPercent) external onlyOwner {
        require(_bonusPercent <= 80, "Bonus pool too high");
        bonusPercent = _bonusPercent;
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee + _buybackFee + _reflectionFee + _marketingFee;
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 4, "Taxes too high");
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = payable(_marketingFeeReceiver);
    }

    function setSwapBackSettings(bool _enabled, uint256 _denominator) external onlyOwner {
        require(_denominator > 0);
        swapEnabled = _enabled;
        swapThreshold = _totalSupply / _denominator;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD) + balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return (accuracy * balanceOf(pair) * 2) / getCirculatingSupply();
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }
    
    function checkDiscountRate(address wallet) external view returns (uint256) {
        return getDiscountRate(wallet);
    }
    
    function getPoolStatistics() external view returns (uint256 totalRewards, uint256 totalRewardsPaid, uint256 rewardsSacrificed, uint256 totalBonuses, uint256 totalBonusesPaid, uint256 bonusSacrificed, uint256 rewardHolders, uint256 bonusHolders) {
        totalRewards = distributor.totalDividends();
        totalRewardsPaid = distributor.totalDistributed();
        rewardsSacrificed = distributor.totalSacrificed();
        totalBonuses = bonusDistributor.totalDividends();
        totalBonusesPaid = bonusDistributor.totalDistributed();
        bonusSacrificed = bonusDistributor.totalSacrificed();
        rewardHolders = distributor.countShareholders();
        bonusHolders = bonusDistributor.countShareholders();
    }
    
    function myStatistics(address wallet) external view returns (uint256 reward, uint256 bonusReward, uint256 rewardClaimed, uint256 bonusClaimed, uint256 rewardsLost, uint256 bonusLost) {
	    reward = distributor.getUnpaidEarnings(wallet);
	    bonusReward = bonusDistributor.getUnpaidEarnings(wallet);
	    rewardClaimed = distributor.getPaidDividends(wallet);
	    bonusClaimed = bonusDistributor.getPaidDividends(wallet);
	    rewardsLost = distributor.getLostRewards(wallet, soldAt[wallet]);
	    bonusLost = bonusDistributor.getLostRewards(wallet, _balances[wallet]);
	}
	
	function checkClaimTime(address wallet) external view returns (uint256) {
	    return distributor.getClaimTime(wallet);
	}
	
	function claimRewards(bool confirm) external {
	    require(confirm, "Please confirm reward claim - bonus rewards will be disabled");
	    distributor.claimDividend(msg.sender);
	    rewardsClaimed[msg.sender] = true;
	    bonusDistributor.setShare(msg.sender, 0);
	}
	
	function claimBonusRewards() external {
	    bonusDistributor.claimDividend(msg.sender);
	}

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
    //C U ON THE MOON
}