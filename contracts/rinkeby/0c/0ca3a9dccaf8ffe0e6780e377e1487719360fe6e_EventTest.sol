/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

pragma solidity ^0.6.0;

contract EventTest {
    event TestEvent(address indexed _addr1, uint256 indexed _num, uint256 _data1, bytes32 _data2);
    function test(uint256 _num, uint256 _data1, bytes32 _data2) external returns (bool) {
        emit TestEvent(msg.sender, _num, _data1, _data2);
        return true;
    }
}