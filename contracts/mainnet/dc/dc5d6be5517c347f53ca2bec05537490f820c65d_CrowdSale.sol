pragma solidity ^0.4.19;

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


contract CrowdSale is Moderated {
    using SafeMath for uint256;
    
    // LEON ERC20 smart contract
    LEON public tokenContract;
    
    // crowdsale aims to sell at least 10 000 000 LEONS
    uint256 public constant crowdsaleTarget = 10000000 * 10**18;
    // running total of LEONS sold
    uint256 public tokensSold;
    // running total of ether raised
    uint256 public weiRaised;

    // 1 Ether buys 13 000 LEONS
    uint256 public constant etherToLEONRate = 13000;
    // address to receive ether 
    address public constant etherVault = 0xD8d97E3B5dB13891e082F00ED3fe9A0BC6B7eA01;    
    // address to store bounty allocation
    address public constant bountyVault = 0x96B083a253A90e321fb9F53645483745630be952;
    // vesting contract to store team allocation
    VestingVault public vestingContract;
    // minimum of 1 ether to participate in crowdsale
    uint256 constant purchaseMinimum = 1 ether;
    // maximum of 65 ether 
    uint256 constant purchaseMaximum = 65 ether;
    
    // boolean to indicate crowdsale finalized state    
    bool public isFinalized;
    // boolean to indicate crowdsale is actively accepting ether
    bool public active;
    
    // mapping of whitelisted participants
    mapping (address => bool) internal whitelist;   
    
    // finalization event
    event Finalized(uint256 sales, uint256 raised);
    // purchase event
    event Purchased(address indexed purchaser, uint256 tokens, uint256 totsales, uint256 ethraised);
    // whitelisting event
    event Whitelisted(address indexed participant);
    // revocation of whitelisting event
    event Revoked(address indexed participant);
    
    // limits purchase to whitelisted participants only
    modifier onlyWhitelist {
        require(whitelist[msg.sender]);
        _;
    }
    // purchase while crowdsale is live only   
    modifier whileActive {
        require(active);
        _;
    }
    
    // constructor
    // @param _tokenAddr, the address of the deployed LEON token
    function CrowdSale(address _tokenAddr) public {
        tokenContract = LEON(_tokenAddr);
    }   

    // fallback function invokes buyTokens method
    function() external payable {
        buyTokens(msg.sender);
    }
    
    // forwards ether received to refund vault and generates tokens for purchaser
    function buyTokens(address _purchaser) public payable ifUnrestricted onlyWhitelist whileActive {
        // purchase value must be between 10 Ether and 65 Ether
        require(msg.value > purchaseMinimum && msg.value < purchaseMaximum);
        // transfer ether to the ether vault
        etherVault.transfer(msg.value);
        // increment wei raised total
        weiRaised = weiRaised.add(msg.value);
        // 1 ETHER buys 13 000 LEONS
        uint256 _tokens = (msg.value).mul(etherToLEONRate); 
        // mint tokens into purchaser address
        require(tokenContract.generateTokens(_purchaser, _tokens));
        // increment token sales total
        tokensSold = tokensSold.add(_tokens);
        // emit purchase event
        Purchased(_purchaser, _tokens, tokensSold, weiRaised);
    }
    
    function initialize() external onlyModerator {
        // cannot have been finalized nor previously activated
        require(!isFinalized && !active);
        // check that this contract address is the moderator of the token contract
        require(tokenContract.getModerator() == address(this));
        // restrict trading
        tokenContract.restrict();
        // set crowd sale to active state
        active = true;
    }
    
    // close sale and allocate bounty and team tokens
    function finalize() external onlyModerator {
        // cannot have been finalized and must be in active state
        require(!isFinalized && active);
        // calculate team allocation (45% of total supply)
        uint256 teamAllocation = tokensSold.mul(9000).div(10000);
        // calculate bounty allocation (5% of total supply)
        uint256 bountyAllocation = tokensSold.sub(teamAllocation);
        // spawn new vesting contract, time of release in six months from present date
        vestingContract = new VestingVault(address(tokenContract), etherVault, (block.timestamp + 26 weeks));
        // generate team allocation
        require(tokenContract.generateTokens(address(vestingContract), teamAllocation));
        // generate bounty tokens
        require(tokenContract.generateTokens(bountyVault, bountyAllocation));
        // emit finalized event
        Finalized(tokensSold, weiRaised);
        // set state to finalized
        isFinalized = true;
        // deactivate crowdsale
        active = false;
    }
    
    // reassign LEON token to the subsequent ICO smart contract
    function migrate(address _moderator) external onlyModerator {
        // only after finalization
        require(isFinalized);
        // can only reassign moderator privelege to another contract
        require(isContract(_moderator));
        // reassign moderator role
        tokenContract.reassignModerator(_moderator);    
    }
    
    // add address to whitelist
    function verifyParticipant(address participant) external onlyModerator {
        // whitelist the address
        whitelist[participant] = true;
        // emit whitelisted event
        Whitelisted(participant);
    }
    
    // remove address from whitelist
    function revokeParticipation(address participant) external onlyModerator {
        // remove address from whitelist
        whitelist[participant] = false;
        // emit revoked event
        Revoked(participant);
    }
    
    // check if an address is whitelisted
    function checkParticipantStatus(address participant) external view returns (bool whitelisted) {
        return whitelist[participant];
    }
}   

// Vesting contract to lock team allocation
contract VestingVault {

    // reference to LEON smart contract
    LEON public tokenContract; 
    // address to which the tokens are released
    address public beneficiary;
    // time upon which tokens may be released
    uint256 public releaseDate;
    
    // constructor takes LEON token address, etherVault address and current time + 6 months as parameters
    function VestingVault(address _token, address _beneficiary, uint256 _time) public {
        tokenContract = LEON(_token);
        beneficiary = _beneficiary;
        releaseDate = _time;
    }
    
    // check token balance in this contract
    function checkBalance() constant public returns (uint256 tokenBalance) {
        return tokenContract.balanceOf(this);
    }

    // function to release tokens to beneficiary address
    function claim() external {
        // can only be invoked by beneficiary
        require(msg.sender == beneficiary);
        // can only be invoked at maturity of vesting period
        require(block.timestamp > releaseDate);
        // compute current balance
        uint256 balance = tokenContract.balanceOf(this);
        // transfer tokens to beneficary
        tokenContract.transfer(beneficiary, balance);
    }
    
    // change the beneficary address
    function changeBeneficiary(address _newBeneficiary) external {
        // can only be changed by current beneficary
        require(msg.sender == beneficiary);
        // assign to new beneficiary
        beneficiary = _newBeneficiary;
    }
    
    /// This method can be used to extract tokens mistakenly sent to this contract.
    /// @param _token The address of the token contract that you want to recover
    function extract(address _token) public returns (bool) {
        require(_token != address(0x0) || _token != address(tokenContract));
        Token token = Token(_token);
        uint256 balance = token.balanceOf(this);
        return token.transfer(beneficiary, balance);
    }   
    
    function() external payable {
        revert();
    }
}