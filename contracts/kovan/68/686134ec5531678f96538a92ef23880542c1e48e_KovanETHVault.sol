/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

pragma solidity ^0.5.0;

contract KovanETHVault{

    function transfer(address payable to, uint256 amount) external {
        to.transfer(amount);
    }

    function () external payable {}
}