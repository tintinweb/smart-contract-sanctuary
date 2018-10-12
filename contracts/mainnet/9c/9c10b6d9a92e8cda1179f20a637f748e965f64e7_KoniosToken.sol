pragma solidity ^0.4.18;

contract owned {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        require(newOwner != owner);  //check that ownership is not being transferred to self.
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }


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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
}


contract TokenERC20 {
    
    using SafeMath for uint256;
    
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        
        // Subtract from the sender .. Add the same to the recipient
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

}

/******************************************/
/*       KONIOS TOKEN STARTS HERE       */
/******************************************/


contract KoniosToken is owned, TokenERC20 {

    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    
    uint256 public soldTokens ;
    
    uint256 public remainingTokens ;

    uint256 startBlock; //crowdsale start block (set in constructor)

    uint256 teamLockup = 4505142; //team allocation cannot be created until this many blocks after endBlock (assuming 14 second blocks, this is 2 years)

    uint256 teamAllocation = 250000000 * 10 ** uint256(decimals); //5% of token supply(5,000,000,000) allocated post-crowdsale for the team fund
    bool teamAllocated = false; //this will change to true when the team fund is allocated

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* This notifies clients about the amount allocated to team fund */
    event AllocateTeamTokens(address indexed from, uint256 value);
    
     /* This notifies clients about the amount burned */
    event Burn(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function KoniosToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
            
            totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
            balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
            name = tokenName;                                   // Set the name for display purposes
            symbol = tokenSymbol;                               // Set the symbol for display purposes
            startBlock = block.number;
            
            remainingTokens = totalSupply ; //set the initial value of remainingTokens as totalSupply in the constructor

    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
        soldTokens = soldTokens.add(_value);
        remainingTokens = remainingTokens.sub(_value);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    /**
     * Set team tokens.
     *
     * Security review
     *
     * - Integer math: ok - only called once with fixed parameters
     *
     * Applicable tests:
     *
     * - Test founder token allocation too early
     * - Test founder token allocation on time
     * - Test founder token allocation twice
     *
     */
    function allocateTeamTokens() onlyOwner public returns (bool success){
        require( (startBlock + teamLockup) > block.number);          // Check if it is time to allocate team tokens
        require(!teamAllocated);
        //check if team tokens have already been allocated
        balanceOf[msg.sender] = balanceOf[msg.sender].add(teamAllocation);
        totalSupply = totalSupply.add(teamAllocation);
        teamAllocated = true;
        AllocateTeamTokens(msg.sender, teamAllocation);
        return true;
    }
    
    
    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }


}