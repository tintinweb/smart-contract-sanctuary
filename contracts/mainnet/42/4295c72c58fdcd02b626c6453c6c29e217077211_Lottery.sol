pragma solidity 0.4.24;

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract Lottery is Owned {
    string constant version = "1.0.0";

    address admin;

    mapping (uint => Game) public games;

    mapping (uint => mapping (address => Ticket[])) public tickets;

    mapping (address => uint) public withdrawGameIndex;

    mapping (address => uint) allowed;

    uint public gameIndex;

    uint public goldKeyJackpot;

    uint public firstPrizeJackpot;

    uint public bonusJackpot;

    uint public nextPrice;

    bool public buyEnable = true;

    mapping(bytes32 => uint) keys;

    uint currentMappingVersion;

    struct Ticket {
        address user;
        uint[] numbers;
        uint buyTime;
    }

    struct Game {
        uint startTime;
        uint price;
        uint ticketIndex;
        uint[] winNumbers;
        uint goldKey;
        uint blockIndex;
        string blockHash;
        uint averageBonus;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function depositOwnership(address admin_) public onlyOwner {
        require(admin_ != address(0));
        admin = admin_;
    }

    constructor() public {
        nextPrice = 0.01 ether;
        games[0].price = nextPrice;
        games[0].startTime = now;
    }

    function() public payable {
        require(buyEnable);
        require(address(this) != msg.sender);
        require(msg.data.length > 9);
        require(msg.data.length % 9 == 1);
        Game storage game = games[gameIndex];
        uint count = uint(msg.data[0]);
        require(msg.value == count * game.price);
        Ticket[] storage tickets_ = tickets[gameIndex][msg.sender];
        uint goldCount = 0;
        uint i = 1;
        while(i < msg.data.length) {
            uint[] memory number_ = new uint[](9);
            for(uint j = 0; j < 9; j++) {
                number_[j] = uint(msg.data[i++]);
            }
            goldCount += number_[1];
            tickets_.push(Ticket(msg.sender, number_, now));
            game.ticketIndex++;
        }
        if(goldCount > 0) {
            uint goldKey_ = getKeys(msg.sender);
            require(goldKey_ >= goldCount);
            goldKey_ -= goldCount;
            bytes32 key = keccak256(abi.encodePacked(currentMappingVersion, msg.sender));
            keys[key] = goldKey_;
        }
        uint amount = msg.value * 4 / 10;
        firstPrizeJackpot += amount;
        bonusJackpot += amount;
        goldKeyJackpot += amount;
        if(goldKeyJackpot >= 1500 ether) {
            game.goldKey++;
            goldKeyJackpot -= 1500 ether;
        }
        emit LogBuyTicket(gameIndex, msg.sender, msg.data, firstPrizeJackpot, bonusJackpot);
    }

    function getWinNumbers(string blockHash) public pure returns (uint[]){
        bytes32 random = keccak256(bytes(blockHash));
        uint[] memory allRedNumbers = new uint[](40);
        uint[] memory allBlueNumbers = new uint[](10);
        uint[] memory winNumbers = new uint[](6);
        for (uint i = 0; i < 40; i++) {
            allRedNumbers[i] = i + 1;
            if(i < 10) {
                allBlueNumbers[i] = i;
            }
        }
        for (i = 0; i < 5; i++) {
            uint n = 40 - i;
            uint r = (uint(random[i * 4]) + (uint(random[i * 4 + 1]) << 8) + (uint(random[i * 4 + 2]) << 16) + (uint(random[i * 4 + 3]) << 24)) % (n + 1);
            winNumbers[i] = allRedNumbers[r];
            allRedNumbers[r] = allRedNumbers[n - 1];
        }
        uint t = (uint(random[i * 4]) + (uint(random[i * 4 + 1]) << 8) + (uint(random[i * 4 + 2]) << 16) + (uint(random[i * 4 + 3]) << 24)) % 10;
        winNumbers[5] = allBlueNumbers[t];
        return winNumbers;
    }

    function getTicketsByGameIndex(uint gameIndex_) public view returns (uint[] tickets_){
        Ticket[] storage ticketArray = tickets[gameIndex_][msg.sender];
        tickets_ = new uint[](ticketArray.length * 12);
        uint k;
        for(uint i = 0; i < ticketArray.length; i++) {
            Ticket storage ticket = ticketArray[i];
            tickets_[k++] = i;
            tickets_[k++] = ticket.buyTime;
            tickets_[k++] = games[gameIndex_].price;
            for (uint j = 0; j < 9; j++)
                tickets_[k++] = ticket.numbers[j];
        }
    }

    function getGameByIndex(uint _gameIndex, bool lately) public view returns (uint[] res){
        if(lately) _gameIndex = gameIndex;
        if(_gameIndex > gameIndex) return res;
        res = new uint[](15);
        Game storage game = games[_gameIndex];
        uint k;
        res[k++] = _gameIndex;
        res[k++] = game.startTime;
        res[k++] = game.price;
        res[k++] = game.ticketIndex;
        res[k++] = bonusJackpot;
        res[k++] = firstPrizeJackpot;
        res[k++] = game.blockIndex;
        if (game.winNumbers.length == 0) {
            for (uint j = 0; j < 6; j++)
                res[k++] = 0;
        } else {
            for (j = 0; j < 6; j++)
                res[k++] = game.winNumbers[j];
        }
        res[k++] = game.goldKey;
        res[k++] = game.averageBonus;
    }

//    function getGames(uint offset, uint count) public view returns (uint[] res){
//        if (offset > gameIndex) return res;
//        uint k;
//        uint n = offset + count;
//        if (n > gameIndex + 1) n = gameIndex + 1;
//        res = new uint[]((n - offset) * 15);
//        for(uint i = offset; i < n; i++) {
//            Game storage game = games[i];
//            res[k++] = i;
//            res[k++] = game.startTime;
//            res[k++] = game.price;
//            res[k++] = game.ticketIndex;
//            res[k++] = bonusJackpot;
//            res[k++] = firstPrizeJackpot;
//            res[k++] = game.blockIndex;
//            if (game.winNumbers.length == 0) {
//                for (uint j = 0; j < 6; j++)
//                    res[k++] = 0;
//            } else {
//                for (j = 0; j < 6; j++)
//                    res[k++] = game.winNumbers[j];
//            }
//            res[k++] = game.goldKey;
//            res[k++] = game.averageBonus;
//        }
//    }

    function stopCurrentGame(uint blockIndex) public onlyOwner {
        Game storage game = games[gameIndex];
        buyEnable = false;
        game.blockIndex = blockIndex;
        emit LogStopCurrentGame(gameIndex, blockIndex);
    }

    function drawNumber(uint blockIndex, string blockHash) public onlyOwner returns (uint[] res){
        Game storage game = games[gameIndex];
        require(game.blockIndex > 0);
        require(blockIndex > game.blockIndex);
        game.blockIndex = blockIndex;
        game.blockHash = blockHash;
        game.winNumbers = getWinNumbers(blockHash);
        emit LogDrawNumbers(gameIndex, blockIndex, blockHash, game.winNumbers);
        res = game.winNumbers;
    }

    function drawReuslt(uint goldCount, address[] goldKeys, address[] jackpots, uint _jackpot, uint _bonus, uint _averageBonus) public onlyOwner {
        firstPrizeJackpot -= _jackpot;
        bonusJackpot -= _bonus;
        Game storage game = games[gameIndex];
        if(jackpots.length > 0 && _jackpot > 0) {
            deleteAllReports();
            uint amount = _jackpot / jackpots.length;
            for(uint j = 0; j < jackpots.length; j++) {
                allowed[jackpots[j]] += amount;
            }
        } else {
            for(uint i = 0; i < goldKeys.length; i++) {
                game.goldKey += goldCount;
                rewardKey(goldKeys[i], 1);
            }
        }
        game.averageBonus = _averageBonus;
        emit LogDrawReuslt(gameIndex, goldCount, goldKeys, jackpots, _jackpot, _bonus, _averageBonus);
    }

    function getAllowed(address _address) public onlyOwner view returns(uint) {
        return allowed[_address];
    }

    function withdraw() public payable {
        uint amount = allowance();
        require(amount >= 0.05 ether);
        withdrawGameIndex[msg.sender] = gameIndex;
        allowed[msg.sender] = 0;
        msg.sender.transfer(amount);
        emit LogTransfer(gameIndex, msg.sender, amount);
    }

    function allowance() public view returns (uint amount) {
        uint gameIndex_ = withdrawGameIndex[msg.sender];
        if(gameIndex_ == gameIndex) return amount;
        require(gameIndex_ < gameIndex);
        amount += allowed[msg.sender];
        for(uint i = gameIndex_; i < gameIndex; i++) {
            Game storage game = games[i];
            Ticket[] storage tickets_ = tickets[i][msg.sender];
            for(uint j = 0; j < tickets_.length; j++) {
                Ticket storage ticket = tickets_[j];
                if(game.winNumbers[5] != ticket.numbers[8]) {
                    amount += game.averageBonus * ticket.numbers[2];
                }
            }
        }
    }

    function startNextGame() public onlyOwner {
        buyEnable = true;
        gameIndex++;
        games[gameIndex].startTime = now;
        games[gameIndex].price = nextPrice;
        emit LogStartNextGame(gameIndex);
    }

    function addJackpotGuaranteed(uint addJackpot) public onlyOwner {
        firstPrizeJackpot += addJackpot;
    }

    function rewardKey(address _user, uint gold) public onlyOwner {
        uint goldKey = getKeys(_user);
        goldKey += gold;
        setKeys(_user, goldKey);
        emit LogRewardKey(_user, gold);
    }

    function getKeys(address _key) public view returns(uint) {
        bytes32 key = keccak256(abi.encodePacked(currentMappingVersion, _key));
        return keys[key];
    }

    function setKeys(address _key, uint _value) private onlyOwner {
        bytes32 key = keccak256(abi.encodePacked(currentMappingVersion, _key));
        keys[key] = _value;
    }

    function deleteAllReports() public onlyOwner {
        Game storage game = games[gameIndex];
        game.goldKey = 0;
        currentMappingVersion++;
        emit LogDeleteAllReports(gameIndex, currentMappingVersion);
    }

    function killContract() public onlyOwner {
        selfdestruct(msg.sender);
        emit LogKillContract(msg.sender);
    }

    function setPrice(uint price) public onlyOwner {
        nextPrice = price;
        emit LogSetPrice(price);
    }

    function setBuyEnable(bool _buyEnable) public onlyOwner {
        buyEnable = _buyEnable;
        emit LogSetBuyEnable(msg.sender, _buyEnable);
    }

    function adjustPrizePoolAfterWin(uint _jackpot, uint _bonus) public onlyOwner {
        firstPrizeJackpot -= _jackpot;
        bonusJackpot -= _bonus;
        emit LogAdjustPrizePoolAfterWin(gameIndex, _jackpot, _bonus);
    }

    function transferToOwner(uint bonus) public payable onlyOwner {
        msg.sender.transfer(bonus);
        emit LogTransfer(gameIndex, msg.sender, bonus);
    }

    event LogBuyTicket(uint indexed _gameIndex, address indexed from, bytes numbers, uint _firstPrizeJackpot, uint _bonusJackpot);
    event LogRewardKey(address indexed _user, uint _gold);
    event LogAwardWinner(address indexed _user, uint[] _winner);
    event LogStopCurrentGame(uint indexed _gameIndex, uint indexed _blockIndex);
    event LogDrawNumbers(uint indexed _gameIndex, uint indexed _blockIndex, string _blockHash, uint[] _winNumbers);
    event LogStartNextGame(uint indexed _gameIndex);
    event LogDeleteAllReports(uint indexed _gameIndex, uint _currentMappingVersion);
    event LogKillContract(address indexed _owner);
    event LogSetPrice(uint indexed _price);
    event LogSetBuyEnable(address indexed _owner, bool _buyEnable);
    event LogTransfer(uint indexed _gameIndex, address indexed from, uint value);
    event LogApproval(address indexed _owner, address indexed _spender, uint256 _value);
    event LogAdjustPrizePoolAfterWin(uint indexed _gameIndex, uint _jackpot, uint _bonus);
    event LogDrawReuslt(uint indexed _gameIndex, uint _goldCount, address[] _goldKeys, address[] _jackpots, uint _jackpot, uint _bonus, uint _averageBonus);
}