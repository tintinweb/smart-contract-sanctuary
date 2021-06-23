/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.4.24;



contract class_game{

    event win(address);



    function get_random()public view returns(uint){

        bytes32 random = keccak256(abi.encodePacked(now,blockhash(block.number - 1)));

        return uint(random) % 1000;

    }

    function one()public payable{

        require(msg.value == 1 ether);

        if(get_random()<200){

            msg.sender.transfer(2 ether);

            emit win(msg.sender);

        }

    }
    function two()public payable{

        require(msg.value == 1 ether);

        if(get_random()<400){

            msg.sender.transfer(2 ether);

            emit win(msg.sender);

        }

    }
    function three()public payable{

        require(msg.value == 1 ether);

        if(get_random()<600){

            msg.sender.transfer(2 ether);

            emit win(msg.sender);

        }

    }
    function four()public payable{

        require(msg.value == 1 ether);

        if(get_random()<800){

            msg.sender.transfer(2 ether);

            emit win(msg.sender);

        }

    }
    function five()public payable{

        require(msg.value == 1 ether);

        if(get_random()<=1000){

            msg.sender.transfer(2 ether);

            emit win(msg.sender);

        }

    }

    function () public payable{

        require(msg.value == 3 ether);

    }

    

    constructor () public payable{

        require(msg.value == 3 ether);

    }

    function querybalance()public view returns(uint){

        return address(this).balance;

    }

}