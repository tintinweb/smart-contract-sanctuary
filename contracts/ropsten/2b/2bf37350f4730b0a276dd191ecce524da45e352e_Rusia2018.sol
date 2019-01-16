pragma solidity ^0.4.24;

/**
 * Contrato inteligente donde crearemos un tipo apuesta de equipos
 * author: Miguel Lomeli
 * email: miguel_AT_lomeli.io
 * version: 23/06/2018
 */


contract Rusia2018 {






    struct Team{
        uint256 slug;
        string name;
        uint256 goals;
        uint256 played;
        uint256 date;
        bool status;
    }

    struct Competitor{
        address user;
        uint256 team;
        uint256 value;
        uint256 date;
        bool statusPay;
        bool statusTeam;
    }


    address public owner;
    address public API;
    uint256 public EntryPrice;
    bool public stopped = false;
    mapping (address => Competitor) public Competitors;
    mapping (uint256 => Team) public Teams;
    uint256[] public teams;
    address[] public competitors;
    address[] public ganadores;




    constructor() public{
        owner = msg.sender;
        API = msg.sender;
    }


    modifier onlyOwner{
        require(owner == msg.sender);
        _;
    }


    modifier onlyAPI{
        require(API == msg.sender);
        _;
    }


    modifier isRunning {
        require(!stopped);
        _;
    }

    modifier validAddress {
        require(0x0 != msg.sender);
        _;
    }

    function stop() onlyOwner public {
        stopped = true;
    }


    function start() onlyOwner public {
        stopped = false;
    }


    function setPrice(uint256 _EntryPrice) onlyOwner isRunning public returns (bool success){
        EntryPrice = _EntryPrice;
        return true;
    }



    function setAPI(address _API) onlyOwner isRunning public returns (bool success){
        API = _API;
        return true;
    }




    function setGoalsPlayed(uint256 _slug , uint256 _goals , uint256 _played , bool _status) onlyOwner isRunning public returns (bool success){
        Teams[_slug].goals = _goals;
        Teams[_slug].played = _played;
        Teams[_slug].status = _status;
        return true;
    }




    function setRetiro(address envio) onlyOwner isRunning public returns (bool success){
        envio.transfer(this.balance);
        return true;
    }



    function Finished(uint256 _slug) onlyOwner isRunning public returns (bool success){



        for(uint256 i=0; i<competitors.length; i++){
            if( Competitors[competitors[i]].team == _slug ){



                ganadores.push(competitors[i]);


            }
        }

        
        
        uint256 saldoContrato = this.balance;

        uint256 saldoGanadores = ganadores.length;

        uint256 saldoEntregar = saldoContrato - (saldoGanadores*EntryPrice);

        uint256 porcentajeParaMi = 10;

        uint256 saldoParaMi = (saldoEntregar * porcentajeParaMi)/100;

        saldoEntregar -= saldoParaMi;

        uint256 saldoApagar = saldoEntregar / saldoGanadores;


        owner.transfer(saldoParaMi);


        for(uint x=0; x<ganadores.length; x++){

            ganadores[x].transfer(saldoApagar);

        }






        return true;
    }







    function setTeam(uint256 _slug , string _name) onlyOwner isRunning public returns (bool success){
        Teams[_slug].slug = _slug;
        Teams[_slug].name = _name;
        Teams[_slug].goals = 0;
        Teams[_slug].played = 0;
        Teams[_slug].status = true;
        Teams[_slug].date = now;
        teams.push(_slug);
        emit TeamEvent(_slug, _name, now);
        return true;
    }



    function Pay() payable isRunning validAddress public {
        require(owner != msg.sender);
        uint256 value = msg.value;
        if( value >= EntryPrice ){
            Competitors[msg.sender].user = msg.sender;
            Competitors[msg.sender].value = value;
            Competitors[msg.sender].statusPay = true;
            Competitors[msg.sender].date = now;
            competitors.push(msg.sender);
            emit CompetitorEvent(msg.sender, value, now);
        } else {
            revert();
        }
    }


    function competitorExists() internal view returns(bool) {
        return Competitors[msg.sender].statusPay;
    }


    function competitorTeam(uint256 _slug) isRunning validAddress public returns (bool success){
        require(competitorExists());
        Competitors[msg.sender].team = _slug;
        Competitors[msg.sender].statusTeam = true;
        emit CompetitorTeamEvent(msg.sender, _slug, now);
        return true;
    }



    function competitorPAY(uint256 _slug) payable isRunning validAddress public {
        require(owner != msg.sender);
        uint256 value = msg.value;
        if( value >= EntryPrice ){
            Competitors[msg.sender].user = msg.sender;
            Competitors[msg.sender].value = value;
            Competitors[msg.sender].statusPay = true;
            Competitors[msg.sender].team = _slug;
            Competitors[msg.sender].statusTeam = true;
            Competitors[msg.sender].date = now;
            competitors.push(msg.sender);
            emit CompetitorEvent(msg.sender, value, now);
            emit CompetitorTeamEvent(msg.sender, _slug, now);
        } else {
            revert();
        }
    }







    function getBalance() view public returns (uint256 balance){
        return address(0x0).balance;
    }

    function getBalance2() view public returns (uint256 balance){
        return this.balance;
    }



    function listCompetitors() external view returns(address[]){
        return competitors;
    }

    function listTeams() external view returns(uint256[]){
        return teams;
    }




    event TeamEvent(uint256 indexed _slug, string indexed _name, uint256 indexed _date);
    event CompetitorEvent(address indexed _user, uint256 indexed _value, uint256 indexed _date);
    event CompetitorTeamEvent(address indexed _user, uint256 indexed _team, uint256 indexed _date);

}