/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract JoevsPng {

    address public manager;
    address public player;
    address[] public joePlayers;
    address[] public pngPlayers;

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function launchGame() public {
        manager = msg.sender;
    }

    function enterJoe() public payable {
        require(msg.value > 0.01 ether);
        player = msg.sender;
        joePlayers.push(player);
    }

    function enterPng() public payable {
        require(msg.value > 0.01 ether);
        player = msg.sender;
        pngPlayers.push(player);
    }

    function shareThePrize() public restricted {
        uint contractVolume = address(this).balance;

        if(joePlayers.length > pngPlayers.length) {
            for (uint i=0; i<joePlayers.length; i++){
                payable(joePlayers[i]).transfer((4*contractVolume)/(5*joePlayers.length));
                payable(manager).transfer(contractVolume/5);
                joePlayers = new address[](0);
                pngPlayers = new address[](0);
            } 
        } else {
            for(uint i=0; i<pngPlayers.length; i++){
                payable(pngPlayers[i]).transfer((4*contractVolume)/(5*pngPlayers.length));
                payable(manager).transfer(contractVolume/5);
                joePlayers = new address[](0);
                pngPlayers = new address[](0);
            }
        }
    }


    function getJoePlayers() public view returns(address[] memory) {
        return joePlayers;
    }

    function getPngPlayers() public view returns(address[] memory) {
        return pngPlayers;
    }

    function getJoePlayersLength() public view returns(uint) {
        return joePlayers.length;
    }

    function getPngPlayersLength() public view returns(uint) {
        return pngPlayers.length;
    }

    function getContractVolume() public view returns(uint) {
        return address(this).balance;
    }
}