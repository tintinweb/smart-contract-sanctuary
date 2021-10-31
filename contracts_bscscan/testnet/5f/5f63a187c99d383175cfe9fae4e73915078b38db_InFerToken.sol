/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

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

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
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
    ) external payable returns (uint amountToken, uint amountSwapBNB, uint liquidity);

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
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDividendForReward) external;
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

    address[] shareholders;
    mapping (address => uint256) public shareholderIndexes;
    mapping (address => uint256) public shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDividendForReward = 1000 * (10 ** 18);

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

    constructor () {
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDividendForReward) external override onlyToken {
        minPeriod = _minPeriod;
        minDividendForReward = _minDividendForReward;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        uint256 dividendAmount = amount;
        if(amount >= minDividendForReward && shares[shareholder].amount == 0){
            addShareholder(shareholder);
            dividendAmount = amount;
        }else if(amount < minDividendForReward){
            dividendAmount = 0;
            if(shares[shareholder].amount > 0)
                removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(dividendAmount);
        shares[shareholder].amount = dividendAmount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }
    receive() external payable { 
        deposit();
    }

    function deposit() public payable override {
        totalDividends = totalDividends.add(msg.value);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(msg.value).div(totalShares));
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
                && getUnpaidEarnings(shareholder) > 0;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            (bool success,) = payable(shareholder).call{value: amount, gas: 3000}("");
            if(success){
                totalDistributed = totalDistributed.add(amount);
                shareholderClaims[shareholder] = block.timestamp;
                shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
                shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            }
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

contract InFerToken is IBEP20, Ownable {
    using SafeMath for uint256;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "InFerToken";
    string constant _symbol = "InFer";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100000000 * (10 ** _decimals);
    uint256 public _maxWalletAmount = _totalSupply / 20; // 5%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isMaxWalletLimitExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => uint256) public dailySoldAmount;
    mapping (address => uint256) public dailySoldCheckPoint;

    uint256 bnbRewardFee = 6;
    uint256 burnFee = 2;
    uint256 liquidFee = 2;
    uint256 vaultFee = 2;

    uint256 public accumulatedRewardFee;
    uint256 public accumulatedLiquid;

    uint256 public launchedTime;

    address public walletMarketing;
    address public walletTeam;
    address public walletVault;

    IDEXRouter public router;
    address public pair;

    DividendDistributor public distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 20000; // 0.005%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    event AutoLiquify(uint256 amountSwapBNB, uint256 amount);

    constructor (address _walletMarketing, address _walletTeam, address _walletVault) {
        //router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Mainnet
        router = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //Testnet
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        distributor = new DividendDistributor();

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;

        isMaxWalletLimitExempt[msg.sender] = true;
        isMaxWalletLimitExempt[address(this)] = true;
        isMaxWalletLimitExempt[pair] = true;
        isMaxWalletLimitExempt[DEAD] = true;
        isMaxWalletLimitExempt[ZERO] = true;
        isMaxWalletLimitExempt[_walletVault] = true;
        isMaxWalletLimitExempt[_walletTeam] = true;
        
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;
        isDividendExempt[_walletVault] = true;

        walletMarketing = _walletMarketing;
        walletTeam = _walletTeam;
        walletVault = _walletVault;

        _balances[_walletTeam] = _balances[_walletTeam].add((_totalSupply/100)*15);
        _balances[_walletMarketing] = _balances[_walletMarketing].add((_totalSupply/100)*5);
        _balances[msg.sender] = _balances[msg.sender].add((_totalSupply/100)*80);
        emit Transfer(address(0), _walletTeam, (_totalSupply/100)*15);
        emit Transfer(address(0), _walletMarketing, (_totalSupply/100)*5);
        emit Transfer(address(0), msg.sender, (_totalSupply/100)*80);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
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

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        
        //Lock team wallets for 6 months
        if(sender == walletTeam){
            require(launchedTime > 0 && block.timestamp > launchedTime.add(180 days), "Team addresses is locked for 6 month");
        }

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        if(launchedTime == 0 && sender == owner() && recipient == pair){
            launchedTime = block.timestamp;
        }

        if(shouldSwapBack()){ swapBack(); }

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        checkWalletLimit(recipient, amountReceived);

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
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

    function checkWalletLimit(address recipient, uint256 amount) internal view {
        require(balanceOf(recipient).add(amount) <= _maxWalletAmount || isMaxWalletLimitExempt[recipient], "Max wallet Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        if(receiver == pair){
            if(block.timestamp/(24*60*60) > dailySoldCheckPoint[sender]){
                dailySoldCheckPoint[sender] = block.timestamp/(24*60*60);
                dailySoldAmount[sender] = 0;
            }
            require(dailySoldAmount[sender].add(amount) <= _totalSupply/1000, "Only be able to sell 0.1% totalSupply daily");
            dailySoldAmount[sender] = dailySoldAmount[sender].add(amount);
        }

        uint256 amountLiquidFee = 0;
        uint256 amountVaultFee = 0;
        uint256 amountBurnFee = 0;
        uint256 amountRewardFee = 0;

        amountLiquidFee = amount.mul(liquidFee).div(100);
        if(receiver == pair){
            amountVaultFee = amount.mul(vaultFee + 2).div(100);
        }else{
            amountVaultFee = amount.mul(vaultFee).div(100);
        }
        amountBurnFee = amount.mul(burnFee).div(100);
        amountRewardFee = amount.mul(bnbRewardFee).div(100);
        
        sendFee(sender, DEAD, amountBurnFee);
        sendFee(sender, walletVault, amountVaultFee);
        sendFee(sender, address(this), amountLiquidFee + amountRewardFee);

        accumulatedRewardFee = accumulatedRewardFee.add(amountRewardFee);
        accumulatedLiquid = accumulatedLiquid.add(amountLiquidFee);

        return amount.sub(amountRewardFee + amountBurnFee + amountLiquidFee + amountVaultFee);
    }

    function sendFee(address sender, address recipient, uint256 amount) internal {
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 halfLiquid = accumulatedLiquid.div(2);
        uint256 amountToSwap = accumulatedRewardFee.add(halfLiquid);

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
        uint256 amountSwapBNB = address(this).balance.sub(balanceBefore);

        uint256 amountBNBReward = amountSwapBNB.mul(accumulatedRewardFee).div(amountToSwap);
        uint256 amountBNBLiquid = amountSwapBNB.mul(halfLiquid).div(amountToSwap);
        
        //Reset accumulated Amount
        accumulatedRewardFee = 0;
        accumulatedLiquid = 0;

        if(amountBNBReward > 0){
            try distributor.deposit{value: amountBNBReward}() {} catch {}
        }

        if(halfLiquid > 0){
            router.addLiquidityETH{value: amountBNBLiquid}(
                address(this),
                halfLiquid,
                0,
                0,
                owner(),
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquid, halfLiquid);
        }
    }

    function setWalletLimit(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 100, "Check amount");
        _maxWalletAmount = amount;
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

    function setIsMaxWalletLimitExempt(address holder, bool exempt) external onlyOwner {
        isMaxWalletLimitExempt[holder] = exempt;
    }

    function setVaultWallet(address _walletVault) external onlyOwner {
        walletVault = _walletVault;

        isFeeExempt[walletVault] = true;
        isMaxWalletLimitExempt[walletVault] = true;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDividendForReward) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDividendForReward);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function setFees(uint256 _bnbRewardFee, uint256 _burnFee, uint256 _liquidFee, uint256 _vaultFee) external onlyOwner {
        bnbRewardFee = _bnbRewardFee;
        burnFee = _burnFee;
        liquidFee = _liquidFee;
        vaultFee = _vaultFee;
    }

}