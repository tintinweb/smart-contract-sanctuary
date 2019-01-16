pragma solidity ^0.4.2;
/*
 * @title Election
 *  A self-talling protocol which ensures  that all voters are recognised
 *
 *  Vilnius University
 */
contract Election {

    address public admin;

    //  Nustatomas kontraktro kurejas kaip administratorius
    function isAdmin() internal {
        admin = msg.sender;
    }

    // @ naujas administratorius
    function setAdmin(address newAdmin) onlyAdmin() public {
        admin = newAdmin;
    }
 //_______________________________________________________Dduomenys_____________________________________________________
    string public question;      // Rinkimų tikslas
    uint public candidatesCount; // kandidatų skaičius. Jei būtų galima šalinti kadidatus, reikėtų naudoti masyvą 
    uint public totalRegistered; // Viso registruotų konktrakte  rinkėjų, galinčių balsuoti
    uint public totalVoted = 0 ; // Viso  balsavusiųjų rinkėjų
    uint public totalReVotes = 0 ; // Viso perbalsavimų
    uint public votesCounted = 0; // Viso suskaičiuota balsų

// Kandidatai 
    struct Candidate {
        uint id;            // id
        string name;        // Kandidato vardas
        uint tally;         // Balsų skaičius
    }

    mapping(uint => Candidate) public candidates; // leis ieškoti kadidato pagal id
// Rinkėjai
    struct Voter {
        bool registered;    // registruotas?
        bool votecast;      // balsavo?
        uint vote;          // kandidato numeris
    }
  
    mapping (address => Voter) private voters; // leis ieškoti rinkėjo pagal adresą
    address[] public addresses;              //  visų rinkėjų adresų masyvas
    mapping (address => uint) public addressid; // Addresų valdymui pagal id

// Etapai 
    
    enum State { SETUP, VOTE, CLOSED } // Konfigūracija-parengtis, balsavimas, uždarytas
    State public state;                // Esama balsavimo fazė
    
//_______________________________________________________________ Apribojimai__________
//------ Etapų  tikrinimas
    modifier inState(State s) {
        if(state != s) {
            revert();
         }
        _;
    }
//------- Administratoriaus apribojimai
    modifier onlyAdmin {
        if(admin != msg.sender) revert();
        _;
    }
//________________________________________________________________Įvykiai - Events____
// Balsas priimtas
event voteReceived(
        address voterAddress
    );
// Adresas registruotas
event  addressRegistered(
        address  addr
    );
// Kandidatas užregistruotas
event  candidateRegistered(
        string name
    );
// Balsavimas pradėtas
event  votingBegins(
        uint state
 );
 // Balsvimas uždaromas
event  tallyComputed(
        uint state
);
//_____________________________________________________________Kontraktas_______________________
    constructor () public {
        question = "Kas bus prezidentas?";
        isAdmin();
    }

//_____________________________________________________________Funkcijos-setteriai________________________
// -----------------------------------------------------------------------------------------Naujo kandidato pridėjimas 
// @Kanidato pavadinimas
    function addCandidate (string _name) external  inState(State.SETUP)  onlyAdmin {
        
        candidatesCount ++;             // kandidaro numeris
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
        emit candidateRegistered(_name);
    }
//-----------------------------------------------------------------------------------------Rinkėjo registracija

// @rinkejo adresas
    function addRegistered(address _addr) external  inState(State.SETUP) onlyAdmin {

        if(!voters[_addr].registered) {          // dar neregistruotas?
            voters[_addr].registered = true;     
            voters[_addr].vote = 0;              // nunulinamas balsas
            addresses.push(_addr);               // naujas rinkejas
            totalRegistered ++;                 // viso rinkėjų
            emit addressRegistered(_addr);                
        }
    }
    
//---------------------------------------------------------------------------------------- Rinkėjų registracija
// @ rinkeju adresu sarasas
    function addManyRegistered(address[] _addr) external  inState(State.SETUP)  onlyAdmin  {

        address temp ;
        
        for(uint i=0; i<_addr.length; i++) {

            if(!voters[_addr[i]].registered) {       // dar neregistruotas?
                temp = _addr[i];
                voters[temp].registered = true;     
                voters[temp].vote = 0;
                addresses.push(temp);               // naujas rinkejas
                totalRegistered ++;         
            }
        }
    }
//---------------------------------------------------------------------------------------- Balsavimo pradžia
    function setVotingPhase() external   onlyAdmin  {
        
        state = State.VOTE;
        emit votingBegins(1);
    }

// ----------------------------------------------------------------------------------------Balsavimas
//@kandidato numeris
    function submitVote (uint _candidateId) external   inState(State.VOTE) {
        
        if(voters[msg.sender].registered && !voters[msg.sender].votecast){  // gali balsuoti?
            voters[msg.sender].vote = _candidateId;  
            voters[msg.sender].votecast = true;
            totalVoted ++ ;                                 //viso balsavo
            emit voteReceived(msg.sender);                                  
        }           
    }

// --------------------------------------------------------------------------------------Perbalsavimas
//@kandidato numeris
    function reVote (uint _candidateId) external   inState(State.VOTE)  {
        
        if(voters[msg.sender].votecast ){             // gali balsuoti?
            voters[msg.sender].vote = _candidateId;     // perrašomas balsas                  
            totalReVotes ++;                            // užfiksuojamas balsavimo faktas
            emit voteReceived(msg.sender);  
        }           
    }    
    
// ---------------------------------------------------------Balsavimo uždarymas ir Rezultatų sumavimas
    function computeResult() inState(State.VOTE) external   onlyAdmin   { 
        
        uint candidate_id;
            
        for(uint i=0; i<totalVoted; i++) {               // Tikrinamas kiekvienas rinkejas

            candidate_id = voters[addresses[i]].vote;    // kandidato numeris
            candidates[candidate_id].tally ++;           //  +1 balsas kandidatui
            votesCounted ++;                             // apdorota rinkėjų balsų
        }
        state = State.CLOSED;                            //  Balsavimas uždaromas. 
        emit tallyComputed(2);
    }
//______________________________________________________Duomenų nuskaitymas - getteriai___________________________________________________________________

// --------------------------------------------------------------------------------------------Savo balo patikrinimas
//  Adresas gali pasitikrinti, ar balsavo ir už ką balsavo
    function showMyVote()  view external inState(State.VOTE)  returns (bool _votecast , uint _candidate_id ){
        return (voters[msg.sender].votecast, voters[msg.sender].vote);
    }
 
//---------------------------------------------------------------------------------------------Registruoti adresai
// Visų registruotų adresų sąrašas
    function getRegistered() view external returns (address[]){
        return addresses; 
    }
//---------------------------------------------------------------------------------------------Rikėjo balsas
// Naudojas tik simuliacjų  tarpinių rezultatų veikimo tikrinimui.
    function checkVoter(address addr) view external  returns (bool, bool){
        return (voters[addr].registered,voters[addr].votecast);
    }
//-----------------------------------------------------------------------------------------------------Kandidato rezultatai
    function getCandidate(uint nr) view external  returns (uint, string, uint){
        return (candidates[nr].id,candidates[nr].name,candidates[nr].tally);
    }
//---------------------------------------------------------------------------------------------Fallback
// Transakcija be parametrų iškvies šią funkciją

    function () public payable { // falllback funkcion to receive ether
    }

//---------------------------------------------------------------------------------------------Eterio išėmimas
// Tam atvejui, jei kontrakte sukauptų eterio

    function withdraw(uint amount) external  onlyAdmin  returns(bool) {
        require(amount <= address(this).balance);
        admin.transfer(amount);
        return true;
    }
}