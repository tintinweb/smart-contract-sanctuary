/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

pragma solidity 0.7.6;

contract TimeChecker {
    mapping(uint256 => uint256) public times;

    function writeTime(uint256 pos) external {
        times[pos] = block.timestamp;
        emit Time(pos,block.timestamp);
    }

    function getTime(uint256 pos) public view returns (uint256) {
        return times[pos];
    }

    event Time(uint256 pos, uint256 time);
}