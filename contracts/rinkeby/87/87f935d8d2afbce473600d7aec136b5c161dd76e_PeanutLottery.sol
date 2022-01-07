/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

//SPDX-License-Identifier: GPL-3.0
//Arbuckle Systems LLC

pragma solidity >=0.5.0 <0.9.0;


contract PeanutLottery{
        address payable[] public players;
        address public manager;

        constructor(){
            manager = msg.sender;
            players.push(payable(manager)); //adds manager to the lottery pool
        }

        receive() external payable{
            require(msg.value == 0.1 ether); //lottery tickets cost .1 ether
            require(msg.sender != manager); //the manager cannot purchase lottery tickets
            players.push(payable(msg.sender));
        }

        function getBalance() public view returns(uint){
            require(msg.sender == manager);
            return address(this).balance;
        }

        function random() public view returns(uint){
            return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
        }

        function pickWinner() public{
            require(players.length >= 10);

            uint r = random();
            address payable winner;

            uint index = r % players.length;
            winner = players[index];

            uint managerFee = (getBalance() * 10) / 100; //manager earns 10% fee every round
            uint winnerPrize = (getBalance() + 90) / 100;
            
            winner.transfer(winnerPrize);
            payable(manager).transfer(managerFee);

            players = new address payable[](0); //resets the lottery
            players.push(payable(manager)); //adds manager to the next lottery drawing pool
        }


}