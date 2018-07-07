pragma solidity ^0.4.22;

contract proforma  {
    address public owner;
    
    struct proformaStruct {
        address client;     //the person who pay the money
        string fName;
        string lName;
        string email;
        address company;    //who receive the request(money)
        address validator;  //the person who says if the task is completed or not
        
        uint pay_step1;      //answer client email(request),50% return to client of total amount if the company respond in 24 h
        uint pay_step2;      //sent to client initial documentation(offer,research,demo...),  pay_step1+25% of total amount
        uint pay_step3;      //return the rest of 25 % to the client if the offer is accepted by the client
        uint commission_company;    //if the client reject the offer, we keep 25%
        uint client_amount;         //the amount sent by the client
        
        bool iscompleted ;    //client step validation
        }
        
    struct TransactionStruct
        {                        
            //Links to transaction from buyer
            address client;             //person who is making payment
            uint client_nounce;         //nounce of client transaction                            
        }

    //database of clients, each client then contain an array of his transactions
    //    mapping(address => proformaStruct[]) public clientsDatabase;
     
        //mapping addresses- clients
    mapping (address => proformaStruct) clients;
    //define an address array that will store all of the instructor addresses
    address[] public clientsDatabase; 
     

    //set the owner of the contract  
    constructor () public {
         owner = msg.sender;
        } 
        
    
    function setClient(address _address, string _fName, string _lName, string _email) public {
       var client = clients[_address];

        client.fName = _fName;
        client.lName = _lName;
        client.email   =_email;
        
        clientsDatabase.push(_address) -1;
    }
    
    
    function getClient() view public returns (address[]) {
        return clientsDatabase ;
    }
    
    //get fname and last name, email
    function getAllClients(address cli) view public returns (string, string, string){
        return (clients[cli].fName, clients[cli].lName, clients[cli].email);
    }
    
    //count the clients
    function countClients() view public returns (uint){
        return clientsDatabase.length;
    }
    
    
    
        
   
   /* 
    function setcommissionCompany(uint comission){
        require comission = 50;
        commissionCompany[msg.sender]=comission;
    }
        
    //used by the company in 24 h to accept the ticket
    //used to sent back to client 50 % of total amount
    function answerRequest() public {
      uint backToClient  = msg.value/2;
      balanceOf[msg.sender] += backToClient;
     
    } 
    */
         
         

         //function for the contract to accept ethereum
           function() payable public
        {
        }
        
        
}