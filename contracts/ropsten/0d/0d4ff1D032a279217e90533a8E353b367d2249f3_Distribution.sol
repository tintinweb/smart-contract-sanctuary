pragma solidity ^0.8.0;

contract Distribution {

address public admin;
mapping(uint=>User) users;

constructor(){
    admin=msg.sender;
}

 

 modifier onlyOwner {
        require(
            msg.sender == admin,
            "Only owner can call this function."
        );
        _;
    }



struct User{
     uint id;
     string name;
     string designation;
     uint amount;
}



function addUser(uint _id,string memory _name, string memory _designation) public   returns (string memory ) {
    users[_id]=User (_id,_name,_designation,0);
    return "success";
}

function getUser(uint _id) external view returns(User memory _user){
    _user=users[_id];
}

}

