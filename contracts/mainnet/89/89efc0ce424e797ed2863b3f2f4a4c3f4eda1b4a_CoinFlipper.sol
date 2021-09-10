/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

contract CoinFlipper {
    
    address payable[] players;

    receive() payable external {
        require(msg.value >= 0.01 ether, "Must send correct amount of ether to play.");
        // Add player that paid to the array
        players.push(payable(msg.sender));
        // If there are 2 players, play
        if( getPlayerCount() == 2 ) {
            play();
        }
    }
    
    function play() internal {
        address payable winner = players[flipTheCoin()];
        // send the winner all the ether
        payOut(winner, getBalance());
    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function payOut(address payable _to, uint _amount) private {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
    
    function getPlayerCount() public view returns(uint) {
        return players.length;
    }
    
    function flipTheCoin() private view returns(uint) {
        return random() % 2;
    }
    
    function random() public view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
}