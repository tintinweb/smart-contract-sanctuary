pragma solidity ^0.4.11;



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

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function assert(bool assertion) internal {
        if (!assertion) {
            throw;
        }
    }

}



contract Token {

	/// total amount of tokens
    uint public totalSupply;

	/// return tokens balance
    function balanceOf(address _owner) constant returns (uint balance);

	/// tranfer successful or not
    function transfer(address _to, uint _value) returns (bool success);

	/// tranfer successful or not
    function transferFrom(address _from, address _to, uint _value) returns (bool success);

	/// approval successful or not
    function approve(address _spender, uint _value) returns (bool success);

	/// amount of remaining tokens
    function allowance(address _owner, address _spender) constant returns (uint remaining);

	/// events
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

}



contract StandardToken is Token {

    modifier onlyPayloadSize(uint size) {
        if(msg.data.length < size + 4) {
            throw;
        }
        _;
    }

    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
	  if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) returns (bool success) {
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



contract LudumToken is StandardToken {

    using SafeMath for uint;

	string public constant name = "Ludum"; // Ludum tokens name
    string public constant symbol = "LDM"; // Ludum tokens ticker
    uint public constant decimals = 18; // Ludum tokens decimals
	uint public constant maximumSupply =  100000000000000000000000000; // Maximum 100M Ludum tokens can be created

    address public ethDepositAddress;
    address public teamFundAddress;
	address public operationsFundAddress;
	address public marketingFundAddress;

    bool public isFinalized;
	uint public constant crowdsaleStart = 1503921600;
	uint public constant crowdsaleEnd = 1506340800;
	
	uint public constant teamPercent = 10;
	uint public constant operationsPercent = 10;
	uint public constant marketingPercent = 10;


    function ludumTokensPerEther() constant returns(uint) {

		if (now < crowdsaleStart || now > crowdsaleEnd) {
			return 0;
		} else {
			if (now < crowdsaleStart + 1 days) return 15000; // Ludum token sale with 50% bonus
			if (now < crowdsaleStart + 7 days) return 13000; // Ludum token sale with 30% bonus
			if (now < crowdsaleStart + 14 days) return 11000; // Ludum token sale with 10% bonus
			return 10000; // Ludum token sale
		}

    }


    // events
    event CreateLudumTokens(address indexed _to, uint _value);

    // Ludum token constructor
    function LudumToken()
    {
        isFinalized = false;
	    ethDepositAddress = "0xD8E4FB6cC1BD2a8eF6E086152877E7ba540B5d9b";
	    teamFundAddress = "0xB6FCB6EF9b46B4ea0AC403e74b53e3962f6fc41d";
	    operationsFundAddress = "0x81B9c43a410C86620fbd85509c29E8C93995A8A9";
	    marketingFundAddress = "0x057CCb6A9061Aa61aEAE047fdCddeCb6511A0865";
    }


    function makeTokens() payable  {
        if (isFinalized) throw;
        if (now < crowdsaleStart) throw;
        if (now > crowdsaleEnd) throw;
        if (msg.value < 10 finney) throw;

        uint tokens = msg.value.mul(ludumTokensPerEther());
	    uint teamTokens = tokens.mul(teamPercent).div(100);
	    uint operationsTokens = tokens.mul(operationsPercent).div(100);
	    uint marketingTokens = tokens.mul(marketingPercent).div(100);

	    uint currentSupply = totalSupply.add(tokens).add(teamTokens).add(operationsTokens).add(marketingTokens);

        if (maximumSupply < currentSupply) throw;

        totalSupply = currentSupply;

        balances[msg.sender] += tokens;
        CreateLudumTokens(msg.sender, tokens);
	  
	    balances[teamFundAddress] += teamTokens;
        CreateLudumTokens(teamFundAddress, teamTokens);
	  
	    balances[operationsFundAddress] += operationsTokens;
        CreateLudumTokens(operationsFundAddress, operationsTokens);
	  
	    balances[marketingFundAddress] += marketingTokens;
        CreateLudumTokens(marketingFundAddress, marketingTokens);
    }


    function() payable {
        makeTokens();
    }


    function finalizeCrowdsale() external {
        if (isFinalized) throw;
        if (msg.sender != ethDepositAddress) throw;

	    if(now <= crowdsaleEnd && totalSupply != maximumSupply) throw;

        isFinalized = true;
        if(!ethDepositAddress.send(this.balance)) throw;
    }

}