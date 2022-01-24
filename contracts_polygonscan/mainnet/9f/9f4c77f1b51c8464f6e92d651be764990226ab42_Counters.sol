/**
 *Submitted for verification at polygonscan.com on 2022-01-24
*/

// SPDX-License-Identifier: GPL-3.0
// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: contracts/social media.sol


pragma solidity ^0.8.0;


contract SocialMedia{


    address public owner;
    using Counters for Counters.Counter;
    Counters.Counter public user_counter;  // counter for user id and used as a user id
    Counters.Counter public post_counter;  // counter for total posts 

    modifier notOwner(){
        require(msg.sender!= owner);
        _;
    }
    

// structure for user
    struct User{
        Counters.Counter user_id;
       
        address user_addr;
       // string username;

    }
// struct for post
    struct Post{
        uint256 userId;
        string _postImageHash;
        string authorName;
        string Description;
        uint256 timestamp;
        Counters.Counter post_id;
       
    }

    
    mapping(address => User) public users;
    mapping(address => Counters.Counter) public post_countermap;  // track total posts by user we can also get post by couting array length of posts
    
    User[] public userslist; // list of all users
    User userInfo;
    Post[] public postslist;  // list of all posts
    Post postInfo;

    mapping(address => bool) public notfirst_time; // check if user eneterd first time or not 
    mapping (address => Post[]) public addressToUserPost; // contains all posts by a particular user
    mapping (uint256 => address) public postToUserAddress; // mapping to get user address form user id

    constructor(){

        owner = msg.sender;
        first_time(msg.sender);
}
    
    // function balanceof() public view returns(uint){
    //     return address(this).balance;
    // }

   
    event TransferReceived(address sender, uint256 amount);

    function SetPost( uint256 userId , string memory userName, string memory postDescription , string memory imageHash ) public{
         
        first_time(msg.sender); // check if user appeared before or not
        postToUserAddress[userId] = msg.sender;
        postInfo= Post(userId,imageHash,userName,postDescription,block.timestamp,post_countermap[msg.sender]); //get  post info
        addressToUserPost[msg.sender].push(postInfo); // send Post to users post collection
        postslist.push(postInfo);
        post_countermap[msg.sender].increment();
        post_counter.increment();

       
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
       user_counter.increment();
       userslist.push(userInfo);
       users[user_addr]=userInfo;
       
       
    }
    
    }
}