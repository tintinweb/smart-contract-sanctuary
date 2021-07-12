/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

// SPDX-License-Identifier: -- 🎲 --

pragma solidity ^0.7.0;

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

contract AccessController {

    address public ceoAddress;
    address public workerAddress;

    bool public paused = false;

    // mapping (address => enumRoles) accessRoles; // multiple operators idea

    event CEOSet(address newCEO);
    event WorkerSet(address newWorker);

    event Paused();
    event Unpaused();

    constructor() {
        ceoAddress = msg.sender;
        workerAddress = msg.sender;
        emit CEOSet(ceoAddress);
        emit WorkerSet(workerAddress);
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
            msg.sender == workerAddress,
            'AccessControl: worker access denied'
        );
        _;
    }

    modifier whenNotPaused() {
        require(
            !paused,
            'AccessControl: currently paused'
        );
        _;
    }

    modifier whenPaused {
        require(
            paused,
            'AccessControl: currenlty not paused'
        );
        _;
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(
            _newCEO != address(0x0),
            'AccessControl: invalid CEO address'
        );
        ceoAddress = _newCEO;
        emit CEOSet(ceoAddress);
    }

    function setWorker(address _newWorker) external {
        require(
            _newWorker != address(0x0),
            'AccessControl: invalid worker address'
        );
        require(
            msg.sender == ceoAddress || msg.sender == workerAddress,
            'AccessControl: invalid worker address'
        );
        workerAddress = _newWorker;
        emit WorkerSet(workerAddress);
    }

    function pause() external onlyWorker whenNotPaused {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyCEO whenPaused {
        paused = false;
        emit Unpaused();
    }
}

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

contract TreasuryBackgammon is AccessController {

    using SafeMath for uint128;
    using SafeMath for uint256;

    enum GameState {NewGame, OnGoingGame, DoublingStage, GameEnded}

    event GameStarted(
        uint256 gameId,
        address indexed playerOne,
        address indexed playerTwo,
        uint8 tokenIndex
    );

    event StakeRaised(
        uint256 gameId,
        address indexed player,
        uint256 stake
    );

    event StakeDoubled(
        uint256 gameId,
        address indexed player,
        uint256 totalStaked
    );

    event PlayerDropped(
        uint256 gameId,
        address indexed player
    );

    event GameResolved(
        uint256 gameId,
        address indexed winner
    );

    struct Game {
        uint256 stake;
        uint256 total;
        address playerOne;
        address playerTwo;
        address lastStaker;
        uint8 tokenIndex;
        GameState state;
    }

    mapping(uint256 => Game) public currentGames;

    modifier onlyDoublingStage(uint256 gameId) {
        require(
            currentGames[gameId].state == GameState.DoublingStage,
            'must be proposed to double first by one of the players'
        );
        _;
    }

    modifier onlyOnGoingGame(uint256 gameId) {
        require(
            currentGames[gameId].state == GameState.OnGoingGame,
            'must be ongoing game'
        );
        _;
    }

    modifier isPlayerInGame(uint256 gameId, address player) {
        require(
            player == currentGames[gameId].playerOne ||
            player == currentGames[gameId].playerTwo,
            'must be one of the players'
        );
        _;
    }

    modifier onlyTreasury() {
        require(
            msg.sender == address(treasury),
            'must be current treasury'
        );
        _;
    }

    TreasuryInstance public treasury;

    struct Store {
        uint8 safeFactor;
        uint8 feePercent;
    }

    Store public s;

    constructor(
        address _treasuryAddress,
        uint8 _safeFactor,
        uint8 _feePercent)
    {
        treasury = TreasuryInstance(_treasuryAddress);
        (s.safeFactor, s.feePercent) = (_safeFactor, _feePercent);
    }

    function initializeGame(
        uint128 _defaultStake,
        address _playerOneAddress,
        address _playerTwoAddress,
        uint8 _tokenIndex
    )
        external
        whenNotPaused
        onlyWorker
        returns (bool)
    {
        require(
            address(_playerOneAddress) != address(_playerTwoAddress),
            'must be two different players'
        );

        uint256 gameId = uint256(
            keccak256(abi.encodePacked(_playerOneAddress, _playerTwoAddress))
        );

        require(
            _defaultStake.mul(s.safeFactor) <= treasury.checkApproval(
                _playerOneAddress, _tokenIndex
            ),
            'P1 must approve/allow treasury as spender'
        );

        require(
            _defaultStake.mul(s.safeFactor) <= treasury.checkApproval(
                _playerTwoAddress, _tokenIndex
            ),
            'P2 must approve/allow treasury as spender'
        );

        require(
            currentGames[gameId].state == GameState.NewGame ||
            currentGames[gameId].state == GameState.GameEnded,
            'cannot initialize running game'
        );

        require(
            treasury.getTokenAddress(_tokenIndex) != address(0x0),
            'token is not delcared in treasury!'
        );

        require(
            _defaultStake <= treasury.getMaximumBet(_tokenIndex),
            'exceeding maximum bet defined in treasury'
        );

        treasury.tokenInboundTransfer(_tokenIndex, _playerOneAddress, _defaultStake);
        treasury.tokenInboundTransfer(_tokenIndex, _playerTwoAddress, _defaultStake);

        Game memory _game = Game(
            _defaultStake,
            _defaultStake.mul(2),
            _playerOneAddress,
            _playerTwoAddress,
            address(0),
            _tokenIndex,
            GameState.OnGoingGame
        );

        currentGames[gameId] = _game;

        emit GameStarted(
            gameId,
            _playerOneAddress,
            _playerTwoAddress,
            _tokenIndex
        );
    }

    function raiseDouble(uint256 _gameId, address _playerRaising)
        external
        whenNotPaused
        onlyWorker
        onlyOnGoingGame(_gameId)
        isPlayerInGame(_gameId, _playerRaising)
    {
        require(
            address(_playerRaising) !=
            address(currentGames[_gameId].lastStaker),
            'same player cannot raise double again'
        );

        require(
            treasury.tokenInboundTransfer(
                currentGames[_gameId].tokenIndex,
                _playerRaising,
                currentGames[_gameId].stake
            ),
            'raising double transfer failed'
        );

        currentGames[_gameId].state = GameState.DoublingStage;
        currentGames[_gameId].lastStaker = _playerRaising;
        currentGames[_gameId].total = currentGames[_gameId].total.add(
            currentGames[_gameId].stake
        );

        emit StakeRaised(
            _gameId,
            _playerRaising,
            currentGames[_gameId].total
        );
    }

    function callDouble(uint256 _gameId, address _playerCalling)
        external
        whenNotPaused
        onlyWorker
        onlyDoublingStage(_gameId)
        isPlayerInGame(_gameId, _playerCalling)
    {
        require(
            address(_playerCalling) !=
            address(currentGames[_gameId].lastStaker),
            'call must come from opposite player who doubled'
        );

        require(
            treasury.tokenInboundTransfer(
                currentGames[_gameId].tokenIndex,
                _playerCalling,
                currentGames[_gameId].stake
            ),
            'calling double transfer failed'
        );

        currentGames[_gameId].total = currentGames[_gameId].total.add(
            currentGames[_gameId].stake
        );

        currentGames[_gameId].stake = currentGames[_gameId].stake.mul(2);
        currentGames[_gameId].state = GameState.OnGoingGame;

        emit StakeDoubled(
            _gameId,
            _playerCalling,
            currentGames[_gameId].total
        );
    }

    function dropGame(uint256 _gameId, address _playerDropping)
        external
        whenNotPaused
        onlyWorker
        onlyDoublingStage(_gameId)
        isPlayerInGame(_gameId, _playerDropping)
    {
        require(
            _playerDropping != currentGames[_gameId].lastStaker,
            'drop must come from opposite player who doubled'
        );

        require(
            treasury.tokenOutboundTransfer(
                currentGames[_gameId].tokenIndex,
                currentGames[_gameId].lastStaker,
                applyPercent(currentGames[_gameId].total)

            ),
            'win amount transfer failed (dropGame)'
        );

        currentGames[_gameId].state = GameState.GameEnded;

        emit PlayerDropped(
            _gameId,
            _playerDropping
        );
    }

    function applyPercent(uint256 _value) public view returns (uint256) {
        return _value.mul(
            100 - uint256(s.feePercent)
        ).div(100);
    }

    function resolveGame(uint256 _gameId, address _winPlayer)
        external
        whenNotPaused
        onlyWorker
        onlyOnGoingGame(_gameId)
        isPlayerInGame(_gameId, _winPlayer)
    {
        require(
            treasury.tokenOutboundTransfer(
                currentGames[_gameId].tokenIndex,
                _winPlayer,
                applyPercent(currentGames[_gameId].total)
            ),
            'win amount transfer failed (resolveGame)'
        );

        currentGames[_gameId].state = GameState.GameEnded;

        emit GameResolved(
            _gameId,
            _winPlayer
        );
    }

    function getGameIdOfPlayers(address playerOne, address playerTwo)
        external
        pure
        returns (uint256 gameId)
    {
        gameId = uint256(keccak256(abi.encodePacked(playerOne, playerTwo)));
    }

    function checkPlayerInGame(uint256 gameId, address player)
        external
        view
        returns (bool)
    {
        if (
            player == currentGames[gameId].playerOne ||
            player == currentGames[gameId].playerTwo
        ) return true;
    }

    function changeSafeFactor(uint8 _newFactor) external onlyCEO {
        require(_newFactor > 0, 'must be above zero');
        s.safeFactor = _newFactor;
    }

    function changeFeePercent(uint8 _newFeePercent) external onlyCEO {
        require(_newFeePercent < 20, 'must be below 20');
        s.feePercent = _newFeePercent;
    }

    function changeTreasury(address _newTreasuryAddress) external onlyCEO {
        treasury = TreasuryInstance(_newTreasuryAddress);
    }

    function _changeTreasury(address _newTreasuryAddress) external onlyTreasury {
        treasury = TreasuryInstance(_newTreasuryAddress);
    }

    function migrateTreasury(address _newTreasuryAddress) external {
        require(
            msg.sender == address(treasury),
            'wrong current treasury address'
        );
        treasury = TreasuryInstance(_newTreasuryAddress);
    }
}