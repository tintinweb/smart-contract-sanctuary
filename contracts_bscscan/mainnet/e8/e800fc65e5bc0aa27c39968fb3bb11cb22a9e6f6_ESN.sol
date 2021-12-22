/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

pragma solidity ^0.4.24;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// Ownership contract
// _newOwner is address of new owner
// ----------------------------------------------------------------------------
contract Owned {
    
    address public owner;
    

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = 0x9d993FA6a5eAdcfa126050f5ED35CaC735e9f695;
      
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // transfer Ownership to other address
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0x0));
        emit OwnershipTransferred(owner,_newOwner);
        owner = _newOwner;
    }
    
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply



// ----------------------------------------------------------------------------
contract ESN is ERC20Interface, Owned {
    
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public tokenSupply;



    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
   
    


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "ESN";
        name = "ETHICALLY SOURCED TOKEN";
        decimals = 18;
        tokenSupply = 200000000 * 10**uint(decimals);
		
        balances[owner] = tokenSupply;
    
       emit Transfer(address(0), owner, tokenSupply);
    
    }
    

    
  
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return tokenSupply;
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        require(to != address(0));
        require(tokens > 0);
        require(balances[msg.sender] >= tokens);
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        require(spender != address(0));
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(from != address(0));
        require(to != address(0));
        require(tokens > 0);
        require(balances[from] >= tokens);
        require(allowed[from][msg.sender] >= tokens);
        
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    
    // ------------------------------------------------------------------------
    // Increase the amount of tokens that an owner allowed to a spender.
    //
    // approve should be called when allowed[_spender] == 0. To increment
    // allowed value is better to use this function to avoid 2 calls (and wait until
    // the first transaction is mined)
    // _spender The address which will spend the funds.
    // _addedValue The amount of tokens to increase the allowance by.
    // ------------------------------------------------------------------------
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        require(_spender != address(0));
        
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    
    // ------------------------------------------------------------------------
    // Decrease the amount of tokens that an owner allowed to a spender.
    //
    // approve should be called when allowed[_spender] == 0. To decrement
    // allowed value is better to use this function to avoid 2 calls (and wait until
    // the first transaction is mined)
    // _spender The address which will spend the funds.
    // _subtractedValue The amount of tokens to decrease the allowance by.
    // ------------------------------------------------------------------------
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        require(_spender != address(0));
        
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
   

}