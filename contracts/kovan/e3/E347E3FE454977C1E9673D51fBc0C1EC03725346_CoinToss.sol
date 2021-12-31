/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract CoinToss {
    event winner(address _winner, uint _amountWon);

    function tossCoin() external payable {
        require(msg.value == 0.01 ether);

        // Not a secure method of generating randomness.
        uint number = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender))) % 100;

        if (number >= 50) {
            _withdrawToWinner(msg.sender);
            emit winner(msg.sender, address(this).balance);
        }
    }

    function _withdrawToWinner(address _winner) internal {
        payable(_winner).transfer(address(this).balance);
    }
}