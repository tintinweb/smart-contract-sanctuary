// SPDX-License-Identifier: MIT

//01110111 01110111 01110111 00101110 01100011 01101000 01110010 01101001 01110011 01110100 01101001 01100101 01110011 00101110 01100011 01101111 01101101
/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                           ***********                                                   //
//                           \         /                                                   //
//                            )_______(                                                    //
//                            |"""""""|_.-._,.---------.,_.-._                             //
//                            |       | | |               | | **]                          //
//                            |       |_| |_             _| |_**]                          //
//                            |_______| '-' `'---------'` '-'                              //
//                            )"""""""(                                                    //
//                           /         \                                                   //
//                           ***********                                                   //
//                                                                                         //
//      ######  ##     ## ########  ####  ######  ######## #### ######## ####  ######      //
//     ##    ## ##     ## ##     ##  ##  ##    ##    ##     ##  ##       #### ##    ##     //
//     ##       ##     ## ##     ##  ##  ##          ##     ##  ##        ##  ##           //
//     ##       ######### ########   ##   ######     ##     ##  ######   ##    ######      //
//     ##       ##     ## ##   ##    ##        ##    ##     ##  ##                  ##     //
//     ##    ## ##     ## ##    ##   ##  ##    ##    ##     ##  ##            ##    ##     //
//      ######  ##     ## ##     ## ####  ######     ##    #### ########       ######      //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////
//01110111 01110111 01110111 00101110 01100011 01101000 01110010 01101001 01110011 01110100 01101001 01100101 01110011 00101110 01100011 01101111 01101101

pragma solidity ^0.6.0;

import "./erc721v7.sol";

contract Christies is ERC721, Ownable{
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    event TokenURIUpdated(uint256 indexed _tokenId, string  _uri);
    event TokenDeleted(uint256 indexed _tokenId);
    

    constructor() public ERC721("Christies", "CHRTOKEN") {
    }
    
    
    //minting function: only christies can call this.
    //Job: Mints a token by serial number linking artist address to tokenID, Links tokenURI and tokenID
    function mint_to_christies()
        public
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(owner(), newItemId);
        _setTokenURI(newItemId, newItemId.toString());
        return newItemId;
    }
    
    //minting function: only christies can call this. Inputs: token URI and address of artist.
    //Job: Mints a token by serial number linking artist address to tokenID, Links tokenURI and tokenID
    function mint_to_artist(address Account)
        public
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(Account, newItemId);
        _setTokenURI(newItemId, newItemId.toString());
        return newItemId;
    }
    
    //minting function: any public person can call this function
    //Job: Tells if a particular tokenId has already been minted
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }
    
    
    //minting function: only owner or approved(operator) can call
    //Job: Deletes a token from existence. 
    function deleteToken(uint256 __tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), __tokenId), "ERC721: transfer caller is not owner nor approved");
        _burn(__tokenId);
        emit TokenDeleted(__tokenId);

    }
    
}