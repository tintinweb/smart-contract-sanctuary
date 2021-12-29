/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface PartInterface {
    function returnPart() external view returns (string memory);
}

contract EthereumWhitepaper {
    constructor() {}

    function assembleParts() public view returns (string memory) {

        string memory whitepaper = string(abi.encodePacked(
            PartInterface(0x6b462ecF62E98c27195ca5d0B8c49ddEC8574122).returnPart(),
            PartInterface(0x619a98Be26E267D02ab6Ba415C52ff3668cD2C3C).returnPart(),
            PartInterface(0xF337320D0A60F0a409da3797703D490FD57B441e).returnPart(),
            PartInterface(0x67e461AB603C8118b781D6dC2e9805cC505C3869).returnPart(),
            PartInterface(0x99aF3cC0Ef5C5f0Dd287955f83295B4fD22843CB).returnPart()
        ));
        return whitepaper;
    }
}