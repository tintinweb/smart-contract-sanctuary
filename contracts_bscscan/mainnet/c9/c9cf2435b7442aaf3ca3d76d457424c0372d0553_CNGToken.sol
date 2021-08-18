/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

pragma solidity >=0.4.22 <0.6.0;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes  _extraData) external; 
}




//begin Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function OwnableSet() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

//end Ownable.sol

// ----------------- 
//begin Pausable.sol



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
   emit Pause();

  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

//end Pausable.sol




contract CNGToken is Pausable {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 9;
    
    
    uint256 public totalSupply;
    uint256 public initialSupply;
    
    //These are addresses to send tax,charity,burn
    address public tax_address = 0x0e304e914786535F92b799808Bc39BB3568452C1;
    address public charity_address = 0x3b0cD33A49b5314443FA58136Eea7cAA54FD01e6;
    address public burn_address = 0x731592a680402dddd3cD941906D0Da2B6191F9EB;


    //These are first percent for tax,charity,burn
    uint256 public charity_percentage = 1;
    uint256 public tax_percentage = 1;
    uint256 public burn_percentage = 1;

    uint256 public charityvalue;
    uint256 public taxvalue;
    uint256 public burnvalue;

    uint256 public ALLsubAmount;
    

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
  
   
    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
      
    ) public {
        
        initialSupply = 10000000000;
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = "CNGToken";                                   // Set the name for display purposes
        symbol = "CNG";                                  // Set the symbol for display purposes
        
      

        
        
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));

        taxvalue = (_value / 100) * (tax_percentage); // Calculate ?% fee
        charityvalue = (_value / 100) * (charity_percentage); // Calculate ?% charity
        burnvalue = (_value / 100) * (burn_percentage); // Calculate ?% charity

        ALLsubAmount = taxvalue + charityvalue + burnvalue;
        
        _value -= ALLsubAmount;
        

        
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        
       // balanceOf[_from] -= taxvalue;
       // balanceOf[_from] -= charityvalue;
       // balanceOf[_from] -= burnvalue;


        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        
        balanceOf[tax_address] += taxvalue;
        emit Transfer(_from, tax_address, taxvalue);
        
        balanceOf[charity_address] += charityvalue;
        emit Transfer(_from, charity_address, charityvalue);
        
        balanceOf[burn_address] += charityvalue;
        emit Transfer(_from, burn_address, burnvalue);
        
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }




    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }






    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
     function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
        
       //burnvalue = (_value / 100) * (burn_percentage); // Calculate ?% burn
        
       _transfer(msg.sender, _to, _value);

       // _transfer(msg.sender, _to, (_value - taxvalue - burnvalue - charityvalue));
       
        //_transfer(msg.sender, tax_address, taxvalue);
        
        //_transfer(msg.sender, charity_address, charityvalue);

       // burn(burn_percentage);

        return true;
    
    }
    
    
    
    
    
    function setTaxPercentage( uint256 _value) public returns (bool success) {
      tax_percentage = _value;
      // emit SetTaxPercentage(msg.sender, tax_percentage);
       return true;  
    }
    
     function setCharityPercentage(uint256 _value) public returns (bool success) {
       charity_percentage = _value;
     //  emit SetCharityPercentage(msg.sender, charity_percentage);
       return true;  
    }
    
     function setBurnPercentage(uint256 _value) public returns (bool success) {
       burn_percentage = _value;
     //  emit SetBurnPercentage(msg.sender, burn_percentage);
       return true;  
    }

     function setTaxAddress(address _value) public returns (bool success) {
       tax_address = _value;
     //  emit SetTaxAddress(msg.sender, tax_address);
       return true;  
    }

     function setCharityAddress(address _value) public returns (bool success) {
       charity_address = _value;
     //  emit SetCharityAddress(msg.sender, charity_address);
       return true;  
    }
    

}