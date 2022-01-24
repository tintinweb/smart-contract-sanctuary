// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Counters.sol";
import "./nf-token-metadata.sol";
import "./whitelist.sol";

contract frens is NFTokenMetadata, Whitelist {

    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
    address public treasuryAddress;
    uint public mintFee;

    constructor() {
        nftName = "lets be frens";
        nftSymbol = "FRNS";
        mintFee = 1000000000000000;
        treasuryAddress = 0x92A9E00F3B52342B47bF5526c1c8cdD43bC76D25;
    }

    function setTreasury(address _addressToMakeTreasury) public onlyOwner {
        treasuryAddress = _addressToMakeTreasury;
    }

    function setMintFee(uint _mintFee) public onlyOwner {
        mintFee = _mintFee;
    }

    function createToken(address _to, string memory tokenURI) public payable isWhitelisted(msg.sender) returns (bool, bytes memory, uint) {
        
        (bool sent, bytes memory data) = treasuryAddress.call{value: mintFee}("");
        require(sent, "Failed to send Ether");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(_to, newItemId);
        _setTokenUri(newItemId, tokenURI);

        return (sent, data, newItemId);
    }

}