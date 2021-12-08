/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

 contract gambling {
     IERC20 public busd;
     address sc_owner;
     

     struct game {
         uint gameId;
         string description;
         uint options;
         uint start;
         uint end;
     }
     struct gameResult {
         uint gameId;
         string description;
         uint winningOption;
         uint date;
         address addBy;
         uint TotalAmountBet;
         uint winners;
         uint loosers; 
         bool processed;
     }
     struct Ticket {
         uint gameId;
         uint optionSelected;
         uint date;
         uint betAmount;
         uint taxGame;
         address generatedBy;
         bool paid;
     }

    //Tax del juego
    uint gameTax;
    //Contador de juegos
    uint gameCount;
    //Minimo de apuesta
    uint minBet;
    //Reward acumulado del owner
    uint public OwnerReward;
    //Mapping de juegos
    mapping(uint=>game) public games;
    //Mapping de resultado de juegos
    mapping(uint=>gameResult) public gamesResults;
    //Mapping de balance de jugadores
    mapping(address=>uint) public playerBalance;
    //Contador de apuetas del jugador
    mapping(address=>uint) public playerCounterBet;
    //Mapping de apuestas relacionados con el jugador, el valor[] del 2do elemento es el playerCounterBet
    mapping(address=>mapping(uint=>Ticket)) public tickets;
    //Mapping de cantidad de opciones apostadas por juego
    mapping(uint=>mapping(uint=>uint)) OptionsperOption;
    //Mapping de valor total apostado por juego
    mapping(uint=>mapping(uint=>uint)) public AmountperOption;
    //Mapping de Suma Total de todas las opciones apostadas por juego
    mapping(uint=>uint) public AmountperGame;
    //Mapping de todas las veces jugadas
    mapping(uint=>uint) public TotalBetTimes;
    //lock
    bool private lock;
    //Mapping description de las opciones de un juego
    mapping(uint=>mapping(uint=>string)) public DescOptions;
 
    constructor(address _busd) {
        busd = IERC20(_busd);
        gameTax = 3;
        minBet = 5;
    }

    function AddGame( string  memory _description, uint _options, uint _start, uint _end, string[] memory _nameoptions) public {
        uint _now;
        _now = block.timestamp;
        uint _descoptions;
        _descoptions=_nameoptions.length;
        require(_descoptions==_options,"Invalid Quantity options or invalid name of options");

        require(_options>0,"Options must be > 0");
        require(_options<=5,"Options must be <=5");
        require(_start>_now,"Start Date is in the past");
        require(_start<_end,"Start Date must be < End Date");
        games[gameCount] = game({
            gameId: uint(gameCount),
            description: string(_description),
            options: uint(_options),
            start: uint(_start),
            end: uint(_end)
        });
        for (uint i=0; i<_descoptions; i++) {
            DescOptions[gameCount][i]=_nameoptions[i];
        }
        gameCount=gameCount+1;
    }
    function BetGame(uint _gameId, uint _option, uint _amount) external {
        //Falta agregar filtro para que la _option no sea mayor a la maxima opcion del juego
        require(_gameId<=gameCount,"The Game doesnt exists");
        uint _now;
        _now = block.timestamp;
        uint _gameStart;
        _gameStart = games[_gameId].start;
        uint _playerBalance;
        _playerBalance = playerBalance[msg.sender];
        require(_now<_gameStart,"The Game already start");
        require(_playerBalance>=_amount,"You dont have money in your account");
        require(_amount>minBet,"Minimum amount not reached");
        uint _taxOwner;
        uint _BetTotal;
        _taxOwner = (gameTax*_amount)/100;
        _BetTotal = _amount-_taxOwner;
        uint _playerCounterBet;
        _playerCounterBet = playerCounterBet[msg.sender];
        tickets[msg.sender][_playerCounterBet] = Ticket({
            gameId: uint(_gameId),
            optionSelected: uint(_option),
            date: uint(block.timestamp),
            betAmount: uint(_BetTotal),
            taxGame: uint(_taxOwner),
            generatedBy: address(msg.sender),
            paid: bool(false)
        });
        playerCounterBet[msg.sender] = playerCounterBet[msg.sender] + 1;
        OptionsperOption[_gameId][_option]=OptionsperOption[_gameId][_option]+1;
        AmountperOption[_gameId][_option]=AmountperOption[_gameId][_option]+_BetTotal;
        AmountperGame[_gameId]=AmountperGame[_gameId]+_BetTotal;
        TotalBetTimes[_gameId]=TotalBetTimes[_gameId]+1;
        playerBalance[msg.sender]=playerBalance[msg.sender]-_amount;
        OwnerReward = OwnerReward+_taxOwner;
    }
    function addResult(uint _gameId, uint _optionWinner, string memory _description) external {
        uint _now;
        _now = block.timestamp;
        uint _gameEnd;
        _gameEnd = games[_gameId].end;
        //Reviso que el juego aun no tenga la finalizacion cargada
        bool _Isprocessed;
        _Isprocessed = gamesResults[_gameId].processed;
        require(_now>_gameId,"The game is not finished yet");
        require(!_Isprocessed,"Already processed");
        uint _loosers;
        _loosers = TotalBetTimes[_gameId]-OptionsperOption[_gameId][_optionWinner];
        gamesResults[_gameId] = gameResult ({
            gameId: uint(_gameId),
            description: string(_description),
            winningOption: uint(_optionWinner),
            date: uint(block.timestamp),
            addBy: address(msg.sender),
            TotalAmountBet: uint(AmountperGame[_gameId]),
            winners: uint(OptionsperOption[_gameId][_optionWinner]),
            loosers: uint(_loosers),
            processed: bool(true)
        });
    }
    function collectMyEarnings() external {
        require(!lock);
        lock=true;
        uint _playerCounterBet;
        _playerCounterBet = playerCounterBet[msg.sender];
        //Ticket Data
        uint _gameId;
        bool _paid;
        uint _PlayerbetAmount;
        uint _PlayeroptionSelected;
        //Game Result Data
        uint _winningOption;
        uint _TotalAmountBet;
        uint _winners; //Esto me interesa porque si winners == 0, tengo que devolver el valor apostado
        uint _RewardbyClient;
        uint _RewardPercentByClient;
        uint _AmountBetperOption;
        
        for (uint i=0; i<=_playerCounterBet; i++) {
            _gameId = tickets[msg.sender][i].gameId;
            _paid = tickets[msg.sender][i].paid;
            // Saco lo que aposto el cliente
            _PlayerbetAmount = tickets[msg.sender][i].betAmount;
            _PlayeroptionSelected = tickets[msg.sender][i].optionSelected;
            
            if (_paid==false) {
                //Actualizamos como que ya se le pago
                tickets[msg.sender][i].paid=true;
                //Cantidad total de ganadores
                _winners = gamesResults[_gameId].winners;
                _winningOption = gamesResults[_gameId].winningOption;
                if (_winningOption>0) { //Tiene que existir una opcion ganadora mayor a cero
                    if (_winners >0) { // Hay apostadores ganadores
                        if (_winningOption==_PlayeroptionSelected) {
                            // Saco el total apostado
                            _TotalAmountBet = gamesResults[_gameId].TotalAmountBet; 
                            // Saco el total apostado en la opcion
                            _AmountBetperOption = AmountperOption[_gameId][_winningOption]; 
                            //Cuanto aposto el cliente??? Cuanto es el total del porcentaje de la torta??
                            _RewardPercentByClient = (_PlayerbetAmount*100)/_AmountBetperOption;
                            _RewardbyClient = (_TotalAmountBet*_RewardPercentByClient)/100;
                            playerBalance[msg.sender]=playerBalance[msg.sender]+_RewardbyClient;
                            
                        }
                    }else{ //Tengo que devolver porque nadie gano
                        // Se devuelve el importe - el tax del juego
                        playerBalance[msg.sender]=playerBalance[msg.sender]+_PlayerbetAmount;
                    }
                }
            }
        }
        lock=false;
    }
    //Testing Functions
    function Getnow() external view returns(uint) {
        return block.timestamp;
    }
    function Faucet() external {
        playerBalance[msg.sender]=playerBalance[msg.sender]+100;
    }
    //End Testing Functions
    
    function ActiveGames() external view returns(game[] memory) {
        // Aca podemos poner > end entonces se mostraria hasta el final , no obstante podemos
        // tambien poner un end + "x" cantidad de horas, para que siga devolviendolo y pueda ser
        // llamada desde web3 y visto en la web.
        uint j;
        uint _now = block.timestamp;
        /*for (uint i=0; i<gameCount;i++) {
            if (games[i].start>_now) {
                resultCount++;
            }
        }*/
        game[] memory result = new game[](gameCount);
        for (uint i=0; i<gameCount; i++) {
            if (games[i].start>_now) {
                result[j] = games[i];
                j++;
            }
        }
        return result;
    }

    /*
    Faltan funciones de withdrawal del owner y withdrawal del cliente.
    */
 }