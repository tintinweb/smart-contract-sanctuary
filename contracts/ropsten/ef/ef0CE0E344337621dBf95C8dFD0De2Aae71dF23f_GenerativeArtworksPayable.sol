// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract GenerativeArtworksERC721 {

  mapping(uint256 => uint256) public pieceIdToPricePerPrintInWei;
  mapping(address => bool) public isAdmin;

  function mint(address to, uint256 pieceId, address by) external returns (uint256) {}
}

contract GenerativeArtworksPayable {

  GenerativeArtworksERC721 internal mintContract;
  address payable public generativeArtworksWallet;
  mapping(uint256 => mapping(address => bool)) public hasMinted;
  mapping(uint256 => bool) public isLimited;

  modifier onlyAdmin() {
      require(mintContract.isAdmin(msg.sender), "Only admin");
      _;
  }

  constructor(address mintContractAddress) {
		mintContract = GenerativeArtworksERC721(mintContractAddress);
    generativeArtworksWallet = payable(msg.sender);
	}
 
	function purchase(address mintTo, uint256 pieceId, address by) payable external returns (uint256) {
      // Check if piece is limited to one mint per wallet address
      if (isLimited[pieceId]) {
        // require that user has not minted this piece or user is an admin
        require(!hasMinted[pieceId][by] || mintContract.isAdmin(by), "Limited to one mint per address");
      }

      // Check if the right value was sent with the transaction
		  require(msg.value == mintContract.pieceIdToPricePerPrintInWei(pieceId), "Incorrect payment amount");
      
      // Mint on other contract
	    uint256 newPrintId = mintContract.mint(mintTo, pieceId, by);

      // Track that "by" has minted "pieceId"
      hasMinted[pieceId][by] = true;

      // Pay to generative artworks wallet
      generativeArtworksWallet.transfer(msg.value);

      return newPrintId;
	}

	function toggleIsLimited(uint256 pieceId) external onlyAdmin {
    isLimited[pieceId] = !isLimited[pieceId];
  }

  function changeMintContract(address mintContractAddress) external onlyAdmin {
    mintContract = GenerativeArtworksERC721(mintContractAddress);
  }

  function changePayableAddress(address payable payableAddress) external onlyAdmin {
    generativeArtworksWallet = payableAddress;
  }

}

