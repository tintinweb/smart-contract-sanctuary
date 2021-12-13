/**
 *Submitted for verification at Etherscan.io on 2021-12-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery{
    address public manager;
    address[] public players;
    uint private entranceFee;

    constructor (){
        manager = msg.sender;
        // players.push(manager);
        entranceFee = 1000000000000000000;
    }

    function addPlayer(address newPlayer) public payable{
        bool isAvailable = true;
        for(uint i = 0; i < players.length; i++){
            if(players[i] == newPlayer){
                isAvailable = false;
                break;
            }
        }

        require(isAvailable && msg.value == 1000000000000000000 wei);
        players.push(newPlayer);
    }

    function getAllPlayers() public view returns(address[] memory) {
        return players;
    }

    function selectWinner()  public payable returns(uint)  {
        //pick a random winner
        address winner = players[randomGenerator()%players.length];

        //send winner the money 80% of the pool balance
        uint prize = getPoolPrize() * 80 / 100;
        payable(winner).transfer(prize);
        //send the commission to manager
        // payable(manager).transfer(address(this).balance);

        //reset the state
        players = new address[](0);
        
        return prize;
    }

    function randomGenerator() private view returns(uint){

        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function getPoolPrize() public view returns(uint){
        return players.length * entranceFee;
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

}