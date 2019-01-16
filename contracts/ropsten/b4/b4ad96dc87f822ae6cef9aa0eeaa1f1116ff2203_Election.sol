pragma solidity ^0.4.2;
/*
 * @title Election
 *  A self-talling protocol which ensures  that all voters are recognised
 *
 *  Author: Evaldas Grišius
 *  Vilnius University
 *  Evalda<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="72015c15001b011b070132151f131b1e5c111d1f">[email&#160;protected]</a>
 */
contract Election {

    address public admin;

    //  Nustatomas konraktro kurejas kaip administratorius
    function isAdmin() public {
        admin = msg.sender;
    }

    // @ naujas administratorius
    function setAdmin(address newAdmin) onlyAdmin() public {
        admin = newAdmin;
    }
 //_______________________________________________________Data_____________________________________________________
    string public question; // Rinkimų priežastis
    uint public candidatesCount; // kandidatų skaičius. Jei būtų galima šalinti kadidatus, reikėtų naudoti masyvą 
    uint public totalRegistered; // Viso registruotų konktrakte  rinkėjų, galinčių balsuoti
    uint public totalVoted = 0 ; // Viso  balsavusiųjų rinkėjų
    uint public totalVotes =0 ; // Viso balsų. Idealiu atveju turi sutapti su  balasavusiuju skaičiumi
    uint public votesCounted = 0; // Viso 
    uint public EthBalance; // Kontrakto eterio balansas

// Kandidatai 
    struct Candidate {
        uint id;            // id
        string name;        // Kandidato vardas
        uint tally;     // Balsų skaičius
    }

    mapping(uint => Candidate) public candidates; // leis ieškoti kadidato pagal id
//----- Rinkėjai
    struct Voter {
        bool registered;
        bool votecast;
        uint vote;
    }
  
    mapping (address => Voter) public voters; // leis ieškoti rinkėjo pagal adresą
    address[] public addresses; //  visų rinkėjų adresų masyvas
    mapping (address => uint) public addressid; // Addresų valdymui pagal id

// Etapai -----
    
    enum State { SETUP, VOTE, CLOSED } // Konfigūracija-parengtis, balsavimas, uždarytas
    State public state; // Esama balsavimo fazė
    
//_______________________________________________________________ Apribojimai________________________________________
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

//________________________________________________________________Kontraktas___________________________
    function Election () public {
        question = "Kas bus prezidentas?";
        isAdmin();
    }

//__________________________________________________________________Funkcijos_________________________________________

// -----------------------------------------------------------------------------------------Naujo kandidato pridėjimas 
// @Kanidato pavadinimas
    function addCandidate (string _name) public inState(State.SETUP)  onlyAdmin {
        
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }
//-----------------------------------------------------------------------------------------Rinkėjo registracija

// @rinkejo adresas
    function addRegistered(address addr) public  inState(State.SETUP) onlyAdmin {

        if(!voters[addr].registered) {          // dar neregistruotas?
            addresses.push(addr);               // naujas rinkejas
            voters[addr].registered = true;     
            voters[addr].vote = 0;
            totalRegistered ++;                 
        }
    }
    
//---------------------------------------------------------------------------------------- Rinkėjų registracija
// @ rinkeju adresu sarasas
    function addManyRegistered(address[] addr) public  inState(State.SETUP)  onlyAdmin  {

        address temp ;
        
        for(uint i=0; i<addr.length; i++) {

            if(!voters[addr[i]].registered) {       // dar neregistruotas?
                temp = addr[i];
                voters[temp].registered = true;     
                voters[temp].vote = 0;
                addresses.push(temp);        // naujas rinkejas
                totalRegistered ++;         
            }
        }
    }
//---------------------------------------------------------------------------------------- Balsavimo pradžia
    function setVotingPhase() public  onlyAdmin  {
        
        state = State.VOTE;
    }

// ----------------------------------------------------------------------------------------Balsavimas
//@kandidato numeris
    function submitVote (uint _candidateId) public  inState(State.VOTE) {
        
        if(voters[msg.sender].registered && !voters[msg.sender].votecast){  // gali balsuoti?
            voters[msg.sender].vote = _candidateId;  
            voters[msg.sender].votecast = true;
            totalVoted += 1;                                   
            totalVotes += 1; 
        }           
    }
// ----------------------------------------------------------------------------------------Savo balo patikrinimas

    function showMyVote() public returns (bool _votecast , uint _candidate_id ){
        address addr = msg.sender;
        _votecast = voters[addr].votecast;
        _candidate_id = voters[addr].vote;
    }
 
// ----------------------------------------------------------------------------------------Perbalsavimas
//@kandidato numeris
    function reVote (uint _candidateId) public  inState(State.VOTE)  {
        
        if(voters[msg.sender].registered ){             // gali balsuoti?
            voters[msg.sender].vote = _candidateId;                  
            totalVotes += 1; 
        }           
    }    
    
// ---------------------------------------------------------------------------------------Balsavimo uždarymas ir Rezultatų sumavimas
    function computeResult() inState(State.VOTE) public  onlyAdmin   { 
        
                
        uint candidate_id;
            
        for(uint i=0; i<totalVoted; i++) {               // Tikrinamas kiekvienas rinkejas

            candidate_id = voters[addresses[i]].vote;    // kandidato numeris
            candidates[candidate_id].tally ++;       //  +1 balsas kandidatui
            votesCounted ++;
        }
        state = State.CLOSED;                            //  Balsavimas uždaromas. 
    }
//______________________________________________________Duomenų nuskaitymas___________________________________________________________________
 
//-----------------------------------------------------------------------------------------------------Registruoti adresai
    function getRegistered() view public returns (address[]){
        return addresses; 
    }
//-----------------------------------------------------------------------------------------------------Kandidato rezultatai
    function getCandidate(uint nr) view public returns (uint, string, uint){
        return (candidates[nr].id,candidates[nr].name,candidates[nr].tally);
    }



//------------------------------------------------------------------------------------------------------Fallback
    function () public payable { // falllback funkcion to receive ether
    }

    //--------------------------------------------------------------------------------------------------Eterio išėmimas
    function withdraw(uint amount) public  onlyAdmin  returns(bool) {
        require(amount <= this.balance);
        admin.transfer(amount);
        return true;
//------------------------------------------------------------------------------------------------------ Balansas
    }
    function getBalanceContract() public  view returns(uint){
        return this.balance;
    }
}