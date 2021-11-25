/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.10;

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
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
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDividendForReward) external;
}

contract RewardMechanism is IRewardMechanism {


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
    uint256 public minDividendForReward;

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
        totalShares = totalShares - shares[shareholder].amount + dividendAmount;
        shares[shareholder].amount = dividendAmount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }
    receive() external payable { 
        deposit();
    }

    function deposit() public payable override {
        totalDividends += msg.value;
        dividendsPerShare += (dividendsPerShareAccuracyFactor * msg.value / totalShares);
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

            gasUsed += (gasLeft - gasleft());
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
                totalDistributed += amount;
                shareholderClaims[shareholder] = block.timestamp;
                shares[shareholder].totalRealised += amount;
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

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share * dividendsPerShare / dividendsPerShareAccuracyFactor;
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

contract PassiveCoin is IBEP20, Ownable {


    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "PassiveCoin";
    string constant _symbol = "PAS";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100000000000 * (10 ** _decimals);
    uint256 public _maxWalletAmount = getCirculatingSupply() / 50; // 2%
    uint256 public _maxTransferAmount = getCirculatingSupply() / 200; // 0.5%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isMaxWalletLimitExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) public isInBlacklist;
    mapping (address => bool) public isMaxTransferLimitExempt;

    uint256 buyBnbRewardFee = 5;
    uint256 buyMarketingFee = 3;
    uint256 buyLiquidFee = 2;
    
    uint256 sellBnbRewardFee = 8;
    uint256 sellMarketingFee = 5;
    uint256 sellLiquidFee = 2;

    uint256 public accumulatedRewardFee;
    uint256 public accumulatedMarketing;
    uint256 public accumulatedLiquid;

    address public walletMarketing;

    uint256 public launchedTime;

    IDEXRouter public router;
    address public pair;

    RewardMechanism public distributor;
    uint256 distributorGas = 500000;

    bool private buyOrSell;
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 20000; // 0.005% of supply in fees accumulate before swapping to BnB
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    event AutoLiquify(uint256 amountSwapBNB, uint256 amount);

    constructor () {
        //router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Mainnet
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //Testnet
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

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
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
        require(_allowances[sender][msg.sender] > 0, "Insufficient Allowance");
            _allowances[sender][msg.sender] -= amount;
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

        uint256 amountReceived;
        
        if(shouldTakeFee(sender)) {
        
        !determineTaxFee(recipient) ? amountReceived = takeBuyFee(sender, amount): amountReceived = takeSellFee(sender, amount);
        }

        else {
        amountReceived = amount;
        }


        checkWalletLimit(recipient, amountReceived);
        checkTransferLimit(amountReceived, sender);

        _balances[sender] -= amount;
        _balances[recipient] += amountReceived;

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkWalletLimit(address recipient, uint256 amount) internal view {
        require((balanceOf(recipient) + amount) <= _maxWalletAmount || isMaxWalletLimitExempt[recipient], "Max wallet Exceeded");
    }

    function checkTransferLimit(uint256 amount, address sender) internal view {
        require( amount <= _maxTransferAmount || isMaxTransferLimitExempt[sender], "Max Transfer Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }



    function determineTaxFee(address isSell) internal view returns (bool) {

    return isSell == pair;
}

    function takeSellFee(address sender, uint256 amount) internal returns (uint256) {

        uint256 amountSellLiquidFee = 0;
        uint256 amountSellMarketingFee = 0;
        uint256 amountSellRewardFee = 0;


        if(block.timestamp <= launchedTime + 1 days) { 

            uint256 launchRewardFeeSell = 15;
            uint256 launchLiquidFeeSell = 10;
            uint256 launchMarketingFeeSell = 15;

            amountSellLiquidFee = amount * launchLiquidFeeSell / 100;
            amountSellRewardFee = amount * launchRewardFeeSell / 100;
            amountSellMarketingFee = amount * launchMarketingFeeSell / 100;
            }

        else {

        amountSellLiquidFee = amount * sellLiquidFee / 100;
        amountSellMarketingFee = amount * sellMarketingFee / 100;
        amountSellRewardFee = amount * sellBnbRewardFee / 100;

        }

        accumulatedRewardFee += amountSellRewardFee;
        accumulatedMarketing += amountSellMarketingFee;
        accumulatedLiquid += amountSellLiquidFee;

        uint256 sellFeeAmount = amountSellRewardFee + amountSellMarketingFee + amountSellLiquidFee;
        _balances[address(this)] += sellFeeAmount;
        emit Transfer(sender, address(this), sellFeeAmount);

        return (amount - sellFeeAmount);
    }

    function takeBuyFee(address sender, uint256 amount) internal returns (uint256) {


        uint256 amountBuyLiquidFee = 0;
        uint256 amountBuyMarketingFee = 0;
        uint256 amountBuyRewardFee = 0;
        

        if(block.timestamp <= launchedTime + 1 days) {

            uint256 launchRewardFeeBuy = 1;
            uint256 launchLiquidFeeBuy = 2;
            uint256 launchMarketingFeeBuy = 2;
            
            amountBuyLiquidFee = amount * launchLiquidFeeBuy / 100;
            amountBuyRewardFee = amount * launchRewardFeeBuy / 100;
            amountBuyMarketingFee = amount * launchMarketingFeeBuy / 100;
        }
        
        else {
            
            amountBuyLiquidFee = amount * buyLiquidFee / 100;
            amountBuyMarketingFee = amount * buyMarketingFee / 100;
            amountBuyRewardFee = amount * buyBnbRewardFee / 100;
            
            
        }
        
        accumulatedRewardFee += amountBuyRewardFee;
        accumulatedMarketing += amountBuyMarketingFee;
        accumulatedLiquid += amountBuyLiquidFee;

        uint256 buyFeeAmount = amountBuyRewardFee + amountBuyMarketingFee + amountBuyLiquidFee;
        _balances[address(this)] += buyFeeAmount;
        emit Transfer(sender, address(this), buyFeeAmount);

        return (amount - buyFeeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 halfLiquid = accumulatedLiquid / 2;
        uint256 amountToSwap = accumulatedRewardFee + accumulatedMarketing + halfLiquid;

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
        uint256 amountSwapBNB = address(this).balance - balanceBefore;

        uint256 amountBNBReward = amountSwapBNB * accumulatedRewardFee / amountToSwap;
        uint256 amountBNBMarketing = amountSwapBNB * accumulatedMarketing / amountToSwap;
        uint256 amountBNBLiquid = amountSwapBNB * halfLiquid / amountToSwap;
        
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

    function setWalletLimitPercentage(uint256 amount) external onlyOwner {
        amount /= (100 * getCirculatingSupply());
        _maxWalletAmount = amount;
    }
    
    function setTransferLimitPercentage(uint256 amount) external onlyOwner {
    amount /= (100 * getCirculatingSupply());
    _maxTransferAmount = amount;
    }

    function timeSinceLaunch () external view returns(uint256){
    return launchedTime;
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

    function setIsMaxTransferLimitExempt(address holder, bool exempt) external onlyOwner {
        isMaxTransferLimitExempt[holder] = exempt;
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
        return (_totalSupply - balanceOf(DEAD) - balanceOf(ZERO));
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

}