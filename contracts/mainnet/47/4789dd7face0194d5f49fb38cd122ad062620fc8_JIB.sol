pragma solidity 0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */

library SafeMath 
{

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */

  function mul(uint256 a, uint256 b) internal pure returns(uint256 c) 
  {
     if (a == 0) 
     {
     	return 0;
     }
     c = a * b;
     assert(c / a == b);
     return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */

  function div(uint256 a, uint256 b) internal pure returns(uint256) 
  {
     return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */

  function sub(uint256 a, uint256 b) internal pure returns(uint256) 
  {
     assert(b <= a);
     return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */

  function add(uint256 a, uint256 b) internal pure returns(uint256 c) 
  {
     c = a + b;
     assert(c >= a);
     return c;
  }
}

contract ERC20Interface
{
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

interface tokenRecipient 
{ 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; 
}

/**
 * @title Basic token
 */

contract JIB is ERC20Interface
{
    using SafeMath for uint256;
   
    uint256 constant public TOKEN_DECIMALS = 10 ** 18;
    string public constant name            = "Jibbit Token";
    string public constant symbol          = "JIB";
    uint256 public totalTokenSupply        = 700000000 * TOKEN_DECIMALS;
    uint8 public constant decimals         = 18;
    address public owner;
    uint256 public totalBurned;
    bool stopped    = false;
    bool saleClosed = false;

    event Burn(address indexed _burner, uint256 _value);
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
    event OwnershipRenounced(address indexed _previousOwner);

    /** mappings **/ 
    mapping(address => uint256) public  balances;
    mapping(address => mapping(address => uint256)) internal  allowed;
    mapping(address => bool) public allowedAddresses;
 
    /**
     * @dev Throws if called by any account other than the owner.
     */

    modifier onlyOwner() 
    {
       require(msg.sender == owner);
       _;
    }
    
    /** constructor **/

    constructor() public
    {
       owner = msg.sender;
       balances[owner] = totalTokenSupply;
       allowedAddresses[owner] = true;

       emit Transfer(address(0x0), owner, balances[owner]);
    }

    /**
     * @dev This function has to be triggered once after ICO sale is completed
     */

    function saleCompleted() external onlyOwner
    {
        saleClosed = true;
    }

    /**
     * @dev To pause token transfer. In general pauseTransfer can be triggered
     *      only on some specific error conditions 
     */

    function pauseTransfer() external onlyOwner
    {
        stopped = true;
    }

    /**
     * @dev To resume token transfer
     */

    function resumeTransfer() external onlyOwner
    {
        stopped = false;
    }

    /**
     * @dev To add address into whitelist
     */

    function addToWhitelist(address _newAddr) public onlyOwner
    {
       allowedAddresses[_newAddr] = true;
    }

    /**
     * @dev To remove address from whitelist
     */

    function removeFromWhitelist(address _newAddr) public onlyOwner
    {
       allowedAddresses[_newAddr] = false;
    }

    /**
     * @dev To check whether address is whitelist or not
     */

    function isWhitelisted(address _addr) public view returns (bool) 
    {
       return allowedAddresses[_addr];
    }

    /**
     * @dev Burn specified number of GSCP tokens
     * This function will be called once after all remaining tokens are transferred from
     * smartcontract to owner wallet
     */

    function burn(uint256 _value) onlyOwner public returns (bool) 
    {
       require(!stopped);
       require(_value <= balances[msg.sender]);

       address burner = msg.sender;

       balances[burner] = balances[burner].sub(_value);
       totalTokenSupply = totalTokenSupply.sub(_value);
       totalBurned      = totalBurned.add(_value);

       emit Burn(burner, _value);
       emit Transfer(burner, address(0x0), _value);
       return true;
    }     

    /**
     * @dev total number of tokens in existence
     * @return An uint256 representing the total number of tokens in existence
     */

    function totalSupply() public view returns(uint256 _totalSupply) 
    {
       _totalSupply = totalTokenSupply;
       return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address
     * @param _owner The address to query the the balance of 
     * @return An uint256 representing the amount owned by the passed address
     */

    function balanceOf(address _owner) public view returns (uint256) 
    {
       return balances[_owner];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amout of tokens to be transfered
     */

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool)     
    {
       require(!stopped);

       if(!saleClosed && !isWhitelisted(msg.sender))
          return false;

       if (_value == 0) 
       {
           emit Transfer(_from, _to, _value);  // Follow the spec to launch the event when value is equal to 0
           return true;
       }

       require(_to != address(0x0));
       require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value >= 0);

       balances[_from] = balances[_from].sub(_value);
       allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
       balances[_to] = balances[_to].add(_value);

       emit Transfer(_from, _to, _value);
       return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds
     * @param _tokens The amount of tokens to be spent
     */

    function approve(address _spender, uint256 _tokens) public returns(bool)
    {
       require(!stopped);
       require(_spender != address(0x0));

       allowed[msg.sender][_spender] = _tokens;

       emit Approval(msg.sender, _spender, _tokens);
       return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender
     * @param _owner address The address which owns the funds
     * @param _spender address The address which will spend the funds
     * @return A uint256 specifing the amount of tokens still avaible for the spender
     */

    function allowance(address _owner, address _spender) public view returns(uint256)
    {
       require(!stopped);
       require(_owner != address(0x0) && _spender != address(0x0));

       return allowed[_owner][_spender];
    }

    /**
     * @dev transfer token for a specified address
     * @param _address The address to transfer to
     * @param _tokens The amount to be transferred
     */

    function transfer(address _address, uint256 _tokens) public returns(bool)
    {
       require(!stopped);

       if(!saleClosed && !isWhitelisted(msg.sender))
          return false;

       if (_tokens == 0) 
       {
           emit Transfer(msg.sender, _address, _tokens);  // Follow the spec to launch the event when tokens are equal to 0
           return true;
       }

       require(_address != address(0x0));
       require(balances[msg.sender] >= _tokens);

       balances[msg.sender] = (balances[msg.sender]).sub(_tokens);
       balances[_address] = (balances[_address]).add(_tokens);

       emit Transfer(msg.sender, _address, _tokens);
       return true;
    }

    /**
     * @dev transfer ownership of this contract, only by owner
     * @param _newOwner The address of the new owner to transfer ownership
     */

    function transferOwnership(address _newOwner)public onlyOwner
    {
       require(!stopped);
       require( _newOwner != address(0x0));

       balances[_newOwner] = (balances[_newOwner]).add(balances[owner]);
       balances[owner] = 0;
       owner = _newOwner;

       emit Transfer(msg.sender, _newOwner, balances[_newOwner]);
   }

   /**
    * @dev Allows the current owner to relinquish control of the contract
    * @notice Renouncing to ownership will leave the contract without an owner
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore
    */

   function renounceOwnership() public onlyOwner 
   {
      require(!stopped);

      owner = address(0x0);
      emit OwnershipRenounced(owner);
   }

   /**
    * @dev Increase the amount of tokens that an owner allowed to a spender
    */

   function increaseApproval(address _spender, uint256 _addedValue) public returns (bool success) 
   {
      require(!stopped);

      allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
   }

   /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender
    */

   function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool success) 
   {
      uint256 oldValue = allowed[msg.sender][_spender];

      require(!stopped);

      if (_subtractedValue > oldValue) 
      {
         allowed[msg.sender][_spender] = 0;
      }
      else 
      {
         allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
      }
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
   }

   function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) 
   {
      require(!stopped);

      tokenRecipient spender = tokenRecipient(_spender);

      if (approve(_spender, _value)) 
      {
          spender.receiveApproval(msg.sender, _value, this, _extraData);
          return true;
      }
   }

   /**
    * @dev To transfer back any accidental ERC20 tokens sent to this contract by owner
    */

   function transferAnyERC20Token(address _tokenAddress, uint256 _tokens) onlyOwner public returns (bool success) 
   {
      require(!stopped);

      return ERC20Interface(_tokenAddress).transfer(owner, _tokens);
   }

   /* This unnamed function is called whenever someone tries to send ether to it */

   function () public payable 
   {
      revert();
   }
}