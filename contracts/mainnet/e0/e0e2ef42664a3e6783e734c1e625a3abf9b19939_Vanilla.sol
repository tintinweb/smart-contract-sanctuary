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
// 'VANILLA' token AND staking contract

// Symbol      : VANILLA
// Name        : Vanilla Network
// Total supply: 1,000,000 (1 million)
// Min supply  : 100k 
// Decimals    : 18


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Vanilla is ERC20Interface, Owned {
    using SafeMath for uint256;
   
    string public symbol = "VANILLA";
    string public  name = "Vanilla Network";
    uint256 public decimals = 18;
    
    uint256 _totalSupply = 1e6 * 10 ** (decimals); // 1,000,000
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
   
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address icoContract) public {
        
        owner = 0xFa50b82cbf2942008A097B6289F39b1bb797C5Cd;
        
        balances[icoContract] =  450000 * 10 ** (18); // 450,000
        emit Transfer(address(0), icoContract, 450000 * 10 ** (18));
        
        balances[address(owner)] =  550000 * 10 ** (18); // 550,000
        emit Transfer(address(0), address(owner), 550000 * 10 ** (18));
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
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens) public override returns (bool success){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
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
       
        uint256 deduction = deductionsToApply(tokens);
        applyDeductions(deduction);
        
        balances[to] = balances[to].add(tokens.sub(deduction));
        emit Transfer(msg.sender, to, tokens.sub(deduction));
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
      
        uint256 deduction = deductionsToApply(tokens);
        applyDeductions(deduction);
       
        balances[to] = balances[to].add(tokens.sub(deduction));
        emit Transfer(from, to, tokens.sub(tokens));
        return true;
    }
    
    function _transfer(address to, uint256 tokens, bool rewards) internal returns(bool){
        // prevent transfer to 0x0, use burn instead
        require(address(to) != address(0));
        require(balances[address(this)] >= tokens );
        require(balances[to] + tokens >= balances[to]);
        
        balances[address(this)] = balances[address(this)].sub(tokens);
        
        uint256 deduction = 0;
        
        if(!rewards){
            deduction = deductionsToApply(tokens);
            applyDeductions(deduction);
        }
        
        balances[to] = balances[to].add(tokens.sub(deduction));
            
        emit Transfer(address(this),to,tokens.sub(deduction));
        
        return true;
    }

    function deductionsToApply(uint256 tokens) private view returns(uint256){
        uint256 deduction = 0;
        uint256 minSupply = 100000 * 10 ** (18);
        
        if(_totalSupply > minSupply){
        
            deduction = onePercent(tokens).mul(5); // 5% transaction cost
        
            if(_totalSupply.sub(deduction) < minSupply)
                deduction = _totalSupply.sub(minSupply);
        }
        
        return deduction;
    }
    
    function applyDeductions(uint256 deduction) private{
        if(stakedCoins == 0){
            burnTokens(deduction);
        }
        else{
            burnTokens(deduction.div(2));
            disburse(deduction.div(2));
        }
    }
    
    // ------------------------------------------------------------------------
    // Burn the ``value` amount of tokens from the `account`
    // ------------------------------------------------------------------------
    function burnTokens(uint256 value) internal{
        require(_totalSupply >= value); // burn only unsold tokens
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(msg.sender, address(0), value);
    }
    
    // ------------------------------------------------------------------------
    // Calculates onePercent of the uint256 amount sent
    // ------------------------------------------------------------------------
    function onePercent(uint256 _tokens) internal pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
    
    
    /********************************STAKING CONTRACT**********************************/
    
    uint256 deployTime;
    uint256 private totalDividentPoints;
    uint256 private unclaimedDividendPoints;
    uint256 pointMultiplier = 1000000000000000000;
    uint256 public stakedCoins;
    
    uint256 public totalStakes;
    uint256 public totalRewardsClaimed;
    
    bool public stakingOpen;
    
    struct  Account {
        uint256 balance;
        uint256 lastDividentPoints;
        uint256 timeInvest;
        uint256 lastClaimed;
        uint256 rewardsClaimed;
        uint256 pending;
    }

    mapping(address => Account) accounts;
    
    function openStaking() external onlyOwner{
        require(!stakingOpen, "staking already open");
        stakingOpen = true;
    }
    
    function STAKE(uint256 _tokens) external returns(bool){
        require(stakingOpen, "staking is close");
        // gets VANILLA tokens from user to contract address
        require(transfer(address(this), _tokens), "In sufficient tokens in user wallet");
        
        uint256 owing = dividendsOwing(msg.sender);
        
        if(owing > 0) // early stakes
            accounts[msg.sender].pending = owing;
            
        uint256 deduction = deductionsToApply(_tokens);
        
        stakedCoins = stakedCoins.add(_tokens.sub(deduction));
        accounts[msg.sender].balance = accounts[msg.sender].balance.add(_tokens.sub(deduction));
        accounts[msg.sender].lastDividentPoints = totalDividentPoints;
        accounts[msg.sender].timeInvest = now;
        accounts[msg.sender].lastClaimed = now;
        
        totalStakes = totalStakes.add(_tokens.sub(deduction));
        
        return true;
    }
    
    function pendingReward(address _user) external view returns(uint256){
        uint256 owing = dividendsOwing(_user);
        return owing;
    }
    
    function dividendsOwing(address investor) internal view returns (uint256){
        uint256 newDividendPoints = totalDividentPoints.sub(accounts[investor].lastDividentPoints);
        return (((accounts[investor].balance).mul(newDividendPoints)).div(pointMultiplier)).add(accounts[investor].pending);
    }
   
    function updateDividend(address investor) internal returns(uint256){
        uint256 owing = dividendsOwing(investor);
        if (owing > 0){
            unclaimedDividendPoints = unclaimedDividendPoints.sub(owing);
            accounts[investor].lastDividentPoints = totalDividentPoints;
        }
        return owing;
    }
   
    function activeStake(address _user) external view returns (uint256){
        return accounts[_user].balance;
    }
   
    function UNSTAKE() external returns (bool){
        require(accounts[msg.sender].balance > 0);
        
        uint256 owing = updateDividend(msg.sender);
        if(owing > 0) // unclaimed reward
            accounts[msg.sender].pending = owing;
        
        stakedCoins = stakedCoins.sub(accounts[msg.sender].balance);

        require(_transfer(msg.sender, accounts[msg.sender].balance, false));
       
        accounts[msg.sender].balance = 0;
        return true;
    }
   
    function disburse(uint256 amount) internal{
        balances[address(this)] = balances[address(this)].add(amount);
        
        uint256 unnormalized = amount.mul(pointMultiplier);
        totalDividentPoints = totalDividentPoints.add(unnormalized.div(stakedCoins));
        unclaimedDividendPoints = unclaimedDividendPoints.add(amount);
    }
   
    function claimReward() external returns(bool){
        uint256 owing = updateDividend(msg.sender);
        
        require(owing > 0);

        require(_transfer(msg.sender, owing, true));
        
        accounts[msg.sender].rewardsClaimed = accounts[msg.sender].rewardsClaimed.add(owing);
       
        totalRewardsClaimed = totalRewardsClaimed.add(owing);
        return true;
    }
    
    function rewardsClaimed(address _user) external view returns(uint256 rewardClaimed){
        return accounts[_user].rewardsClaimed;
    }
}