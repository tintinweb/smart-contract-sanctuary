// SPDX-License-Identifier: Unlicensed

/*
koji.earth project
launched on Ethereum 6.2021, killed by high gas fees
relaunching on BSC with new, better contract at original public sale price

Website: https://koji.earth
Telegram: https://t.me/kojiearth
Withdraw/Reinvest dividends : https://app.koji.earth

Staking & Full NFT comic book coming Q1 2022 (maybe sooner!)

Tokenomics: 
25 Million KOJI required to receive divs in BNB
Supply: 1 Trillion
                                /   1% KOJI to burn wallet
                                |   6% left converts to BNB
7% tax on buy/sell/transfer -   |   40% of BNB to holders
                                |   20% of BNB to liquidity
                                |   20% to charity 
                                \   20% to admin (artwork, marketing, etc..)

*/

pragma solidity ^0.8.9;

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

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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
    function setDistributionCriteria(uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function addBNB() external payable;
    function setDividendToken(address dividendToken) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 unpaidDividends;
        uint256 totalExcluded;
        uint256 totalRealised;
        bool rewardEligible;
    }

    IBEP20 dividendToken;
    IDEXRouter router;
    
    address WETH;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => uint256) public shareholderExpired;
    mapping (address => Share) public shares;
    mapping (address => bool) shareholderAdded;

    uint256 public totalWithdrawn;
    uint256 public totalReinvested;
    uint256 public netDividends;
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 distribWalletGas = 40000;
    uint256 distribReinvestGas = 450000;

    uint256 public impoundTimelimit = 1; //2592000; //1 month default
    uint256 public minDistribution = 1000000* (10 ** 9); //0.001
    uint256 public minHoldAmountForRewards = 25000000 * (10**9); // Must hold 25 million tokens to receive rewards

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
            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
        dividendToken = IBEP20(_dividendToken);
        WETH = router.WETH();
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            shares[shareholder].unpaidDividends = shares[shareholder].unpaidDividends.add(getUnpaidEarnings(shareholder));
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            if (amount >= minHoldAmountForRewards) {
                addShareholder(shareholder);
            }
        }else if(amount == 0 && shares[shareholder].amount > 0){
            if (shares[shareholder].unpaidDividends == 1 || shares[shareholder].unpaidDividends == 0) {
                removeShareholder(shareholder);
            }
            
        }

        bool boolGetsRewards = shares[shareholder].rewardEligible;

        if (amount >= minHoldAmountForRewards) {
            if (!boolGetsRewards) {
                shares[shareholder].rewardEligible = true;
                totalShares = totalShares.add(amount);
                shares[shareholder].amount = amount;
            } else {
                totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
                shares[shareholder].amount = amount;
            }
        } else {
            if (boolGetsRewards) {
                shares[shareholder].rewardEligible = false;
                totalShares = totalShares.sub(shares[shareholder].amount);
                shares[shareholder].amount = 0;
            } else {
                shares[shareholder].amount = 0;
            }
        }

        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 amount = msg.value;

        netDividends = netDividends.add(amount);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function addBNB() external payable override onlyToken {
        uint256 amount = msg.value;
    }

     //withdraw dividends
     function distributeDividend(address shareholder, uint256 percent) public {

         require(percent >= 25 && percent <= 100, "Percent of withdrawal is outside of parameters");
        
         uint256 fullamount = shares[shareholder].unpaidDividends.add(getUnpaidEarnings(shareholder));
        
         uint256 netamount = fullamount.mul(percent).div(100);
        
        if(netamount > 0){
            
            netamount = netamount.sub(1); //this is so we aren't short on dust in the holding wallet

            totalDistributed = totalDistributed.add(netamount);

            (bool successShareholder, /* bytes memory data */) = payable(shareholder).call{value: netamount, gas: distribWalletGas}("");
            require(successShareholder, "Shareholder rejected BNB transfer");
            shareholderClaims[shareholder] = block.timestamp;
            
            shares[shareholder].unpaidDividends = fullamount.sub(netamount); 
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(netamount);

            totalWithdrawn = totalWithdrawn.add(netamount);
            netDividends = netDividends.sub(netamount);          


        } else {
            return; 
        }
    }

    //Reinvest dividends
    function reinvestDividend(address shareholder, uint256 percent, uint256 minOut) public {

        require(percent >= 25 && percent <= 100, "Percent of reinvestment is outside of parameters");

        uint256 fullamount = shares[shareholder].unpaidDividends.add(getUnpaidEarnings(shareholder));
        
        uint256 netamount = fullamount.mul(percent).div(100);

        if(netamount >= minDistribution){

           netamount = netamount.sub(1); //this is so we aren't short on dust in the holding wallet

            address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = _token;

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value:netamount, gas:distribReinvestGas}(
                minOut,
                path,
                address(shareholder),
                block.timestamp
            );

            totalDistributed = totalDistributed.add(netamount);
            
            shares[shareholder].unpaidDividends = fullamount.sub(netamount); 

            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(netamount);
            
            totalReinvested = totalReinvested.add(netamount);
            shareholderClaims[shareholder] = block.timestamp;
            netDividends = netDividends.sub(netamount);
            
        } else {
            return; 
        }
    }
    
    function getUnpaidDividends(address shareholder) public view returns (uint256 unpaidDividends) {
        return shares[shareholder].unpaidDividends;
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

    //Impounds all divs from non-KOJI holders that sold all, yet didn't claim rewards within time limit
    function sweep(uint256 gas) public {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        currentIndex = 0;
    
        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

                if (shares[shareholders[currentIndex]].unpaidDividends > 0 && shares[shareholders[currentIndex]].amount == 0 && block.timestamp.add(impoundTimelimit) > shareholderExpired[shareholders[currentIndex]]) {
                    impoundDividend(shareholders[currentIndex]);
                } 

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();

            currentIndex++;
            iterations++;
        }

        cleanup();
        
    }

    //Removes non-KOJI holders from array after sweep()
    function cleanup() internal {

        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 iterations = 0;
        currentIndex = 0;
    
        while(iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if (shares[shareholders[currentIndex]].unpaidDividends == 0 && shares[shareholders[currentIndex]].amount == 0 && block.timestamp.add(impoundTimelimit) > shareholderExpired[shareholders[currentIndex]]) {
                  removeShareholder(shareholders[currentIndex]); 
            } 

            currentIndex++;
            iterations++;
        }

    }


    //Impounds unclaimed dividends from wallets that sold all their tokens yet didn't claim rewards within the specified timeframe (default 30 days)
    function impoundDividend(address shareholder) internal {

        uint256 amount = shares[shareholder].unpaidDividends.add(getUnpaidEarnings(shareholder));

        uint256 netamount = amount.sub(1); //this is so we aren't short on dust in the holding wallet

        (bool successShareholder, /* bytes memory data */) = payable(_token).call{value: netamount, gas: distribWalletGas}("");
        require(successShareholder, "Shareholder rejected BNB transfer");

        shareholderClaims[shareholder] = block.timestamp;
        shareholderExpired[shareholder] = 9999999999;

        shares[shareholder].unpaidDividends = 0;

        netDividends = netDividends.sub(amount);

    }

    function addShareholder(address shareholder) internal {
        if (shareholderAdded[shareholder]) {
            return;
        } else {
            shareholderIndexes[shareholder] = shareholders.length;
            shareholders.push(shareholder);
            shareholderAdded[shareholder] = true;
        }
        
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
        shareholderAdded[shareholder] = false;
    }
    
    function setDividendToken(address _dividendToken) external override onlyToken {
        dividendToken = IBEP20(_dividendToken);
        emit DividendTokenUpdate(_dividendToken);
    }
    
    function getDividendToken() external view returns (address) {
        return address(dividendToken);
    }

    //Change the min hold requirement for rewards. In this contract, this new value can only be lowered or it will break lots of stuff
    function changeMinHold(uint256 _amount) external {

        require(_amount < minHoldAmountForRewards, "Min hold amount should be lower than current amount");
        
        minHoldAmountForRewards = _amount;
    }

    // Function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    function transferBEP20Tokens(address _tokenAddr, address _to, uint _amount) external {
        IBEP20(_tokenAddr).transfer(_to, _amount);
    }

    // This will allow to rescue ETH held in the distributor interface address
    function rescueETHFromContract() external {
        address payable _owner = payable(_token);
        _owner.transfer(address(this).balance);
    }

    function viewMinHold() external view returns (uint256) {
        return minHoldAmountForRewards;
    }

    function holderInfo(address _holder) external view returns (uint256, uint256, uint256, uint256) {
        return (shares[_holder].amount, shares[_holder].unpaidDividends, shares[_holder].totalRealised, shares[_holder].totalExcluded);
    }

    function mathInfo() external view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return (totalShares, netDividends, totalDistributed, totalReinvested, totalWithdrawn, totalDividends);
    }

    function getShareholderExpired(address _holder) external view returns (uint256) {
        return shareholderExpired[_holder];
    }

    function changeImpoundTimelimit(uint256 _timelimit) external {
        impoundTimelimit = _timelimit;
    }

    function changeDistribGas(uint256 _walletGas, uint256 _reinvestGas) external {
        distribWalletGas = _walletGas;
        distribReinvestGas = _reinvestGas;
    }

    function setDistributionCriteria(uint256 _minDistribution) external override onlyToken {
        minDistribution = _minDistribution;
    }

    function getDistributionCriteria() external view returns (uint256) {
        return minDistribution;
    }
}

contract KojiEarth is IBEP20, Auth, ReentrancyGuard {
    using SafeMath for uint256;

    address WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    IWETH WETHrouter;
    
    string constant _name = "koji.earth";
    string constant _symbol = "KOJI v0.06";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1000000000000 * (10 ** _decimals);
    uint256 public _maxTxAmountBuy = _totalSupply;
    uint256 public _maxTxAmountSell = _totalSupply;
    uint256 public _maxWalletToken = _totalSupply; 

    struct Partners {
        address token_addr;
        uint256 minHoldAmount;
        uint256 discount;
        bool enabled;
    }

    mapping (uint256 => Partners) private partners;
    address[] partneraddr;
    mapping (address => bool) partnerAdded;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isBot;

    uint256 initialBlockLimit = 1;
    
    uint256 public burnRatio = 142;
    uint256 public stakepoolRatio = 142;
    uint256 public taxRatio = 200;

    uint256 public totalFee = 70; //(7%)
    uint256 public partnerFeeLimiter = 50;
    uint256 public feeDenominator = 1000;
    uint256 public WETHaddedToPool;

    address public charityWallet;
    address public adminWallet;
    address public nftRewardWallet;
    address public stakePoolWallet;

    uint256 public totalCharity;
    uint256 public totalAdmin;
    uint256 public totalNFTrewards;
    uint256 public totalStakepool;

    IDEXRouter public router;
    
    address public pair;

    uint256 public launchedAt;

    bool public swapEnabled = true;
    bool public stakePoolActive = false;
    bool public nftPoolActive = false;
    bool public distributorDeposit = true;
    bool public teamWalletDeposit = true;
    bool public addToLiquid = true;
    bool public enablePartners = false;
    
    bool inSwap;
    
    DividendDistributor distributor;
    uint256 distributorGas = 750000;
    uint256 walletGas = 40000;
    uint256 depositGas = 350000;

    uint256 private swapThreshold = 100000000000000; 
    
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0xCc7aDc94F3D80127849D2b41b6439b7CF1eB4Ae0); //pcs test
        //router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); //pcs  
        //router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //uni
            
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
        adminWallet = 0x6A3Ca89608c2c9153daddb93589Fe27A98C30639;
        nftRewardWallet = 0x105ae2202A44b3C81C7865B508765Ae4E4b2c033;
        stakePoolWallet = 0xe4C97046c10ba4C1803403Df78cFe3a2E3481722;

        isFeeExempt[stakePoolWallet] = true;
        isDividendExempt[stakePoolWallet] = true;

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
        require(amount > 0, "Insufficient Amount");
        if(inSwap){ return _basicTransfer(s, r, amount); }

        checkTxLimit(s, r, amount);

        if (r == pair) {

            if(shouldSwapBack()){ swapBack(); }
        }

        if(!launched() && r == pair){ require(_balances[s] > 0); launch(); }

        _balances[s] = _balances[s].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(s) && shouldTakeFee(r) ? takeFee(s, r, amount) : amount;

        
        if(r != pair && !isTxLimitExempt[r]){
            uint256 contractBalanceRecepient = balanceOf(r);
            require(contractBalanceRecepient + amountReceived <= _maxWalletToken, "Exceeds maximum wallet token amount"); 
        }
        
        _balances[r] = _balances[r].add(amountReceived);

        if(!isDividendExempt[s]){ try distributor.setShare(s, _balances[s]) {} catch {}}
        if(!isDividendExempt[r]){ try distributor.setShare(r, _balances[r]) {} catch {}}
        
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

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount; 
        uint256 regularFee = getTotalFee(isBot[sender]);
        uint256 discountFee = 0;

        if (enablePartners && recipient != pair && sender == pair) {
            //scan wallet for BEP20 tokens matching those in struct 

            uint256 partnerCount = partneraddr.length;
            
            for (uint256 x = 0; x <= partnerCount; ++x) {

                Partners storage tokenpartners = partners[x];

                if (tokenpartners.enabled) {

                   if(IBEP20(address(tokenpartners.token_addr)).balanceOf(address(recipient)) >= tokenpartners.minHoldAmount) {

                       discountFee = discountFee.add(tokenpartners.discount);

                   } 

                } 
            }

            if (discountFee > regularFee.mul(partnerFeeLimiter).div(100)) {
                discountFee = regularFee.mul(partnerFeeLimiter).div(100);
            } else {
                discountFee = regularFee.sub(discountFee);
            }
            
            feeAmount = amount.mul(discountFee).div(feeDenominator);

        } else {

            feeAmount = amount.mul(regularFee).div(feeDenominator);

        }

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

        uint256 amountToSwap = IBEP20(address(this)).balanceOf(address(this));
        uint256 burnAmount = amountToSwap.mul(burnRatio).div(feeDenominator);

        IBEP20(address(this)).transfer(address(DEAD), burnAmount);

        if (stakePoolActive) {  
             
            uint256 stakePoolAmount = amountToSwap.mul(stakepoolRatio).div(feeDenominator);

            amountToSwap = amountToSwap.sub(stakePoolAmount);

            IBEP20(address(this)).transfer(address(stakePoolWallet), stakePoolAmount);

            totalStakepool = totalStakepool.add(stakePoolAmount);

            amountToSwap = amountToSwap.sub(burnAmount);

        } else {
            amountToSwap = amountToSwap.sub(burnAmount);
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        //We want to put any built up WBNB back into the pool 
        if (addToLiquid) {
            uint256 balance = IWETH(WETH).balanceOf(address(this));
            if (balance > 0) {
                IWETH(WETH).transfer(pair, balance);
                WETHaddedToPool = WETHaddedToPool.add(balance);
            }
        }

        //Exchange the built up tokens
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp           
        );

        //Calculate the distribution
        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 taxSplit = amountBNB.mul(taxRatio).div(feeDenominator);
        uint256 amountBNBcharity = taxSplit;
        uint256 amountBNBadmin = taxSplit;
        uint256 amountBNBbuyback = taxSplit;
        uint256 amountBNBReflection;
        uint256 amountBNBnft;

        if (nftPoolActive) {
            amountBNBnft = taxSplit;
            amountBNBReflection = amountBNB.sub(amountBNBcharity).sub(amountBNBbuyback).sub(amountBNBadmin).sub(amountBNBnft);

            (bool successTeam3, /* bytes memory data */) = payable(nftRewardWallet).call{value: amountBNBnft, gas: walletGas}("");
            require(successTeam3, "NFT reward wallet rejected BNB transfer");

            totalNFTrewards = totalNFTrewards.add(amountBNBnft);

        } else {

            amountBNBReflection = amountBNB.sub(amountBNBcharity).sub(amountBNBbuyback).sub(amountBNBadmin);
        }
        
        //Deposit into the distributor
        if (distributorDeposit) {

            try distributor.deposit{value: amountBNBReflection}() {} catch {}
        }
        
        //Deposit to the team wallets
        if (teamWalletDeposit) {
        (bool successTeam1, /* bytes memory data */) = payable(charityWallet).call{value: amountBNBcharity, gas: walletGas}("");
        require(successTeam1, "Charity wallet rejected BNB transfer");

        totalCharity = totalCharity.add(amountBNBcharity);

        (bool successTeam2, /* bytes memory data */) = payable(adminWallet).call{value: amountBNBadmin, gas: walletGas}("");
        require(successTeam2, "Admin wallet rejected BNB transfer");

        totalAdmin = totalAdmin.add(amountBNBadmin);
        
        }
        
        //Convert the buyback amount to WBNB and hold until the next qualifying sell
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
    
    function isInBot(address _address) public view returns (bool) {
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

    function setFee(uint256 _totalFee) external onlyOwner {
        //Total fees has to be between 0 and 10 percent
        require(_totalFee >= 0 && _totalFee <= 100, "Total Fee must be between 0 and 100 (100 = ten percent)");
        totalFee = _totalFee;
        
    }
    
    function setFeeReceivers(address _charityWallet, address _adminWallet, address _nftRewardWallet, address _stakePoolWallet) external onlyOwner {
        require(_charityWallet != ZERO, "Charity wallet must not be zero address");
        require(_adminWallet != ZERO, "Admin wallet must not be zero address");
        require(_nftRewardWallet != ZERO, "NFT reward wallet must not be zero address");
        require(_stakePoolWallet != ZERO, "Stakepool wallet must not be zero address");
         require(_charityWallet != DEAD, "Charity wallet must not be dead address");
        require(_adminWallet != DEAD, "Admin wallet must not be dead address");
        require(_nftRewardWallet != DEAD, "NFT reward wallet must not be dead address");
        require(_stakePoolWallet != DEAD, "Stakepool wallet must not be dead address");
        charityWallet = _charityWallet;
        nftRewardWallet = _nftRewardWallet;
        adminWallet = _adminWallet;
        stakePoolWallet = _stakePoolWallet;

    }
    
    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
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

    function viewTeamWalletInfo() public view returns (uint256 charityDivs, uint256 adminDivs, uint256 nftDivs, uint256 stakeDivs) {
        return (totalCharity, totalAdmin, totalNFTrewards, totalStakepool);
    }

    // This will allow owner to rescue BNB sent by mistake directly to the contract
    function rescueBNB() external onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }

    // Converts to WBNB any BNB held in the contract (from sweep() function, for example)
    function convertBNB() external onlyOwner {
         IWETH(WETH).deposit{value : address(this).balance}();
    }

    // Function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    function transferBEP20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
       require(_tokenAddr != address(this), "Cannot transfer out native token");
        IBEP20(_tokenAddr).transfer(_to, _amount);
    }

    // This allows us to get any BNB out of the distributor address 
    function RescueBNBfromDistributor() external onlyOwner {
        distributor.rescueETHFromContract();
    }

    // Function to allow admin to claim *other* ERC20 tokens sent to the distributor  (by mistake)
    function TransferBEP20fromDistributor(address _tokenAddr, address _to, uint _amount) external onlyOwner {
        distributor.transferBEP20Tokens(_tokenAddr, _to, _amount);
    }

    //Depost BNB into the contract, then call this to increase holders dividends
    function AddToDistributor() external onlyOwner { 
       distributor.deposit{value: address(this).balance}();
    }

    //Deposit BNB into the contract, then call this to add BNB to the distributor in case it doesn't have enough to cover withdrawals (shouldn't happen, but just in case)
    function AddToDistributorBNB() external onlyOwner { 
       distributor.addBNB{value: address(this).balance}();
    }

    function GetClaimed(address _holder) external view returns (uint256 pending) {
        return distributor.getUnpaidDividends(_holder);
    }

    function GetPending(address _holder) external view returns (uint256 pending) {
        return distributor.getUnpaidEarnings(_holder);
    }

    function Withdrawal(uint256 _percent) external nonReentrant {
        distributor.distributeDividend(msg.sender, _percent);
    }

    function Reinvest(uint256 _percent, uint256 _amountOutMin) external nonReentrant {
        distributor.reinvestDividend(msg.sender, _percent, _amountOutMin);
    }

    function setburnRatio(uint256 _amount) external onlyOwner {
        require(_amount <= 500, "burn ratio cannot be more than 50 percent of total tax");
        taxRatio = _amount;
    } 

    function setstakepoolRatio(uint256 _amount) external onlyOwner {
        require(_amount <= 500, "stakepool ratio cannot be more than 50 percent of total tax");
        taxRatio = _amount;
    } 

    function settaxRatio(uint256 _amount) external onlyOwner {
        require(_amount <= 500, "tax ratio cannot be more than 50 percent of total tax");
        taxRatio = _amount;
    }


    function ChangeMinHold(uint256 _amount) external onlyOwner swapping {
        distributor.changeMinHold(_amount);
    }

    function ViewMinHold() external view returns (uint256 amount) {
        return distributor.viewMinHold();
    }
 
    function ViewHolderInfo(address _address) external view returns (uint256 amount, uint256 unpaid, uint256 realised, uint256 excluded) {
        return distributor.holderInfo(_address);
    }
    
    function ViewMathInfo() external view returns (uint256 totalshares, uint256 netdividends, uint256 totaldistributed, uint256 totalreinvested, uint256 totalwithdrawn, uint256 totaldividends) {
        return distributor.mathInfo();
    }

    function GetMinDistribution() external view returns (uint256) {
        return distributor.getDistributionCriteria();
    }

     function GetRewardsToken() external view returns (address) {
        return distributor.getDividendToken();
    }

    function SetDistributionCriteria(uint256 _amount) external onlyOwner {
        require(_amount > 0, "minimum distribution level must be greater than zero");
        distributor.setDistributionCriteria(_amount);
    }

    function GetShareholderExpired(address _holder) external view returns (uint256) {
        return distributor.getShareholderExpired(_holder);
    }

    function ChangeImpoundTimelimit(uint256 _timelimit) external onlyOwner {
        require(_timelimit >= 2592000, "Holder should have minimum 30 days (2592000) to withdraw unclaimed divs");
        distributor.changeImpoundTimelimit(_timelimit);
    }

    //reclaim divs from anyone who dumped KOJI over 30 days (default) ago but never withdrew their dividends
    function SweepDivs() external onlyOwner {
      try distributor.sweep(distributorGas) {} catch {}
    }

    function setStakePoolActive(bool _status) external onlyOwner {
        stakePoolActive = _status; 
    }

    function setNFTPoolActive(bool _status) external onlyOwner {
        nftPoolActive = _status; 
    }

    function changeGas(uint256 _distributorgas, uint256 _walletgas, uint256 _processgas) external onlyOwner {
        require(_distributorgas > 0, "distributor cannot be equal to zero");
        require(_walletgas > 0, "distributor cannot be equal to zero");
        require(_walletgas > 0, "distributor cannot be equal to zero");
        require(_processgas > 0, "distributor cannot be equal to zero");
        
        distributorGas = _distributorgas;
        walletGas = _walletgas;
        depositGas = _processgas;
    }

    function ChangeDistribGas(uint256 _walletGas, uint256 _reinvestGas) external onlyOwner {
         require(_walletGas > 0, "distributor cannot be equal to zero");
         require(_reinvestGas > 0, "distributor cannot be equal to zero");
         distributor.changeDistribGas(_walletGas, _reinvestGas);
    }

    function isContract(address addr) internal view returns (bool) {
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        bytes32 codehash;
        assembly {
            codehash := extcodehash(addr)
        }
            return (codehash != 0x0 && codehash != accountHash);
    }

    function addPartnership(address _tokencontract, uint256 _minHoldAmount, uint256 _percent) external onlyOwner {

        require(_tokencontract != DEAD && _tokencontract != ZERO && _tokencontract != pair, "Please input a valid token contract address");
        require(isContract(_tokencontract), "Please input an actual token contract");
        require(!partnerAdded[_tokencontract], "Contract already added. To change parameters please remove first.");
        require(_minHoldAmount > 0, "Min hold must be greater than zero");
        require(_percent <= totalFee, "Discount cannot be greater than total tax");

        uint256 partnerCount = partneraddr.length;
        
        Partners storage tokenpartners = partners[partnerCount];

            tokenpartners.token_addr = _tokencontract;
            tokenpartners.minHoldAmount = _minHoldAmount;
            tokenpartners.discount =_percent;
            tokenpartners.enabled = true;

            partnerAdded[_tokencontract] = true;
            partneraddr.push(_tokencontract);
        
    }

    function removePartnership(address _tokencontract) external onlyOwner {

        uint256 partnerCount = partneraddr.length;

        if (partnerCount > 0) {
            for (uint256 x = 0; x < partnerCount; ++x) {

                Partners storage tokenpartners = partners[x];

                if (address(tokenpartners.token_addr) == address(_tokencontract)) {

                    if (x == partnerCount) {
                        tokenpartners.token_addr = ZERO;
                        tokenpartners.minHoldAmount = 0;
                        tokenpartners.discount = 0;
                        tokenpartners.enabled = false;

                        partnerAdded[_tokencontract] = false;

                        partneraddr.pop();
                        
                    } else {

                        Partners storage tokenpartnerscopy = partners[partneraddr.length-1];

                        tokenpartners.token_addr = tokenpartnerscopy.token_addr;
                        tokenpartners.minHoldAmount = tokenpartnerscopy.minHoldAmount;
                        tokenpartners.discount = tokenpartnerscopy.discount;
                        tokenpartners.enabled = true;

                        partnerAdded[_tokencontract] = false;

                        tokenpartnerscopy.token_addr = ZERO;
                        tokenpartnerscopy.minHoldAmount = 0;
                        tokenpartnerscopy.discount = 0;
                        tokenpartnerscopy.enabled = false;

                        partneraddr[x] = partneraddr[partneraddr.length-1];
                        partneraddr.pop();

                    }
                    
                }
            }

        } else {
            return;
        }
    }

    function getPartnershipIndex() external view returns (uint256) {
        return partneraddr.length;
    }

    function viewPartnership(uint256 _index) external view returns (string memory name, string memory symbol, uint8 decimals, address tokencontract, uint256 minHoldAmount, uint256 discount, bool enabled) {
        Partners storage tokenpartners = partners[_index];
        string memory token_name = IBEP20(tokenpartners.token_addr).name();
        string memory token_symbol = IBEP20(tokenpartners.token_addr).symbol();
        uint8 token_decimals = IBEP20(tokenpartners.token_addr).decimals();
        return (token_name, token_symbol, token_decimals, tokenpartners.token_addr,tokenpartners.minHoldAmount,tokenpartners.discount,tokenpartners.enabled);
    }

    function setEnablePartners(bool _status) external onlyOwner {
        enablePartners = _status;
    }

    //value of 100 allows partner taxes to reduce 0% of totalFee tax, 50 = 50% of total tax (default), 1 allows 99% tax reduction of total tax for partners
    function setPartnerFeeLimiter(uint256 _limiter) external onlyOwner {
        require(_limiter <= 100 && _limiter >= 1, "fee limiter must be between 1 and 100");
        partnerFeeLimiter = _limiter;
    }

}