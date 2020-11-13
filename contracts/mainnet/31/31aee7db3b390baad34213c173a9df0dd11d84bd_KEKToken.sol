pragma solidity ^0.6.0;
// SPDX-License-Identifier: UNLICENSED

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
// 'KEK' token contract

// Symbol      : KEK
// Name        : KEK
// Total supply: 70,000,000 (70 million)
// Decimals    : 18
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract KEKToken is ERC20Interface, Owned {
    using SafeMath for uint256;
    string public symbol = "KEK";
    string public  name = "KEK";
    uint256 public decimals = 18;
    uint256 _totalSupply = 7e7 * 10 ** decimals;
    uint256 private stakingRewards = 0;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) allowedPools;
    
    modifier onlyPools(address _caller){
        require(allowedPools[_caller], "UnAuthorized");
        _;
    }

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address team, address payable presale, address production, address airdropRewards) public {
        owner = presale;
        
        balances[address(this)] = totalSupply();

        emit Transfer(address(0),address(this), totalSupply());

        balances[address(this)] = balances[address(this)].sub(3500000 * 10 ** decimals);
        balances[presale] = balances[presale].add(3500000 * 10 ** decimals);
        emit Transfer(address(this), presale, 3500000 * 10 ** decimals);

        balances[address(this)] = balances[address(this)].sub(7000000 * 10 ** decimals);
        balances[team] = balances[team].add(7000000 * 10 ** decimals);
        emit Transfer(address(this), team, 7000000 * 10 ** decimals);

        balances[address(this)] = balances[address(this)].sub(7000000 * 10 ** decimals);
        balances[production] = balances[production].add(7000000 * 10 ** decimals);
        emit Transfer(address(this), production, 7000000 * 10 ** decimals);

        balances[address(this)] = balances[address(this)].sub(3500000 * 10 ** decimals);
        balances[airdropRewards] = balances[airdropRewards].add(3500000 * 10 ** decimals);
        emit Transfer(address(this), airdropRewards, 3500000 * 10 ** decimals);
        
        stakingRewards = 49000000 * 10 ** decimals; // keep rest of all stakingRewards inside the contract
    }
    
    function claimRewards(uint256 rewards, address rewardedTo) public onlyPools(msg.sender) returns(bool){
        
        // check the address should not be 0
        require(address(rewardedTo) != address(0), "Reward taker shall not be address 0");
        require(stakingRewards > 0, "Insufficient rewards available in KEK");
        
        if(stakingRewards < rewards)
            rewards = stakingRewards;
            
        balances[address(this)] = balances[address(this)].sub(rewards);
        balances[rewardedTo] = balances[rewardedTo].add(rewards);
        emit Transfer(address(this),rewardedTo,rewards); 
        
        stakingRewards = stakingRewards.sub(rewards);
        
        return true;
    }
    
    function configureAllowedPools(address poolAddress) external onlyOwner{
        require(poolAddress != address(0), "Invalid pool address");
        allowedPools[poolAddress] = true;
    }
    
    function removePools(address poolAddress) external onlyOwner{
        require(poolAddress != address(0), "Invalid pool address");
        allowedPools[poolAddress] = false;
    }
    
    function stakingRewardsAvailable() public view returns(uint256 _rewardsAvailable){
        return stakingRewards;
    }
    
    function getTokensInEmergency(uint256 tokens) public onlyOwner{
        balances[address(this)] = balances[address(this)].sub(tokens);
        balances[owner] = balances[owner].add(tokens);
        emit Transfer(address(this),owner,tokens); 
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
        require(balances[msg.sender] >= tokens);
        require(balances[to] + tokens >= balances[to]);
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender,to,tokens);
        return true;
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
        require(balances[to] + tokens >= balances[to]);
        
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(from,to,tokens);
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
    // @dev Public function that burns an amount of the token from a given account
    // @param _amount The amount that will be burnt
    // @param _account The tokens to burn from
    // can be used from account owner
    // ------------------------------------------------------------------------
    function burnTokens(uint256 _amount, address _account) public {
        require(msg.sender == _account, "UnAuthorized");
        require(balances[_account] >= _amount, "Insufficient account balance");
        _totalSupply = _totalSupply.sub(_amount);
        balances[_account] = balances[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }
}