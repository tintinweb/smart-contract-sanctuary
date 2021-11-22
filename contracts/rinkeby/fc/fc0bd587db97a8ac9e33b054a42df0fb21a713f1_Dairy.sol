/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Dairy {
    address public owner;
    constructor () {
        owner = msg.sender;
    }
    
    struct PostData {
        string imageUri;
        string title;
        string Description;
    }
    PostData[] public postDatas;
    mapping( uint256 => address) users;
    
    modifier onlyOwner {
        require(msg.sender == owner, "you are not the owner");
        _;
    }
    // ["amar", "name", "rabbi"]   
    function addPost (PostData memory _post) public {
        postDatas.push(_post);
        uint256 id = postDatas.length - 1;
        users[id] = msg.sender;
    }
    
    function getPost () public view returns (PostData[] memory) {
        return postDatas;
    }
    
    function updatePost (PostData memory _post, uint256 _index) public {
        postDatas[_index] = _post;
    }
}