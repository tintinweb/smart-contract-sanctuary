/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-01
*/

/**


Vote for your next Reward Token in our Telegram
Reward Switching like BTC, ETH, Doge, and many others
Auto Rewards

Telegram: t.me/switchybsc

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
    function changeToken(address newToken, bool forceChange) external;
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function claimDividend(address shareholder) external;
    function checkUnpaidDividends(address shareholder) external view returns (uint256);
    function checkTokenChangeProgress() external view returns (uint256 count, uint256 progress);
}

contract DividendDistributor is IDividendDistributor {

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
        uint256 lastConversionNumerator;
        uint256 lastConversionDivisor;
    }

    IERC20 TOKEN;
    address WBNB;
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
    uint256 public tokenConversionNumerator;
    uint256 public tokenConversionDivisor;
    uint256 public tokenConversionCount;
    uint256 public tokenConversionProgress;

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

    constructor (address _router, address reflectToken, address _wbnb) {
        router = IDEXRouter(_router);
        TOKEN = IERC20(reflectToken);
        WBNB = _wbnb;
        _token = msg.sender;
    }
    
    function changeToken(address newToken, bool forceChange) external override onlyToken {
        require(tokenConversionCount <= tokenConversionProgress || forceChange, "Previous conversion not complete.");
        tokenConversionDivisor = TOKEN.balanceOf(address(this));
        require(totalDividends == 0 || tokenConversionDivisor > 0, "Requires at least some of initial token to calculate convertion rate.");
        
        if (tokenConversionDivisor > 0) {
            TOKEN.approve(address(router), tokenConversionDivisor);
            
            address[] memory path = new address[](3);
            path[0] = address(TOKEN);
            path[1] = WBNB;
            path[2] = address(newToken);
    
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenConversionDivisor,
                0,
                path,
                address(this),
                block.timestamp
            );
            
            tokenConversionCount = shareholders.length;
            tokenConversionProgress = 0;
        }
        
        TOKEN = IERC20(newToken);
        
        if (totalDividends > 0) {
            tokenConversionNumerator = TOKEN.balanceOf(address(this));
            
            totalDividends = (totalDividends * tokenConversionNumerator) / tokenConversionDivisor;
            dividendsPerShare = (dividendsPerShare * tokenConversionNumerator) / tokenConversionDivisor;
            totalDistributed = (totalDistributed * tokenConversionNumerator) / tokenConversionDivisor;
        }
    }
    
    function checkTokenChangeProgress() external override view returns (uint256 count, uint256 progress) {
        return (tokenConversionCount, tokenConversionProgress);
    }
    
    function processTokenChange(address shareholder) internal {
        if(shares[shareholder].lastConversionNumerator != tokenConversionNumerator || shares[shareholder].lastConversionDivisor != tokenConversionDivisor) {
            shares[shareholder].lastConversionNumerator = tokenConversionNumerator;
            shares[shareholder].lastConversionDivisor = tokenConversionDivisor;
            shares[shareholder].totalRealised = (shares[shareholder].totalRealised * tokenConversionNumerator) / tokenConversionDivisor;
            shares[shareholder].totalExcluded = (shares[shareholder].totalExcluded * tokenConversionNumerator) / tokenConversionDivisor;
        }
        tokenConversionProgress++;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            if(shares[shareholder].lastConversionNumerator != tokenConversionNumerator || shares[shareholder].lastConversionDivisor != tokenConversionDivisor) { processTokenChange(shareholder); }
            distributeDividend(shareholder, getUnpaidEarnings(shareholder));
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = (totalShares - shares[shareholder].amount) + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = TOKEN.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(TOKEN);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = TOKEN.balanceOf(address(this)) - balanceBefore;

        totalDividends = totalDividends + amount;
        dividendsPerShare = dividendsPerShare + ((dividendsPerShareAccuracyFactor * amount) / totalShares);
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
            
            if(shares[shareholders[currentIndex]].lastConversionNumerator != tokenConversionNumerator || shares[shareholders[currentIndex]].lastConversionDivisor != tokenConversionDivisor)
                processTokenChange(shareholders[currentIndex]);
            
            uint256 unpaidEarnings = getUnpaidEarnings(shareholders[currentIndex]);
            if(shouldDistribute(shareholders[currentIndex], unpaidEarnings)){
                distributeDividend(shareholders[currentIndex], unpaidEarnings);
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder, uint256 unpaidEarnings) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && unpaidEarnings > minDistribution;
    }

    function distributeDividend(address shareholder, uint256 unpaidEarnings) internal {
        if(shares[shareholder].amount == 0){ return; }

        if(unpaidEarnings > 0){
            totalDistributed = totalDistributed + unpaidEarnings;
            TOKEN.transfer(shareholder, unpaidEarnings);
            shareholderClaims[shareholder] = block.timestamp;
            
            shares[shareholder].totalRealised = shares[shareholder].totalRealised + unpaidEarnings;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend(address shareholder) external override {
        if(shares[shareholder].lastConversionNumerator != tokenConversionNumerator || shares[shareholder].lastConversionDivisor != tokenConversionDivisor) { processTokenChange(shareholder); }
        distributeDividend(shareholder, getUnpaidEarnings(shareholder));
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        
        if(shares[shareholder].lastConversionNumerator != tokenConversionNumerator || shares[shareholder].lastConversionDivisor != tokenConversionDivisor) {
            shareholderTotalDividends = (shareholderTotalDividends * tokenConversionNumerator) / tokenConversionDivisor;
            shareholderTotalExcluded = (shareholderTotalExcluded * tokenConversionNumerator) / tokenConversionDivisor;
        }

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }
    
    function checkUnpaidDividends(address shareholder) external view override returns (uint256) {
        return getUnpaidEarnings(shareholder);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return (share * dividendsPerShare) / dividendsPerShareAccuracyFactor;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        if(shares[shareholder].lastConversionNumerator != tokenConversionNumerator || shares[shareholder].lastConversionDivisor != tokenConversionDivisor)
            tokenConversionProgress++;
            
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract RewardSwitchingToken is IERC20, Ownable {
    using Address for address;
    
    address WBNB;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    IERC20 discountToken;
    uint256 discountTokenMaxWallet;
    address public currentlyServing;

    string _name = "Switch1";
    string _symbol = "Switch1";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = (_totalSupply * 1) / 100;
    uint256 public _maxWalletSize = (_totalSupply * 2) / 100;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) airDropped;
    mapping (address => uint256) airDropVestingPeriod;
    mapping (address => uint256) lastSell;

    uint256 liquidityFee = 400;
    uint256 buybackFee = 0;
    uint256 reflectionFee = 1100;
    uint256 marketingFee = 300;
    uint256 totalFee = 1800;
    uint256 feeDenominator = 10000;
    uint256 public _sellMultiplierNumerator = 120;
    uint256 public _sellMultiplierDenominator = 100;
    uint256 public _dumpProtectionNumerator = 50;
    uint256 public _dumpProtectionDenominator = 100 * _maxTxAmount;
    uint256 public _dumpProtectionThreshold = 3;
    uint256 public _dumpProtectionTimer = 15 seconds;
    uint256 public _discountNumerator = 80;
    uint256 public _discountDenominator = 100;
    
    mapping (uint256 => address) IDToRewardAddress;
    mapping (address => uint256) rewardAddressToID;
    
    uint256 totalRewards;
    bool switchingRewards;

    uint256 timeStampAtPreviousSwitch;

    uint256 timeBetweenSwitches = 300;// 5minute

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
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 2000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () {
        router = IDEXRouter(routerAddress);
        
        
        addRewardToList(0x2170Ed0880ac9A755fd29B2688956BD959F933F8);//ETH
        addRewardToList(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);//CAKE
        addRewardToList(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47);//ADA
        addRewardToList(0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE);//XRP
        addRewardToList(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c);//BTC
        addRewardToList(0xB5bCF4fAa81457e98f4609a2a3291dF64E246f01);//PARABOLIC
        
        
        WBNB = router.WETH();
        currentlyServing = IDToRewardAddress[1];
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[msg.sender][routerAddress] = type(uint256).max;
        _allowances[address(this)][routerAddress] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[routerAddress] = true;
        isDividendExempt[pair] = true;
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
    function symbol() external view returns (string memory) { return _symbol; }
    function name() external view returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function updateTokenDetails(string memory newName, string memory newSymbol) external onlyOwner {
        _name = newName;
        _symbol = newSymbol;
    }
    
    function addRewardToList(address rewardToken) public onlyOwner{
        require(rewardAddressToID[rewardToken] == 0);
        totalRewards++;
        IDToRewardAddress[totalRewards] = rewardToken;
        rewardAddressToID[rewardToken] = totalRewards;
    }
    
    function removeRewardFromList(address rewardToken) public onlyOwner{
        uint256 removedID = rewardAddressToID[rewardToken];
        require(removedID != 0 && totalRewards > 1 && currentlyServing != rewardToken);
        if(removedID == totalRewards){
            rewardAddressToID[rewardToken] = 0;
            IDToRewardAddress[removedID] = address(0);
        }else{
            uint256 lastRewardID = totalRewards;
            address lastReward = IDToRewardAddress[lastRewardID];
            IDToRewardAddress[removedID] = lastReward;
            rewardAddressToID[lastReward] = removedID;
            rewardAddressToID[rewardToken] = 0;
        }
        totalRewards = totalRewards - 1;
    }
    
    function airdrop(address[] memory addresses, uint256[] memory amounts, uint256 vestingPeriod, bool fromContract) external onlyOwner {
        require(addresses.length > 0 && amounts.length > 0 && addresses.length == amounts.length);
        address from = fromContract ? address(this) : msg.sender;
        for (uint i = 0; i < addresses.length; i++) {
            if(balanceOf(addresses[i]) == 0) {
                _allowances[from][addresses[i]] = amounts[i];
                _transferFrom(from, addresses[i], amounts[i]);
                airDropVestingPeriod[addresses[i]] = block.timestamp + vestingPeriod;
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
        
        if(block.timestamp - timeStampAtPreviousSwitch > timeBetweenSwitches && switchingRewards == false) autoSwitchReward();

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        
        if(shouldSwapBack(recipient)){ swapBack(amount); }
        if(shouldAutoBuyback(recipient)){ triggerAutoBuyback(); }
        
        _balances[recipient] = _balances[recipient] + amountReceived;

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function autoSwitchReward() private{
        switchingRewards = true;
        timeStampAtPreviousSwitch = block.timestamp;
        address currentReward = currentlyServing;
        address nextReward;
        if(rewardAddressToID[currentReward] < totalRewards){
            nextReward = IDToRewardAddress[rewardAddressToID[currentReward]+1];
        }
        else{
            nextReward = IDToRewardAddress[1];
        }
        distributor.changeToken(nextReward, true);
        switchingRewards = false;
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
            uint256 balance;
            balance = discountToken.balanceOf(recipient);
            if (balance > 0)
                walletLimit = walletLimit + (walletLimit * getDiscountRate(balance)) / totalFee;
        }
        require(_balances[recipient] + amount <= walletLimit, "Transfer amount exceeds the bag size.");
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }
    
    function setup(address reflectToken) external onlyOwner {
        require(!launched());
        currentlyServing = reflectToken;
        distributor = new DividendDistributor(routerAddress, currentlyServing, WBNB);
        discountTokenMaxWallet = 1;
    }
    
    function setDiscountToken(address _discountToken, uint256 _discountMaxWallet) external onlyOwner {
        require(_discountToken.isContract());
        discountToken = IERC20(_discountToken);
        _discountDenominator = (_discountDenominator * _discountMaxWallet) / discountTokenMaxWallet;
        discountTokenMaxWallet = _discountMaxWallet;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }
    
    function getDiscountRate(uint256 balance) internal view returns (uint256) {
        if (balance > discountTokenMaxWallet)
            balance = discountTokenMaxWallet;
        return (totalFee * balance * _discountNumerator) / _discountDenominator;
    }
    
    function checkDiscountRate(address wallet) external view returns (uint256) {
        return getDiscountRate(discountToken.balanceOf(wallet));
    }

    function getTotalFee(bool selling, address sender, address recipient, uint256 amount) public view returns (uint256) {
        if(launchedAt + 1 >= block.number){ return feeDenominator - 1; }
        if(selling){
            if (lastSell[sender] + _dumpProtectionTimer <= block.timestamp)
                return (totalFee * _sellMultiplierNumerator) / _sellMultiplierDenominator + (amount > swapThreshold * _dumpProtectionThreshold  ? ( amount * totalFee * _dumpProtectionNumerator) / _dumpProtectionDenominator : 0); 
            else
                return (totalFee * _sellMultiplierNumerator) / _sellMultiplierDenominator + (_maxTxAmount * totalFee * _dumpProtectionNumerator) / _dumpProtectionDenominator; 
        }
        if (_discountNumerator == 0 || isDividendExempt[recipient]) 
            return totalFee;
        uint256 balance = discountToken.balanceOf(recipient);
        if (balance == 0)
            return totalFee;
        return totalFee - getDiscountRate(balance);
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = (amount * getTotalFee(recipient == pair, sender, recipient, amount)) / feeDenominator;
        if (recipient == pair) lastSell[sender] = block.timestamp;

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
        uint256 swapHolderProtection = amount > swapThreshold * _dumpProtectionThreshold ? amount + (_dumpProtectionNumerator * amount * amount) / (_dumpProtectionDenominator * 2) : amount;
        if (_balances[address(this)] < swapHolderProtection) swapHolderProtection = _balances[address(this)];
        if (swapHolderProtection > _maxTxAmount) swapHolderProtection = _maxTxAmount;
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
        uint256 amountBNBReflection = (amountBNB * reflectionFee) / totalBNBFee;
        uint256 amountBNBMarketing = amountBNB - (amountBNBLiquidity + amountBNBReflection);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        
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
    
    function manualTokenPurchase(uint256 amount) external onlyOwner {
        try distributor.deposit{value: amount}() {} catch {}
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

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
        launchedTime = block.timestamp;
        timeStampAtPreviousSwitch = block.timestamp;
    }

    function setTxLimit(uint256 numerator, uint256 divisor) external onlyOwner {
        require(numerator > 0 && divisor > 0 && divisor <= 10000);
        _maxTxAmount = (_totalSupply * numerator) / divisor;
    }
    
    function setReflectToken(address newToken, bool forceChange) external onlyOwner {
        require(newToken.isContract(), "Enter valid contract address");
        distributor.changeToken(newToken, forceChange);
        currentlyServing = newToken;
    }
    
    function checkReflectTokenUpdate() external view onlyOwner returns (uint256 count, uint256 progress) {
        return distributor.checkTokenChangeProgress();
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
        require(divisor > 0 && numerator / divisor <= 2 , "Taxes too high");
        _dumpProtectionNumerator = numerator;
        _dumpProtectionDenominator = divisor * _maxTxAmount;
        _dumpProtectionThreshold = dumpThreshold;
        _dumpProtectionTimer = dumpTimer;
    }
    
    function setDiscountMultiplier(uint256 numerator, uint256 divisor) external onlyOwner() {
        require(divisor > 0 && numerator / divisor <= 1);
        _discountNumerator = numerator;
        _discountDenominator = divisor * discountTokenMaxWallet;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee + _buybackFee + _reflectionFee + _marketingFee;
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 4);
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

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
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
    
    function availableDividends(address account) external view returns (uint256) {
	    return distributor.checkUnpaidDividends(account);
	}
	
	function claimDividends() external {
	    distributor.claimDividend(msg.sender);
	    try distributor.process(distributorGas) {} catch {}
	}

    function processDividends() external {
	    try distributor.process(distributorGas) {} catch {}
	}

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
    //C U ON MARS
}