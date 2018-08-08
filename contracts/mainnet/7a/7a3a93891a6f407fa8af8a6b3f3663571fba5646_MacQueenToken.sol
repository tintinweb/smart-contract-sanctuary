pragma solidity ^0.4.17;


// ----------------------------------------------------------------------------
// MQN token contract
//
// Symbol           : MQN
// Name             : MacQueen
// Total Supply     : 900,000,000
// Decimals         : 8
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe math
// ----------------------------------------------------------------------------
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
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// FiatContract 
// ----------------------------------------------------------------------------
contract FiatContract {

    function USD(uint _id) constant public returns (uint256);

}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract MacQueenToken is ERC20Interface {
    
    //FiatContract price = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591); // MAINNET ADDRESS
    FiatContract price = FiatContract(0x2CDe56E5c8235D6360CCbb0c57Ce248Ca9C80909); // TESTNET ADDRESS (ROPSTEN)
    
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    address public owner;
    bool isStopped = false;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    modifier onlyWhenRunning {
        require(!isStopped);
        _;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function MacQueenToken() public {
        symbol = "MQN";
        name = "MacQueen";
        decimals = 8;
        _totalSupply = 900000000;
        _totalSupply = _totalSupply.mul(10 ** uint(decimals));
        owner = msg.sender;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
    
    
    function() public payable {
        buyTokens();
    }
    
    function buyTokens() onlyWhenRunning public payable {
        require(msg.value > 0);
        
        uint256 tokenPrice; // ETH  value 
        //uint256 ethCent = price.USD(0); // 0.01 $ in wei
        
        // Remove in PRODUCTION
        uint256 ethCent = 14157267420000;
        
        tokenPrice = ethCent.mul(9); // 0.09 $ in wei
        uint tokens = msg.value.div(tokenPrice).mul(10 ** uint(decimals)); // 1 MQN = 0.09 $
        
        // owner should have enough tokens to sell
        require(balances[owner] >= tokens);
        
        // token transfer to buyer
        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[owner] = balances[owner].sub(tokens);
        
        // ETH transfer the the owner
        owner.transfer(msg.value);
        
        // Log event
        emit Transfer(owner, msg.sender, tokens);
        
    }
    
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
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
    // from the token owner&#39;s account
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
    // transferred to the spender&#39;s account
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
    
    
    // ------------------------------------------------------------------------
    // stop the ICO
    // ------------------------------------------------------------------------
    function stopICO() onlyOwner public {
        isStopped = true;
    }
    
    
    // ------------------------------------------------------------------------
    // resume the ICO
    // ------------------------------------------------------------------------
    function resumeICO() onlyOwner public {
        isStopped = false;
    }

}