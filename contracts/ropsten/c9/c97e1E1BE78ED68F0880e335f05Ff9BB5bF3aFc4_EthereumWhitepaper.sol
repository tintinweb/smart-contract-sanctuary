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

    function assembleParts(
        address one,
        address two,
        address three,
        address four,
        address five
        ) public view returns (string memory) {

        string memory whitepaper = string(abi.encodePacked(
            PartInterface(one).returnPart(),
            PartInterface(two).returnPart(),
            PartInterface(three).returnPart(),
            PartInterface(four).returnPart(),
            PartInterface(five).returnPart()
        ));
        return whitepaper;
    }
}