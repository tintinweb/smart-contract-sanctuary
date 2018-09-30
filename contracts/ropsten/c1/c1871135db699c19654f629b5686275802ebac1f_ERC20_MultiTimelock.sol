pragma solidity ^0.4.25;

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

contract tokenInterface {
	function balanceOf(address _owner) public constant returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
	bool public started;
}

contract ERC20_MultiTimelock is Ownable, Authorizable {
    using SafeMath for uint256;

	tokenInterface public tokenContract;
	
	uint256 public startRelease;
	mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public timelock;
	
	/***************
	 * START ERC20 IMPLEMENTATION
	 ***************/
	 
 	string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    function transfer(address, uint256) public returns (bool) {
        return claim();
    }
    
	/***************
	 * END ERC20 IMPLEMENTATION
	 ***************/

	constructor(address _tokenAddress) public {
		tokenContract = tokenInterface(_tokenAddress);
		
		name = "AQER Timelock";
        symbol = "AQER-TL";
        decimals = 18;
	}

    //set start time to countdown
	function setRelease(uint256 _time) onlyOwner public {
	    require( startRelease == 0 , "startRelease == 0 ");
	    startRelease = _time;
	}
	
	//claim
	function claim() private returns (bool) {
	    require( startRelease != 0 , "startRelease != 0 ");
	    require( balanceOf[msg.sender] > 0, "balanceOf[msg.sender] > 0");
	    require( now > timelock[msg.sender].add(startRelease), "now > timelock[msg.sender].add(startRelease)" );
	    
		uint256 tknToSend = balanceOf[msg.sender];
		balanceOf[msg.sender] = 0;

		tokenContract.transfer(msg.sender, tknToSend);
		
	    emit Transfer(msg.sender, address(0), tknToSend);
	    totalSupply = totalSupply.sub(tknToSend);
	    
	    return true;
	}
	
	function () public {
	    claim();
	}
	
	//deposit
	function depositToken( address _beneficiary, uint256 _amount, uint256 _timelock) onlyAuthorized public {
	    require( tokenContract.transferFrom(msg.sender, this, _amount), "tokenContract.transferFrom(msg.sender, this, _amount)" );
	    
	    balanceOf[_beneficiary] = balanceOf[_beneficiary].add(_amount);
	    if ( timelock[_beneficiary] == 0 ) timelock[_beneficiary] = _timelock;
	    
	    totalSupply = totalSupply.add(_amount);
	    emit Transfer(address(0), _beneficiary, _amount);
	}
    
    //Emergency withdrawl
    function noAccountedWithdraw() onlyOwner public {
        uint256 diff = tokenContract.balanceOf(this).sub(totalSupply);
        tokenContract.transfer(msg.sender, diff);
    }
}