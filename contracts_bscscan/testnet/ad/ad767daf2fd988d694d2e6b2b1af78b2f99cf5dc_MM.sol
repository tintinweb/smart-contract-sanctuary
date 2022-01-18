/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/MilkMoney.sol

// contracts/MM.sol

pragma solidity ^0.8.11;


library SafeMath {
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
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
}

interface IBEP20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DividendDistributor {
    using SafeMath for uint256;
    address _token;
	
//    IBEP20 reflectingToken = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // Testnet - BUSD Token
//    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // Mainnet - WBNB Token
    IBEP20 reflectingToken = IBEP20(0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee); // Testnet - BUSD Token
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // Mainnet - WBNB Token

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    IDEXRouter router;
    mapping (address => Share) public shares;
    mapping (address => uint256) shareholderIndexes;
    uint256 public totalShares;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    address[] shareholders;
    mapping (address => uint256) shareholderClaims;
    uint256 public minPeriod = 1 hours; // min 1 hour delay
    uint256 public minDistribution = 1 * (10 ** 18); // 1 coin worth minimum auto send, 18 decimal places - try to make this equate to $1 worth
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 currentIndex;
    bool initialized;

    function decideCoin(address coinAddress) external onlyToken {
        IBEP20 newCoin = IBEP20(coinAddress);
        //emit ReflectingCoinChanged(address(reflectingToken), address(newCoin));
        reflectingToken = newCoin;
    }

    //event ReflectingCoinChanged(address oldCoinName, address newCoinName);

    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }
    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor(address _router) {
        router = _router != address(0)
            ? IDEXRouter(_router)
//            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Mainnet
  		: IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // Testnet
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minTokens, uint8 _decimalPlaces) external onlyToken {
        minPeriod = _minPeriod;
        minDistribution = uint256(_minTokens * (10 ** _decimalPlaces));
    }
    function setShare(address shareholder, uint256 amount) external onlyToken {
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
    function deposit() external payable onlyToken {
        uint256 balanceBefore = reflectingToken.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(reflectingToken);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amount = reflectingToken.balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }
    function process(uint256 gas) external onlyToken {
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
    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }
    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            reflectingToken.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    function claimDividend() external {
        distributeDividend(msg.sender);
    }
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }
}

contract MM is IBEP20, Ownable {
    using SafeMath for uint256;

    string constant _name = "MeeMoo";
    string constant _symbol = "MM";
    uint8 constant _decimals = 9;
    uint256 constant _totalSupply = 10 ** 12 * (10 ** _decimals);
    uint256 constant _maxHold = _totalSupply / 100;
    uint256 public liquidityFee = 0;
    uint256 public reflectionFee = 50;
    uint256 public totalFee = reflectionFee + liquidityFee;
    uint256 constant feeDenominator = 1000;
//  address private _reflectingTokenAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // Mainnet - BUSD Token
    address private _reflectingTokenAddress = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee; // Testnet - BUSD Token
    address private _coinDecider;
    function getReflectingTokenAddress() public view returns (address) {
        return _reflectingTokenAddress;
    }

//	address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // Mainnet - WBNB Token
    address constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // Testnet - WBNB Token

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address constant autoLiquidityReceiver = DEAD; // May remove without liquidity fee
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isMaxHoldExempt;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isDividendExempt;
    address[] pairs;
    IDEXRouter router;
    address pancakeV2BNBPair;
    DividendDistributor distributor;
    uint256 distributorGas = 600000;
    uint256 launchedAt;
    bool liquifyEnabled = false;
    bool feesOnNormalTransfers = false;
    bool swapEnabled = true;
    bool inSwap;
//    uint256 constant swapThreshold = _totalSupply / 5000; // 0.02% - Increasing this may stop the wallet from accumulating
    uint256 constant swapThreshold = _totalSupply / 1000; // 0.1%
    modifier isSwapping() { inSwap = true; _; inSwap = false; }

    // IBEP20 implementation
    receive() external payable { }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function name() external pure override returns (string memory) { return _name; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function getOwner() external view override returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function totalSupply() external pure override returns (uint256) { return _totalSupply; }

    constructor() Ownable() {
    //  router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Mainnet
		router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // Testnet
        pancakeV2BNBPair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = ~uint256(0);
        pairs.push(pancakeV2BNBPair);
        distributor = new DividendDistributor(address(router));
        isDividendExempt[DEAD] = true;
        isDividendExempt[pancakeV2BNBPair] = true;
        isDividendExempt[address(this)] = true;
        isMaxHoldExempt[DEAD] = true;
        isMaxHoldExempt[pancakeV2BNBPair] = true;
        isMaxHoldExempt[address(this)] = true;
        isMaxHoldExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[msg.sender] = true;
        _coinDecider = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // Set without affecting anything else just the address
    function setRewardsCoin(address coinAddress) public onlyDecider {
        distributor.decideCoin(coinAddress);
        _reflectingTokenAddress = coinAddress;
    }

    function setRewardsCoin(address coinAddress, uint256 _minPeriod, uint256 _minTokens, uint8 _decimalPlaces) public onlyDecider {
        distributor.decideCoin(coinAddress);
        distributor.setDistributionCriteria(_minPeriod, _minTokens, _decimalPlaces);
        _reflectingTokenAddress = coinAddress;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minTokens, uint8 _decimalPlaces) public onlyDecider {
        distributor.setDistributionCriteria(_minPeriod, _minTokens, _decimalPlaces);
    }

    function setDistributorSettings(uint256 gas) public onlyDecider {
        require(gas <= 1000000);
        distributorGas = gas;
    }

    modifier onlyDecider {
        require(_isCoinDecider(_msgSender()), "Only the coin decider can do this."); _;
    }

    function _isCoinDecider(address account) internal view returns (bool){
        return account == getCoinDecider();
    }

    function getCoinDecider() public view returns (address){
        return _coinDecider;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != ~uint256(0)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        if(shouldSwapBack()){ swapBack(); } // This is what engages the "reflections" mechanism
        if(!launched() && recipient == pancakeV2BNBPair){ require(_balances[sender] > 0); launch(); }
        if(!isMaxHoldExempt[recipient]){
            require((_balances[recipient] + (amount - amount * totalFee / feeDenominator))<= _maxHold, "Wallet cannot hold more than 1%");
        }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }
        try distributor.process(distributorGas) {} catch {}
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function approveMax(address spender) external returns (bool) {
        return approve(spender, ~uint256(0));
    }

    function getTotalFee() internal view returns (uint256) {
        if(launchedAt + 1 >= block.number){ return feeDenominator.sub(1); }
        return totalFee;
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if (isFeeExempt[sender] || isFeeExempt[recipient] || !launched()) return false;
        address[] memory liqPairs = pairs;
        for (uint256 i = 0; i < liqPairs.length; i++) {
            if (sender == liqPairs[i] || recipient == liqPairs[i]) return true;
        }
        return feesOnNormalTransfers;
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee()).div(feeDenominator);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pancakeV2BNBPair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    // Allows us to see how much supply is actually held outside of pcs and burn addresses, this can be used for calculating a dynamic swapThreshold
    function getActiveSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO)).sub(balanceOf(pancakeV2BNBPair));
    }

//    function claimDividend() external {
//        distributor.claimDividend();
//    }

    // May remove this
    function clearStuckBNB() public onlyDecider {
        payable(_coinDecider).transfer(address(this).balance);
    }

    // Can gut a lot of this to cut down on fees if no LP tax (all the liquidityfee stuff)
    // Basically you're just stopping some of it from being pulled with LP tax
    function swapBack() internal isSwapping {
        uint256 swapLiquidityFee = liquifyEnabled ? liquidityFee : 0;
        uint256 amountToLiquify = swapThreshold.mul(swapLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);
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
        )
        {
            uint256 amountBNB = address(this).balance.sub(balanceBefore);
            uint256 totalBNBFee = totalFee.sub(swapLiquidityFee.div(2));
            uint256 amountBNBLiquidity = amountBNB.mul(swapLiquidityFee).div(totalBNBFee).div(2);
            uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
            try distributor.deposit{value: amountBNBReflection}() {} catch {}
            if(amountToLiquify > 0)
            {
                try router.addLiquidityETH{ value: amountBNBLiquidity }(
                    address(this),
                    amountToLiquify,
                    0,
                    0,
                    autoLiquidityReceiver,
                    block.timestamp
                ) {} catch {}
            }
        } catch {}
    }

}