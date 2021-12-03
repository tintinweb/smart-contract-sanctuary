// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


contract KYC {

    struct Client {
        address userID;
        string report_uri;
        bool used;
        uint end_date;
    }
    
    
    // Stores userID => Client
    mapping (address => Client) public Clientdatabase;
   
    address [] public clientList;   // Create a list to loop through and get expiring KYC reports

    address public  admin; // contract administrator
    
    uint price = 100000000000000; // check price = 0.001 BNB
    
    constructor() {
        admin = msg.sender;
    }
    
    // Events that will emit changes 
    event NewClient(address userID, string report_uri); 
    event ChangeClientInfo(address userID, string report_uri); 

    function registerKYC(address userID, string memory report_uri) public payable returns(bool) { 
        
        require(!Clientdatabase[userID].used, "Account already Exists"); //To prevent duplicate registration
        require(msg.value >= price, "You must pay sufficient funds"); 
        // Permanently associates the report_uri with the userID  on-chain via Events.
        emit NewClient(userID, report_uri);
       
        Clientdatabase[userID] = Client(userID, report_uri, true, block.timestamp + 365 days);
        appendclientinfo(userID);

        //return to sender
        payable(msg.sender).transfer(msg.value);
       return Clientdatabase[userID].used;
  }
       
    
    function updateKYC(address userID, string memory newreport_uri) public returns(string memory) {
        Clientdatabase[userID].report_uri = newreport_uri;

        // Permanently associates the report_uri with the userID  on-chain via Events.
        emit ChangeClientInfo(userID, newreport_uri);
        
        return Clientdatabase[userID].report_uri;
        

    }
    
     // check validity of a particular contract
    function checkvalidity(address userID) public view returns(string memory) {
        if (block.timestamp > Clientdatabase[userID].end_date){
            return "KYC report has Expired!";
        }
        else {  
             return "KYC report is Valid!";
        }
    } 
 
   
    //Add each new client to the client list
    function appendclientinfo(address client) private {
        clientList.push(client);
       
    }
    
    function getclientCount() public view returns(uint count) {
        return clientList.length;
    }


}