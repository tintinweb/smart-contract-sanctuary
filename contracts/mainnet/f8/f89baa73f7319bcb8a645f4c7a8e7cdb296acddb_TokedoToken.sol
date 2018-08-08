pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
	address public owner;
	address public newOwner;

	event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

	constructor() public {
		owner = msg.sender;
		newOwner = address(0);
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "msg.sender == owner");
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		require(address(0) != _newOwner, "address(0) != _newOwner");
		newOwner = _newOwner;
	}

	function acceptOwnership() public {
		require(msg.sender == newOwner, "msg.sender == newOwner");
		emit OwnershipTransferred(owner, msg.sender);
		owner = msg.sender;
		newOwner = address(0);
	}
}

contract Authorizable is Ownable {
    mapping(address => bool) public authorized;
  
    event AuthorizationSet(address indexed addressAuthorized, bool indexed authorization);

    constructor() public {
        authorized[msg.sender] = true;
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "authorized[msg.sender]");
        _;
    }

    function setAuthorized(address addressAuthorized, bool authorization) onlyOwner public {
        emit AuthorizationSet(addressAuthorized, authorization);
        authorized[addressAuthorized] = authorization;
    }
  
}

contract ERC20Basic {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    function transferFunction(address _sender, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0), "_to != address(0)");
        require(_to != address(this), "_to != address(this)");
        require(_value <= balances[_sender], "_value <= balances[_sender]");

        balances[_sender] = balances[_sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_sender, _to, _value);
        return true;
    }
  
    function transfer(address _to, uint256 _value) public returns (bool) {
	    return transferFunction(msg.sender, _to, _value);
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
}

contract ERC223TokenCompatible is BasicToken {
  using SafeMath for uint256;
  
  event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);

	function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public returns (bool success) {
		require(_to != address(0), "_to != address(0)");
        require(_to != address(this), "_to != address(this)");
		require(_value <= balances[msg.sender], "_value <= balances[msg.sender]");
		
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
		if( isContract(_to) ) {
			require( _to.call.value(0)( bytes4( keccak256( abi.encodePacked( _custom_fallback ) ) ), msg.sender, _value, _data), "_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data)" );

		} 
		emit Transfer(msg.sender, _to, _value, _data);
		return true;
	}

	function transfer(address _to, uint256 _value, bytes _data) public returns (bool success) {
		return transfer( _to, _value, _data, "tokenFallback(address,uint256,bytes)");
	}

	//assemble the given address bytecode. If bytecode exists then the _addr is a contract.
	function isContract(address _addr) private view returns (bool is_contract) {
		uint256 length;
		assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
		}
		return (length>0);
    }
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "_to != address(0)");
        require(_to != address(this), "_to != address(this)");
        require(_value <= balances[_from], "_value <= balances[_from]");
        require(_value <= allowed[_from][msg.sender], "_value <= allowed[_from][msg.sender]");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
    }

}

contract HumanStandardToken is StandardToken {
    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        approve(_spender, _value);
        require(_spender.call(bytes4(keccak256("receiveApproval(address,uint256,bytes)")), msg.sender, _value, _extraData), &#39;_spender.call(bytes4(keccak256("receiveApproval(address,uint256,bytes)")), msg.sender, _value, _extraData)&#39;);
        return true;
    }
    function approveAndCustomCall(address _spender, uint256 _value, bytes _extraData, bytes4 _customFunction) public returns (bool success) {
        approve(_spender, _value);
        require(_spender.call(_customFunction, msg.sender, _value, _extraData), "_spender.call(_customFunction, msg.sender, _value, _extraData)");
        return true;
    }
}

contract Startable is Ownable, Authorizable {
    event Start();

    bool public started = false;

    modifier whenStarted() {
	    require( started || authorized[msg.sender], "started || authorized[msg.sender]" );
        _;
    }

    function start() onlyOwner public {
        started = true;
        emit Start();
    }
}

contract StartToken is Startable, ERC223TokenCompatible, StandardToken {

    function transfer(address _to, uint256 _value) public whenStarted returns (bool) {
        return super.transfer(_to, _value);
    }
    function transfer(address _to, uint256 _value, bytes _data) public whenStarted returns (bool) {
        return super.transfer(_to, _value, _data);
    }
    function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public whenStarted returns (bool) {
        return super.transfer(_to, _value, _data, _custom_fallback);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenStarted returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenStarted returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenStarted returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenStarted returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}


contract BurnToken is StandardToken {
    uint256 public initialSupply;

    event Burn(address indexed burner, uint256 value);

    function burnFunction(address _burner, uint256 _value) internal returns (bool) {
        require(_value > 0, "_value > 0");
		require(_value <= balances[_burner], "_value <= balances[_burner]");

        balances[_burner] = balances[_burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_burner, _value);
		return true;
    }
    
	function burn(uint256 _value) public returns(bool) {
        return burnFunction(msg.sender, _value);
    }
	
	function burnFrom(address _from, uint256 _value) public returns (bool) {
		require(_value <= allowed[_from][msg.sender], "_value <= allowed[_from][msg.sender]"); // check if it has the budget allowed
		burnFunction(_from, _value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		return true;
	}
}

contract TokedoToken is ERC20Basic, ERC223TokenCompatible, StandardToken, HumanStandardToken, StartToken, BurnToken  {
    constructor() public {
        name = "Tokedo";
        symbol = "TKD";
        decimals = 18;
        totalSupply = 78750709292959827150083646;
        balances[msg.sender] = totalSupply;
        initialSupply = totalSupply;
    }
}