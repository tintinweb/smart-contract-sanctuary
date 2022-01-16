// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import "./Libraries.sol";
/**
 * Contract Code
 */

contract Cheemspro is IBEP20, Ownable {
    
    // Basic Contract Info
    string private constant _name = "CheemsPro";
    string private constant _symbol = "CP";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 100_000_000_000_000*10**_decimals; // 100 Trillions
    
    // Boolean variables
    bool private _tradingEnabled;
    bool private _inSwap;
    bool public swapEnabled;
    bool public rewardsEnabled;

    // Events
    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
    event StuckBalanceSent(uint256 amountBNB, address recipient);
    event ForeignTokenTransfer(address tokenAddress, uint256 quantity);
    event DividendExempt(address Address, bool Excluded);
    event OwnerSetLimits(uint256 maxSell,uint256 maxWallet);
    event OwnerUpdateTaxes(uint8 buyTax,uint8 sellTax);
    event OwnerUpdateSecondaryTaxes(uint8 liquidity,uint8 rewards,uint8 marketing);
    event OwnerUpdateSwapThreshold(bool enabled, uint256 minSwapSize, uint256 maxSwapSize);
    event OwnerEnableTrading(uint256 timestamp);

    // Mappings
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;

    // Structs
    Tax private _tax;
    Limit private _limit;
    Distributor private _distributor;
    struct Limit {
        // Tax limits
        uint8 maxBuyTax;
        uint8 maxSellTax;
        // Swap variables
        uint256 maxSwapThreshold;
        uint256 swapThreshold;
        // Transaction limits
        uint256 maxWalletSize;
        uint256 maxSellSize;
    }
    struct Tax {
        // Primary Taxes
        uint8 buyTax;
        uint8 sellTax;
        // Secondary Taxes
        uint8 liquidityTax;
        uint8 rewardsTax;
        uint8 marketingTax;
    }
    struct Distributor {
        uint256 gas;
    }
   
    // Addresses (Router, Distributor, Marketing)
    IDEXRouter private router;
    address public _pancakeRouterAddress=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address public pair;
    DividendDistributor public distributor;
    address private marketingFeeReceiver = 0x0000000000000000000000000000000000000000;

   modifier LockTheSwap {
        _inSwap=true;
        _;
        _inSwap=false;
    }

    constructor () Ownable(msg.sender) {
        // Initialize Pancake Pair
        router=IDEXRouter(_pancakeRouterAddress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        // Initialize Distributor
        distributor = new DividendDistributor(address(router));
        // Exempt owner
        address _owner = owner;
        isFeeExempt[_owner] = true;
        isTxLimitExempt[_owner] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        // Mint _totalSupply to address
        _updateBalance(_owner,_totalSupply);
        emit Transfer(address(0),_owner,_totalSupply);
        // Set initial taxes
        _tax.buyTax=12;
        _tax.sellTax=15;
        _limit.maxBuyTax=20;
        _limit.maxSellTax=33;
        _tax.liquidityTax=20;
        _tax.rewardsTax=50;
        _tax.marketingTax=30;
        _limit.swapThreshold=_totalSupply/1000;
        _limit.maxSwapThreshold=_totalSupply/100;
        // Set initial reward settings
        rewardsEnabled=swapEnabled=true;
        _distributor.gas=500000;
        // Set transaction limits
        _limit.maxWalletSize=_totalSupply*3/100; // 3%
        _limit.maxSellSize=_totalSupply/100; // 1 %
    }

///////// Transfer Functions \\\\\\\\\
    function _transfer(address sender, address recipient, uint256 amount) internal {
        bool isBuy=sender==pair;
        bool isSell=recipient==pair;
        bool isExcluded=isFeeExempt[sender]||isFeeExempt[recipient]||_inSwap;

        if(isExcluded)_transferExcluded(sender,recipient,amount);
        else {
            require(_tradingEnabled);
            if(isBuy)_buyTokens(sender,recipient,amount);
            else if(isSell) {
                if(_shouldSwapBack())swapBack();
                if(rewardsEnabled)try distributor.process(_distributor.gas) {} catch {}
                _sellTokens(sender,recipient,amount);
            } else {
                require(isTxLimitExempt[recipient]||_balances[recipient]+amount<=_limit.maxWalletSize);
                _transferExcluded(sender,recipient,amount);
            }
        }
    }
    function _buyTokens(address sender,address recipient,uint256 amount) private {
        require(_balances[recipient]+amount<=_limit.maxWalletSize);
        uint256 tokenTax=amount*_tax.buyTax/100;
        _transferIncluded(sender,recipient,amount,tokenTax);
    }
    function _sellTokens(address sender,address recipient,uint256 amount) private {
        require(amount<=_limit.maxSellSize);
        uint256 tokenTax=amount*_tax.sellTax/100;
        _transferIncluded(sender,recipient,amount,tokenTax);
    }

    function _transferExcluded(address sender,address recipient,uint256 amount) private {
        _updateBalance(sender,_balances[sender]-amount);
        _updateBalance(recipient,_balances[recipient]+amount);
        emit Transfer(sender,recipient,amount);
    }

    function _transferIncluded(address sender,address recipient,uint256 amount,uint256 tokenTax) private {
        uint256 newAmount=amount-tokenTax;
        _updateBalance(sender,_balances[sender]-amount);
        _updateBalance(address(this),_balances[address(this)]+tokenTax);
        _updateBalance(recipient,_balances[recipient]+newAmount);
        emit Transfer(sender,recipient,newAmount);
    }

    function _updateBalance(address account,uint256 newBalance) private {
        _balances[account]=newBalance;
        if(!isDividendExempt[account])try distributor.setShare(account, _balances[account]) {} catch {}
        else return;
    }

    function swapBack() internal LockTheSwap {
        uint256 contractTokenBalance=_balances[address(this)];
        uint256 tokensToSell;
        if(contractTokenBalance >= _limit.maxSwapThreshold){
            tokensToSell = _limit.maxSwapThreshold;            
        }
        else{
            tokensToSell = contractTokenBalance;
        }
        uint256 totalLPTokens=tokensToSell*_tax.liquidityTax/100;
        uint256 tokensLeft=tokensToSell-totalLPTokens;
        uint256 LPTokens=totalLPTokens/2;
        uint256 LPBNBTokens=totalLPTokens-LPTokens;
        tokensToSell=tokensLeft+LPBNBTokens;
        uint256 oldBNB=address(this).balance;
        _swapTokensForBNB(tokensToSell);
        uint256 newBNB=address(this).balance-oldBNB;
        uint256 LPBNB=(newBNB*LPBNBTokens)/tokensToSell;
        _addLiquidity(LPTokens,LPBNB);
        uint256 remainingBNB=address(this).balance-oldBNB;
        _distributeBNB(remainingBNB);
    }

///////// Rewards Functions \\\\\\\\\
    function ownerSetIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
        emit DividendExempt(holder, exempt);
    }
    
///////// Internal Functions \\\\\\\\\
    function _distributeBNB(uint256 amountWei) private {
        uint256 rewardBNB=amountWei*_tax.marketingTax/100;
        uint256 marketingBNB=amountWei-rewardBNB;

        try distributor.deposit{value: rewardBNB}() {} catch {}
        (bool success, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: marketingBNB, gas: 30000}("");
        require(success, "receiver rejected ETH transfer");
    }

    function _shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !_inSwap
        && swapEnabled
        && _balances[address(this)] >= _limit.swapThreshold;
    }

    function _swapTokensForBNB(uint256 amount) private {
        address[] memory path=new address[](2);
        path[0]=address(this);
        path[1]=router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 amountTokens,uint256 amountBNB) private {
        router.addLiquidityETH{value: amountBNB}(
            address(this),
            amountTokens,
            0,
            0,
            marketingFeeReceiver,
            block.timestamp
        );
        emit AutoLiquify(amountTokens,amountBNB);
    }

///////// Owner Functions \\\\\\\\\
    function ownerSetLimits(uint256 maxSell,uint256 maxWallet) public onlyOwner{
        require(maxWallet*10**_decimals >= _totalSupply/100, "Can't set lower MaxWallet than 1%");
        require(maxSell*10**_decimals >= _totalSupply/200, "Can't set lower MaxSell than 0.5%");
        _limit.maxWalletSize=maxWallet*10**_decimals;
        _limit.maxSellSize=maxSell*10**_decimals;
        emit OwnerSetLimits(maxSell,maxWallet);
    }
    function ownerEnableTrading() public onlyOwner{
        require(!_tradingEnabled, "Trading already enabled");
        _tradingEnabled=true;
        emit OwnerEnableTrading(block.timestamp);
    }
    function ownerUpdateTaxes(uint8 buyTax,uint8 sellTax) public onlyOwner {
        require(buyTax<=_limit.maxBuyTax&&sellTax<=_limit.maxSellTax);
        _tax.buyTax=buyTax;
        _tax.sellTax=sellTax;
        emit OwnerUpdateTaxes(buyTax,sellTax);
    }
    function ownerUpdateSecondaryTaxes(uint8 liquidity,uint8 rewards,uint8 marketing) public onlyOwner {
        require(liquidity+rewards+marketing==100);
        _tax.liquidityTax=liquidity;
        _tax.rewardsTax=rewards;
        _tax.marketingTax=marketing;
        emit OwnerUpdateSecondaryTaxes(liquidity,rewards,marketing);
    }
    function ownerUpdateSwapThreshold(bool _enabled,uint256 swapThreshold_Base1000,uint256 maxSwapThreshold_Base1000) public onlyOwner {
        swapEnabled=_enabled;
        _limit.swapThreshold=_totalSupply*swapThreshold_Base1000/1000;
        _limit.maxSwapThreshold=_totalSupply*maxSwapThreshold_Base1000/1000;
        emit OwnerUpdateSwapThreshold(_enabled,swapThreshold_Base1000,maxSwapThreshold_Base1000);
    }
        
    // Distributor Settings
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas<750000);
        _distributor.gas=gas;
    }

    // Stuck Balance Functions
    function ClearStuckBalance() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        payable(marketingFeeReceiver).transfer(contractBalance);
        emit StuckBalanceSent(contractBalance, marketingFeeReceiver);
    }

    function transferForeignToken(address _token) public onlyOwner {
        require(_token != address(this), "Can't let you take all native token");
        uint256 _contractBalance = IBEP20(_token).balanceOf(address(this));
        payable(marketingFeeReceiver).transfer(_contractBalance);
        emit ForeignTokenTransfer(_token, _contractBalance);
    }

///////// IBEP20 \\\\\\\\\
    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
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
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - (amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }
    
    receive() external payable { }
}
/**
 * Rewards Code
 */

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {

    IBEP20 RWRD = IBEP20(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c); // BTC: 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    
    IDEXRouter router;

    address[] shareholders;
    address _token;

    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 30 * 60;
    uint256 public minDistribution = 1 * (10 ** 9);

    uint256 currentIndex;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router=IDEXRouter(_router);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares - (shares[shareholder].amount) + (amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = RWRD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(RWRD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = RWRD.balanceOf(address(this)) - (balanceBefore);

        totalDividends = totalDividends + (amount);
        dividendsPerShare = dividendsPerShare + (dividendsPerShareAccuracyFactor * (amount) / (totalShares));
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

            gasUsed = gasUsed + (gasLeft - (gasleft()));
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
            totalDistributed = totalDistributed + amount;
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised + (amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            RWRD.transfer(shareholder, amount);
        }
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends - (shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share * (dividendsPerShare) / (dividendsPerShareAccuracyFactor);
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