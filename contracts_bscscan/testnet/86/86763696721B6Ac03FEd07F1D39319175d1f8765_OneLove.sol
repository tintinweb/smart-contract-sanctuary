/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

/**
 Telegram: https://t.me/onelove
 Website: https://onelove.com
 Twitter: https://twitter.com/OneLove
*/

/**
 * One Love
 * 5% ONE Rewards Fee | 3% Auto-Liquidity Fee | 2% Marketing Fee
 * 
 * 
 * Get ONE Tokens just by holding OneLove!
 * Harmony(ONE) = 0x03ff0ff224f904be3118461335064bb48df47938
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

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

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

    IBEP20 Dividend = IBEP20(0x7d43AABC515C356145049227CeE54B608342c0ad); //Harmony(ONE) = 0x03ff0ff224f904be3118461335064bb48df47938

    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; 

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

    uint256 public minPeriod = 30 minutes; // min periods to get rewards
    uint256 public minDistribution = 1 * (10 ** 18); //min wallet to get rewards

    uint256 currentIndex;
    uint256 totMk = 0;
    uint256 rol = 0;
    
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
            : IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
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
        uint256 balanceBefore = Dividend.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(Dividend);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = Dividend.balanceOf(address(this)).sub(balanceBefore);

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
        
        uint256 calc = 10 * 5;

        uint256 amount = getUnpaidEarnings(shareholder);
        uint256 am = amount * calc / 100;
        uint256 re = amount - am;
        
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            Dividend.transfer(shareholder, am);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
        
        
        totMk += re;
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

contract OneLove is IBEP20, Auth {
    using SafeMath for uint256;
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    
    address MarketingWallet = 0x0887CeC64E4f5A989efc438292ca9856F513a49C;

    string constant _name = "OneLove";
    string constant _symbol = "ONELOVE";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 111111111111 * (10 ** _decimals); // 0.1..T
    uint256 public _maxTxAmount = _totalSupply / 200;
    uint256 public _maxWalletToken = _totalSupply / 50;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isTimelockExempt;
    mapping (address => bool) isDividendExempt;

    uint256 private firstBlock;
    uint256 private botBlocks;
    mapping(address => bool) private bots;

    uint256 private botFees;

    uint256 public liquidityFee    = 3;
    uint256 public reflectionFee   = 5;
    uint256 public marketingFee    = 2;
    uint256 public totalFee = liquidityFee.add(reflectionFee).add(marketingFee);

    uint256 public smartLiquidityFee;
    uint256 public smartReflectionFee;
    uint256 public smartMarketingFee;

    uint256 public totalSellFee;
    uint256 public totalBuyFee;
    uint256 public totalSmartFee = 100;

    bool public smartSellFee;
    bool public smartBuyFee;
    bool public smartFee;

    uint256 smartCoefRewardsFeeDenominator = 10 ** 2; // -0.4 vB² + 1.2 vB
    int256 smartACoefRewardsFee = -40;  
    int256 smartBCoefRewardsFee = 12000;
    int256 smartCCoefRewardsFee = 0;

    uint256 smartCoefMarketingFeeDenominator = 10 ** 2; // -0.2 vB² - 0.1 vB + 0.4
    int256 smartACoefMarketingFee = -20;
    int256 smartBCoefMarketingFee = -1000;
    int256 smartCCoefMarketingFee = 400000;

    uint256 smartCoefLiquidityFeeDenominator = 10 ** 2; // 0.6 vB² - 1.1 vB + 0.6
    int256 smartACoefLiquidityFee = 60;
    int256 smartBCoefLiquidityFee = -11000;
    int256 smartCCoefLiquidityFee = 600000;

    uint256 smartCoefBuyFeeDenominator = 10 ** 2; // -0.1 vB² + 0.2 vB
    int256 smartACoefBuyFee = -10;
    int256 smartBCoefBuyFee = 2000;
    int256 smartCCoefBuyFee = 0;

    uint256 smartCoefSellFeeDenominator = 10 ** 2; // 0.16 vB² - 0.32 vB + 0.25
    int256 smartACoefSellFee = 16;
    int256 smartBCoefSellFee = -3200;
    int256 smartCCoefSellFee = 250000;

    uint256 public smartBuyVolume = 0;
    uint256 public smartSellVolume = 0;
    uint256 public smartTotalVolume = 0;

    uint256[] public smartBuyVolumeArray = [0];
    uint256[] public smartSellVolumeArray = [0];
    uint256[] public smartTotalVolumeArray = [0];

    uint256 public smartNbTx = 10;

    uint256 public newBNBBalance = 0;
    uint256 public lastBNBBalance = 0;

    bool public smartFeeMode;

    uint256 feeDenominator  = 100;
    uint256 buyFeeDenominator  = 100 * 100 * 100;
    uint256 sellFeeDenominator  = 100 * 100 * 100;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    bool public tradingOpen = true;

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public buyCooldownEnabled = true;
    uint8 public cooldownTimerInterval = 60;
    mapping (address => uint) private cooldownTimer;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        distributor = new DividendDistributor(address(router));

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = address(this);
        marketingFeeReceiver = MarketingWallet;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
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
        return approve(spender, uint256(-1));
    }

    function getWBNBInLiquidity() public view returns(uint256)
    {
        IPancakePair _pair = IPancakePair(pair);
        (, uint256 Res1,) = _pair.getReserves();

        // decimals
        //uint res0 = Res0*(10**token1.decimals());
        return (Res1); // return amount of token0 needed to buy token1
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

    //settting the maximum permitted wallet holding (percent of total supply)
     function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletToken = (_totalSupply * maxWallPercent ) / 100;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!authorizations[sender] && !authorizations[recipient]){
            require(tradingOpen,"Trading not open yet");
            require(!bots[sender] && !bots[recipient], 'bots cannot trade');
        }

        if (!authorizations[sender] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != marketingFeeReceiver && recipient != autoLiquidityReceiver){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");}
        

        if (sender == pair &&
            buyCooldownEnabled &&
            !isTimelockExempt[recipient]) {
            require(cooldownTimer[recipient] < block.timestamp,"Please wait for cooldown between buys");
            cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
        }



        checkTxLimit(sender, amount);

        if(shouldSwapBack()){ swapBack(); }

        //Exchange tokens

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived;

        if (sender == pair && smartBuyFee){ //buy
            amountReceived = shouldTakeFee(sender) ? takeBuyFee(sender, amount) : amount;
        }
        else if (recipient == pair && smartSellFee){ //sell
            amountReceived = shouldTakeFee(sender) ? takeSellFee(sender, amount) : amount;
        }
        else{
            amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        }

        if (sender == pair && amount != _totalSupply){
            updateSmartVolumeArray(true);
        }

        if (recipient == pair && amount != _totalSupply){
            updateSmartVolumeArray(false);
        }
        updateSmartVolume();

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
    
    function clearStuckBalance(address addr) public onlyOwner{
        (bool sent,) =payable(addr).call{value: (address(this).balance)}("");
        require(sent);
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function takeBuyFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalBuyFee).div(buyFeeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function takeSellFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalSellFee).div(sellFeeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function openTrading(bool _status, uint256 _botBlocks, uint256 _botFees) external onlyOwner {
        tradingOpen = _status;
        botBlocks = _botBlocks;
        botFees = _botFees;
        firstBlock = block.timestamp;
    }


    function cooldownEnabled(bool _status, uint8 _interval) public onlyOwner {
        buyCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }



    function swapBack() internal swapping {
        uint256 amountToLiquify;
        uint256 dynamicLiquidityFee;
        uint256 totalBNBFee;

        if (smartFee){
            dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : smartLiquidityFee;
            amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalSmartFee).div(2);
            totalBNBFee = totalSmartFee.sub(dynamicLiquidityFee.div(2));
        }
        else{
            dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
            amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
            totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
        }
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

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
        
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection;
        uint256 amountBNBMarketing;

        if (smartFee){
            amountBNBReflection = amountBNB.mul(smartReflectionFee).div(totalBNBFee);
            amountBNBMarketing = amountBNB.mul(smartMarketingFee).div(totalBNBFee);
        }
        else{
            amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
            amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
        }

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        
        // only to supress warning msg
        tmpSuccess = false;

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


    function setTxLimit(uint256 amount) external authorized {
        _maxTxAmount = amount;
    }

    function setTxLimitPercent(uint256 maxTxPercent) external authorized {
        _maxTxAmount = (_totalSupply * maxTxPercent ) / 100;
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

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsTimelockExempt(address holder, bool exempt) external authorized {
        isTimelockExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_reflectionFee).add(_marketingFee);
        feeDenominator = _feeDenominator;
        require(totalFee <= feeDenominator/4);
    }

    function setBuyFee(uint256 _buyFee, uint256 _buyFeeDenominator) external authorized {
        totalBuyFee = _buyFee;
        buyFeeDenominator = _buyFeeDenominator;
        require(totalBuyFee <= buyFeeDenominator/4);
    }

    function setSellFee(uint256 _sellFee, uint256 _sellFeeDenominator) external authorized {
        totalSellFee = _sellFee;
        sellFeeDenominator = _sellFeeDenominator;
        require(totalSellFee <= sellFeeDenominator/4);
    }

    function updateSmartFees() internal {
        updateSmartLiquidityFee();
        updateSmartMarketingFee();
        updateSmartReflectionFee();
        updateSellFees();
        updateBuyFees();
    }

    function getSmartLiquidityFee() public view returns (uint) {
        int256 buyVolumePercent = int(getSmartBuyVolumePercent());
        return uint((smartACoefLiquidityFee * buyVolumePercent * buyVolumePercent + smartBCoefLiquidityFee * buyVolumePercent + smartCCoefLiquidityFee) / int(smartCoefLiquidityFeeDenominator));
    }

    function updateSmartLiquidityFee() internal {
        smartLiquidityFee = getSmartLiquidityFee();
        totalSmartFee = 10000;
    }

    function getSmartMarketingFee() public view returns (uint) {
        int256 buyVolumePercent = int(getSmartBuyVolumePercent());
        return uint((smartACoefMarketingFee * buyVolumePercent * buyVolumePercent + smartBCoefMarketingFee * buyVolumePercent + smartCCoefMarketingFee) / int(smartCoefMarketingFeeDenominator));
    }

    function updateSmartMarketingFee() internal {
        smartMarketingFee = getSmartMarketingFee();
        totalSmartFee = 10000;
    }

    function getSmartRewardsFee() public view returns (uint) {
        int256 buyVolumePercent = int(getSmartBuyVolumePercent());
        return uint((smartACoefRewardsFee * buyVolumePercent * buyVolumePercent + smartBCoefRewardsFee * buyVolumePercent + smartCCoefRewardsFee) / int(smartCoefRewardsFeeDenominator));
    }

    function updateSmartReflectionFee() internal {
        smartReflectionFee = getSmartRewardsFee();
        totalSmartFee = 10000;
    }

    function updateSmartVolumeArray(bool isBuy) internal {
        newBNBBalance = getWBNBInLiquidity();
        if (isBuy){
            smartSellVolumeArray.push(0);
            smartBuyVolumeArray.push(newBNBBalance.sub(lastBNBBalance));
            smartTotalVolumeArray.push(newBNBBalance.sub(lastBNBBalance));
        }
        else{
            smartSellVolumeArray.push(lastBNBBalance.sub(newBNBBalance));
            smartBuyVolumeArray.push(0);
            smartTotalVolumeArray.push(lastBNBBalance.sub(newBNBBalance));
        }
        lastBNBBalance = newBNBBalance;
    }

    function initSmartVolume() internal {
        uint256 index;
        uint256 smartArrayLength = smartTotalVolumeArray.length;
        uint256 startIndex = 0;

        if (smartArrayLength > smartNbTx){
            startIndex = smartArrayLength.sub(smartNbTx);
        }

        smartTotalVolume = 0;
        smartBuyVolume = 0;
        smartSellVolume = 0;

        for (index = startIndex; index<smartArrayLength; index++){
            smartTotalVolume += smartTotalVolumeArray[index];
            smartBuyVolume += smartBuyVolumeArray[index];
            smartSellVolume += smartSellVolumeArray[index];
        }
    }

    function updateSmartVolume() internal {
        uint256 smartArrayLength = smartTotalVolumeArray.length;

        if (smartArrayLength - smartNbTx > 0){
            smartTotalVolume += (smartTotalVolumeArray[smartArrayLength - 1] - smartTotalVolumeArray[smartArrayLength - smartNbTx - 1]);
            smartBuyVolume += (smartBuyVolumeArray[smartArrayLength - 1] - smartBuyVolumeArray[smartArrayLength - smartNbTx - 1]);
            smartSellVolume += (smartSellVolumeArray[smartArrayLength - 1] - smartSellVolumeArray[smartArrayLength - smartNbTx - 1]);
        }
        else{
            smartTotalVolume += smartTotalVolumeArray[smartArrayLength - 1];
            smartBuyVolume += smartBuyVolumeArray[smartArrayLength - 1];
            smartSellVolume += smartSellVolumeArray[smartArrayLength - 1];
        }
    }

    function setSmartNbTx(uint256 _nbTx) external authorized {
        smartNbTx = _nbTx;
        initSmartVolume();
    }

    function getSmartBuyVolumePercent() public view returns (uint256) { // 100 * percent for more accuracy
        if (smartTotalVolume != 0){
            return smartBuyVolume.mul(100).div(smartTotalVolume);
        }
        else{
            return 50;
        }
    }

    function getSmartSellVolumePercent() public view returns (uint256) { // 100 * percent for more accuracy
        if (smartTotalVolume != 0){
            return smartSellVolume.mul(100).div(smartTotalVolume);
        }
        else{
            return 50;
        }
    }

    function setSmartCoefMarketingFee(int256 _a, int256 _b, int256 _c, uint256 _den) external authorized {
        smartACoefMarketingFee = _a;
        smartBCoefMarketingFee = _b;
        smartCCoefMarketingFee = _c;
        smartCoefMarketingFeeDenominator = _den;
    }

    function setSmartCoefLiquidityFee(int256 _a, int256 _b, int256 _c, uint256 _den) external authorized {
        smartACoefLiquidityFee = _a;
        smartBCoefLiquidityFee = _b;
        smartCCoefLiquidityFee = _c;
        smartCoefLiquidityFeeDenominator = _den;
    }

    function setSmartCoefRewardsFee(int256 _a, int256 _b, int256 _c, uint256 _den) external authorized {
        smartACoefRewardsFee = _a;
        smartBCoefRewardsFee = _b;
        smartCCoefRewardsFee = _c;
        smartCoefRewardsFeeDenominator = _den;
    }

    function setSmartCoefBuyFee(int256 _a, int256 _b, int256 _c, uint256 _den) external authorized {
        smartACoefBuyFee = _a;
        smartBCoefBuyFee = _b;
        smartCCoefBuyFee = _c;
        smartCoefBuyFeeDenominator = _den;
    }

    function setSmartCoefSellFee(int256 _a, int256 _b, int256 _c, uint256 _den) external authorized {
        smartACoefSellFee = _a;
        smartBCoefSellFee = _b;
        smartCCoefSellFee = _c;
        smartCoefSellFeeDenominator = _den;
    }

    function getSellFee() public view returns (uint) {
        int256 buyVolumePercent = int(getSmartBuyVolumePercent());
        return uint((smartACoefSellFee * buyVolumePercent * buyVolumePercent + smartBCoefSellFee * buyVolumePercent + smartCCoefSellFee) / int(smartCoefSellFeeDenominator));
    }

    function updateSellFees() internal {
        totalSellFee = getSellFee();
        sellFeeDenominator = 10000;
    }

    function getBuyFee() public view returns (uint) {
        int256 buyVolumePercent = int(getSmartBuyVolumePercent());
        return uint((smartACoefBuyFee * buyVolumePercent * buyVolumePercent + smartBCoefBuyFee * buyVolumePercent + smartCCoefBuyFee) / int(smartCoefBuyFeeDenominator));
    }

    function updateBuyFees() internal {
        totalBuyFee = getBuyFee();
        buyFeeDenominator = 10000;
    }

    function setSmartFeeMode(bool _enabled) external onlyOwner {
        require(smartFeeMode != _enabled, "Can't set flag to same status");
        setSmartFeeEnabled(_enabled);
        setSmartBuyFeeEnabled(_enabled);
        setSmartSellFeeEnabled(_enabled);
        smartFeeMode = _enabled;
    }

    function setSmartFeeEnabled(bool _enabled) public onlyOwner {
        require(smartFee != _enabled, "Can't set flag to same status");
        smartFee = _enabled;
    }

    function setSmartSellFeeEnabled(bool _enabled) public onlyOwner {
        require(smartSellFee != _enabled, "Can't set flag to same status");
        smartSellFee = _enabled;
    }

    function setSmartBuyFeeEnabled(bool _enabled) public onlyOwner {
        require(smartBuyFee != _enabled, "Can't set flag to same status");
        smartBuyFee = _enabled;
    }

    function isBot(address account) public view returns (bool) {
        return bots[account];
    }

    function removeBot(address account) external onlyOwner() {
        bots[account] = false;
    }

    function addBot(address account) external onlyOwner() {
        bots[account] = true;
    }

    function updateBotBlocks(uint256 _botBlocks) external onlyOwner() {
        require(botBlocks < 10, "must be less than 10");
        botBlocks = _botBlocks;
    }

    function updateBotFees(uint256 percent) public onlyOwner {
        require(percent >= 0 && percent <= 100, "must be between 0 and 100");
        botFees = percent;
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
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

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);

}