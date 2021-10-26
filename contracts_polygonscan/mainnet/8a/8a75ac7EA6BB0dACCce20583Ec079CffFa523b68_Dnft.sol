// SPDX-License-Identifier: None
pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./ERC721.sol";

contract Dnft is Ownable, ERC721 {
    using SafeMath for uint256;
    
    constructor(string memory tokenBaseUri) ERC721("NFT of DPCP ecosystem", "dNFT") {
        _setBaseURI(tokenBaseUri);
    }

    function mintDnft(address _to) external onlyMinter returns(uint256) {
        uint256 newId = totalSupply();
        _safeMint(_to, newId);
        return newId;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    function tokensOwnedBy(address _addr) external view returns(uint256[] memory) {
      uint tokenCount = balanceOf(_addr);

      uint256[] memory ownedTokenIds = new uint256[](tokenCount);
      for(uint i = 0; i < tokenCount; i++){
        ownedTokenIds[i] = tokenOfOwnerByIndex(_addr, i);
      }
      return ownedTokenIds;
    }
    
    
    function setMinter(address _newMinter) external onlyOwner{
        _setMinter(_newMinter);
    }
    
    modifier onlyMinter(){
        require(msg.sender == _minter, "caller is not the minter");
        _;
    }

}