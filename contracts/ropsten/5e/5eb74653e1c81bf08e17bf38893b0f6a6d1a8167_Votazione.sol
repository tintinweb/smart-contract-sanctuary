pragma solidity ^0.4.24;

contract Votazione {
    
    struct Elettore {        
        bool votato;  // vero = l&#39;elettore ha votato
        address address_candidato;   // indice del candidato votato
        bool autorizzato; 
    }
    
    struct Candidato {        
        string nome_candidato;  
        uint conteggio_voti; 
    }
    
    address public eletto = address(0);
    address public proprietario;
    mapping(address => Elettore) public elettore_da_indirizzo;
    mapping(address => Candidato) public candidato_da_indirizzo;
    
    constructor() public {
        proprietario = msg.sender;
    }
    
    function registrazione_candidato(string nome) external {
        candidato_da_indirizzo[msg.sender].nome_candidato = nome;
    }
 
    function assegna_diritto_di_voto(address _elettore) public {
        require (!elettore_da_indirizzo[_elettore].autorizzato);
        require (msg.sender == proprietario);
        elettore_da_indirizzo[_elettore].autorizzato = true;
    }
 
    function vota_un_candidato(address candidato_scelto) public {
        Elettore storage sender = elettore_da_indirizzo[msg.sender];
        require(!sender.votato);
        require(sender.autorizzato);
        sender.votato = true;
        sender.address_candidato = candidato_scelto;
        candidato_da_indirizzo[candidato_scelto].conteggio_voti += 1;
    }
    
    function esercita_potere_pubblico() external{
        if(eletto != address(0)){
            if(candidato_da_indirizzo[msg.sender].conteggio_voti > candidato_da_indirizzo[eletto].conteggio_voti){
                eletto = msg.sender;
            }
        } else {
            eletto = msg.sender;
        }
    }
 


    
}