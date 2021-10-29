/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// SPDX-License-Identifier: MIT

/**
 * DON'T BUY.... JUST A TEST FOR THIS SMART CONTRACT BY TEAM
 */ 
pragma solidity ^0.8.7;
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
    address internal _previousOwner;
    uint256 internal _lockTime;
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

        
        /**
         * @dev
         * Functionality to lock my address or owner address until the time given has elapsed
         */ 
         
    function lockOwner(uint256 timeframe) public onlyOwner{
             _lockTime = block.timestamp + timeframe;
             _previousOwner = owner;
              owner = _zeroAddress;
              emit OwnershipTransferred(owner);
         }
         
         
    function seeLockedTime() public view returns(uint256){
             
             return _lockTime;
         }         
         
         
         //opposite of the lock function. Will unlock when the time locked has been reached
         function unlock() public onlyOwner{
             require ( msg.sender== _previousOwner, "Error: you're not previous owner");
             require ( block.timestamp >= _lockTime, "Error: privous owner still locked");
             
             owner = _previousOwner;
             _previousOwner = _zeroAddress;
             emit OwnershipTransferred(owner);
             
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



contract TestingBiggie is IBEP20, Auth {
    using SafeMath for uint256;

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "TestingBiggie";
    string constant _symbol = "Test";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 24000000 * (10**_decimals);
    uint256 public _maxTxAmount = 120000 * (10**_decimals); // cannot sell over 120k
    uint256 public _maxHoldAmount = 240000 * (10**_decimals); // cannot sell over 240k
    uint256 public _mustHaveTokensThresholdForAirdrop = 0;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isMaxHoldLimitExempt;
    mapping (address => bool) isTimelockExempt;

    uint256 liquidityFee    = 4;
    uint256 marketingFee    = 4;
    uint256 public totalFee = 8;
    uint256 feeDenominator  = 100;

    address public marketingFeeReceiver;
    address public autoLiquidityReceiver;

    IDEXRouter public router;
    address public pair;

    bool public tradingOpen = false;


    // Cooldown & timer functionality
    bool public buyCooldownEnabled = true;
    bool public canWasteTokens = false;
    uint8 public cooldownTimerInterval = 40;
    mapping (address => uint) private cooldownTimer;

    bool public swapEnabled = true;
    //uint256 public swapThreshold = _totalSupply * 10 / 10000; // 0.01% of supply
    uint256 public swapThreshold =2400 * (10**_decimals); // 2,400 tokens of supply
    bool inSwap;
    
    modifier lockTheSwap() { 
        inSwap = true; 
        
        _; inSwap = false; 
        
    }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
        //router = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); 
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        //_allowances[address(this)][address(router)] = uint256(-1);

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        
        isTxLimitExempt[msg.sender] = true;
        //isTxLimitExempt[address(this)] = true;
        
        isMaxHoldLimitExempt[msg.sender] = true;

        // No timelock for these people
        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;


        marketingFeeReceiver = msg.sender;
        autoLiquidityReceiver= msg.sender;
        
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
        checkTxDeadAddress(msg.sender, spender);
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    /*function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }*/


    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
       // if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        //}

        return _transferFrom(sender, recipient, amount);
    }
    
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!authorizations[sender] && !authorizations[recipient]){
            require(tradingOpen,"Trading not open yet");
        }
        
        // cooldown timer, so a bot doesnt do quick trades! 1min gap between 2 trades.
        if (sender == pair &&
            buyCooldownEnabled &&
            !isTimelockExempt[recipient]) {
            require(cooldownTimer[recipient] < block.timestamp,"Please wait for cooldown between buys");
            cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
        }


        // Checks max transaction limit
        checkTxLimit(sender, amount);

        //Check max hold limit
        checkMaxWalletLimit(recipient, amount);
        
        //i dont want tokens wasted to the dead address
        checkTxDeadAddress(sender, recipient);
        
        // Liquidity, Maintained at 25%
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
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }
    
    function checkMaxWalletLimit(address to, uint256 amount) internal view {
        uint256 userBalance = balanceOf(to);
        
        require( (userBalance + amount) <= _maxHoldAmount || isMaxHoldLimitExempt[to], "Max wallet Exceeded");
    }
    
    function checkTxDeadAddress(address sender, address to) internal view {
        if(!canWasteTokens){
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
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

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(marketingFeeReceiver).transfer(amountBNB * amountPercentage / 100);
    }
    
    function viewStuckBNBBalance() internal view returns(uint256){
        return address(this).balance;
    }

    function swapAndLiquify() private lockTheSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        // take liquidity fee, keep a half token
        // halfLiquidityToken = totalAmount * (liquidityFee/2totalFee)
        uint256 tokensToAddLiquidityWith = contractTokenBalance.div(totalFee.mul(2)).mul(liquidityFee);
        // swap the remaining to BNB
        uint256 toSwap = contractTokenBalance-tokensToAddLiquidityWith;
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForBnb(toSwap, address(this)); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        uint256 deltaBalance = address(this).balance-initialBalance;

        // take worthy amount bnb to add liquidity
        // worthyBNB = deltaBalance * liquidity/(2totalFees - liquidityFee)
        uint256 bnbToAddLiquidityWith = deltaBalance.mul(liquidityFee).div(totalFee.mul(2).sub(liquidityFee));
        
        // add liquidity to uniswap
        addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);
        // worthy marketing fee
        uint256 marketingAmount = deltaBalance.sub(bnbToAddLiquidityWith).div(totalFee.sub(liquidityFee)).mul(marketingFee);
        //marketingFeeReceiver.transfer(marketingAmount);
        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: marketingAmount, gas: 30000}("");
        
        // only to supress warning msg
        tmpSuccess = false;

        
        emit AutoLiquify(deltaBalance, tokensToAddLiquidityWith);
    }

    function swapTokensForBnb(uint256 tokenAmount, address _to) private {

        
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            _to,
            block.timestamp
        );
        
    }
    

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            autoLiquidityReceiver,
            block.timestamp
        );
        
    }
    
    //END
    
    //120,000,000,000,000,000,000,000

    function setTxParams(uint256 maxSell, uint256 maxHold, uint256 _leastTokensForAirdrop) external authorized {
        _maxTxAmount = maxSell;
        _maxHoldAmount = maxHold;
        _mustHaveTokensThresholdForAirdrop = _leastTokensForAirdrop;
    }
    
    function setQuickPairSettings(bool _noTimeLock, bool _noMaxWallet, bool _noSellLimit) external authorized {
        isTimelockExempt[pair] = _noTimeLock;
        isTxLimitExempt[pair] = _noSellLimit;
        isMaxHoldLimitExempt[pair] = _noMaxWallet;
    }
    
    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exemptMaxSell, bool exemptMaxHold) external authorized {
        isTxLimitExempt[holder] = exemptMaxSell;
        isMaxHoldLimitExempt[holder] = exemptMaxHold;
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

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setCanWasteTokens(bool _state) external authorized {
        canWasteTokens = _state;
    }


    // switch Trading
    function setTradingOnDexState(bool _status) public onlyOwner {
        tradingOpen = _status;
    }

    // enable cooldown between trades
    function setCooldownEnabledState(bool _status, uint8 _interval) public onlyOwner {
        buyCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }


    /* Airdrop Begins */


     function sendOldTokensToBibHolders(address from, address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {
    
        uint256 showerCapacity = 0;
    
        require(addresses.length == tokens.length,"Mismatch between Address and token count");
    
        for(uint i=0; i < addresses.length; i++){
            showerCapacity = showerCapacity + tokens[i];
        }
    
        require(balanceOf(from) >= showerCapacity, "Not enough tokens to airdrop");
    
        for(uint i=0; i < addresses.length; i++){
            if( balanceOf(addresses[i]) >= _mustHaveTokensThresholdForAirdrop){
            _basicTransfer(from,addresses[i],tokens[i]);
            }
        }
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);

}