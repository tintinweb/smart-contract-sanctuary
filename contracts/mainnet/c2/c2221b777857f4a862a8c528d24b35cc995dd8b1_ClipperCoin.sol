//////////////////////////////////////////////////////////////////////////////////////////
//																						//
//	Title: 						Clipper Coin Creation Contract							//
//	Author: 					Marko Valentin Micic									//
//	Version: 					v0.1													//
//	Date of current version:	2017/09/01												//
//	Brief Description:			The smart contract that will create tokens. The tokens	//
//								will be apportioned according to the results of the 	//
//								ICO conducted on ico.info earlier. Results of the ICO	// 
//								can be viewed at https://ico.info/projects/19 and are 	//
//								summarized below:										//
//								BTC raised: 386.808										//
//								ETH raised: 24451.896									//
//								EOS raised: 1468860										//
//								In accordance with Clipper Coin Venture&#39;s plan (also	//
//								viewable on the same website), the appropriate 			//
//								proportion of coins will be delivered to ICOInfo, a 	//
//								certain proportion will be deleted, and the rest held 	//
//								in reserve for uses that will be determined by later	//
//								smart contracts. 										//
//																						//
//////////////////////////////////////////////////////////////////////////////////////////
pragma solidity ^0.4.11;

contract ERC20Protocol {
/* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint supply);
    is replaced with:
    uint public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

/// @dev `Owned` is a base level contract that assigns an `owner` that can be
///  later changed
contract Owned {

    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

    /// @notice The Constructor assigns the message sender to be `owner`
    function Owned() {
        owner = msg.sender;
    }

    address public newOwner;

    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner. 0x0 can be used to create
    ///  an unowned neutral vault, however that cannot be undone
    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }


    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract StandardToken is ERC20Protocol {
    using SafeMath for uint;

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        assert((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
}

contract tokenRecipient { 
	function receiveApproval(
		address _from, 
		uint256 _value, 
		address _token, 
		bytes _extraData); 
}

contract ClipperCoin is Owned{
    using SafeMath for uint;

    /// Constant token specific fields
    string public name = "Clipper Coin";
    string public symbol = "CCCT";
    uint public decimals = 18;

    /// Total supply of Clipper Coin
    uint public totalSupply = 200000000 ether;
    
    /// Create an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    /// Generate public event on the blockchain that will notify clients of transfers
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /// Generate public event on the blockchain that notifies clients how much CCC has 
    /// been destroyed
    event Burn(address indexed from, uint256 value);
    
    /// Initialize contract with initial supply of tokens sent to the creator of the 
    /// contract, who is defined as the minter of the coin
    function ClipperCoin(
    	uint256 initialSupply,
    	uint8 tokenDecimals,
    	string tokenName,
    	string tokenSymbol
    	) {
    	    
    	//Give creator all initial tokens
    	balanceOf[msg.sender]  = initialSupply;
    	
    	// Set the total supply of all Clipper Coins
    	totalSupply  = initialSupply;
    	
    	// Set the name of Clipper Coins
    	name = tokenName;
    	
    	// Set the symbol of Clipper Coins: CCC
    	symbol = tokenSymbol;
    	
    	// Set the amount of decimal places present in Clipper Coin: 18
    	// Note: 18 is the ethereum standard
    	decimals = tokenDecimals;
    }
    
    
    /// Internal transfers, which can only be called by this contract.
    function _transfer(
    	address _from,
    	address _to,
    	uint _value)
    	internal {
    	    
    	// Prevent transfers to the 0x0 address. Use burn() instead to 
    	// permanently remove Clipper Coins from the Blockchain
    	require (_to != 0x0);
    	
    	// Check that the account has enough Clipper Coins to be transferred
        require (balanceOf[_from] > _value);                
        
        // Check that the subraction of coins is not occuring
        require (balanceOf[_to] + _value > balanceOf[_to]); 
        balanceOf[_from] -= _value;                         
        balanceOf[_to] += _value;                           
        Transfer(_from, _to, _value);
    }
    
    /// @notice Send `_value` tokens to `_to` from your account
    /// @param _to The address of the recipient
    /// @param _value the amount to send
    function transfer(
    	address _to, 
    	uint256 _value) {
        _transfer(msg.sender, _to, _value);
    }

    /// @notice Send `_value` tokens to `_to` on behalf of `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value the amount to send
    function transferFrom(
    	address _from, 
    	address _to, 
    	uint256 _value) returns (bool success) {
        require (_value < allowance[_from][msg.sender]);     
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /// @notice Allows `_spender` to spend no more than `_value` tokens on your behalf
    /// @param _spender The address authorized to spend
    /// @param _value the max amount they can spend
    function approve(
    	address _spender, 
    	uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /// @notice Allows `_spender` to spend no more than `_value` tokens on your behalf, 
    ///			and then ping the contract about it
    /// @param _spender The address authorized to spend
    /// @param _value the max amount they can spend
    /// @param _extraData some extra information to send to the approved contract
    function approveAndCall(
    	address _spender, 
    	uint256 _value, 
    	bytes _extraData) returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }        

    /// @notice Remove `_value` tokens from the system irreversibly
    /// @param _value the amount of money to burn
    function burn(uint256 _value) returns (bool success) {
        require (balanceOf[msg.sender] > _value);            
        balanceOf[msg.sender] -= _value;                      
        totalSupply -= _value;                                
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(
    	address _from, 
    	uint256 _value) returns (bool success) {
        require(balanceOf[_from] >= _value);                
        require(_value <= allowance[_from][msg.sender]);    
        balanceOf[_from] -= _value;                         
        allowance[_from][msg.sender] -= _value;             
        totalSupply -= _value;                              
        Burn(_from, _value);
        return true;
    }
}