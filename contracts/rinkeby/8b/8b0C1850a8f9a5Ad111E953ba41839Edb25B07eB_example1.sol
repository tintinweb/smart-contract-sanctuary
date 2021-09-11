/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity ^0.8.4;

contract example1{
    
    User[] public users;
    uint public total;
    struct User{
        string _id;
        address _wallet;
        uint _currency;
    }
    
    event SMC_emit_data(address _wallet,string _id);
    
    function SignIn(string memory _id) public payable {
        User memory newUser = User(_id, msg.sender,msg.value);
        total+=msg.value;
        users.push(newUser);
        emit SMC_emit_data(msg.sender,_id);
    }
}