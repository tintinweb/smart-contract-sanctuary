pragma solidity ^0.4.20;

contract LotteryGenerator {
    address[] public lotteries;
    struct lottery {
        uint256 index;
        address manager;
        string createdAt;
    }
    mapping(address => lottery) lotteryStructs;

    function createLottery(string name, string createdAt) public {
        require(bytes(name).length > 0);
        address newLottery = new Lottery(name, msg.sender, createdAt);
        lotteryStructs[newLottery].index = lotteries.push(newLottery) - 1;
        lotteryStructs[newLottery].manager = msg.sender;
        lotteryStructs[newLottery].createdAt = createdAt;

        // event
        LotteryCreated(newLottery);
    }

    function getLotteries() public view returns (address[]) {
        return lotteries;
    }

    function deleteLottery(address lotteryAddress) public {
        require(msg.sender == lotteryStructs[lotteryAddress].manager);
        uint256 indexToDelete = lotteryStructs[lotteryAddress].index;
        address lastAddress = lotteries[lotteries.length - 1];
        lotteries[indexToDelete] = lastAddress;
        lotteries.length--;
    }

    // Events
    event LotteryCreated(address lotteryAddress);
}

contract Lottery {
    // name of the lottery
    string public lotteryName;
    // Creator of the lottery contract
    address public manager;

    string public createdAt;

    // variables for players
    struct Player {
        string name;
        uint256 entryCount;
        uint256 index;
    }
    address[] public addressIndexes;
    mapping(address => Player) players;
    address[] public lotteryBag;

    // Variables for lottery information
    Player public winner;
    bool public isLotteryLive;
    uint256 public maxEntriesForPlayer;
    uint256 public ethToParticipate;

    // constructor
    function Lottery(
        string name,
        address creator,
        string created
    ) public {
        manager = creator;
        lotteryName = name;
        createdAt = created;
    }

    // Let users participate by sending eth directly to contract address
    function() public payable {
        // player name will be unknown
        participate("Unknown");
    }

    function participate(string playerName) public payable {
        require(bytes(playerName).length > 0);
        require(isLotteryLive);
        require(msg.value == ethToParticipate * 1 wei);
        require(players[msg.sender].entryCount < maxEntriesForPlayer);

        if (isNewPlayer(msg.sender)) {
            players[msg.sender].entryCount = 1;
            players[msg.sender].name = playerName;
            players[msg.sender].index = addressIndexes.push(msg.sender) - 1;
        } else {
            players[msg.sender].entryCount += 1;
        }

        lotteryBag.push(msg.sender);

        // event
        PlayerParticipated(
            players[msg.sender].name,
            players[msg.sender].entryCount
        );
    }

    function activateLottery(uint256 maxEntries, uint256 ethRequired)
        public
        restricted
    {
        isLotteryLive = true;
        maxEntriesForPlayer = maxEntries == 0 ? 1 : maxEntries;
        ethToParticipate = ethRequired == 0 ? 1 : ethRequired;
    }

    function declareWinner() public restricted {
        require(lotteryBag.length > 0);

        uint256 index = generateRandomNumber() % lotteryBag.length;
        lotteryBag[index].transfer(this.balance);

        winner.name = players[lotteryBag[index]].name;
        winner.entryCount = players[lotteryBag[index]].entryCount;

        // empty the lottery bag and indexAddresses
        lotteryBag = new address[](0);
        addressIndexes = new address[](0);

        // Mark the lottery inactive
        isLotteryLive = false;

        // event
        WinnerDeclared(winner.name, winner.entryCount);
    }

    function getPlayers() public view returns (address[]) {
        return addressIndexes;
    }

    function getPlayer(address playerAddress)
        public
        view
        returns (string, uint256)
    {
        if (isNewPlayer(playerAddress)) {
            return ("", 0);
        }
        return (players[playerAddress].name, players[playerAddress].entryCount);
    }

    function getWinningPrice() public view returns (uint256) {
        return this.balance;
    }

    // Private functions
    function isNewPlayer(address playerAddress) private view returns (bool) {
        if (addressIndexes.length == 0) {
            return true;
        }
        return (addressIndexes[players[playerAddress].index] != playerAddress);
    }

    // NOTE: This should not be used for generating random number in real world
    function generateRandomNumber() private view returns (uint256) {
        return uint256(keccak256(block.difficulty, now, lotteryBag));
    }

    // Modifiers
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    // Events
    event WinnerDeclared(string name, uint256 entryCount);
    event PlayerParticipated(string name, uint256 entryCount);
}