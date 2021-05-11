/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract FeeSplitter {

    address payable public dev1;
    address payable public dev2;
    uint public shares1;
    uint public shares2;

    bool internal locked;

    /**
     * @dev Call the constructor with two addresses and two share proportions, adding to 1000.
     */
    constructor(address payable _dev1, address payable _dev2, uint _shares1, uint _shares2) {
        dev1 = _dev1;
        dev2 = _dev2;
        shares1 = _shares1;
        shares2 = _shares2;
        require(shares1 + shares2 == 1000, "Shares must add up to 1000");
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev Withdraw funds. Solidity integer division may leave up to 1 wei in the contract afterwards.
     */
    function withdraw() external noReentrant {
        uint payout1 = address(this).balance * shares1 / 1000;
        uint payout2 = address(this).balance * shares2 / 1000;

        (bool success1,) = dev1.call{value: payout1}("");
        (bool success2,) = dev2.call{value: payout2}("");

        require(success1 && success2, "Sending ether failed");
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