pragma solidity ^0.4.19;



/**
 * @title Moderated
 * @dev restricts execution of &#39;onlyModerator&#39; modified functions to the contract moderator
 * @dev restricts execution of &#39;ifUnrestricted&#39; modified functions to when unrestricted 
 *      boolean state is true
 * @dev allows for the extraction of ether or other ERC20 tokens mistakenly sent to this address
 */
contract Moderated {
    
    address public moderator;
    
    bool public unrestricted;
    
    modifier onlyModerator {
        require(msg.sender == moderator);
        _;
    }
    
    modifier ifUnrestricted {
        require(unrestricted);
        _;
    }
    
    modifier onlyPayloadSize(uint256 numWords) {
        assert(msg.data.length >= numWords * 32 + 4);
        _;
    }    
    
    function Moderated() public {
        moderator = msg.sender;
        unrestricted = true;
    }
    
    function reassignModerator(address newModerator) public onlyModerator {
        moderator = newModerator;
    }
    
    function restrict() public onlyModerator {
        unrestricted = false;
    }
    
    function unrestrict() public onlyModerator {
        unrestricted = true;
    }  
    
    /// This method can be used to extract tokens mistakenly sent to this contract.
    /// @param _token The address of the token contract that you want to recover
    function extract(address _token) public returns (bool) {
        require(_token != address(0x0));
        Token token = Token(_token);
        uint256 balance = token.balanceOf(this);
        return token.transfer(moderator, balance);
    }
    
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_addr) }
        return (size > 0);
    }  
    
    function getModerator() public view returns (address) {
        return moderator;
    }
} 

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract Token { 

    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);    
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);    
    event Transfer(address indexed from, address indexed to, uint256 value);    
    event Approval(address indexed owner, address indexed spender, uint256 value);    

}



/**
 * @title SafeMath
 * @dev Math operations that are safe for uint256 against overflow and negative values
 * @dev https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
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

// @dev Assign moderation of contract to CrowdSale

contract LEON is Moderated {	
	using SafeMath for uint256;

		string public name = "LEONS Coin";	
		string public symbol = "LEONS";			
		uint8 public decimals = 18;
		
		mapping(address => uint256) internal balances;
		mapping (address => mapping (address => uint256)) internal allowed;

		uint256 internal totalSupply_;

		// the maximum number of LEONS there may exist is capped at 200 million tokens
		uint256 public constant maximumTokenIssue = 200000000 * 10**18;
		
		event Approval(address indexed owner, address indexed spender, uint256 value); 
		event Transfer(address indexed from, address indexed to, uint256 value);		

		/**
		* @dev total number of tokens in existence
		*/
		function totalSupply() public view returns (uint256) {
			return totalSupply_;
		}

		/**
		* @dev transfer token for a specified address
		* @param _to The address to transfer to.
		* @param _value The amount to be transferred.
		*/
		function transfer(address _to, uint256 _value) public ifUnrestricted onlyPayloadSize(2) returns (bool) {
		    return _transfer(msg.sender, _to, _value);
		}

		/**
		* @dev Transfer tokens from one address to another
		* @param _from address The address which you want to send tokens from
		* @param _to address The address which you want to transfer to
		* @param _value uint256 the amount of tokens to be transferred
		*/
		function transferFrom(address _from, address _to, uint256 _value) public ifUnrestricted onlyPayloadSize(3) returns (bool) {
		    require(_value <= allowed[_from][msg.sender]);
		    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		    return _transfer(_from, _to, _value);
		}		

		function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
			// Do not allow transfers to 0x0 or to this contract
			require(_to != address(0x0) && _to != address(this));
			// Do not allow transfer of value greater than sender&#39;s current balance
			require(_value <= balances[_from]);
			// Update balance of sending address
			balances[_from] = balances[_from].sub(_value);	
			// Update balance of receiving address
			balances[_to] = balances[_to].add(_value);		
			// An event to make the transfer easy to find on the blockchain
			Transfer(_from, _to, _value);
			return true;
		}

		/**
		* @dev Gets the balance of the specified address.
		* @param _owner The address to query the the balance of.
		* @return An uint256 representing the amount owned by the passed address.
		*/
		function balanceOf(address _owner) public view returns (uint256) {
			return balances[_owner];
		}

		/**
		* @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
		*
		* Beware that changing an allowance with this method brings the risk that someone may use both the old
		* and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
		* race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
		* https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
		* @param _spender The address which will spend the funds.
		* @param _value The amount of tokens to be spent.
		*/
		function approve(address _spender, uint256 _value) public ifUnrestricted onlyPayloadSize(2) returns (bool sucess) {
			// Can only approve when value has not already been set or is zero
			require(allowed[msg.sender][_spender] == 0 || _value == 0);
			allowed[msg.sender][_spender] = _value;
			Approval(msg.sender, _spender, _value);
			return true;
		}

		/**
		* @dev Function to check the amount of tokens that an owner allowed to a spender.
		* @param _owner address The address which owns the funds.
		* @param _spender address The address which will spend the funds.
		* @return A uint256 specifying the amount of tokens still available for the spender.
		*/
		function allowance(address _owner, address _spender) public view returns (uint256) {
			return allowed[_owner][_spender];
		}

		/**
		* @dev Increase the amount of tokens that an owner allowed to a spender.
		*
		* approve should be called when allowed[_spender] == 0. To increment
		* allowed value is better to use this function to avoid 2 calls (and wait until
		* the first transaction is mined)
		* From MonolithDAO Token.sol
		* @param _spender The address which will spend the funds.
		* @param _addedValue The amount of tokens to increase the allowance by.
		*/
		function increaseApproval(address _spender, uint256 _addedValue) public ifUnrestricted onlyPayloadSize(2) returns (bool) {
			require(_addedValue > 0);
			allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
			Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
			return true;
		}

		/**
		* @dev Decrease the amount of tokens that an owner allowed to a spender.
		*
		* approve should be called when allowed[_spender] == 0. To decrement
		* allowed value is better to use this function to avoid 2 calls (and wait until
		* the first transaction is mined)
		* From MonolithDAO Token.sol
		* @param _spender The address which will spend the funds.
		* @param _subtractedValue The amount of tokens to decrease the allowance by.
		*/
		function decreaseApproval(address _spender, uint256 _subtractedValue) public ifUnrestricted onlyPayloadSize(2) returns (bool) {
			uint256 oldValue = allowed[msg.sender][_spender];
			require(_subtractedValue > 0);
			if (_subtractedValue > oldValue) {
				allowed[msg.sender][_spender] = 0;
			} else {
				allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
			}
			Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
			return true;
		}

		/**
		* @dev Function to mint tokens
		* @param _to The address that will receive the minted tokens.
		* @param _amount The amount of tokens to mint.
		* @return A boolean that indicates if the operation was successful.
		*/
		function generateTokens(address _to, uint _amount) public onlyModerator returns (bool) {
		    require(isContract(moderator));
			require(totalSupply_.add(_amount) <= maximumTokenIssue);
			totalSupply_ = totalSupply_.add(_amount);
			balances[_to] = balances[_to].add(_amount);
			Transfer(address(0x0), _to, _amount);
			return true;
		}
		/**
		* @dev fallback function - reverts transaction
		*/		
    	function () external payable {
    	    revert();
    	}		
}