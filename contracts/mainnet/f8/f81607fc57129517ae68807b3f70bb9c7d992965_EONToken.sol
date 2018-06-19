pragma solidity ^0.4.23;

contract Ownable {
	address public owner;

	// event
	event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		require(_newOwner != address(0));
		emit OwnershipTransferred(owner, _newOwner);
		owner = _newOwner;
	}
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = true;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

contract ControllablePause is Pausable {
    mapping(address => bool) public transferWhiteList;
    
    modifier whenControllablePaused() {
        if (!paused) {
            require(transferWhiteList[msg.sender]);
        }
        _;
    }
    
    modifier whenControllableNotPaused() {
        if (paused) {
            require(transferWhiteList[msg.sender]);
        }
        _;
    }
    
    function addTransferWhiteList(address _new) public onlyOwner {
        transferWhiteList[_new] = true;
    }
    
    function delTransferWhiteList(address _del) public onlyOwner {
        delete transferWhiteList[_del];
    }
}

// https://github.com/ethereum/EIPs/issues/179
contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address _owner) public view returns (uint256);
	function transfer(address _to, uint256 _value) public returns (bool);
	
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


// https://github.com/ethereum/EIPs/issues/20
contract ERC20 is ERC20Basic {
	function allowance(address _owner, address _spender) public view returns (uint256);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
	function approve(address _spender, uint256 _value) public returns (bool);
	
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract BasicToken is ERC20Basic {
    
    // use SafeMath to avoid uint256 overflow
	using SafeMath for uint256;

    // balances of every address
	mapping(address => uint256) balances;

	// total number of token
	uint256 totalSupply_;

    // return total number of token
	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	// transfer _value tokens to _to from msg.sender
	function transfer(address _to, uint256 _value) public returns (bool) {
	    // if you want to destroy tokens, use burn replace transfer to address 0
		require(_to != address(0));
		// can not transfer to self
		require(_to != msg.sender);
		require(_value <= balances[msg.sender]);

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	// return _owner how many tokens
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

}


// anyone can destroy his tokens
contract BurnableToken is BasicToken {

	event Burn(address indexed burner, uint256 value);

    // destroy his tokens
	function burn(uint256 _value) public {
		require(_value <= balances[msg.sender]);
		
		address burner = msg.sender;
		balances[burner] = balances[burner].sub(_value);
		totalSupply_ = totalSupply_.sub(_value);
		emit Burn(burner, _value);
		// add a Transfer event only to ensure Transfer event record integrity
		emit Transfer(burner, address(0), _value);
	}
}


// refer: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
contract StandardToken is ERC20, BasicToken {

	mapping (address => mapping (address => uint256)) internal allowed;

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_from != _to);
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	// https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

    // return how many tokens _owner approve to _spender
	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

    // increase approval to _spender
	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

    // decrease approval to _spender
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


contract PausableToken is BurnableToken, StandardToken, ControllablePause{
    
    function burn(uint256 _value) public whenControllableNotPaused {
        super.burn(_value);
    }
    
    function transfer(address _to, uint256 _value) public whenControllableNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public whenControllableNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}


contract EONToken is PausableToken {
	using SafeMath for uint256;
    
	string public constant name	= &#39;Entertainment Open Network&#39;;
	string public constant symbol = &#39;EON&#39;;
	uint public constant decimals = 18;
	uint public constant INITIAL_SUPPLY = 21*10**26;

	constructor() public {
		totalSupply_ = INITIAL_SUPPLY;
		balances[owner] = totalSupply_;
		emit Transfer(address(0x0), owner, totalSupply_);
	}

	function batchTransfer(address[] _recipients, uint256 _value) public whenControllableNotPaused returns (bool) {
		uint256 count = _recipients.length;
		require(count > 0 && count <= 20);
		uint256 needAmount = count.mul(_value);
		require(_value > 0 && balances[msg.sender] >= needAmount);

		for (uint256 i = 0; i < count; i++) {
			transfer(_recipients[i], _value);
		}
		return true;
	}
	
    // Record private sale wallet to allow transfering.
    address public privateSaleWallet;

    // Crowdsale contract address.
    address public crowdsaleAddress;
    
    // Lock tokens contract address.
    address public lockTokensAddress;
    
    function setLockTokensAddress(address _lockTokensAddress) external onlyOwner {
        lockTokensAddress = _lockTokensAddress;
    }
	
    function setCrowdsaleAddress(address _crowdsaleAddress) external onlyOwner {
        // Can only set one time.
        require(crowdsaleAddress == address(0));
        require(_crowdsaleAddress != address(0));
        crowdsaleAddress = _crowdsaleAddress;
    }

    function setPrivateSaleAddress(address _privateSaleWallet) external onlyOwner {
        // Can only set one time.
        require(privateSaleWallet == address(0));
        privateSaleWallet = _privateSaleWallet;
    }
    
    // revert error pay 
    function () public {
        revert();
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