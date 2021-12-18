/**
 *Submitted for verification at polygonscan.com on 2021-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface RNGOracle {
	function modulusRequest(uint256 _modulus, uint256 _betmask, bytes32 _seed) external returns (bytes32 queryId);
}

interface ERC20 {
	function allowance(address, address) external view returns (uint256);
	function balanceOf(address) external view returns (uint256);
	function approve(address, uint256) external returns (bool);
	function transfer(address, uint256) external returns (bool);
	function transferFrom(address, address, uint256) external returns (bool);
}

contract FomoCoin {

	uint256 constant private FLOAT_SCALAR = 2**64;
	uint256 constant private MAX_TIME = 24 hours;
	uint256 constant private KRILL_COST_PER_FLIP = 1e23; // 100k

	struct RoundPlayer {
		uint256 shares;
		int256 scaledPayout;
	}

	struct Round {
		uint256 targetTimestamp;
		uint256 jackpotValue;
		uint256 totalShares;
		uint256 scaledCumulativeKRILL;
		mapping(address => RoundPlayer) roundPlayers;
		address[3] lastPlayers;
	}

	struct Info {
		uint256 totalRounds;
		mapping(uint256 => Round) rounds;
		mapping(bytes32 => address) betInfo;
		RNGOracle oracle;
		ERC20 krill;
		ERC20 link;
		address owner;
	}
	Info private info;


	event BetPlaced(address indexed player, bytes32 queryId);
	event BetResolved(address indexed player, bytes32 indexed queryId, uint256 indexed round, bool didWin);
	event BetFailed(address indexed player, bytes32 indexed queryId);
	event RoundStarted(uint256 indexed round);
	event RoundEnded(uint256 indexed round, uint256 endTime, uint256 jackpotValue, uint256 totalShares, address[3] lastPlayers);
	event Withdraw(address indexed player, uint256 indexed round, uint256 amount);


	modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}

	modifier _checkRound {
		uint256 _round = currentRoundIndex();
		if (roundTargetTimestamp(_round) <= block.timestamp) {
			emit RoundEnded(_round, roundTargetTimestamp(_round), roundJackpotValue(_round), roundTotalShares(_round), roundLastPlayers(_round));
			_newRound();
		}
		_;
	}


	constructor(RNGOracle _rngOracle, ERC20 _krill) {
		info.link = ERC20(0xb0897686c545045aFc77CF20eC7A532E3120E0F1);
		info.link.approve(address(_rngOracle), type(uint256).max);
		info.owner = msg.sender;
		info.oracle = _rngOracle;
		info.krill = _krill;
		_newRound();
	}

	function setOwner(address _owner) external _onlyOwner {
		info.owner = _owner;
	}

	function withdrawLINK() external _onlyOwner {
		info.link.transfer(msg.sender, info.link.balanceOf(address(this)));
	}

	function flipCoin() external _checkRound {
		info.krill.transferFrom(msg.sender, address(this), KRILL_COST_PER_FLIP);
		bytes32 _queryId = info.oracle.modulusRequest(2, 1, keccak256(abi.encodePacked(msg.sender, block.number)));
		info.betInfo[_queryId] = msg.sender;
		emit BetPlaced(msg.sender, _queryId);
	}

	function modulusCallback(bytes32 _queryId, uint256, uint256 _result) external _checkRound {
		require(msg.sender == address(info.oracle));
		address _player = info.betInfo[_queryId];
		Round storage _currentRound = info.rounds[currentRoundIndex()];
		uint256 _timeDiff = _currentRound.targetTimestamp - block.timestamp;
		uint256 _delta = _timeDiff / (_currentRound.totalShares + 1);
		if (_result == 0) {
			_currentRound.totalShares++;
			_currentRound.roundPlayers[_player].shares++;
			_currentRound.roundPlayers[_player].scaledPayout += int256(_currentRound.scaledCumulativeKRILL);
			_currentRound.lastPlayers[2] = _currentRound.lastPlayers[1];
			_currentRound.lastPlayers[1] = _currentRound.lastPlayers[0];
			_currentRound.lastPlayers[0] = _player;
		} else {
			_delta /= 10;
		}
		uint256 _newTarget = _currentRound.targetTimestamp + _delta;
		_currentRound.targetTimestamp = _newTarget < block.timestamp + MAX_TIME ? _newTarget : block.timestamp + MAX_TIME;
		if (_currentRound.totalShares == 0) {
			_currentRound.jackpotValue += KRILL_COST_PER_FLIP;
		} else {
			_currentRound.jackpotValue += KRILL_COST_PER_FLIP / 2;
			_currentRound.scaledCumulativeKRILL += KRILL_COST_PER_FLIP * FLOAT_SCALAR / _currentRound.totalShares / 2;
		}
		emit BetResolved(_player, _queryId, currentRoundIndex(), _result == 0);
	}

	function queryFailed(bytes32 _queryId) external {
		require(msg.sender == address(info.oracle));
		address _player = info.betInfo[_queryId];
		info.krill.transfer(_player, KRILL_COST_PER_FLIP);
		emit BetFailed(_player, _queryId);
	}

	function withdrawRound(uint256 _round) public returns (uint256) {
		uint256 _withdrawable = roundDividendsOf(msg.sender, _round);
		if (_withdrawable > 0) {
			info.rounds[_round].roundPlayers[msg.sender].scaledPayout += int256(_withdrawable * FLOAT_SCALAR);
		}
		if (_round != currentRoundIndex()) {
			uint256 _jackpotPrize = roundJackpotValue(_round);
			address[3] memory _lastPlayers = roundLastPlayers(_round);
			if (_lastPlayers[0] == msg.sender) {
				_withdrawable += _jackpotPrize / 2;
				info.rounds[_round].lastPlayers[0] = address(0x0);
			}
			if (_lastPlayers[1] == msg.sender) {
				_withdrawable += _jackpotPrize / 3;
				info.rounds[_round].lastPlayers[1] = address(0x0);
			}
			if (_lastPlayers[2] == msg.sender) {
				_withdrawable += _jackpotPrize / 6;
				info.rounds[_round].lastPlayers[2] = address(0x0);
			}
		}
		if (_withdrawable > 0) {
			info.krill.transfer(msg.sender, _withdrawable);
			emit Withdraw(msg.sender, _round, _withdrawable);
		}
		return _withdrawable;
	}

	function withdrawCurrent() external returns (uint256) {
		return withdrawRound(currentRoundIndex());
	}

	function withdrawAll() external _checkRound returns (uint256) {
		uint256 _withdrawn = 0;
		for (uint256 i = 0; i < info.totalRounds; i++) {
			_withdrawn += withdrawRound(i);
		}
		return _withdrawn;
	}


	function owner() public view returns (address) {
		return info.owner;
	}

	function currentRoundIndex() public view returns (uint256) {
		return info.totalRounds - 1;
	}

	function roundTargetTimestamp(uint256 _round) public view returns (uint256) {
		return info.rounds[_round].targetTimestamp;
	}

	function roundJackpotValue(uint256 _round) public view returns (uint256) {
		return info.rounds[_round].jackpotValue;
	}

	function roundTotalShares(uint256 _round) public view returns (uint256) {
		return info.rounds[_round].totalShares;
	}

	function roundLastPlayers(uint256 _round) public view returns (address[3] memory) {
		return info.rounds[_round].lastPlayers;
	}

	function roundSharesOf(address _player, uint256 _round) public view returns (uint256) {
		return info.rounds[_round].roundPlayers[_player].shares;
	}

	function roundDividendsOf(address _player, uint256 _round) public view returns (uint256) {
		return uint256(int256(info.rounds[_round].scaledCumulativeKRILL * roundSharesOf(_player, _round)) - info.rounds[_round].roundPlayers[_player].scaledPayout) / FLOAT_SCALAR;
	}

	function roundWithdrawableOf(address _player, uint256 _round) public view returns (uint256) {
		uint256 _withdrawable = roundDividendsOf(_player, _round);
		if (_round != currentRoundIndex()) {
			uint256 _jackpotPrize = roundJackpotValue(_round);
			address[3] memory _lastPlayers = roundLastPlayers(_round);
			if (_lastPlayers[0] == _player) {
				_withdrawable += _jackpotPrize / 2;
			}
			if (_lastPlayers[1] == _player) {
				_withdrawable += _jackpotPrize / 3;
			}
			if (_lastPlayers[2] == _player) {
				_withdrawable += _jackpotPrize / 6;
			}
		}
		return _withdrawable;
	}

	function allWithdrawableOf(address _player) public view returns (uint256) {
		uint256 _withdrawable = 0;
		for (uint256 i = 0; i < info.totalRounds; i++) {
			_withdrawable += roundWithdrawableOf(_player, i);
		}
		return _withdrawable;
	}

	function allRoundInfoFor(address _player, uint256 _round) public view returns (uint256[4] memory compressedRoundInfo, address[3] memory roundLasts, uint256 playerBalance, uint256 playerAllowance, uint256[3] memory compressedPlayerRoundInfo) {
		return (_compressedRoundInfo(_round), roundLastPlayers(_round), info.krill.balanceOf(_player), info.krill.allowance(_player, address(this)), _compressedPlayerRoundInfo(_player, _round));
	}

	function allCurrentInfoFor(address _player) public view returns (uint256[4] memory compressedInfo, address[3] memory lastPlayers, uint256 playerBalance, uint256 playerAllowance, uint256[3] memory compressedPlayerRoundInfo) {
		return allRoundInfoFor(_player, currentRoundIndex());
	}


	function _newRound() internal {
		Round storage _round = info.rounds[info.totalRounds++];
		_round.targetTimestamp = block.timestamp + MAX_TIME;
		emit RoundStarted(currentRoundIndex());
	}


	function _compressedRoundInfo(uint256 _round) internal view returns (uint256[4] memory data) {
		data[0] = block.number;
		data[1] = roundTargetTimestamp(_round);
		data[2] = roundJackpotValue(_round);
		data[3] = roundTotalShares(_round);
	}

	function _compressedPlayerRoundInfo(address _player, uint256 _round) internal view returns (uint256[3] memory data) {
		data[0] = roundSharesOf(_player, _round);
		data[1] = roundWithdrawableOf(_player, _round);
		data[2] = allWithdrawableOf(_player);
	}
}