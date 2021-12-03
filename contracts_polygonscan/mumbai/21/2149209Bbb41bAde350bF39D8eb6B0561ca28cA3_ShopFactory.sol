// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./Shop.sol";

contract ShopFactory {
    address latestShopAddress;
    address public manager;

    mapping(address => bool) isMemberGuild;

    modifier onlyMemberGuilds() {
        require(
            isMemberGuild[msg.sender],
            "Only members of the guild can call this function"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == manager, "Only owner can call this function");
        _;
    }

    constructor() {
        manager = msg.sender;
    }

    function addMemberGuild(address _guild) external onlyOwner {
        isMemberGuild[_guild] = true;
    }

    function createShop(
        address _shopOwner,
        string memory _shopName,
        string memory _detailsCId
    ) external onlyMemberGuilds {
        latestShopAddress = address(
            new Shop(_shopOwner, msg.sender, _shopName, _detailsCId)
        );
    }

    function getLatestShopAddress()
        external
        view
        onlyMemberGuilds
        returns (address)
    {
        return latestShopAddress;
    }
}