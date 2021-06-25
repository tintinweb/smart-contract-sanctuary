/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

pragma solidity > 0.5;

contract P2P {
    address payable client;
    address public administrateur;
    mapping (address=>uint) prime;
    mapping (address=>bool)  vote;
    bool sinistre;
    address public adresseAssure;
    bool vote_remboursement;
    int remboursement;
    uint [2] votes; 
    uint debut;
    uint resultat; 
    bool resultat_vote;
    
    constructor () public  {
        administrateur=msg.sender;
        debut = block.timestamp;
    }
    
    modifier onlyadministrateur () {
        require (administrateur==msg.sender, "seulement l'administrateur peut definir la prime");
        _;
    }
    modifier interditAdministrateur () {
        require (administrateur!=msg.sender,"l'administrateur ne peut pas executer cette fonction");
        _;
    }
    modifier temps_ecoule () {
        require (block.timestamp-debut<=30, "le temps valable de 7 jours pour voter est ecoule");
        _;
    }
    
    modifier temps_ecoule2() {
        require(block.timestamp-debut>=30, "Vous pouvez encore voter");
        _;
    }

    modifier aDejaVote (address assure) {
        require(!vote[msg.sender],"vous avez deja vote");
        _;
    }
    
    modifier propositionValide (uint laProposition) {
        require (laProposition>=0 && laProposition<3);
        _;
    }
    
    modifier demande_accepte ( uint ) {
        require (resultat >7, "le remboursement est accepte");
        _;
    }
    
    modifier versement_reserve () {
        require (block.timestamp-debut>=31536000, "Le reste du montant_utilisable peut etre transfere a la reserve chaque annee");
        _;
    }
    
    function primes (address assure) public payable onlyadministrateur{
        prime[assure]+=msg.value;
    }
    
    function annonce_sinistre () public interditAdministrateur{
        sinistre=true;
        adresseAssure=msg.sender;
    }
    
     function demande_remboursement () public view  returns (bool) {
        return sinistre;
    }
     
     function voter (uint decision_de_vote) public propositionValide(decision_de_vote)   temps_ecoule { //aDejaVote
        votes[decision_de_vote] =  votes[decision_de_vote] + 1;
    }

    //function versementRemboursement () public payable {
      //  msg.sender.transfer(prime[client]);
    //}
    
    function voirprime (address assure) public view returns(uint) {
        return prime [assure];
    }
    
   function cumuldesprimes ()public view returns (uint) {
        return address(this).balance;
    }
    
     function montant_utilisable (uint montant_cumuldesprimes) public view onlyadministrateur returns (uint256){
       return montant_cumuldesprimes*60/100;
    }
    
    function reassuance (uint montant_cumuldesprimes) public view onlyadministrateur returns (uint256) {
        return montant_cumuldesprimes *40/100;
    }
    function voirVotes () public view returns (uint [2] memory) {
        return votes;
    }
    
    function resultat_votation () public view temps_ecoule2 returns (uint) {
      if (votes[0]>7) return 0;
      if (votes[0]<=7) return 1;
    }
    
    function reserve (uint montant_reserve) public view versement_reserve returns (uint) {
        if (montant_reserve >0) {
            return montant_reserve*90/100;
        }else {
            return 0;
        }    
        
    }
   function retirerDons() public payable  {
    client.transfer(address(this).balance);
    }        
}