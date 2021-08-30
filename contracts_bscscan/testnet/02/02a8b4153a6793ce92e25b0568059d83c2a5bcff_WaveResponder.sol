/**
 *Submitted for verification at BscScan.com on 2021-08-30
*/

pragma solidity >=0.7.0 <0.9.0;

contract WaveResponder {
    event Acknowledge(address indexed waver, uint count);
    
    mapping(address => uint) waveCounts;

    function wave() public {
        waveCounts[msg.sender] += 1;
        emit Acknowledge(msg.sender, waveCounts[msg.sender]);
    }
}