/**
 *Submitted for verification at polygonscan.com on 2022-01-24
*/

// SPDX-License-Identifier: GPL-3.0
// File: contracts/social media.sol


pragma solidity ^0.8.0;


contract SocialMedia{


    address public owner;
    
    uint256 public user_counter;  // counter for user id and used as a user id
   uint256 public post_counter;  // counter for total posts 

    modifier notOwner(){
        require(msg.sender!= owner);
        _;
    }
    

// structure for user
    struct User{
        uint256 user_id;
       
        address user_addr;
      

    }
// struct for post
    struct Post{
        uint256 userId;
        string _postImageHash;
        string authorName;
        string Description;
        uint256 timestamp;
        uint256 post_id;
       
    }

    
    mapping(address => User) public users;
    mapping(address => uint256) public post_countermap;  // track total posts by user we can also get post by couting array length of posts
    
    User[] public userslist; // list of all users
    User userInfo;
    Post[] public postslist;  // list of all posts
    Post postInfo;

    mapping(address => bool) public notfirst_time; // check if user eneterd first time or not 
    mapping (address => Post[]) public addressToUserPost; // contains all posts by a particular user
    mapping (uint256 => address) public postToUserAddress; // mapping to get user address form user id

    constructor(){

        owner = msg.sender;
        
}
    

   
    event TransferReceived(address sender, uint256 amount);

    function SetPost( uint256 userId , string memory userName, string memory postDescription , string memory imageHash ) public{
         
        first_time(msg.sender); // check if user appeared before or not
        postToUserAddress[userId] = msg.sender;
        postInfo= Post(userId,imageHash,userName,postDescription,block.timestamp,post_countermap[msg.sender]); //get  post info
        addressToUserPost[msg.sender].push(postInfo); // send Post to users post collection
        postslist.push(postInfo);
        post_countermap[msg.sender]++;
        post_counter++;

       
    }


// get all posts
    function getallposts() public view returns(Post[] memory){
    return postslist;
    }

// get post by id

    function getpostbyid(uint256 id) public view returns(Post memory){
        return postslist[id];
    }

// get post by particular user by id

    function getpostsbyuser(address user_addr,uint256 id) public view returns(Post memory){
        return addressToUserPost[user_addr][id];
    }

// get all posts by a particular user

    function getallpostbyuser(address user_addr) public view returns (Post[] memory){
        return addressToUserPost[user_addr];
    }

// you can send eth to user if you like the post 😁
     function SupportMe( address payable sender,uint256 amount ) notOwner payable external {
        require(sender != address(0), "Sender address cannot be zero.");
        sender.transfer(amount);
    }

   
   
    function first_time(address user_addr) public{
             
    if(notfirst_time[user_addr]){

    }
    
    else{
       
       notfirst_time[user_addr]=true;
       userInfo = User(user_counter,user_addr);
       user_counter++;
       userslist.push(userInfo);
       users[user_addr]=userInfo;
       
       
    }
    
    }
}