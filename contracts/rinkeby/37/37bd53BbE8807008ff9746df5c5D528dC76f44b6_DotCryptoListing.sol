/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

abstract contract Registry {
    function setOwner(address to, uint256 tokenId) virtual external;
    function isApprovedOrOwner(address spender, uint256 tokenId) virtual external view returns (bool);
}

/**
 * @title DotCryptoListing
 * @dev List .crypto domains for sale
 */
contract DotCryptoListing {

    mapping(uint256 => uint) internal _listings;
    Registry internal _registry;
    
    constructor(Registry registry) {
        _registry = registry;
    }
    
    fallback() external {}

    function listDomain(uint256 tokenId, uint domainPrice) external {
        require(_registry.isApprovedOrOwner(msg.sender, tokenId));
        require(_registry.isApprovedOrOwner(address(this), tokenId));
        _listings[tokenId] = domainPrice;
    }
    
    function buyDomain(uint256 tokenId) external payable {
        require(_listings[tokenId] == msg.value);
        _registry.setOwner(msg.sender, tokenId);
        delete _listings[tokenId];
    }

    function price(uint256 tokenId) external view returns (uint) {
        return _listings[tokenId];
    }
}