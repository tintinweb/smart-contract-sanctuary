/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Authentication{
    struct UserDetails{
        address userAddress;
        string username;
        string password;
        string hash;  //X
        bool isloggedin;
    }
    mapping (address => UserDetails) user;
    
    function signup(address _address, string memory _username, string memory _password, string memory _hash) public notAdmin returns(bool){
        require(user[_address].userAddress != msg.sender);
        user[_address].userAddress = _address;
        user[_address].username = _username;
        user[_address].password = _password;
        user[_address].hash = _hash;
        user[_address].isloggedin = false;
        return true;
    }
    
    function loginuser(address _address, string memory _password) public returns(bool){
        if(keccak256(abi.encodePacked(user[_address].password)) == keccak256(abi.encodePacked(_password))){  //X
            user[_address].isloggedin = true;
            return user[_address].isloggedin;
        }
        else{
            return false;
        }
    }
    
    function checkUser(address _address) public view returns (bool, string memory){
        return (user[_address].isloggedin, user[_address].hash);
    }
    
    function logoutUser(address _address) public{
        user[_address].isloggedin = false;
    }
    
    struct AdminDetails{
        address adminAddress;
        string name;
        string password;
        string hash;
        bool isloggedin;
    }
    mapping(address => AdminDetails) admin;
    
    constructor() public {
        address adminAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    }
    
    modifier onlyAdmin(){
        require(msg.sender == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);  //X
        _;
    }
    
    modifier notAdmin(){
        require(msg.sender != 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        _;
    }
    
    function registerAdmin(address _address, string memory _name, string memory _password, string memory _hash) public onlyAdmin returns(bool){
        require(admin[_address].adminAddress != msg.sender);
        admin[_address].adminAddress = _address;
        admin[_address].name = _name;
        admin[_address].password = _password;
        admin[_address].hash = _hash;
        admin[_address].isloggedin;
        return true;
    }
    
    function loginAdmin(address _address, string memory _password) public returns (bool){
        if(keccak256(abi.encodePacked(admin[_address].password)) == keccak256(abi.encodePacked(_password))){
            admin[_address].isloggedin = true;
            return admin[_address].isloggedin;
        }
        else{
            return false;
        }
    }
    
    function checkAdmin(address _address) public view returns(bool, string memory){
        return (admin[_address].isloggedin, admin[_address].hash);
    }
    
    function logoutAdmin(address _address) public{
        admin[_address].isloggedin = false;
    }
    
    function getAdminBalance(address _address) public view returns (uint){ //X
        return (admin[_address].adminAddress.balance);
    }
}