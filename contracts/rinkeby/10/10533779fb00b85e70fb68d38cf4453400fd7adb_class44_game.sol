/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

pragma solidity ^0.4.24;
contract class44_game{
    event win(address);
    address owner;
    function get_random() public view returns(uint){
        bytes32 ramdon = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
        return uint(ramdon) % 10;}
    function play() public payable {
        require(msg.value == 1 wei);
        if(get_random()>=5){msg.sender.transfer(2 ether);emit win(msg.sender);}}
    function () public payable{
        require(msg.value == 20 wei);}  
    constructor () public payable{
        require(msg.value == 20 wei); }
    function killcontract() public {
        require(msg.sender == owner);
        selfdestruct(0x9a91296b267De4A43D44f0aE39E5D3235ED4bf61);
    }
}