//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./AggregatorV3Interface.sol";
/**
 * SAFEMATH LIBRARY
 */
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

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function shouldPrintTokens() external view returns(bool);
    function burn(uint256 amount) external returns (bool);    
	function printToken(uint256 amount)external returns (bool); 
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
    
    function getAmountsOut(
        uint amountIn, 
        address[] calldata path
        ) external view returns (uint[] memory amounts);
    
}

interface IBankOfTEST4 {
    function depositToBank(address shareholder, uint256 amount) external;   
    function deposit() external payable;
    function process(uint256 gas) external;
    function establishPool() external;    
}

interface IburnerWallet {
    function burnTokens() external;
}

contract BurnerWallet is IburnerWallet {
    using SafeMath for uint256;

    IBEP20 bep_token;

    modifier onlyToken() {
       require(msg.sender == address(bep_token)); _;
    }

    constructor () {
        bep_token = IBEP20(msg.sender);
             }

    function burnTokens() external override onlyToken {
            uint256 token_balance = bep_token.balanceOf(address(this));
            if (token_balance > 0){
                bep_token.burn(token_balance);
            }
    }
}

contract TEST4 is IBEP20, Auth {
    using SafeMath for uint256;

    uint256 public constant MASK = type(uint128).max;
    address BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address public WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "TEST4";
    string constant _symbol = "TEST4";    
    uint8 constant _decimals = 18;

    uint256 _totalSupply;
    uint256 public _maxTxAmount;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;

    mapping (address => bool) whitelisted;
    
    uint256 liquidityFee = 0;
    uint256 burnFee = 20;
    uint256 dividendFee = 30;
    uint256 hedgeFundFee = 10;
    uint256 totalFee = 60;
    uint256 feeDenominator = 1000;

    IBEP20 LPtokens;

	bool public dynamicFees = true;
    bool public priceRescueEnabled = true; 
    bool public printStopped = false;
	
    uint256 maxTokenPrintAnnual;
    uint256 printTimestampMonthly;
    uint256 maxTokenToPrintMonthly;
    uint256 printTimestampAnnual;
    uint256 inflationTarget = 100;
    uint256 previousTotalSupply;
	
    address public autoLiquidityReceiver;
    address public hedgeFund;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;
    address dexRouter_;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;
    uint256 public lockLPTime;
 
    uint256 setPriceTimestamp;
    uint256 setPriceTimestampInterval = 7 days;
    uint256 previousPrice;
    uint256 currentPrice;
    uint256 priceChange;
    uint256 BNB_BUSD;

    uint256 public IDOprice = 20000;
    uint256 hardCap;
    uint256 IDOendDate; 
    bool IDOstarted = false;
    bool public autoBuybackEnabled = false;
    mapping (address => bool) buyBacker;
    uint256 autoBuybackAmount = 20 * (10 ** 18);
    AggregatorV3Interface internal priceFeed;

    address public bankAddress;
    IBankOfTEST4 bank;

    BurnerWallet burner;
    address public burnerAddress;
    bool autoProcessDividend = true;
    uint256 bankGas = 700000;
    bool public swapEnabled = true;
    uint256 public swapThreshold = 2000 * (10 ** 18);
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        dexRouter_ = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        router = IDEXRouter(dexRouter_);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        WBNB = router.WETH();
  
        bank = IBankOfTEST4(bankAddress);
        burner = new BurnerWallet();
        burnerAddress = address(burner); 
        LPtokens = IBEP20(pair);
        priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
        autoLiquidityReceiver = msg.sender;
        hedgeFund = 0xeeFA848f3b4069F1Ef97A570365Bf5078F8aD087;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[hedgeFund] = true;
        isFeeExempt[burnerAddress] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[hedgeFund] = true;
        isTxLimitExempt[burnerAddress] = true;
        buyBacker[msg.sender] = true;
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    modifier onlyBuybacker() { require(buyBacker[msg.sender] == true, ""); _; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function burn(uint256 amount) public returns (bool) {_burn(msg.sender, amount);  return true; }
    function printToken(uint256 amount) public returns (bool) {_printToken(msg.sender, amount);  return true; }	
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

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        if(recipient != bankAddress){ checkTxLimit(sender, amount); }
 
        if(shouldSwapBack()){ swapBack(); }
        if(shouldAutoBuyback()){ triggerAutoBuyback(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender] && recipient == bankAddress){ try bank.depositToBank(sender, amountReceived) {} catch {} }        
        
        checkMarketCondition();
        recalculationMaxTokenToPrint();	

        try bank.establishPool() {} catch {} 
        if(autoProcessDividend){ try bank.process(bankGas) {} catch {} }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
//        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require((amount <= _maxTxAmount && launched()) || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(address sender, address receiver) public view returns (uint256) {
        if (dynamicFees && receiver == pair) { 
            if (priceChange < 70) { return totalFee.mul(3);  } // strong downtrend
            else if (priceChange < 100) { return totalFee.mul(2);  }// downtrend 
         }
       // a downtrend offers opportunities to buy tokens with very low fees
         else if (dynamicFees && sender == pair) {
            if (priceChange < 80) { return 0;  }
            else if (priceChange < 100) { return totalFee.div(2);  } 
         }
        return totalFee;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(sender, receiver)).div(feeDenominator);
        if(receiver == bankAddress) { feeAmount = 0; }
        if(feeAmount > 0){
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }
        return amount.sub(feeAmount);
    }
    
    function checkMarketCondition() internal {
        if(launched()) { updateCurrentPrice(); }
        if(setPriceTimestamp <= block.timestamp && currentPrice > 0){ updatePreviousPrice(); }
        if(previousPrice > 0 ) { priceChange = currentPrice.mul(100).div(previousPrice);}    
    }   

    function updateCurrentPrice() internal {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);
        setCurrentPrice(router.getAmountsOut(1, path)); 
    }

    function getLatestPrice() internal view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function setCurrentPrice(uint256[] memory amounts) internal {
        uint256 amountWBNB = amounts[0];
        uint256 amountTOKEN = amounts[1];
        currentPrice = amountWBNB.mul(10**18).div(amountTOKEN);
        BNB_BUSD = uint256(getLatestPrice());
        if(BNB_BUSD > 0) { currentPrice = currentPrice.mul(BNB_BUSD).div(10**8); }
    }

    function updatePreviousPrice() internal {
        if (previousPrice < currentPrice) { previousPrice = currentPrice; } //force a price increase
        setPriceTimestamp = block.timestamp + setPriceTimestampInterval;
    }

    function recalculationMaxTokenToPrint() internal {
		if(printTimestampAnnual <= block.timestamp){
			previousTotalSupply = _totalSupply;			
	        maxTokenPrintAnnual = previousTotalSupply.mul(inflationTarget).div(100);
	        printTimestampAnnual = block.timestamp.add(365);	
            maxTokenToPrintMonthly = 0;				
		}
		if(printTimestampMonthly <= block.timestamp){
			maxTokenToPrintMonthly += maxTokenPrintAnnual.div(12);
	        printTimestampMonthly = block.timestamp.add(30);
		}
    }
    
    function priceRescue() internal view returns (bool) {
        return priceChange < 80
        && priceRescueEnabled;
    }
	
    function shouldPrintTokens() public view returns (bool) {
        return _totalSupply <= previousTotalSupply + maxTokenToPrintMonthly
		&& _totalSupply <= previousTotalSupply + maxTokenPrintAnnual
        && !priceRescue()
		&& !printStopped
		&& launched();
    }	
    
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && launched()
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
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
        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBDividend = amountBNB.mul(dividendFee).div(totalBNBFee);
        uint256 amountBNBhedgeFund = amountBNB.mul(hedgeFundFee).div(totalBNBFee);

        try bank.deposit{value: amountBNBDividend}() {} catch {}
        payable(hedgeFund).transfer(amountBNBhedgeFund);

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

    function triggerManualBuyback(uint256 amount, address to) external authorized {
        buyBackAndBurn(amount, to);
    }
    
    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && autoBuybackEnabled
        && launched()
        && address(this).balance >= autoBuybackAmount;
    }

    function triggerAutoBuyback() internal {
            buyBackAndBurn(autoBuybackAmount, burnerAddress); 
            try burner.burnTokens() {} catch {} // burn
        } 

    function buyBackAndBurn(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function setAutoBuybackSettings(bool _enabled, uint256 _amount) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackAmount = _amount * (10 ** 18); //set in bnb
    }

    function setAutoDistributionDividend(bool _enabled) external authorized {
        autoProcessDividend = _enabled;
    }

    function updatePriceTimestampInterval(uint256 _setPriceTimestampInterval) external authorized {
        setPriceTimestampInterval = _setPriceTimestampInterval * 1 days; //e.g if set to 10 then check price every 10 days
        setPriceTimestamp = block.timestamp;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function updateRouter(address newAddress) external authorized {
        require(newAddress != address(router), "The router already has that address");
        router = IDEXRouter(newAddress);
    }

    function addBankAdr(address newAddress) external authorized {
        require(newAddress != address(router), "The Bank already has that address");
        bankAddress = newAddress;
        isFeeExempt[bankAddress] = true;
        isTxLimitExempt[bankAddress] = true;
        bank = IBankOfTEST4(bankAddress);
    }

    function launch() internal {
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }

    function _print(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: print to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);    
        emit Transfer(bankAddress, account, amount);
    }
	
    function _printToken(address account, uint256 amount) internal {
        require(account == bankAddress, "Only Bank Of TEST4 can print tokens");
		if(shouldPrintTokens()){ _print(bankAddress, amount); }
    }	

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
        emit Transfer(account, burnerAddress, amount);
    }

    function provideLP() internal {
        require(!launched(), "Already launched");

        uint256 amountBNBtoWithdraw = address(this).balance.mul(20).div(100);
        uint256 amountBNBLiquidity = address(this).balance.sub(amountBNBtoWithdraw);
        payable(hedgeFund).transfer(amountBNBtoWithdraw);
        
        uint256 adjustedIDOprice = _totalSupply.div(amountBNBLiquidity);
        uint256 amountTokenLiquidity = amountBNBLiquidity * adjustedIDOprice.div(125).mul(100);
 
		 _print(address(this), amountTokenLiquidity);  
        _allowances[address(this)][dexRouter_] = _totalSupply;
        _allowances[address(this)][address(pair)] = _totalSupply; 
        _maxTxAmount = _totalSupply.div(100);
        router.addLiquidityETH{value: amountBNBLiquidity}(
        address(this),
        amountTokenLiquidity,
        0,
        0,
        address(this),
        block.timestamp);    

        lockLPTime = block.timestamp + 1 days; //lock LP for 400 days
        launch();

        emit firstLPprovided(amountBNBLiquidity, amountTokenLiquidity);
    }    

    function unlockLP() external authorized {
        require(block.timestamp >= lockLPTime, "The liquidity pool is still locked");	
		if(LPtokens.balanceOf(address(this)) > 0){  
        LPtokens.transfer(owner, LPtokens.balanceOf(address(this)));
        }
    }    

    function IDO(address referrer) external payable returns(bool) {
        require(IDOstarted, "IDO NOT started");
        require(!launched(), "IDO ended");
        require(referrer != msg.sender, "You cannot refer yourself!");
        if(_totalSupply > 0){
        uint256 adjustedIDOprice = _totalSupply.div(address(this).balance);
        IDOprice = IDOprice.mul(adjustedIDOprice).div(IDOprice);
        }
        uint256 amount = msg.value.mul(IDOprice);

        if(balanceOf(referrer) >= 2000 * (10**18)){
            payable(referrer).transfer(msg.value.div(50));	
            if(balanceOf(referrer) <= 10000 * 10**18){
               _print(referrer, amount.div(10));
            }
            amount = amount.add(amount.div(10));
        }
        if(whitelisted[msg.sender]) {
            amount = amount.add(amount.div(10));
        }        
        _print(msg.sender, amount);      
        if(address(this).balance >= hardCap || IDOendDate <= block.timestamp){ provideLP(); }
        emit tokensBought(msg.sender, amount);
        return true;
    }

    function joinWhitelist(address adr) external {
        require(!launched(), "IDO ended");
        require(!IDOstarted, "IDO started");
        whitelisted[adr] = true;
    } 

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 10000); 
        _maxTxAmount = amount * (10 ** _decimals); // max Tx amount in tokens
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _burnFee, uint256 _dividendFee, uint256 _hedgeFundFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        burnFee = _burnFee;
        dividendFee = _dividendFee;
        hedgeFundFee = _hedgeFundFee;
        totalFee = _liquidityFee.add(_burnFee).add(_dividendFee).add(_hedgeFundFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/4);
    }

    function setNewFeeReceiver(address _autoLiquidityReceiver, address _hedgeFund) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        hedgeFund = _hedgeFund;
    }
    
    function updatePreviousPrice(uint256 _previousPrice) external authorized {
        previousPrice = _previousPrice;
    }
 
    function IDOSettings(uint256 hardCap_, uint256 IDOduration) external authorized {
        hardCap = hardCap_;
        IDOstarted = true;
        IDOendDate = block.timestamp.add(IDOduration * 1 days); 
    }

    function printSettings(bool _printStopped, uint256 _inflationTarget) external authorized {
        printStopped = _printStopped;
        inflationTarget = _inflationTarget;
	    maxTokenPrintAnnual = previousTotalSupply.mul(inflationTarget).div(100);
        require(_inflationTarget <= 300);
    }    

    function manualDividendDistribution() external {
        try bank.process(bankGas) {} catch {}
    }

    function depositToBank(uint256 amountDeposit) external authorized {
        try bank.deposit{value: amountDeposit}() {} catch {}
    }    
    
    function setSwapBackSettings(bool _enabled, bool _priceRescueEnabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        priceRescueEnabled = _priceRescueEnabled;
        swapThreshold = _amount * (10 ** _decimals);  //the threshold in tokens
    }

    function DynamicFees(bool _enabled) external authorized {
        dynamicFees = _enabled;
    }

    function approveDEX() external authorized {
        _allowances[address(this)][dexRouter_] = _totalSupply;
        _allowances[address(this)][address(pair)] = _totalSupply;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setbankSettings(uint256 gas) external authorized {
        require(gas < 1200000);
        bankGas = gas;
    }
    
    function feeInfo() public view returns (
        uint256 Liquidity_fee, 
        uint256 Buyback_fee, 
        uint256 Dividend_fee, 
        uint256 HedgeFund_fee, 
        uint256 Total_fee, 
        uint256 totalFeeForBuyers, 
        uint256 totalFeeForSellers) {
        return (
            liquidityFee, 
            burnFee, 
            dividendFee, 
            hedgeFundFee, 
            totalFee, 
            getTotalFee(pair, msg.sender), 
            getTotalFee(msg.sender, pair));
    }    

    function priceInfo() public view returns (
        uint256 BNB_PRICE, 
        uint256 previous_price, 
        uint256 current_price, 
        uint256 price_change, 
        uint256 setPrice_TimestampInterval, 
        uint256 setPrice_Timestamp) {
        return (
            BNB_BUSD,
            previousPrice, 
            currentPrice, 
            priceChange, 
            setPriceTimestampInterval.div(86400), 
            setPriceTimestamp
        );
    }  

    function printInfo() public view returns (
        uint256 maxTokenPrintAnnual_, 
        uint256 printTimestampAnnual_, 
        uint256 maxTokenToPrintMonthly_, 
        uint256 printTimestampMonthly_, 
        uint256 inflationTarget_, 
        uint256 previousTotalSupply_) {
        return (
            maxTokenPrintAnnual,
            printTimestampAnnual, 
            maxTokenToPrintMonthly, 
            printTimestampMonthly, 
            inflationTarget, 
            previousTotalSupply
        );
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

    event AutoLiquify(uint256 amountBNB, uint256 amountCRY);
    event tokensBought(address buyer, uint256 amountCRY);
    event firstLPprovided(uint256 amountBNB, uint256 amountCRY);
}