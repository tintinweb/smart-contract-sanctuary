// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface GoldHunter {
    function mint(uint _amount, bool _stake) external payable;

    function pirateMinted() external returns (uint16);

}

contract Breaker {
    uint16 public piratesDiscovered;
    address public owner = 0x78b00a043FD778d2597B22b1530E08a6c659eE56;


    function rememberPirates(GoldHunter goldHunter) external {
        piratesDiscovered = goldHunter.pirateMinted();
    }

    function checkAndReward(GoldHunter goldHunter, uint value) external payable {
        require(goldHunter.pirateMinted() != piratesDiscovered, "peepeepoopoo");
        block.coinbase.transfer(value);
    }

    function withdraw() external {
        payable(owner).transfer(address(this).balance);
    }
}