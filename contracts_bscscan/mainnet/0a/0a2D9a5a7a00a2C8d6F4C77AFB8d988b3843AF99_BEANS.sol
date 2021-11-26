/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Allows for contract ownership along with multi-address authorization
 */
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
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }



    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
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

    IBEP20 REWARDS = IBEP20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); //the reward token you want distributed - BNB

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

    uint256 public minPeriod = 45 minutes;
    uint256 public minDistribution = 1000000 * (10**18); //min Tokens required for dividend share

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
        minDistribution = _minDistribution * (10**18);
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

        uint256 amount = REWARDS.balanceOf(address(this));

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
            REWARDS.transfer(shareholder, amount);
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
    
    function TransferDividendToken(address payable recipient, uint256 amount) external onlyToken {
        require(recipient != address(0), "Cannot withdraw the Dividend Token balance to the zero address");
        REWARDS.transfer(recipient, amount);
    }
    
    function TransferStuckBNB(address payable recipient, uint256 amount) external onlyToken {
        require(recipient != address(0), "Cannot withdraw the BNB balance to the zero address");
        recipient.transfer(amount);
    }
}

contract BEANS is IBEP20, Auth {
    using SafeMath for uint256;

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; 
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    
    address public marketingWallet = 0xAA90C628B5CBcBBc223BB08B597e76BAA75C9Cc1;
    address public devWallet =  0x0547129b98ec1e18D8a5B62809011bD0ccaD2Db0;

    address routerv2 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    string constant _name = "BEANS";
    string constant _symbol = "BEANS";
    uint8 constant _decimals = 18;

    uint256 internal constant _totalSupply = 1000000000 * (10**18);
    
    uint256 public maxTxAmount = _totalSupply / 1000; // 0.5% of the total supply
    uint256 public maxWalletBalance = _totalSupply / 50; // 2% of the total supply
    
    uint256 public maxBuy = _totalSupply / 100; // 1% of the total supply

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isDividendExempt;
    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public processedAirdrops;
    
    uint256 public sellingMarketingFee = 4;
    uint256 public buyingMarketingFee = 4;
    
    uint256 public sellingRewardFee = 2;
    uint256 public buyingRewardFee = 2;
    
    uint256 public sellingLpFee = 3;
    uint256 public buyingLpFee = 3;
    
    uint256 public sellingDevFee = 1;
    uint256 public buyingDevFee = 1;
    
    uint256 public buyersTotalFees = buyingMarketingFee.add(buyingRewardFee).add(buyingLpFee).add(buyingDevFee);
    uint256 public sellersTotalFees = sellingMarketingFee.add(sellingRewardFee).add(sellingLpFee).add(sellingDevFee);
    
    uint256 internal FEES_DIVISOR = 10**2;

    IDEXRouter public router;
    address public pair;

    DividendDistributor public distributor;
    uint256 distributorGas = 500000;

    bool public takeFeeEnabled = true;
    bool public tradingIsEnabled = true;
    bool public isInPresale = false;
    
    bool public antiBotEnabled = false;
    uint256 public antiBotFee = 99;
    uint256 public _startTimeForSwap;
    
    bool public buyCooldownEnabled = false;
    uint256 public cooldownTimerInterval;

    bool private swapping;
    bool public swapEnabled = true;
    uint256 public swapTokensAtAmount = 100000 * (10**18);
    
    // Total = 100%
    uint256 public marketingPortionOfSwap = 40; // 45%
    uint256 public rewardPortionOfSwap = 20; // 20%
    uint256 public devPortionOfSwap = 10; // 10%
    uint256 public lpPortionOfSwap = 30; // 30%
    
    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event DevWalletUpdated(address indexed newDevWallet, address indexed oldDevWallet);
    
    event LiquidityAdded(uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity);

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;

        distributor = new DividendDistributor(address(router));

        isFeeExempt[msg.sender] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        
        approve(routerv2, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    receive() external payable { }

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
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }
    
    function updateFeesDivisor(uint256 divisor) external onlyOwner() {
        FEES_DIVISOR = divisor;
    }
    
    function updateSwapTokensAt(uint256 _swaptokens) external onlyOwner {
        swapTokensAtAmount = _swaptokens * (10**18);
    }
    
    function setLaunch() external onlyOwner {
        require(!buyCooldownEnabled, "This can only be initiated once");
        buyCooldownEnabled = true;
        cooldownTimerInterval = block.timestamp + 900;
    }
    
    function doAirDrop(address[] calldata _recipients, uint256[] calldata _values) external onlyOwner {
        require(_recipients.length == _values.length);
        uint256 total = balanceOf(address(this));
        
        for (uint i = 0; i < _recipients.length; i++) {
            uint256 toSend = _values[i] * (10**18);
            
            if(processedAirdrops[_recipients[i]] == false){
                require(total >= toSend);
                total = total.sub(toSend);
                
               _basicTransfer(address(this), _recipients[i], toSend);
               processedAirdrops[_recipients[i]] = true;
            }
            
         }
    }
    
    function updateSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled  = _enabled;
    }
    
    function updateWalletMax(uint256 _walletMax) external onlyOwner {
        maxWalletBalance = _walletMax * (10**18);
    }
    
    function updateTransactionMax(uint256 _txMax) external onlyOwner {
        maxTxAmount = _txMax * (10**18);
    }
    
    function calcBuyersTotalFees() private {
        buyersTotalFees = buyingMarketingFee.add(buyingRewardFee).add(buyingLpFee).add(buyingDevFee);
    }
    
    function calcSellersTotalFees() private {
        sellersTotalFees = sellingMarketingFee.add(sellingRewardFee).add(sellingLpFee).add(sellingDevFee);
    }
    
    function updateSellingRewardFee (uint256 newFee) external onlyOwner {
        sellingRewardFee = newFee;
        calcSellersTotalFees();
    }
    
    function updateSellingMarketingFee (uint256 newFee) external onlyOwner {
        sellingMarketingFee = newFee;
        calcSellersTotalFees();
    }
    
    function updateSellingLpFee (uint256 newFee) external onlyOwner {
        sellingLpFee = newFee;
        calcSellersTotalFees();
    }
    
    function updateSellingDevFee (uint256 newFee) external onlyOwner {
        sellingDevFee = newFee;
        calcSellersTotalFees();
    }
    
    function updateBuyingRewardFee (uint256 newFee) external onlyOwner {
        buyingRewardFee = newFee;
        calcBuyersTotalFees();
    }
    
    function updateBuyingMarketingFee (uint256 newFee) external onlyOwner {
        buyingMarketingFee = newFee;
        calcBuyersTotalFees();
    }
    
    function updateBuyingLpFee (uint256 newFee) external onlyOwner {
        buyingLpFee = newFee;
        calcBuyersTotalFees();
    }
    
    function updateBuyingDevFee (uint256 newFee) external onlyOwner {
        buyingDevFee = newFee;
        calcBuyersTotalFees();
    }
    
    function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
        require(newMarketingWallet != marketingWallet, "The Marketing wallet is already this address");
        emit MarketingWalletUpdated(newMarketingWallet, marketingWallet);
        
        marketingWallet = newMarketingWallet;
    }
    
    function updateDevWallet(address newDevWallet) external onlyOwner {
        require(newDevWallet != devWallet, "The Dev wallet is already this address");
        emit DevWalletUpdated(newDevWallet, devWallet);
        
        devWallet = newDevWallet;

    }
    
    function updatePortionsOfSwap(uint256 marketingPortion, uint256 rewardPortion, 
    uint256  devPortion, uint256 lpPortion) external onlyOwner {
        
        uint256 totalPortion = marketingPortion.add(rewardPortion).add(devPortion).add(lpPortion);
        require(totalPortion == 100, "Total must be equal to 100");
        
        marketingPortionOfSwap = marketingPortion;
        rewardPortionOfSwap = rewardPortion;
        devPortionOfSwap = devPortion;
        lpPortionOfSwap = lpPortion;
    }
    
    function prepareForPreSale() external onlyOwner {
        takeFeeEnabled = false;
        swapEnabled = false;
        isInPresale = true;
        maxTxAmount = _totalSupply;
        maxWalletBalance = _totalSupply;
    }
    
    function afterPreSale() external onlyOwner {
        takeFeeEnabled = true;
        swapEnabled = true;
        isInPresale = false;
        maxTxAmount = _totalSupply / 1000;
        maxWalletBalance = _totalSupply / 50;
        
        if(!buyCooldownEnabled) {
            buyCooldownEnabled = true;
            cooldownTimerInterval = block.timestamp + 900;
        }
    }
    
    function whitelistDxSale(address _presaleAddress, address _routerAddress) external onlyOwner {
        isFeeExempt[_presaleAddress] = true;
        isDividendExempt[_presaleAddress] = true;
        
        isFeeExempt[_routerAddress] = true;
        isDividendExempt[_routerAddress] = true;
  	}
  	
  	function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }
  	
  	function updateTradingIsEnabled(bool tradingStatus) external onlyOwner() {
        tradingIsEnabled = tradingStatus;
    }
    
    function toggleAntiBot(bool toggleStatus) external onlyOwner() {
        antiBotEnabled = toggleStatus;
        if(antiBotEnabled){
            _startTimeForSwap = block.timestamp + 60;    
        }
        
    }
    
    function updateRouterAddress(address newAddress) external onlyOwner {
        require(newAddress != address(router), "The router already has that address");
        router = IDEXRouter(newAddress);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "Token: transfer from the zero address");
        require(recipient != address(0), "Token: transfer to the zero address");
        require(sender != address(DEAD), "Token: transfer from the burn address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], "Blacklisted address");
        
        require(tradingIsEnabled, "This account cannot send tokens until trading is enabled");
        
        if(swapping){ return _basicTransfer(sender, recipient, amount); }
        
        if(buyCooldownEnabled && block.timestamp <= cooldownTimerInterval && recipient != address(pair)) {
            
           if(!isFeeExempt[recipient] && !isFeeExempt[sender]) {
                require(amount <= maxBuy, "Transfer amount exceeds the Max Buy Amount.");  
           }
        }
        
        if (
            sender != address(router) && //router -> pair is removing liquidity which shouldn't have max
            !isFeeExempt[recipient] && //no max for those excluded from fees
            !isFeeExempt[sender] 
        ) {
            require(amount <= maxTxAmount, "Transfer amount exceeds the Max Transaction Amount.");
            
        }

        if ( maxWalletBalance > 0 && !isFeeExempt[recipient] && !isFeeExempt[sender] && recipient != address(pair) ) {
                uint256 recipientBalance = balanceOf(recipient);
                require(recipientBalance + amount <= maxWalletBalance, "New balance would exceed the maxWalletBalance");
            }
        
       _beforeTokenTransfer(recipient);

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        
         // indicates whether or not fee should be deducted from the transfer
        bool _isTakeFee = takeFeeEnabled;
        
         // if any account belongs to isFeeExempt account then remove the fee
        if(isFeeExempt[sender] || isFeeExempt[recipient]) { 
            _isTakeFee = false; 
        }
        
        if ( isInPresale ){ _isTakeFee = false; }

        uint256 amountReceived = _isTakeFee ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        // Dividend tracker
        if(!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {} 
        }

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
    
    function _beforeTokenTransfer(address recipient) private {
        if ( !isInPresale ){
            uint256 contractTokenBalance = balanceOf(address(this));
            // swap
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            
            if (!swapping && canSwap && swapEnabled && recipient == pair) {
                swapping = true;
                
                swapBack();
                
                swapping = false;
            }
            
        }
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 totalFee = sender == pair ? buyersTotalFees : sellersTotalFees;
        totalFee = antiBotEnabled && block.timestamp <= _startTimeForSwap ? antiBotFee : totalFee;
        uint256 feeAmount = amount.mul(totalFee).div(FEES_DIVISOR);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function swapBack() internal {
        uint256 splitLiquidityPortion = lpPortionOfSwap.div(2);
        uint256 amountToLiquify = balanceOf(address(this)).mul(splitLiquidityPortion).div(FEES_DIVISOR);
        uint256 amountToSwap = balanceOf(address(this)).sub(amountToLiquify);

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
        
        uint256 amountBNBMarketing = amountBNB.mul(marketingPortionOfSwap).div(FEES_DIVISOR);
        uint256 amountBNBDev = amountBNB.mul(devPortionOfSwap).div(FEES_DIVISOR);
        uint256 amountBNBReflection = amountBNB.mul(rewardPortionOfSwap).div(FEES_DIVISOR);
        uint256 amountBNBLiquidity = amountBNB.mul(splitLiquidityPortion).div(FEES_DIVISOR);
        

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        
          // Send to addresses
        transferToAddressBNB(payable(marketingWallet), amountBNBMarketing);
        transferToAddressBNB(payable(devWallet), amountBNBDev);
        
        // add liquidity
        _addLiquidity(amountToLiquify, amountBNBLiquidity);

    }
    
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        approve(address(router), tokenAmount);

        // add the liquidity
        (uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity) = router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            DEAD,
            block.timestamp
        );

        emit LiquidityAdded(tokenAmountSent, ethAmountSent, liquidity);
    }


    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
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
    
    function transferToAddressBNB(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function clearStuckBalance(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Cannot withdraw the ETH balance to the zero address");
        recipient.transfer(amount);
    }
    
   function TransferDividendToken(address payable recipient, uint256 amount) external onlyOwner {
        distributor.TransferDividendToken(recipient, amount);
    }
    
    function TransferStuckBNB(address payable recipient, uint256 amount) external onlyOwner {
        distributor.TransferStuckBNB(recipient, amount);
    }

}