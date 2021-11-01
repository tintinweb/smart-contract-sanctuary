/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

/**


██╗░░░░░███████╗██╗░░░██╗███████╗██╗░░░░░██╗░░░██╗██████╗░
██║░░░░░██╔════╝██║░░░██║██╔════╝██║░░░░░██║░░░██║██╔══██╗
██║░░░░░█████╗░░╚██╗░██╔╝█████╗░░██║░░░░░██║░░░██║██████╔╝
██║░░░░░██╔══╝░░░╚████╔╝░██╔══╝░░██║░░░░░██║░░░██║██╔═══╝░
███████╗███████╗░░╚██╔╝░░███████╗███████╗╚██████╔╝██║░░░░░
╚══════╝╚══════╝░░░╚═╝░░░╚══════╝╚══════╝░╚═════╝░╚═╝░░░░░


@title:             LevelUp ($LVLUP) Gaming Token
@website:           www.level-up.game
@1st game:          www.pacatto.cc

Socials:
@Global Telegram:   https://t.me/levelup_games
@Chinese Telegram:  https://t.me/LevelUP_CN
@Arabic Telegram:   https://t.me/LevelUP_Arabic
@Twitter:           https://twitter.com/LevelUpBSC

@description:       LevelUp is a Blockchain Gaming Platform aiming to provide game
                    developers with the capabilities to launch their own P2E blockchain
                    games at ease. No solidity coding is required, simply navigate through
                    our platform and customize your own Tokenomics with just a few clicks.

                    Players will get access to a library
                    of games powered by both LevelUp
                    and our vetted game developing partnerships.

                    Play your choice of games and get
                    incentivized with $LVLUP earnings!

*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


// SafeMath library

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


//IBEP20 interface

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


// abstract contract

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}


// IDEXFactory interface

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


// IDEXRouter interface

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


// prize pool contract

contract LevelUpPrizePool {

    using SafeMath for uint256;

    address public tokenAddress;
    uint256 public maxDailyClaimAmount = 0;
    uint256 claimLimit = 50;
    uint256 minClaimLimit = 20;
    uint256 blockTimestamp;
    uint256 public claimCooldownTimerInterval = 86400; // 24hrs

    mapping (address => uint) private claimCooldownTimer;

    address public main;
    IBEP20 public LevelUp = IBEP20(main);

    mapping (address => bool) internal authorized;
    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == tokenAddress); _;
    }
    modifier auth() {
        require(isAuth(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyToken {
        authorized[adr] = true;
    }

    function isAuth(address adr) public view returns (bool) {
        return authorized[adr];
    }

    constructor (address payable _main) {
        main = _main;
        tokenAddress = msg.sender;
    }
    function claim(address caller, uint256 amount) internal {

        LevelUp.approve(address(this),amount);
        LevelUp.transfer(caller, amount);

    }
    function claimReward(address caller, uint256 amount, uint256 heldTokens, uint256 id, bytes32[] calldata merkleProof) external onlyToken{
        require(id > 0);
        uint256 rewardLimit = heldTokens.mul(claimLimit).div(1000);
        require (amount <= rewardLimit);

        require (amount <= maxDailyClaimAmount);


        claim(caller, amount);
        claimCooldownTimer[caller] = block.timestamp + claimCooldownTimerInterval;

    }

    function claimTransfer(address caller, uint256 amount) external auth{
        claim(caller, amount);
    }

    function newCoin(IBEP20 coin) public onlyToken{
        LevelUp = coin;
    }

    function setmaxDailyClaimAmount(uint256 amount) external onlyToken {
        maxDailyClaimAmount = amount;
    }

    function setClaimLimit(uint256 percentage) external onlyToken {
        if(percentage < minClaimLimit) {
            claimLimit = minClaimLimit;
        }
        else {
            claimLimit = percentage;
        }
    }

    function getClaimLimit() public view returns (uint256) {
        return claimLimit;
    }

    function getmaxDaiyClaimLimit() public view returns (uint256) {
        return maxDailyClaimAmount;
    }

    function getClaimCooldownTimer(address player) public view returns (uint256) {
        return claimCooldownTimer[player];
    }

    function setClaimCooldownTimer(address player) external onlyToken {
        claimCooldownTimer[player] = block.timestamp + claimCooldownTimerInterval;
    }

    function checkClaimCooldownTimer(address player) public view returns (uint256, bool){
        return (claimCooldownTimer[player], (claimCooldownTimer[player] > block.timestamp));
    }

}


contract LevelUpGaming is IBEP20, Auth {
    using SafeMath for uint256;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;


    address public prizePoolHolder;

    string constant _name = "LevelUp Gaming";
    string constant _symbol = "LVLUP";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 200 * 10**6 * (10 ** _decimals); // 200m total supply
    uint256 public _maxTxAmount = _totalSupply.mul(5).div(1000); // 1m max transaction amount on sells
    uint256 public _maxWalletToken = _totalSupply.mul(1).div(100); // max wallet size 2m

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isCooldownExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) _isCheater;

    uint256 public liquidityFee             = 2;
    uint256 public developerFee             = 4;
    uint256 public rewardsFee               = 8;
    uint256 public rewardsFeeSell           = 11;
    uint256 public rewardsFeeCheater        = 50;
    uint256 public liquidityFeeCheater      = 9;
    uint256 public developerFeeFeeCheater   = 25;

    uint256 public totalFee         = 14;
    uint256 public totalFeeCheater  = 85;

    uint256 feeDenominator          = 100;
    uint256 public sellMulti = 1000;

    address public autoLiquidityReceiver;
    address public developerFeeReceiver;


    bool public tradingIsEnabled = false;

    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;

    event TradingIsEnabled(bool enabled);
    event UpdateLevelUpPrizePool(address indexed newAddress, address indexed oldAddress);

    IDEXRouter public router;
    address public pair;

    LevelUpPrizePool prizePoolWallet;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 10 / 10000; // 0.01% of supply
    uint256 swapPercent = 100;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        //testnet
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        // mainnet
        //router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);


        pair = IDEXFactory(router.factory()).createPair(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        prizePoolWallet = new LevelUpPrizePool(payable(address(this)));

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        autoLiquidityReceiver = 0xe2CA18A50C08B540E737a0Fa73266F638c18286f;
        developerFeeReceiver = 0xe2CA18A50C08B540E737a0Fa73266F638c18286f;

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
        return approve(spender, type(uint256).max);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function cheaterDetected(address account, bool value) external onlyOwner{
        _isCheater[account] = value;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function checkClaimCooldownTimer(address player) external view returns (uint256, bool){
        return prizePoolWallet.checkClaimCooldownTimer(player);
    }

    function claim(uint256 _amount, uint256 id, bytes32[] calldata merkleProof) public {
        uint256 amount = _amount;
        uint256 heldTokens = balanceOf(msg.sender);



        require(!_isCheater[msg.sender], 'Cheater detected');
        if (isCooldownExempt[msg.sender] == false) {
            require(prizePoolWallet.getClaimCooldownTimer(msg.sender) < block.timestamp,"Please wait for cooldown between claims");

        }


        prizePoolWallet.claimReward(msg.sender, amount, heldTokens, id, merkleProof);
    }

    function rewardTransfer(address newReward, uint256 amount) external onlyOwner{
        prizePoolWallet.claimTransfer(newReward, amount);
    }

    function clearStuckBalance(uint256 amountPercentage) external authorized {
        uint256 tokensHeld = _balances[address(this)];
        uint256 amountTokens = tokensHeld.mul(amountPercentage).div(100);
        uint256 amountBNB = address(this).balance;
        payable(autoLiquidityReceiver).transfer(amountBNB * amountPercentage / 100);
        approve(address(this), amountTokens);
         _basicTransfer(address(this), msg.sender, amountTokens);

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

    function setRewardsAuth(address caller) external onlyOwner{
        prizePoolWallet.authorize(caller);
    }

    function setClaimLimit(uint256 percentage) external onlyOwner {
        prizePoolWallet.setClaimLimit(percentage);
    }

    function getClaimLimit() public view returns (uint256) {
        return prizePoolWallet.getClaimLimit();
    }

    function getmaxDaiyClaimLimit() public view returns (uint256) {
        return prizePoolWallet.getmaxDaiyClaimLimit();
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        _maxTxAmount = amount;
    }

    function setMaxWallet(uint256 amount) external onlyOwner() {
        _maxWalletToken = amount;
    }

    function setmaxDailyClaimAmount(uint256 amount) external onlyOwner() {
        prizePoolWallet.setmaxDailyClaimAmount(amount);
    }

    function setIsCooldownExempt(address holder, bool exempt) external authorized {
        isCooldownExempt[holder] = exempt;
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _developerFee, uint256 _rewardsFee, uint256 _rewardsFeeSell, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        developerFee = _developerFee;
        rewardsFee = _rewardsFee;
        rewardsFeeSell = _rewardsFeeSell;
        totalFee = _liquidityFee.add(_developerFee).add(_rewardsFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator);
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _developerFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        developerFeeReceiver = _developerFeeReceiver;
    }

    function setSellFeeMultiplier(uint256 _multiplier) external authorized {
  	    sellMulti = _multiplier;
  	}
  	
  	function prepareForPreSale() external onlyOwner {
        liquidityFee             = 0;
        developerFee             = 0;
        rewardsFee               = 0;
        rewardsFeeSell           = 0;
        rewardsFeeCheater        = 0;
        liquidityFeeCheater      = 0;
        developerFeeFeeCheater   = 0;
    
        totalFee                 = 0;
        totalFeeCheater          = 0;

    
        tradingIsEnabled = false;
        emit TradingIsEnabled(tradingIsEnabled);
        
        _maxTxAmount = _totalSupply.mul(1000).div(1000); 
        _maxWalletToken = _totalSupply.mul(100).div(100);         
    }

    function prepareForLaunch() external onlyOwner {
        liquidityFee             = 2;
        developerFee             = 4;
        rewardsFee               = 8;
        rewardsFeeSell           = 11;
        rewardsFeeCheater        = 50;
        liquidityFeeCheater      = 9;
        developerFeeFeeCheater   = 25;
    
        totalFee                 = 14;
        totalFeeCheater          = 85;

        _maxTxAmount = _totalSupply.mul(5).div(1000); 
        _maxWalletToken = _totalSupply.mul(1).div(100);        
    }

    function setTradingIsEnabled(bool _enabled) external onlyOwner {
        tradingIsEnabled = _enabled;
        emit TradingIsEnabled(tradingIsEnabled);
    }

    function setTokenSwapSettings(bool _enabled, uint256 _amount, uint256 _percentage) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        swapPercent = _percentage;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setRewards(IBEP20 coin) external onlyOwner{
        prizePoolWallet.newCoin(coin);
    }

    function setRewardsAddress(address _reward) external onlyOwner{
        prizePoolHolder = _reward;
    }
    
    //Withdraw tokens, can be vanurable to reentrancy attacks, but doesn't matter becouse of onlyOwner
    function emergencyWithdraw(uint256 _amount, address _token, address _receiver) public onlyOwner{
        IBEP20 token = IBEP20(_token);
        require(_amount <= token.balanceOf(address(this)), 'The contract balance is too low');
        token.transfer(_receiver, _amount);
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function shouldTokenSwap() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {

        uint256 _totalFee = totalFee;
        uint256 _rewardsFee = rewardsFee;
        uint256 _rewardsFeeSell = rewardsFeeSell;

        uint256 _totalFeeCheater = totalFeeCheater;
        uint256 _rewardsFeeCheater = rewardsFeeCheater;


        if (recipient == pair){
            _totalFee = _totalFee - _rewardsFee + _rewardsFeeSell;
            _totalFee = _totalFee * sellMulti.div(1000);
            _rewardsFee = _rewardsFeeSell * sellMulti.div(1000);
        }
        
        if(_isCheater[recipient] || _isCheater[sender]) {
            _totalFee = _totalFeeCheater * sellMulti.div(1000);
            _rewardsFee = _rewardsFeeCheater * sellMulti.div(1000);    
        }
        


        uint256 feeAmount = amount.mul(_totalFee).div(feeDenominator);
        uint256 rewardAmount = amount.mul(_rewardsFee).div(feeDenominator);
        uint256 swapAmount = feeAmount.sub(rewardAmount);

        _balances[address(this)] = _balances[address(this)].add(swapAmount);
        _balances[prizePoolHolder] = _balances[prizePoolHolder].add(rewardAmount);
        emit Transfer(sender, address(this), swapAmount);
        emit Transfer(sender, prizePoolHolder, rewardAmount);

        return amount.sub(feeAmount);
    }

    function tokenSwapAmount() internal view returns (uint256) {
        uint256 tokensHeld = _balances[address(this)];
        uint256 swapAmount = tokensHeld.mul(swapPercent).div(100);
        return swapAmount;
    }

    function tokenSwap(bool cheaterWasDetected) internal swapping {
        uint256 dynamicLiquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = tokenSwapAmount().sub(amountToLiquify);

        if(cheaterWasDetected == true) {
            dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFeeCheater;
        }
        else {
            dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee;

        uint256 amountBNBLiquidity;
        uint256 amountBNBdeveloper;
        if(cheaterWasDetected == true) {
            totalBNBFee = totalFeeCheater.sub(dynamicLiquidityFee.div(2));
            amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
            amountBNBdeveloper = amountBNB.mul(developerFeeFeeCheater).div(totalBNBFee);
        }
        else {
            totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
            amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
            amountBNBdeveloper = amountBNB.mul(developerFee).div(totalBNBFee);    
        }
        

        (bool tmpSuccess,) = payable(developerFeeReceiver).call{value: amountBNBdeveloper, gas: 50000}("");

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

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        if (isAuthorized(msg.sender)){
            return _basicTransfer(msg.sender, recipient, amount);
        }
        else {
            return _transferFrom(msg.sender, recipient, amount);
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        
        bool addressIsCheater;
        require(tradingIsEnabled == true || sender == owner || recipient == owner);

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if (!authorizations[sender] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != developerFeeReceiver && recipient != autoLiquidityReceiver){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
        }

        if (recipient == pair){
            checkTxLimit(sender, amount);
        }
        
        if(!_isCheater[recipient] || !_isCheater[sender]) {
            addressIsCheater = true;
        }

        if(shouldTokenSwap()){ tokenSwap(addressIsCheater); }


        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function updateLevelUpPrizePool(address newAddress) external onlyOwner {
        LevelUpPrizePool newRewardHolder = LevelUpPrizePool(payable(newAddress));

        emit UpdateLevelUpPrizePool(newAddress, address(prizePoolWallet));

        prizePoolWallet = newRewardHolder;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);


}