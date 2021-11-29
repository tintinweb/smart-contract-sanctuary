// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface GoldHunter {
    function mint(uint _amount, bool _stake) external payable;

    function pirateMinted() external returns (uint16);

}

contract Breaker {
    uint16 public piratesDiscovered;

    function rememberPirates(GoldHunter goldHunter) external {
        piratesDiscovered = goldHunter.pirateMinted();
    }

    function checkAndReward(GoldHunter goldHunter, uint value) external payable {
        require(goldHunter.pirateMinted() != piratesDiscovered, "peepeepoopoo");
        block.coinbase.transfer(value);
    }
}