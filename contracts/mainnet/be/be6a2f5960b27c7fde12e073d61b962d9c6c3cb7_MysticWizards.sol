// SPDX-License-Identifier: MIT

/*
*
* Mystic Wizards Contract
* 
* Contract by Matt Casanova [Twitter: @DevGuyThings]
* 
* Launched on Hashku
*
*/

pragma solidity 0.8.10;

import "./Hashku.sol";

// MYSTIC WIZARDS WITHDRAWAL ADDRESS: 0x82d2d60103A9455Efe466831e38d1418927b1358

contract MysticWizards is Hashku {

    uint public presalePrice = 50000000000000000;
    mapping(uint256 => uint256) public tokenAffinities;

    constructor() Hashku(
        "Mystic Wizards", 
        "MYSTIC", 
        "https://storage.hashku.com/api/mystic-wizards/main/", 
        "MYSTIC", 
        7777, 
        10, 
        20, 
        60000000000000000, 
        5, 
        0x82d2d60103A9455Efe466831e38d1418927b1358
    )  {
    }

    // convenience function used by Hashku to check max for UI
    function maxMintPerTransaction() public view override returns (uint256) {
        if (isPublic) {
            return maxMintPerTransactionNumber;
        }

        return 0;
    }

    // convenience function used by Hashku to check max for UI; 0 is unlimited
    function maxMintPerAddress() public view override returns (uint256) {
        if (isPublic) {
            return 0;
        }

        return maxMintPerAddressNumber;
    }

    // convenience function used by Hashku to check max for UI
    function price() public view override returns (uint256) {
        if (isPublic) {
            return priceNumber;
        }

        return presalePrice;
    }

    // public minting: max tokens per transaction only
    function shop(uint256 _amount) external override payable {
        require(_amount <= maxMintPerTransactionNumber, "max_mintable");
        require(nextToken() + _amount <= maxTokens, "not_enough_tokens");
        require(!isClosed, "is_closed");
        require(isPublic, "not_public");
        require(priceNumber * _amount == msg.value, "incorrect_funds");

        for (uint256 i = 0; i < _amount; i++) {
            mint(_msgSender());
        }
    }

    // pre-sale minting: max tokens per address, signature required
    function shop(uint256 _amount, bytes memory _signature) external override payable {
        require(tokensMinted[_msgSender()] + _amount <= maxMintPerAddressNumber, "max_minted");
        require(nextToken() + _amount <= maxTokens, "not_enough_tokens");
        require(!isPublic, "is_public");
        require(!isClosed, "is_closed");
        require(verifySignature(_signature), "invalid_signature");
        require(presalePrice * _amount == msg.value, "incorrect_funds");

        tokensMinted[_msgSender()] += _amount;
        for (uint256 i = 0; i < _amount; i++) {
            mint(_msgSender());
        }
    }

    function setPresalePrice(uint256 _price) external onlyOwner {
        presalePrice = _price;
    }

    function setTokenAffinities(uint256[] calldata _tokenIds, uint256[] calldata _affinityIds) external onlyOwner {
        require(_tokenIds.length == _affinityIds.length, "amount_mismatch");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenAffinities[_tokenIds[i]] = _affinityIds[i];
        }
    }
}