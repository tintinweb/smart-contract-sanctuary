/**
 *Submitted for verification at polygonscan.com on 2021-08-29
*/

pragma solidity 0.8.7;

contract timestamp {
    function timeNow() public view returns (uint256) {
        return block.timestamp;
    }
    
    function timerSeconds() public view returns (uint256) {
        if (1630274674 - block.timestamp < 0) {
            return 0;
        }
        return 1630274674 - block.timestamp;
    }
    

}