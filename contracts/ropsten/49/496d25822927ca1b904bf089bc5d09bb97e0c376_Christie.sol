// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./erc721v3.sol";

contract Christie is ERC721, Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    event TokenURIUpdated(uint256 indexed _tokenId, string  _uri);
    event TokenDeleted(uint256 indexed _tokenId);
    

    constructor() public ERC721("Christies", "ChristiesToken") {
    }
    
    
    //minting function: only christies can call this. Inputs: token URI and address of artist.
    //Job: Mints a token by serial number linking artist address to tokenID, Links tokenURI and tokenID
    function mint(string memory tokenURI, address Account)
        public
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(Account, newItemId);
        _setTokenURI(newItemId, tokenURI);
        return newItemId;
    }
    
    //minting function: any public person can call this function
    //Job: Tells if a particular tokenId has already been minted
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }
    
    //updateURI function: only owner or approved(operator) can call
    //Job: Changes tokenURI to different tokenURI. This useful when metadata has to be changed or tokenURI link is broken
    function updateURI(string memory __tokenURI, uint256 __tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), __tokenId), "ERC721: transfer caller is not owner nor approved");
        _setTokenURI(__tokenId,__tokenURI);
        emit TokenURIUpdated(__tokenId,  __tokenURI);
    }
    
    //minting function: only owner or approved(operator) can call
    //Job: Deletes a token from existence. 
    function deleteToken(uint256 __tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), __tokenId), "ERC721: transfer caller is not owner nor approved");
        _burn(__tokenId);
        emit TokenDeleted(__tokenId);

    }
    
}