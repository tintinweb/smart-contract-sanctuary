/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

pragma solidity >=0.8.0 <0.9.0;

contract Gate {
	address payable public owner;

	modifier onlyOwner() {
		require(msg.sender == owner, 'Owner only');
		_;
	}

	function setOwner(address payable _owner) public onlyOwner {
		_setOwner(_owner);
	}

	function _setOwner(address payable _owner) internal {
		require(_owner != address(0));
		owner = _owner;
	}
}

contract RelayGame is Gate {

	struct Game {
		address payable player;
		uint32 roundNumber;
		uint value;
		uint delta;
		uint interest;
		uint fee;
	}

	struct Round {
		address player;
		string data;
		uint timestamp;
	}

	mapping (uint32 => Game) public games;
	mapping (uint32 => mapping(uint32 => Round)) public rounds;

	event Transfered(address _target, uint _value);

	constructor() {
		_setOwner(payable(msg.sender));
	}

	fallback() external payable {
		revert();
	}

	receive() external payable {
		revert();
	}

	function createGame(uint32 _gameId, uint _startValue, uint _delta, uint _interest, uint _fee) public onlyOwner {
		Game storage _game = games[_gameId];
		require(_game.player == address(0), 'Id is used');
		require(_fee > 0, 'Invalid fee');
		require(_interest > 0, 'Invalid interest');

		_game.player = owner;
		_game.roundNumber = 0;
		_game.value = _startValue;
		_game.delta = _delta;
		_game.interest = _interest;
		_game.fee = _fee;
	}

	function play(uint32 _gameId, string memory _data) public payable {
		Game storage _game = games[_gameId];
		require(_game.player != address(0), 'Invalid game id');

		uint _newValue = _game.value + (_game.value / _game.interest) + _game.delta;
		require(msg.value == _newValue, 'Invalid value');

		uint _feeValue = (_newValue - _game.value) / _game.fee;
		uint _playerValue = _newValue - _feeValue;

		_game.roundNumber++;
		_game.value = _playerValue;
		_game.player = payable(msg.sender);

		Round storage _round = rounds[_gameId][_game.roundNumber];
		_round.player = msg.sender;
		_round.data = _data;
		_round.timestamp = block.timestamp;

		_transfer(owner, _feeValue);
		_transfer(_game.player, _playerValue);
		require(address(this).balance == 0);
	}

	function _transfer(address payable _target, uint _value) private {
		(bool _success, ) = _target.call{ value: _value }('');
		require(_success, 'Transfer failed');
		emit Transfered(_target, _value);
	}
}