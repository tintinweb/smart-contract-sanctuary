/**
 *Submitted for verification at snowtrace.io on 2021-12-18
*/

// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File contracts/Palette.sol

contract Palette {

  // palette IDs
  uint256 lastPaletteId;
  
  // palette colors
  mapping(uint256 => uint8[]) _tokenColors;


  event PaletteCreated(uint256 paletteId);
  
  function createPalette(uint8[] memory tokenColors) public returns (uint256) {
    uint256 tokenId = lastPaletteId;
    lastPaletteId += 1;
    _tokenColors[tokenId] = tokenColors;
    emit PaletteCreated(tokenId);
    return tokenId;
  }

  function viewPalette(uint256 tokenId) public view returns (uint8[] memory) {
    return _tokenColors[tokenId];
  }
}