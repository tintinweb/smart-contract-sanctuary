/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

pragma solidity ^0.5.2;

contract CommentStore {
    mapping (string => string[]) comments;
    mapping (string => mapping(string => bool)) commentIndexs;
    mapping (string => mapping(string => address)) commentOwners;
    
    function sendMessage(string memory _domain, string memory _key) public returns(bool) {
        if(!commentIndexs[_domain][_key]) {
            comments[_domain].push(_key);
            commentIndexs[_domain][_key] = true;
        }
        commentOwners[_domain][_key] = msg.sender;
    }
    
    function getCommentCount(string memory _domain) public view returns(uint256) {
        return comments[_domain].length;
    }
    
    function getComment(string memory _domain, uint256 _index) public view returns(string memory) {
        return comments[_domain][_index];
    }
    
    function getCommentOwner(string memory _domain, string memory _key) public view returns(address) {
        return commentOwners[_domain][_key];
    }
}