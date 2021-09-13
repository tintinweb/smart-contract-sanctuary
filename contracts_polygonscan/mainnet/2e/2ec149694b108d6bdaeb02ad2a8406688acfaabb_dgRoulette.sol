/**
 *Submitted for verification at polygonscan.com on 2021-09-13
*/

// SPDX-License-Identifier: -- 🎲 --

pragma solidity ^0.7.4;

// Roulette Logic Contract ///////////////////////////////////////////////////////////
// Author: Decentral Games ([email protected]) ///////////////////////////////////////
// Roulette - MultiPlayer - TokenIndex 3.0

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
        workerAddress = creator;
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

contract dgRoulette is AccessController {

    using SafeMath for uint128;
    using SafeMath for uint256;

    uint256 private store;
    uint256 public pointsCap;

    enum GameState { NewGame, OnGoingGame, EndedGame }
    enum BetType { Single, EvenOdd, RedBlack, HighLow, Column, Dozen }

    mapping (address => uint) public totalBets;
    mapping (address => uint) public totalPayout;

    mapping (uint => uint) public maxSquareBets;
    mapping (uint => mapping (uint => mapping (uint => uint))) public currentBets;

    struct Game {
        address[] players;
        uint256 landID;
        uint256 machineID;
        uint8[] betIDs;
        uint8[] betValues;
        uint128[] betAmount;
        uint8[] tokenIndex;
        uint8 playersCount;
        uint8[] wearableBonus;
        GameState state;
    }

    mapping(bytes16 => Game) public Games;

    Bet[] public bets;
    uint256[] winAmounts;

    struct Bet {
        address player;
        uint8 betType;
        uint8 number;
        uint8 tokenIndex;
        uint128 value;
    }

    event BetPlaced(
        bytes16 indexed gameId,
        address[] players,
        uint8[] betIDs,
        uint8[] betValues,
        uint128[] betAmounts,
        uint8[] tokenIndex,
        uint256 indexed landID,
        uint256 indexed machineID
    );

    event GameResult(
        bytes16 _gameId,
        address[] _players,
        uint8[] _tokenIndex,
        uint256 indexed _landID,
        uint256 indexed _number,
        uint256 indexed _machineID,
        uint256[] _winAmounts
    );

    TreasuryInstance public treasury;
    PointerInstance public pointerContract;

    constructor(
        address _treasuryAddress,
        uint128 _maxSquareBetDefault,
        uint8 _maxNumberBets,
        address _pointerAddress
    ) {
        treasury = TreasuryInstance(_treasuryAddress);
        store |= _maxNumberBets<<0;
        store |= _maxSquareBetDefault<<8;
        store |= block.timestamp<<136;
        pointerContract = PointerInstance(_pointerAddress);
        pointsCap = 2;
    }

    function addPoints(
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

    function createBet(
        address _player,
        uint8 _betType,
        uint8 _number,
        uint8 _tokenIndex,
        uint128 _value
    )
        external
        onlyWorker
    {
        bet(
            _player,
            _betType,
            _number,
            _tokenIndex,
            _value
        );
    }


    function bet(
        address _player,
        uint8 _betType,
        uint8 _number,
        uint8 _tokenIndex,
        uint128 _value
    )
        internal
    {
        currentBets[_tokenIndex][_betType][_number] += _value;

        uint256 _maxSquareBet = maxSquareBets[_tokenIndex] == 0
            ? uint128(store>>8)
            : maxSquareBets[_tokenIndex];

        require(
            currentBets[_tokenIndex][_betType][_number] <= _maxSquareBet,
            'Roulette: exceeding maximum bet limit'
        );

        bets.push(Bet({
            player: _player,
            betType: _betType,
            number: _number,
            tokenIndex: _tokenIndex,
            value: _value
        }));
    }

    function _launch(
        bytes16 _gameId,
        bytes32 _localhash,
        address[] memory _players,
        uint8[] memory _tokenIndex,
        uint256 _landID,
        uint256 _machineID
    )
        private
        returns(
            uint256[] memory,
            uint256 number
        )
    {
        require(
            bets.length > 0,
            'Roulette: must have bets'
        );

        delete winAmounts;

        store ^= (store>>136)<<136;
        store |= block.timestamp<<136;

        number = uint(
            keccak256(
                abi.encodePacked(
                    _localhash
                )
            )
        ) % 37;

        for (uint i = 0; i < bets.length; i++) {
            bool won = false;
            Bet memory b = bets[i];
            if (b.betType == uint(BetType.Single) && b.number == number) {
                won = true;
            } else if (b.betType == uint(BetType.EvenOdd) && number <= 36) {
                if (number > 0 && number % 2 == b.number) {
                    won = true;
                }
            } else if (b.betType == uint(BetType.RedBlack) && b.number == 0) {
                if ((number > 0 && number <= 10) || (number >= 19 && number <= 28)) {
                    won = (number % 2 == 1);
                } else {
                    if (number > 0 && number <= 36) {
                        won = (number % 2 == 0);
                    }
                }
            } else if (b.betType == uint(BetType.RedBlack) && b.number == 1) {
                if ((number > 0 && number <= 10) || (number >= 19 && number <= 28)) {
                    won = (number % 2 == 0);
                } else {
                    if (number > 0 && number <= 36) {
                        won = (number % 2 == 1);
                    }
                }
            } else if (b.betType == uint(BetType.HighLow) && number <= 36) {
                if (number >= 19 && b.number == 0) {
                    won = true;
                }
                if (number > 0 && number <= 18 && b.number == 1) {
                    won = true;
                }
            } else if (b.betType == uint(BetType.Column) && number <= 36) {
                if (b.number == 0 && number > 0) won = (number % 3 == 1);
                if (b.number == 1 && number > 0) won = (number % 3 == 2);
                if (b.number == 2 && number > 0) won = (number % 3 == 0);
            } else if (b.betType == uint(BetType.Dozen) && number <= 36) {
                if (b.number == 0) won = (number > 0 && number <= 12);
                if (b.number == 1) won = (number > 12 && number <= 24);
                if (b.number == 2) won = (number > 24 && number <= 36);
            }

            if (won) {
                uint256 betWin = b.value.mul(
                    getPayoutForType(b.betType, b.number)
                );
                winAmounts.push(betWin);
            } else {
                winAmounts.push(0);
            }
            currentBets[b.tokenIndex][b.betType][b.number] = 0;
        }

        delete bets;

        emit GameResult(
            _gameId,
            _players,
            _tokenIndex,
            _landID,
            number,
            _machineID,
            winAmounts
        );

        return(
            winAmounts,
            number
        );
    }

    function placeBets(
        bytes16 _gameId,
        address[] memory _players,
        uint256 _landID,
        uint256 _machineID,
        uint8[] memory _betIDs,
        uint8[] memory _betValues,
        uint128[] memory _betAmount,
        uint8[] memory _tokenIndex,
        uint8 _playerCount,
        uint8[] memory _wearableBonus
    )
        public
        onlyWorker
    {
        require(
            _betIDs.length == _betValues.length,
            'Roulette: inconsistent amount of betsValues'
        );

        require(
            _tokenIndex.length == _betAmount.length,
            'Roulette: inconsistent amount of betAmount'
        );

        require(
            _betValues.length == _tokenIndex.length,
            'Roulette: inconsistent amount of tokenIndex'
        );

        require(
            _betIDs.length <= uint8(store>>0),
            'Roulette: maximum amount of bets reached'
        );

        require(
            Games[_gameId].state == GameState.NewGame ||
            Games[_gameId].state == GameState.EndedGame,
            'Roulette: ongoing game detected'
        );

        Game memory _game = Game(
            _players,
            _landID,
            _machineID,
            _betIDs,
            _betValues,
            _betAmount,
            _tokenIndex,
            _playerCount,
            _wearableBonus,
            GameState.OnGoingGame
        );

        Games[_gameId] = _game;

        bool[5] memory checkedTokens;
        uint8 i;

        for (i = 0; i < _betIDs.length; i++) {

            require(
                treasury.getMaximumBet(_tokenIndex[i]) >= _betAmount[i],
                'Roulette: bet amount is more than maximum'
            );

            treasury.tokenInboundTransfer(
                _tokenIndex[i],
                _players[i],
                _betAmount[i]
            );

            if (!checkedTokens[_tokenIndex[i]]) {
                uint256 tokenFunds = treasury.checkAllocatedTokens(_tokenIndex[i]);
                require(
                    getNecessaryBalance(_tokenIndex[i]) <= tokenFunds,
                    'Roulette: not enough tokens for payout'
                );
                checkedTokens[_tokenIndex[i]] = true;
            }
        }

        emit BetPlaced(
            _gameId,
            _players,
            _betIDs,
            _betValues,
            _betAmount,
            _tokenIndex,
            _landID,
            _machineID
        );
    }

    function resolveGame(
        bytes16 _gameId,
        bytes32 _localhash
    )
        public
        onlyWorker
    {
        require(
            Games[_gameId].state == GameState.OnGoingGame,
            'dgRoulette: not ongoing game detected'
        );

        Games[_gameId].state = GameState.EndedGame;

        for (uint8 i = 0; i < Games[_gameId].betIDs.length; i++) {
            bet(
                Games[_gameId].players[i],
                Games[_gameId].betIDs[i],
                Games[_gameId].betValues[i],
                Games[_gameId].tokenIndex[i],
                Games[_gameId].betAmount[i]
            );
        }

        uint256 _spinResult;
        (winAmounts, _spinResult) = _launch(
            _gameId,
            _localhash,
            Games[_gameId].players,
            Games[_gameId].tokenIndex,
            Games[_gameId].landID,
            Games[_gameId].machineID
        );

        // payout && points preparation
        for (uint8 i = 0; i < winAmounts.length; i++) {
            address player = Games[_gameId].players[i];
            if (winAmounts[i] > 0) {
                treasury.tokenOutboundTransfer(
                    Games[_gameId].tokenIndex[i],
                    Games[_gameId].players[i],
                    winAmounts[i]
                );
                // collecting totalPayout
                totalPayout[player] =
                totalPayout[player] + winAmounts[i];
            }
            totalBets[player] =
            totalBets[player] + Games[_gameId].betAmount[i];
        }

        // point calculation && bonus
        for (uint8 i = 0; i < Games[_gameId].players.length; i++) {
            _issuePointsAmount(
                Games[_gameId].players[i],
                Games[_gameId].tokenIndex[i],
                Games[_gameId].playersCount,
                Games[_gameId].wearableBonus[i]
            );
        }
    }

    function changeCap(
        uint256 _newPointsCap
    )
        external
        onlyCEO
    {
        pointsCap = _newPointsCap;
    }

    function _issuePointsAmount(
        address _player,
        uint8 _tokenIndex,
        uint256 _playerCount,
        uint256 _wearableBonus
    )
        private
    {
        if (totalPayout[_player] > totalBets[_player]) {

            uint256 points = totalPayout[_player].sub(totalBets[_player]);
            uint256 limits = totalBets[_player].mul(pointsCap);

            points = points > limits
                ? limits
                : points;

            addPoints(
                _player,
                points,
                treasury.getTokenAddress(_tokenIndex),
                _playerCount,
                _wearableBonus
            );
        }
        else if (totalPayout[_player] < totalBets[_player]) {
            addPoints(
                _player,
                totalBets[_player].sub(totalPayout[_player]),
                treasury.getTokenAddress(_tokenIndex),
                _playerCount,
                _wearableBonus
            );
        }
        totalBets[_player] = 0;
        totalPayout[_player] = 0;
    }

    function getPayoutForType(
        uint256 _betType,
        uint256 _betNumber
    )
        public
        pure
        returns(uint256)
    {
        if (_betType == uint8(BetType.Single))
            return _betNumber > 36 ? 0 : 36;
        if (_betType == uint8(BetType.EvenOdd))
            return _betNumber > 1 ? 0 : 2;
        if (_betType == uint8(BetType.RedBlack))
            return _betNumber > 1 ? 0 : 2;
        if (_betType == uint8(BetType.HighLow))
            return _betNumber > 1 ? 0 : 2;
        if (_betType == uint8(BetType.Column))
            return _betNumber > 2 ? 0 : 3;
        if (_betType == uint8(BetType.Dozen))
            return _betNumber > 2 ? 0 : 3;

        return 0;
    }

    function getNecessaryBalance(
        uint256 _tokenIndex
    )
        public
        view
        returns (uint256 _necessaryBalance)
    {
        uint256 _necessaryForBetType;
        uint256[6] memory betTypesMax;

        for (uint8 _i = 0; _i < bets.length; _i++) {
            Bet memory b = bets[_i];
            if (b.tokenIndex == _tokenIndex) {

                uint256 _payout = getPayoutForType(b.betType, b.number);
                uint256 _square = currentBets[b.tokenIndex][b.betType][b.number];

                require(
                    _payout > 0,
                    'Roulette: incorrect bet type/value'
                );

                _necessaryForBetType = _square.mul(_payout);

                if (_necessaryForBetType > betTypesMax[b.betType]) {
                    betTypesMax[b.betType] = _necessaryForBetType;
                }
            }
        }

        for (uint8 _i = 0; _i < betTypesMax.length; _i++) {
            _necessaryBalance = _necessaryBalance.add(
                betTypesMax[_i]
            );
        }
    }

    function getBetsCountAndValue()
        external
        view
        returns(uint value, uint)
    {
        for (uint i = 0; i < bets.length; i++) {
            value += bets[i].value;
        }

        return (bets.length, value);
    }

    function getBetsCount()
        external
        view
        returns (uint256)
    {
        return bets.length;
    }

    function changeMaxSquareBet(
        uint256 _tokenIndex,
        uint256 _newMaxSquareBet
    )
        external
        onlyCEO
    {
        maxSquareBets[_tokenIndex] = _newMaxSquareBet;
    }

    function changeMaxSquareBetDefault(
        uint128 _newMaxSquareBetDefault
    )
        external
        onlyCEO
    {
        store ^= uint128((store>>8))<<8;
        store |= _newMaxSquareBetDefault<<8;
    }

    function changeMaximumBetAmount(
        uint8 _newMaximumBetAmount
    )
        external
        onlyCEO
    {
        store ^= uint8(store)<<0;
        store |= _newMaximumBetAmount<<0;
    }

    function changeTreasury(
        address _newTreasuryAddress
    )
        external
        onlyCEO
    {
        treasury = TreasuryInstance(
            _newTreasuryAddress
        );
    }

    function getNextRoundTimestamp()
        external
        view
        returns(uint)
    {
        return store>>136;
    }

    function checkMaximumBetAmount()
        external
        view
        returns (uint8)
    {
        return uint8(store>>0);
    }

    function checkMaxSquareBetDefault()
        external
        view
        returns (uint128)
    {
        return uint128(store>>8);
    }

    function updatePointer(
        address _newPointerAddress
    )
        external
        onlyCEO
    {
        pointerContract = PointerInstance(
            _newPointerAddress
        );
    }
}