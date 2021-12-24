// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

abstract contract IImpishSpiral is IERC721 {
  uint256 public _tokenIdCounter;

  function getMintPrice() public virtual view returns (uint256);
  function mintSpiralRandom() external virtual payable;
}

contract MultiMint is ReentrancyGuard, IERC721Receiver {
  // The ImpishSpiral contract
  IImpishSpiral public impishspiral;

  constructor(address _impishspiral) {
    impishspiral = IImpishSpiral(_impishspiral);
  }

  function multiMint(uint8 count) external payable nonReentrant{
    require(count > 0, "AtLeastOne");
    require(count <= 10, "AtMost10");

    // This function doesn't check if you've sent enough money. If you didn't it will revert
    // because the mintSpiralRandom will fail
    uint8 mintedSoFar;
    uint256 nextTokenId = impishspiral._tokenIdCounter();
    
    for (mintedSoFar = 0; mintedSoFar < count; mintedSoFar++) {
      uint256 price = impishspiral.getMintPrice();
      impishspiral.mintSpiralRandom{value: price}();
      
      impishspiral.safeTransferFrom(address(this), msg.sender, nextTokenId);
      nextTokenId += 1;  
    }

    // If there is any excess money left, send it back
    if (address(this).balance > 0) {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
    }
  }

  // Default payable function, so the contract can accept any refunds
  receive() external payable {
    // Do nothing
  }

  // Function that marks this contract can accept incoming NFT transfers
  function onERC721Received(address, address, uint256 , bytes calldata) public pure returns(bytes4) {
      // Return this value to accept the NFT
      return IERC721Receiver.onERC721Received.selector;
  }
}