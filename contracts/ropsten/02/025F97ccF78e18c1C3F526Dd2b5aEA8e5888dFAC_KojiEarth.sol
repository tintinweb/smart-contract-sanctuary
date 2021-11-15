// SPDX-License-Identifier: Unlicensed

/*
koji.earth project
digital NFT comic book

BNB reflections:
2% to holders
1% to charity
1% to WBNB side of pool
1% to cake NFT rewards
1% to burn address

website: https://koji.earth
telegram: https://t.me/kojiearth

launched june 19th on ethereum, now officially moved to BSC
*/

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * Function modifier to require caller to be contract deployer
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!Owner"); _;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Transfer ownership to new address. Caller must be deployer. Leaves old deployer authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
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
    function process() external;
    function setDividendToken(address dividendToken) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 heldAmount;
        uint256 unpaidDividends;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 dividendToken;
    IDEXRouter router;
    
    address WETH;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1000000* (10 ** 9); //0.0001
    uint256 public minHoldAmountForRewards = 250000000 * (10**9); // Must hold 250 million tokens to receive BNB rewards.

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
    
    event DividendTokenUpdate(address dividendToken);

    constructor (address _router, address _dividendToken) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  // 0x10ED43C718714eb63d5aA57B78B54704E256024E
        _token = msg.sender;
        dividendToken = IBEP20(_dividendToken);
        WETH = router.WETH();
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {

        //existing holder balance changes
        if(amount > 0 && shares[shareholder].heldAmount > 0){
            
            //user had enough for rewards previously but now dropped below
            if (amount < minHoldAmountForRewards && shares[shareholder].heldAmount > minHoldAmountForRewards) {
                shares[shareholder].heldAmount = amount;
                shares[shareholder].amount = 0;
                totalShares = totalShares.sub(shares[shareholder].heldAmount);
            }

            //user didn't have enough for rewards and doesn't now either
            if (amount < minHoldAmountForRewards && shares[shareholder].heldAmount < minHoldAmountForRewards) {
                shares[shareholder].heldAmount = amount;
                shares[shareholder].amount = 0;
            }

            //user bought more to qualify for rewards
            if (amount > minHoldAmountForRewards && shares[shareholder].heldAmount < minHoldAmountForRewards) {
                shares[shareholder].amount = amount;
                shares[shareholder].heldAmount = amount;
                totalShares = totalShares.add(amount);
                shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            }

            //user bought more but already qualified for rewards
            if (amount > minHoldAmountForRewards && shares[shareholder].heldAmount > minHoldAmountForRewards) {
                shares[shareholder].amount = amount;
                shares[shareholder].heldAmount = amount;
                totalShares = totalShares.sub(shares[shareholder].heldAmount).add(amount);
                shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            }

        }

        //new holder
        if(amount > 0 && shares[shareholder].heldAmount == 0){
            addShareholder(shareholder);
            
            if (amount < minHoldAmountForRewards) {
                shares[shareholder].heldAmount = amount;
                shares[shareholder].amount = 0;
            } else {
                shares[shareholder].amount = amount;
                shares[shareholder].heldAmount = amount;
                totalShares = totalShares.add(amount);
                shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            }
        }

        //existing holder cashed out
        if(amount == 0 && shares[shareholder].heldAmount > 0){

            if(shares[shareholder].unpaidDividends > 0){
                distributeDividend(shareholder);
            }

            if (shares[shareholder].heldAmount > minHoldAmountForRewards) {
                totalShares = totalShares.sub(shares[shareholder].heldAmount);
            }
            
            shares[shareholder].amount = 0;
            shares[shareholder].heldAmount = 0;
            shares[shareholder].unpaidDividends = 0;
            removeShareholder(shareholder);
            
        }

    }

    function deposit() external payable override onlyToken {
        uint256 amount = msg.value;

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process() external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 iterations = 0;
        currentIndex = 0;

        while(iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                shares[shareholders[currentIndex]].unpaidDividends = shares[shareholders[currentIndex]].unpaidDividends.add(getUnpaidEarnings(shareholders[currentIndex]));
            }

            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return getUnpaidEarnings(shareholder) > minDistribution && shares[shareholder].amount > 0;
    }

     function distributeDividend(address shareholder) public {
        if(shares[shareholder].amount == 0){ return; } 

        require(shouldDistribute(shareholder), "Holder doesn't have the required amount for distribution");
        
        uint256 amount = shares[shareholder].unpaidDividends;

        if (amount == 0){ return; }
        
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            (bool successShareholder, /* bytes memory data */) = payable(shareholder).call{value: amount, gas: 30000}("");
            require(successShareholder, "Shareholder rejected BNB transfer");
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].unpaidDividends = 0;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function reinvestDividend(address shareholder) public {
        if(shares[shareholder].amount == 0){ return; } 

        require(shouldDistribute(shareholder), "Holder doesn't have the required amount for distribution");
        
        uint256 amount = shares[shareholder].unpaidDividends;

        if (amount == 0){ return; }
        
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);

            address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = address(this);

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
                1000000000,
                path,
                address(shareholder),
                block.timestamp           
            );

            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].unpaidDividends = 0;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount < minHoldAmountForRewards){ return 0; }

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
    
    function setDividendToken(address _dividendToken) external override onlyToken {
        dividendToken = IBEP20(_dividendToken);
        emit DividendTokenUpdate(_dividendToken);
    }
    
    function getDividendToken() external view returns (address) {
        return address(dividendToken);
    }

    function changeMinHold(uint256 _amount) external {

        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 iterations = 0;
        currentIndex = 0;

        //holding requirement is higher
        if (_amount > minHoldAmountForRewards) {
            while(iterations < shareholderCount) {
                if(currentIndex >= shareholderCount){
                    currentIndex = 0;
                }

                //if holder isn't holding above the new amount, doesn't qualify
                if(shares[shareholders[currentIndex]].heldAmount < _amount) {
                    shares[shareholders[currentIndex]].amount = 0;
                    totalShares = totalShares.sub(shares[shareholders[currentIndex]].heldAmount);
                }

                currentIndex++;
                iterations++;
            }
        }

        //holding requirement is lower
        if (_amount < minHoldAmountForRewards) {
            while(iterations < shareholderCount) {
                if(currentIndex >= shareholderCount){
                    currentIndex = 0;
                }

                //if holder now qualifies
                if(shares[shareholders[currentIndex]].heldAmount > _amount) {
                    shares[shareholders[currentIndex]].amount = shares[shareholders[currentIndex]].heldAmount;
                    totalShares = totalShares.add(shares[shareholders[currentIndex]].heldAmount);
                    shares[shareholders[currentIndex]].totalExcluded = getCumulativeDividends(shares[shareholders[currentIndex]].amount);
                }

                currentIndex++;
                iterations++;
            }
        }

        minHoldAmountForRewards = _amount;
    }

    function viewMinHold() external view returns (uint256) {
        return minHoldAmountForRewards;
    }

    function holderInfo(address _holder) external view returns (uint256, uint256, uint256, uint256, uint256) {
        return (shares[_holder].amount, shares[_holder].heldAmount, shares[_holder].unpaidDividends, shares[_holder].totalExcluded, shares[_holder].totalRealised);
    }

    function mathInfo() external view returns (uint256, uint256, uint256, uint256, uint256) {
        return (totalShares, totalDividends, totalDistributed, dividendsPerShare, dividendsPerShareAccuracyFactor);
    }
    
}

contract KojiEarth is IBEP20, Auth {
    using SafeMath for uint256;

    address WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "koji.earth";
    string constant _symbol = "KOJI";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1000000000000 * (10 ** _decimals);
    uint256 public _maxTxAmountBuy = _totalSupply;
    uint256 public _maxTxAmountSell = _totalSupply;
    
    uint256 public _maxWalletToken = _totalSupply; //13 * 10**9 * (10 ** _decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isBot;

    uint256 initialBlockLimit = 1;
    
    uint256 reflectionFee = 10;
    uint256 charityFee = 10;
    uint256 buybackFee = 10;
    uint256 cakeFee = 10;
    uint256 burnFee = 10;
    uint256 taxRatio = 200;
    uint256 public totalFee = 50;
    uint256 public feeDenominator = 1000;
    uint256 public WETHaddedToPool;

    address public charityWallet;
    address public cakeWallet;

    IDEXRouter public router;
    IWETH public WETHrouter;
    address public pair;

    uint256 public launchedAt;

    bool shouldProcess = false;
    bool public distributorDeposit = true;
    bool public teamWalletDeposit = true;
    bool public addToLiquid = true;

    DividendDistributor distributor;
    uint256 distributorGas = 750000;

    bool public swapEnabled = true;
    uint256 private swapThreshold = _totalSupply / 100000; // 10M
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        //router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); //main
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //test
            
        address _presaler = msg.sender;
            
        WETH = router.WETH();
        
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        distributor = new DividendDistributor(address(router), WETH);

        isFeeExempt[_presaler] = true;
        isDividendExempt[_presaler] = true;
        isTxLimitExempt[_presaler] = true;
        isTxLimitExempt[DEAD] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        charityWallet = 0x3E596691f96f44055a3718c10C37Fc093998EC74;
        cakeWallet = 0x105ae2202A44b3C81C7865B508765Ae4E4b2c033;
        
        _balances[_presaler] = _totalSupply;
        emit Transfer(address(0), _presaler, _totalSupply);
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
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _tF(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _tF(sender, recipient, amount);
    }

    function _tF(address s, address r, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(s, r, amount); }
        
        checkTxLimit(s, r, amount);

        if(shouldSwapBack()){ swapBack(); }

        if(!launched() && r == pair){ require(_balances[s] > 0); launch(); }

        _balances[s] = _balances[s].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(s) ? takeFee(s, amount) : amount;
        
        if(r != pair && !isTxLimitExempt[r]){
            uint256 contractBalanceRecepient = balanceOf(r);
            require(contractBalanceRecepient + amountReceived <= _maxWalletToken, "Exceeds maximum wallet token amount"); 
        }
        
        _balances[r] = _balances[r].add(amountReceived);

        if(!isDividendExempt[s]){ try distributor.setShare(s, _balances[s]) {} catch {} }
        if(!isDividendExempt[r]){ try distributor.setShare(r, _balances[r]) {} catch {} }

        try distributor.process() {} catch {}

        emit Transfer(s, r, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function manualBurn(uint256 amount) external onlyOwner returns (bool) {
        return _basicTransfer(address(this), DEAD, amount);
    }

    function checkTxLimit(address sender, address receiver, uint256 amount) internal view {
        sender == pair
            ? require(amount <= _maxTxAmountBuy || isTxLimitExempt[receiver], "Buy TX Limit Exceeded")
            : require(amount <= _maxTxAmountSell || isTxLimitExempt[sender], "Sell TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool bot) public view returns (uint256) {
        // Anti-bot, fees as 99% for the first block
        if(launchedAt + initialBlockLimit >= block.number || bot){ return feeDenominator.sub(1); }
        return totalFee;
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(isBot[sender])).div(feeDenominator);

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

    function swapBack() internal swapping {

        //ideally we can exchange the whole balance so it doesn't build to a huge amount
        uint256 amountToSwap = IBEP20(address(this)).balanceOf(address(this));

        //lets burn the 1% (20% of the total tax)
        uint256 burnAmount = amountToSwap.mul(taxRatio).div(feeDenominator);

        amountToSwap = amountToSwap.sub(burnAmount);

        //"thoiya!" ~ Randy Marsh
        IBEP20(address(this)).transfer(address(DEAD), burnAmount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        //we want to put back any WBNB into the pool to give ourselves the best price
        if (addToLiquid) {
            uint256 balance = IWETH(WETH).balanceOf(address(this));
            if (balance > 0) {
                IWETH(WETH).transfer(pair, balance);
                WETHaddedToPool = WETHaddedToPool.add(balance);
            }
        }

        //dump the built up tokens
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp           
        );

        //calculate the distribution
        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        
        uint256 amountBNBcharity = amountBNB.mul(taxRatio).div(feeDenominator);
        uint256 amountBNBbuyback = amountBNB.mul(taxRatio).div(feeDenominator);
        uint256 amountBNBcake = amountBNB.mul(taxRatio).div(feeDenominator);
        
        uint256 amountBNBReflection = amountBNB.sub(amountBNBcharity).sub(amountBNBbuyback).sub(amountBNBcake);

        //set the total shares
        if (distributorDeposit) {
            //try distributor.deposit(amountBNBReflection) {} catch {}
            try distributor.deposit{value: amountBNBReflection}() {} catch {}
        }
        
        //deposit to the team wallets
        if (teamWalletDeposit) {
        (bool successTeam1, /* bytes memory data */) = payable(charityWallet).call{value: amountBNBcharity, gas: 30000}("");
        require(successTeam1, "Charity wallet rejected BNB transfer");

        (bool successTeam2, /* bytes memory data */) = payable(cakeWallet).call{value: amountBNBcake, gas: 30000}("");
        require(successTeam2, "Cake wallet rejected BNB transfer");

        }
        
        //convert the buyback amount to WBNB and hold until the next qualifying sell
        IWETH(WETH).deposit{value : amountBNBbuyback}();
        
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }
    
    function setInitialBlockLimit(uint256 blocks) external onlyOwner {
        require(blocks > 0, "Blocks should be greater than 0");
        initialBlockLimit = blocks;
    }

    function setBuyTxLimit(uint256 amount) external onlyOwner {
        _maxTxAmountBuy = amount;
    }
    
    function setSellTxLimit(uint256 amount) external onlyOwner {
        _maxTxAmountSell = amount;
    }
    
    function setMaxWalletToken(uint256 amount) external onlyOwner {
        _maxWalletToken = amount;
    }
    
    function setBot(address _address, bool toggle) external onlyOwner {
        isBot[_address] = toggle;
        _setIsDividendExempt(_address, toggle);
    }
    
    function isInBot(address _address) public view onlyOwner returns (bool) {
        return isBot[_address];
    }

    function _setIsDividendExempt(address holder, bool exempt) internal {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }
    
    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        _setIsDividendExempt(holder, exempt);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _reflectionFee, uint256 _charityFee, uint256 _buybackFee, uint256 _cakeFee, uint256 _burnFee) external onlyOwner {
        reflectionFee = _reflectionFee;
        charityFee = _charityFee;
        buybackFee = _buybackFee;
        cakeFee = _cakeFee;
        burnFee = _burnFee;
        totalFee = _reflectionFee.add(_charityFee).add(_buybackFee).add(_cakeFee).add(_burnFee);
        //Total fees has to be less than 10%
        require(totalFee < feeDenominator/10, "Total Fee cannot be more than 10%");
    }
    
    function setFeeReceivers(address _charityWallet, address _buybackWallet) external onlyOwner {
        charityWallet = _charityWallet;
        cakeWallet = _buybackWallet;
    }
    
    function getFees() public view returns (uint256, uint256, uint256, uint256, uint256) {
        return (reflectionFee, charityFee, buybackFee, cakeFee, burnFee);
    }
    
    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function setDistributorDeposit(bool _status) external onlyOwner {
        distributorDeposit = _status;
    }

    function setTeamWalletDeposit(bool _status) external onlyOwner {
        teamWalletDeposit = _status;
    }

    function setAddToLiquid(bool _status) external onlyOwner {
        addToLiquid = _status;
    }

    // This will allow to rescue ETH sent by mistake directly to the contract
    function rescueETHFromContract() external onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }

    // Function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    function transferERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
       
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    function getPending(address _holder) external view returns (uint256 pending) {
        return distributor.getUnpaidEarnings(_holder);
    }

    function withdraw() external {
        distributor.distributeDividend(msg.sender);
    }

    function reinvest() external {
        distributor.reinvestDividend(msg.sender);
    }

    function getRewardsToken() external view returns (address) {
        return distributor.getDividendToken();
    }

    function setRewardsToken(address _address) external onlyOwner {
        distributor.setDividendToken(_address);
    }

    function settaxRatio(uint256 _amount) external onlyOwner {
        require(_amount <= 200, "burn ratio cannot be more than 20 percent of total tax");
        taxRatio = _amount;
    }

    function changeMinHold(uint256 _amount) external onlyOwner {
        distributor.changeMinHold(_amount);
    }

    function viewMinHold() external view returns (uint256 amount) {
        return distributor.viewMinHold();
    }
 
    function viewHolderInfo(address _address) external view returns (uint256 amount, uint256 held, uint256 unpaid, uint256 excluded, uint256 realised) {
        return distributor.holderInfo(_address);
    }
    
    //totalShares, totalDividends, totalDistributed, dividendsPerShare, dividendsPerShareAccuracyFactor
    function viewMathInfo() external view returns (uint256 totalshares, uint256 totaldividends, uint256 totaldistributed, uint256 dividendspershare, uint256 accuracyfactor) {
        return distributor.mathInfo();
    }

    function startProcess() external onlyOwner {
        distributor.process();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

