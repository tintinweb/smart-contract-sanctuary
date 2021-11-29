// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Target {
    function blockNumber() external returns (uint);

    function f() external;
}

contract Reward {

    function f(Target target, uint reward) external payable {
        require(target.blockNumber() != 0, "ASDASD");
        block.coinbase.transfer(reward);
    }

}