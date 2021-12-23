// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "./ERC721.sol";


contract NFT is ERC721{
    constructor() ERC721("Ixiono token","IXI"){}
   
   uint private _tokenId=0;
   
    function mint() external returns (uint){
    _tokenId++;
    _mint(msg.sender, _tokenId);
    return _tokenId;
    }
}