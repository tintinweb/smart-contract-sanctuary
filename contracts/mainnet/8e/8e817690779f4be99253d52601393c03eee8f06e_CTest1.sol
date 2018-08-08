/**
 * Overflow aware uint math functions.
 *
 * Inspired by https://github.com/MakerDAO/maker-otc/blob/master/contracts/simple_market.sol
 */
contract SafeMath {
  //internals

  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}

/**
 * ERC 20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

/**
 * ERC 20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is Token {

    /**
     * Reviewed:
     * - Interger overflow = OK, checked
     */
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

}


/**
 * CTest1 crowdsale contract.
 *
 * Security criteria evaluated against http://ethereum.stackexchange.com/questions/8551/methodological-security-review-of-a-smart-contract
 *
 *
 */
contract CTest1 is StandardToken, SafeMath {

    string public name = "CTest1 Token";
    string public symbol = "CTest1";
    uint public decimals = 18;
    
    uint256 public totalSupply = 1000000;


    // Set the contract controller address
    // Set the 3 Founder addresses
    address public owner = msg.sender;
    address public Founder1 = 0xB5D39A8Ea30005f9114Bf936025De2D6f353813E;
    address public Founder2 = 0x00A591199F53907480E1f5A00958b93B43200Fe4;
    address public Founder3 = 0x0d19C131400e73c71bBB2bC1666dBa8Fe22d242D;


    event Buy(address indexed sender, uint eth, uint fbt);


    /**
     * ERC 20 Standard Token interface transfer function
     */
    function transfer(address _to, uint256 _value) returns (bool success) {
        return super.transfer(_to, _value);
    }
    /**
     * ERC 20 Standard Token interface transfer function
     *
     */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }
    
    
   
// CTest1 TOKEN FOUNDER ETH ADDRESSES 
// 0xB5D39A8Ea30005f9114Bf936025De2D6f353813E
// 0x00A591199F53907480E1f5A00958b93B43200Fe4
// 0x0d19C131400e73c71bBB2bC1666dBa8Fe22d242D
    
    
    function () payable {
        
        
        //If all the tokens are gone, stop!
        if (totalSupply < 1)
        {
            throw;
        }
        
        
        uint256 rate = 0;
        address recipient = msg.sender;
        
        
        //Set the price to 0.0003 ETH/CTest1
        //$0.10 per
        if (totalSupply > 975000)
        {
            rate = 3340;
        }
        
        //Set the price to 0.0015 ETH/CTest1
        //$0.50 per
        if (totalSupply < 975001)
        {
            rate = 668;
        }
        
        //Set the price to 0.0030 ETH/CTest1
        //$1.00 per
        if (totalSupply < 875001)
        {
            rate = 334;
        }
        
        //Set the price to 0.0075 ETH/CTest1
        //$2.50 per
        if (totalSupply < 475001)
        {
            rate = 134;
        }
        
        
       

        
        uint256 tokens = safeMul(msg.value, rate);
        tokens = tokens/1 ether;
        
        
        //Make sure they send enough to buy atleast 1 token.
        if (tokens < 1)
        {
            throw;
        }
        
        
        //Make sure someone isn&#39;t buying more than the remaining supply
        uint256 check = safeSub(totalSupply, tokens);
        if (check < 0)
        {
            throw;
        }
        
        
        //Make sure someone isn&#39;t buying more than the current tier
        if (totalSupply > 975000 && check < 975000)
        {
            throw;
        }
        
        //Make sure someone isn&#39;t buying more than the current tier
        if (totalSupply > 875000 && check < 875000)
        {
            throw;
        }
        
        //Make sure someone isn&#39;t buying more than the current tier
        if (totalSupply > 475000 && check < 475000)
        {
            throw;
        }
        
        
        //Prevent any ETH address from buying more than 50 CTest1 during the pre-sale
        if ((balances[recipient] + tokens) > 50 && totalSupply > 975000)
        {
            throw;
        }
        
        
        balances[recipient] = safeAdd(balances[recipient], tokens);
        
        totalSupply = safeSub(totalSupply, tokens);

    
	    Founder1.transfer((msg.value/3));					//Send the ETH
	    Founder2.transfer((msg.value/3));					//Send the ETH
	    Founder3.transfer((msg.value/3));					//Send the ETH

        Buy(recipient, msg.value, tokens);
        
    }
    
    
    
    //Burn all remaining tokens.
    //Only contract creator can do this.
    function Burn () {
        
        if (msg.sender == owner && totalSupply > 0)
        {
            totalSupply = 0;
        } else {throw;}

    }
    
    

}