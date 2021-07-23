/**
 *Submitted for verification at polygonscan.com on 2021-07-23
*/

pragma solidity 0.6.12;

contract GetTimeStamp {
    
    function getBlockTimestamp() public view returns (uint) {
            // solium-disable-next-line security/no-block-members
            return block.timestamp;
    }
}