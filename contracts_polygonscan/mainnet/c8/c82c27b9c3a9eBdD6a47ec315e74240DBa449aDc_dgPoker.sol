/**
 *Submitted for verification at polygonscan.com on 2021-07-30
*/

// SPDX-License-Identifier: -- � --

pragma solidity ^0.7.4;

interface TreasuryInstance {

    function getTokenAddress(
        uint8 _tokenIndex
    ) external view returns (address);

    function tokenInboundTransfer(
        uint8 _tokenIndex,
        address _from,
        uint256 _amount
    )  external returns (bool);

    function tokenOutboundTransfer(
        uint8 _tokenIndex,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function checkAllocatedTokens(
        uint8 _tokenIndex
    ) external view returns (uint256);

    function checkApproval(
        address _userAddress,
        uint8 _tokenIndex
    ) external view returns (uint256 approved);

    function getMaximumBet(
        uint8 _tokenIndex
    ) external view returns (uint128);

    function consumeHash(
        bytes32 _localhash
    ) external returns (bool);
}

contract AccessController {

    address public ceoAddress;

    mapping (address => bool) public isWorker;

    event CEOSet(
        address newCEO
    );

    event WorkerAdded(
        address newWorker
    );

    event WorkerRemoved(
        address existingWorker
    );

    constructor() {

        address creator = msg.sender;

        ceoAddress = creator;

        isWorker[creator] = true;

        emit CEOSet(
            creator
        );

        emit WorkerAdded(
            creator
        );
    }

    modifier onlyCEO() {
        require(
            msg.sender == ceoAddress,
            'AccessControl: CEO access denied'
        );
        _;
    }

    modifier onlyWorker() {
        require(
            isWorker[msg.sender] == true,
            'AccessControl: worker access denied'
        );
        _;
    }

    modifier nonZeroAddress(address checkingAddress) {
        require(
            checkingAddress != address(0x0),
            'AccessControl: invalid address'
        );
        _;
    }

    function setCEO(
        address _newCEO
    )
        external
        nonZeroAddress(_newCEO)
        onlyCEO
    {
        ceoAddress = _newCEO;

        emit CEOSet(
            ceoAddress
        );
    }

    function addWorker(
        address _newWorker
    )
        external
        onlyCEO
    {
        _addWorker(
            _newWorker
        );
    }

    function addWorkerBulk(
        address[] calldata _newWorkers
    )
        external
        onlyCEO
    {
        for (uint8 index = 0; index < _newWorkers.length; index++) {
            _addWorker(_newWorkers[index]);
        }
    }

    function _addWorker(
        address _newWorker
    )
        internal
        nonZeroAddress(_newWorker)
    {
        require(
            isWorker[_newWorker] == false,
            'AccessControl: worker already exist'
        );

        isWorker[_newWorker] = true;

        emit WorkerAdded(
            _newWorker
        );
    }

    function removeWorker(
        address _existingWorker
    )
        external
        onlyCEO
    {
        _removeWorker(
            _existingWorker
        );
    }

    function removeWorkerBulk(
        address[] calldata _workerArray
    )
        external
        onlyCEO
    {
        for (uint8 index = 0; index < _workerArray.length; index++) {
            _removeWorker(_workerArray[index]);
        }
    }

    function _removeWorker(
        address _existingWorker
    )
        internal
        nonZeroAddress(_existingWorker)
    {
        require(
            isWorker[_existingWorker] == true,
            "AccessControl: worker not detected"
        );

        isWorker[_existingWorker] = false;

        emit WorkerRemoved(
            _existingWorker
        );
    }
}

interface PointerInstance {

    function addPoints(
        address _player,
        uint256 _points,
        address _token,
        uint256 _numPlayers,
        uint256 _wearableBonus
    ) external returns (
        uint256 newPoints,
        uint256 multiplierA,
        uint256 multiplierB
    );

    function addPoints(
        address _player,
        uint256 _points,
        address _token,
        uint256 _numPlayers
    ) external returns (
        uint256 newPoints,
        uint256 multiplierA,
        uint256 multiplierB
    );

    function addPoints(
        address _player,
        uint256 _points,
        address _token
    ) external returns (
        uint256 newPoints,
        uint256 multiplierA,
        uint256 multiplierB
    );
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SafeMath: subtraction overflow');
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'SafeMath: modulo by zero');
        return a % b;
    }
}

contract dgPoker is AccessController {

    using SafeMath for uint256;

    enum GameState { NewGame, OnGoingGame, EndedGame }
    enum PlayerState { notInGame, inGame, hasFolded, hasLost, hasWon }

    struct Game {
        address[] players;
        uint256[] entryBets;
        uint256[] approvals;
        uint256 wageredTotal; // sum of all bets per game includes entryBets
        uint8 tokenIndex;
        uint8 playersCount;
        uint8 beneficiaryPercent;
        address gameBeneficiary;
        PlayerState[] pState;
        GameState state;
    }

    mapping(bytes16 => Game) public Games;

    modifier onlyOnGoingGames(bytes16 _gameId) {
        require(
            Games[_gameId].state == GameState.OnGoingGame,
            "onlyOnGoingGames: not OnGoingGame"
        );
        _;
    }

    modifier onlyInGamePlayer(bytes16 _gameId, uint8 _playerIndex) {
        require(
            Games[_gameId].pState[_playerIndex] == PlayerState.inGame,
            "onlyInGamePlayer: player not inGame"
        );
        _;
    }

    modifier checkPlayerIndex(bytes16 _gameId, uint8 _playerIndex, address _playerAddress) {
        require(
            Games[_gameId].players[_playerIndex] == _playerAddress,
            "checkPlayerIndex: invalid _playerAddress"
        );
        _;
    }

    TreasuryInstance public treasury;

    uint256[] public maxBet;
    uint256[] public maxApproval;

    struct Globals {
        uint256 nonce;
        uint256 threshold;
        uint8 maxPlayers;
        uint8 houseFee;

    }

    Globals public globals;

    event ApprovedAmountTaken(
        uint8 indexed tokenIndex,
        address indexed player,
        uint256 approvedAmount
    );

    event EntryBetPlaced(
        uint8 indexed tokenIndex,
        address indexed player,
        uint256 betAmount
    );

    event GameInitializing(
        bytes16 indexed gameId
    );

    event GameInitialized(
        bytes16 indexed gameId,
        uint256[] entryBets,
        uint256[] approvals,
        uint8 tokenIndex,
        uint256 indexed landId,
        uint256 indexed tableId
    );

    event PlayerFolded(
        bytes16 indexed gameId,
        uint8 indexed playerIndex,
        address indexed playerAddress
    );

    event PlayerRefunded(
        bytes16 indexed gameId,
        address indexed player,
        uint256 indexed entryBet,
        uint256 refundAmount,
        uint256 wageredAmount,
        uint256 approvedAmount
    );

    event PlayerWon(
        bytes16 indexed gameId,
        address indexed player,
        uint256 winAmount,
        uint256 wageredAmount
    );

    event FinishedGame(
        bytes16 indexed gameId
    );

    PointerInstance public pointerContract;

    constructor(
        address _treasuryAddress,
        address _pointerAddress,
        uint8 _maxPlayers,
        uint8 _houseFee,
        uint8 _tokenCount
    ) {
        require(_maxPlayers <= 10);
        require(_houseFee <= 10);

        treasury = TreasuryInstance(
            _treasuryAddress
        );

        globals.maxPlayers = _maxPlayers;
        globals.houseFee = _houseFee;

        pointerContract = PointerInstance(
            _pointerAddress
        );

        changeTokenCount(_tokenCount);
    }

    function changeHouseFee(
        uint8 _newHouseFee
    )
        external
        onlyCEO
    {
        require(_newHouseFee <= 10);
        globals.houseFee = _newHouseFee;
    }

    function changeMaxPlayer(
        uint8 _newMaxPlayer
    )
        external
        onlyCEO
    {
        require(_newMaxPlayer <= 10);
        globals.maxPlayers = _newMaxPlayer;
    }

    function changeMaxBet(
        uint8 _tokenIndex,
        uint256 _newMaxBet
    )
        external
        onlyCEO
    {
        require(
            _newMaxBet < maxApproval[_tokenIndex]
        );
        maxBet[_tokenIndex] = _newMaxBet;
    }

    function changeMaxApproval(
        uint8 _tokenIndex,
        uint256 _newMaxApproval
    )
        external
        onlyCEO
    {
        require(
            _newMaxApproval > maxBet[_tokenIndex]
        );

        maxApproval[_tokenIndex] = _newMaxApproval;
    }

    function changeTokenCount(
        uint8 _tokenCount
    )
        public
        onlyCEO
    {
        require(
            _tokenCount > 0,
            "dgPoker: invalid _tokenCount"
        );

        maxBet = new uint8[](_tokenCount);
        maxApproval = new uint8[](_tokenCount);
    }

    function getPlayerStatus(
        uint8 _playerIndex,
        bytes16 _gameId
    )
        external
        view
        returns(PlayerState)
    {
        return Games[_gameId].pState[_playerIndex];
    }

    function _addPoints(
        address _player,
        uint256 _points,
        address _token,
        uint256 _numPlayers,
        uint256 _wearableBonus
    )
        private
    {
        pointerContract.addPoints(
            _player,
            _points,
            _token,
            _numPlayers,
            _wearableBonus
        );
    }

    function takeApprovedAmount(
        bytes16 _gameId,
        uint8 _playerIndex
    )
        private
    {
        uint8 tokenIndex = Games[_gameId].tokenIndex;
        address player = Games[_gameId].players[_playerIndex];
        uint256 approvalAmount = Games[_gameId].approvals[_playerIndex];

        require(
            treasury.getMaximumBet(tokenIndex) >= approvalAmount,
            "takeApprovedAmount: approvalAmount must be below treasury limit"
        );

        require(
            maxApproval[tokenIndex] >= approvalAmount,
            "takeApprovedAmount: approvalAmount must be below game limit"
        );

        treasury.tokenInboundTransfer(
            tokenIndex, player, approvalAmount
        );

        emit ApprovedAmountTaken(
            tokenIndex, player, approvalAmount
        );
    }

    function placeEntryBet(
        bytes16 _gameId,
        uint8 _playerIndex
    )
        private
    {
        uint8 tokenIndex = Games[_gameId].tokenIndex;
        address player = Games[_gameId].players[_playerIndex];
        uint256 entryBet = Games[_gameId].entryBets[_playerIndex];

        require(
            maxBet[tokenIndex] >= entryBet,
            "placeEntryBet: entryBet must be below game limit"
        );

        // Games[_gameId].wageredTotal =
        // Games[_gameId].wageredTotal.add(entryBet);

        emit EntryBetPlaced(
            tokenIndex,
            player,
            entryBet
        );
    }

    function initializePlayer(
        bytes16 _gameId,
        uint8 _playerIndex
    )
        private
    {
        require(
            Games[_gameId].pState[_playerIndex] == PlayerState.notInGame ||
            Games[_gameId].pState[_playerIndex] == PlayerState.hasFolded ||
            Games[_gameId].pState[_playerIndex] == PlayerState.hasLost ||
            Games[_gameId].pState[_playerIndex] == PlayerState.hasWon,
            "initializePlayer: invalid playerState detected"
        );

        Games[_gameId].pState[_playerIndex] = PlayerState.inGame;
    }

    /** @param _approvals number of approved tokens (for duration of game they will be sent to treasury)
      * @param _tokenIndex token index in dgTreasury
      * @param _beneficiaryPercent percentage of winnings that will sent to the beneficiary (depends on houseFee)
      * @param _gameBeneficiary beneficiary address
    */
    function initializeGame(
        bytes16 _gameId,
        address[] calldata _players,
        uint256[] calldata _entryBets,
        uint256[] calldata _approvals,
        uint8 _tokenIndex,
        uint256 _serverId,
        uint256 _landId,
        uint256 _tableId,
        uint8 _beneficiaryPercent,
        address _gameBeneficiary
    )
        external
        onlyWorker
    {
        require(
            _players.length <= globals.maxPlayers &&
            _entryBets.length == _players.length,
            "initializeGame: invalid length in initializeGame"
        );

        bytes16 gameId = _gameId;
        // gameId = getGameId(
        //     _serverId,
        //     _landId,
        //     _tableId,
        //     globals.nonce
        // );

        globals.nonce = globals.nonce + 1;

        require(
            Games[gameId].state == GameState.NewGame ||
            Games[gameId].state == GameState.EndedGame,
            "initializeGame: invalid GameState detected"
        );

        emit GameInitializing(
            gameId
        );

        Game memory _game = Game(
            _players,
            _entryBets,
            _approvals,
            0,
            _tokenIndex,
            uint8(_players.length),
            _beneficiaryPercent,
            _gameBeneficiary,
            new PlayerState[](_players.length),
            GameState.OnGoingGame
        );

        Games[gameId] = _game;

        for (uint8 playerIndex = 0; playerIndex < _players.length; playerIndex++) {

            initializePlayer(
                gameId, playerIndex
            );

            takeApprovedAmount(
                gameId, playerIndex
            );

            placeEntryBet(
                gameId, playerIndex
            );
        }

        emit GameInitialized(
            gameId,
            _entryBets,
            _approvals,
            _tokenIndex,
            _landId,
            _tableId
        );
    }

    function playerFolds(
        bytes16 _gameId,
        address _foldPlayer,
        uint8 _playerIndex,
        uint256 _wageredAmount,
        uint256 _refundAmount
    )
        external
        onlyOnGoingGames(_gameId)
        onlyWorker
    {
        _refundPlayer(
            _gameId,
            Games[_gameId].tokenIndex,
            _playerIndex,
            _foldPlayer,
            _wageredAmount,
            _refundAmount
        );

        Games[_gameId].pState[_playerIndex] = PlayerState.hasFolded;

        emit PlayerFolded(
            _gameId,
            _playerIndex,
            _foldPlayer
        );
    }

    /** @param _winAmount sum of all wageredAmounts includes winner's wageredAmount
      * @param _wageredAmounts sum of all bets per game for each player includes entryBets
      * @param _refundAmounts sum of refund per game for each player (approvals - wageredAmounts)
    */
    function manualPayout(
        bytes16 _gameId,
        address _winPlayerAddress, // 0x...
        uint8 _winPlayerIndex, // 2
        uint256 _winAmount, // 950 = total wagered of all players + entry bets of all players
        uint256[] calldata _wageredAmounts, // [100, 400, 400] shows inGameBets for each player
        uint256[] calldata _refundAmounts // [390, 90, 80]
        // uint256[] calldata _wearableBonus
    )
        external
        onlyOnGoingGames(_gameId)
        onlyWorker
    {
        uint8 playersCount = Games[_gameId].playersCount;

        require(
            playersCount == _wageredAmounts.length &&
            playersCount == _refundAmounts.length,
            "manualPayout: invalid playersCount"
        );

        // require(
        //     _checkWinnerWageredAmount(
        //         _wageredAmounts,
        //         _winPlayerIndex
        //     ),
        //     "manualPayout: low wagered amount for winner"
        // );

        _refundPlayer(
            _gameId,
            Games[_gameId].tokenIndex,
            _winPlayerIndex,
            _winPlayerAddress,
            _wageredAmounts[_winPlayerIndex],
            _refundAmounts[_winPlayerIndex]
        );

        _payoutLoss(
            _gameId,
            _winPlayerAddress,
            _wageredAmounts,
            _refundAmounts
            // _wearableBonus
        );

        uint256 treasuryPayout =

        _payoutWin(
            _gameId,
            _winPlayerIndex,
            _winPlayerAddress,
            _winAmount,
            _wageredAmounts[_winPlayerIndex]
        );

        _proceedWithPoints(
            _gameId,
            treasuryPayout,
            _wageredAmounts
        );

        Games[_gameId].state = GameState.EndedGame;

        emit FinishedGame(
            _gameId
        );
    }

    function _payoutLoss(
        bytes16 _gameId,
        address _winPlayerAddress,
        uint256[] calldata _wageredAmounts,
        uint256[] calldata _refundAmounts
        // uint256[] calldata _wearableBonus
    )
        private
    {
        for (uint8 i = 0; i < _refundAmounts.length; i++) {

            address _playerAddress = Games[_gameId].players[i];

            if (
                _playerAddress != _winPlayerAddress &&
                Games[_gameId].pState[i] == PlayerState.inGame
            ) {
                _refundPlayer(
                    _gameId,
                    Games[_gameId].tokenIndex,
                    i,
                    _playerAddress,
                    _wageredAmounts[i],
                    _refundAmounts[i]
                );

                // wageredTotal = (all players entryBets + loss players wagered amount);
                Games[_gameId].pState[i] = PlayerState.hasLost;
            }

            Games[_gameId].wageredTotal =
            Games[_gameId].wageredTotal.add(_wageredAmounts[i]);
        }
    }

    function _payoutWin(
        bytes16 _gameId,
        uint8 _playerIndex,
        address _playerAddress,
        uint256 _winAmount,  // = allEntryBets + allPlayers wagered
        uint256 _wageredAmount
    )
        private
        returns (uint256)
    {
        uint256 wageredTotal = Games[_gameId].wageredTotal;

        // require(
        //     _winAmount == wageredTotal, // all entryBets + all inGameBets
        //     "_payoutWin: invalid _winAmount"
        // );

        uint256 taxableAmount = _winAmount > 0 
            ? _winAmount.sub(_wageredAmount) 
            : 0;

        uint256 treasuryPayout = _proceedWithPayout(
            _gameId,
            _playerIndex,
            _winAmount, // totalWinAmount to return
            taxableAmount // amount for fee calculation
        );

        emit PlayerWon(
            _gameId,
            _playerAddress,
            _winAmount,
            _wageredAmount
        );

        return treasuryPayout;
    }

    function _proceedWithPoints(
        bytes16 _gameId,
        uint256 _treasuryPayout,
        uint256[] memory _wageredAmounts
    )
        private
    {
        for (uint8 i = 0; i < _wageredAmounts.length; i++) {

            address playerAddress = Games[_gameId].players[i];

            uint256 points = _wageredAmounts[i].mul(100)
                .div(Games[_gameId].wageredTotal)
                .mul(_treasuryPayout).div(100);

            _addPoints(
                playerAddress,
                points,
                treasury.getTokenAddress(Games[_gameId].tokenIndex),
                Games[_gameId].playersCount,
                0
            );
        }
    }

    function _subtractHouseFee(
        uint256 _winAmount,
        uint256 _taxableAmount,
        uint256 _threshold,
        uint8 _houseFee,
        bytes16 _gameId
    )
        internal
        view
        returns (
            uint256 treasuryPayout,
            uint256 beneficiaryPayout,
            uint256 winAmount
        )
    {
        if (_winAmount > 0) {
            treasuryPayout = _taxableAmount
                .mul(_houseFee)
                .div(100);

            treasuryPayout = treasuryPayout > _threshold
                ? _threshold
                : treasuryPayout;

            beneficiaryPayout = treasuryPayout
                .mul(Games[_gameId].beneficiaryPercent)
                .div(100);

            winAmount = _winAmount.sub(treasuryPayout);
        }
    }

    function _proceedWithPayout(
        bytes16 _gameId,
        uint8 _playerIndex,
        uint256 _winAmount,
        uint256 _taxableAmount
    )
        private
        onlyInGamePlayer(_gameId, _playerIndex)
        returns (uint256)
    {
        Games[_gameId].pState[_playerIndex] = PlayerState.hasWon;

        (
            uint256 treasuryPayout,
            uint256 beneficiaryPayout,
            uint256 winAmount
        )

        = _subtractHouseFee(
            _winAmount,
            _taxableAmount,
            globals.threshold,
            globals.houseFee,
            _gameId
        );

        if (beneficiaryPayout > 0) {
            treasury.tokenOutboundTransfer(
                Games[_gameId].tokenIndex,
                Games[_gameId].gameBeneficiary,
                beneficiaryPayout
            );
        }

        if (winAmount > 0) {
            treasury.tokenOutboundTransfer(
                Games[_gameId].tokenIndex,
                Games[_gameId].players[_playerIndex],
                winAmount
            );
        }

        return treasuryPayout;
    }

    function _refundPlayer(
        bytes16 _gameId,
        uint8 _tokenIndex,
        uint8 _playerIndex,
        address _playerAddress,
        uint256 _wageredAmount,
        uint256 _refundAmount
    )
        private
        onlyInGamePlayer(_gameId, _playerIndex)
    {
        require(
            Games[_gameId].players[_playerIndex] == _playerAddress,
            "checkPlayerIndex: invalid _playerAddress"
        );

        uint256 approvedAmount = Games[_gameId].approvals[_playerIndex];

        require(
            _refundAmount == approvedAmount.sub(_wageredAmount),
            "_refundPlayer: invalid _refundAmount"
        );

        treasury.tokenOutboundTransfer(
            _tokenIndex, _playerAddress, _refundAmount
        );

        emit PlayerRefunded(
            _gameId,
            _playerAddress,
            Games[_gameId].entryBets[_playerIndex],
            _refundAmount,
            _wageredAmount,
            approvedAmount
        );
    }

    function _checkWinnerWageredAmount(
        uint256[] memory _wageredAmounts,
        uint8 _winnerIndex
    )
        internal
        pure
        returns (bool)
    {
        return _wageredAmounts[_winnerIndex] == _findMax(_wageredAmounts);
    }

    function _findMax(
        uint256[] memory _array
    )
        internal
        pure
        returns (uint256 maximal)
    {
        for(uint8 index = 0; index < _array.length; index++){
            if(_array[index] > maximal){
                maximal = _array[index];
            }
        }
    }

    function getGameId(
        uint256 _serverID,
        uint256 _landID,
        uint256 _tableID,
        uint256 _nonce
    )
        public
        pure
        returns (bytes16 gameId)
    {
        gameId = bytes16(
            keccak256(
                abi.encodePacked(
                    _serverID,
                    _landID,
                    _tableID,
                    _nonce
                )
            )
        );
    }

    function updateThreshold(
        uint256 _newThreshold
    )
        external
        onlyCEO
    {
        globals.threshold = _newThreshold;
    }

    function updatePointer(
        address _newPointerAddress
    )
        external
        onlyCEO
    {
        pointerContract = PointerInstance(_newPointerAddress);
    }
}