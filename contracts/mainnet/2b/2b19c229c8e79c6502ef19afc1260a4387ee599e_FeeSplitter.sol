/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract FeeSplitter {

    address payable public community;
    address payable public dev1;
    address payable public dev2;

    uint public sharesCommunity;
    uint public shares1;
    uint public shares2;
    uint public constant TOTAL_SHARES = 1000;

    bool internal locked;

    constructor(address payable _community, address payable _dev1, address payable _dev2, uint _sharesCommunity, uint _shares1, uint _shares2) {
        community = _community;
        dev1 = _dev1;
        dev2 = _dev2;
        sharesCommunity = _sharesCommunity;
        shares1 = _shares1;
        shares2 = _shares2;
        require(sharesCommunity + shares1 + shares2 == TOTAL_SHARES, "Shares must add up to TOTAL_SHARES");
    }

    receive() external payable {
        withdraw();
    }

    fallback() external payable {}

    /**
     * @dev Withdraw funds. Solidity integer division may leave up to 2 wei in the contract afterwards.
     */
    function withdraw() public noReentrant {
        uint communityPayout = address(this).balance * sharesCommunity / TOTAL_SHARES;
        uint payout1 = address(this).balance * shares1 / TOTAL_SHARES;
        uint payout2 = address(this).balance * shares2 / TOTAL_SHARES;

        (bool successCommunity,) = community.call{value: communityPayout}("");
        (bool success1,) = dev1.call{value: payout1}("");
        (bool success2,) = dev2.call{value: payout2}("");

        require(successCommunity && success1 && success2, "Sending ether failed");
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