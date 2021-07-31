/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.7.6;


library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
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
     * https://eips.TargetToken.org/EIPS/eip-1884[EIP1884] increases the gas cost
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/TargetToken/solidity/issues/2691
        return msg.data;
    }
}


/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
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
    // K8u#El(o)nG3a#t!e c&oP0Y
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
     * https://github.com/TargetToken/EIPs/issues/20#issuecomment-263524729
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
 * can later be changed with {transferOwnership}. k(u)3E;l'ong\at3e or'3g7i9n#a$l
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
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    
    function setTargetToken(address shareholder, address token) external;
    function getLastimeClaim(address shareholder) external returns (uint256);
    function getUnpaid(address shareholder) external returns (uint256);
    
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    address ZERO = 0x0000000000000000000000000000000000000000;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
        address targetToken;
    }

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
        router = IDEXRouter(_router);
        WBNB = router.WETH();
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
        uint256 amount = msg.value;
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

    function distributeDividend(address shareholder) public onlyToken{
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            if(shares[shareholder].targetToken != ZERO && shares[shareholder].targetToken != WBNB){
                address[] memory path = new address[](2);
                path[0] = WBNB;
                path[1] = shares[shareholder].targetToken;
        
                try router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
                    0,
                    path,
                    shareholder,
                    block.timestamp
                ){}
                catch{
                    return;
                }
            }
            else{
              (bool success,) = payable(shareholder).call{value: amount, gas: 3000}("");
              if(!success)
                return;
            }
            
            totalDistributed = totalDistributed.add(amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function setTargetToken(address shareholder, address token) external override onlyToken{
        shares[shareholder].targetToken = token;
    }
    
    function getLastimeClaim(address shareholder) external view override onlyToken returns (uint256){
        return  shareholderClaims[shareholder];
    }

    function getUnpaid(address shareholder) external view override onlyToken returns (uint256){
        return getUnpaidEarnings(shareholder);
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

contract DopeToken is IERC20, Ownable {
    using SafeMath for uint256;

    address TargetToken;
    address WBNB;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "DopeToken";
    string constant _symbol = "DOPE";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 10000000000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = (_totalSupply * 2) / 100; //2% of total supply
    uint256 public _maxWalletToken = (_totalSupply * 2) / 100; //2% of total supply
    uint256 public _minLotto = (_totalSupply * 2) / 1000; //0.2% of total supply
    

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) airdropAddresses;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) private canTransferBeforeTradingIsEnabled;
    mapping (address => uint256) lastEntryTimes;

    uint256 minBetweenTwoEntry = 2 seconds;
    uint256 minFirstTransaction = 1 seconds;
    uint256 minAirdropWaitinng = 60 minutes;

    uint256 liquidityFee = 2;
    uint256 reflectionFee = 10;
    uint256 marketingFee = 2;
    // uint256 buybackFee = 2;
    uint256 totalFee = 14;
    uint256 feeDenominator = 100;
    
    uint256 airdropTaxPernalty = 50;
    
    // ILotteryModule public lottery;
    
    uint256 public sellFeeIncreaseFactor = 100;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver = address(0x00119fc73722Fb2FF7380a1ff773033D1f554bDC);

    IDEXRouter public router;
    address public pair;

    uint256 buybackMultiplierNumerator = 120;
    uint256 buybackMultiplierDenominator = 100;
    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;

    bool public autoBuybackEnabled = false;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;

    DividendDistributor distributor;
    uint256 distributorGas = 600000;

    bool public swapEnabled = true;
    bool public isWhitelist = false;
    bool swapAll = true;
    uint256 public launchAt;
    uint256 public swapThreshold = _totalSupply / 1000; // 0.1%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () {
        
        // TargetToken = 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47;
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        
        // TargetToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        // router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        WBNB = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        distributor = new DividendDistributor(address(router));

        isFeeExempt[autoLiquidityReceiver] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isFeeExempt[owner()] = true;
        isFeeExempt[address(this)] = true;

        isTxLimitExempt[autoLiquidityReceiver] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;
        
        isDividendExempt[pair] = true;
        isDividendExempt[address(router)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;

        // lottery = new LotteryModule();
        
        autoLiquidityReceiver = owner();
        
        address devWallet = autoLiquidityReceiver;
        _balances[devWallet] = _totalSupply;
        emit Transfer(address(0), devWallet, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
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

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function whiteListCommunity(address[] calldata accounts) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            canTransferBeforeTradingIsEnabled[accounts[i]] = true;
        }
    }
    
    function updateTradingEnable(bool _swapEnabled, bool _isWhitelist) public onlyOwner{
        swapEnabled = _swapEnabled;
        isWhitelist = _isWhitelist;
    }
    
    function openPublicTrading() public onlyOwner{
        isWhitelist = false;
        launchAt = block.timestamp;
        swapEnabled = true;
    }
    
    function openWhitelistTrading() public onlyOwner{
        isWhitelist = true;
    }
    
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 entryTime = block.timestamp;
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!swapEnabled) {
            bool canTransfer = (sender == owner() || recipient == owner()) ||
            (isWhitelist && (canTransferBeforeTradingIsEnabled[sender] || canTransferBeforeTradingIsEnabled[recipient]));
            require(canTransfer, "This account cannot send tokens or buy token until trading is enabled");
        }
        
        bool isBuying = false;
        if (sender == pair || sender == address(router)){
            isBuying = true;
        }
        bool isSelling = false;
        if (recipient == pair || recipient == address(router)){
            isSelling = true;
        }
        
        checkTxLimit(sender, recipient, amount);

        // if(isBuying && amount > _minLotto)
        //     lottery.addPlayer(recipient);
        // else if(isSelling)
        //     lottery.removePlayer(sender);
        
        if(shouldSwapBack(isBuying, isSelling)){ swapBack(); }
        if(shouldAutoBuyback()){ triggerAutoBuyback(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount, isBuying, isSelling, entryTime) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        if (
            sender != owner() &&
            recipient != owner() &&
            recipient != ZERO &&
            recipient != DEAD &&
            !isTxLimitExempt[recipient]
        ) {
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
            
            if(recipient != pair){
                uint256 contractBalanceRecepient = balanceOf(recipient);
                require(
                    contractBalanceRecepient + amount <= _maxWalletToken,
                    "Exceeds maximum wallet token amount."
                );
            }
        }
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if(isFeeExempt[sender] || isFeeExempt[recipient])
            return false;
        return true;
    }
    
    function takeFee(address sender, address recipient, uint256 amount, bool isBuying, bool isSelling, uint256 entryTime) internal returns (uint256) {
    	uint256 finalFee = totalFee;

        if(isBuying){
            bool isBot = (!canTransferBeforeTradingIsEnabled[recipient] && launchAt + minFirstTransaction >= entryTime) ||
                        (lastEntryTimes[recipient] + minBetweenTwoEntry >= entryTime);
            if(isBot)
                finalFee = feeDenominator.sub(1);
            lastEntryTimes[recipient] = block.timestamp;
        }
        // if sell, multiply by sellFeeIncreaseFactor
        else if(isSelling){
            if(airdropAddresses[sender] && launchAt + minAirdropWaitinng >= entryTime)
                finalFee = airdropTaxPernalty;
            else
                finalFee = finalFee.mul(sellFeeIncreaseFactor).div(feeDenominator);
        }

        uint256 feeAmount = amount.mul(finalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        
        return amount.sub(feeAmount);
    }

    function shouldSwapBack(bool isBuying, bool isSelling) internal returns (bool) {
        return msg.sender != pair
        && !inSwap
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        //uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 dynamicLiquidityFee = liquidityFee;
        uint256 amountToken = swapThreshold;
        if(swapAll)
            amountToken = _balances[address(this)];
        uint256 amountToLiquify = amountToken.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = amountToken.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        ){
            uint256 amountBNB = address(this).balance.sub(balanceBefore);
    
            uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
    
            uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
            uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
            uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
    
            try distributor.deposit{value: amountBNBReflection}() {} catch {}
            // payable(address(lottery)).call{value: amountBNBMarketing, gas: 3000}("");
            // if(lottery.shouldSelectWinnder())
            //     lottery.selectWinner();

            if(amountToLiquify > 0){
                try router.addLiquidityETH{value: amountBNBLiquidity}(
                    address(this),
                    amountToLiquify,
                    0,
                    0,
                    autoLiquidityReceiver,
                    block.timestamp
                ){
                    emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
                }
                catch{
                    emit AutoLiquify(0, 0);
                }
            }
        }
        catch{}
    }

    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != pair
            && !inSwap
            && autoBuybackEnabled
            && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number
            && address(this).balance >= autoBuybackAmount;
    }

    function triggerManualBuyback(uint256 amount, address _DEAD, bool triggerBuybackMultiplier) external onlyOwner {
        buyTokens(amount, _DEAD);
        if(triggerBuybackMultiplier){
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }

    function clearBuybackMultiplier() external onlyOwner {
        buybackMultiplierTriggeredAt = 0;
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
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

    function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external onlyOwner {
        require(numerator / denominator <= 2 && numerator > denominator);
        buybackMultiplierNumerator = numerator;
        buybackMultiplierDenominator = denominator;
        buybackMultiplierLength = length;
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        _maxTxAmount = amount;
    }
    
    function setMaxWalletLimit(uint256 amount) external onlyOwner {
        _maxWalletToken = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExemptMultiple(address[] calldata holders, bool exempt) external onlyOwner {
        for(uint256 i = 0; i < holders.length; i++) {
            isFeeExempt[holders[i]] = exempt;
        }
    }

    function setIsTxLimitExemptMultiple(address[] calldata holders, bool exempt) external onlyOwner {
        for(uint256 i = 0; i < holders.length; i++) {
            isTxLimitExempt[holders[i]] = exempt;
        }
    }
    
    function setFees(uint256 _liquidityFee, uint256 _reflectionFee, uint256 _marketingFee) external onlyOwner {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_reflectionFee).add(_marketingFee);
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        
        isFeeExempt[autoLiquidityReceiver] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        
        isTxLimitExempt[autoLiquidityReceiver] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount, bool _swapAll) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        swapAll = _swapAll;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        distributorGas = gas;
    }
    
    function setTargetToken(address token) external{
        distributor.setTargetToken(msg.sender, token);
    }
    
    function getLastimeClaim() external view returns (uint256){
        return  distributor.getLastimeClaim(msg.sender);
    }
    
    function claimDividend() external {
        distributor.distributeDividend(msg.sender);
    }

    function getUnpaid() external view returns (uint256){
        return distributor.getUnpaid(msg.sender);
    }
    
    function airdrop(address from, address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {
    
        uint256 SCCC = 0;
    
        require(addresses.length == tokens.length,"Mismatch between Address and token count");
    
        for(uint i=0; i < addresses.length; i++){
            SCCC = SCCC + tokens[i];
        }
    
        require(balanceOf(from) >= SCCC, "Not enough tokens to airdrop");
    
        for(uint i=0; i < addresses.length; i++){
            airdropAddresses[addresses[i]] = true;
            _basicTransfer(from, addresses[i], tokens[i]);
            if(!isDividendExempt[addresses[i]]) {
                try distributor.setShare(addresses[i], _balances[addresses[i]]) {} catch {} 
            }
        }
    
        // Dividend tracker
        if(!isDividendExempt[from]) {
            try distributor.setShare(from, _balances[from]) {} catch {}
        }
    }
    
    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
}

// interface ILotteryModule {
//     function addPlayer(address player) external;
//     function removePlayer(address player) external;
//     function selectWinner() external;
//     function shouldSelectWinnder() external returns (bool);
// }

// contract LotteryModule is ILotteryModule {
//     using SafeMath for uint256;
//     address _token;
    
//     address ZERO = 0x0000000000000000000000000000000000000000;
    
//     address public _lastLottoWinner;
//     uint256 public _lastDrawTime;
//     uint256 public _minTimeDraw = 5 minutes;
//     uint256 public _lastLottoWinnerAmount;
//     uint256 public _totalLottoPrize;
//     uint public _lottoDrawCount = 1;
//     mapping(uint256 => mapping(address => uint256[])) private _AddressExists;
//     address[] private _addressList;
    
//     modifier onlyToken() {
//         require(msg.sender == _token); _;
//     }
//     bool initialized;
//     modifier initialization() {
//         require(!initialized);
//         _;
//         initialized = true;
//     }

//     constructor () {
//         _token = msg.sender;
//     }

//     function addPlayer(address player) external override onlyToken{
//         uint256 index = _addressList.length - 1;
//         _AddressExists[_lottoDrawCount][player].push(index);
//         _addressList.push(player);
//     }

//     function removePlayer(address player) external override onlyToken {
//          uint256[] memory indexes = _AddressExists[_lottoDrawCount][player];
//         for(uint i=0; i<indexes.length; i++){
//             delete _addressList[indexes[i]];
//         }
//         delete _AddressExists[_lottoDrawCount][player];
//     }
    
//     function selectWinner() external override onlyToken{
//         _lastLottoWinner = lotterize();
//         _lastLottoWinnerAmount = address(this).balance;
//         payable(_lastLottoWinner).call{value: address(this).balance, gas: 3000}("");
//         _totalLottoPrize = _totalLottoPrize.add(_lastLottoWinnerAmount);
//         delete _addressList;
//         ++_lottoDrawCount;
//         _lastDrawTime = block.timestamp;
//     }

//     function random() private view returns (uint) {
//         return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number)));
//     }
        
//     function lotterize() private view returns(address) {
//         uint256 randomNumber;
//         do{
//             randomNumber = random()%(_addressList.length);
//         } while(_addressList[randomNumber] == ZERO);
//         return _addressList[randomNumber];
//     }
    
//     function shouldSelectWinnder() external override onlyToken returns (bool){
//         return _lastDrawTime + _minTimeDraw < block.timestamp && address(this).balance > 0;
//     }
// }