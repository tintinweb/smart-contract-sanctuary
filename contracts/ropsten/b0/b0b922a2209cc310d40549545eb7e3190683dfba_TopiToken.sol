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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

contract Token {
    uint256 public totalSupply;

   
    function balanceOf(address _owner) constant returns (uint256 balance);

    
    function transfer(address _to, uint256 _value) returns (bool success);

   
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

   
    function approve(address _spender, uint256 _value) returns (bool success);

   
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);

   
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Issuance(address indexed _to, uint256 _value);
    event Burn(address indexed _from, uint256 _value);
}




contract StandardToken is Token {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) returns (bool success) {
        
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
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



contract TopiToken is StandardToken {
    using SafeMath for uint256;

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
        if (msg.sender != minter && msg.sender != exchanger) {
            revert();
        }
        _;
    }

    function transfer(address _to, uint256 _value) returns (bool success) {

        if (exchanger != 0x0 && _to == exchanger) {
            assert(ExchangeContract(exchanger).exchange(msg.sender, _value));
            return true;
        }

        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {

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

        if (totalSupply.sub(tokenCount) > totalSupply) {
            revert();
        }

        if (balances[_for].sub(tokenCount) > balances[_for]) {
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

    function TopiToken() {
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

		TopiToken prevToken = TopiToken(prevTokenAddress);
     	TopiToken nextToken = TopiToken(nextTokenAddress);

		if (prevToken.balanceOf(_for) >= prevTokensAmount) {
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



contract TopiTokenMinter {
    using SafeMath for uint256;

    TopiToken public token; // Token contract

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

    modifier onlyFounder() {
        // Only founder is allowed to do this action.
        if (msg.sender != founder) {
            revert();
        }
        _;
    }

    modifier onlyHelper() {
        if (msg.sender != helper) {
            revert();
        }
        _;
    }

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
        token = TopiToken(newAddress);
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

        if (getBlockTimestamp() >= endTime) {
            currentTimeDiff = endTime.sub(startTime).add(1);
            currentDay = 5 * 365;
        }

        uint maxCurrentHarvest = currentDay.mul(unfrozePerDay);
        uint wasNotHarvested = maxCurrentHarvest.sub(alreadyHarvestedTokens);

        require(wasNotHarvested > 0);
        require(token.issueTokens(teamPoolForFrozenTokens, wasNotHarvested));
        alreadyHarvestedTokens = alreadyHarvestedTokens.add(wasNotHarvested);

        return wasNotHarvested;
    }

    function () payable {
        require(false);
    }

    function getBlockTimestamp() returns (uint256) {
        return block.timestamp;
    }
}