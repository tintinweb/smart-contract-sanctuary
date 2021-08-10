/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

pragma solidity ^0.8.6;

contract EventTestContract {
    
    mapping(address => uint256) private _counts;
    
    event Increase(address indexed addr, uint256 oldValue, uint256 newValue);
    
    function increaseWithEvent() public returns (bool) {
        uint256 oldValue = _counts[msg.sender];
        _increase();
        uint256 newValue = _counts[msg.sender];
        emit Increase(msg.sender, oldValue, newValue);
    }
    
    function increaseWithoutEvent() public returns (bool) {
        _increase();
    }
    
    function _increase() private {
        _counts[msg.sender] += 1;
    }
    
}