pragma solidity ^0.6.0;
// SPDX-License-Identifier: UNLICENSED
// ----------------------------------------------------------------------------
// 'ezgamers' token contract

// Symbol      : ezgamers
// Name        : ezg
// Total supply: 1,000,000,000 (1 billion)
// Decimals    : 18
// ----------------------------------------------------------------------------

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

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 *
*/

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
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Token is ERC20Interface, Owned {
    using SafeMath for uint256;
    string public symbol = "EZG";
    string public  name = "Ezgamers";
    uint256 public decimals = 18;
    uint256 _totalSupply = 1e9 * 10 ** (decimals); 
    uint256 public soldTokens;
    uint256 private icoEndDate;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        owner = 0x833Cfb9D53cb5dC97F53F715f1555998Cf1251b9;
        icoEndDate = block.timestamp.add(4 weeks);
        balances[address(this)] =  onePercent(totalSupply()).mul(25);
        emit Transfer(address(0), address(this), onePercent(totalSupply()).mul(25));
        balances[address(owner)] =  onePercent(totalSupply()).mul(75);
        emit Transfer(address(0), address(owner), onePercent(totalSupply()).mul(75));
    }
    
    receive() external payable{
        
        require(block.timestamp <= icoEndDate && balanceOf(address(this)) > 0, "pre sale is finished");
        require(msg.value >= 0.25 ether, "Min allowed investment is 0.25 ethers");
        
        // receive ethers
        uint tokens = getTokenAmount(msg.value);
        _transfer(msg.sender, tokens, true);
        // send received funds to the owner
        owner.transfer(msg.value);
    }
    
    function getUnSoldTokens() external onlyOwner{
        // sale is over
        require(block.timestamp > icoEndDate && balanceOf((address(this))) > 0, "No tokens in contract to withdraw");
        
        _transfer(owner, balanceOf(address(this)), false); // send all the unsold tokens to the owner
    }
    
    function getTokenAmount(uint256 amount) internal pure returns(uint256){
        return amount * 400000;
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
        uint256 burn_value = 0;
        if (totalSupply().sub(tokens) > 100e6 * 10 ** (decimals)){
            burn_value = onePercent(tokens).mul(6);
            _burn(burn_value);
        }
            
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens.sub(burn_value));
        emit Transfer(msg.sender, to, tokens.sub(burn_value));
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Calculates onePercent of the uint256 amount sent
    // ------------------------------------------------------------------------
    function onePercent(uint256 _tokens) internal pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
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
        uint256 burn_value = 0;
        if (totalSupply().sub(tokens) > 100e6 * 10 ** (decimals)){
            burn_value = onePercent(tokens).mul(6);
            _burn(burn_value);
        }
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens.sub(burn_value));
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(from,to,tokens.sub(burn_value));
        return true;
    }
    
    
    function _transfer(address to, uint256 tokens, bool purchased) internal {
        // prevent transfer to 0x0, use burn instead
        require(address(to) != address(0));
        require(balances[address(this)] >= tokens );
        require(balances[to] + tokens >= balances[to]);
        
        balances[address(this)] = balances[address(this)].sub(tokens);
        balances[to] = balances[to].add(tokens);
        if(purchased)
            soldTokens = soldTokens.add(tokens);
        emit Transfer(address(this),to,tokens);
    }
    
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    /**
     * @dev Internal function that burns an amount of the token of a given
     * @param value The amount that will be burnt.
     */
    function _burn(uint256 value) internal {
        _totalSupply = _totalSupply.sub(value);
        balances[address(0)] = balances[address(0)].add(value);
        emit Transfer(address(msg.sender), address(0), value);
    }
}