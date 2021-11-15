pragma solidity ^0.8.0;

contract Time {
    function GetTimeNow() public view returns (uint256) {
        return block.timestamp;
    }
}

