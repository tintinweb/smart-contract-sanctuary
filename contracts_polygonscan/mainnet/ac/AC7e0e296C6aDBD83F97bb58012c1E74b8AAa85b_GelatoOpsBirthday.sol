// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GelatoOpsBirthday {
    uint256 public constant BIRTH_YEAR = 2021;
    address public constant GELATO_OPS =
        address(0xB3f5503f93d5Ef84b06993a1975B9D21B962892F);

    uint256 public age;
    uint256[] public birthdayBlocks;

    event SingBirthdaySong(string indexed lyrics);

    function celebrate() external {
        require(msg.sender == GELATO_OPS);
        age += 1;

        birthdayBlocks.push(block.number);

        emit SingBirthdaySong("Happy Birthday Gelato Ops");
    }
}