pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./INoftToken.sol";

contract NoftGameManager is Ownable {
    using SafeMath for uint256;

    address payable wallet;
    address manager;
    address token;
    address rentAddress;
    address serverAddress;
    INoftToken tokenContract;

    uint FEE_PERCENTAGE = 10;
    uint RENT_FEE_PERCENTAGE = 30;
    uint[] GAME_FEES = [
    5000000000000000,
    10000000000000000,
    20000000000000000,
    50000000000000000,
    100000000000000000,
    200000000000000000
    ];
    uint[] PLAYER_COUNTS = [8];
    uint incrementPlayerId = 1;

    struct Player {
        uint playerId;
        address payable account;
        uint tokenId;
        bool isRent;
        bool isBot;
        uint strategyId;
    }

    enum GameStatus {
        STARTED,
        ENDED,
        CANCELLED,
        PICKED
    }

    struct Game {
        uint gameId;
        GameStatus status;
        uint[] playerIds;
        uint gameFee;
        uint winnerId;
        uint bank;
        uint playersCount;
        address creator;
        bool leaveEnabled;
        bool botsEnabled;
        uint seed;
    }

    mapping(uint => Game) games;
    mapping(uint => Player) players;

    modifier onlyOwnerOrManager() {
        require(_msgSender() == owner() || manager == _msgSender());
        _;
    }

    modifier onlyOwnerOrManagerOrServer() {
        require(_msgSender() == owner() || manager == _msgSender() || serverAddress == _msgSender());
        _;
    }

    event GameStatusChanged(uint indexed gameId, GameStatus indexed status);

    event PlayerChanged(address indexed account, uint indexed gameId, uint indexed playerId, bool isBot);

    event WalletChanged(address indexed oldWallet, address indexed newWallet);
    event ManagerChanged(address oldManager, address newManager);
    event TokenChanged(address oldToken, address newToken);
    event ServerChanged(address oldServer, address newServer);
    event RentChanged(address oldRent, address newRent);

    constructor(address _token, address payable _wallet, address _manager, address _rentAddress) {
        wallet = _wallet;
        manager = _manager;
        token = _token;
        rentAddress = _rentAddress;
        tokenContract = INoftToken(_token);
    }

    function startGame(uint gameId, uint feeIdx, uint playersCountIdx, bool leaveEnabled, bool botsEnabled) external {
        require(gameId > 0 && games[gameId].gameId == 0);
        games[gameId] = Game(
            gameId,
            GameStatus.STARTED,
            new uint[](0),
            GAME_FEES[feeIdx],
            0,
            0,
            PLAYER_COUNTS[playersCountIdx],
            _msgSender(),
            leaveEnabled,
            botsEnabled,
            bytesToUint(keccak256(abi.encodePacked(blockhash(block.number - 1), gameId)))
        );

        emit GameStatusChanged(gameId, GameStatus.STARTED);
    }

    function addPlayer(uint tokenId, uint gameId, uint strategyId) external payable returns (uint playerId) {
        Game memory game = games[gameId];

        require(game.gameFee == msg.value);
        require(game.status == GameStatus.STARTED);

        for (uint i = 0; i < game.playerIds.length; i++) {
            require(players[game.playerIds[i]].tokenId != tokenId);
        }

        playerId = incrementPlayerId++;
        bool isRent = tokenContract.ownerOf(tokenId) == rentAddress;
        bool isOwn = tokenContract.ownerOf(tokenId) == _msgSender();

        (, , , , , , INoftToken.Ranks rank) = tokenContract.getToken(tokenId);
        require(!isRent || uint(rank) <= 2);
        require(isRent || isOwn);

        players[playerId] = Player(playerId, payable(_msgSender()), tokenId, isRent, false, strategyId);

        games[gameId].playerIds.push(playerId);
        games[gameId].bank = games[gameId].bank.add(msg.value);

        emit PlayerChanged(_msgSender(), gameId, playerId, false);
        if (game.playersCount == games[gameId].playerIds.length) {
            games[gameId].status = GameStatus.PICKED;
            emit GameStatusChanged(gameId, GameStatus.PICKED);
        }
    }

    function addBots(uint[] memory tokenIds, uint gameId, uint[] memory strategyIds) external {
        Game memory game = games[gameId];
        require(game.botsEnabled);
        require(game.status == GameStatus.STARTED);
        bool isManager = _msgSender() == owner() || manager == _msgSender() || serverAddress == _msgSender();
        bool isGameCreator = game.creator == _msgSender();
        require(isManager || isGameCreator);
        require(tokenIds.length == strategyIds.length);
        require(tokenIds.length + game.playerIds.length <= game.playersCount);

        uint botsCount = getBotsCount(gameId);

        require(game.playersCount - botsCount >= 2);

        for (uint i = 0; i < tokenIds.length; i++) {
            require(tokenContract.ownerOf(tokenIds[i]) == rentAddress);
            uint playerId = incrementPlayerId++;

            players[playerId] = Player(playerId, payable(_msgSender()), tokenIds[i], false, true, strategyIds[i]);

            games[gameId].playerIds.push(playerId);

            emit PlayerChanged(_msgSender(), gameId, playerId, true);
            if (game.playersCount == games[gameId].playerIds.length) {
                games[gameId].status = GameStatus.PICKED;
                emit GameStatusChanged(gameId, GameStatus.PICKED);
            }
        }
    }

    function endGame(uint gameId, uint winnerId) external onlyOwnerOrManagerOrServer returns (uint prize) {
        Game memory game = games[gameId];
        require(game.status == GameStatus.PICKED);

        Player memory winner = players[winnerId];
        require(!winner.isBot);

        uint fee = winner.isRent ? RENT_FEE_PERCENTAGE : FEE_PERCENTAGE;
        uint bankFee = game.bank.div(100).mul(fee);
        prize = game.bank.sub(bankFee);

        wallet.transfer(bankFee);
        winner.account.transfer(prize);

        games[gameId].winnerId = winnerId;
        games[gameId].status = GameStatus.ENDED;

        emit PlayerChanged(_msgSender(), gameId, winnerId, false);
        emit GameStatusChanged(gameId, GameStatus.ENDED);
    }

    function leavePlayer(uint gameId, uint playerId) external {
        require(games[gameId].leaveEnabled);

        Player memory player = players[playerId];
        bool isManager = _msgSender() == owner() || manager == _msgSender() || serverAddress == _msgSender();
        bool isTokenOwner = _msgSender() == player.account;
        require(isManager || isTokenOwner);

        removePlayer(gameId, playerId);
    }

    function removePlayer(uint gameId, uint playerId) internal {
        Player memory player = players[playerId];
        Game memory game = games[gameId];

        uint playersCount = game.playerIds.length;
        uint playerIdx = playersCount;

        for (uint i = 0; i < playersCount - 1; i++) {
            if (game.playerIds[i] == playerId) {
                playerIdx = i;
            }
            if (playerIdx < playersCount) {
                game.playerIds[i] = game.playerIds[i + 1];
            }
        }

        games[gameId].playerIds.pop();

        if (!player.isBot) {
            player.account.transfer(game.gameFee);
            games[gameId].bank = games[gameId].bank.sub(game.gameFee);
        }

        emit PlayerChanged(player.account, gameId, playerId, player.isBot);
    }

    function cancelGame(uint gameId) external onlyOwnerOrManagerOrServer {
        Game memory game = games[gameId];
        require(game.status != GameStatus.ENDED && game.status != GameStatus.CANCELLED);

        uint playersCount = game.playerIds.length;
        if (playersCount > 0) {
            for (uint i = playersCount - 1; i > 0; i--) {
                removePlayer(gameId, game.playerIds[i]);
            }
            removePlayer(gameId, game.playerIds[0]);
        }

        games[gameId].status = GameStatus.CANCELLED;

        emit GameStatusChanged(gameId, GameStatus.CANCELLED);
    }

    function setWallet(address payable newWallet) external onlyOwnerOrManager {
        address old = wallet;
        wallet = newWallet;
        emit WalletChanged(old, wallet);
    }

    function setManager(address _manager) external onlyOwner {
        emit ManagerChanged(manager, _manager);
        manager = _manager;
    }

    function setToken(address _token) external onlyOwnerOrManager {
        emit TokenChanged(token, _token);
        token = _token;
        tokenContract = INoftToken(token);
    }

    function setServer(address _server) external onlyOwnerOrManager {
        emit ServerChanged(serverAddress, _server);
        serverAddress = _server;
    }

    function setRentAddress(address _rent) external onlyOwnerOrManager {
        emit RentChanged(rentAddress, _rent);
        rentAddress = _rent;
    }

    function setRentFeePercentage(uint _fee) external onlyOwnerOrManager {
        RENT_FEE_PERCENTAGE = _fee;
    }

    function setFeePercentage(uint _fee) external onlyOwnerOrManager {
        FEE_PERCENTAGE = _fee;
    }

    function setGameFees(uint[] calldata _fees) external onlyOwnerOrManager {
        GAME_FEES = _fees;
    }

    function setPlayersCounts(uint[] calldata _counts) external onlyOwnerOrManager {
        PLAYER_COUNTS = _counts;
    }

    function getGame(uint _gameId) external view returns (
        uint gameId,
        GameStatus status,
        uint gameFee,
        uint winnerId,
        uint bank,
        uint playersCount,
        uint currentPlayerCount,
        address creator,
        bool leaveEnabled,
        bool botsEnabled,
        uint seed
    ) {
        Game memory game = games[_gameId];

        gameId = game.gameId;
        status = game.status;
        gameFee = game.gameFee;
        winnerId = game.winnerId;
        bank = game.bank;
        playersCount = game.playersCount;
        creator = game.creator;
        botsEnabled = game.botsEnabled;
        leaveEnabled = game.leaveEnabled;
        currentPlayerCount = game.playerIds.length;
        seed = game.seed;
    }

    function getPlayer(uint _playerId) external view returns (
        uint playerId,
        address account,
        uint tokenId,
        bool isRent,
        bool isBot,
        uint strategyId
    ) {
        Player memory player = players[_playerId];

        playerId = player.playerId;
        account = player.account;
        tokenId = player.tokenId;
        isRent = player.isRent;
        isBot = player.isBot;
        strategyId = player.strategyId;
    }

    function getGamePlayer(uint gameId, uint index) external view returns (
        uint playerId,
        address account,
        uint tokenId,
        bool isRent,
        bool isBot,
        uint strategyId
    ) {
        Game memory game = games[gameId];
        Player memory player = players[game.playerIds[index]];

        playerId = player.playerId;
        account = player.account;
        tokenId = player.tokenId;
        isRent = player.isRent;
        isBot = player.isBot;
        strategyId = player.strategyId;
    }

    function getWallet() external view returns (address) {
        return wallet;
    }

    function getManager() external view returns (address) {
        return manager;
    }

    function getTokenAddress() external view returns (address) {
        return token;
    }

    function getServerAddress() external view returns (address) {
        return serverAddress;
    }

    function getRentAddress() external view returns (address) {
        return rentAddress;
    }

    function getRentFeePercentage() external view returns (uint) {
        return RENT_FEE_PERCENTAGE;
    }

    function getFeePercentage() external view returns (uint) {
        return FEE_PERCENTAGE;
    }

    function getGameFee(uint index) external view returns (uint) {
        return GAME_FEES[index];
    }

    function getGameFeeLength() external view returns (uint) {
        return GAME_FEES.length;
    }

    function getPlayersCounts(uint index) external view returns (uint) {
        return PLAYER_COUNTS[index];
    }

    function getPlayersCountsLength() external view returns (uint) {
        return PLAYER_COUNTS.length;
    }

    function bytesToUint(bytes32 b) internal pure returns (uint number){
        number = 0;
        for (uint i = 0; i < b.length; i++) {
            number = number.add(uint(uint8(b[i])) * (2 ** (8 * (b.length - (i + 1)))));
        }
    }

    function getBotsCount(uint gameId) public view returns (uint count) {
        count = 0;

        for (uint i = 0; i < games[gameId].playerIds.length; i++) {
            if (players[games[gameId].playerIds[i]].isBot) {
                count += 1;
            }
        }
    }
}