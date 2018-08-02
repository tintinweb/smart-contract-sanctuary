pragma solidity ^0.4.24;

contract MajorityGameFactory {

    address[] public deployedGames;
    address[] public endedGames;
    address[] public tempArray;

    address public adminAddress;

    mapping(address => uint) private gameAddressIdMap;

    uint public gameCount = 0;
    uint public endedGameCount = 0;

    modifier adminOnly() {
        require(msg.sender == adminAddress);
        _;
    }

    constructor () public {
        adminAddress = msg.sender;
    }

    /**
     * create new game
     **/
    function createGame (uint _gameBet, uint _startTime, string _questionText, address _officialAddress) public adminOnly payable {
        gameCount ++;
        address newGameAddress = new MajorityGame(gameCount, _gameBet, _startTime, _questionText, _officialAddress);
        deployedGames.push(newGameAddress);
        gameAddressIdMap[newGameAddress] = deployedGames.length;

        setJackpot(newGameAddress, msg.value);
    }

    /**
     * return all available games address
     **/
    function getDeployedGames() public view returns (address[]) {
        return deployedGames;
    }

    /**
     * return all available games address
     **/
    function getEndedGames() public view returns (address[]) {
        return endedGames;
    }

    /**
     * set bonus of the game
     **/
    function setJackpot(address targetAddress, uint val) adminOnly public {
        if (val > 0) {
            MajorityGame mGame = MajorityGame(targetAddress);
            mGame.setJackpot.value(val)();
        }
    }

    /**
     * end the game
     **/
    function endGame(address targetAddress) public {
        uint targetGameIndex = gameAddressIdMap[address(targetAddress)];
        endedGameCount++;
        endedGames.push(targetAddress);
        deployedGames[targetGameIndex-1] = deployedGames[deployedGames.length-1];

        gameAddressIdMap[deployedGames[deployedGames.length-1]] = targetGameIndex;

        delete deployedGames[deployedGames.length-1];
        deployedGames.length--;

        MajorityGame mGame = MajorityGame(address(targetAddress));
        mGame.endGame();
    }

    /**
     * force to end the game
     **/
    function forceEndGame(address targetAddress) public adminOnly {
        uint targetGameIndex = gameAddressIdMap[address(targetAddress)];
        endedGameCount++;
        endedGames.push(targetAddress);
        deployedGames[targetGameIndex-1] = deployedGames[deployedGames.length-1];

        gameAddressIdMap[deployedGames[deployedGames.length-1]] = targetGameIndex;

        delete deployedGames[deployedGames.length-1];
        deployedGames.length--;

        MajorityGame mGame = MajorityGame(address(targetAddress));
        mGame.forceEndGame();
    }
}


contract MajorityGame {

    // 1 minute
    //uint constant private AVAILABLE_GAME_TIME = 0;
    uint constant private MINIMUM_BET = 50000000000000000;
    uint constant private MAXIMUM_BET = 50000000000000000;

    uint public gameId;

    uint private jackpot;
    uint private gameBet;

    // address of the creator
    address public adminAddress;
    address public officialAddress;

    // game start time
    uint private startTime;

    // game data
    string private questionText;

    // store all player bet value
    mapping(address => bool) private playerList;
    uint public playersCount;

    // store all player option record
    mapping(address => bool) private option1List;
    mapping(address => bool) private option2List;

    // address list
    address[] private option1AddressList;
    address[] private option2AddressList;
    address[] private winnerList;

    uint private winnerSide;
    uint private finalBalance;
    uint private award;

    // count the player option
    //uint private option1Count;
    //uint private option2Count;
    modifier adminOnly() {
        require(msg.sender == adminAddress);
        _;
    }

    modifier withinGameTime() {
        require(now <= startTime);
        //require(now < startTime + AVAILABLE_GAME_TIME);
        _;
    }

    modifier afterGameTime() {
        require(now > startTime);
        //require(now > startTime + AVAILABLE_GAME_TIME);
        _;
    }

    modifier notEnded() {
        require(winnerSide == 0);
        _;
    }

    modifier isEnded() {
        require(winnerSide > 0);
        _;
    }

    constructor(uint _gameId, uint _gameBet, uint _startTime, string _questionText, address _officialAddress) public {
        gameId = _gameId;
        adminAddress = msg.sender;

        gameBet = _gameBet;
        startTime = _startTime;
        questionText = _questionText;

        playersCount = 0;
        winnerSide = 0;
        award = 0;

        officialAddress = _officialAddress;
    }
    /*
    function() public payable {
    }
    */
    /**
     * set the bonus of the game
     **/
    function setJackpot() public payable adminOnly returns (bool) {
        if (msg.value > 0) {
            jackpot += msg.value;
            return true;
        }
        return false;
    }

    /**
     * return the game data when playing
     * 0 start time
     * 1 end time
     * 2 no of player
     * 3 total bet
     * 4 jackpot
     * 5 is ended game boolean
     * 6 game bet value
     **/
    function getGamePlayingStatus() public view returns (uint, uint, uint, uint, uint, uint, uint) {
        return (
        startTime,
        startTime,
        //startTime + AVAILABLE_GAME_TIME,
        playersCount,
        address(this).balance,
        jackpot,
        winnerSide,
        gameBet
        );
    }

    /**
     * return the game details:
     * 0 game id
     * 1 start time
     * 2 end time
     * 3 no of player
     * 4 total bet
     * 5 question + option 1 + option 2
     * 6 jackpot
     * 7 is ended game
     * 8 game bet value
     **/
    function getGameData() public view returns (uint, uint, uint, uint, uint, string, uint, uint, uint) {
        return (
        gameId,
        startTime,
        startTime,
        //startTime + AVAILABLE_GAME_TIME,
        playersCount,
        address(this).balance,
        questionText,
        jackpot,
        winnerSide,
        gameBet
        );
    }

    /**
     * player submit their option
     **/
    function submitChoose(uint _chooseValue) public payable notEnded withinGameTime {
        require(!playerList[msg.sender]);
        require(msg.value == gameBet);

        playerList[msg.sender] = true;
        playersCount++;

        if (_chooseValue == 1) {
            option1List[msg.sender] = true;
            option1AddressList.push(msg.sender);
        } else if (_chooseValue == 2) {
            option2List[msg.sender] = true;
            option2AddressList.push(msg.sender);
        }
    }

    /**
     * calculate the winner side
     * calculate the award to winner
     **/
    function endGame() public afterGameTime {
        require(winnerSide == 0);

        // 10% for operation fee
        finalBalance = address(this).balance;

        uint totalAward = uint(finalBalance * 9 / 10);

        uint option1Count = option1AddressList.length;
        uint option2Count = option2AddressList.length;

        if (option1Count > option2Count || (option1Count == option2Count && gameId % 2 == 1)) { // option1 win
            award = option1Count == 0 ? 0 : uint(totalAward / option1Count);
            winnerSide = 1;
            winnerList = option1AddressList;
        } else if (option2Count > option1Count || (option1Count == option2Count && gameId % 2 == 0)) { // option2 win
            award = option2Count == 0 ? 0 : uint(totalAward / option2Count);
            winnerSide = 2;
            winnerList = option2AddressList;
        }
    }

    /**
     * calculate the winner side
     * calculate the award to winner
     **/
    function forceEndGame() public adminOnly {
        require(winnerSide == 0);
        // 10% for operation fee
        finalBalance = address(this).balance;

        uint totalAward = uint(finalBalance * 9 / 10);

        uint option1Count = option1AddressList.length;
        uint option2Count = option2AddressList.length;

        if (option1Count > option2Count || (option1Count == option2Count && gameId % 2 == 1)) { // option1 win
            award = option1Count == 0 ? 0 : uint(totalAward / option1Count);
            winnerSide = 1;
            winnerList = option1AddressList;
        } else if (option2Count > option1Count || (option1Count == option2Count && gameId % 2 == 0)) { // option2 win
            award = option2Count == 0 ? 0 : uint(totalAward / option2Count);
            winnerSide = 2;
            winnerList = option2AddressList;
        }
    }

    /**
     * send award to winner
     **/
    function sendAward() public isEnded {
        require(winnerList.length > 0);

        uint count = winnerList.length;

        if (count > 250) {
            for (uint i = 0; i < 250; i++) {
                this.sendAwardToLastWinner();
            }
        } else {
            for (uint j = 0; j < count; j++) {
                this.sendAwardToLastWinner();
            }
        }
    }

    /**
     * send award to last winner of the list
     **/
    function sendAwardToLastWinner() public isEnded {
        address(winnerList[winnerList.length - 1]).transfer(award);

        delete winnerList[winnerList.length - 1];
        winnerList.length--;

        if(winnerList.length == 0){
          address add=address(officialAddress);
          address(add).transfer(address(this).balance);
        }
    }

    /**
     * return the game details after ended
     * 0 winner side
     * 1 nomber of player who choose option 1
     * 2 nomber of player who choose option 2
     * 3 total award
     * 4 award of each winner
     **/
    function getEndGameStatus() public isEnded view returns (uint, uint, uint, uint, uint) {
        return (
            winnerSide,
            option1AddressList.length,
            option2AddressList.length,
            finalBalance,
            award
        );
    }

    /**
    * get the option os the player choosed
    **/
    function getPlayerOption() public view returns (uint) {
        if (option1List[msg.sender]) {
            return 1;
        } else if (option2List[msg.sender]) {
            return 2;
        } else {
            return 0;
        }
    }

    /**
     * return the players who won the game
     **/
    function getWinnerAddressList() public isEnded view returns (address[]) {
      if (winnerSide == 1) {
        return option1AddressList;
      }else {
        return option2AddressList;
      }
    }

    /**
     * return the players who won the game
     **/
    function getLoserAddressList() public isEnded view returns (address[]) {
      if (winnerSide == 1) {
        return option2AddressList;
      }else {
        return option1AddressList;
      }
    }

    /**
     * return winner list
     **/
    function getWinnerList() public isEnded view returns (address[]) {
        return winnerList;
    }

    /**
     * return winner list size
     **/
    function getWinnerListLength() public isEnded view returns (uint) {
        return winnerList.length;
    }
}