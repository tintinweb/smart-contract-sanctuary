//SourceUnit: bmtT7.sol

pragma solidity ^0.4.25;

// ----------------------------------------------------------------------------
// A token for the BMT (Temp) is an exchangeable token with the TRX.
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
	function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

// ----------------------------------------------------------------------------
// TRON TRC20
// ----------------------------------------------------------------------------
contract TRC20Interface {
	function totalSupply() public constant returns (uint supply);
	function balanceOf(address _owner) public constant returns (uint balance);
	function transfer(address _to, uint _tokens) public returns (bool success);
	function transferFrom(address _from, address _to, uint _tokens) public returns (bool success);
	function approve(address _spender, uint _tokens) public returns (bool success);
	function allowance(address _owner, address _spender) public constant returns (uint remaining);

	event Transfer(address indexed _from, address indexed _to, uint _tokens);
	event Approval(address indexed _owner, address indexed _spender, uint _tokens);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
	address public owner;
	address public newOwner;

	event OwnershipTransferred(address indexed _from, address indexed _to);

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		newOwner = _newOwner;
	}

	function acceptOwnership() public {
		require(msg.sender == newOwner);
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
		newOwner = address(0);
	}
}

// ----------------------------------------------------------------------------
// NAME : Blockchain Middleware Token (Temp) (bmtT)
// ----------------------------------------------------------------------------
contract bmtT is Owned, TRC20Interface {
	// external variable
	string public symbol;
	string public name;
	uint public decimals;
	
	uint256 public bPrice;
	uint256 public sPrice;

	uint256 public playCount;
	uint256 public winCount;
	uint256 public totalBet;
	uint256 public totalReward;

	// internal variable
	uint _mega;
	uint _totalSupply;

	mapping(address => uint) balances;
	mapping(address => mapping (address => uint)) allowed;
	mapping(address => uint) receivedTRX;

	event ReceiveTRX(address _sender, uint _amount);
	event ChangeSupply(uint256 _supply);
	event ChangePrice(uint256 _bprice, uint256 _sprice);
	event Bet(address _player, uint256 _amount);
	event BetInfo(address _player, uint256 _amount, string _info);
	event Reward(address _player, uint256 _amount);
	event TakeFee(uint256 _amount);

	constructor() public {
		symbol = "bmtT7";
		name = "BM Token Temp7";
		decimals = 6;

		sPrice = 1 * 10**decimals;
		bPrice = 1 * 10**decimals;

		_mega = 1000000;
		_totalSupply = 2000 * _mega * 10**decimals;
		balances[owner] = _totalSupply;

		playCount  = 0;
		winCount   = 0;
		totalBet   = 0;
		totalReward= 0;

		emit Transfer(address(0), owner, _totalSupply);
	}

	// ----------------------------------------------------------------------------
	// TRC20
	// ----------------------------------------------------------------------------
	function totalSupply() public view returns (uint supply) {
		return _totalSupply;
	}
  
	function balanceOf(address _owner) public view returns (uint balance) {
		return balances[_owner];
	}
	
	function transfer(address _to, uint _tokens) public returns (bool success) {
		require(balances[msg.sender] >= _tokens);
		require(_tokens > 0);
		
		balances[msg.sender] -= _tokens;
		balances[_to] += _tokens;
		
		emit Transfer(msg.sender, _to, _tokens);
		return true;
	}
  
	function transferFrom(address _from, address _to, uint _tokens) public returns (bool success) {
		require(balances[_from] >= _tokens);
		require(_tokens > 0);
		require(allowed[_from][msg.sender] >= _tokens);
		
		balances[_from] -= _tokens;
		allowed[_from][msg.sender] -= _tokens;
		balances[_to] += _tokens;
		
		emit Transfer(_from, _to, _tokens);
		return true;
	}
	
	function approve(address _spender, uint _tokens) public returns (bool success) {
		allowed[msg.sender][_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint remaining) {
		return allowed[_owner][_spender];
	}
  
	// ----------------------------------------------------------------------------
	// TRANS
	// ----------------------------------------------------------------------------
	function() payable public {
		receivedTRX[msg.sender] = msg.value;
    	emit ReceiveTRX(msg.sender, msg.value);
	}

	function buy() payable external {
		address ownAddress = address(owner);
		uint256 ownToken = balances[ownAddress];
		uint256 ownTrx = (ownToken * sPrice) / 10**decimals;
		
		uint256 retTrx = 0;
		if (msg.value > ownTrx) {
			retTrx = msg.value - ownTrx;
			msg.sender.transfer(retTrx);
		}
		
		uint256 amtToken = ((msg.value - retTrx) * bPrice) / 10**decimals;
		require(amtToken > 0);
		
		balances[ownAddress] -= amtToken;
		balances[msg.sender] += amtToken;

		emit Transfer(ownAddress, msg.sender, amtToken);
	}

	function sell(uint256 _tokens) public {
		address ownAddress = address(owner);
		uint256 amtTrx = (_tokens * sPrice) / 10**decimals;

		require(_tokens > 0);
		require(balances[msg.sender] >= _tokens);
		require(ownAddress.balance >= amtTrx);
		
		balances[ownAddress] += _tokens;
		balances[msg.sender] -= _tokens;

		emit Transfer(msg.sender, ownAddress, _tokens);
		msg.sender.transfer(amtTrx);
	}

	function setBuyPrice(uint256 _bprice) public onlyOwner {
		bPrice = _bprice;
		emit ChangePrice(bPrice, sPrice);
	}
	
	function setSellPrice(uint256 _sprice) public onlyOwner {
		sPrice = _sprice;
		emit ChangePrice(bPrice, sPrice);
	}

	// ----------------------------------------------------------------------------
	// BALANCE
	// ----------------------------------------------------------------------------
	function memBalance(address _owner) public view returns (uint256 tokens, uint256 balance) {
		return (balances[_owner], _owner.balance); 
	}

	function contBalance() public view returns (uint256 tokens, uint256 balance) {
		address cont = address(this);
		return (balances[cont], cont.balance); 
	}

	function ownBalance() public view returns (uint256 tokens, uint256 balance) {
		address ownAddress = address(owner);    
		return (balances[ownAddress], ownAddress.balance);
	}

	function mintToken(address _to, uint _amount) public onlyOwner returns (bool success) {
		address ownAddress = address(owner);
		
		balances[_to] += _amount;
		_totalSupply += _amount;
		emit Transfer(ownAddress, _to, _amount);
		emit ChangeSupply(_totalSupply);
		return true;
	}

	function burnToken(uint _amount) public onlyOwner returns (bool success) {
		address ownAddress = address(owner);   
		require(balances[ownAddress] > _amount);
		
		balances[ownAddress] -= _amount;
		_totalSupply -= _amount;
		emit ChangeSupply(_totalSupply);
		return true;
	}
  
	// ----------------------------------------------------------------------------
	// Game
	// ----------------------------------------------------------------------------
	function bet() payable external returns (uint256 amount) {
		totalBet += msg.value;
		playCount += 1;

		address player = msg.sender;
		emit Bet(player, msg.value);

		return msg.value;
	}
  
	function betinfo(string info) payable external returns (string) {
		totalBet += msg.value;
		playCount += 1;

		address player = msg.sender;
		emit BetInfo(player, msg.value, info);

		return info;
	}
  
	function reward(address player, uint256 _reward, uint256 _draw) onlyOwner public returns (uint256 profit) {
		totalReward += _reward;
		if (_reward > _draw) {
			winCount += 1;
		}

		address ownAddress = address(owner);
		require(ownAddress.balance >= _reward);
		player.transfer(_reward);
		emit Reward(player, _reward);

		if (_reward < _draw) return 0;
		else return _reward - _draw;
	}
  
	function betreward() payable external returns (uint256 amount) {
		totalBet += msg.value;
		playCount += 1;

		address player = msg.sender;
		emit Bet(player, msg.value);

		address ownAddress = address(owner);
		require(ownAddress.balance >= msg.value);

		player.transfer(msg.value);
		emit Reward(player, msg.value);

		return msg.value;
	}
  
	function takeFee(uint256 amount) onlyOwner public returns(uint256 balance) {
		address cont = address(this);
		require(cont.balance >= amount);

		msg.sender.transfer(amount);
		emit TakeFee(amount);
		return cont.balance;
	} 
  
}