pragma solidity ^0.4.11;

interface IERC20 {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
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


contract Kcoin is IERC20{

    using SafeMath for uint256;

    uint public initialSupply = 150000000000e18; // crowdsale

    string public constant symbol = "24K";
    string public constant name = "24Kcoin";
    uint8 public constant decimals = 18;
    uint public totalSupply = 1500000000000e18;

    uint256 public constant Rate1 = 5000; //month March rate 1 Eth
    uint256 public constant Rate2 = 5000; //month April rate 1 Eth
    uint256 public constant Rate3 = 4500; //month May rate 1 Eth
    uint256 public constant Rate4 = 4000; //month June rate 1 Eth
    uint256 public constant Rate5 = 3500; //month July rate 1 Eth
    uint256 public constant Rate6 = 3000; //month August rate 1 Eth
	uint256 public constant Rate7 = 2500; //month September rate 1 Eth
	uint256 public constant Rate8 = 2000; //month October rate 1 Eth
	uint256 public constant Rate9 = 1500; //month November rate 1 Eth
	uint256 public constant Rate10= 1000; //month December rate 1 Eth


    uint256 public constant Start1 = 1519862400; //start 03/01/18 12:00 AM UTC time to Unix time stamp
    uint256 public constant Start2 = 1522540800; //start 04/01/18 12:00 AM UTC time to Unix time stamp
    uint256 public constant Start3 = 1525132800; //start 05/01/18 12:00 AM UTC time to Unix time stamp
    uint256 public constant Start4 = 1527811200; //start 06/01/18 12:00 AM UTC time to Unix time stamp
    uint256 public constant Start5 = 1530403200; //start 07/01/18 12:00 AM UTC time to Unix time stamp
    uint256 public constant Start6 = 1533081600; //start 08/01/18 12:00 AM UTC time to Unix time stamp
	uint256 public constant Start7 = 1535760000; //start 09/01/18 12:00 AM UTC time to Unix time stamp
	uint256 public constant Start8 = 1538352000; //start 10/01/18 12:00 AM UTC time to Unix time stamp
	uint256 public constant Start9 = 1541030400; //start 11/01/18 12:00 AM UTC time to Unix time stamp
	uint256 public constant Start10= 1543622400; //start 12/01/18 12:00 AM UTC time to Unix time stamp

	
    uint256 public constant End1 = 1522540799; //End 03/31/18 11:59 PM UTC time to Unix time stamp
    uint256 public constant End2 = 1525132799; //End 04/30/18 11:59 PM UTC time to Unix time stamp
    uint256 public constant End3 = 1527811199; //End 05/31/18 11:59 PM UTC time to Unix time stamp
    uint256 public constant End4 = 1530403199; //End 06/30/18 11:59 PM UTC time to Unix time stamp
    uint256 public constant End5 = 1533081599; //End 07/31/18 11:59 PM UTC time to Unix time stamp
    uint256 public constant End6 = 1535759999; //End 08/31/18 11:59 PM UTC time to Unix time stamp
	
	uint256 public constant End7 = 1538351940; //End 09/30/18 11:59 PM UTC time to Unix time stamp
	uint256 public constant End8 = 1540943940; //End 10/30/18 11:59 PM UTC time to Unix time stamp
	uint256 public constant End9 = 1543622340; //End 11/30/18 11:59 PM UTC time to Unix time stamp
	uint256 public constant End10= 1546300740; //End 12/31/18 11:59 PM UTC time to Unix time stamp
	
	
    address public owner;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Burn(address indexed from, uint256 value);

    function() public payable {
        buyTokens();
    }

    function Kcoin() public {
        //TODO
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }
    function buyTokens() public payable {

        require(msg.value > 0);

        uint256 weiAmount = msg.value;
        uint256 tokens1 = weiAmount.mul(Rate1); //make sure to check which rate tier we are in
        uint256 tokens2 = weiAmount.mul(Rate2);
        uint256 tokens3 = weiAmount.mul(Rate3);
        uint256 tokens4 = weiAmount.mul(Rate4);
        uint256 tokens5 = weiAmount.mul(Rate5);
        uint256 tokens6 = weiAmount.mul(Rate6);
		uint256 tokens7 = weiAmount.mul(Rate7);
		uint256 tokens8 = weiAmount.mul(Rate8);
		uint256 tokens9 = weiAmount.mul(Rate9);
		uint256 tokens10= weiAmount.mul(Rate10);

        //send tokens from ICO contract address
        if (now >= Start1 && now <= End1) //we can send tokens at rate 1
        {
            balances[msg.sender] = balances[msg.sender].add(tokens1);
            initialSupply = initialSupply.sub(tokens1);
            //transfer(msg.sender, tokens1);
        }
        if (now >= Start2 && now <= End2) //we can send tokens at rate 2
        {
            balances[msg.sender] = balances[msg.sender].add(tokens2);
            initialSupply = initialSupply.sub(tokens2);
        }
        if (now >= Start3 && now <= End3) //we can send tokens at rate 3
        {
            balances[msg.sender] = balances[msg.sender].add(tokens3);
            initialSupply = initialSupply.sub(tokens3);
        }
        if (now >= Start4 && now <= End4) //we can send tokens at rate 4
        {
            balances[msg.sender] = balances[msg.sender].add(tokens4);
            initialSupply = initialSupply.sub(tokens4);
        }
        if (now >= Start5 && now <= End5) //we can send tokens at rate 5
        {
            balances[msg.sender] = balances[msg.sender].add(tokens5);
            initialSupply = initialSupply.sub(tokens5);
        }
        if (now >= Start6 && now <= End6) //we can send tokens at rate 6
        {
            balances[msg.sender] = balances[msg.sender].add(tokens6);
            initialSupply = initialSupply.sub(tokens6);
        }
		        if (now >= Start7 && now <= End7) //we can send tokens at rate 7
        {
            balances[msg.sender] = balances[msg.sender].add(tokens7);
            initialSupply = initialSupply.sub(tokens7);
        }
		        if (now >= Start8 && now <= End8) //we can send tokens at rate 8
        {
            balances[msg.sender] = balances[msg.sender].add(tokens8);
            initialSupply = initialSupply.sub(tokens8);
        }
		        if (now >= Start9 && now <= End9) //we can send tokens at rate 9
        {
            balances[msg.sender] = balances[msg.sender].add(tokens9);
            initialSupply = initialSupply.sub(tokens9);
        }
		        if (now >= Start10 && now <= End10) //we can send tokens at rate 10
        {
            balances[msg.sender] = balances[msg.sender].add(tokens10);
            initialSupply = initialSupply.sub(tokens10);
        }
		

        owner.transfer(msg.value);
    }

   function totalSupply() public constant returns (uint256 ) {
        //TODO
        return totalSupply;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        //TODO
        return balances[_owner];
    }

     function transfer(address _to, uint256 _value) public returns (bool success) {
        //TODO
        require(
            balances[msg.sender] >= _value
            && _value > 0
        );
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] += balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //TODO
        require(
            allowed[_from][msg.sender] >= _value
            && balances[_from] >= _value
            && _value > 0
        );
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

   function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

	 function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }

  function approve(address _spender, uint256 _value) public returns (bool success){
        //TODO
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     function allowance(address _owner, address _spender) public constant returns (uint256 remaining){
        //TODO
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}