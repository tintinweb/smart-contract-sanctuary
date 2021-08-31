/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
contract Bulksender{
    function bulksendToken(IERC20 _token, address[] memory _to, uint256[] memory _values) external {
        require(_to.length == _values.length);
        for (uint256 i = 0; i < _to.length; i++) {
            require(_token.transferFrom(msg.sender, _to[i], _values[i]));
        }
    }
    
    function bulksendTokenSingleValue(IERC20 _token, uint256 _value, address[] memory _to) external {
        require(_value > 0);
        for (uint256 i = 0; i < _to.length; i++) {
            require(_token.transferFrom(msg.sender, _to[i], _value));
        }
    }
}