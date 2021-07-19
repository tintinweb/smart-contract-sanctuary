/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma solidity 0.6.6;

contract SynContracts {
    string[3] public postBody;
    function setPostBody(string memory _body1, string memory _body2, string memory _body3) public{
        postBody = [_body1, _body2, _body3];
    }
}