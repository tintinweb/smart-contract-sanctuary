/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

pragma solidity ^0.5.0;

contract GameOf42 {

    uint256 public score;
    address payable public winner;

    function play() public payable {
        require(msg.value >= 0.1 ether);
        require(score != 42);
        score = score + 1;
        if(score == 42) {
            winner = msg.sender;
        }
    }

    function payout() public {
        require(msg.sender == winner);
        winner.transfer(address(this).balance);
    }

    function getBalance() public view returns(uint256) {
        return(address(this).balance);
    }
}