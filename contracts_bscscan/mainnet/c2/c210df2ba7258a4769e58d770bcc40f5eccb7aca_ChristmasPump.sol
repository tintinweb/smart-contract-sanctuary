/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

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
 * Standard SafeMath
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
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    address internal _previousOwner;
    address internal _zeroAddress = 0x0000000000000000000000000000000000000000;
        
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



contract ChristmasPump is IBEP20, Auth {
    using SafeMath for uint256;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isMaxHoldLimitExempt;
    mapping (address => bool) isTimelockExempt;
    mapping (address => bool) isBot;

    bool public blacklistEnabled = false;

    uint256 liquidityFee    = 5;
    uint256 marketingFee    = 5;
    uint256 public totalFee = 10;
    uint256 feeDenominator  = 100;


    string constant _name = "ChristmasPump"; 
    string constant _symbol = "CHP";
    uint8  constant _decimals = 18;

    address public marketingFeeReceiver;
    address public autoLiquidityReceiver;

    IDEXRouter public router;
    address public pair;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;
    
    // Cooldown & timer functionality
    bool public buyCooldownEnabled = true;
    uint8 public cooldownTimerInterval = 15;
    mapping (address => uint) private cooldownTimer;

    bool public swapEnabled = true;
    bool inSwap;
    
    
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address ZERO = 0x0000000000000000000000000000000000000000;


    uint256 _totalSupply = 33000000000000    * (10**_decimals);
    uint256 public _maxTxAmount = _totalSupply  /200;
    uint256 public _maxHoldAmount = (_totalSupply *2) / 100;
    uint256 public swapThreshold =  6600000000 * (10**_decimals);
    

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        //router = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
      
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        
        isTxLimitExempt[msg.sender] = true;
        
        isMaxHoldLimitExempt[msg.sender] = true;
        isMaxHoldLimitExempt[pair] = true;

        // No timelock for these people
        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;


        marketingFeeReceiver = msg.sender;
        autoLiquidityReceiver= address(this);
        
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
        //checkTxDeadAddress(msg.sender, spender);
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
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
    
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        


        // Checks max transaction limit
        checkTxLimit(sender, amount);

        //Check max hold limit
        checkMaxWalletLimit(recipient, amount);
        
        checkBotAddress(sender, recipient);
        

        // cooldown timer, so a bot doesnt do quick trades! 1min gap between 2 trades.
        if (
            buyCooldownEnabled &&
            
            sender == pair &&
            
            !isTimelockExempt[recipient]) {
                
            require(cooldownTimer[recipient] < block.timestamp,"In cooldown state");
            cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
        }
        
        if(shouldSwapBack()){ swapAndLiquify(); }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);



        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "Tx limit reached");
    }
    
    function checkMaxWalletLimit(address to, uint256 amount) internal view {
        uint256 userBal = balanceOf(to);
        
        require( 
            
            (userBal + amount) <= _maxHoldAmount || isMaxHoldLimitExempt[to] 
            || (to == autoLiquidityReceiver) || (to == address(DEAD)) 
            || (to == marketingFeeReceiver), "Max wallet Exceeded");
    }
    
    function checkBotAddress(address sender, address recipient) internal view{
        
        if(blacklistEnabled){
        require( !isBot[sender] , "sender blacklisted");
        require( !isBot[recipient] , "Receipient blacklisted");
        }
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

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

   function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        
        uint256 circulatingSupply    = _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
        uint256 tokensInDexLiquidity = balanceOf(pair);
        
        return accuracy.mul( tokensInDexLiquidity.mul(2) ).div(circulatingSupply)> target;
    }
    
    modifier pauseMultiSwaps() { 
        inSwap = true; 
        
        _; inSwap = false; 
        
    }


    function swapAndLiquify() internal pauseMultiSwaps {
        
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
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);

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

    
    function setBlackBotstate(bool _bool) external authorized {
        blacklistEnabled = _bool;
    }
    
    function stopBotTrades(address _address, bool _bool) external authorized {
       
    require( _address != address(this) && _address != marketingFeeReceiver && _address != pair && 
        owner != _address && _address != autoLiquidityReceiver, "Access denied to black this wallet"); 
        
        isBot[_address] = _bool;
    }
    
    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setTxAndHold(uint256 maxSellPerc, uint256 maxHoldPerc) external authorized {

        _maxTxAmount = (_totalSupply * maxSellPerc)/100;
        _maxHoldAmount = (_totalSupply * maxHoldPerc)/100;
        
    } 

    function setTx(uint256 maxSellTokens) external authorized {

        _maxTxAmount = maxSellTokens * (10**_decimals);
        
    } 
    
    
    function setQuickPairSettings(bool _noTimeLock, bool _noMaxWallet, bool _noSellLimit) external authorized {
        isTimelockExempt[pair] = _noTimeLock;
        isTxLimitExempt[pair] = _noSellLimit;
        isMaxHoldLimitExempt[pair] = _noMaxWallet;
    }
    
    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exemptMaxSell, bool exemptMaxWallet) external authorized {
        isTxLimitExempt[holder] = exemptMaxSell;
        isMaxHoldLimitExempt[holder] = exemptMaxWallet;
    }

    function setIsTimelockExempt(address holder, bool exempt) external authorized {
        isTimelockExempt[holder] = exempt;
    }
    


    function setFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_marketingFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/4);
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 swapTokensAt) external authorized {
        swapEnabled = _enabled;
        swapThreshold = swapTokensAt * (10**_decimals);
    }

    // enable cooldown between trades
    function setCooldownEnabledState(bool _status, uint8 _interval) public onlyOwner {
        buyCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }
     
    function isExemptedFromMaxWallet(address _address) external view authorized returns (bool){
       return isMaxHoldLimitExempt[_address];  
     }


     function isExemptedFromMaxTx(address _address) external view authorized returns (bool){
       return isTxLimitExempt[_address];  
     }
     

    function viewStuckBNBBalance() external view authorized returns(uint256){
        return address(this).balance;
    }

     //see a blacklisted bot address
    function isBlackListed(address _address) external view authorized returns(bool){
        return isBot[_address];
    }


    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);

}