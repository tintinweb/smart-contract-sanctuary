/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

// SPDX-License-Identifier: MIT

/**
 * BigNFT
 * 
 * The nft market is fast expanding, new nft projects are popping up here and there
 * with amazing gameplay and in-dept innovative ideas in the nft and metaverse space
 * 
 * This is why we are launching BigNft as a platform to collect, vett and list those
 * projects.
 * 
 * You simply earn points for shilling, commenting, uploading nfts and liking nfts
 * on the website. Those points are converted to BUSD based on the leaderboard
 * 
 * Join TG channel : @bignft_ann
 * Join TG         :  @bignft_io 
 * 
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
         function unlock() public{
             require ( msg.sender== _previousOwner, "Woah: you're not previous owner buddy");
             require ( block.timestamp >= _lockTime, "Woah: previous owner still locked");
             
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



contract BigNFT is IBEP20, Auth {
    using SafeMath for uint256;

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "BigNFT"; 
    string constant _symbol = "BGN";
    uint8  constant _decimals = 9;

    uint256 _totalSupply = 24000000 * (10**_decimals);
    uint256 public _maxTxAmount = 120000 * (10**_decimals); // cannot sell over 240k
    uint256 public _maxHoldAmount = 240000 * (10**_decimals); // cannot sell over 240k
    uint256 public _mustHaveTokensThresholdForAirdrop = 2400 * (10**_decimals);
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isMaxHoldLimitExempt;
    mapping (address => bool) isTimelockExempt;
    mapping (address => bool) isBlackListBotAddresses;

    //any bot who wrecks the chat i will put your address here! Don't mess with BigNft
    bool public blacklistingSwitch = false;

    uint256 liquidityFee    = 4;
    uint256 marketingFee    = 4;
    uint256 public totalFee = 8;
    uint256 feeDenominator  = 100;

    address public marketingFeeReceiver;
    address public autoLiquidityReceiver;

    IDEXRouter public router;
    address public pair;

    bool public tradingOpen = false;

    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;
    
    // Cooldown & timer functionality
    bool public buyCooldownEnabled = true;
    //bool public canWasteTokens = false;
    uint8 public cooldownTimerInterval = 30;
    mapping (address => uint) private cooldownTimer;

    bool public swapEnabled = true;
    //uint256 public swapThreshold = _totalSupply * 10 / 10000; // 0.01% of supply
    uint256 public swapThreshold =2400 * (10**_decimals); // 2,400 tokens of supply
    bool inSwap;
    

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); //real
        //router = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //pcs testnet
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        
        isTxLimitExempt[msg.sender] = true;
        //isTxLimitExempt[address(this)] = true;
        
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

        if(!authorizations[sender] && !authorizations[recipient]){
            require(tradingOpen,"Woah: Trade now closed");
        }
        
        // cooldown timer, so a bot doesnt do quick trades! 1min gap between 2 trades.
        if (
            buyCooldownEnabled &&
            
            sender == pair &&
            
            !isTimelockExempt[recipient]) {
                
            require(cooldownTimer[recipient] < block.timestamp,"Woah: Please buy after cooldown");
            cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
        }


        // Checks max transaction limit
        checkTxLimit(sender, amount);

        //Check max hold limit
        checkMaxWalletLimit(recipient, amount);
        
        //if you hurt our charts we will black list you. Don't disturb
        checkBlackList(sender, recipient);
        
        //i dont want tokens wasted to the dead address
       // checkTxDeadAddress(sender, recipient);
        
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
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "Woah: Tiger, tx limit reached");
    }
    
    function checkMaxWalletLimit(address to, uint256 amount) internal view {
        uint256 userBalance = balanceOf(to);
        
        require( 
            
            (userBalance + amount) <= _maxHoldAmount || isMaxHoldLimitExempt[to] 
            || (to == autoLiquidityReceiver) || (to == address(DEAD)) 
            || (to == marketingFeeReceiver), "Max wallet Exceeded");
    }
    
    function checkBlackList(address sender, address recipient) internal view{
        
        if(blacklistingSwitch){
        require( !isBlackListBotAddresses[sender] , "Woah: sender blacklisted already");
        require( !isBlackListBotAddresses[recipient] , "Woah: Receipient blacklisted already");
        }
    }
    
    /*
    This code was stopping me from adding Liquidity on PCS... Incase you are copying my smart contract for BigNFT
    don't remove the comment, else you won't be able add LP.
    
    function checkTxDeadAddress(address sender, address to) internal view {
        if(!canWasteTokens){
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        }
    }*/

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
    
    function clearStuckBalance() external onlyOwner{
        (bool sent,) =payable(pair).call{value: (address(this).balance)}("");
        require(sent);
    }

  
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

   function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        
        //we just need to remove the burnt tokens from the total supply
        uint256 circulatingSupply    = _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
        uint256 tokensInDexLiquidity = balanceOf(pair);
        
        return accuracy.mul( tokensInDexLiquidity.mul(2) ).div(circulatingSupply)> target;
    }
    
    modifier lockTheSwap() { 
        inSwap = true; 
        
        _; inSwap = false; 
        
    }


    function swapAndLiquify() internal lockTheSwap {
        
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

    
    function setBlacklistSwitch(bool _bool) external authorized {
        blacklistingSwitch = _bool;
    }
    
    function addToBlackList(address _address, bool _bool) external authorized {
       
        require( owner != _address && _address != autoLiquidityReceiver && _address != address(this) && _address != marketingFeeReceiver && _address != pair, "Woah: Sorry you can't blacklist me"); 
        
        isBlackListBotAddresses[_address] = _bool;
    }
    
    //120,000,000,000,000,000,000,000
    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setTranscSettings(uint256 maxSellPercentage, uint256 maxHoldPercentage, uint256 _leastTokensForAirdropPercentage) external authorized {
        //        _maxWalletToken = (_totalSupply * maxWallPercent ) / 100;

        _maxTxAmount = (_totalSupply * maxSellPercentage)/100;
        _maxHoldAmount = (_totalSupply * maxHoldPercentage)/100;
        
        _mustHaveTokensThresholdForAirdrop = (_totalSupply * _leastTokensForAirdropPercentage)/100;
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

    function setSwapBackSettings(bool _enabled, uint256 _amountPercentage) external authorized {
        swapEnabled = _enabled;
        swapThreshold = (_totalSupply * _amountPercentage) /100;
    }

    /*function setCanWasteTokens(bool _state) external authorized {
        canWasteTokens = _state;
    }*/


    // switch Trading
    function setTradingOnDexState(bool _status) public onlyOwner {
        tradingOpen = _status;
    }

    // enable cooldown between trades
    function setCooldownEnabledState(bool _status, uint8 _interval) public onlyOwner {
        buyCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }

    /**
     * Views variables
     */
     //check if this person pays fee or not
     function vIsExemptedFromFee(address _address) external view authorized returns (bool){
       return isFeeExempt[_address];  
     }
     
     //check if this person has max hold or not
     function vIsExemptedFromMaxHold(address _address) external view authorized returns (bool){
       return isMaxHoldLimitExempt[_address];  
     }
     
     //check if this person has max transaction
     function vIsExemptedFromMaxTx(address _address) external view authorized returns (bool){
       return isTxLimitExempt[_address];  
     }
     
     //view stuck BNB balance
    function viewStuckBNBBalance() external view authorized returns(uint256){
        return address(this).balance;
    }

     //view a blacklisted user
    function vIsBlacklisted(address _address) external view authorized returns(bool){
        return isBlackListBotAddresses[_address];
    }


    /* Airdrop Begins */


     function sendOldTokensToBibHolders(address from, address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {
    
        uint256 totalAirdropTokens = 0;
    
        require(addresses.length == tokens.length,"Woah: Dude tokens and holders count didn't match");
    
        for(uint i=0; i < addresses.length; i++){
            totalAirdropTokens = totalAirdropTokens + tokens[i];
        }
    
        require(balanceOf(from) >= totalAirdropTokens, "Woah: poor wallet dude. Buy more to send");
    
        for(uint i=0; i < addresses.length; i++){
            if( balanceOf(addresses[i]) >= _mustHaveTokensThresholdForAirdrop){
            _basicTransfer(from,addresses[i],tokens[i]);
            }
        }
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);

}


//BigNFT - by Mazi... My first Smart contract.... Best of luck to us!