pragma solidity ^0.4.18;


/**
 * 
 * This contract is used to set admin to the contract  which has some additional features such as minting , burning etc
 * 
 */
    contract Owned {
        address public owner;

        function owned() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }
        
        /* This function is used to transfer adminship to new owner
         * @param  _newOwner - address of new admin or owner        
         */

        function transferOwnership(address _newOwner) onlyOwner public {
            owner = _newOwner;
        }          
    }


/**
 * This is base ERC20 Contract , basically ERC-20 defines a common list of rules for all Ethereum tokens to follow
 */ 

contract ERC20 {
  
  using SafeMath for uint256;

  //This creates an array with all balances 
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) allowed;  

  //This maintains list of all black list account
  mapping(address => bool) public isblacklistedAccount;
    
  // public variables of the token  
  string public name;
  string public symbol;
  uint8 public decimals = 4;
  uint256 public totalSupply;
   
  // This notifies client about the approval done by owner to spender for a given value
  event Approval(address indexed owner, address indexed spender, uint256 value);

  // This notifies client about the approval done
  event Transfer(address indexed from, address indexed to, uint256 value);
 
  
  function ERC20(uint256 _initialSupply,string _tokenName, string _tokenSymbol) public {    
    totalSupply = _initialSupply * 10 ** uint256(decimals); // Update total supply with the decimal amount     
    balanceOf[msg.sender] = totalSupply;  
    name = _tokenName;
    symbol = _tokenSymbol;   
  }
  
    /* This function is used to transfer tokens to a particular address 
     * @param _to receiver address where transfer is to be done
     * @param _value value to be transferred
     */
	function transfer(address _to, uint256 _value) public returns (bool) {
        require(!isblacklistedAccount[msg.sender]);                 // Check if sender is not blacklisted
        require(!isblacklistedAccount[_to]);                        // Check if receiver is not blacklisted
		require(balanceOf[msg.sender] > 0);                     
		require(balanceOf[msg.sender] >= _value);                   // Check if the sender has enough  
		require(_to != address(0));                                 // Prevent transfer to 0x0 address. Use burn() instead
		require(_value > 0);
		require(balanceOf[_to] .add(_value) >= balanceOf[_to]);     // Check for overflows 
		require(_to != msg.sender);                                 // Check if sender and receiver is not same
		balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);  // Subtract value from sender
		balanceOf[_to] = balanceOf[_to].add(_value);                // Add the value to the receiver
		Transfer(msg.sender, _to, _value);                          // Notify all clients about the transfer events
        return true;
	}

	/* Send _value amount of tokens from address _from to address _to
     * The transferFrom method is used for a withdraw workflow, allowing contracts to send
     * tokens on your behalf
     * @param _from address from which amount is to be transferred
     * @param _to address to which amount is transferred
     * @param _amount to which amount is transferred
     */
    function transferFrom(
         address _from,
         address _to,
         uint256 _amount
     ) public returns (bool success)
      {
         if (balanceOf[_from] >= _amount
             && allowed[_from][msg.sender] >= _amount
             && _amount > 0
             && balanceOf[_to].add(_amount) > balanceOf[_to])
        {
             balanceOf[_from] = balanceOf[_from].sub(_amount);
             allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
             balanceOf[_to] = balanceOf[_to].add(_amount);
             return true;
        } else {
             return false;
        }
    }
    
    /* This function allows _spender to withdraw from your account, multiple times, up to the _value amount.
     * If this function is called again it overwrites the current allowance with _value.
     * @param _spender address of the spender
     * @param _amount amount allowed to be withdrawal
     */
     function approve(address _spender, uint256 _amount) public returns (bool success) {
         allowed[msg.sender][_spender] = _amount;
         Approval(msg.sender, _spender, _amount);
         return true;
    } 

    /* This function returns the amount of tokens approved by the owner that can be
     * transferred to the spender&#39;s account
     * @param _owner address of the owner
     * @param _spender address of the spender 
     */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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



//This is the Main Morph Token Contract derived from the other two contracts Owned and ERC20
contract MorphToken is Owned, ERC20 {

    using SafeMath for uint256;

    uint256  tokenSupply = 100000000; 
             
    // This notifies clients about the amount burnt , only admin is able to burn the contract
    event Burn(address from, uint256 value); 
    
    /* This is the main Token Constructor 
     * @param _centralAdmin  Address of the admin of the contract
     */
	function MorphToken() 

	ERC20 (tokenSupply,"MORPH","MORPH") public
    {
		owner = msg.sender;
	}

       
    /* This function is used to Blacklist a user or unblacklist already blacklisted users, blacklisted users are not able to transfer funds
     * only admin can invoke this function
     * @param _target address of the target 
     * @param _isBlacklisted boolean value
     */
    function blacklistAccount(address _target, bool _isBlacklisted) public onlyOwner {
        isblacklistedAccount[_target] = _isBlacklisted;       
    }


    /* This function is used to mint additional tokens
     * only admin can invoke this function
     * @param _mintedAmount amount of tokens to be minted  
     */
    function mintTokens(uint256 _mintedAmount) public onlyOwner {
        balanceOf[owner] = balanceOf[owner].add(_mintedAmount);
        totalSupply = totalSupply.add(_mintedAmount);
        Transfer(0, owner, _mintedAmount);      
    }    

     /**
    * This function Burns a specific amount of tokens.
    * @param _value The amount of token to be burned.
    */
    function burn(uint256 _value) public onlyOwner {
      require(_value <= balanceOf[msg.sender]);
      // no need to require value <= totalSupply, since that would imply the
      // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure
      address burner = msg.sender;
      balanceOf[burner] = balanceOf[burner].sub(_value);
      totalSupply = totalSupply.sub(_value);
      Burn(burner, _value);
  }
}