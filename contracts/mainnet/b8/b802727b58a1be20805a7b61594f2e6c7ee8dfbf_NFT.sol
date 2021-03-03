pragma solidity ^0.4.24;

import "./ERC721Token.sol";

contract NFT is ERC721Token {

    constructor (string _name, string _symbol) public
        ERC721Token(_name, _symbol){
    }

    function mintUniqueTokenTo(
        address _to,
        uint256 _tokenId,
        string  _tokenURI
    ) public
    {
        super._mint(_to, _tokenId);
        super._setTokenURI(_tokenId, _tokenURI);
    }

}