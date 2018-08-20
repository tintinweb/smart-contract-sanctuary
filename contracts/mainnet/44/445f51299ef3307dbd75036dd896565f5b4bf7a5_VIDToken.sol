pragma solidity ^0.4.24;

contract ERC20 {
	uint256 public totalSupply;

	function balanceOf(address who) public view returns (uint256 balance);

	function allowance(address owner, address spender) public view returns (uint256 remaining);

	function transfer(address to, uint256 value) public returns (bool success);

	function approve(address spender, uint256 value) public returns (bool success);

	function transferFrom(address from, address to, uint256 value) public returns (bool success);

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
	function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a - b;
		assert(b <= a && c <= a);
		return c;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a && c>=b);
		return c;
	}
}

library SafeERC20 {
	function safeTransfer(ERC20 _token, address _to, uint256 _value) internal {
		require(_token.transfer(_to, _value));
	}
}

contract Owned {
	address public owner;

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner,"O1- Owner only function");
		_;
	}

	function setOwner(address newOwner) onlyOwner public {
		owner = newOwner;
	}
}

contract Pausable is Owned {
	event Pause();
	event Unpause();

	bool public paused = false;

	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	modifier whenPaused() {
		require(paused);
		_;
	}

	function pause() public onlyOwner whenNotPaused {
		paused = true;
		emit Pause();
	}

	function unpause() public onlyOwner whenPaused {
		paused = false;
		emit Unpause();
	}
}

contract VIDToken is Owned, Pausable, ERC20 {
	using SafeMath for uint256;
	using SafeERC20 for ERC20;

	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) public allowed;
	mapping (address => bool) public frozenAccount;
	mapping (address => bool) public verifyPublisher;
	mapping (address => bool) public verifyWallet;

	struct fStruct { uint256 index; }
	mapping(string => fStruct) private fileHashes;
	string[] private fileIndex;

	string public constant name = "V-ID Token";
	uint8 public constant decimals = 18;
	string public constant symbol = "VIDT";
	uint256 public constant initialSupply = 100000000;

	uint256 public validationPrice = 7 * 10 ** uint(decimals);
	address public validationWallet = address(0);

	constructor() public {
		validationWallet = msg.sender;
		verifyWallet[msg.sender] = true;
		totalSupply = initialSupply * 10 ** uint(decimals);
		balances[msg.sender] = totalSupply;
		emit Transfer(address(0),owner,initialSupply);
	}

	function () public payable {
		revert();
	}

	function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
		require(_to != msg.sender,"T1- Recipient can not be the same as sender");
		require(_to != address(0),"T2- Please check the recipient address");
		require(balances[msg.sender] >= _value,"T3- The balance of sender is too low");
		require(!frozenAccount[msg.sender],"T4- The wallet of sender is frozen");
		require(!frozenAccount[_to],"T5- The wallet of recipient is frozen");

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

		emit Transfer(msg.sender, _to, _value);

		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
		require(_to != address(0),"TF1- Please check the recipient address");
		require(balances[_from] >= _value,"TF2- The balance of sender is too low");
		require(allowed[_from][msg.sender] >= _value,"TF3- The allowance of sender is too low");
		require(!frozenAccount[_from],"TF4- The wallet of sender is frozen");
		require(!frozenAccount[_to],"TF5- The wallet of recipient is frozen");

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);

		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

		emit Transfer(_from, _to, _value);

		return true;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
		require((_value == 0) || (allowed[msg.sender][_spender] == 0),"A1- Reset allowance to 0 first");

		allowed[msg.sender][_spender] = _value;

		emit Approval(msg.sender, _spender, _value);

		return true;
	}

	function increaseApproval(address _spender, uint256 _addedValue) public whenNotPaused returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

		return true;
	}

	function decreaseApproval(address _spender, uint256 _subtractedValue) public whenNotPaused returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].sub(_subtractedValue);

		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	struct TKN { address sender; uint256 value; bytes data; bytes4 sig; }

	function tokenFallback(address _from, uint256 _value, bytes _data) public pure returns (bool) {
		TKN memory tkn;
		tkn.sender = _from;
		tkn.value = _value;
		tkn.data = _data;
		uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
		tkn.sig = bytes4(u);
		return true;
	}

	function transferToken(address tokenAddress, uint256 tokens) public onlyOwner {
		ERC20(tokenAddress).safeTransfer(owner,tokens);
	}

	function burn(uint256 _value) public onlyOwner returns (bool) {
		require(_value <= balances[msg.sender],"B1- The balance of burner is too low");

		balances[msg.sender] = balances[msg.sender].sub(_value);
		totalSupply = totalSupply.sub(_value);

		emit Burn(msg.sender, _value);

		emit Transfer(msg.sender, address(0), _value);

		return true;
	}

	function freeze(address _address, bool _state) public onlyOwner returns (bool) {
		frozenAccount[_address] = _state;

		emit Freeze(_address, _state);

		return true;
	}

	function validatePublisher(address Address, bool State, string Publisher) public onlyOwner returns (bool) {
		verifyPublisher[Address] = State;

		emit ValidatePublisher(Address,State,Publisher);

		return true;
	}

	function validateWallet(address Address, bool State, string Wallet) public onlyOwner returns (bool) {
		verifyWallet[Address] = State;

		emit ValidateWallet(Address,State,Wallet);

		return true;
	}

	function validateFile(address To, uint256 Payment, bytes Data, bool cStore, bool eLog) public whenNotPaused returns (bool) {
		require(Payment>=validationPrice,"V1- Insufficient payment provided");
		require(verifyPublisher[msg.sender],"V2- Unverified publisher address");
		require(!frozenAccount[msg.sender],"V3- The wallet of publisher is frozen");
		require(Data.length == 64,"V4- Invalid hash provided");

		if (!verifyWallet[To] || frozenAccount[To]) {
			To = validationWallet;
		}

		uint256 index = 0;
		string memory fileHash = string(Data);

		if (cStore) {
			if (fileIndex.length > 0) {
				require(fileHashes[fileHash].index == 0,"V5- This hash was previously validated");
			}

			fileHashes[fileHash].index = fileIndex.push(fileHash)-1;
			index = fileHashes[fileHash].index;
		}

		if (allowed[To][msg.sender] >= Payment) {
			allowed[To][msg.sender] = allowed[To][msg.sender].sub(Payment);
		} else {
			balances[msg.sender] = balances[msg.sender].sub(Payment);
			balances[To] = balances[To].add(Payment);
		}

		emit Transfer(msg.sender, To, Payment);

		if (eLog) {
			emit ValidateFile(index,fileHash);
		}

		return true;
	}

	function verifyFile(string fileHash) public view returns (bool) {
		if (fileIndex.length == 0) {
			return false;
		}

		bytes memory a = bytes(fileIndex[fileHashes[fileHash].index]);
		bytes memory b = bytes(fileHash);

		if (a.length != b.length) {
			return false;
		}

		for (uint256 i = 0; i < a.length; i ++) {
			if (a[i] != b[i]) {
				return false;
			}
		}

		return true;
	}

	function setPrice(uint256 newPrice) public onlyOwner {
		validationPrice = newPrice;
	}

	function setWallet(address newWallet) public onlyOwner {
		validationWallet = newWallet;
	}

	function listFiles(uint256 startAt, uint256 stopAt) onlyOwner public returns (bool) {
		if (fileIndex.length == 0) {
			return false;
		}

		require(startAt <= fileIndex.length-1,"L1- Please select a valid start");

		if (stopAt > 0) {
			require(stopAt > startAt && stopAt <= fileIndex.length-1,"L2- Please select a valid stop");
		} else {
			stopAt = fileIndex.length-1;
		}

		for (uint256 i = startAt; i <= stopAt; i++) {
			emit LogEvent(i,fileIndex[i]);
		}

		return true;
	}

	event Burn(address indexed burner, uint256 value);
	event Freeze(address target, bool frozen);

	event ValidateFile(uint256 index, string data);
	event ValidatePublisher(address indexed publisherAddress, bool state, string indexed publisherName);
	event ValidateWallet(address indexed walletAddress, bool state, string indexed walletName);

	event LogEvent(uint256 index, string data) anonymous;
}