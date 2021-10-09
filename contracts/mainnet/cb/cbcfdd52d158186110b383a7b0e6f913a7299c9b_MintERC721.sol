// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";


contract MintERC721 is ERC721Tradable {
    string private uribaseToken_;
      
    constructor(string memory collectionName, string memory collectionSymbol, string memory _baseuri, address _proxyRegistryAddress,address _adminwallet,uint256 _price) 
        ERC721Tradable(collectionName, collectionSymbol, _proxyRegistryAddress,_adminwallet,_price)
    {
        
        uribaseToken_ = _baseuri;
        
    }
        
    
    function baseTokenURI() override public view returns (string memory) {
        return uribaseToken_;
    }

    function contractURI() public view returns (string memory) {
        return uribaseToken_;
    }
    
    function updateURL(string memory _uri) public onlyOwner {
        uribaseToken_ = _uri;
    }
}