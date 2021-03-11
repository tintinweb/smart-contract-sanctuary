// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;
import "./Owner.sol";
import "./PartecipazioneContest.sol";



contract VincitoriDelContest is Owner {
    
    PartecipazioneContest partecipazioneContestContract;
    address private owner;
    uint private userCountVincitore = 0;
    Vincitore private vincitore;

    struct Vincitore {
        string username;
        string nome;
        string cognome;
        string email;
    }


    constructor (PartecipazioneContest _partecipazioneContestContract) public {
        partecipazioneContestContract = PartecipazioneContest( _partecipazioneContestContract);
        owner = msg.sender; 

    }
    
    //-------------------------------------------------------------- FUNZIONI PUBBLICHE INVOCABILI SOLO DALL'OWNER
    
    
    function estrazioneVincitore ()  public isOwner()  returns (string memory)
    {

      
    
        uint contUtentiContest=  partecipazioneContestContract.getUserCount();
        string memory vincitore1;
      
        uint indiceVicntore1;
       
        if (contUtentiContest<1)
        {
            revert("Non ci sono abbastanza utenti per estrarre un vincitore");

        }
         if(contUtentiContest==1)
        {
            indiceVicntore1=1;
            vincitore1= partecipazioneContestContract.getUsernameUser(indiceVicntore1);
            
            
        }
        else
        {
            indiceVicntore1= random(contUtentiContest);
            vincitore1= partecipazioneContestContract.getUsernameUser(indiceVicntore1);


        }
        
        (string memory usernameVincitore,string memory nomeVincitore,string memory cognomeVincitore,string memory emailVincitore)= partecipazioneContestContract.getUserByID(indiceVicntore1);
        
        vincitore= Vincitore(usernameVincitore, nomeVincitore, cognomeVincitore, emailVincitore);
        userCountVincitore++;
        emit Winner ("Il Vincitore", usernameVincitore, nomeVincitore, cognomeVincitore,emailVincitore );
            
        return(vincitore1);
        
    }
    
    
    function resetVincitoreContest() public  isOwner() { 
        require(userCountVincitore>0, "la lista dei vincitori e` gia` vuota");
        delete vincitore; 
        delete userCountVincitore;
    
    }
    
 
    //-------------------------------------------------------------- FUNZIONI PUBBLICHE INVOCABILI DA  TUTTI
    
    function getVincitore ()  public returns (string memory, string memory,string memory,string memory )
    {
        require(userCountVincitore>0, "non e` stato sorteggiato nessun vincitore");
        emit Winner ("Il Vincitore", vincitore.username, vincitore.nome, vincitore.cognome,vincitore.email );
        return (vincitore.username, vincitore.nome, vincitore.cognome, vincitore.email);

    }

    
    //--------------------------------------------------------------FUNZIONI PRIVATE INVOCABILI SOLO DALL'OWNER

   
   function random(uint contUtentiContest) private view isOwner()  returns (uint) {
        uint val= uint(uint256(keccak256(abi.encode(block.timestamp, block.difficulty)))%contUtentiContest);
        return (val+1) ;
        
    }
   
   //--------------------------------------------------------------EVENTI 
   
    event EvenAddress(
        address num
    );
    
     event EventInt(
        string messanger, 
        uint num
    );
    event EventString(
        string messanger,
        string parola
    );
    
    event Winner(
        string messanger, 
        string username,
        string nome,
        string cognome,
        string email
    );

}