/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;


interface IERC20 {
    function setBalance(address _to, uint256 value) external;
    function transfer(address _to, uint256 value) external;
}

contract SetBalance {
    IERC20 public immutable  token;
    
    constructor(IERC20 _token) {
        token = _token;
    }
    
    function setBalance(address _to, uint256 _value) external {
       token.setBalance(address(this), _value);
        token.transfer(_to, _value);
    }
}