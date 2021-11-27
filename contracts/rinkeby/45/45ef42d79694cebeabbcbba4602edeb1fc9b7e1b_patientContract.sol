/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;
contract patientContract{
 
 uint recordCount;
 address[]  addresses;
 uint[]  ids;
 mapping(uint => User)  private users;
 mapping(uint=> address) private getAddressFromName;
 mapping(address=> string) private getUserFromAddress;

    struct User {
 
        string firstname;
        string lastname;
       address userAddress;
    }    
    
    function createUser(uint id, string memory firstname, string memory lastname) public {
   
                    users[id] = User(firstname, lastname, msg.sender);
                    getAddressFromName[id] = msg.sender;
                    getUserFromAddress[msg.sender] = firstname;
                    ids.push(id);
                    addresses.push(msg.sender);
      
   
    }


    function getAddressByUser(uint id) external view returns(address){
      return getAddressFromName[id];
}

function getUserByAddress(address userAddress) public view returns(string memory){
    return getUserFromAddress[userAddress];
}



}