pragma solidity ^0.4.18;

// File: contracts/Bet0xgameMaster.sol

interface OraclizeResolverI {
    function remoteSetWinner(uint _gameId, string _oraclizeSource, uint _callback_wei, uint _callback_gas_limit) external;
    function eventSetWinner(uint _gameId, address _verityAddress, uint _verityResultIndex) external;
}


contract Bet0xgameMaster {
    address public owner;
    address public resolverAddress;

    mapping(bool => uint) boolMapping;

    string constant draw = "draw";

    uint public totalBetPool;

    struct PlayerBet {
        uint betAmount;
        uint team;
        bool withdrawn;
    }

    struct PlayerData {
        uint totalBetAmount;
        uint totalWithdrawn;
    }
    mapping(address => PlayerData) playerData;

    struct Game {
        uint WINNER;
        uint loserOne;
        uint loserTwo;
        string teamOne;
        string teamTwo;

        string description;
        string oddsApi;

        string oraclizeSource;

        address verityAddress;
        uint verityResultIndex;

        bytes32 category;
        bytes32 subcategory;

        uint betsCloseAt;
        uint endsAt;

        uint gameId;
        uint balance;
        uint totalPool;

        bool drawPossible;

        uint withdrawAfter;

        mapping(uint => mapping(address => uint)) book;
        mapping(uint => uint) oddsMapping;
        mapping(string => uint) teamMapping;
        mapping(address => mapping(uint => PlayerBet)) playerBets;
    }
    Game[] game;

    /// Events
    event PlayerJoined(
        uint indexed gameId,
        address indexed playerAddress,
        uint betAmount,
        uint team
    );

    event RewardWithdrawn(
        uint indexed gameId,
        address indexed withdrawer,
        uint withdrawnAmount
    );

    event WinningTeamSet(
        uint indexed gameId,
        string team
    );

    event NewGame(
        uint indexed gameId,
        string teamOne,
        string teamTwo,
        uint betsCloseAt
    );

    event BetFailed(
        uint indexed gameId,
        address indexed playerAddress,
        uint betAmount,
        uint team
    );

    event GameInvalidated(
        uint gameId
    );

    /// Modifiers
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can do this"
        );
        _;
    }

    modifier onlyValidTeamName(uint _gameId, string _team) {
        require(
            keccak256(bytes(_team)) == keccak256(bytes(game[_gameId].teamOne)) ||
            keccak256(bytes(_team)) == keccak256(bytes(game[_gameId].teamTwo)) ||
            keccak256(bytes(_team)) == keccak256(bytes(draw)),
            "Not a valid team name for game."
        );
        _;
    }

    modifier onlyValidTeam(uint _team) {
        require(
            _team > 0 &&
            _team <= 3,
            "Not a valid team identifier."
        );
        _;
    }

    modifier onlyAfterEndTime(uint _gameId) {
        require(
            now >= game[_gameId].endsAt,
            "Game not ended yet."
        );
        _;
    }

    modifier onlyAfterWithdrawTime(uint _gameId) {
        require(
            now >= game[_gameId].withdrawAfter,
            "Can&#39;t withdraw remaining rewards yet."
        );
        _;
    }

    modifier onlyIfGameValid(uint _gameId) {
        require(
            game[_gameId].betsCloseAt > 0,
            "Game not valid"
        );
        _;
    }

    modifier onlyIfWinnerIsMissing(uint _gameId) {
        require(
            game[_gameId].WINNER == 0,
            "Winner already set."
        );
        _;
    }

    modifier onlyIfWinnerIsSet(uint _gameId) {
        require(
            game[_gameId].WINNER != 0,
            "Winner not set."
        );
        _;
    }

    modifier endsAtAfterBetsCloseAt(uint _betsCloseAt, uint _endsAt) {
        require(
            _betsCloseAt < _endsAt,
            "Bets can&#39;t close after game ends."
        );
        _;
    }

    modifier onlyBeforeBetsCloseAt(uint _gameId) {
        require(
            now < game[_gameId].betsCloseAt,
            "Bets already closed."
        );
        _;
    }

    modifier onlyResolver {
        require(
            msg.sender == resolverAddress || msg.sender == address(this),
            "Only resolver can do this"
        );
        _;
    }

    /// Constructor
    constructor(address _resolverAddress) public {
        owner = msg.sender;
        resolverAddress = _resolverAddress;

        buildBoolMapping();
    }

    /// Public functions
    function createGame(
        string _teamOne,
        string _teamTwo,
        uint _endsAt,
        uint _betsCloseAt,
        string _oraclizeSource,
        address _verityAddress,
        uint _verityResultIndex,
        string _oddsApi,
        bytes32[2] _categories,
        bool _drawPossible,
        string _description
    )
        public
        onlyOwner
        endsAtAfterBetsCloseAt(_betsCloseAt, _endsAt)
    {
        Game memory _game;

        _game.gameId = game.length;
        _game.teamOne = _teamOne;
        _game.teamTwo = _teamTwo;
        _game.betsCloseAt = _betsCloseAt;
        _game.endsAt = _endsAt;
        _game.oddsApi = _oddsApi;
        _game.category = _categories[0];
        _game.subcategory = _categories[1];
        _game.drawPossible = _drawPossible;
        _game.description = _description;
        _game.verityAddress = _verityAddress;
        _game.verityResultIndex = _verityResultIndex;
        _game.oraclizeSource = _oraclizeSource;

        _game.withdrawAfter = _endsAt + 1 weeks;

        game.push(_game);

        buildTeamMapping(_game.gameId);

        emit NewGame(
            _game.gameId,
            _teamOne,
            _teamTwo,
            _betsCloseAt
        );
    }

    function getGameLength() public view returns(uint) {
        return game.length;
    }

    function getGame(uint _gameId) public view returns(string, string, bool, uint, uint, uint, uint, string, string) {
        Game storage _game = game[_gameId];

        return (
            _game.teamOne,
            _game.teamTwo,
            _game.drawPossible,
            _game.WINNER,
            _game.betsCloseAt,
            _game.endsAt,
            _game.totalPool,
            _game.oddsApi,
            _game.description
        );
    }

    // Returns only first 32 characters of each team&#39;s name
    function getGames(uint[] _gameIds) public view returns(
        uint[], bytes32[], bytes32[], bool[], uint[], uint[]
    ) {
        bytes32[] memory _teamOne = new bytes32[](_gameIds.length);
        bytes32[] memory _teamTwo = new bytes32[](_gameIds.length);
        uint[] memory _WINNER = new uint[](_gameIds.length);
        uint[] memory _betsCloseAt = new uint[](_gameIds.length);

        bool[] memory _drawPossible = new bool[](_gameIds.length);

        for(uint i = 0; i < _gameIds.length; ++i) {
            _teamOne[i] = strToBytes32(game[_gameIds[i]].teamOne);
            _teamTwo[i] = strToBytes32(game[_gameIds[i]].teamTwo);
            _WINNER[i] = game[_gameIds[i]].WINNER;
            _betsCloseAt[i] = game[_gameIds[i]].betsCloseAt;
            _drawPossible[i] = game[_gameIds[i]].drawPossible;

        }

        return (
            _gameIds,
            _teamOne,
            _teamTwo,
            _drawPossible,
            _WINNER,
            _betsCloseAt
        );
    }

    function getGamesMeta(uint[] _gameIds) public view returns(
        uint[], bytes32[], bytes32[], bool[], bool[]
    ) {
        bytes32[] memory _category = new bytes32[](_gameIds.length);
        bytes32[] memory _subcategory = new bytes32[](_gameIds.length);
        bool[] memory _hasOddsApi = new bool[](_gameIds.length);
        bool[] memory _hasDescription = new bool[](_gameIds.length);

        for(uint i = 0; i < _gameIds.length; ++i) {
            _category[i] = game[_gameIds[i]].category;
            _subcategory[i] = game[_gameIds[i]].subcategory;
            _hasOddsApi[i] = (bytes(game[_gameIds[i]].oddsApi).length != 0);
            _hasDescription[i] = (bytes(game[_gameIds[i]].description).length != 0);
        }

        return (
            _gameIds,
            _category,
            _subcategory,
            _hasOddsApi,
            _hasDescription
        );
    }

    function getGamesPool(uint[] _gameIds) public view returns(
        uint[], uint[], uint[], uint[]
    ) {
        uint[] memory _oddsOne = new uint[](_gameIds.length);
        uint[] memory _oddsTwo = new uint[](_gameIds.length);
        uint[] memory _oddsDraw = new uint[](_gameIds.length);

        for(uint i = 0; i < _gameIds.length; ++i) {
            _oddsOne[i] = game[_gameIds[i]].oddsMapping[1];
            _oddsTwo[i] = game[_gameIds[i]].oddsMapping[2];
            _oddsDraw[i] = game[_gameIds[i]].oddsMapping[3];
        }

        return (
            _gameIds,
            _oddsOne,
            _oddsTwo,
            _oddsDraw
        );
    }

    function getGameResolverData(uint _gameId) public view returns(string, address, uint) {
        Game storage _game = game[_gameId];

        return(
            _game.oraclizeSource,
            _game.verityAddress,
            _game.verityResultIndex
        );
    }

    function invalidateGame(uint _gameId)
        public
        onlyOwner
        onlyIfWinnerIsMissing(_gameId)
    {
        Game storage _game = game[_gameId];

        _game.betsCloseAt = 0;
        _game.endsAt = 0;
        _game.withdrawAfter = now + 1 weeks;

        emit GameInvalidated(_gameId);
    }

    function bet(uint _gameId, uint _team)
        public
        payable
    {
        storeBet(_gameId, _team, msg.value);
        playerData[msg.sender].totalBetAmount += msg.value;
        totalBetPool += msg.value;
    }

    function multiBet(uint[] _gameIds, uint[] _teams, uint[] _amounts)
        public
        payable
    {
        require(
            _gameIds.length == _teams.length &&
            _gameIds.length == _amounts.length,
            "Lengths do not match."
        );

        uint _betsNum = _gameIds.length;
        uint _balance = msg.value;

        for(uint i = 0; i < _betsNum; ++i) {
            if (_balance >= _amounts[i]) {
                storeBet(_gameIds[i], _teams[i], _amounts[i]);
                _balance -= _amounts[i];
            } else {
                revert("Not enough balance sent.");
            }
        }

        if (_balance > 0) {
            msg.sender.transfer(_balance);
            playerData[msg.sender].totalBetAmount += (msg.value - _balance);
            totalBetPool += (msg.value - _balance);
        }
    }

    function withdrawReward(uint _gameId)
        public
        onlyIfGameValid(_gameId)
        onlyAfterEndTime(_gameId)
        onlyIfWinnerIsSet(_gameId)
    {
        Game storage _game = game[_gameId];

        uint betAmount = _game.book[_game.WINNER][msg.sender];
        if (betAmount == 0) {
            return;
        }

        uint reward = betAmount + (
            betAmount *
            (_game.oddsMapping[_game.loserOne] + _game.oddsMapping[_game.loserTwo]) /
            _game.oddsMapping[_game.WINNER]
        );

        if (_game.balance < reward) {
            revert("Not enough balance on game. Contact 0xgame.");
        }
        address(msg.sender).transfer(reward);
        _game.balance -= reward;
        playerData[msg.sender].totalWithdrawn += reward;

        _game.playerBets[msg.sender][_game.WINNER].withdrawn = true;
        _game.book[_game.WINNER][msg.sender] = 0;

        emit RewardWithdrawn(_gameId, msg.sender, reward);
    }

    function multiWithdrawReward(uint[] _gameIds)
        public
    {
        for (uint i = 0; i < _gameIds.length; ++i) {
            withdrawReward(_gameIds[i]);
        }
    }

    function withdrawInvalidated(uint _gameId)
        public
    {
        Game storage _game = game[_gameId];

        require(
            _game.betsCloseAt == 0,
            "Game not invalidated."
        );

        uint[3][3] memory _playerData = getPlayerDataForGame(_gameId, msg.sender);

        uint _totalBetAmount =
            _playerData[0][1] +
            _playerData[1][1] +
            _playerData[2][1];

        address(msg.sender).transfer(_totalBetAmount);

        _game.playerBets[msg.sender][1].betAmount = 0;
        _game.playerBets[msg.sender][2].betAmount = 0;
        _game.playerBets[msg.sender][3].betAmount = 0;
    }

    function remoteSetWinner(uint _gameId, uint _callback_wei, uint _callback_gas_limit)
        public
        onlyAfterEndTime(_gameId)
        onlyIfWinnerIsMissing(_gameId)
    {
        if (game[_gameId].verityAddress == 0x0) {
            OraclizeResolverI(resolverAddress).remoteSetWinner(
                _gameId,
                game[_gameId].oraclizeSource,
                _callback_wei,
                _callback_gas_limit
            );
        } else {
            OraclizeResolverI(resolverAddress).eventSetWinner(_gameId, game[_gameId].verityAddress, game[_gameId].verityResultIndex);
        }
    }

    function callback(uint _gameId, string _result)
        external
        onlyResolver
        onlyValidTeamName(_gameId, _result)
    {
        game[_gameId].WINNER = game[_gameId].teamMapping[_result];
        emit WinningTeamSet(_gameId, _result);
        setLosers(_gameId);
    }

    //  see private method buildTeamMapping, buildBoolMapping
    //  first element in the nested array represents the team user betted on:
    //    (teamOne -> 1, teamTwo -> 2, draw -> 3)
    //  second element in nested array is the bet amount
    //  third element in nested array represents withdrawal status:
    //    (false -> 0, true -> 1)
    //  additionally (applies to first level elements):
    //    first array holds player data for teamOne
    //    second array holds player data for teamTwo
    //    third array holds pleyer data for draw
    function getPlayerDataForGame(uint _gameId, address _playerAddress) public view returns(uint[3][3]) {
        Game storage _game = game[_gameId];

        return [
            [
                1,
                _game.playerBets[_playerAddress][1].betAmount,
                boolMapping[_game.playerBets[_playerAddress][1].withdrawn]
            ],
            [
                2,
                _game.playerBets[_playerAddress][2].betAmount,
                boolMapping[_game.playerBets[_playerAddress][2].withdrawn]
            ],
            [
                3,
                _game.playerBets[_playerAddress][3].betAmount,
                boolMapping[_game.playerBets[_playerAddress][3].withdrawn]
            ]
        ];
    }

    function getPlayerData(address _playerAddress) public view returns(uint[2]) {
        return [
            playerData[_playerAddress].totalBetAmount,
            playerData[_playerAddress].totalWithdrawn
        ];
    }

    function getGamePool(uint _gameId) public view returns(uint[3]) {
        Game storage _game = game[_gameId];

        return [
            _game.oddsMapping[1],
            _game.oddsMapping[2],
            _game.oddsMapping[3]
        ];
    }

    function addBalanceToGame(uint _gameId)
        public
        payable
        onlyOwner
    {
        game[_gameId].balance += msg.value;
    }

    function withdrawRemainingRewards(uint _gameId)
        public
        onlyOwner
        onlyAfterWithdrawTime(_gameId)
    {
        address(owner).transfer(game[_gameId].balance);
    }

    function setResolver(address _resolverAddress)
        public
        onlyOwner
    {
        resolverAddress = _resolverAddress;
    }

    function updateGameMeta(uint _gameId, string _oddsApi, string _description)
        public
        onlyOwner
    {
        Game storage _game = game[_gameId];

        _game.oddsApi = _oddsApi;
        _game.description = _description;
    }

    /// Private functions
    function buildBoolMapping() private {
        boolMapping[false] = 0;
        boolMapping[true] = 1;
    }

    function buildTeamMapping(uint _gameId) internal {
        game[_gameId].teamMapping[game[_gameId].teamOne] = 1;
        game[_gameId].teamMapping[game[_gameId].teamTwo] = 2;
        game[_gameId].teamMapping[draw] = 3;
    }

    function setLosers(uint _gameId) private returns(string) {
        Game storage _game = game[_gameId];

        if (_game.WINNER == 1) {
            _game.loserOne = 2;
            _game.loserTwo = 3;
        } else if (_game.WINNER == 2) {
            _game.loserOne = 1;
            _game.loserTwo = 3;
        } else if (_game.WINNER == 3) {
            _game.loserOne = 1;
            _game.loserTwo = 2;
        }
    }

    function storeBet(uint _gameId, uint _team, uint _amount)
        private
        onlyIfGameValid(_gameId)
        onlyValidTeam(_team)
    {
        Game storage _game = game[_gameId];

        if (now > _game.betsCloseAt) {
            emit BetFailed(_gameId, msg.sender, _amount, _team);
            return;
        }

        _game.book[_team][msg.sender] += _amount;
        _game.oddsMapping[_team] += _amount;
        _game.balance += _amount;
        _game.totalPool += _amount;

        if (_game.playerBets[msg.sender][_team].betAmount == 0) {
            _game.playerBets[msg.sender][_team] = PlayerBet(_amount, _team, false);
        } else {
            _game.playerBets[msg.sender][_team].betAmount += _amount;
        }

        emit PlayerJoined(_gameId, msg.sender, _amount, _team);
    }

    function strToBytes32(string _team) internal pure returns(bytes32 result) {
        bytes memory _teamBytes;

        _teamBytes = bytes(_team);
        assembly {
            result := mload(add(_teamBytes, 32))
        }
    }
}

// File: contracts/mocks/MockBet0xgameMaster.sol

contract MockBet0xgameMaster is Bet0xgameMaster {

    constructor(address _resolverAddress)
        public
        Bet0xgameMaster(_resolverAddress)
    {}

    function resetTimes(uint _gameId, uint _seconds) public {
        game[_gameId].betsCloseAt = now + _seconds;
        game[_gameId].endsAt = now + _seconds;
        game[_gameId].WINNER = 0;
    }

    function resetWithdrawTimer(uint _gameId) public {
        game[_gameId].withdrawAfter = now;
    }

    function closeBets(uint _gameId) public {
        game[_gameId].betsCloseAt = now;
    }

    function endGame(uint _gameId) public {
        game[_gameId].betsCloseAt = now - 100;
        game[_gameId].endsAt = now;
    }

    function resetUser(uint _gameId, address user) public {
        game[_gameId].playerBets[user][game[_gameId].WINNER].withdrawn = false;
    }

    function setWinner(uint _gameId) public {
        game[_gameId].WINNER = 1;
    }

    function testCreateGames(uint _count) public {
        Game memory _game;

        for (uint i = 0; i < _count; ++i) {
            _game.gameId = game.length;
            _game.teamOne = "Home";
            _game.teamTwo = "Away";
            _game.oraclizeSource = "";
            _game.betsCloseAt = now + 300;
            _game.endsAt = now + 600;
            _game.oddsApi = "";
            _game.category = bytes32("category");
            _game.subcategory = bytes32("subcategory");
            _game.drawPossible = true;
            game.push(_game);

            buildTeamMapping(_game.gameId);

            emit NewGame(
                _game.gameId,
                _game.teamOne,
                _game.teamTwo,
                _game.betsCloseAt
            );
        }
    }

    function testCreateGame(
        string _teamOne,
        string _teamTwo,
        bool _drawPossible,
        string _oraclizeSource,
        address _eventAddress,
        string _oddsApi
    )
        public
    {
        Game memory _game;

        _game.gameId = game.length;
        _game.teamOne = _teamOne;
        _game.teamTwo = _teamTwo;
        _game.oraclizeSource = _oraclizeSource;
        _game.betsCloseAt = now + 300;
        _game.endsAt = now + 600;
        _game.oddsApi = _oddsApi;
        _game.category = bytes32("category");
        _game.subcategory = bytes32("subcategory");
        _game.drawPossible = _drawPossible;
        _game.verityAddress = _eventAddress;
        _game.verityResultIndex = 0;

        game.push(_game);

        buildTeamMapping(_game.gameId);

        emit NewGame(
            _game.gameId,
            _game.teamOne,
            _game.teamTwo,
            _game.betsCloseAt
        );
    }
}