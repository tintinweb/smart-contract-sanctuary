/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

pragma solidity 0.4.24;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Token {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
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

      mapping (address => mapping (address => uint256)) internal allowed;


    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner,address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _addedValue The amount of tokens to increase the allowance by.
    */
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
          allowed[msg.sender][_spender] = 0;
        } else {
          allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract ICOToken is Token {
	string public name = 'ICOToken';
	string public symbol = 'ITK';
	uint256 public decimals = 18;
	address public crowdsaleAddress;
	address public owner;
	uint256 public ICOEndTime;

	modifier onlyCrowdsale {
		require(msg.sender == crowdsaleAddress);
		_;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	modifier afterCrowdsale {
		require(now > ICOEndTime || msg.sender == crowdsaleAddress);
		_;
	}

	constructor (uint256 _ICOEndTime) public Token() {
		require(_ICOEndTime > 0);
	        totalSupply_ = 100e24;
		owner = msg.sender;
		ICOEndTime = _ICOEndTime;
	}

	function setCrowdsale(address _crowdsaleAddress) public onlyOwner {
		require(_crowdsaleAddress != address(0));
		crowdsaleAddress = _crowdsaleAddress;
	}

	function buyTokens(address _receiver, uint256 _amount) public onlyCrowdsale {
		require(_receiver != address(0));
		require(_amount > 0);
		transfer(_receiver, _amount);
	}

    /// @notice Override the functions to not allow token transfers until the end of the ICO
    function transfer(address _to, uint256 _value) public afterCrowdsale returns(bool) {
        return super.transfer(_to, _value);
    }

    /// @notice Override the functions to not allow token transfers until the end of the ICO
    function transferFrom(address _from, address _to, uint256 _value) public afterCrowdsale returns(bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /// @notice Override the functions to not allow token transfers until the end of the ICO
    function approve(address _spender, uint256 _value) public afterCrowdsale returns(bool) {
        return super.approve(_spender, _value);
    }

    /// @notice Override the functions to not allow token transfers until the end of the ICO
    function increaseApproval(address _spender, uint _addedValue) public afterCrowdsale returns(bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    /// @notice Override the functions to not allow token transfers until the end of the ICO
    function decreaseApproval(address _spender, uint _subtractedValue) public afterCrowdsale returns(bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function emergencyExtract() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}

contract Crowdsale {
    using SafeMath for uint256;

    bool public icoCompleted;
    uint256 public icoStartTime;
    uint256 public icoEndTime;
    uint256 public tokenRate;
    ICOToken public token;
    uint256 public fundingGoal;
    address public owner;
    uint256 public tokensRaised;
    uint256 public etherRaised;
    uint256 public rateOne = 5000;
    uint256 public rateTwo = 4000;
    uint256 public rateThree = 3000;
    uint256 public rateFour = 2000;
    uint256 public limitTierOne = 25e6 * (10 ** token.decimals());
    uint256 public limitTierTwo = 50e6 * (10 ** token.decimals());
    uint256 public limitTierThree = 75e6 * (10 ** token.decimals());
    uint256 public limitTierFour = 100e6 * (10 ** token.decimals());

    modifier whenIcoCompleted {
        require(icoCompleted);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function () public payable {
        buy();
    }

    constructor(uint256 _icoStart, uint256 _icoEnd, uint256 _tokenRate, address _tokenAddress, uint256 _fundingGoal) public {
        require(_icoStart != 0 &&
            _icoEnd != 0 &&
            _icoStart < _icoEnd &&
            _tokenRate != 0 &&
            _tokenAddress != address(0) &&
            _fundingGoal != 0);

        icoStartTime = _icoStart;
        icoEndTime = _icoEnd;
        tokenRate = _tokenRate;
        token = ICOToken(_tokenAddress);
        fundingGoal = _fundingGoal;
        owner = msg.sender;
    }

    function calculateExcessTokens(
      uint256 amount,
      uint256 tokensThisTier,
      uint256 tierSelected,
      uint256 _rate
    ) public returns(uint256 totalTokens) {
        require(amount > 0 && tokensThisTier > 0 && _rate > 0);
        require(tierSelected >= 1 && tierSelected <= 4);

        uint weiThisTier = tokensThisTier.sub(tokensRaised).div(_rate);
        uint weiNextTier = amount.sub(weiThisTier);
        uint tokensNextTier = 0;
        bool returnTokens = false;

        // If there's excessive wei for the last tier, refund those
        if(tierSelected != 4)
            tokensNextTier = calculateTokensTier(weiNextTier, tierSelected.add(1));
        else
            returnTokens = true;

        totalTokens = tokensThisTier.sub(tokensRaised).add(tokensNextTier);

        // Do the transfer at the end
        if(returnTokens) msg.sender.transfer(weiNextTier);
   }

    function calculateTokensTier(uint256 weiPaid, uint256 tierSelected)
        internal constant returns(uint256 calculatedTokens)
    {
        require(weiPaid > 0);
        require(tierSelected >= 1 && tierSelected <= 4);

        if(tierSelected == 1)
            calculatedTokens = weiPaid.mul(rateOne);
        else if(tierSelected == 2)
            calculatedTokens = weiPaid.mul(rateTwo);
        else if(tierSelected == 3)
            calculatedTokens = weiPaid.mul(rateThree);
        else
            calculatedTokens = weiPaid.mul(rateFour);
   }

    function buy() public payable {
    	require(tokensRaised < fundingGoal);
    	require(now < icoEndTime && now > icoStartTime);

        uint256 tokensToBuy;
    	uint256 etherUsed = msg.value;

    	// If the tokens raised are less than 25 million with decimals, apply the first rate
    	if(tokensRaised < limitTierOne) {
    	    // Tier 1
    		tokensToBuy = etherUsed * (10 ** token.decimals()) / 1 ether * rateOne;

    		// If the amount of tokens that you want to buy gets out of this tier
    		if(tokensRaised + tokensToBuy > limitTierOne) {
    			tokensToBuy = calculateExcessTokens(etherUsed, limitTierOne, 1, rateOne);
    		}
    	} else if(tokensRaised >= limitTierOne && tokensRaised < limitTierTwo) {
    	    // Tier 2
            tokensToBuy = etherUsed * (10 ** token.decimals()) / 1 ether * rateTwo;

            // If the amount of tokens that you want to buy gets out of this tier
       		if(tokensRaised + tokensToBuy > limitTierTwo) {
    			tokensToBuy = calculateExcessTokens(etherUsed, limitTierTwo, 2, rateTwo);
    		}
        } else if(tokensRaised >= limitTierTwo && tokensRaised < limitTierThree) {
            // Tier 3
            tokensToBuy = etherUsed * (10 ** token.decimals()) / 1 ether * rateThree;

            // If the amount of tokens that you want to buy gets out of this tier
       		if(tokensRaised + tokensToBuy > limitTierThree) {
    			tokensToBuy = calculateExcessTokens(etherUsed, limitTierThree, 3, rateThree);
    		}
        } else if(tokensRaised >= limitTierThree) {
            // Tier 4
            tokensToBuy = etherUsed * (10 ** token.decimals()) / 1 ether * rateFour;
        }

    	// Check if we have reached and exceeded the funding goal to refund the exceeding tokens and ether
    	if(tokensRaised + tokensToBuy > fundingGoal) {
    		uint256 exceedingTokens = tokensRaised + tokensToBuy - fundingGoal;
    		uint256 exceedingEther;

    		// Convert the exceedingTokens to ether and refund that ether
    		exceedingEther = exceedingTokens * 1 ether / tokenRate / token.decimals();
    		msg.sender.transfer(exceedingEther);

    		// Change the tokens to buy to the new number
    		tokensToBuy -= exceedingTokens;

    		// Update the counter of ether used
    		etherUsed -= exceedingEther;
    	}

    	// Send the tokens to the buyer
    	token.buyTokens(msg.sender, tokensToBuy);

    	// Increase the tokens raised and ether raised state variables
    	tokensRaised += tokensToBuy;
    }

    function extractEther() public whenIcoCompleted onlyOwner {
        owner.transfer(address(this).balance);
    }
}