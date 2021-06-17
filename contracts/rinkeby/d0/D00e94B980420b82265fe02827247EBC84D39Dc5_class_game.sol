/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity ^0.4.24;



contract class_game{

    event win(address);



    function get_random()public view returns(uint){

        bytes32 random = keccak256(abi.encodePacked(now,blockhash(block.number - 1)));

        return uint(random) % 1000;

    }

    function big()public payable{

        require(msg.value == 1 ether);

        if(get_random()>500){

            msg.sender.transfer(2 ether);

            emit win(msg.sender);

        }

    }
    function small()public payable{

        require(msg.value == 1 ether);

        if(get_random()<=500){

            msg.sender.transfer(2 ether);

            emit win(msg.sender);

        }

    }

    function () public payable{

        require(msg.value == 1 ether);

    }

    

    constructor () public payable{

        require(msg.value == 1 ether);

    }

    function querybalance()public view returns(uint){

        return address(this).balance;

    }

}