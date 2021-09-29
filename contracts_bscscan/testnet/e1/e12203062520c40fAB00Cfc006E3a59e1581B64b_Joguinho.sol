/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Joguinho {
    
    function random() internal view returns (uint) {
        return uint8((uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))%10)+1);
    }
    
    function rollDice(uint _lowOrHigh) internal view returns (bool) {
        require(_lowOrHigh >= 0, 'Error, accept only 0 and 1');
        require(_lowOrHigh <= 1, 'Error, accept only 0 and 1');
        uint8 diceNumber = uint8(random());
        if((diceNumber <= 5 && _lowOrHigh == 0) || (diceNumber >= 6 && _lowOrHigh == 1)) {
            return true;
        } else {
            return false;
        }
    }
    
    function bet(uint _lowOrHigh) external payable {
        require(msg.value >= 0.1 ether);
        if(rollDice(_lowOrHigh)) {
            address payable player = payable (msg.sender);
            player.transfer(msg.value*2);
        }
    }
    
    receive() external payable {
    }
    
    function withdraw() public payable{
        address payable usuario = payable (msg.sender);
        usuario.transfer(address(this).balance);
    }
    
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}