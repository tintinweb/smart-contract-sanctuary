pragma solidity ^0.4.18;

contract Random {
  uint256 _seed;

  function maxRandom() public returns (uint256 randomNumber) {
    _seed = uint256(keccak256(
        _seed,
        block.blockhash(block.number - 1),
        block.coinbase,
        block.difficulty
    ));
    return _seed;
  }

  // return a pseudo random number between lower and upper bounds
  // given the number of previous blocks it should hash.
  function random(uint256 upper) public returns (uint256 randomNumber) {
    return maxRandom() % upper;
  }
}

contract Lottery is Random {

	struct Stage {
		uint32 maxNum;
		bytes32 participantsHash;
		uint winnerNum;
	}
	mapping (uint32 => Stage) public stages;
	address public owner;

	event Winner(uint32 _stageNum, uint _winnerNum);

	modifier onlyOwner() { require(msg.sender == owner); _;}

	constructor() public {
        owner = msg.sender;
    }

	function randomJackpot(uint32 _stageNum, bytes32 _participantsHash, uint32 _maxNum) external onlyOwner {
		require(_maxNum > 0);
		uint winnerNum = random(_maxNum);
		stages[_stageNum] = Stage(_maxNum, _participantsHash, winnerNum);
		emit Winner(_stageNum, winnerNum);
	}
}