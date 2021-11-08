/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestContract {
    struct Ownership {
        address owner;
        bool hasBeenSet;
    }
    mapping(string => Ownership) public ownership;
    mapping(string => uint256) public blockvalid;
    uint private defaultStakedValue = 100;
    address private burnAddress = address(0);

    function mint(address beneficiary, string memory tokenURI) public payable {
        require(msg.value >= defaultStakedValue, "Must lock up at least 100 wei");
        Ownership memory ownershipobj = ownership[tokenURI];
        require(ownershipobj.owner == address(0) && ownershipobj.hasBeenSet == false, "somebody already owns this, use send");
        ownership[tokenURI] = Ownership(beneficiary, true);
        blockvalid[tokenURI] = block.number + 5760 * 7; // must be sent within a week
    }

    function send(string memory tokenURI, address to) payable public {
        require(ownership[tokenURI].owner == msg.sender, "you don't own this");
        require(block.number <= blockvalid[tokenURI], "you can't send this anymore, anybody can burn your NFT");
        require(msg.value >= defaultStakedValue, "Must lock up at least 100 wei");
        ownership[tokenURI] = Ownership(to, true); // transfer it
        blockvalid[tokenURI] = block.number + 5760 * 7; // must be sent within a week
        payable(burnAddress).transfer(defaultStakedValue); // burn their stake
    }

    function burnOtherNFT(string memory tokenURI, address payable beneficiary) public {
        require(block.number > blockvalid[tokenURI], "must be past blocknumber where owner can send");
        require(ownership[tokenURI].owner != address(0), "must be owned already");
        ownership[tokenURI] = Ownership(burnAddress, true); // burn it, can redeem stake
        beneficiary.transfer(defaultStakedValue); // send them money for burning
    }
}