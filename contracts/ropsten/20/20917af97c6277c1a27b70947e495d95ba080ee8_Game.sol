pragma solidity ^0.4.24;

contract MyToken{

	mapping (address => uint) public balanceOf;
	uint public totalSupply;
	address public bank;
	address public owner;

	modifier onlyBy(address _address){
		require(msg.sender == _address);
		_;
	}

	constructor (address _bank){
		bank = _bank;
		owner = msg.sender;
		totalSupply = 0;
	}

	function transfer(address _to, uint _amount) returns (bool){
		require(balanceOf[_to] + _amount > balanceOf[_to]);
		require(balanceOf[msg.sender] >= _amount);
		balanceOf[msg.sender] -= _amount;
		balanceOf[_to] += _amount;
		
		return true;
	}

	function mint(address _to, uint _amount) onlyBy(bank){
		require(balanceOf[_to] + _amount > balanceOf[_to]);
		balanceOf[_to] += _amount;
		totalSupply += _amount;
	}

	function transferByGame(address _from, address _to, uint _amount) onlyBy(owner){
		require(balanceOf[_to] + _amount > balanceOf[_to]);
		require(balanceOf[_from] >= _amount);
		balanceOf[_from] -= _amount;
		balanceOf[_to] += _amount;
	}

	function changeBank(address _newBank) onlyBy(bank){
		bank = _newBank;
	}

}

contract Game{
	
	struct Option {
		uint totalGet;
		mapping (address => uint) betInfo;
	}

	Option[2] public options;
	uint public bettingTime;
	uint public totalReward;
	address public tokenAddress;
	uint winner;
	uint totalSend;
	MyToken money;

	enum GameState {Create, Betting, GettingResult, Dispatch, End}
	GameState state;

	event BetSuccess(address _address, uint _amount, uint _option);
	event RevealResult(uint _totalA, uint totalB);
	event Winner(uint _option);
	event Reward(address _receiver, uint _amount);

	modifier onlyAt(GameState _state){
		require(state == _state);
		_;
	}

	// Stage 0: Create
	// Initialize
	constructor (uint _betTimePeriodInMinutes, address _bank){
		bettingTime = _betTimePeriodInMinutes * 1 minutes;
		state = GameState.Betting;
		tokenAddress = new MyToken(_bank);
		money = MyToken(tokenAddress);
	}

	// Stage 1: Betting
	function bet(uint _option, uint _amount) onlyAt(GameState.Betting){
		require(_option < options.length);
		money.transferByGame(msg.sender, this, _amount);
		options[_option].betInfo[msg.sender] += _amount;
		options[_option].totalGet += _amount;
		totalReward += _amount;
		emit BetSuccess(msg.sender, _amount, _option);
		if(now > bettingTime){
			state = GameState.GettingResult;
			emit RevealResult(options[0].totalGet, options[1].totalGet);
		}
	}

	// Stage 2: Getting Result
	function revealResult() onlyAt(GameState.GettingResult){
		winner = uint(sha3(block.timestamp)) % 2;
		state = GameState.Dispatch;
		emit Winner(winner);
	}

	// Stage 3: Dispatch the reward
	function withdraw() onlyAt(GameState.Dispatch){
		require(winner < options.length);
		require(options[winner].betInfo[msg.sender] != 0);

		uint value = totalReward * options[winner].betInfo[msg.sender] / options[winner].totalGet;
		require(money.transfer(msg.sender, value));
		emit Reward(msg.sender, value);

		options[winner].betInfo[msg.sender] = 0;
		totalSend += value;

		if(totalSend == totalReward) state = GameState.End;
	}

	// helper funtion
	function showWinner() view returns(string){
		if(state <= GameState.GettingResult) return "no result";
		else if(winner == 0) return "The winner is A.";
		else if(winner == 1) return "The winner is B.";
		else throw;
	}

	function showState() view returns(string){
		if(state == GameState.Create) return "Create";
		else if(state == GameState.Betting) return "Betting";
		else if(state == GameState.GettingResult) return "GettingResult";
		else if(state == GameState.Dispatch) return "Dispatch";
		else if(state == GameState.End) return "End";
		else throw;
	}
}