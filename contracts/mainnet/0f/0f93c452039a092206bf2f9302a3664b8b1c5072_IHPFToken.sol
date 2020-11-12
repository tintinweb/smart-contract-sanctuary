// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

interface IHPFToken {
    function mint(address dst, uint rawAmount) external;
    function transfer(address dst, uint rawAmount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
    function totalSupply() external view returns (uint);
}