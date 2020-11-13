pragma solidity ^0.6.0;
// "SPDX-License-Identifier: UNLICENSED "

// ----------------------------------------------------------------------------
// 'FSD' token contract

// Name: Fireside Token
// Ticker: FSD
// Total supply: 20M
// 5.2 million released at 10% per month
// 3% burn on each transaction
// ----------------------------------------------------------------------------


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
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Token is ERC20Interface, Owned {
    using SafeMath for uint256;
    string public symbol = "FSD";
    string public  name = "Fireside Token";
    uint256 public decimals = 18;
    uint256 private _totalSupply = 20e6 * 10 ** (decimals);
    
    struct Locked{
        uint256 tokens;
        uint256 lastVisit;
    }
    mapping(address => Locked) lockedTokens;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        owner = 0xa87e5b051541f289e9141Be73f05ca68B3dc3D8C;
        balances[address(owner)] = totalSupply();
        lockedTokens[owner].lastVisit = now;
        lockedTokens[owner].tokens = 5200000 * 10 ** (decimals); // 5.2 million
        emit Transfer(address(0),address(owner), totalSupply());
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

        if (lockedTokens[msg.sender].tokens > 0){
            check_time(msg.sender);
        }
        require(balances[msg.sender].sub(tokens) >= lockedTokens[msg.sender].tokens, "Please wait for tokens to be released");
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        
        uint256 toBurn = onePercent(tokens).mul(3); // 3% transaction deduction
        burnTokens(toBurn);
        
        balances[to] = balances[to].add(tokens.sub(toBurn));
        
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function check_time(address _from) private {
        if ((now.sub(lockedTokens[_from].lastVisit)).div(30 days) >= 1){
            uint256 months;
            uint256 released;
            uint256 monthlyAllowed = 520000 * 10 ** (decimals); // 520,000 per month
            months = (now.sub(lockedTokens[_from].lastVisit)).div(30 days);
            released = months.mul(monthlyAllowed);
            if (released > lockedTokens[_from].tokens){
                released = lockedTokens[_from].tokens;
            }
            lockedTokens[_from].lastVisit = now;
            lockedTokens[_from].tokens = lockedTokens[_from].tokens.sub(released);
        }
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
        
        if (lockedTokens[from].tokens > 0){
            check_time(from);
        }
        require(balances[from].sub(tokens) >= lockedTokens[from].tokens, "Please wait for tokens to be released");
        
        
        balances[from] = balances[from].sub(tokens);
        
        uint256 toBurn = onePercent(tokens).mul(3); // 3% transaction deduction
        burnTokens(toBurn);
        
        balances[to] = balances[to].add(tokens.sub(toBurn));
        
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
    // Calculates onePercent of the uint256 amount sent
    // ------------------------------------------------------------------------
    function onePercent(uint256 _tokens) internal pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
    
    // ------------------------------------------------------------------------
    // Burn the ``value` amount of tokens from the `account`
    // ------------------------------------------------------------------------
    function burnTokens(uint256 value) internal{
        require(_totalSupply >= value); // burn only unsold tokens
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(msg.sender, address(0), value);
    }

}