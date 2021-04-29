/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity ^0.6.0;

contract EventTest {
    uint256 public number;
    
    event SaveValue(address indexed _sender, uint256 _num);
    
    function saveValue(uint256 _num) external returns (bool) {
        number = _num;
        emit SaveValue(msg.sender, _num);
    }
}