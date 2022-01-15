/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Shuffle {
    address owner;
    bool gameOn;
    bool gamePause;
    uint256 gameRound;
    uint256 pool;
    uint256 ticketPrice;
    uint256 ticketNumberCurrent;
    uint8 percentageOwner;
    uint8 percentageWinner;
    uint8 playersCurrent;
    uint8 playersMax;

    event __newGame(uint256 _gameRound);
    event __buyTicker(uint256 _gameRound, address _address, uint256 _value, uint256 _ticketsNumbers, uint _ticketsStart, uint _ticketsEnd);

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
        require(playersCurrent >= playersMax);
        _;
    }

    constructor() payable {
        owner = msg.sender;
        gameOn = true;
        gamePause = false;
        gameRound = 1;
        pool = msg.value;
        ticketPrice = 100000000000000000;
        ticketNumberCurrent = 0;
        percentageOwner = 5;
        percentageWinner = 95;
        playersMax = 3;
        playersCurrent = 0;
    }

    /*
        percentage -
    */

    function percentagesSet(uint8 _percentage) public ownerRequired gameStopRequired {
        require(_percentage <= 100, "El porcentage debe ser >= 100");
        percentageWinner = _percentage;
        percentageOwner = 100 - _percentage;
    }

    /*
        game -
    */

    function gameInfo() public view returns(bool, uint256, uint256, uint256, uint8, uint8, uint256, uint256, uint8, uint8, uint256) {
        uint256 payWinner;
        uint256 payOwner;
        payWinner = (pool / 100) * percentageWinner;
        payOwner = (pool / 100) * percentageOwner;

        return (gameOn, gameRound, pool, ticketPrice, playersCurrent, playersMax, payWinner, payOwner, percentageWinner, percentageOwner, ticketNumberCurrent);
    }

    function gamePauseNextRound() public ownerRequired {
        gamePause = true;
    }

    function gameStart() public ownerRequired gameStopRequired {
        gameOn = true;
    }

    function gameEnd(address _addressWinner) public ownerRequired playersMaxRequired {
        poolPayment(_addressWinner);
        gameReset();
    }


    function gameReset() internal  {
        gameRound += 1;
        playersCurrent = 0;
        ticketNumberCurrent = 0;
        
        if(gamePause)
            gameOn = false;
            gamePause = false;
    }

    /*
        ticker -
    */
    function tickerSetPrice(uint256 _price) public ownerRequired gameStopRequired {
        ticketPrice = _price;
    }

    function tickerBuy(uint256 _ticketPrice) public payable gameOnRequired {
        require(
            playersCurrent <= (playersMax - 1),
            "Ya esta el maximo de jugadores"
        );

        require(
            msg.value == _ticketPrice,
            "El valor no es == al precio del ticker"
        );
        require(
            msg.value >= ticketPrice,
            "No estas enviando el valor minimo de entrada"
        );
        

        uint tickerN = msg.value / ticketPrice;
        uint tickerS = ticketNumberCurrent + 1;
        uint tickerE = ticketNumberCurrent + tickerN;
        
        emit __buyTicker(gameRound, msg.sender, msg.value, tickerN, tickerS, tickerE);
        ticketNumberCurrent += tickerN;
        pool += msg.value;
        playersCurrent += 1;
    }

    /*
        payouts - poolPayment -
    */

    function poolPayment(address _addressWinner) public payable ownerRequired returns (bool) {
        uint256 payWinner;
        uint256 payOwner;
        payWinner = (pool / 100) * percentageWinner;
        payOwner = (pool / 100) * percentageOwner;

        payable(_addressWinner).transfer(payWinner);
        payable(msg.sender).transfer(payOwner);
        pool = 0;

        return true;
    }
}