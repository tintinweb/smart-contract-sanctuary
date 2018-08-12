pragma solidity ^0.4.13;

contract EIP20Interface {

    uint256 public totalSupply;


    function balanceOf(address _owner) public view returns (uint256 balance);

  
    function transfer(address _to, uint256 _value) public returns (bool success);


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Monarch is EIP20Interface {
    using SafeMath for uint256;
    
	uint public constant totalSupply = 100000000000000000;

	string public constant symbol = "XMA";
	string public constant name = "Monarch";
	uint8 public constant decimals = 8;

	mapping(address => uint256) public balances;
	mapping(address => mapping(address => uint256)) public allowed;

    modifier validDestination( address to ) {
        require(to != address(0x0));
        require(to != address(this) );
        _;
    }

	function Monarch() public{
		balances[msg.sender] = totalSupply;
	}

	function balanceOf(address _owner) public view returns (uint256 balance){
		return balances[_owner];		
	}


	function transfer(address _to, uint _value) public
        validDestination(_to)
        returns (bool)
        {
		require(
			balances[msg.sender] >= _value
			&& _value > 0
		);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}


	function transferFrom(address _from, address _to, uint _value) public
        validDestination(_to)
        returns (bool)
        
        {require(
			allowed[_from][msg.sender] >= _value
			&& balances[_from] >= _value
			&& _value > 0
		);
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}


	function approve(address _spender, uint256 _value) public returns (bool success){
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;		
	}


	function allowance(address _owner, address _spender) public constant returns (uint256 remaining){
		return allowed[_owner][_spender];
	}

    function () public {
    
    }

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {

  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}