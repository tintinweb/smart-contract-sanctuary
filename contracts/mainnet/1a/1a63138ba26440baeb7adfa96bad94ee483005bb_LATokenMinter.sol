pragma solidity ^0.4.12;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b &gt; 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b &lt;= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c &gt;= a);
    return c;
  }
}

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens, after that function `receiveApproval`
    /// @notice will be called on `_spender` address
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @param _extraData Some data to pass in callback function
    /// @return Whether the approval was successful or not
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Issuance(address indexed _to, uint256 _value);
    event Burn(address indexed _from, uint256 _value);
}

/*
Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
.*/


contract StandardToken is Token {

    mapping (address =&gt; uint256) balances;
    mapping (address =&gt; mapping (address =&gt; uint256)) allowed;

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] &gt;= _value &amp;&amp; balances[_to] + _value &gt; balances[_to]) {
        if (balances[msg.sender] &gt;= _value &amp;&amp; _value &gt; 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] &gt;= _value &amp;&amp; allowed[_from][msg.sender] &gt;= _value &amp;&amp; balances[_to] + _value &gt; balances[_to]) {
        if (balances[_from] &gt;= _value &amp;&amp; allowed[_from][msg.sender] &gt;= _value &amp;&amp; _value &gt; 0) {
            balances[_from] -= _value;
            balances[_to] += _value;
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

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        string memory signature = &quot;receiveApproval(address,uint256,address,bytes)&quot;;

        if (!_spender.call(bytes4(bytes32(sha3(signature))), msg.sender, _value, this, _extraData)) {
            revert();
        }

        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}



contract LATToken is StandardToken {
    using SafeMath for uint256;
    /* Public variables of the token */

    address     public founder;
    address     public minter = 0;
    address     public exchanger = 0;

    string      public name             =       &quot;LAToken&quot;;
    uint8       public decimals         =       18;
    string      public symbol           =       &quot;LAToken&quot;;
    string      public version          =       &quot;0.7.2&quot;;


    modifier onlyFounder() {
        if (msg.sender != founder) {
            revert();
        }
        _;
    }

    modifier onlyMinterAndExchanger() {
        if (msg.sender != minter &amp;&amp; msg.sender != exchanger) {
            revert();
        }
        _;
    }

    function transfer(address _to, uint256 _value) returns (bool success) {

        if (exchanger != 0x0 &amp;&amp; _to == exchanger) {
            assert(ExchangeContract(exchanger).exchange(msg.sender, _value));
            return true;
        }

        if (balances[msg.sender] &gt;= _value &amp;&amp; balances[_to] + _value &gt; balances[_to]) {

            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);

            Transfer(msg.sender, _to, _value);
            return true;

        } else {
            return false;
        }
    }

    function issueTokens(address _for, uint tokenCount)
        external
        onlyMinterAndExchanger
        returns (bool)
    {
        if (tokenCount == 0) {
            return false;
        }

        totalSupply = totalSupply.add(tokenCount);
        balances[_for] = balances[_for].add(tokenCount);
        Issuance(_for, tokenCount);
        return true;
    }

    function burnTokens(address _for, uint tokenCount)
        external
        onlyMinterAndExchanger
        returns (bool)
    {
        if (tokenCount == 0) {
            return false;
        }

        if (totalSupply.sub(tokenCount) &gt; totalSupply) {
            revert();
        }

        if (balances[_for].sub(tokenCount) &gt; balances[_for]) {
            revert();
        }

        totalSupply = totalSupply.sub(tokenCount);
        balances[_for] = balances[_for].sub(tokenCount);
        Burn(_for, tokenCount);
        return true;
    }

    function changeMinter(address newAddress)
        public
        onlyFounder
        returns (bool)
    {
        minter = newAddress;
        return true;
    }

    function changeFounder(address newAddress)
        public
        onlyFounder
        returns (bool)
    {
        founder = newAddress;
        return true;
    }

    function changeExchanger(address newAddress)
        public
        onlyFounder
        returns (bool)
    {
        exchanger = newAddress;
        return true;
    }

    function () payable {
        require(false);
    }

    function LATToken() {
        founder = msg.sender;
        totalSupply = 0;
    }
}



contract ExchangeContract {
    using SafeMath for uint256;

	address public founder;
	uint256 public prevCourse;
	uint256 public nextCourse;

	address public prevTokenAddress;
	address public nextTokenAddress;

	modifier onlyFounder() {
        if (msg.sender != founder) {
            revert();
        }
        _;
    }

    modifier onlyPreviousToken() {
    	if (msg.sender != prevTokenAddress) {
            revert();
        }
        _;
    }

    // sets new conversion rate
	function changeCourse(uint256 _prevCourse, uint256 _nextCourse)
		public
		onlyFounder
	{
		prevCourse = _prevCourse;
		nextCourse = _nextCourse;
	}

	function exchange(address _for, uint256 prevTokensAmount)
		public
		onlyPreviousToken
		returns (bool)
	{

		LATToken prevToken = LATToken(prevTokenAddress);
     	LATToken nextToken = LATToken(nextTokenAddress);

		// check if balance is correct
		if (prevToken.balanceOf(_for) &gt;= prevTokensAmount) {
			uint256 amount = prevTokensAmount.div(prevCourse);

			assert(prevToken.burnTokens(_for, amount.mul(prevCourse))); // remove previous tokens
			assert(nextToken.issueTokens(_for, amount.mul(nextCourse))); // give new ones

			return true;
		} else {
			revert();
		}
	}

	function changeFounder(address newAddress)
        external
        onlyFounder
        returns (bool)
    {
        founder = newAddress;
        return true;
    }

	function ExchangeContract(address _prevTokenAddress, address _nextTokenAddress, uint256 _prevCourse, uint256 _nextCourse) {
		founder = msg.sender;

		prevTokenAddress = _prevTokenAddress;
		nextTokenAddress = _nextTokenAddress;

		changeCourse(_prevCourse, _nextCourse);
	}
}



contract LATokenMinter {
    using SafeMath for uint256;

    LATToken public token; // Token contract

    address public founder; // Address of founder
    address public helper;  // Address of helper

    address public teamPoolInstant; // Address of team pool for instant issuance after token sale end
    address public teamPoolForFrozenTokens; // Address of team pool for smooth unfroze during 5 years after 5 years from token sale start

    bool public teamInstantSent = false; // Flag to prevent multiple issuance for team pool after token sale

    uint public startTime;               // Unix timestamp of start
    uint public endTime;                 // Unix timestamp of end
    uint public numberOfDays;            // Number of windows after 0
    uint public unfrozePerDay;           // Tokens sold in each window
    uint public alreadyHarvestedTokens;  // Tokens were already harvested and sent to team pool

    /*
     *  Modifiers
     */
    modifier onlyFounder() {
        // Only founder is allowed to do this action.
        if (msg.sender != founder) {
            revert();
        }
        _;
    }

    modifier onlyHelper() {
        // Only helper is allowed to do this action.
        if (msg.sender != helper) {
            revert();
        }
        _;
    }

    // sends 400 millions of tokens to teamPool at the token sale ending (200m for distribution + 200m for company)
    function fundTeamInstant()
        external
        onlyFounder
        returns (bool)
    {
        require(!teamInstantSent);

        uint baseValue = 400000000;
        uint totalInstantAmount = baseValue.mul(1000000000000000000); // 400 millions with 18 decimal points

        require(token.issueTokens(teamPoolInstant, totalInstantAmount));

        teamInstantSent = true;
        return true;
    }

    function changeTokenAddress(address newAddress)
        external
        onlyFounder
        returns (bool)
    {
        token = LATToken(newAddress);
        return true;
    }

    function changeFounder(address newAddress)
        external
        onlyFounder
        returns (bool)
    {
        founder = newAddress;
        return true;
    }

    function changeHelper(address newAddress)
        external
        onlyFounder
        returns (bool)
    {
        helper = newAddress;
        return true;
    }

    function changeTeamPoolInstant(address newAddress)
        external
        onlyFounder
        returns (bool)
    {
        teamPoolInstant = newAddress;
        return true;
    }

    function changeTeamPoolForFrozenTokens(address newAddress)
        external
        onlyFounder
        returns (bool)
    {
        teamPoolForFrozenTokens = newAddress;
        return true;
    }

    // method which will be called each day after 5 years to get unfrozen tokens
    function harvest()
        external
        onlyHelper
        returns (uint)
    {
        require(teamPoolForFrozenTokens != 0x0);

        uint currentTimeDiff = getBlockTimestamp().sub(startTime);
        uint secondsPerDay = 24 * 3600;
        uint daysFromStart = currentTimeDiff.div(secondsPerDay);
        uint currentDay = daysFromStart.add(1);

        if (getBlockTimestamp() &gt;= endTime) {
            currentTimeDiff = endTime.sub(startTime).add(1);
            currentDay = 5 * 365;
        }

        uint maxCurrentHarvest = currentDay.mul(unfrozePerDay);
        uint wasNotHarvested = maxCurrentHarvest.sub(alreadyHarvestedTokens);

        require(wasNotHarvested &gt; 0);
        require(token.issueTokens(teamPoolForFrozenTokens, wasNotHarvested));
        alreadyHarvestedTokens = alreadyHarvestedTokens.add(wasNotHarvested);

        return wasNotHarvested;
    }

    function LATokenMinter(address _LATTokenAddress, address _helperAddress) {
        founder = msg.sender;
        helper = _helperAddress;
        token = LATToken(_LATTokenAddress);

        numberOfDays = 5 * 365; // 5 years
        startTime = 1661166000; // 22 august 2022 11:00 GMT+0;
        endTime = numberOfDays.mul(1 days).add(startTime);

        uint baseValue = 600000000;
        uint frozenTokens = baseValue.mul(1000000000000000000); // 600 millions with 18 decimal points
        alreadyHarvestedTokens = 0;

        unfrozePerDay = frozenTokens.div(numberOfDays);
    }

    function () payable {
        require(false);
    }

    function getBlockTimestamp() returns (uint256) {
        return block.timestamp;
    }
}