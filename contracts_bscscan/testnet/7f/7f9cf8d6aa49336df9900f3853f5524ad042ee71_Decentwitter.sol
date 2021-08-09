/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

pragma solidity ^0.5.11;

contract Decentwitter {
    string public name = "Decentwitter";
    
    struct Post {
        uint id;
        string hash;
        string description;
        uint tipAmount;
        address payable author;
    }
    
    mapping(uint => Post) public posts;
    
    function uploadPost() public {
        posts[0] = Post(0, 'abc123', 'Hello World', 0, address(0x0));
    }
}