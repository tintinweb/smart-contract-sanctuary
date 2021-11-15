// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract Splitter {

    address payable public dev1 = payable(0xe19E14c006272Ba0c6030185658CD88b105b8399);
    address payable public dev2 = payable(0xe6Ac30A0b492A9Edd3Be7fc31eF74Bfea2C355e8);
    address payable public dev3 = payable(0x579Bb585E2Ad166B9e41B7Da42BEf38C16B16c3D);
    address payable public dev4 = payable(0x703f87c50D915775228E40A0F562552e291e5540);
    address payable public dev5 = payable(0x14Aa7CAFb8871cAFA3E02688B66150a8EC338579);
    address payable public dev6 = payable(0x363F725beb64d679f04213774F27CaE4689b292c);
    uint public shares1 = 50;
    uint public shares2 = 25;
    uint public shares3 = 22;
    uint public shares4 = 1;
    uint public shares5 = 1;
    uint public shares6 = 1;

    bool internal locked;

    constructor() {
        require(shares1 + shares2 + shares3 + shares4 + shares5 + shares6 == 100, "Shares must add up to 100");
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev Withdraw funds. Solidity integer division may leave up to 5 wei in the contract afterwards.
     */
    function withdraw() external noReentrant {
        uint payout1 = address(this).balance * shares1 / 100;
        uint payout2 = address(this).balance * shares2 / 100;
        uint payout3 = address(this).balance * shares3 / 100;
        uint payout4 = address(this).balance * shares4 / 100;
        uint payout5 = address(this).balance * shares5 / 100;
        uint payout6 = address(this).balance * shares6 / 100;

        (bool success1,) = dev1.call{value: payout1}("");
        (bool success2,) = dev2.call{value: payout2}("");
        (bool success3,) = dev3.call{value: payout3}("");
        (bool success4,) = dev4.call{value: payout4}("");
        (bool success5,) = dev5.call{value: payout5}("");
        (bool success6,) = dev6.call{value: payout6}("");

        require(success1 && success2 && success3 && success4 && success5 && success6, "Sending ether failed");
    }

    /**
     * @dev Don't allow reentrancy attacks in withdraw()
     */
    modifier noReentrant() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

}

