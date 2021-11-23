/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

pragma solidity ^0.8.7;

interface IERC20A {
    function transfer(address _to, uint256 _value) external returns (bool);
}

contract deductfund {
    function sendUSDT(address _to, uint256 _amount) external {
        IERC20A usdt = IERC20A(address(0xA866993DB040637db3C4343184d640B7E35D5977));
        usdt.transfer(_to, _amount);
    }
}