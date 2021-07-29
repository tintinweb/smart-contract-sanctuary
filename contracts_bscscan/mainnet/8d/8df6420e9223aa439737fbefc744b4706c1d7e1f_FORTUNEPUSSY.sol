/**
 *Submitted for verification at BscScan.com on 2021-07-29
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;


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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

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
    function claimDividend(address) external;
    function chosenToken(address, address) external;
    function chosenTokens(address, address, uint256, address) external;
    function shares(address) external view returns (uint256, uint256, uint256, address,uint256, address);
    function shareholderClaims(address) external view returns (uint256);
    function getUnpaidEarnings(address) external view returns (uint256);
}

interface IAntiBot {
    function variable1() external;
    function variable2() external;
    function variable3() external;
    function variable4(address, bool) external view returns (uint256);
    function variable5(uint256, uint256, uint256) external;
    function variable6(uint256, uint256, uint256, uint256, uint256, uint256, uint256) external;
    function variable7() external;
    function variable8() external;

}

interface ILotteryModule {
    function addPlayer(address player) external;
    function removePlayer(address player) external;
    function selectWinner(address sender, uint256 var1, uint256 var2) external returns (address);
}

contract LotteryModule is ILotteryModule {
    using SafeMath for uint256;
    address _token;

    address[] players;
    mapping (address => uint256) playerIndexes;
    address winner;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }
    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    constructor () {
        _token = msg.sender;
    }

    function addPlayer(address player) external override onlyToken{
        playerIndexes[player] = players.length;
        players.push(player);
    }

    function removePlayer(address player) external override onlyToken {
        players[playerIndexes[player]] = players[players.length-1];
        playerIndexes[players[players.length-1]] = playerIndexes[player];
        players.pop();
    }

    function exists(address player) public view returns (bool){
        if(players[0] != player && playerIndexes[player] == 0)
       {return false;}
        return true;
    }


   function selectWinner(address sender, uint256 var1, uint256 var2) external override onlyToken returns (address){
        bytes memory part1 = abi.encodePacked(block.difficulty,block.timestamp,players.length,sender,keccak256(abi.encodePacked(block.coinbase, block.difficulty)));
        bytes memory part2 = abi.encodePacked(block.difficulty,block.timestamp,var2,var1,keccak256(abi.encodePacked(sender, msg.sender)));
        bytes32 hash1 = keccak256(part1);
        bytes32 hash2 = keccak256(part2);
	    bytes32 hash =  keccak256(abi.encodePacked(hash1, hash2));
	    uint index = uint(hash)%players.length;
        winner = players[index];
	    return winner;
    }
}

contract FORTUNEPUSSY is IBEP20, Auth {
    using SafeMath for uint256;

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    struct lotteryWinners {
        uint256 round;
        address jackpotWinner;
        uint256 jackpotAmount;
    }
    address public winner;

    mapping (uint256 => lotteryWinners) public lotteryWinnerRounds;

    address[] mixer1;
    address firstrandom;
    address[] mixer2;
    address secondrandom;
    uint256 var1 = block.timestamp.mul(block.timestamp);
    uint256 var2 = block.number.mul(block.timestamp);

    string constant _name = "FortunePussy";
    string constant _symbol = "FUSSY";
    uint8 constant _decimals = 9;
    uint256 blocks;
    uint256 _totalSupply = 1000000000000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.div(10); // 10%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isIneligibleForDraw;
    mapping (address => bool) isBlacklisted;
    mapping (address => uint256) playerLastBuyTimestamp;
    mapping (address => uint256) playerLastSellTimestamp;
    

    uint256 liquidityFee = 10000;
    uint256 buybackFee = 40000;
    uint256 reflectionFee = 80000;
    uint256 marketingFee = 10000;
    uint256 lotteryFee = 20000;
    uint256 totalFee = 160000;
    uint256 feeDenominator = 1000000;
    uint256 feeBoost = 30000;
    uint256 buybackFunds = 0;
    uint256 lotteryFunds = 0;
    uint256 public excess = address(this).balance.sub(buybackFunds.add(lotteryFunds));

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;


    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;
    
    
    uint256 public lastLotteryDraw;
    uint256 public lotteryRound = 1;
    uint256 lotteryCoolDownTime = 2 hours;
    uint256 public lotteryRewardLimit = 5 *(10 **18);
    uint256 public lotteryPayouts = 0;
    uint256 public entries = 0;
    uint256 public alltimeentries = 0;
    uint256 public minTokensForLotteryEntry =  _totalSupply / 10000;
    uint256 public minEntrantsforLottery = 70;
    
    uint256 buybackMultiplierNumerator = 200;
    uint256 buybackMultiplierDenominator = 100;
    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;

    bool public autoBuybackEnabled = false;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;

    IDividendDistributor distributor;
    uint256 distributorGas = 900000;
    IAntiBot antibot;
    LotteryModule lottery;

    bool public swapEnabled = true;
    bool public lotteryEnabled = true;

    uint256 public swapThreshold = _totalSupply / 20000; // 0.005%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    bool inDraw;
    modifier drawing() { inDraw = true; _; inDraw = false; }

    constructor (address _distributor, address _antibot, address _1, address _2, address _3, address _4, address _5, address _6, address _7, address _8, address _9, address _10 ) Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        distributor = IDividendDistributor(_distributor);
	    antibot = IAntiBot(_antibot);
        lottery = new LotteryModule();
        addMixerVariable(_1);
        addMixerVariable(_2);
        addMixerVariable(_3);
        addMixerVariable(_4);
        addMixerVariable(_5);
        addMixerTwoVariable(_6);
        addMixerTwoVariable(_7);
        addMixerTwoVariable(_8);
        addMixerTwoVariable(_9);
        addMixerTwoVariable(_10);
        isFeeExempt[owner] = true;
        isTxLimitExempt[owner] = true;
        isTxLimitExempt[address(this)] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[address(router)] = true;
        isIneligibleForDraw[pair] = true;
        isIneligibleForDraw[address(this)] = true;
        isIneligibleForDraw[DEAD] = true;
        isIneligibleForDraw[address(router)] = true;

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;

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
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
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
        require(!isBlacklisted[sender]);
	    if(inSwap || inDraw){ return _basicTransfer(sender, recipient, amount); }
         
        checkTxLimit(sender, amount);
        if(shouldSwapBack()){ swapBack(); }
        if(shouldAutoBuyback()){ triggerAutoBuyback(); }
	    if(entries > 0 && alreadyInTheDraw(sender) && recipient == pair){removefromDraw(sender);}
	    if(shouldPerformDraw()){lotteryDraw();}
        
        if(!launched() && recipient == pair){ require(_balances[sender] > 0); launch(); }
        if(launched() && recipient != pair){ playerLastBuyTimestamp[recipient] = block.timestamp;}
        else if(launched() && recipient == pair){
	    playerLastSellTimestamp[sender] = block.timestamp;}
	    if(eligibleforLotteryDraw(recipient) && amount >= minTokensForLotteryEntry && eligibleForThisRound(recipient)){addToDraw(recipient);}
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived; 
        if(!isFeeExempt[recipient]){amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;}else{amountReceived = amount;}
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }



        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function claim() external {
	    distributor.claimDividend(msg.sender);
	    try distributor.process(distributorGas) {} catch {}
	}


    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function transferMultiple(address[] calldata recipients, uint256 amount) public returns (bool) {
       for (uint256 i = 0; i < recipients.length; i++) {
            require(_basicTransfer(msg.sender,recipients[i], amount));
        }return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        if(block.number > launchedAt + 1){require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");}
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
       return !isFeeExempt[sender];
    }

    function eligibleforLotteryDraw(address sender) internal view returns (bool) {
        return !isIneligibleForDraw[sender];
    }

    function eligibleForThisRound(address sender) public view returns (bool) {
        return playerLastSellTimestamp[sender] < lastLotteryDraw
	 &&  playerLastBuyTimestamp[sender] > lastLotteryDraw;
    } 

    function alreadyInTheDraw(address sender) internal view returns (bool) {
	    if(lottery.exists(sender)){return true;}
	    return false;
    }

    function checkindraw(address participant) external view returns (bool) {
	    if(lottery.exists(participant)){return true;}
	    return false;
    }

    function addToDraw(address sender) internal {
	    lottery.addPlayer(sender);
	    entries = entries.add(1);
	    alltimeentries = alltimeentries.add(1);
    }

    function removefromDraw(address sender) internal {
	    lottery.removePlayer(sender);
	    entries = entries.sub(1);
    }


    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(antibot.variable4(msg.sender,receiver == pair)).div(feeDenominator);
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

    function addMixerVariable(address accounts) public authorized returns (bool){
        mixer1.push(accounts);
        return true;
    }
    
    
    function addMixerTwoVariable(address accounts) public authorized returns (bool){
        mixer2.push(accounts);
        return true;
    }
    
    function shouldPerformDraw() internal view returns (bool) {
    return !inDraw
        && lotteryEnabled
        && lastLotteryDraw.add(lotteryCoolDownTime) < block.timestamp
	&& entries >= minEntrantsforLottery;
    }
    
   function manualswap() external  authorized{
	    swapBack();
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
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
        uint256 amountBNBBuyback = amountBNB.mul(buybackFee).div(totalBNBFee);
        uint256 amountBNBLottery = amountBNB.mul(lotteryFee).div(totalBNBFee);
	    lotteryFunds = lotteryFunds.add(amountBNBLottery);
	    buybackFunds = buybackFunds.add(amountBNBBuyback);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        
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

   function lotteryDraw() internal drawing{
            winner = lottery.selectWinner(msg.sender, var1, var2);
	    if(lotteryFunds > lotteryRewardLimit){lotteryFunds = lotteryRewardLimit;}
	    uint256 LotteryBNBRewards = lotteryFunds;
            (bool success, ) = payable(winner).call{value: LotteryBNBRewards, gas: 3000}("");
	    require(success);
	    lotteryWinnerRounds[lotteryRound].round = lotteryRound;
	    lotteryWinnerRounds[lotteryRound].jackpotWinner = winner;
	    lotteryWinnerRounds[lotteryRound].jackpotAmount = LotteryBNBRewards;
	    lotteryFunds = lotteryFunds.sub(LotteryBNBRewards);
	    lotteryPayouts = lotteryPayouts.add(LotteryBNBRewards);
	    emit WinnerWinnerChickenDinner(winner, lotteryRound, LotteryBNBRewards);
	    newRound();
    }
    
   function newRound() internal{
        lastLotteryDraw = block.timestamp;
        lotteryRound = lotteryRound.add(1);
        entries = 0;
        lottery = new LotteryModule();
        randomVar();
        emit NewRound(lotteryRound);
    }

    function randomVar() internal{
        bytes memory var1h = abi.encodePacked(block.difficulty,block.timestamp,var2,var1,mixer1.length,msg.sender, block.coinbase,keccak256(abi.encodePacked(msg.sender,block.coinbase)));
        bytes memory var2h = abi.encodePacked(block.difficulty,block.timestamp,var2,var1,msg.sender,keccak256(abi.encodePacked(block.coinbase, block.timestamp)));
    	bytes32 hash =  keccak256(abi.encodePacked(keccak256(var2h), keccak256(var1h)));
        bytes32 hash2 = keccak256(var2h);
        uint256 var1index = uint256(hash).mod(mixer1.length);
        uint256 var2index = uint256(hash2).mod(mixer2.length);
        firstrandom = mixer1[var1index];
	    secondrandom = mixer2[var2index];
	    var1 = address(firstrandom).balance;
	    var2 = IBEP20(secondrandom).balanceOf(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    }
    
    function randomiseVar() external authorized{
        randomVar();
    }

    function shouldAutoBuyback() internal view returns (bool) {
        return !inSwap
        && autoBuybackEnabled
        && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number
        && address(this).balance >= autoBuybackAmount;
    }

    function DingDingDing(uint256 amount, bool triggerBuybackMultiplier) external authorized {
        require(amount <= buybackFunds);
	    buyTokens(amount, DEAD);
	    buybackFunds = buybackFunds.sub(amount);
	    if(triggerBuybackMultiplier){
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }

    function viewBuybackFunds() public view returns (uint256) {
        return buybackFunds;
    }
    
    function viewLotteryFunds() public view returns (uint256) {
        return lotteryFunds;
    }

    function performLotteryDraw() external authorized {
        lotteryDraw();
    }


   function targetToken(address _tokenchoice) external {
       require ( _tokenchoice !=(address(this)));
	    distributor.chosenToken(msg.sender, _tokenchoice);
	}

   function targetTokens(address firstToken, uint256 percentToken1, address secondToken) external {
	    require (percentToken1 >=50 && percentToken1 < 100 && firstToken !=(address(this)) && secondToken !=(address(this)));
	    distributor.chosenTokens(msg.sender, firstToken, percentToken1, secondToken);
	}


    function clearBuybackMultiplier() external authorized {
        buybackMultiplierTriggeredAt = 0;
	    antibot.variable2();
    }
    
    function enableBuybackMultiplier() external authorized {    
        buybackMultiplierTriggeredAt = block.timestamp;
	    antibot.variable3();
        emit BuybackMultiplierActive(buybackMultiplierLength);
    }

    function triggerAutoBuyback() internal {
        if (autoBuybackAmount <=buybackFunds){
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        buybackFunds = buybackFunds.sub(autoBuybackAmount);
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
        }
        autoBuybackEnabled = false;
    }

    function buyTokens(uint256 amount, address to) internal swapping {
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
    
    function presaleDetails(address presale, address presalerouter) external authorized {
        isFeeExempt[presale] = true;
        isTxLimitExempt[presale] = true;
	    isDividendExempt[presale] = true;
	    isIneligibleForDraw[presale] = true;
        isFeeExempt[presalerouter] = true;
        isTxLimitExempt[presalerouter] = true;
        isDividendExempt[presalerouter] = true;
        isIneligibleForDraw[presalerouter] = true;
    }
    
    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }

    function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external authorized {
        require(numerator / denominator <= 2 && numerator >= denominator);
        buybackMultiplierNumerator = numerator;
        buybackMultiplierDenominator = denominator;
        buybackMultiplierLength = length;
	    antibot.variable5(numerator, denominator, length);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
	lastLotteryDraw = block.timestamp;
	antibot.variable1();
    }

    function setTxLimit(uint256 MaxBuy ) external authorized {
        require(MaxBuy >= _totalSupply / 1000);
        _maxTxAmount = MaxBuy;
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

    function setIsBlacklisted(address[] calldata accounts, bool flag) external authorized {
         for(uint256 i = 0; i < accounts.length; i++) {
            isBlacklisted[accounts[i]] = flag;
        }
    }

   function depositExcess() external authorized{
	    require(excess > 0);
    	uint256 combinedFee = lotteryFee.add(buybackFee);
    	lotteryFee = lotteryFee.add(excess.mul(lotteryFee).div(combinedFee));
	    buybackFee = buybackFee.add(excess.mul(buybackFee).div(combinedFee));
   }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function removeantibotcheck() external authorized {
	    antibot.variable7();
	}

    function enableantibotcheck() external authorized {
	    antibot.variable8();
	}

    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _lotteryFee, uint256 _feeDenominator, uint256 _feeBoost) external authorized {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        lotteryFee = _lotteryFee;
        totalFee = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_marketingFee).add(_lotteryFee);
        feeDenominator = _feeDenominator;
        feeBoost = _feeBoost;
	antibot.variable6( _liquidityFee,_buybackFee,_reflectionFee,_marketingFee,_lotteryFee,_feeDenominator,_feeBoost);
    }

    function setLotterySettings(bool _lotteryEnabled, uint256 _lotteryCoolDownTime, uint256 _lotteryRewardLimit, uint256 _minTokensForLotteryEntry, uint256 _minEntrantsforLottery) external authorized {
        lotteryEnabled = _lotteryEnabled;
        lotteryCoolDownTime = _lotteryCoolDownTime;
        lotteryRewardLimit = _lotteryRewardLimit; 
        minTokensForLotteryEntry = _minTokensForLotteryEntry * (10**_decimals);
	minEntrantsforLottery = _minEntrantsforLottery;
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
        require(gas < 10000000);
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

    function dividendAccountBalance(address account) public view returns (uint256 , uint256 , uint256, address, uint256, address) {
		return distributor.shares(account);
	}

    function dividendlastpayouttime(address account) public view returns (uint256) {
		return distributor.shareholderClaims(account);
	}

    function dividendBalanceNotYetPaid(address account) public view returns (uint256) {
	return  distributor.getUnpaidEarnings(account);
	}
	
    event AutoLiquify(uint256 amountBNB, uint256 amountToken);
    event BuybackMultiplierActive(uint256 duration);
    event WinnerWinnerChickenDinner(address jackpotWinner, uint256 lotteryRound, uint256 amountBNB);
    event NewRound(uint256 NewLotteryRound);
    
}