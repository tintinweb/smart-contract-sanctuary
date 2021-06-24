/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function mint(address _to, uint256 _amount) external returns (bool);
}

contract MintTest {
    function test(address _token, address _to, uint256 _amount) external {
        IERC20(_token).mint(_to, _amount);
    }
}