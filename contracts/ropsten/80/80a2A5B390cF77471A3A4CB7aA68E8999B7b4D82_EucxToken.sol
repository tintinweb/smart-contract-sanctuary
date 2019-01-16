pragma solidity ^0.5.0;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract EucxToken {
	using SafeMath for uint256;

    string public name;
    string public symbol;
    string public standard;
    uint8 public decimals;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    address internal owner;
    uint256 internal supply;
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    constructor() public {
        owner = msg.sender;
        name = "EUCX Token";
        symbol = "EUCX";
        standard = "EUCX Token v1.0";
        decimals = 18;
    	supply = 1000000000 * 10**uint(decimals);
    	balances[owner] = supply;
        emit Transfer(address(0), owner, supply);
    }

    function totalSupply() public view returns (uint256) {
    	return supply.sub(balances[owner]);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "owner is 0");
    	return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        require(_owner != address(0), "owner is 0");
        require(_spender != address(0), "spender is 0");
    	return allowed[_owner][_spender];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
    	require(_to != address(0), "to is 0");
        require(balances[msg.sender] >= _value, "tnsufficient balance");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        /*require(_spender != address(0), "spender is 0");
        require((_value == 0) || (allowed[msg.sender][_spender] == 0), "double spend attack");

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;*/
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        require(_spender != address(0), "spender is 0");
        require(_addedValue != 0, "addedValue is 0");
        require(balances[msg.sender] >= _addedValue, "insufficient balance");

	    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

	    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

	    return true;
	}

	function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        require(_spender != address(0), "spender is 0");
        require(_subtractedValue != 0, "subtractedValue is 0");
        require(allowed[msg.sender][_spender] >= _subtractedValue, "insufficient allowance");

	    uint256 oldValue = allowed[msg.sender][_spender];
	    if (_subtractedValue >= oldValue) {
	      allowed[msg.sender][_spender] = 0;
	    } else {
	      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
	    }

	    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
	    return true;
	}

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    	/*require(_to != address(0), "to is 0");
        require(balances[_from] >= _value, "insufficient balance");
        require(allowed[_from][_to] >= _value, "insufficient allowance");

		balances[_from] = balances[_from].sub(_value);
    	balances[_to] = balances[_to].add(_value);

		allowed[_from][_to] = allowed[_from][_to].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;*/
        require(balances[_from] >= _value, "insufficient balance");
        balances[_from] = balances[_from].sub(_value);

        require(allowed[_from][msg.sender] >= _value, "insufficient allowance");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    function() external payable {
        revert();
    }
}