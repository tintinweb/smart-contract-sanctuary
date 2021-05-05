/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Friends{
   
   address private owner;
   uint private recordId;
   uint private password;
   bool private lockPassword;
   bool private paused;
   
    constructor() {
        owner = msg.sender;
    }
    
    struct Friend{
        string  Name;
        string  Message;
        address Address;
        uint    EngravedDate;
        uint Id;
    }
    
    Friend[] friends;
    mapping(string => bool) nameExists;
    mapping(address => bool) canAddFriends;
    
    
    
    function createFriend(string memory _fullName, string memory _message) public{
        require(msg.sender == owner || canAddFriends[msg.sender], "Call A-beast for permission");
        require(!paused, "Creation of new friend is paused");
        require(nameExists[_fullName] == false, "This name has already been taken!");
        address _requester = msg.sender;
        if(_requester == owner){
            _requester = address(0);
        }
        Friend memory _friend = Friend(_fullName, _message, _requester, block.timestamp, recordId);
        friends.push(_friend);
        recordId = add(recordId, 1);
    }
     
     function createFriendWithAddress(string memory _fullName, string memory _message, uint _password) external{
        require(_password == password, "You have incorrect password.");
        require(nameExists[_fullName] == false, "This name has already been taken!");
        Friend memory _friend = Friend(_fullName, _message, msg.sender, block.timestamp, recordId);
        friends.push(_friend);
        recordId = add(recordId, 1);
    }
    
    function addFriendPermission(address _address) external{
          require(msg.sender == owner, "Only owner can add permission");
          canAddFriends[_address] = true;
    }
    
    function setPassword(uint _password) external {
        require(!lockPassword || msg.sender == owner, "You cannot set password now.");
        require(msg.sender == owner, "Call A-beast to set the password");
        lockPassword = true;
        password = _password;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function getFriend(uint _id) external view returns (string memory Name, string memory Message, uint EngravedDate, uint Id) {
        Friend memory _friend = friends[_id];
        return (_friend.Name, _friend.Message, _friend.EngravedDate, _friend.Id);
    }
    
    function getFriendByName(string memory _name) external view returns (string memory Name, string memory Message, uint EngravedDate, uint Id) {
        uint _id;
        for(uint i = 0; i <= friends.length; i++){
            if(keccak256(abi.encodePacked((friends[i].Name))) == keccak256(abi.encodePacked((_name)))){
                _id = friends[i].Id;
            }
        }
        Friend memory _friend = friends[_id];
        return (_friend.Name, _friend.Message, _friend.EngravedDate, _friend.Id);
    }
    
    
    function getAllFriendsRaw() view external returns(Friend[] memory){
        return friends;
    }
    
    function getAllFriendNames() view external returns(string[] memory){
        string[] memory _friends;
        for(uint i = 0; i < friends.length; i++){
            _friends[i] = friends[i].Name;
        }
        return _friends;
    }
    
    function setPaused(bool _paused) external{
        require(msg.sender == owner, "You are not the owner ");
        paused = _paused;
    }
    
    
   function withdrawAllEther(address payable _to) external {
        require(!paused, "Withdrawal is paused"); 
        require(msg.sender == owner, "Only owner is allowed to withdraw all the money");
        _to.transfer(address(this).balance);   
   }
   
    function destroySmartContract(address payable _to ) external {
        require(msg.sender == owner, "You are not allowed to rug pull");
        require(!paused, "Destruction is paused");
        selfdestruct(_to);
    }
    
    function transferOwnership(address _to) external  {
          require(msg.sender == owner, "You are not allowed to transfer ownership");
          owner = _to;
    }
    
    function withdrawEther(address payable _to, uint _amount) external {
        require(!paused, "Withdrawal is paused"); 
        require(msg.sender == owner, "Only owner is allowed to withdraw ether");
        require(address(this).balance >= _amount, "Not enough funds");
        _to.transfer(_amount);
    }
    
    function getBalance() view external returns(uint){
        return address(this).balance;
    }
    
    function getTotalFriends() view external returns(uint){
        return friends.length;
    }
    
     function DonateToAbhigya() public payable{
     }
     
}