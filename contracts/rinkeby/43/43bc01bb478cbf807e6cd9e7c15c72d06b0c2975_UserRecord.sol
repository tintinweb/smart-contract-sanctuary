/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity ^0.4.23;

contract UserRecord {
    constructor() public { owner = msg.sender; }

    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    struct User {
        uint userEmail;
        uint index;
    }

    mapping (uint => User) private users;

    uint[] private usersRecords;
    event LogNewUser(uint indexed userEmail, uint index);

    function setUseremail(uint _userEmail) public onlyOwner returns(bool success){
        users[_userEmail].userEmail = _userEmail;
        users[_userEmail].index = usersRecords.push(_userEmail) -1;

        emit LogNewUser(
        _userEmail,
        users[_userEmail].index
        );
        return true;
    }

//this will delete the user at particular index and gap will be not there

    function deleteUser(uint _userEmail) public onlyOwner returns(uint index){

        uint toDelete = users[_userEmail].index;
        uint lastIndex = usersRecords[usersRecords.length-1];
        usersRecords[toDelete] = lastIndex;
        //users[lastIndex].index = toDelete; 
        usersRecords.length--;
        return toDelete;   
    }    
    
     function getAllSaleObjects() public constant returns (uint[]) 
    {
        return usersRecords;
    }
}