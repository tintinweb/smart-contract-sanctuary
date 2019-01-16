pragma solidity ^0.4.19;

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function () public payable {
        revert();
    }
}


/*  ERC 20 token */
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_to] + _value < balances[_to]) revert(); // Check for overflows
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

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    function () public payable {
        revert();
    }
}

contract SafeMath {

    /* function assert(bool assertion) internal { */
    /*   if (!assertion) { */
    /*     throw; */
    /*   } */
    /* }      // assert no longer needed once solidity is on 0.4.10 */

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }

    function () public payable {
        revert();
    }

}
contract Owner {

	/// @dev `owner` is the only address that can call a function with this
	/// modifier
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	address public owner;

	/// @notice The Constructor assigns the message sender to be `owner`
	function Owner() public {
		owner = msg.sender;
	}

	address public newOwner;

	/// @notice `owner` can step down and assign some other address to this role
	/// @param _newOwner The address of the new owner. 0x0 can be used to create
	///  an unowned neutral vault, however that cannot be undone
	function changeOwner(address _newOwner) public onlyOwner {
		newOwner = _newOwner;
	}


	function acceptOwnership() public {
		if (msg.sender == newOwner) {
			owner = newOwner;
		}
	}

	function () public payable {
		revert();
	}

}
contract MOT is Owner, StandardToken, SafeMath {
	string public constant name = "MOT";
	string public constant symbol = "MOT";
	uint256 public constant decimals = 18;
	string public version = "1.0";


	uint256 public constant total = 1 * (10**8) * 10**decimals;   // 1*10^8 MOT total

	function MOT() {

		totalSupply = total;
		balances[msg.sender] = total;             // Give the creator all initial tokens
	}
	function () public payable {
		revert();
	}
}