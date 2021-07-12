/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

// SPDX-License-Identifier: -- 🎲 --

pragma solidity ^0.7.0;

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

contract HashChain {
    bytes32 public tail;

    function _setTail(bytes32 _tail) internal {
        tail = _tail;
    }

    function _consume(bytes32 _parent) internal {
        require(
            keccak256(
                abi.encodePacked(_parent)
            ) == tail,
            'hash-chain: wrong parent'
        );
        tail = _parent;
    }
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

interface PointerInstance {
    function addPoints(
        address _player,
        uint256 _points
    ) external returns (bool);
}

contract BlackJackHelper {

    function getCardsRawData(uint8 _card) public pure returns (uint8, uint8) {
        return (_card / 13, _card % 13);
    }

    function getCardsDetails(uint8 _card) public pure returns (string memory, string memory) {

        string[4] memory Suits = ["C", "D", "H", "S"];
        string[13] memory Vals = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K"];

        (uint8 _suit, uint8 _val) = getCardsRawData(_card);
        return (Suits[_suit], Vals[_val]);
    }

    function getRandomCardIndex(bytes32 _localhash, uint256 _length) internal pure returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    _localhash, _length
                )
            )
        ) % _length;
    }

    function getCardsPower(uint8 _card) public pure returns (uint8 power) {
        bytes13 cardsPower = "\x0B\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0A\x0A\x0A";
        return uint8(cardsPower[_card % 13]);
    }

    function getHandsPower(uint8[] memory _cards) public pure returns (uint8 powerMax) {

        uint8 aces;
        uint8 power;

        for (uint8 i = 0; i < _cards.length; i++) {
            power = getCardsPower(_cards[i]);
            powerMax += power;
            if (power == 11) {
                aces += 1;
            }
        }
        if (powerMax > 21) {
            for (uint8 i = 0; i < aces; i++) {
                powerMax -= 10;
                if (powerMax <= 21) {
                    break;
                }
            }
        }
        return powerMax;
    }

    function isBlackJack(uint8[] memory _cards) public pure returns (bool) {
        return getHandsPower(_cards) == 21 && _cards.length == 2;
    }

    function canSplitCards(uint8[] memory _cards) public pure returns (bool) {
        return getCardsPower(_cards[0]) == getCardsPower(_cards[1]) && _cards.length == 2;
    }

    function verifyHiddenCard(bytes32 _hashChild, bytes32 _hashParent) public pure returns (bool) {
        return keccak256(
            abi.encodePacked(_hashParent)
        ) == _hashChild ? true : false;
    }

}

contract dgBlackJack is AccessController, BlackJackHelper, HashChain {

    using SafeMath for uint128;
    using SafeMath for uint256;

    enum inGameState { notJoined, Playing, EndedPlay }
    enum GameState { NewGame, OnGoingGame, EndedGame }
    enum PlayerState { notBusted, hasSplit, isSplit, isSettled, isBusted, hasBlackJack }

    struct Game {
        address[] players;
        uint128[] bets;
        uint8[] tokens;
        uint8[] deck;
        PlayerState[] pState;
        GameState state;
    }

    struct HiddenCard {
        bytes32 hashChild;
        bytes32 hashParent;
    }

    mapping(bytes16 => Game) public Games;
    mapping(bytes16 => HiddenCard) public DealersHidden;
    mapping(bytes16 => uint8[]) public DealersVisible;
    mapping(bytes16 => uint8[]) public NonBustedPlayers;
    mapping(address => mapping(bytes16 => uint8[])) PlayersHand;
    mapping(address => mapping(bytes16 => uint8[])) public PlayerSplit;
    mapping(address => mapping(bytes16 => bool)) public PlayersInsurance;
    mapping(address => mapping(bytes16 => inGameState)) public inGame;

    modifier onlyOnGoingGame(bytes16 _gameId) {
        require(
            Games[_gameId].state == GameState.OnGoingGame,
            'BlackJack: not ongoing game'
        );
        _;
    }

    modifier ifPlayerInGame(bytes16 _gameId, address _player, uint8 _pIndex) {
        require(
            Games[_gameId].players[_pIndex] == _player &&
            inGame[_player][_gameId] == inGameState.Playing,
            'BlackJack: wrong player'
        );
        _;
    }

    modifier onlyNonBustedOrSplit(bytes16 _gameId, uint8 _pIndex) {
        require(
            Games[_gameId].pState[_pIndex] == PlayerState.notBusted ||
            Games[_gameId].pState[_pIndex] == PlayerState.hasSplit ||
            Games[_gameId].pState[_pIndex] == PlayerState.isSplit,
            'BlackJack: player already settled or busted'
        );
        _;
    }

    modifier onlyNonBusted(bytes16 _gameId, uint8 _pIndex) {
        require(
            Games[_gameId].pState[_pIndex] == PlayerState.notBusted,
            'BlackJack: player busted'
        );
        _;
    }

    modifier whenTableSettled(bytes16 _gameId) {
        address[] memory _players = Games[_gameId].players;
        for (uint256 i = 0; i < _players.length; i++) {
            require(
                uint8(Games[_gameId].pState[i]) >= uint8(PlayerState.isSettled),
                'BlackJack: table not settled'
            );
        }
        _;
    }

    TreasuryInstance public treasury;

    uint8 maxPlayers;
    uint256 nonce;

    event BetPlaced(
        uint8 tokenIndex,
        address player,
        uint256 betAmount
    );

    event GameInitializing(
        bytes16 gameId
    );

    event GameInitialized(
        bytes16 gameId,
        address[] players,
        uint128[] bets,
        uint8[] tokens,
        uint256 landId,
        uint256 tableId
    );

    event PlayerCardDrawn(
        bytes16 gameId,
        address player,
        uint8 playerIndex,
        uint8 cardsIndex,
        string cardSuit,
        string cardVal
    );

    event DealersCardDrawn(
        bytes16 gameId,
        uint8 cardsIndex,
        string cardSuit,
        string cardVal
    );

    event DealersCardRevealed(
        bytes16 gameId,
        uint8 cardsIndex,
        string cardSuit,
        string cardVal
    );

    event splitHand(
        bytes16 gameId,
        address player,
        uint8[] hand,
        uint8[] split
    );

    event InsurancePurchased(
        bytes16 gameId,
        address player,
        uint8 playerIndex
    );

    event InsurancePayout(
        address player,
        uint256 amount
    );

    event PlayersPayout(
        address player,
        uint256 amount
    );

    event FinishedGame(
        bytes16 gameId,
        bytes32 localhashB
    );

    constructor(
        address _treasuryAddress,
        uint8 _maxPlayers
    ) {
        require(_maxPlayers < 10);
        treasury = TreasuryInstance(_treasuryAddress);
        maxPlayers = _maxPlayers;
    }

    function setTail(bytes32 _localhashB) external onlyCEO {
        _setTail(_localhashB);
    }

    function checkPlayer(bytes16 _gameId, address _player) private {
        require(
            inGame[_player][_gameId] == inGameState.notJoined ||
            inGame[_player][_gameId] == inGameState.EndedPlay
        );
        inGame[_player][_gameId] = inGameState.Playing;
    }

    function takePlayersBet(bytes16 _gameId, uint8 _playerIndex) private {

        uint8 tokenIndex = Games[_gameId].tokens[_playerIndex];
        address player = Games[_gameId].players[_playerIndex];
        uint256 betAmount = Games[_gameId].bets[_playerIndex];

        require(
            treasury.getMaximumBet(tokenIndex) >= betAmount,
            'BlackJack: bet amount is more than maximum'
        );

        treasury.tokenInboundTransfer(
            tokenIndex, player, betAmount
        );

        emit BetPlaced(
            tokenIndex, player, betAmount
        );
    }

    function initializePlayer(bytes16 _gameId, uint8 _playerIndex) private {
        Games[_gameId].pState[_playerIndex] = PlayerState.notBusted;
    }

    function checkForBlackJack(bytes16 _gameId, address _player, uint8 _playerIndex) private {

        if (
            isBlackJack(
                    getHand(_gameId, _player, _playerIndex)
            )) {
            NonBustedPlayers[_gameId].push(_playerIndex);
            Games[_gameId].pState[_playerIndex] = PlayerState.hasBlackJack;
        }
    }

    function drawDealersCard(
        bytes16 _gameId,
        bytes32 _localhashA,
        uint256 _deckLength
    )
        private
    {
        uint8 _card = drawCard(_gameId, getRandomCardIndex(
                _localhashA, _deckLength
            )
        );

        (
            string memory _cardsSuit,
            string memory _cardsVal
        ) = getCardsDetails(_card);

        DealersVisible[_gameId].push(_card);

        emit DealersCardDrawn(
            _gameId,
            _card,
            _cardsSuit,
            _cardsVal
        );
    }

    function drawPlayersCard(
        bytes16 _gameId,
        uint8 _pIndex,
        bytes32 _localhashA,
        uint256 _deckLength
    )
        private
    {
        address _player = Games[_gameId].players[_pIndex];

        uint8 _card = drawCard(_gameId, getRandomCardIndex(
                _localhashA, _deckLength
            )
        );

        (
            string memory _cardsSuit,
            string memory _cardsVal
        ) = getCardsDetails(_card);

        uint8[] storage playersHand = hasSplit(_gameId, _pIndex)
            ? PlayerSplit[_player][_gameId]
            : PlayersHand[_player][_gameId];

        playersHand.push(_card);

        emit PlayerCardDrawn(
            _gameId,
            _player,
            _pIndex,
            _card,
            _cardsSuit,
            _cardsVal
        );
    }

    function initializeGame(
        address[] calldata _players,
        uint128[] calldata _bets,
        uint8[] calldata _tokens,
        uint256 _landId,
        uint256 _tableId,
        bytes32 _localhashA,
        bytes32 _localhashB
    )
        external
        whenNotPaused
        onlyWorker
        returns (bytes16 gameId)
    {
        require(
            _players.length <= maxPlayers &&
            _bets.length == _tokens.length &&
            _tokens.length == _players.length,
            'BlackJack: wrong parameters'
        );

        _consume(_localhashB);
        treasury.consumeHash(_localhashA);

        gameId = getGameId(_landId, _tableId, _players, nonce);
        nonce = nonce + 1;

        require(
            Games[gameId].state == GameState.NewGame ||
            Games[gameId].state == GameState.EndedGame,
            'BlackJack: cannot initialize running game'
        );

        // starting to initialize game
        emit GameInitializing(gameId);

        uint8[] storage _deck = prepareDeck(gameId);

        Game memory _game = Game(
            _players,
            _bets,
            _tokens,
            _deck,
            new PlayerState[](_players.length),
            GameState.OnGoingGame
        );

        Games[gameId] = _game;

        uint8 pIndex; // playersIndex

        // first card drawn to each player + take bets
        for (pIndex = 0; pIndex < _players.length; pIndex++) {

            checkPlayer(
                gameId, _players[pIndex]
            );

            initializePlayer(
                gameId, pIndex
            );

            takePlayersBet(
                gameId, pIndex
            );

            drawPlayersCard(
                gameId, pIndex, _localhashA, _deck.length
            );
        }

        // dealers first card (visible)
        drawDealersCard(
            gameId, _localhashA, _deck.length
        );

        delete NonBustedPlayers[gameId];

        // players second cards (visible)
        for (pIndex = 0; pIndex < _players.length; pIndex++) {

            drawPlayersCard(
                gameId, pIndex, _localhashA, _deck.length
            );

            checkForBlackJack(
                gameId, _players[pIndex], pIndex
            );
        }

        delete pIndex;

        // dealers second card (hidden)
        DealersHidden[gameId] =
            HiddenCard({
                hashChild: _localhashB,
                hashParent: 0x0
            });

        // game initialized
        emit GameInitialized(
            gameId,
            _players,
            _bets,
            _tokens,
            _landId,
            _tableId
        );
    }

    function prepareDeck(
        bytes16 _gameId
    )
        internal
        returns (uint8[] storage _deck)
    {
        _deck = Games[_gameId].deck;
		for (uint8 i = 0; i < 52; i++) {
			_deck.push(i);
		}
    }

    function drawCard(
        bytes16 _gameId,
        uint256 _card
    ) internal returns (uint8) {
        uint8[] storage _deck = Games[_gameId].deck;
        uint8 card = _deck[_card];
        _deck[_card] = _deck[_deck.length - 1];
        _deck.pop();
        return card;
    }

    function hitMove(
        bytes16 _gameId,
        address _player,
        uint8 _pIndex,
        bytes32 _localhashA
    )
        external
        onlyWorker
        onlyOnGoingGame(_gameId)
        onlyNonBustedOrSplit(_gameId, _pIndex)
        ifPlayerInGame(_gameId, _player, _pIndex)
    {
        treasury.consumeHash(_localhashA);

        drawPlayersCard(
           _gameId, _pIndex, _localhashA, Games[_gameId].deck.length
        );

        uint256 playersPower = getHandsPower(
            getHand(_gameId, _player, _pIndex)
        );

        if (playersPower > 21) {
            Games[_gameId].pState[_pIndex] = PlayerState.isBusted;
        }

        if (playersPower == 21) {
            NonBustedPlayers[_gameId].push(_pIndex);
            Games[_gameId].pState[_pIndex] = PlayerState.isSettled;
        }
    }

    function stayMove(
        bytes16 _gameId,
        address _player,
        uint8 _pIndex
    )
        external
        onlyWorker
        onlyOnGoingGame(_gameId)
        onlyNonBustedOrSplit(_gameId, _pIndex)
        ifPlayerInGame(_gameId, _player, _pIndex)
    {
        NonBustedPlayers[_gameId].push(_pIndex);
        Games[_gameId].pState[_pIndex] = PlayerState.isSettled;
    }

    function revealDealersCard(
        bytes16 _gameId,
        bytes32 _localhashB
    )
        internal
    {
        uint8 revealed = drawCard(_gameId, getRandomCardIndex(
                _localhashB, Games[_gameId].deck.length
            )
        );

        _consume(_localhashB);

        (
            string memory _cardsSuit,
            string memory _cardsVal
        ) = getCardsDetails(revealed);

        DealersVisible[_gameId].push(revealed);

        emit DealersCardRevealed(
            _gameId,
            revealed,
            _cardsSuit,
            _cardsVal
        );
    }

    function dealersMove(
        bytes16 _gameId,
        bytes32 _localhashA,
        bytes32 _localhashB
    )
        external
        onlyWorker
        onlyOnGoingGame(_gameId)
        whenTableSettled(_gameId)
    {
        require(
            DealersHidden[_gameId].hashParent == 0x0,
            'BlackJack: delaers move done in this game'
        );

        DealersHidden[_gameId].hashParent = _localhashB;

        require(
            verifyHiddenCard(
                DealersHidden[_gameId].hashChild,
                DealersHidden[_gameId].hashParent
            ) == true
        );

        treasury.consumeHash(_localhashA);
        revealDealersCard(_gameId, _localhashB);

        uint8[] memory _leftPlayers = getNotBustedPlayers(_gameId);

        // check if any player left in the game
        if (_leftPlayers.length > 0) {

            // check if dealer has a blackjack - proceed to payout
            if (isBlackJack(DealersVisible[_gameId])) {

                $payoutAgainstBlackJack(_gameId, _leftPlayers);

            // check if dealer needs more cards
            } else {

                uint256 dealersPower = getHandsPower(
                    DealersVisible[_gameId]
                );

                uint8 _card;

                // draw cards for dealer with _localhashA
                while (dealersPower <= 16) {

                    _card = drawCard(_gameId, getRandomCardIndex(
                            _localhashA, Games[_gameId].deck.length
                        )
                    );

                    (
                        string memory _cardsSuit,
                        string memory _cardsVal
                    ) = getCardsDetails(_card);

                    DealersVisible[_gameId].push(_card);

                    emit DealersCardDrawn(
                        _gameId,
                        _card,
                        _cardsSuit,
                        _cardsVal
                    );

                    dealersPower = getHandsPower(
                        DealersVisible[_gameId]
                    );
                }

                delete _card;

                // calculate any winnings and payout
                $payoutAgainstDealersHand(_gameId, _leftPlayers, dealersPower);
            }
        }

        // mark all players finishing the game
        address[] memory _players = Games[_gameId].players;
        for (uint256 i = 0; i < _players.length; i++) {
            inGame[_players[i]][_gameId] = inGameState.EndedPlay;
        }

        // set game status to ended
        Games[_gameId].state = GameState.EndedGame;

        emit FinishedGame(
            _gameId,
            _localhashB
        );
    }

    function $payoutAgainstBlackJack(bytes16 _gameId, uint8[] memory _leftPlayers) private {
        for (uint256 i = 0; i < _leftPlayers.length; i++) {

            address player = Games[_gameId].players[_leftPlayers[i]];

            // payout if player also has a blackjack
            if (Games[_gameId].pState[i] == PlayerState.hasBlackJack) {

                uint128 amount = Games[_gameId].bets[_leftPlayers[i]];

                payoutAmount(
                    Games[_gameId].tokens[_leftPlayers[i]],
                    player,
                    amount
                );

                emit PlayersPayout(
                    player,
                    amount
                );
            }

            // payout if player purchased insurance
            if (PlayersInsurance[player][_gameId] == true) {

                uint128 amount = Games[_gameId].bets[_leftPlayers[i]];

                payoutAmount(
                    Games[_gameId].tokens[_leftPlayers[i]],
                    player,
                    amount
                );

                emit InsurancePayout(
                    player,
                    amount
                );
            }
        }
    }

    function $payoutAgainstDealersHand(bytes16 _gameId, uint8[] memory _leftPlayers, uint256 _dealersPower) private {
        for (uint256 i = 0; i < _leftPlayers.length; i++) {

            uint8 pi = _leftPlayers[i]; // players index
            address player = Games[_gameId].players[pi];
            uint256 playersPower = getHandsPower(getHand(_gameId, player, pi));
            uint128 payout;

            if (Games[_gameId].pState[pi] == PlayerState.hasBlackJack) {
                payout = Games[_gameId].bets[pi] * 250 / 100;
            }
            else if (playersPower > _dealersPower) {
                payout = Games[_gameId].bets[pi] * 200 / 100;
            }
            else if (playersPower == _dealersPower) {
                payout = Games[_gameId].bets[pi];
            }

            if (payout > 0) {
                payoutAmount(
                    Games[_gameId].tokens[pi],
                    player,
                    payout
                );
                emit PlayersPayout(
                    player,
                    payout
                );
            }
        }
    }

    function getNotBustedPlayers(bytes16 _gameId) public view returns (uint8[] memory) {
        return NonBustedPlayers[_gameId];
    }

    function payoutAmount(uint8 _tokenIndex, address _player, uint128 _amount) private {
        treasury.tokenOutboundTransfer(
            _tokenIndex, _player, uint256(_amount)
        );
    }

    function splitCards(
        bytes16 _gameId,
        address _player,
        uint8 _pIndex
    )
        external
        onlyWorker
        onlyOnGoingGame(_gameId)
        onlyNonBusted(_gameId, _pIndex)
        ifPlayerInGame(_gameId, _player, _pIndex)
    {
        require(
            PlayerSplit[_player][_gameId].length == 0 &&
            canSplitCards(PlayersHand[_player][_gameId]),
            'BlackJack: wrong split!'
        );

        Games[_gameId].players.push(_player);
        Games[_gameId].bets.push(Games[_gameId].bets[_pIndex]);
        Games[_gameId].tokens.push(Games[_gameId].tokens[_pIndex]);
        Games[_gameId].pState.push(PlayerState.isSplit);
        Games[_gameId].pState[_pIndex] = PlayerState.hasSplit;

        takePlayersBet(
            _gameId, _pIndex
        );

        PlayersHand[_player][_gameId].pop();
        PlayerSplit[_player][_gameId] = PlayersHand[_player][_gameId];

        emit splitHand(
            _gameId,
            _player,
            PlayersHand[_player][_gameId],
            PlayerSplit[_player][_gameId]
        );
    }

    function purchaseInsurance(
        bytes16 _gameId,
        address _player,
        uint8 _pIndex
    )
        external
        onlyWorker
        onlyOnGoingGame(_gameId)
        onlyNonBusted(_gameId, _pIndex)
    {
        require (
            PlayersHand[_player][_gameId].length == 2 &&
            PlayersInsurance[_player][_gameId] == false,
            'BlackJack: insurance denied!'
        );

        require (
            DealersVisible[_gameId].length == 1 &&
            getHandsPower(DealersVisible[_gameId]) == 11 ,
            'BlackJack: not an ace!'
        );

        PlayersInsurance[_player][_gameId] = true;

        uint8 tokenIndex = Games[_gameId].tokens[_pIndex];
        address player = Games[_gameId].players[_pIndex];
        uint256 betAmount = Games[_gameId].bets[_pIndex];

        treasury.tokenInboundTransfer(
            tokenIndex, player, betAmount.div(2)
        );

        emit InsurancePurchased(
            _gameId, player, _pIndex
        );
    }

    function doubleDown(
        bytes16 _gameId,
        address _player,
        bytes32 _localhashA,
        uint8 _pIndex
    )
        external
        onlyWorker
        onlyOnGoingGame(_gameId)
        onlyNonBusted(_gameId, _pIndex)
        ifPlayerInGame(_gameId, _player, _pIndex)
    {
        require (
            PlayersHand[_player][_gameId].length == 2,
            'BlackJack: double down denied'
        );

        treasury.consumeHash(_localhashA);

        treasury.tokenInboundTransfer(
            Games[_gameId].tokens[_pIndex],
            _player,
            Games[_gameId].bets[_pIndex]
        );

        Games[_gameId].bets[_pIndex] =
        Games[_gameId].bets[_pIndex] * 2;

        drawPlayersCard(
           _gameId, _pIndex, _localhashA, Games[_gameId].deck.length
        );

        uint256 playersPower = getHandsPower(
            getHand(_gameId, _player, _pIndex)
        );

        emit DoubleDown(
            playersPower
        );

        if (playersPower > 21) {
            Games[_gameId].pState[_pIndex] = PlayerState.isBusted;
            emit Busted(true);
        } else {
            NonBustedPlayers[_gameId].push(_pIndex);
            Games[_gameId].pState[_pIndex] = PlayerState.isSettled;
            emit Busted(false);
        }
    }

    event DoubleDown(
        uint256 powerAfter
    );

    event Busted(
        bool
    );

    function checkDeck(
        bytes16 _gameId
    )
        public
        view
        returns (uint8[] memory _deck)
    {
        return Games[_gameId].deck;
    }

    function getGameId(
        uint256 _landID,
        uint256 _tableID,
        address[] memory _players,
        uint256 _nonce
    )
        public
        pure
        returns (bytes16 gameId)
    {
        gameId = bytes16(
            keccak256(
                abi.encodePacked(_landID, _tableID, _players, _nonce)
            )
        );
    }

    function checkPlayerInGame(
        bytes16 _gameId,
        address _player
    )
        external
        view
        returns (bool)
    {
        return inGame[_player][_gameId] == inGameState.notJoined ? false : true;
    }

    function checkMyHand(
        bytes16 _gameId
    )
        external
        view
        returns (uint8[] memory)
    {
        return checkPlayersHand(_gameId, msg.sender);
    }

    function checkMySplit(
        bytes16 _gameId
    )
        external
        view
        returns (uint8[] memory)
    {
        return checkPlayerSplit(_gameId, msg.sender);
    }

    function checkDealersHand(
        bytes16 _gameId
    )
        public
        view
        returns (uint8[] memory)
    {
        return DealersVisible[_gameId];
    }

    function checkPlayersHand(
        bytes16 _gameId,
        address _player
    )
        public
        view
        returns (uint8[] memory)
    {
        return PlayersHand[_player][_gameId];
    }

    function checkPlayerSplit(
        bytes16 _gameId,
        address _player
    )
        public
        view
        returns (uint8[] memory)
    {
        return PlayerSplit[_player][_gameId];
    }

    function getHand(
        bytes16 _gameId,
        address _player,
        uint8 _playerIndex
    )
        public
        view
        returns (uint8[] memory playersHand)
    {
        playersHand = hasSplit(_gameId, _playerIndex)
            ? PlayerSplit[_player][_gameId]
            : PlayersHand[_player][_gameId];
    }

    function hasSplit(
        bytes16 _gameId,
        uint8 _pIndex
    )
        public
        view
        returns (bool)
    {
        return Games[_gameId].pState[_pIndex] == PlayerState.isSplit;
    }

    function changeTreasury(
        address _newTreasuryAddress
    )
        external
        onlyCEO
    {
        treasury = TreasuryInstance(_newTreasuryAddress);
    }
}