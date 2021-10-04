/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

pragma solidity ^0.8.0;

contract lottery
{
    address public manager; // manager ka address lenge
    address payable[] public participants;
    
    constructor() // iss pure contract ko hamarea manager deploye karega kuki manager ke pass pura control hoga
    {
        manager=msg.sender;// this is golabal varable
    }
    
    receive() external payable // you can only use one time
    {
        require(msg.value >=1 ether);
        participants.push(payable(msg.sender)); // iska matlab hai ki  iss address se 2 ether transfer kr rahe hai address
    }
    
    function getBalance() public view returns(uint)
    {
        require(msg.sender==manager);
        return address(this).balance;
    }
    
    function random() public view returns(uint)
    {
        return uint(keccak256(abi.encodePacked(block.difficulty ,block.timestamp ,participants.length )));
    }
    
    function selectWinner() public
    {
        require(msg.sender== manager);
        require(participants.length >=3);
        uint r =random();
        address payable Winner;
        uint index= r %  participants.length;
        Winner =participants[index];
        Winner.transfer(getBalance());
        participants = new address payable[](0);
    }
}