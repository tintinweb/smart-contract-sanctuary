/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface PancakeSwap {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
}

contract Test is IERC20 {

    /* The stakeTimer is the timestamp on which the staker last withdrew their 
    rewards from the BNB -> VEL vault. The rewardCollectTimer is the timestamp 
    on which the staker last staked in the BNB -> VEL vault. The refer 
    property indicates how much VEL the staker has earned through referrals.
    The previousAmount property captures the value of ratioTracker when the 
    staker last staked in the VEL -> BNB pool.*/
    struct Staking {
        //   BNB -> VEL vault
        uint lpStaked;
        uint bnbStaked;
        uint stakeTimer;
        uint rewardCollectTimer;
        uint refer;

        //   VEL -> BNB vault
        uint velStaked;
        uint previousAmount;
    }

    /* The ratio tracker accumulates the quantity
    bigNumber * totalVelStaked / totalBnbRewardable,
    adding to it each time a user stakes into the BNB -> VEL pool.
    It is used to keep track of how much BNB a user
    will receive upon withdrawal. */
    uint private totalVelStaked = 0;
    uint private totalBnbRewadable = 0;
    uint private bigNumber = 10**18;
    uint private ratioTracker;


    /* The currentMultiplier at a given time is equivalent to the 
    APY relative to VEL divided by 100. */
    uint private currentMultiplier = 10;
   
    string public name = 'Test';
    string public symbol = 'TEST';
    uint public decimals = 18;
    uint private _totalSupply;

    address payable feeAddress;
    address         PANCAKEROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;       
    address private FACTORY = PancakeSwap(PANCAKEROUTER).factory();                
    address private WETHAddress = PancakeSwap(PANCAKEROUTER).WETH();  
 
    mapping (address => Staking) public vault;
    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;


    //Sets the fee address and creates the PancakeSwap pair
    constructor() {
        feeAddress = payable(msg.sender);
        mint(feeAddress,10**18);
    }

    receive() external payable {
       if(msg.sender != PANCAKEROUTER) stakeBnb(address(0));
    }

    function sendValue(address payable recipient, uint amount) private {
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Unable to send value, recipient may have reverted");
    }

    function velDivideBnb() public view returns (uint) {
        address poolAddress = PancakeSwap(FACTORY).getPair(address(this), WETHAddress); 
        return bigNumber * _balances[poolAddress] / IERC20(WETHAddress).balanceOf(poolAddress);
    }

    function bnbDivideVel() public view returns (uint) {
        address poolAddress = PancakeSwap(FACTORY).getPair(address(this), WETHAddress);
        return bigNumber * IERC20(WETHAddress).balanceOf(poolAddress) / _balances[poolAddress];
    }

    //Staking functions
    function stakeBnb(address ref) public payable {
     	sendValue(feeAddress, (address(this).balance - totalBnbRewadable) * 45 / 100);
        totalBnbRewadable +=  (address(this).balance - totalBnbRewadable) * 5 / 55;
     	uint allowableAmount = address(this).balance - totalBnbRewadable; 

     	ratioTracker += (bigNumber * totalBnbRewadable) / totalVelStaked;
        if(ref != address(0)) vault[ref].refer += (allowableAmount * velDivideBnb() / 20) / bigNumber;
        uint velAmount = (allowableAmount * velDivideBnb()) / bigNumber;
        mint(address(this), velAmount); 

        approve(PANCAKEROUTER, velAmount); 
        (,uint amountBnb, uint amountLiquidity) = PancakeSwap(PANCAKEROUTER).addLiquidityETH{ value: allowableAmount }
        (address(this), velAmount, 1, 1, address(this), 33136721748); 

        vault[msg.sender].lpStaked += amountLiquidity;
        vault[msg.sender].bnbStaked += amountBnb;  

        if (vault[msg.sender].stakeTimer == 0) vault[msg.sender].rewardCollectTimer = block.timestamp;
        vault[msg.sender].stakeTimer = block.timestamp;
        
        currentMultiplier += amountBnb * 700 / bigNumber;
    }

    function stakeVel(uint amount) external {
        require(amount <= _balances[msg.sender], "Amount chosen to stake must be less than balance");
        if(vault[msg.sender].velStaked != 0) withdrawBnbReward();
        _balances[msg.sender] -= amount;
        vault[msg.sender].velStaked += amount;
        vault[msg.sender].previousAmount = ratioTracker;
        totalVelStaked += amount;
    }

//Withdrawal functions
    function withdrawLp(uint amount) public {
        require(vault[msg.sender].stakeTimer + 2 minutes <= block.timestamp, "It has not yet been 10 days since you last staked");
        require(amount <= vault[msg.sender].lpStaked,"Amount withdrawn exceeds amount staked");
        withdrawVelRewardRefererall();
        PancakeSwap(PANCAKEROUTER).removeLiquidityETH(address(this), amount, 1, 1, msg.sender, 33136721748);
        vault[msg.sender].lpStaked -= amount;
        vault[msg.sender].bnbStaked -= amount * vault[msg.sender].bnbStaked / vault[msg.sender].lpStaked;
    }

    function withdrawBnbReward() public {
    	uint amount = vault[msg.sender].velStaked * (ratioTracker - vault[msg.sender].previousAmount) / bigNumber;
    	sendValue(payable(msg.sender), amount);
    	totalBnbRewadable -= amount;
    	vault[msg.sender].previousAmount = ratioTracker;
    }

    function withdrawVel(uint amount) public {
    	require(amount <= vault[msg.sender].velStaked, "Amount chosen to withdraw must be less than amount staked");
    	withdrawBnbReward();
    	vault[msg.sender].velStaked -= amount;
    	_balances[msg.sender] += amount;
    	totalVelStaked -= amount;
    }

    function withdrawVelRewardRefererall() public {
        require(vault[msg.sender].stakeTimer + 2 minutes <= block.timestamp, "It has not yet been 10 days since you last staked");
        vault[msg.sender].rewardCollectTimer = block.timestamp;

        mint(msg.sender, (currentMultiplier * vault[msg.sender].bnbStaked * 
        	(block.timestamp - vault[msg.sender].rewardCollectTimer) * 
        	velDivideBnb() / 31557600 / bigNumber) +vault[msg.sender].refer);
        vault[msg.sender].refer = 0;
    }

//Getter functions
    function totalSupply() external view override returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) external view override returns (uint) {
        return _allowances[owner][spender];
    }

//Minting function
    function mint(address account, uint amount) private {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

//Transfer functions
    function transfer(address to, uint amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) public override returns (bool) {
    	require(amount <=  _allowances[from][msg.sender]);
        _transfer(from, to, amount);
        _approve(from, msg.sender, _allowances[from][msg.sender] - amount);
        return true;
    }

    function _transfer(address from, address to, uint amount) private {
        require(amount <= _balances[from],"ERC20: Transfer amount greater than balance");
        require(amount != 0, "ERC20: Transfer amount was 0");
        require(from != address(0) && to != address(0), "ERC20: Transfer from/to the zero address");
    
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function approve(address to, uint amount) public virtual override returns (bool) {
        _approve(msg.sender, to, amount);
        return true;
    }

     function _approve(address from, address to, uint amount) internal virtual {
        require(from != address(0) && to != address(0), "ERC20: Approve from/to the zero address");

        _allowances[from][to] = amount;
        emit Approval(from, to, amount);
    }

    function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    	require(subtractedValue <= _allowances[msg.sender][spender],"ERC20: Decreased allowance below zero");
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }
}