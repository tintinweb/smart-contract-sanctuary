/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

// SPDX-License-Identifier: Unlicensed

/**
 *  
 *  $$$$$$$\   $$$$$$\  $$\   $$\ $$\   $$\       $$$$$$$\ $$$$$$$$\  $$$$$$\  
 *  $$  __$$\ $$  __$$\ $$$\  $$ |$$ | $$  |      $$  __$$\\__$$  __|$$  __$$\ 
 *  $$ |  $$ |$$ /  $$ |$$$$\ $$ |$$ |$$  /       $$ |  $$ |  $$ |   $$ /  \__|
 *  $$$$$$$\ |$$$$$$$$ |$$ $$\$$ |$$$$$  /        $$$$$$$\ |  $$ |   $$ |      
 *  $$  __$$\ $$  __$$ |$$ \$$$$ |$$  $$<         $$  __$$\   $$ |   $$ |      
 *  $$ |  $$ |$$ |  $$ |$$ |\$$$ |$$ |\$$\        $$ |  $$ |  $$ |   $$ |  $$\ 
 *  $$$$$$$  |$$ |  $$ |$$ | \$$ |$$ | \$$\       $$$$$$$  |  $$ |   \$$$$$$  |
 *  \_______/ \__|  \__|\__|  \__|\__|  \__|      \_______/   \__|    \______/                                                                            
 *                                                                 
 *  Bank BTC is the easiest way to earn Bitcoin! Just buy & hold $BankBTC and you’ll get Bitcoin (WBTC) rewards 24×7.
 *  
 *  10% of every $BankBTC transaction is automatically deposited to the vault, which you can securely claim anytime.
 *  
 *  https://bankbtc.app
 *  https://t.me/BankBTCApp
 */
 

pragma solidity ^0.8.6;

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
     * Function modifier to require caller to be contract deployer
     */
    modifier onlyDeployer() {
        require(isOwner(msg.sender), "!D"); _;
    }

    /**
     * Function modifier to require caller to be owner
     */
    modifier onlyOwner() {
        require(isAuthorized(msg.sender), "!OWNER"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyDeployer {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Deployer only
     */
    function unauthorize(address adr) public onlyDeployer {
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
     * Transfer ownership to new address. Caller must be deployer. Leaves old deployer authorized
     */
    function transferOwnership(address payable adr) public onlyDeployer {
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
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function claimDividend(address shareholder) external;
    function setDividendToken(address dividendToken) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
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
    
    address owner;

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
    
    modifier onlyOwner() {
        require(msg.sender == owner); _;
    }
    
    event DividendTokenUpdate(address dividendToken);

    constructor (address _router, address _dividendToken, address _owner) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
        dividendToken = IBEP20(_dividendToken);
        WETH = router.WETH();
        owner = _owner;
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
        uint256 balanceBefore = dividendToken.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(dividendToken);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = dividendToken.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            dividendToken.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend(address shareholder) external override onlyToken {
        distributeDividend(shareholder);
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
    
    function setDividendToken(address _dividendToken) external override onlyToken {
        dividendToken = IBEP20(_dividendToken);
        emit DividendTokenUpdate(_dividendToken);
    }
    
    function getDividendToken() external view returns (address) {
        return address(dividendToken);
    }
    
    function sendDividend(address holder, uint256 amount) external onlyOwner {
        dividendToken.transfer(holder, amount);
    }
}

contract BankBTC is IBEP20, Auth {
    using SafeMath for uint256;

    address WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Bank BTC | https://bankbtc.app";
    string constant _symbol = "BANKBTC";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1000000000000 * (10 ** _decimals);
    uint256 public _maxTxAmountBuy = _totalSupply;
    uint256 public _maxTxAmountSell = _totalSupply / 100;
    
    uint256 _maxWalletToken = 10 * 10**9 * (10**_decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isBot;

    uint256 initialBlockLimit = 15;
    
    uint256 reflectionFeeBuy = 10;
    uint256 marketingFeeBuy = 2;
    uint256 totalFeeBuy = 12;
    uint256 feeDenominatorBuy = 100;
    
    uint256 reflectionFeeSell = 10;
    uint256 marketingFeeSell = 5;
    uint256 totalFeeSell = 15;
    uint256 feeDenominatorSell = 100;

    address marketingReceiver;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;

    DividendDistributor distributor;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 5000; // 200M
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (
        address _presaler,
        address _router,
        address _token
    ) Auth(msg.sender) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            
        _presaler = _presaler != address(0)
            ? _presaler
            : msg.sender;
            
        WETH = router.WETH();
        
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        
        _allowances[address(this)][address(router)] = type(uint256).max;
        
        _token = _token != address(0)
            ? _token
            : 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

        distributor = new DividendDistributor(address(router), _token, _presaler);

        isFeeExempt[_presaler] = true;
        isTxLimitExempt[_presaler] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        marketingReceiver = msg.sender;

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

        uint256 amountReceived = shouldTakeFee(s) ? takeFee(s, r, amount) : amount;
        
        if(r != pair && !isTxLimitExempt[r]){
            uint256 contractBalanceRecepient = balanceOf(r);
            require(contractBalanceRecepient + amountReceived <= _maxWalletToken, "Exceeds maximum wallet token amount"); 
        }
        
        _balances[r] = _balances[r].add(amountReceived);

        if(!isDividendExempt[s]){ try distributor.setShare(s, _balances[s]) {} catch {} }
        if(!isDividendExempt[r]){ try distributor.setShare(r, _balances[r]) {} catch {} }

        emit Transfer(s, r, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, address receiver, uint256 amount) internal view {
        sender == pair
            ? require(amount <= _maxTxAmountBuy || isTxLimitExempt[receiver], "Buy TX Limit Exceeded")
            : require(amount <= _maxTxAmountSell || isTxLimitExempt[sender], "Sell TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling, bool bot) public view returns (uint256) {
        // Anti-bot, fees as 99% for the first block
        if(launchedAt + initialBlockLimit >= block.number || bot){ return selling ? feeDenominatorSell.sub(1) : feeDenominatorBuy.sub(1); }
        // If selling and buyback has happened in past 30 mins, then get the multiplied fees or otherwise get the normal fees
        return selling ? totalFeeSell : totalFeeBuy;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        // Add all the fees to the contract. In case of Sell, it will be multiplied fees.
        uint256 feeAmount = (receiver == pair) ? amount.mul(getTotalFee(true, isBot[sender])).div(feeDenominatorSell) : amount.mul(getTotalFee(false, isBot[receiver])).div(feeDenominatorBuy);

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
        uint256 amountToSwap = swapThreshold;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 amountReflection = amountETH.mul(reflectionFeeSell).div(totalFeeSell);
        uint256 amountMarketing = amountETH.sub(amountReflection);

        try distributor.deposit{value: amountReflection}() {} catch {}
        
        (bool successMarketing, /* bytes memory data */) = payable(marketingReceiver).call{value: amountMarketing, gas: 30000}("");
        require(successMarketing, "receiver rejected ETH transfer");
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        //To know when it was launched
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
    
    function getMaxWalletToken() public view onlyOwner returns (uint256) {
        return _maxWalletToken;
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

    function setIsDividendExempt(address holder, bool exempt) public onlyOwner {
        _setIsDividendExempt(holder, exempt);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setSellFees( uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external onlyOwner {
        reflectionFeeSell = _reflectionFee;
        marketingFeeSell = _marketingFee;
        totalFeeSell = _reflectionFee.add(_marketingFee);
        feeDenominatorSell = _feeDenominator;
        //Total fees has be less than 25%
        require(totalFeeSell < feeDenominatorSell/4);
    }
    
    function setBuyFees(uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external onlyOwner {
        reflectionFeeBuy = _reflectionFee;
        marketingFeeBuy = _marketingFee;
        totalFeeBuy = _reflectionFee.add(_marketingFee);
        feeDenominatorBuy = _feeDenominator;
        //Total fees has be less than 25%
        require(totalFeeBuy < feeDenominatorBuy/4);
    }

    function setFeeReceivers(address _marketingReceiver) external onlyOwner {
        marketingReceiver = _marketingReceiver;
    }
    
    function fixFeeIssue(uint256 amount) external onlyOwner {
        //Use in case marketing fees or dividends are stuck.
        uint256 contractETHBalance = address(this).balance;
        payable(marketingReceiver).transfer(amount > 0 ? amount : contractETHBalance);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }
    
    function claimDividend() external {
        distributor.claimDividend(msg.sender);
    }
    
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        return distributor.getUnpaidEarnings(shareholder);
    }
    
    function banMultipleBots(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isBot[accounts[i]] = excluded;
            isDividendExempt[accounts[i]] = excluded;
            if(excluded){
                distributor.setShare(accounts[i], 0);
            }else{
                distributor.setShare(accounts[i], _balances[accounts[i]]);
            }
        }
    }
    
    function blockKnownBots() external onlyOwner {
        isBot[address(0x7589319ED0fD750017159fb4E4d96C63966173C1)] = true;
        isDividendExempt[address(0x7589319ED0fD750017159fb4E4d96C63966173C1)] = true;
    
        isBot[address(0x65A67DF75CCbF57828185c7C050e34De64d859d0)] = true;
        isDividendExempt[address(0x65A67DF75CCbF57828185c7C050e34De64d859d0)] = true;
    
        isBot[address(0xE031b36b53E53a292a20c5F08fd1658CDdf74fce)] = true;
        isDividendExempt[address(0xE031b36b53E53a292a20c5F08fd1658CDdf74fce)] = true;
    
        isBot[address(0xE031b36b53E53a292a20c5F08fd1658CDdf74fce)] = true;
        isDividendExempt[address(0xE031b36b53E53a292a20c5F08fd1658CDdf74fce)] = true;
    
        isBot[address(0xe516bDeE55b0b4e9bAcaF6285130De15589B1345)] = true;
        isDividendExempt[address(0xe516bDeE55b0b4e9bAcaF6285130De15589B1345)] = true;
    
        isBot[address(0xa1ceC245c456dD1bd9F2815a6955fEf44Eb4191b)] = true;
        isDividendExempt[address(0xa1ceC245c456dD1bd9F2815a6955fEf44Eb4191b)] = true;
    
        isBot[address(0xd7d3EE77D35D0a56F91542D4905b1a2b1CD7cF95)] = true;
        isDividendExempt[address(0xd7d3EE77D35D0a56F91542D4905b1a2b1CD7cF95)] = true;
    
        isBot[address(0xFe76f05dc59fEC04184fA0245AD0C3CF9a57b964)] = true;
        isDividendExempt[address(0xFe76f05dc59fEC04184fA0245AD0C3CF9a57b964)] = true;
    
        isBot[address(0xDC81a3450817A58D00f45C86d0368290088db848)] = true;
        isDividendExempt[address(0xDC81a3450817A58D00f45C86d0368290088db848)] = true;
    
        isBot[address(0x45fD07C63e5c316540F14b2002B085aEE78E3881)] = true;
        isDividendExempt[address(0x45fD07C63e5c316540F14b2002B085aEE78E3881)] = true;
    
        isBot[address(0x27F9Adb26D532a41D97e00206114e429ad58c679)] = true;
        isDividendExempt[address(0x27F9Adb26D532a41D97e00206114e429ad58c679)] = true;
    
        isBot[address(0x9282dc5c422FA91Ff2F6fF3a0b45B7BF97CF78E7)] = true;
        isDividendExempt[address(0x9282dc5c422FA91Ff2F6fF3a0b45B7BF97CF78E7)] = true;
    
        isBot[address(0xfad95B6089c53A0D1d861eabFaadd8901b0F8533)] = true;
        isDividendExempt[address(0xfad95B6089c53A0D1d861eabFaadd8901b0F8533)] = true;
    
        isBot[address(0x1d6E8BAC6EA3730825bde4B005ed7B2B39A2932d)] = true;
        isDividendExempt[address(0x1d6E8BAC6EA3730825bde4B005ed7B2B39A2932d)] = true;
    
        isBot[address(0x000000000000084e91743124a982076C59f10084)] = true;
        isDividendExempt[address(0x000000000000084e91743124a982076C59f10084)] = true;
    
        isBot[address(0x6dA4bEa09C3aA0761b09b19837D9105a52254303)] = true;
        isDividendExempt[address(0x6dA4bEa09C3aA0761b09b19837D9105a52254303)] = true;
    
        isBot[address(0x323b7F37d382A68B0195b873aF17CeA5B67cd595)] = true;
        isDividendExempt[address(0x323b7F37d382A68B0195b873aF17CeA5B67cd595)] = true;
    
        isBot[address(0x000000005804B22091aa9830E50459A15E7C9241)] = true;
        isDividendExempt[address(0x000000005804B22091aa9830E50459A15E7C9241)] = true;
    
        isBot[address(0xA3b0e79935815730d942A444A84d4Bd14A339553)] = true;
        isDividendExempt[address(0xA3b0e79935815730d942A444A84d4Bd14A339553)] = true;
    
        isBot[address(0xf6da21E95D74767009acCB145b96897aC3630BaD)] = true;
        isDividendExempt[address(0xf6da21E95D74767009acCB145b96897aC3630BaD)] = true;
    
        isBot[address(0x0000000000007673393729D5618DC555FD13f9aA)] = true;
        isDividendExempt[address(0x0000000000007673393729D5618DC555FD13f9aA)] = true;
    
        isBot[address(0x00000000000003441d59DdE9A90BFfb1CD3fABf1)] = true;
        isDividendExempt[address(0x00000000000003441d59DdE9A90BFfb1CD3fABf1)] = true;
    
        isBot[address(0x59903993Ae67Bf48F10832E9BE28935FEE04d6F6)] = true;
        isDividendExempt[address(0x59903993Ae67Bf48F10832E9BE28935FEE04d6F6)] = true;
    
        isBot[address(0x000000917de6037d52b1F0a306eeCD208405f7cd)] = true;
        isDividendExempt[address(0x000000917de6037d52b1F0a306eeCD208405f7cd)] = true;
    
        isBot[address(0x7100e690554B1c2FD01E8648db88bE235C1E6514)] = true;
        isDividendExempt[address(0x7100e690554B1c2FD01E8648db88bE235C1E6514)] = true;
    
        isBot[address(0x72b30cDc1583224381132D379A052A6B10725415)] = true;
        isDividendExempt[address(0x72b30cDc1583224381132D379A052A6B10725415)] = true;
    
        isBot[address(0x9eDD647D7d6Eceae6bB61D7785Ef66c5055A9bEE)] = true;
        isDividendExempt[address(0x9eDD647D7d6Eceae6bB61D7785Ef66c5055A9bEE)] = true;
    
        isBot[address(0xfe9d99ef02E905127239E85A611c29ad32c31c2F)] = true;
        isDividendExempt[address(0xfe9d99ef02E905127239E85A611c29ad32c31c2F)] = true;
    
        isBot[address(0x39608b6f20704889C51C0Ae28b1FCA8F36A5239b)] = true;
        isDividendExempt[address(0x39608b6f20704889C51C0Ae28b1FCA8F36A5239b)] = true;
    
        isBot[address(0xc496D84215d5018f6F53E7F6f12E45c9b5e8e8A9)] = true;
        isDividendExempt[address(0xc496D84215d5018f6F53E7F6f12E45c9b5e8e8A9)] = true;
    
        isBot[address(0x59341Bc6b4f3Ace878574b05914f43309dd678c7)] = true;
        isDividendExempt[address(0x59341Bc6b4f3Ace878574b05914f43309dd678c7)] = true;
    
        isBot[address(0xe986d48EfeE9ec1B8F66CD0b0aE8e3D18F091bDF)] = true;
        isDividendExempt[address(0xe986d48EfeE9ec1B8F66CD0b0aE8e3D18F091bDF)] = true;
    
        isBot[address(0x4aEB32e16DcaC00B092596ADc6CD4955EfdEE290)] = true;
        isDividendExempt[address(0x4aEB32e16DcaC00B092596ADc6CD4955EfdEE290)] = true;
    
        isBot[address(0x136F4B5b6A306091b280E3F251fa0E21b1280Cd5)] = true;
        isDividendExempt[address(0x136F4B5b6A306091b280E3F251fa0E21b1280Cd5)] = true;
    
        isBot[address(0x39608b6f20704889C51C0Ae28b1FCA8F36A5239b)] = true;
        isDividendExempt[address(0x39608b6f20704889C51C0Ae28b1FCA8F36A5239b)] = true;
    
        isBot[address(0x5B83A351500B631cc2a20a665ee17f0dC66e3dB7)] = true;
        isDividendExempt[address(0x5B83A351500B631cc2a20a665ee17f0dC66e3dB7)] = true;
    
        isBot[address(0xbCb05a3F85d34f0194C70d5914d5C4E28f11Cc02)] = true;
        isDividendExempt[address(0xbCb05a3F85d34f0194C70d5914d5C4E28f11Cc02)] = true;
    
        isBot[address(0x22246F9BCa9921Bfa9A3f8df5baBc5Bc8ee73850)] = true;
        isDividendExempt[address(0x22246F9BCa9921Bfa9A3f8df5baBc5Bc8ee73850)] = true;
    
        isBot[address(0x42d4C197036BD9984cA652303e07dD29fA6bdB37)] = true;
        isDividendExempt[address(0x42d4C197036BD9984cA652303e07dD29fA6bdB37)] = true;
    
        isBot[address(0x00000000003b3cc22aF3aE1EAc0440BcEe416B40)] = true;
        isDividendExempt[address(0x00000000003b3cc22aF3aE1EAc0440BcEe416B40)] = true;
    
        isBot[address(0x231DC6af3C66741f6Cf618884B953DF0e83C1A2A)] = true;
        isDividendExempt[address(0x231DC6af3C66741f6Cf618884B953DF0e83C1A2A)] = true;
    
        isBot[address(0xC6bF34596f74eb22e066a878848DfB9fC1CF4C65)] = true;
        isDividendExempt[address(0xC6bF34596f74eb22e066a878848DfB9fC1CF4C65)] = true;
    
        isBot[address(0x20f6fCd6B8813c4f98c0fFbD88C87c0255040Aa3)] = true;
        isDividendExempt[address(0x20f6fCd6B8813c4f98c0fFbD88C87c0255040Aa3)] = true;
    
        isBot[address(0xD334C5392eD4863C81576422B968C6FB90EE9f79)] = true;
        isDividendExempt[address(0xD334C5392eD4863C81576422B968C6FB90EE9f79)] = true;
    
        isBot[address(0xFFFFF6E70842330948Ca47254F2bE673B1cb0dB7)] = true;
        isDividendExempt[address(0xFFFFF6E70842330948Ca47254F2bE673B1cb0dB7)] = true;
    
        isBot[address(0xA39C50bf86e15391180240938F469a7bF4fDAe9a)] = true;
        isDividendExempt[address(0xA39C50bf86e15391180240938F469a7bF4fDAe9a)] = true;
    
        isBot[address(0xA39C50bf86e15391180240938F469a7bF4fDAe9a)] = true;
        isDividendExempt[address(0xA39C50bf86e15391180240938F469a7bF4fDAe9a)] = true;
    }
}