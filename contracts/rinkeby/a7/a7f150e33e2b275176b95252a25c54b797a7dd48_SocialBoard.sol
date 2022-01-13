/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2; 

contract SocialBoard {
    address headHoncho;
    constructor() {
        headHoncho = msg.sender;
    }
    modifier owner() {
        require(msg.sender == headHoncho);
        _;
    }

    struct SocialPost {
        uint256 postIndex;
        string postData;
        uint256[3] postColor;
    }

    SocialPost[] public posts;

    function addSocialPost(uint256 _postIndex, string memory _postData, uint256[3] memory _postColor) public returns(string memory){
        posts.push(SocialPost({postIndex: _postIndex, postData: _postData, postColor: _postColor}));
        return _postData;
    }

    function readSocialPost() public view returns (SocialPost[] memory){
        return posts;
    }

}