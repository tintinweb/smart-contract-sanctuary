/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

pragma solidity ^0.7.4;

//SPDX-License-Identifier: MIT

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

contract RewardHolder {
    using SafeMath for uint256;

    address public _token;

    address public main;
    IBEP20 public SPC = IBEP20(main);

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address payable _main) {
        main = _main;
        _token = msg.sender;
    }
    function claim(address caller, uint256 amount) internal {
        
    
    SPC.approve(address(this),amount);
    SPC.transfer(caller, amount);
    
    }
    function claimReward(address caller, uint256 amount) external onlyToken{
        claim(caller, amount);
    }
    function newCoin(IBEP20 coin) public onlyToken{
        SPC = coin;
    }
    
    receive() external payable { }
}
contract SpacePortUniverse is IBEP20, Auth {
    using SafeMath for uint256;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address NFT = 0xEd840De2c93BA3BfaF3d9aa79BfcDC869B77De09;
    
    address public rewardsHolder;
    
    string constant _name = "SpacePort Universe";
    string constant _symbol = "SPU";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100 * 10**6 * (10 ** _decimals); //
    uint256 public _maxTxAmount = _totalSupply * 100 / 100; //
    uint256 public _maxWalletToken = ( _totalSupply * 100 ) / 100; //
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isCooldownExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) _isBlacklisted;

    uint256 public liquidityFee  = 1;
    uint256 public developerFee  = 1;
    uint256 public rewardsFee    = 5;
    uint256 public totalFee      = 7;
    uint256 feeDenominator       = 100;
    uint256 public sellMulti = 500;
    
    uint256 claimLimit = 2;

    address public autoLiquidityReceiver;
    address public developerFeeReceiver;
    
    
    //1 day
    uint256 public claimCooldownTimerInterval = 86400;
    mapping (address => uint) private claimCooldownTimer;
    
    bool public tradingIsEnabled = false;

    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;
    
    event TradingIsEnabled(bool enabled);

    IDEXRouter public router;
    address public pair;
    
    RewardHolder rewardHolder;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 10 / 10000; // 0.01% of supply
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);
        
        rewardHolder = new RewardHolder(address(this));

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        autoLiquidityReceiver = 0x168b151F99858E3f954C533855A81D45e855D9Ff;
        developerFeeReceiver = 0x168b151F99858E3f954C533855A81D45e855D9Ff;

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
        return approve(spender, uint256(-1));
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
        
    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }
    
    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }
    
    function checkClaimCooldownTimer(address player) external view returns (uint256, bool){
        return (claimCooldownTimer[player], (claimCooldownTimer[player] > block.timestamp));
    }
    
    function claim(uint256 _amount) public {
        uint256 amount = _amount * 10**_decimals;
        uint256 heldTokens = balanceOf(msg.sender);
        uint256 rewardLimit = nftRewardLimit(heldTokens);
        require (amount <= rewardLimit);
        if (isCooldownExempt[msg.sender] == false) {
            require(claimCooldownTimer[msg.sender] < block.timestamp,"Please wait for cooldown between claims");
        }
        claimCooldownTimer[msg.sender] = block.timestamp + claimCooldownTimerInterval;
        
        rewardHolder.claimReward(msg.sender, amount);
    }
    
    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(autoLiquidityReceiver).transfer(amountBNB * amountPercentage / 100);
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    
    function nftAmount(address owner) internal view returns (uint256) {
        uint256 a = nftCheck(NFT, owner, 6448882);
        uint256 b = nftCheck(NFT, owner, 2975434);
        uint256 c = nftCheck(NFT, owner, 447770);
        uint256 d = nftCheck(NFT, owner, 9999770);
        uint256 e = nftCheck(NFT, owner, 1542322);
        return a + b + c + d + e;
    }
    
    function nftCheck(address addr, address owner, uint256 id) public view returns(uint) {
        NFTCheck check = NFTCheck(addr);
        return check.balanceOf(owner, id);
    }
    
    function nftRewardLimit(uint256 _balance) internal view returns (uint256){
        uint256 nftCount = nftAmount(msg.sender);
        
        //done to allow for 2% max balance
        uint256 nftCountMult = nftCount.add(claimLimit * 10);
        uint256 rewardLimit;
        if (nftCount == 0){
            rewardLimit = _balance.mul(claimLimit * 10).div(1000);
        }
        else if (nftCount > 0 && nftCount < 5){
            rewardLimit = _balance.mul(nftCountMult).div(1000);
        }
        else {
            nftCountMult = nftCountMult.mul(10).add(75);
            rewardLimit = _balance.mul(nftCountMult).div(10000);
        }
        return rewardLimit;
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }
    
    function setClaimLimit(uint256 percentage) external onlyOwner {
        claimLimit = percentage;
    }
    
    function setTxLimit(uint256 amount) external onlyOwner {
        _maxTxAmount = amount;
    }

    function setMaxWallet(uint256 amount) external onlyOwner() {
        _maxWalletToken = amount;
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

    function setFees(uint256 _liquidityFee, uint256 _developerFee, uint256 _rewardsFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        developerFee = _developerFee;
        rewardsFee = _rewardsFee;
        totalFee = _liquidityFee.add(_developerFee).add(_rewardsFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator);
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _developerFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        developerFeeReceiver = _developerFeeReceiver;
    }
    
    function setSellFeeMultiplier(uint256 _multiplier) external authorized {
  	    sellMulti = _multiplier;
  	}
    
    function setTradingIsEnabled(bool _enabled) external onlyOwner {

        tradingIsEnabled = _enabled;
        emit TradingIsEnabled(tradingIsEnabled);
    }

    function setTokenSwapSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }
    
    function setRewards(IBEP20 coin) external onlyOwner{
        
        rewardHolder.newCoin(coin);
    }
    
    function setRewardsAddress(address _reward) external onlyOwner{
        rewardsHolder = _reward;
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
        
        if (recipient == pair){
            _totalFee = _totalFee * sellMulti.div(100);
            _rewardsFee = _rewardsFee * sellMulti.div(100);
        }
        
        uint256 feeAmount = amount.mul(_totalFee).div(feeDenominator);
        uint256 rewardAmount = amount.mul(_rewardsFee).div(feeDenominator);
        uint256 swapAmount = feeAmount.sub(rewardAmount);

        _balances[address(this)] = _balances[address(this)].add(swapAmount);
        _balances[rewardsHolder] = _balances[rewardsHolder].add(rewardAmount);
        emit Transfer(sender, address(this), swapAmount);
        emit Transfer(sender, rewardsHolder, rewardAmount);

        return amount.sub(feeAmount);
    }

    function tokenSwap() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = _balances[address(this)].sub(amountToLiquify);

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

        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
        
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBdeveloper = amountBNB.mul(developerFee).div(totalBNBFee);
        
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
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }
    
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(tradingIsEnabled == true || sender == owner || recipient == owner);
        require(!_isBlacklisted[recipient] && !_isBlacklisted[sender], 'Blacklisted address');
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        if (!authorizations[sender] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != developerFeeReceiver && recipient != autoLiquidityReceiver){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
        }

        checkTxLimit(sender, amount);

        if(shouldTokenSwap()){ tokenSwap(); }
        
        
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    

}
    contract NFTCheck {
        mapping (uint256 => mapping(address => uint256)) internal balances;
        function balanceOf(address _owner,uint256 _id)  external view returns (uint256){
            
            return balances[_id][_owner];
        }
    }