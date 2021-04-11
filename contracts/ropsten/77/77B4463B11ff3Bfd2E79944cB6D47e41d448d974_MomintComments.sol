/**
 *Submitted for verification at Etherscan.io on 2021-04-11
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;



// Part: ISocial

interface ISocial {
     function isValidUser(address _user) external view returns (bool);
}

// File: MomintComments.sol

contract MomintComments {

    ISocial SOCIAL;
    constructor(ISocial _social) public
    {
        SOCIAL = ISocial(_social);
    }
    modifier onlyUser
    {
        require(SOCIAL.isValidUser(msg.sender) == true, "You are not a valid user!");
         _;
    }
    struct Comment
    {
        address sender;
        string message;
    }
    mapping(uint256 => Comment[]) tokenComments;

    /*Comment on a token given it is valid*/
    function commentToken(uint256 _tokenID, string memory _message) external onlyUser
    {
        Comment memory content = Comment(msg.sender, _message);
        tokenComments[_tokenID].push(content);
    }

    /*Return amount of comments on a specific token*/
    function getAmountComments(uint256 _tokenID) external view returns(uint256)
    {
        return tokenComments[_tokenID].length;
    }

    /*Return sender & message of a comments on a specific token at a specific index*/
    function getCommentByIndex(uint256 _tokenID, uint256 _index) external view returns(address _sender, string memory _message)
    {
        Comment memory content = tokenComments[_tokenID][_index];
        return (content.sender, content.message);
    }

}