pragma solidity ^0.4.24;

contract ERC20 {

    function totalSupply() public constant returns (uint);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

}

contract BasicToken is ERC20 {

    using SafeMath for uint256;

    uint256  public totalSupply = 10*10**26;
    uint8 constant public decimals = 18;
    string constant public name = "Koala Coin";
    string constant public symbol = "KLC";

	mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) internal allowed;

	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}


   function totalSupply() public constant returns (uint256){
        return totalSupply;
   }

	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}


	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}


	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit  Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract Ownable {

	address public owner;
	
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

}

contract Controlled is Ownable{

    constructor() public {
       setExclude(msg.sender);
    }

    bool public transferEnabled = false;

    bool public lockFlag=true;
    mapping(address => bool) locked;
    mapping(address => bool) exclude;

	event AddLock(address indexed _addr);
	event RemoveLock(address indexed _addr);

    function enableTransfer(bool _enable) public onlyOwner{
        transferEnabled=_enable;
    }

    function disableLock(bool _enable) public onlyOwner returns (bool success){
        lockFlag=_enable;
        return true;
    }

	
    function addLock(address _addr) public onlyOwner returns (bool success){
        require(_addr!=msg.sender);
        locked[_addr]=true;
		emit AddLock(_addr);
        return true;
    }

    function setExclude(address _addr) public onlyOwner returns (bool success){
        exclude[_addr]=true;
        return true;
    }

    function removeLock(address _addr) public onlyOwner returns (bool success){
        locked[_addr]=false;
		emit RemoveLock(_addr);
        return true;
    }

    modifier transferAllowed(address _addr) {
        if (!exclude[_addr]) {
            assert(transferEnabled);
            if(lockFlag){
                assert(!locked[_addr]);
            }
        }
        _;
    }

}

contract BurnableToken is BasicToken {


	event Burn(address indexed burner, uint256 value);

	function burn(uint256 _value) public {
		require(_value <= balances[msg.sender]);

		address burner = msg.sender;
		balances[burner] = balances[burner].sub(_value);
		totalSupply = totalSupply.sub(_value);
		emit Burn(burner, _value);
	}
}


contract ControlledToken is BasicToken, Controlled {

  function transfer(address _to, uint256 _value) public transferAllowed(msg.sender) returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public transferAllowed(msg.sender) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public transferAllowed(msg.sender) returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public transferAllowed(msg.sender) returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public transferAllowed(msg.sender) returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}


contract  KLCToken is ControlledToken, BurnableToken {



	constructor() public {
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
	}

	event LogRedeem(address beneficiary, uint256 amount);

	function redeem() public {

		uint256 balance = balanceOf(msg.sender);
		super.burn(balance);
 		emit LogRedeem(msg.sender, balance);
	}


}


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