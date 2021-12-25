//  SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";

contract SNOWFLAKE is Ownable, ERC721 {

    string public baseURI;
    uint16 public totalSupply = 0;

    // tokenId => # of remptions left
    // every tokenId starts with 0
    // increment up with ev redemption max==2
    mapping(uint16 => uint8) public redemptions;

   constructor() 
        ERC721('SNOFLAKES', "SF") {
        setBaseURI("https://snoflakes.io/files");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // baseURI + tokenId + .json
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, '/', Strings.toString(tokenId), '/', Strings.toString(tokenId), '.json')) : "";
    }

    function withdraw() public onlyOwner {
        // withdraw logic
        require(payable(msg.sender).send(address(this).balance));
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function mint(address to, uint16 qualifyingTokenId) public {
        require (
            ( ownerOf(qualifyingTokenId) == msg.sender && redemptions[qualifyingTokenId] < 2 )
            , "You must have a qualifying token that has not been used twice to mint new tokens." );
        require (msg.sender != to, "You cannot mint to yourself.");

        redemptions[totalSupply + 1] = 0;
        redemptions[qualifyingTokenId] += 1;
        _safeMint(to, totalSupply + 1);
        totalSupply++;
    }

    function ownerMint(address to) onlyOwner public {
        require (  msg.sender == owner(), "Only owner." );
        redemptions[totalSupply + 1] = 0;
        _safeMint(to, totalSupply + 1);
        totalSupply++;
    }
    

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}