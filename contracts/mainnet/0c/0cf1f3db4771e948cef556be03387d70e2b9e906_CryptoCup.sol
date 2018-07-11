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

contract CryptoCup is Random {

    uint32 public maxNum;
    address public owner;

    event Winner(uint _winnerNum);

    modifier onlyOwner() {require(msg.sender == owner);
        _;}

    constructor() public {
        owner = msg.sender;
    }

    function updateMaxNum(uint32 _num) external onlyOwner {
        maxNum = _num;
    }

    function randomJackpot() external onlyOwner {
        uint winnerNum = random(maxNum);
        emit Winner(winnerNum);
    }
}