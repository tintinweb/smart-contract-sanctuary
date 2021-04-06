/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract FeeSplitter {

    address payable public dev1;
    address payable public dev2;
    address payable public dev3;
    uint public shares1;
    uint public shares2;
    uint public shares3;

    bool internal locked;

    constructor(address payable _dev1, address payable _dev2, address payable _dev3, uint _shares1, uint _shares2, uint _shares3) {
        dev1 = _dev1;
        dev2 = _dev2;
        dev3 = _dev3;
        shares1 = _shares1;
        shares2 = _shares2;
        shares3 = _shares3;
        require(shares1 + shares2 + shares3 == 1000, "Shares must add up to 1000");
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev Withdraw funds. Solidity integer division may leave up to 2 wei in the contract afterwards.
     */
    function withdraw() external noReentrant {
        uint payout1 = address(this).balance * shares1 / 1000;
        uint payout2 = address(this).balance * shares2 / 1000;
        uint payout3 = address(this).balance * shares3 / 1000;

        (bool success1,) = dev1.call{value: payout1}("");
        (bool success2,) = dev2.call{value: payout2}("");
        (bool success3,) = dev3.call{value: payout3}("");

        require(success1 && success2 && success3, "Sending ether failed");
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