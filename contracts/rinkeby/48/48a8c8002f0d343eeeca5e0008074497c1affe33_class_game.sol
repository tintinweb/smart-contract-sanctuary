/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity ^0.4.24;

contract class_game{
    event win(address);
    uint my_random;
    uint sys_random;
    function get_random()public view returns(uint){
        bytes32 random = keccak256(abi.encodePacked(now,blockhash(block.number - 1)));
        return uint(random) % 1000;
    }
    function bigger()public payable{
        require(msg.value == 1 ether);
        my_random = get_random();
        sys_random = get_random();
        if(sys_random < my_random){
            msg.sender.transfer(2 ether);
            emit win(msg.sender);
        }
        if(sys_random == my_random){
            msg.sender.transfer(1 ether);
            emit win(msg.sender);
        }
    }
    function smaller()public payable{
        require(msg.value == 1 ether);
        my_random = get_random();
        sys_random = get_random();
        if(sys_random > my_random){
            msg.sender.transfer(2 ether);
            emit win(msg.sender);
        }
        if(sys_random == my_random){
            msg.sender.transfer(1 ether);
            emit win(msg.sender);
        }
    }
    function () public payable{
        require(msg.value == 10 ether);
    }
    
    constructor () public payable{
        require(msg.value == 10 ether);
    }

    function killcontract() public{
        require(msg.sender == 0x132bF06B8a6F9FE2c93098f62A4d4Bda040BC4d9);
        selfdestruct(0x132bF06B8a6F9FE2c93098f62A4d4Bda040BC4d9);
    }
}