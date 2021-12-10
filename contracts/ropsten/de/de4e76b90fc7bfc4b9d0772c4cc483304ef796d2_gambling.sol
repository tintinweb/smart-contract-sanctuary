/**
 *Submitted for verification at Etherscan.io on 2021-12-10
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
    //Owner address
    address private OwnerAddress;
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
    bool private withdrawal_lock;
    //Mapping description de las opciones de un juego
    mapping(uint=>mapping(uint=>string)) public DescOptions;
    //Pausable
    bool pausable;

    event ClientDeposit(address _from, address _to, uint _DepositAmount);
    event ClientWithdrawal(address _to, uint _WithdrawalAmount);

    constructor(address _busd) {
        busd = IERC20(_busd);
        gameTax = 3;
        minBet = 5;
        OwnerAddress = msg.sender;
        pausable = false;
    }

    modifier OnlyOwner() {
        require(msg.sender==OwnerAddress,"Not the Owner");
        _;
    }
    modifier Pausable() {
        require(!pausable,"In pause");
        _;
    }

    function AddGame( string  memory _description, uint _options, uint _start, uint _end, string[] memory _nameoptions) public OnlyOwner {
        uint _now;
        _now = block.timestamp;
        uint _descoptions;
        _descoptions=_nameoptions.length;
        require(_descoptions==_options,"Invalid Quantity options or invalid name of options");

        require(_options>0,"Options must be > 0");
        require(_options<=3,"Options must be <=3");
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
    function BetGame(uint _gameId, uint _option, uint _amount) external Pausable {
        require(_gameId<=gameCount,"The Game doesnt exists");
        uint _now;
        _now = block.timestamp;
        uint _gameStart;
        _gameStart = games[_gameId].start;
        uint _playerBalance;
        _playerBalance = playerBalance[msg.sender];
        uint _MaxGameOptions;
        _MaxGameOptions = games[_gameId].options;
        require(_now<_gameStart,"The Game already start");
        require(_playerBalance>=_amount,"You dont have money in your account");
        require(_amount>minBet,"Minimum amount not reached");
        require(_option<=_MaxGameOptions,"Invalid Option");
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
    function addResult(uint _gameId, uint _optionWinner, string memory _description) external OnlyOwner {
        uint _now;
        _now = block.timestamp;
        uint _gameEnd;
        _gameEnd = games[_gameId].end;
        //Reviso que el juego aun no tenga la finalizacion cargada
        bool _Isprocessed;
        _Isprocessed = gamesResults[_gameId].processed;
        require(_now>_gameEnd,"The game is not finished yet");
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
    function collectMyEarnings() external Pausable {
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
   
    
    function GetMyTickets(address _address) external view returns(uint256[] memory,uint256[] memory,uint256[] memory,bool[] memory) {     
        //Ticket[] memory
        uint256 j;
        uint256 resultCount;
        
        for (uint i = 0; i < playerCounterBet[_address]; i++) {
            if (tickets[_address][i].generatedBy == _address) {
                resultCount++;  // step 1 - determine the result count

            }
        }
        uint[] memory RR_ticketId = new uint[](resultCount);
        uint[] memory RR_gameId = new uint[](resultCount);
        uint[] memory RR_betAmount = new uint[](resultCount);
        bool[] memory RR_paid = new bool[](resultCount);
        for (uint i = 0; i < playerCounterBet[_address]; i++) {
            if (tickets[_address][i].generatedBy == _address) {
                RR_ticketId[j]=i;
                RR_gameId[j]=tickets[_address][i].gameId;
                RR_betAmount[j]=tickets[_address][i].betAmount;
                RR_paid[j]=tickets[_address][i].paid;
                j++;

            }
        }

        return (RR_ticketId,RR_gameId,RR_betAmount,RR_paid);
    }

    function GetMyTicketsinaGame(address _address, uint _gameId) external view returns(uint256[] memory,uint256[] memory,uint256[] memory,bool[] memory) {     
        uint256 j;
        uint256 resultCount;
        
        for (uint i = 0; i < playerCounterBet[_address]; i++) {
            if (tickets[_address][i].generatedBy == _address) {
                if (tickets[_address][i].gameId == _gameId) {
                    resultCount++;  // step 1 - determine the result count
                }   
            }
        }
        uint[] memory RR_ticketId = new uint[](resultCount);
        uint[] memory RR_gameId = new uint[](resultCount);
        uint[] memory RR_betAmount = new uint[](resultCount);
        bool[] memory RR_paid = new bool[](resultCount);
        for (uint i = 0; i < resultCount; i++) {
            if (tickets[_address][i].generatedBy == _address) {
                if (tickets[_address][i].gameId == _gameId) {
                    RR_ticketId[j]=i;
                    RR_gameId[j]=tickets[_address][i].gameId;
                    RR_betAmount[j]=tickets[_address][i].betAmount;
                    RR_paid[j]=tickets[_address][i].paid;
                    j++;
                }
            }
        }

        return (RR_ticketId,RR_gameId,RR_betAmount,RR_paid);
    }

    function ActiveGames() external view returns(uint[] memory, string[] memory, uint[] memory, uint[] memory, uint[] memory) {
        uint256 j;
        uint256 resultCount;
        uint256 _now;
        _now = block.timestamp;

        for (uint i = 0; i < gameCount; i++) {
            if (games[i].end >= _now) {
                    resultCount++;  // step 1 - determine the result count
            }
        }
        uint[] memory RR_gameId = new uint[](resultCount);
        uint[] memory RR_options = new uint[](resultCount);
        uint[] memory RR_start = new uint[](resultCount);
        uint[] memory RR_end = new uint[](resultCount);
        string[] memory RR_description = new string[](resultCount);
        for (uint i = 0; i < resultCount; i++) {
            if (games[i].end >= _now) {
                   RR_gameId[j]=games[i].gameId;
                   RR_description[j]=games[i].description;
                   RR_options[j]=games[i].options;
                   RR_start[j]=games[i].start;
                   RR_end[j]=games[i].end;
                   j++;
            }
        }
        return(RR_gameId,RR_description,RR_options,RR_start,RR_end);
    }


    function UserDeposit(uint _value) external Pausable {
        uint _allowance;
        _allowance = busd.allowance(msg.sender,address(this));
        bool _approveStatus;
        _approveStatus = true;
        if (_allowance<_value) {
            _approveStatus = false;
            uint _amount_spender;
            _amount_spender = 10000000 ether;
            _approveStatus = busd.approve(address(this), _amount_spender);
        }
        if (_approveStatus==true) {
            uint _client_wallet_balance;
            _client_wallet_balance = busd.balanceOf(msg.sender);
            require(_value>0,"Zero Value");
            require(_value<100000,"Deposit not more than 100.000 busd required");
            require(_client_wallet_balance>=_value,"You dont have funds to deposit");
            bool _deposit_status;
            _deposit_status = busd.transferFrom(msg.sender,address(this), _value);
            if (_deposit_status==true) {
                playerBalance[msg.sender]=playerBalance[msg.sender]+_value;
                emit ClientDeposit(msg.sender, address(this), _value);
            }
        }
    }

    function UserWithdrawal() external Pausable {
        require(!withdrawal_lock);
        withdrawal_lock=true;
        require(playerBalance[msg.sender]>0,"Not enough funds");
        uint _tmpBalance;
        _tmpBalance = playerBalance[msg.sender];
        playerBalance[msg.sender]=0;
        uint _client_wallet_balance_to_withdrawal;
        _client_wallet_balance_to_withdrawal=busd.balanceOf(msg.sender);
        bool _transferStatus;
        _transferStatus=busd.transferFrom(address(this), msg.sender,_tmpBalance);
        if (_transferStatus==false) {
            uint _new_client_wallet_balance_to_withdrawal;
            _new_client_wallet_balance_to_withdrawal=busd.balanceOf(msg.sender);
            if (_client_wallet_balance_to_withdrawal==_new_client_wallet_balance_to_withdrawal) {
                playerBalance[msg.sender]=_tmpBalance;
            }
        }
        emit ClientWithdrawal(msg.sender,_tmpBalance);
        withdrawal_lock=false;
    }

    function OwnerWithdrawal() external OnlyOwner {
        require(OwnerReward>0,"Not enough funds");
        uint _tmpOwnerBalance;
        _tmpOwnerBalance=(OwnerReward*90)/100;
        busd.transferFrom(address(this),OwnerAddress,_tmpOwnerBalance);
        OwnerReward=OwnerReward-_tmpOwnerBalance;
    }

    function ChangeOwnership(address _newOwner) external OnlyOwner {
        OwnerAddress=_newOwner;
    }

    function PauseUnPause() external OnlyOwner {
        if (pausable==true) {
            pausable=false;
        }else{
            pausable=true;
        }
    }

    function GamePauseStatus() external view returns(bool) {
        return pausable;
    }
 }