/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Shuffle {
    /*
        variables globals
    */
    address owner;
    bool gameOn;
    bool gamePause;
    uint256 gameRound;

    uint256 pool;

    uint256 ticketPrice;
    uint256 ticketsCurrentNumber;

    uint256 percentageOwner;
    uint256 percentageWinner;

    uint256 playersMax;
    uint256 playersCurrentNumber;
    uint256 [] playersTimeTracker;
    mapping (address => bool) playersAddressTracker;
    mapping (uint => Player) playersCurrent;
    struct Player {
        uint _timestamp;
        address _address;
        uint256 _value;
        uint256 _tickerNumbers;
        uint256 _tickerStart;
        uint256 _tickerEnd;
    }

    /*
        events -
    */

    event __roundStart(uint256);
    event __roundPayment(uint256, address, uint256);
    event __roundEnd(uint256);
    event __roundPlayersComplete(uint256, uint256, uint256, uint256);
    event __tickerBuy(uint256, address, uint256, uint256, uint256, uint256);

    /*
        modifier
    */

    modifier ownerRequired() {
        require(owner == msg.sender, "No eres el dueno del contrato");
        _;
    }

    modifier gameOnRequired() {
        require(gameOn, "No hay juego en curso");
        _;
    }

    modifier gameStopRequired() {
        require(!gameOn, "Hay un juego en curso");
        _;
    }

    modifier playersMaxRequired() {
        require(playersCurrentNumber >= playersMax);
        _;
    }

    /*
        constructor - 
    */

    constructor() payable {
        owner = msg.sender;
        gameOn = true;
        gameRound = 1;
        pool = msg.value;
        ticketPrice = 100000000000000000;
        ticketsCurrentNumber = 0;
        percentageOwner = 5;
        percentageWinner = 95;
        playersMax = 3;
        playersCurrentNumber = 0;
    }

    /*
        percentage -
    */

    function percentagesSet(uint256 _percentage) public ownerRequired gameStopRequired {
        require(_percentage <= 100, "El porcentage debe ser >= 100");
        percentageWinner = _percentage;
        percentageOwner = 100 - _percentage;
    }

    /*
        game -
    */

    function gameInfo() public view returns(
        bool _gameOn,
        uint256 _gameRound,
        uint256 _pool,
        uint256 _ticketPrice,
        uint256 _playersMax,
        uint256 _playersCurrentNumber,
        uint256 _ticketsCurrentNumber
    ) {
        _gameOn = gameOn;
        _gameRound = gameRound;
        _pool = pool;
        _ticketPrice = ticketPrice;
        _playersMax = playersMax;
        _playersCurrentNumber = playersCurrentNumber;
        _ticketsCurrentNumber = ticketsCurrentNumber;
    }

    function gameStart() public ownerRequired gameStopRequired {
        gameOn = true;
        emit __roundStart(gameRound);
    }

    function roundFinish(address _addressWinner) public ownerRequired playersMaxRequired  {
        roundPayment(_addressWinner);
        gameRound += 1;
        ticketsCurrentNumber = 0;
        playersReset();
        gameOn = false;
    }

    /*
        ticker -
    */
    function tickerSetPrice(uint256 _price) public ownerRequired gameStopRequired {
        ticketPrice = _price;
    }

    function tickerBuy() public payable gameOnRequired {
        require(
            playersCurrentNumber <= (playersMax - 1),
            "Ya esta el maximo de jugadores"
        );

        require(
            msg.value >= ticketPrice,
            "No estas enviando el valor minimo de entrada"
        );
        

        uint256 tickerN = msg.value / ticketPrice;
        uint256 tickerS = ticketsCurrentNumber + 1;
        uint256 tickerE = ticketsCurrentNumber + tickerN;
        
        ticketsCurrentNumber += tickerN;
        pool += msg.value;
        playerSet(msg.sender, msg.value, tickerN, tickerS, tickerE);

        emit __tickerBuy(gameRound, msg.sender, msg.value, tickerN, tickerS, tickerE);
    }

    /*
        players -
    */
    function playersGet() public view returns(Player[] memory) {
        Player[] memory playersAll = new Player[](playersTimeTracker.length);

        for (uint i = 0; i < playersTimeTracker.length; i++) {
            Player memory _gplayer = playersCurrent[playersTimeTracker[i]];

            playersAll[i] = _gplayer;
        }

        return playersAll;
    }
    
    function playerSet(address _address, uint256 _value, uint256 _tickerN, uint256 _tickerS, uint256 _tickerE) internal {
        uint256 time = block.timestamp;
        playersCurrent[time] = Player(time, _address, _value, _tickerN, _tickerS, _tickerE);
        playersTimeTracker.push(time);

        if(!playersAddressTracker[_address]) {
            playersCurrentNumber++;
        }

        playersAddressTracker[_address] = true;

        if (playersCurrentNumber >= playersMax) {
            emit __roundPlayersComplete(gameRound, playersMax, playersCurrentNumber, ticketsCurrentNumber);
        }
    }


    function playersReset() internal returns (bool) {
        for (uint i = 0; i < playersTimeTracker.length; i++) {
            delete playersAddressTracker[playersCurrent[playersTimeTracker[i]]._address];
        }

        for (uint i = 0; i < playersTimeTracker.length; i++) {
            delete playersCurrent[playersTimeTracker[i]];
        }

        playersCurrentNumber = 0;
        delete playersTimeTracker;
        emit __roundEnd(gameRound);  
        
        return true;
    }

    /*
        payouts - roundPayment -
    */

    function roundPayment(address _addressWinner) public payable ownerRequired {
        uint256 payWinner;
        uint256 payOwner;
        payWinner = (pool / 100) * percentageWinner;
        payOwner = (pool / 100) * percentageOwner;

        payable(_addressWinner).transfer(payWinner);
        payable(msg.sender).transfer(payOwner);
        pool = 0;
        emit __roundPayment(gameRound, _addressWinner, payWinner);
    }
}