pragma solidity ^0.6.0;
// SPDX-License-Identifier: UNLICENSED

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 *
*/
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
 
  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual returns (bool success);
    function approve(address spender, uint256 tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface IERC20 {
    function transfer(address to, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

// ----------------------------------------------------------------------------
// 'MCORE' token AND staking contract

// Symbol      : MCORE
// Name        : MetaCore
// Total supply: 7000 (7 thousands)
// Decimals    : 18


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract MetaCore is ERC20Interface, Owned {
    using SafeMath for uint256;
   
    string public symbol = "MCORE";
    string public  name = "MetaCore";
    uint256 public decimals = 18;
    
    uint256 _totalSupply = 7e3 * 10 ** (decimals);
    
    uint256 deployTime;
    uint256 private totalDividentPoints;
    uint256 pointMultiplier = 1000000000000000000;
    uint256 public stakedCoins;
    
    uint256 public totalRewardsClaimed;
    
    address uniSwapAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address MCORE_WETH_POOL_ADDRESS = address(0);
    address devs;
    address communityFund;
    
    struct  Account {
        uint256 balance;
        uint256 lastDividentPoints;
        uint256 timeInvest;
        uint256 lastClaimed;
        uint256 rewardsClaimed;
        uint256 totalStakes;
        uint256 pending;
    }

    mapping(address => Account) accounts;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
   
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        
        owner = 0xcC3d0B03DCC7C2d4f7C71E4DAFDb1C40A4829Df5;
        devs =  0x81B794fad3BC654C8662614e83750E3541591fE5;
        communityFund = 0x9F2742e7427E26DeC6beD359F0B4b5bff6A41bB3;
        
        balances[communityFund] =  totalSupply(); // 7000
        emit Transfer(address(0), communityFund, totalSupply());
        
        deployTime = block.timestamp;
    }

    function setLpsAddress(address _MCORE_WETH_POOL_ADDRESS) external onlyOwner{
        require(_MCORE_WETH_POOL_ADDRESS != address(0), "Pool address cannot be zero");
        require(MCORE_WETH_POOL_ADDRESS == address(0), "Pool address already set");
        MCORE_WETH_POOL_ADDRESS = _MCORE_WETH_POOL_ADDRESS;
    }
    
    // ------------------------------------------------------------------------
    // Stake the 'MCORE-WETH Lp' tokens to earn reward in 'MCORE'tokens
    // ------------------------------------------------------------------------
    
    function STAKE(uint256 _tokens) external returns(bool){
        require(IERC20(MCORE_WETH_POOL_ADDRESS).transferFrom(msg.sender, address(this), _tokens), "Insufficient Tokens!");

        stakedCoins = stakedCoins.add(_tokens); // MCORE_WETH Lp
        
        uint256 owing = dividendsOwing(msg.sender); // MCORE tokens
        
        if(owing > 0) { // checks previous pending rewards
            accounts[msg.sender].pending = owing;
        }
        
        accounts[msg.sender].balance = accounts[msg.sender].balance.add(_tokens); // MCORE_WETH Lp
        accounts[msg.sender].lastDividentPoints = totalDividentPoints;            // MCORE tokens
        accounts[msg.sender].timeInvest = now;
        accounts[msg.sender].lastClaimed = now;
        accounts[msg.sender].totalStakes = accounts[msg.sender].totalStakes.add(_tokens); // MCORE_WETH Lp
        
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Gives the tokens in MCORE - ready to claim
    // ------------------------------------------------------------------------
    function pendingReward(address _user) external view returns(uint256 MCORE){
        uint256 owing = dividendsOwing(_user);
        return owing;
    }
    
    // ------------------------------------------------------------------------
    // internal function used when MCORE tokens reward is claimed
    // ------------------------------------------------------------------------
    function updateDividend(address investor) internal returns(uint256){
        uint256 owing = dividendsOwing(investor);       // MCORE tokens
        if (owing > 0){
            accounts[investor].lastDividentPoints = totalDividentPoints; 
        }
        return owing;
    }
    
    // ------------------------------------------------------------------------
    // Gives the MCORE_WETH Lp tokens actively staked by the user
    // ------------------------------------------------------------------------
    function activeStake(address _user) external view returns (uint256){
        return accounts[_user].balance;
    }
    
    // ------------------------------------------------------------------------
    // Gives the MCORE_WETH Lp tokens staked by the user till the current date
    // ------------------------------------------------------------------------
    function totalStakesTillToday(address _user) external view returns (uint256){
        return accounts[_user].totalStakes;
    }
   
    // ------------------------------------------------------------------------
    // Used to stop the staking and get back MCORE_WETH Lp Tokens
    // ------------------------------------------------------------------------
    function UNSTAKE() external returns (bool){
        require(stakedCoins > 0);   // MCORE_WETH Lp 
        require(accounts[msg.sender].balance > 0); // MCORE_WETH Lp 
        
        uint256 owing = dividendsOwing(msg.sender); // MCORE tokens
        
        if(owing > 0) { // checks previous pending rewards
            accounts[msg.sender].pending = owing;
        }
        
        stakedCoins = stakedCoins.sub(accounts[msg.sender].balance); // MCORE_WETH Lp 
       
        require(IERC20(MCORE_WETH_POOL_ADDRESS).transfer(msg.sender, accounts[msg.sender].balance)); // sends the lp tokens back from the contract to the investor
       
        accounts[msg.sender].balance = 0; // reset the balance of the investor
        
        return true;
    }
    
    // -------------------------------------------------------------------------------
    // Internal function used to disburse the MCORE tokens among all Lp tokens staked
    // -------------------------------------------------------------------------------
    function disburse(uint256 amount) internal{
        uint256 unnormalized = amount.mul(pointMultiplier);
        totalDividentPoints = totalDividentPoints.add(unnormalized.div(stakedCoins)); // stakedCoins is the MCORE_WETH lp tokens
    }
   
    // -------------------------------------------------------------------------------
    // Internal function gives how much MCORE tokens reward is ready to be claimed
    // -------------------------------------------------------------------------------
    function dividendsOwing(address investor) internal view returns (uint256){
        uint256 newDividendPoints = totalDividentPoints.sub(accounts[investor].lastDividentPoints);
        return (((accounts[investor].balance).mul(newDividendPoints)).div(pointMultiplier)).add(accounts[investor].pending);
    }
    
    // -------------------------------------------------------------------------------
    // Used to claim the reward in MCORE tokens 
    // -------------------------------------------------------------------------------
    function claimReward() external returns(bool){
        uint256 owing = updateDividend(msg.sender); // MCORE tokens ready to be claimed

        require(_transfer(msg.sender, owing));
        
        accounts[msg.sender].rewardsClaimed = accounts[msg.sender].rewardsClaimed.add(owing);
       
        totalRewardsClaimed = totalRewardsClaimed.add(owing);
        return true;
    }
    
    function rewardsClaimed(address _user) external view returns(uint256 rewardClaimed){
        return accounts[_user].rewardsClaimed;
    }
   
    /** ERC20Interface function's implementation **/
   
    function totalSupply() public override view returns (uint256){
       return _totalSupply;
    }
   
    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens) public override returns (bool success) {
        // prevent transfer to 0x0, use burn instead
        require(address(to) != address(0));
        require(balances[msg.sender] >= tokens );
        require(balances[to] + tokens >= balances[to]);
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
       
        uint256 deduction = applyDeductions(to, tokens);
        
        balances[to] = balances[to].add(tokens.sub(deduction));
        emit Transfer(msg.sender, to, tokens.sub(deduction));
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Apply 1.5% deduction on every token transfer
    // 0.02% is given to the devs, 
    // 0.06% goes to a community fund, 
    // and the 1.42% goes to farmers split 
    // ------------------------------------------------------------------------
    function applyDeductions(address to, uint256 tokens) private returns(uint256){
        uint256 deduction = 0;
        if(to != uniSwapAddress && to != address(this))
            deduction = findOnePointFivePercent(tokens);
        
        uint256 devsTokens = findZeroPointZeroTwoPercent(deduction);
        balances[devs] = balances[devs].add(devsTokens);
        emit Transfer(address(this), devs, devsTokens);
            
        uint256 communityFundTokens = findZeroPointZeroSixPercent(deduction);
        balances[communityFund] = balances[communityFund].add(communityFundTokens);
        emit Transfer(address(this), communityFund, communityFundTokens);
            
        if(stakedCoins == 0){
            
        }
        else{
            balances[address(this)] = balances[address(this)].add(findOnePointFourTwoPercent(deduction));
            disburse(findOnePointFourTwoPercent(deduction));
        }
        return deduction;
    }
   
    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens) public override returns (bool success){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success){
        require(tokens <= allowed[from][msg.sender]); //check allowance
        require(balances[from] >= tokens);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
      
        uint256 deduction = applyDeductions(to, tokens);
       
        balances[to] = balances[to].add(tokens.sub(deduction));
        emit Transfer(from, to, tokens.sub(tokens));
        return true;
    }

    // no deductions are applied on claim of rewards
    function _transfer(address to, uint256 tokens) internal returns(bool){
        // prevent transfer to 0x0, use burn instead
        require(address(to) != address(0));
        require(balances[address(this)] >= tokens );
        require(balances[to] + tokens >= balances[to]);
        balances[address(this)] = balances[address(this)].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(address(this),to,tokens);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    /***********************************************UTILITY FUNCTIONS**************************************************************************/
    
    // ------------------------------------------------------------------------
    // Calculates 1.5% of the value sent
    // ------------------------------------------------------------------------
    function findOnePointFivePercent(uint256 value) private pure returns (uint256)  {
        uint256 result = onePercent(value);
        result = result.mul(15);
        result = result.div(10);
        return result;
    }
    
    // ------------------------------------------------------------------------
    // Calculates 0.02% of the value sent
    // ------------------------------------------------------------------------
    function findZeroPointZeroTwoPercent(uint256 value) private pure returns (uint256) {
        uint256 result = onePercent(value);
        result = result.mul(2);
        result = result.div(100);
        return result;
    }
    
    // ------------------------------------------------------------------------
    // Calculates 0.06% of the value sent
    // ------------------------------------------------------------------------
    function findZeroPointZeroSixPercent(uint256 value) private pure returns (uint256) {
        uint256 result = onePercent(value);
        result = result.mul(6);
        result = result.div(100);
        return result;
    }
    
    // ------------------------------------------------------------------------
    // Calculates 1.42% of the value sent 
    // ------------------------------------------------------------------------
    function findOnePointFourTwoPercent(uint256 value) private pure returns (uint256) {
        uint256 result = onePercent(value);
        result = result.mul(142);
        result = result.div(100);
        return result;
    }
    
    // ------------------------------------------------------------------------
    // Calculates onePercent of the uint256 amount sent
    // ------------------------------------------------------------------------
    function onePercent(uint256 _tokens) internal pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
}