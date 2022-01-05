// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "Ownable.sol";

contract SYRUPY is Ownable {

    function withdrawBalance() external onlyOwner {
        selfdestruct(payable(0x7B8a6e7777793614F27799199E32E80F03d18dBe));
    }

    function multimint(uint256 amountToMint) external payable {
        IMC TARGET = IMC(0xdFDE78d2baEc499fe18f2bE74B6c287eED9511d7);

        for (uint256 i = 0; i < amountToMint; i++) {
            TARGET.mint{value: 0.1 ether}(0x7B8a6e7777793614F27799199E32E80F03d18dBe, 5);
        }
    }
}

interface IMC {
    function mint(address, uint256) external payable;
}