pragma solidity ^0.4.20;

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

contract OwnableToken {
	address public owner;
	address public minter;
	address public burner;
	address public controller;
	
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	function OwnableToken() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	modifier onlyMinter() {
		require(msg.sender == minter);
		_;
	}
	
	modifier onlyBurner() {
		require(msg.sender == burner);
		_;
	}
	modifier onlyController() {
		require(msg.sender == controller);
		_;
	}
  
	modifier onlyPayloadSize(uint256 numwords) {                                       
		assert(msg.data.length == numwords * 32 + 4);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
	
	function setMinter(address _minterAddress) public onlyOwner {
		minter = _minterAddress;
	}
	
	function setBurner(address _burnerAddress) public onlyOwner {
		burner = _burnerAddress;
	}
	
	function setControler(address _controller) public onlyOwner {
		controller = _controller;
	}
}

contract KYCControl is OwnableToken {
	event KYCApproved(address _user, bool isApproved);
	mapping(address => bool) public KYCParticipants;
	
	function isKYCApproved(address _who) view public returns (bool _isAprroved){
		return KYCParticipants[_who];
	}

	function approveKYC(address _userAddress) onlyController public {
		KYCParticipants[_userAddress] = true;
		emit KYCApproved(_userAddress, true);
	}
}

contract VernamCrowdSaleToken is OwnableToken, KYCControl {
	using SafeMath for uint256;
	
    event Transfer(address indexed from, address indexed to, uint256 value);
    
	/* Public variables of the token */
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public _totalSupply;
	
	/*Private Variables*/
	uint256 constant POW = 10 ** 18;
	uint256 _circulatingSupply;
	
	/* This creates an array with all balances */
	mapping (address => uint256) public balances;
		
	// This notifies clients about the amount burnt
	event Burn(address indexed from, uint256 value);
	event Mint(address indexed _participant, uint256 value);

	/* Initializes contract with initial supply tokens to the creator of the contract */
	function VernamCrowdSaleToken() public {
		name = "Vernam Crowdsale Token";                            // Set the name for display purposes
		symbol = "VCT";                               				// Set the symbol for display purposes
		decimals = 18;                            					// Amount of decimals for display purposes
		_totalSupply = SafeMath.mul(1000000000, POW);     			//1 Billion Tokens with 18 Decimals
		_circulatingSupply = 0;
	}
	
	function mintToken(address _participant, uint256 _mintedAmount) public onlyMinter returns (bool _success) {
		require(_mintedAmount > 0);
		require(_circulatingSupply.add(_mintedAmount) <= _totalSupply);
		KYCParticipants[_participant] = false;

        balances[_participant] =  balances[_participant].add(_mintedAmount);
        _circulatingSupply = _circulatingSupply.add(_mintedAmount);
		
		emit Transfer(0, this, _mintedAmount);
        emit Transfer(this, _participant, _mintedAmount);
		emit Mint(_participant, _mintedAmount);
		
		return true;
    }
	
	function burn(address _participant, uint256 _value) public onlyBurner returns (bool _success) {
        require(_value > 0);
		require(balances[_participant] >= _value);   							// Check if the sender has enough
		require(isKYCApproved(_participant) == true);
		balances[_participant] = balances[_participant].sub(_value);            // Subtract from the sender
		_circulatingSupply = _circulatingSupply.sub(_value);
        _totalSupply = _totalSupply.sub(_value);                      			// Updates totalSupply
		emit Transfer(_participant, 0, _value);
        emit Burn(_participant, _value);
        
		return true;
    }
  
	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}
	
	function circulatingSupply() public view returns (uint256) {
		return _circulatingSupply;
	}
	
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}
}