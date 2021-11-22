/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

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

interface IPair {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
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
    
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

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

    address private _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

   //IBEP20 private DOGE = IBEP20(0xbA2aE424d960c26247Dd6c32edC70B295c744C43); // mainnet DOGE token
    IBEP20 private DOGE = IBEP20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7); // testnet BUSD token
    
    IDEXRouter private router;

    address[] private shareholders;
    mapping (address => uint256) private shareholderIndexes;
    mapping (address => uint256) private shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 18);

    uint256 private currentIndex;

    bool private initialized;
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
        uint256 balanceBefore = DOGE.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(DOGE);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = DOGE.balanceOf(address(this)).sub(balanceBefore);

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
            DOGE.transfer(shareholder, amount);
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
}

contract DaddyDogeBack is IBEP20, Auth {
    using SafeMath for uint256;

    // address private DOGE = 0xbA2aE424d960c26247Dd6c32edC70B295c744C43; // mainnet DOGE token
    address private DOGE = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; // testnet BUSD token
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Daddy Dogeback";
    string constant _symbol = "DADDYDB";
    uint8 constant _decimals = 18;

    uint256 private _totalSupply = 1000000000000000 * (10 ** _decimals);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private isFeeExempt;
    mapping (address => bool) private isDividendExempt;
    mapping (address => bool) private liquidityHolders;
    mapping (address => bool) private automatedMarketMakerPairs;

    uint256 private dividendShare = 1500;
    uint256 private marketingShare = 300;
    uint256 private partnerShare = 100;
    uint256 private teamShare = 300;
    uint256 private liquidityShare = 200;
    uint256 private buybackShare = 200;
    uint256 private totalShare = 2600;
    
    uint256 private denominator = 10000;
    
    uint256 private transactionTaxUpdateDivsor = 20;
    
    uint256 public baseTax = 800;
    uint256 public dynamicTaxStep = 5;
    
    uint256 public buyTax;
    uint256 public buyTaxFloor = 400;
    bool public dynamicBuyTaxEnabled = false;
    
    uint256 public sellTax;
    uint256 public sellTaxCeiling = 3000;
    bool public dynamicSellTaxEnabled = true;
    
    bool public goldenHour;
    uint256 public goldenHourStartTimestamp;

    address public marketingReceiver = 0x43d17c90b178BFA043Cd6552Ae7e99C2F2A551B9;
    address public teamReceiver = 0xB877076A0962b442BBBD15Da9ec204a29F6E71bC;
    address public partnerReceiver = 0x0cC19b76F08373134aB239d78711C8900347f804;

    uint256 public targetLiquidity = 25;
    uint256 public targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pcsPair;

    uint256 public launchedAt;

    bool public autoBuybackEnabled = true;
    uint256 public autoBuybackAccumulator;
    uint256 public autoBuybackAmount = 1 * (10 ** _decimals);
    uint256 public autoBuybackBlockPeriod;
    uint256 public autoBuybackBlockLast;

    DividendDistributor private distributor;
    uint256 public distributorGas = 500000;

    bool public swapEnabled = true;
    bool public hasLiqBeenAdded;
    uint256 public swapMultiplier = 1;
    uint256 public swapThreshold = _totalSupply / 20000;
    bool public swapSetToThreshold = true;
    bool public inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        // router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); // mainnet
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // testnet
        pcsPair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = 2**256 - 1;

        distributor = new DividendDistributor(address(router));

        isDividendExempt[pcsPair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;
        
        isFeeExempt[marketingReceiver] = true;
        isFeeExempt[teamReceiver] = true;
        isFeeExempt[partnerReceiver] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[ZERO] = true;
        
        _setAutomatedMarketMakerPair(pcsPair, true);
        
        liquidityHolders[msg.sender] = true;

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
        return approve(spender, 2**256 - 1);
    }
    
    function whitelistPresale(address _presaleAddress) external onlyOwner {
  	    liquidityHolders[_presaleAddress] = true;
        isFeeExempt[_presaleAddress] = true;
        isDividendExempt[_presaleAddress] = true;
  	}
  	
  	function setDynamicTaxStatuses(bool _dynamicBuyTaxEnabled, bool _dynamicSellTaxEnabled) external onlyOwner {
  	    dynamicBuyTaxEnabled = _dynamicBuyTaxEnabled;
  	    dynamicSellTaxEnabled = _dynamicSellTaxEnabled;
  	}
  	
  	function setAutomatedMarketMakerPair(address _pair, bool _value) public onlyOwner {
        require(_pair != pcsPair);

        _setAutomatedMarketMakerPair(_pair, _value);
    }

    function _setAutomatedMarketMakerPair(address _pair, bool _value) private {
        require(automatedMarketMakerPairs[_pair] != _value);
        automatedMarketMakerPairs[_pair] = _value;

        if(_value) {
            isDividendExempt[_pair] = true;
        }

        emit SetAutomatedMarketMakerPair(_pair, _value);
    }
    
    function _checkLiquidityAdd(address from, address to) internal {
        // if liquidity is added by the _liquidityholders set trading enables to true and start the anti sniper timer
        require(!hasLiqBeenAdded);

        if(liquidityHolders[from] && automatedMarketMakerPairs[to]) {
            hasLiqBeenAdded = true;
            buyTax = baseTax;
            sellTax = baseTax;
            launch();
        }
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    
    function updateTransactionTaxes(bool selling) internal {
        if(!selling) {
            if(dynamicBuyTaxEnabled) {
                if(buyTax > buyTaxFloor) {
                    if(sellTax > baseTax) {
                        sellTax = sellTax.sub(dynamicTaxStep);
                    }
                    buyTax = buyTax.sub(dynamicTaxStep);
                }
            }
        } else {
            if(sellTax < sellTaxCeiling) {
                if(buyTax < baseTax) {
                    buyTax = buyTax.add(dynamicTaxStep);
                }
                sellTax = sellTax.add(dynamicTaxStep);
            }
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != 2**256 - 1){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(launched() || (isFeeExempt[sender] || isFeeExempt[recipient]));

        if(inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
        
        if(block.timestamp > launchedAt.add(2 hours) && !dynamicBuyTaxEnabled) {
            dynamicBuyTaxEnabled = true;
        }

        if (!hasLiqBeenAdded) {
            _checkLiquidityAdd(sender, recipient);
        }
        
        if(goldenHour && block.timestamp > goldenHourStartTimestamp + 1 hours) {
            goldenHour = false;
            dynamicBuyTaxEnabled = true;
        }

        if (amount == 0) {
            return _basicTransfer(sender, recipient, 0);
        }
        
        bool feeExempt = isFeeExempt[sender] || isFeeExempt[recipient];
        bool walletToWalletTransfer = !automatedMarketMakerPairs[sender] || !automatedMarketMakerPairs[recipient];

        if (!feeExempt || !walletToWalletTransfer) {
            if(amount >= getDDBEquivalentValue().div(transactionTaxUpdateDivsor)) {
                updateTransactionTaxes(!automatedMarketMakerPairs[sender]);
            }
            amount = takeFee(sender, !automatedMarketMakerPairs[sender], amount);
        }

        if(shouldSwapBack(sender)){ swapBack(); }
        if(shouldAutoBuyback(sender)){ triggerAutoBuyback(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        
        _balances[recipient] = _balances[recipient].add(amount);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, bool selling, uint256 amount) internal returns (uint256) {
        uint256 feeAmount;
        
        if(selling) {
            feeAmount = amount.mul(sellTax).div(denominator);
        } else {
            if(!goldenHour) {
                feeAmount = amount.mul(buyTax).div(denominator);
            }
        }

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack(address sender) internal view returns (bool) {
        if(swapSetToThreshold) {
            return !automatedMarketMakerPairs[sender]
            && !inSwap
            && swapEnabled
            && _balances[address(this)] >= swapThreshold;
        } else {
            return !automatedMarketMakerPairs[sender]
            && !inSwap
            && swapEnabled
            && _balances[address(this)] >= getDDBEquivalentValue().mul(swapMultiplier);
        }
    }
    
    function startGoldenHour() external authorized {
        require(!goldenHour);
        goldenHourStartTimestamp = block.timestamp;
        goldenHour = true;
        dynamicBuyTaxEnabled = false;
    }

    function disableGoldenHour() external authorized {
        require(goldenHour);
        goldenHour = false;
        dynamicBuyTaxEnabled = true;
    }
    
    function updateTransactionTaxUpdateDivisor(uint256 _divisor) external authorized {
        require(_divisor > 0 && _divisor < 50);
        transactionTaxUpdateDivsor = _divisor;
    }

    function swapBack() internal swapping {
        uint256 tokensToSwap = swapSetToThreshold ? swapThreshold : getDDBEquivalentValue().mul(swapMultiplier);
        
        uint256 dynamicLiquidityShare = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityShare;
        uint256 amountToLiquify = tokensToSwap.mul(dynamicLiquidityShare).div(totalShare).div(2);
        uint256 amountToSwap = tokensToSwap.sub(amountToLiquify);

        uint256 amountBNB = swapForBNB(amountToSwap);
    
        uint256 totalBNBShare = totalShare.sub(dynamicLiquidityShare.div(2));
        
        if(amountToLiquify > 0){
            addLiquidity(amountBNB.mul(dynamicLiquidityShare).div(totalBNBShare), amountToLiquify);
        }
        
        uint256 amountBNBDividend = amountBNB.mul(dividendShare).div(totalBNBShare);
        uint256 amountBNBMarketing = amountBNB.mul(marketingShare).div(totalBNBShare);
        uint256 amountBNBPartner = amountBNB.mul(partnerShare).div(totalBNBShare);
        uint256 amountBNBTeam = amountBNB.mul(teamShare).div(totalBNBShare);

        try distributor.deposit{value: amountBNBDividend}() {} catch {}
        (bool marketingShareSuccess, /* bytes memory data */) = payable(marketingReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        require(marketingShareSuccess);
        (bool teamShareSuccess, /* bytes memory data */) = payable(teamReceiver).call{value: amountBNBTeam, gas: 30000}("");
        require(teamShareSuccess);
        (bool partnerShareSuccess, /* bytes memory data */) = payable(partnerReceiver).call{value: amountBNBPartner, gas: 30000}("");
        require(partnerShareSuccess);
    }
    
    function swapForBNB(uint256 amountToSwap) internal returns (uint256) {
        uint256 balanceBefore = address(this).balance;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        
        return address(this).balance.sub(balanceBefore);
    }
    
    function addLiquidity(uint256 amountBNBLiquidity, uint256 amountToLiquify) internal {
        router.addLiquidityETH{value: amountBNBLiquidity}(
            address(this),
            amountToLiquify,
            0,
            0,
            teamReceiver,
            block.timestamp
        );
        emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
    }

    function shouldAutoBuyback(address sender) internal view returns (bool) {
        return !automatedMarketMakerPairs[sender]
            && !inSwap
            && autoBuybackEnabled
            && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number
            && address(this).balance >= autoBuybackAmount;
    }

    function triggerManualBuyback(uint256 amount) external authorized {
        buyTokens(amount, teamReceiver);
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, teamReceiver);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function getDDBEquivalentValue() internal view returns (uint256)
    {
        IPair pair = IPair(pcsPair);
        (uint256 Res0, uint256 Res1,) = pair.getReserves();
        
        uint256 bnb;
        uint256 nativeToken;
        
        if(pair.token0() == router.WETH()){
            bnb = Res0;
            nativeToken = Res1;
        }
        else {
            bnb = Res1;
            nativeToken = Res0;
        }
        
        return nativeToken.mul(1e18).div(bnb);
    }

    function setAutoBuybackSettings(bool _enabled, uint256 _amount, uint256 _period) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackAmount = _amount * (10 ** _decimals);
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }
    
    function inCaseTokensGetStuck(address _token) external authorized {
        require(_token != address(this));

        uint256 amount = IBEP20(_token).balanceOf(address(this));
        IBEP20(_token).transfer(marketingReceiver, amount);
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pcsPair);
        require(isDividendExempt[holder] != exempt);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        require(isFeeExempt[holder] != exempt, "Can't set holder to the same status");
        isFeeExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityShare, uint256 _buybackShare, uint256 _dividendShare, uint256 _marketingShare, uint256 _teamShare, uint256 _partnerShare) external authorized {
        liquidityShare = _liquidityShare;
        buybackShare = _buybackShare;
        dividendShare = _dividendShare;
        marketingShare = _marketingShare;
        teamShare = _teamShare;
        partnerShare = _partnerShare;
        totalShare = _liquidityShare.add(_buybackShare).add(_dividendShare).add(_marketingShare).add(_teamShare).add(_partnerShare);
        require(totalShare < denominator.div(100));
    }
    
    function setTaxthresholds(uint256 _buyTaxFloor, uint256 _sellTaxCeiling) external authorized {
        require(_buyTaxFloor > 0 && _buyTaxFloor < 800);
        require(_sellTaxCeiling > 800 && _sellTaxCeiling < 4000);
        buyTaxFloor = _buyTaxFloor;
        sellTaxCeiling = _sellTaxCeiling;
    }

    function setFeeReceivers(address _marketingReceiver, address _teamReceiver, address _partnerReceiver) external authorized {
        marketingReceiver = _marketingReceiver;
        teamReceiver = _teamReceiver;
        partnerReceiver = _partnerReceiver;
    }

    function setSwapBackSettings(bool _enabled, bool _swapSetToThreshold, uint256 _multiplier, uint256 _divisor) external authorized {
        swapEnabled = _enabled;
        swapSetToThreshold = _swapSetToThreshold;
        swapMultiplier = _multiplier;
        swapThreshold = _totalSupply / _divisor;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas > 0 && gas < 750000);
        distributorGas = gas;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pcsPair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
}