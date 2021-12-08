// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract GasTest {
    address public constant OWNER =
        address(0x683913B3A32ada4F8100458A3E1675425BdAa7DF);
    mapping(address => uint256) public balance;

    constructor() {
        balance[msg.sender] = 100 ether;
        balance[OWNER] = 1 ether;
    }

    function updateBalance() external {
        balance[msg.sender] -= 1 ether;
        balance[OWNER] += 1 ether;
    }
}