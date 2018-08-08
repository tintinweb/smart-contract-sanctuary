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

    modifier onlyPayloadSize(uint numWords) {
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

contract Touch is Moderated {
	using SafeMath for uint256;

		string public name = "Touch. Token";
		string public symbol = "TST";
		uint8 public decimals = 18;

        uint256 public maximumTokenIssue = 1000000000 * 10**18;

		mapping(address => uint256) internal balances;
		mapping (address => mapping (address => uint256)) internal allowed;

		uint256 internal totalSupply_;

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
		function generateTokens(address _to, uint _amount) internal returns (bool) {
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

    	function Touch () public {
    		generateTokens(msg.sender, maximumTokenIssue);
    	}

}

contract CrowdSale is Moderated {
	using SafeMath for uint256;

        address public recipient1 = 0x375D7f6bf5109E8e7d27d880EC4E7F362f77D275; // @TODO: replace this!
        address public recipient2 = 0x2D438367B806537a76B97F50B94086898aE5C518; // @TODO: replace this!
        address public recipient3 = 0xd198258038b2f96F8d81Bb04e1ccbfC2B3c46760; // @TODO: replace this!
        uint public percentageRecipient1 = 35;
        uint public percentageRecipient2 = 35;
        uint public percentageRecipient3 = 30;

	// Touch ERC20 smart contract
	Touch public tokenContract;

    uint256 public startDate;

    uint256 public endDate;

    // crowdsale aims to sell 100 Million TST
    uint256 public constant crowdsaleTarget = 22289 ether;
    // running total of tokens sold
    uint256 public etherRaised;

    // address to receive accumulated ether given a successful crowdsale
	address public etherVault;

    // minimum of 0.005 ether to participate in crowdsale
	uint256 constant purchaseThreshold = 5 finney;

    // boolean to indicate crowdsale finalized state
	bool public isFinalized = false;

	bool public active = false;

	// finalization event
	event Finalized();

	// purchase event
	event Purchased(address indexed purchaser, uint256 indexed tokens);

    // checks that crowd sale is live
    modifier onlyWhileActive {
        require(now >= startDate && now <= endDate && active);
        _;
    }

    function CrowdSale( address _tokenAddr,
                        uint256 start,
                        uint256 end) public {
        require(_tokenAddr != address(0x0));
        require(now < start && start < end);
        // the Touch token contract
        tokenContract = Touch(_tokenAddr);

        etherVault = msg.sender;

        startDate = start;
        endDate = end;
    }

	// fallback function invokes buyTokens method
	function () external payable {
	    buyTokens(msg.sender);
	}

	function buyTokens(address _purchaser) public payable ifUnrestricted onlyWhileActive returns (bool) {
	    require(!targetReached());
	    require(msg.value > purchaseThreshold);
	   // etherVault.transfer(msg.value);
	   splitPayment();

	    uint256 _tokens = calculate(msg.value);
        // approve CrowdSale to spend 100 000 000 tokens on behalf of moderator
        require(tokenContract.transferFrom(moderator,_purchaser,_tokens));
		//require(tokenContract.generateTokens(_purchaser, _tokens));
        Purchased(_purchaser, _tokens);
        return true;
	}

	function calculate(uint256 weiAmount) internal returns(uint256) {
	    uint256 excess;
	    uint256 numTokens;
	    uint256 excessTokens;
        if(etherRaised < 5572 ether) {
            etherRaised = etherRaised.add(weiAmount);
            if(etherRaised > 5572 ether) {
                excess = etherRaised.sub(5572 ether);
                numTokens = weiAmount.sub(excess).mul(5608);
                etherRaised = etherRaised.sub(excess);
                excessTokens = calculate(excess);
                return numTokens + excessTokens;
            } else {
                return weiAmount.mul(5608);
            }
        } else if(etherRaised < 11144 ether) {
            etherRaised = etherRaised.add(weiAmount);
            if(etherRaised > 11144 ether) {
                excess = etherRaised.sub(11144 ether);
                numTokens = weiAmount.sub(excess).mul(4807);
                etherRaised = etherRaised.sub(excess);
                excessTokens = calculate(excess);
                return numTokens + excessTokens;
            } else {
                return weiAmount.mul(4807);
            }
        } else if(etherRaised < 16716 ether) {
            etherRaised = etherRaised.add(weiAmount);
            if(etherRaised > 16716 ether) {
                excess = etherRaised.sub(16716 ether);
                numTokens = weiAmount.sub(excess).mul(4206);
                etherRaised = etherRaised.sub(excess);
                excessTokens = calculate(excess);
                return numTokens + excessTokens;
            } else {
                return weiAmount.mul(4206);
            }
        } else if(etherRaised < 22289 ether) {
            etherRaised = etherRaised.add(weiAmount);
            if(etherRaised > 22289 ether) {
                excess = etherRaised.sub(22289 ether);
                numTokens = weiAmount.sub(excess).mul(3738);
                etherRaised = etherRaised.sub(excess);
                excessTokens = calculate(excess);
                return numTokens + excessTokens;
            } else {
                return weiAmount.mul(3738);
            }
        } else {
            etherRaised = etherRaised.add(weiAmount);
            return weiAmount.mul(3738);
        }
	}


    function changeEtherVault(address newEtherVault) public onlyModerator {
        require(newEtherVault != address(0x0));
        etherVault = newEtherVault;

}


    function initialize() public onlyModerator {
        // assign Touch moderator to this contract address
        // assign moderator of this contract to crowdsale manager address
        require(tokenContract.allowance(moderator, address(this)) == 102306549000000000000000000);
        active = true;
        // send approve from moderator account allowing for 100 million tokens
        // spendable by this contract
    }

	// activates end of crowdsale state
    function finalize() public onlyModerator {
        // cannot have been invoked before
        require(!isFinalized);
        // can only be invoked after end date or if target has been reached
        require(hasEnded() || targetReached());

        active = false;

        // emit Finalized event
        Finalized();
        // set isFinalized boolean to true
        isFinalized = true;
    }

	// checks if end date of crowdsale is passed
    function hasEnded() internal view returns (bool) {
        return (now > endDate);
    }

    // checks if crowdsale target is reached
    function targetReached() internal view returns (bool) {
        return (etherRaised >= crowdsaleTarget);
    }
    function splitPayment() internal {
        recipient1.transfer(msg.value * percentageRecipient1 / 100);
        recipient2.transfer(msg.value * percentageRecipient2 / 100);
        recipient3.transfer(msg.value * percentageRecipient3 / 100);
    }

}