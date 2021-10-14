/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

pragma solidity ^0.8.7;
//SPDX-License-Identifier: UNLICENCED


/*
 *  First SIMP Rewards token following the "nomics" trend
*   Website: https://simpnomics.com
*   Telegram: https://t.me/SimpNomics
*   Twitter: https://twitter.com/SimpNomics
*/


/**
 * Standard SafeMath, stripped Nomics to just add/sub/mul/div
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
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
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


contract SimpNomicsDividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
    
    address _token;

    mapping(address => bool) adminAccounts;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
   
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    IBEP20 public rewardtoken;
    mapping (address => uint256) totaldividendsOfToken;
    IDEXRouter router;

    address[] public shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;
    mapping (address => mapping (address => Share)) public rewardshares;

    uint256 public totalShares;
    //uint256 public totalDividends;
    uint256 public totalDistributed;
    //uint256 public dividendsPerShare;
    mapping (address => uint256) public dividendsPerShareRewardToken;
    mapping (address => uint256) public totaldividendsrewardtoken;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 12);

    uint256 public currentIndex;

    bool initialized = false;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router, address _rewardToken) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Mainnet
            //: IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //Testnet
        _token = msg.sender;
        rewardtoken = IBEP20(_rewardToken);
    }
    

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }
    

    function claimUnsentTokens(IBEP20 tokenAddress, address walletaddress) external onlyToken {
        tokenAddress.transfer(walletaddress, tokenAddress.balanceOf(address(this)));
        totaldividendsOfToken[address(rewardtoken)]  = 0;
    }
    
    
    function setInitialShare(address shareholder, uint256 amount) external onlyToken {
        addShareholder(shareholder);
        totalShares += amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }
    
    function setShareMultiple(address[] calldata addresses, uint256[] calldata amounts) external onlyToken
    {
        require(addresses.length == amounts.length, "must have the same length");
        for (uint i = 0; i < addresses.length; i++){
            setShareInternal(addresses[i], amounts[i]*(10**18));
        }
    }
    
    function setShareInternal(address shareholder, uint256 amount) internal {
        
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares += (shares[shareholder].amount) + (amount);
        shares[shareholder].amount = amount;
        rewardshares[address(rewardtoken)][shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
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

        totalShares -= (shares[shareholder].amount);
        shares[shareholder].amount = amount;
        totalShares += (amount);
        rewardshares[address(rewardtoken)][shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override {
        if (address(rewardtoken) != WBNB){
            uint256 balanceBefore = rewardtoken.balanceOf(address(this));

            address[] memory path = new address[](2);
            path[0] = address(WBNB);
            path[1] = address(rewardtoken);

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 amount = rewardtoken.balanceOf(address(this)) - (balanceBefore);
            
            totaldividendsOfToken[address(rewardtoken)] = totaldividendsOfToken[address(rewardtoken)] + amount;
            
            dividendsPerShareRewardToken[address(rewardtoken)] = dividendsPerShareRewardToken[address(rewardtoken)] + (dividendsPerShareAccuracyFactor * (amount) / (totalShares));
        }else{
            totaldividendsOfToken[address(rewardtoken)] = totaldividendsOfToken[address(rewardtoken)] + msg.value;
            dividendsPerShareRewardToken[address(rewardtoken)] = dividendsPerShareRewardToken[address(rewardtoken)] + (dividendsPerShareAccuracyFactor * (msg.value) / (totalShares));
        }
    }

    function process(uint256 gas) external override {
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

            gasUsed += (gasLeft - (gasleft()));
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
        //uint256 distributedAmount = amount / (10**(18-rewardtoken.decimals()));
        if(amount > 0){
            totalDistributed += amount;
            
            // do the swap and transfer the token
            if(address(rewardtoken) == WBNB){
                payable(shareholder).transfer(amount);
            }else{
                rewardtoken.transfer(shareholder, amount);
            }
            
            shareholderClaims[shareholder] = block.timestamp;
            rewardshares[address(rewardtoken)][shareholder].totalRealised  += (amount);
            rewardshares[address(rewardtoken)][shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = rewardshares[address(rewardtoken)][shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends - (shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share * dividendsPerShareRewardToken[address(rewardtoken)] / dividendsPerShareAccuracyFactor;
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

contract SimpNomics is IBEP20, Auth {
    using SafeMath for uint256;

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address SIMP = 0xD0ACCF05878caFe24ff8b3F82F194C62Ed755707;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "SimpNomics";
    string constant _symbol = "SimpNomics";
    uint8 constant _decimals = 9;

   uint256 _totalSupply = 1 * 10**9 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply / 100; // 1% (Change after contract deployed)
    uint256 public _maxSellTxAMount = _totalSupply / 100; // 1% 
    uint256 public _maxHoldAmount = _totalSupply / 50; // 2% (Can change after contract deployed)

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isMaxHoldExempt;
    
    mapping (address => bool) canTradeAnytime;
   
    /* @dev   
        all fees are set with 2 decimal places added, please remember this when setting fees. So 2 pc is 200
    */

    uint256 public liquidityFee = 300; //all these are changeable after deployment
    uint256 public marketingFee = 400;
    uint256 public developmentfee = 300;
    uint256 public rewardtokenFee = 500;
    uint256 public totalFee = 1500;
    uint256 public feeDenominator = 10000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public devFeeReceiver;

    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;
    mapping (address => bool) public pairs;

    bool public canTrade = false;


    SimpNomicsDividendDistributor public distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 10000; // 0.05%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (
    ) Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Mainnet
        //router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //Testnet
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        pairs[pair] = true;
        _allowances[msg.sender][address(router)] = _totalSupply;
        _allowances[address(this)][address(router)] = _totalSupply;
        isMaxHoldExempt[pair] = true;
        

        distributor = new SimpNomicsDividendDistributor(address(router), SIMP);

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        
        

        isTxLimitExempt[msg.sender] = true;
        isFeeExempt[msg.sender] = true;
        authorizations[msg.sender] = true;
        canTradeAnytime[msg.sender] = true;
        
        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;
        devFeeReceiver = msg.sender;
        owner = msg.sender;
        isMaxHoldExempt[owner] = true;
        _balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender];} 
    function rewardtoken()external view returns(address) {return address(distributor.rewardtoken());}
    function getrewardDistributionTime()external view returns(uint256){return distributor.minPeriod();}
    function getRewardDistributionMinAmount() external view returns(uint256){return distributor.minDistribution();}
    

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }
    
    
    function setmaxholdpercentage(uint256 _Num, uint256 _Den) external authorized {
        _maxHoldAmount = _totalSupply * _Num / _Den / 100; // percentage based on amount
    }
    
    
    function allowtrading()external authorized {
        canTrade = true;
    }
    
    
    function addNewPair(address newPair)external authorized{
        pairs[newPair] = true;
        isMaxHoldExempt[newPair] = true;
        isDividendExempt[newPair] = true;
    }
    
    function removePair(address pairToRemove)external authorized{
        pairs[pairToRemove] = false;
        isMaxHoldExempt[pairToRemove] = false;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(_totalSupply)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
	if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        if(!canTrade){
            require(sender == owner || canTradeAnytime[sender]); // only owner allowed to trade or add liquidity
        }
        if(sender != owner && recipient != owner){
            if(!pairs[recipient] && !isMaxHoldExempt[recipient]){
                require (balanceOf(recipient) + amount <= _maxHoldAmount, "cant hold more than max hold dude, sorry");
            }
        }
        
        

        if(shouldSwapBack()){ swapBack(); }
        
        checkTxLimit(sender, recipient, amount);
        
        
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
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

    function checkTxLimit(address sender, address receiver, uint256 amount) internal view {
        if(sender != owner && receiver != owner){
            require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        }
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }


    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
        
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }
    
    // returns any mis-sent tokens to the marketing wallet
    function claimtokensback(IBEP20 tokenAddress) external authorized {
        payable(marketingFeeReceiver).transfer(address(this).balance);
        tokenAddress.transfer(marketingFeeReceiver, tokenAddress.balanceOf(address(this)));
    }

function switchRewardToken(address rewardToken) public onlyOwner {
        SIMP = rewardToken;
        distributor = new SimpNomicsDividendDistributor(address(router), rewardToken);
    }	

    function setTxLimit(uint256 _Num, uint256 _Den) external authorized {
        _maxTxAmount = _totalSupply * _Num / _Den / 100;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && !pairs[holder]);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }
    
    function setCanTradeAnytime(address holder, bool _canTrade) external authorized {
        canTradeAnytime[holder] = _canTrade;
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee,  uint256 _rewardsFee, uint256 _marketingFee, uint256 _devFee,uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        rewardtokenFee = _rewardsFee;
        marketingFee = _marketingFee;
        developmentfee = _devFee;
        totalFee = _liquidityFee.add(_rewardsFee).add(_marketingFee).add(developmentfee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/4); // cant be over 25% of total.
    }
    
    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2); // leave some tokens for liquidity addition
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify); // swap everything bar the liquidity tokens. we need to add a pair

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

        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
        
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        
        if(rewardtokenFee > 0){
            uint256 amountBNBReflection = amountBNB.mul(rewardtokenFee).div(totalBNBFee);
            try distributor.deposit{value: amountBNBReflection}() {} catch {}
        }
        
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
        uint256 amountBNBDev = amountBNB.mul(developmentfee).div(totalBNBFee);

        
        payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        payable(devFeeReceiver).call{value: amountBNBDev, gas: 30000}("");
        
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

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address devWallet) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        devFeeReceiver = devWallet;
    }
    

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }
    
     function shouldSwapBack() internal view returns (bool) {
        return !pairs[msg.sender]
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        // minperiod is sent in in seconds, _mindistribution is sent in as a number * 10**18, i.e wei value.
        require(_minPeriod >= 1 hours && _minPeriod <= 1 days, "can not set the period to any thing less than an hour or more than 7 days");
        require(_minDistribution <= 2 * 10 ** 18 && _minDistribution > 0, "can not set the distribution to anything more than 2 bnb and it must be greater than 0");
        
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }


    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
    
}