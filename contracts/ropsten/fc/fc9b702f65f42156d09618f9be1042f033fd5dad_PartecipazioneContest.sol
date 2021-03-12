// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;
import "./Owner.sol";


/** @title Partecipazione al Contest. */
contract PartecipazioneContest is Owner {
    address private owner;
    uint public userCount = 0;
    mapping(uint => User) private users;


    constructor() public {
        owner = msg.sender; 
    }

    struct User {
        uint id;
        string username;
        string nome;
        string cognome;
        string email;
    }
    
    //----------------------------------------------FUNZIONI PUBLICHE E INVOCABILI SONO DALL'OWNER


    /** @dev Aggiunta utente alla BlockChain
      * @param _username username univoco dell'untete(lo smart contract verifica la sua univocita`)
      * @param _nome nome utente
      * @param _cognome cognome utente
      * @param _email email utente
      */
    function addUser( string memory _username, string memory _nome, string memory _cognome, string memory _email) public  isOwner() {
        require(bytes(_username).length > 0 , "Username vuoto");
        require(bytes(_nome).length > 0 , "Nome vuoto");
        require(bytes(_cognome).length > 0 , "Cognome vuoto");
        require(bytes(_email).length > 0 , "Email vuota");
        
        if(checkUsernameExisting(_username)==0)
        {
            userCount ++;
            users[userCount] = User(userCount, _username, _nome, _cognome, _email);
            emit UserAdded(userCount, _username, _nome, _cognome, _email);
        }
        else
        {
            emit Error("Username gia` presenteaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
            revert("Username gia` presente");
        }

    }
    
    function resetPartecipantiAlContest() public  isOwner() { 
        require(userCount>0, "non ci sono partecipanti al contest");

        uint i; 
        for (i=1; i<= userCount; i++)
        {
            delete users[i];
        }
        
        delete userCount;
    
        
    }
    
    //invocando questo metodo bisogna rifare il deploy degli smartcontract 
    /*
    function distruggiSmartContract() public isOwner() { //onlyOwner is custom modifier
        selfdestruct(payable(owner));  // `owner` is the owners address
    }*/
    
    //----------------------------------------------FUNZIONI PUBBLICHE INVOCABILI DA CHINQUE  (funzioni di lettura)
    
    
    
    function getUsernameUser(uint indexUser) public view returns (string memory) 
    {
         require(indexUser > 0 , "indice utente non valido");
         require(indexUser <= userCount , "indice utente non valido");
         
         return users[indexUser].username;

        
    }


    function getUserCount() public view returns(uint) {
        
        return userCount;
    }
    
    
   
  
    function getUserByID(uint _ID) public view  returns (string memory, string memory,string memory,string memory){
        
        require(userCount >0, "Non ci sono utenti nel contest");
        require(_ID >0, "ID nullo");
        require(_ID<=userCount, "indice utente non valido" );

        return (users[_ID].username,users[_ID].nome,users[_ID].cognome, users[_ID].email );
    }
  
    //----------------------------------------------FUNZIONI PRIVATE INVOCABILI SOLO DALL'OWNER (che non servono agli altri Smart Contract)

    function getIDByUsername( string memory _username) private isOwner() view returns (uint id){
        require(userCount >0, "Non ci sono utenti nel contest");
        require(bytes(_username).length > 0 , "Username vuoto");
        
        uint i=0;
        bool trovato= false; 
        uint ID;

        do{
            if (keccak256(abi.encodePacked(users[i].username)) == keccak256(abi.encodePacked(_username)))
            {
                trovato= true;
                ID= users[i].id;
            }
            i++;
        }while(i<=userCount && trovato==false );
        
        if (trovato==true)
        {
            return ID;
        }
        else
        {
            
            return 0;
        }

    
    }
  
  
    function checkUsernameExisting( string memory _username) private isOwner() view returns (uint id){
        require(bytes(_username).length > 0 , "Username vuoto");
        
        uint i=0;
        bool trovato= false; 
        uint ID;

        do{
            if (keccak256(abi.encodePacked(users[i].username)) == keccak256(abi.encodePacked(_username)))
            {
                trovato= true;
                ID= users[i].id;
            }
            i++;
        }while(i<=userCount && trovato==false );
        
        if (trovato==true)
        {
            return ID;
        }
        else
        {
            return 0;
        }

    
    }
    
    //---------------------------------------------- EVENTI
  
  
    event Error(
        string error
    );
    
    event UserAdded(
        uint id,
        string username,
        string nome,
        string cognome,
        string email
    );
  
  
 



}