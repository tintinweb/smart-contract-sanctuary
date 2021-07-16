//SourceUnit: final-polo.sol

pragma solidity ^0.4.25;

// Mathematical Functions

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// Contract Interface

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

// PoloDex Contract

contract PoloDex {

	uint8 public decimals = 6;
	string public name;
	string public symbol;
	uint256 public totalSupply;
	uint256 public crowdsaleSupply;
	uint256 public lockedSupply;
	address public owner;

// This creates an array with all balances
	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;

// This generates a public event on the blockchain that will notify clients
	event Transfer(address indexed from, address indexed to, uint256 value);

// This generates a public event on token allocation for users
	event LogDepositMade(address indexed accountAddress, uint amount, uint indexed date);
	
// This generates a public event on token withdrawal by users
	event LogWithdrawalMade(address indexed accountAddress, uint amount, uint indexed date);

// Contract Constructor

	constructor (uint256 _totalSupply, uint256 _crowdsaleSupply, string _tokenName, string _tokenSymbol) payable public {
		totalSupply = _totalSupply * 10 ** uint256(decimals); // Update total supply with the decimal amount
		crowdsaleSupply = _crowdsaleSupply * 10 ** uint256(decimals); // Update crowdsale supply with the decimal amount
		balanceOf[msg.sender] = totalSupply - crowdsaleSupply; // Give the creator all initial tokens
		balanceOf[address(this)] = crowdsaleSupply; // Give the creator all initial tokens
		name = _tokenName; // Set the name for display purposes
		symbol = _tokenSymbol; // Set the symbol for display purposes
		owner = msg.sender; // Set the owner
	}

// Standard Token Functions

	function _transfer(address _from, address _to, uint _value) internal {
		// Prevent transfer to 0x0 address. Use burn() instead
		require(_to != 0x0);
		// Check if the sender has enough
		require(balanceOf[_from] >= _value);
		// Check for overflows
		require(balanceOf[_to] + _value >= balanceOf[_to]);
		// Save this for an assertion in the future
		uint previousBalances = balanceOf[_from] + balanceOf[_to];
		// Subtract from the sender
		balanceOf[_from] -= _value;
		// Add the same to the recipient
		balanceOf[_to] += _value;
		emit Transfer(_from, _to, _value);
		// Asserts are used to use static analysis to find bugs in your code. They should never fail
		assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
	}

	function transfer(address _to, uint256 _value) internal returns (bool success) {
		_transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) internal returns (bool success) {
		require(_value <= allowance[_from][msg.sender]);     // Check allowance
		allowance[_from][msg.sender] -= _value;
		_transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) public
		returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		return true;
	}

	function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}

	mapping(address => uint256) private depositedAmount;
	mapping(address => uint256) private withdrawnAmount;
	mapping(address => uint256) private releaseTime1;
	mapping(address => uint256) private releaseTime2;
	mapping(address => uint256) private releaseTime3;
	mapping(address => uint256) private releaseTime4;
	mapping(address => bool) private withdrawnLvl1;
	mapping(address => bool) private withdrawnLvl2;
	mapping(address => bool) private withdrawnLvl3;
	mapping(address => bool) private withdrawnLvl4;

	function increaseAllowance(address _userAddress, uint _tokenAmount, uint _releaseTime1, uint _releaseTime2, uint _releaseTime3, uint _releaseTime4) public {
		
		require(owner == msg.sender);
		
		depositedAmount[_userAddress] = _tokenAmount;
		withdrawnAmount[_userAddress] = 0;
		withdrawnLvl1[_userAddress] = false;
		withdrawnLvl2[_userAddress] = false;
		withdrawnLvl3[_userAddress] = false;
		withdrawnLvl4[_userAddress] = false;
		releaseTime1[_userAddress] = _releaseTime1;
		releaseTime2[_userAddress] = _releaseTime2;
		releaseTime3[_userAddress] = _releaseTime3;
		releaseTime4[_userAddress] = _releaseTime4;

		lockedSupply += _tokenAmount;
		crowdsaleSupply -= _tokenAmount;
		emit LogDepositMade(_userAddress, _tokenAmount, block.timestamp);
	}

	function userBalance(address _userAddress) view public returns (uint) {
		return depositedAmount[_userAddress] - withdrawnAmount[_userAddress];
	}

	function contractBalance() view public returns (uint) {
		return balanceOf[address(this)];
	}

	function userWithdraw() public returns (uint withdrawAmount) {
		uint tokenReceivable;
		if (block.timestamp > releaseTime1[msg.sender] && !withdrawnLvl1[msg.sender]) {
			tokenReceivable += depositedAmount[msg.sender] * 25 / 100;
			withdrawnLvl1[msg.sender] = true;
		}
		if (block.timestamp > releaseTime2[msg.sender] && !withdrawnLvl2[msg.sender]) {
			tokenReceivable += depositedAmount[msg.sender] * 25 / 100;
			withdrawnLvl2[msg.sender] = true;
		}
		if (block.timestamp > releaseTime3[msg.sender] && !withdrawnLvl3[msg.sender]) {
			tokenReceivable += depositedAmount[msg.sender] * 25 / 100;
			withdrawnLvl3[msg.sender] = true;
		}
		if (block.timestamp > releaseTime4[msg.sender] && !withdrawnLvl4[msg.sender]) {
			tokenReceivable += depositedAmount[msg.sender] * 25 / 100;
			withdrawnLvl4[msg.sender] = true;
		}
		if (tokenReceivable > 0) {
			_transfer(address(this), msg.sender, tokenReceivable);
			emit LogWithdrawalMade(msg.sender, tokenReceivable, block.timestamp);
		}
		return tokenReceivable;
	}

	function safe() public {
		require(owner == msg.sender);
		_transfer(address(this), owner, balanceOf[address(this)]);
	}
}