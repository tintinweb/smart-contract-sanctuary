/**
 *Submitted for verification at Etherscan.io on 2021-12-01
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

 mapping(address => string[])  private records;

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

    function createRecord(address add, string memory data) public {
   PreviousRecords = getPreviousRecords(add);
   PreviousRecords.push(data);
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

function getRecordCount() public view returns(uint){
    string[] memory temp = getPreviousRecords(msg.sender);
    return temp.length;
}


}