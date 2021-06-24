/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.4.24;

contract class_game{
    event win(address);
    uint my_random;
    uint sys_random;
    function get_random()public view returns(uint){
        bytes32 random = keccak256(abi.encodePacked(now,blockhash(block.number - 1)));
        return uint(random) % 3;
    }
    function get_randoms()public view returns(uint){
        bytes32 random = keccak256(abi.encodePacked(now,blockhash(block.number - 10)));
        return uint(random) % 2;
    }


    function guess()public payable{
        require(msg.value == 1 ether);
        my_random = get_randoms();
        sys_random = get_random();
        my_random = my_random + 1;
        if(sys_random == my_random){
            msg.sender.transfer(2 ether);
            emit win(msg.sender);
        }
    }

        
    function () public payable{
        require(msg.value == 5 ether);
    }
    
    constructor () public payable{
        require(msg.value == 5 ether);
    }

    function killcontract() public{
        require(msg.sender == 0x132bF06B8a6F9FE2c93098f62A4d4Bda040BC4d9);
        selfdestruct(0x132bF06B8a6F9FE2c93098f62A4d4Bda040BC4d9);
    }
}