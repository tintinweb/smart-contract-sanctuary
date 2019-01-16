pragma solidity ^0.4.24;

contract TwoUp {

    address public creator;
    bytes32 public creatorSeedHash;
    bytes32 public creatorSeed;

    address public taker;
    bytes32 public takerSeedHash;
    bytes32 public takerSeed;

    uint256 public bet;
    bool public isHeads;

    bool public betAccepted;
    bool public seedsRevealed;

    uint256 public firstReveal;
    address public firstRevealer;
    uint256 constant public timeout = 15 minutes;

    address public winner;
    bool public expired;

    constructor(bytes32 _creatorSeedHash, bool _isHeads) payable public {
        require(msg.value > 0.01 ether);
        bet = msg.value;
        isHeads = _isHeads;
        creator = msg.sender;
        creatorSeedHash = _creatorSeedHash;
    }

    function takeBet(bytes32 _takerSeedHash) public payable {
        require(msg.sender != creator);
        require(!betAccepted);
        require(msg.value == bet, "bet must be matched");
        taker = msg.sender;
        takerSeedHash = _takerSeedHash;
        betAccepted = true;
    }

    function toHash(string t) view returns(bytes32) {
        return keccak256(stringToBytes32(t));
    }
    
    function toBytes(string t) view returns(bytes32) {
        return stringToBytes32(t);
    }

    function revealBet(string _seed) public {
        require(betAccepted && !seedsRevealed);
        bytes32 seed = stringToBytes32(_seed);

        if(msg.sender == creator) {
            require(creatorSeedHash == keccak256(seed));
            creatorSeed = seed;
        } else if(msg.sender == taker) {
            require(takerSeedHash == keccak256(seed));
            takerSeed = seed;
        } else {
            revert("only creator or taker can participate");
        }

        //start the timer
        if(firstReveal == 0) {
            firstReveal = now;
            firstRevealer = msg.sender;
        }

        //if both parties revealed
        if(creatorSeed != 0 && takerSeed != 0) {
            seedsRevealed = true;
        }
    }

    function withdraw() public {
        require(!seedsRevealed);
        require(firstReveal + timeout < now);
        uint256 reward = address(this).balance;
        firstRevealer.transfer(reward);
        expired = true;
        emit Expired(firstRevealer, reward);
    }

    function coinFlip() public returns (uint) {
        require(seedsRevealed && winner == address(0));
        uint random = uint(keccak256(uint(creatorSeed) + uint(takerSeed) + block.number)) % 4;

        //headsheads
        if(random == 0) {
            if (isHeads) {
                winner = creator;
            } else {
                winner = taker;
            }
        //tailstails
        } else if (random == 3){
            if (!isHeads) {
                winner = creator;
            } else {
                winner = taker;
            }
        }

        if(winner != address(0)){
            uint256 reward = address(this).balance;
            winner.transfer(reward);
            emit Winner(winner, reward);
        }

        return random;
    }

function stringToBytes32(string memory source) returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}

    event Winner(address winner, uint256 reward);
    event Expired(address winner, uint256 reward);
}