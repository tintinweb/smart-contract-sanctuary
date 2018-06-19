pragma solidity ^0.4.11;

contract Utils {
    function currentTime() public view returns (uint256){
        return uint256(now);
    }
}