/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity ^0.6.0;

contract EventTest {
    uint256 public num;

    event TestEvent(address indexed _addr1, uint256 indexed _num, uint256 _data1, bytes32 _data2);
    event SaveValue(address indexed _sender, uint256 _num);
    event ManyTopics(address indexed _addr1, uint256 indexed _num1, uint256 indexed _num2, uint256 _data1, uint256 _data2);

    function test(uint256 _num, uint256 _data1, bytes32 _data2) external returns (bool) {
        emit TestEvent(msg.sender, _num, _data1, _data2);
        return true;
    }

    function saveValue(uint256 _num) external returns (bool) {
        num = _num;
        emit SaveValue(msg.sender, _num);
    }
    
    function manyTopics() external returns (bool) {
        emit ManyTopics(msg.sender, 1, 2, 3, 4);
    }
}