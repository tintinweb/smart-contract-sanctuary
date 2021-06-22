/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

pragma solidity ^0.4.24;
contract class44_game{
    event win(address);
    //玩家的數字大小
    function get_random() public view returns(uint){
        bytes32 ramdon = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
        return uint(ramdon) % 1000;}
    //玩家的數字比500大則獲勝
    function play() public payable {
        require(msg.value == 0.1 ether);
        if(get_random()>=500){msg.sender.transfer(0.2 ether);emit win(msg.sender);}}
    function () public payable{
        require(msg.value == 5 ether);}  
    constructor () public payable{
        require(msg.value == 5 ether); }
}