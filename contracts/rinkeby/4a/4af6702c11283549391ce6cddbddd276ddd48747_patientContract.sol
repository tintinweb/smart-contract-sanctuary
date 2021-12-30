/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;
contract patientContract{
 
 uint recordCount;
 address[]  addresses;
 uint[]  ids;
 string[] PreviousRecords;
 mapping(address => string)  private users;
 mapping(uint=> address) private getAddressFromName;
 mapping(address=> string) private getUserFromAddress;
 mapping(address => mapping(uint => record)) private userRecord; 
 mapping(address => string[])  private records;
 mapping(address=> uint) private countID;
 mapping(uint=> string) private lookup;

 mapping(address=> uint) private recordLookup;

    struct User {
 
        string firstname;
        string lastname;
       address userAddress;
    }    
    
    struct record {
 
        string id;
        string name;
     
   }  

    function createUser(address add, uint id, string memory name) public {
   
                    users[add] = name;
                    getAddressFromName[id] = msg.sender;
                    ids.push(id);
                    addresses.push(msg.sender);
      
    }

    function createRecord(address add, string memory data, string memory keys) public {
   PreviousRecords = getPreviousRecords(add);
   PreviousRecords.push(data);
   recordCount = getRecordCount(msg.sender);
   lookup[recordCount] = keys;
   records[add] = PreviousRecords;
                  
    }




    function getAddressByUser(uint id) external view returns(address){
      return getAddressFromName[id];
}

function getUserByAddress(address userAddress) public view returns(string memory){
    return users[userAddress];
}

function get() public view returns(string memory){
    return users[msg.sender];
}


function getPreviousRecords(address userAddress) public view returns(string[] memory){
    return records[userAddress];
}

function getRecordCount(address userAddress) public view returns(uint){
    string[] memory temp = getPreviousRecords(userAddress);
    return temp.length;
}


}