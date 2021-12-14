// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract NFTStakingPoolTest {

  mapping(address => mapping(uint256 => uint32)) public tokenStaminas; 
  mapping(uint256 => bool) public hasMerged;

  constructor() {
  }

  function getTokenStaminaTotal(uint256 _tokenId, address _nftContractAddress) external view returns (uint32 stamina) {
    return tokenStaminas[_nftContractAddress][_tokenId];
  }

  function setTokenStaminaTotal(uint32 _stamina, uint256 _tokenId, address _nftContractAddress) external {
    tokenStaminas[_nftContractAddress][_tokenId] = _stamina;
  }

  function getTokenStamina(uint256 _tokenId, address _nftContractAddress) external view returns (uint256 _stamina) {
    return tokenStaminas[_nftContractAddress][_tokenId] / 1000000000;
  }
  function mergeTokens(uint256 _newTokenId, uint256[] memory _tokenIds, address _nftContractAddress) external {
    
    tokenStaminas[_nftContractAddress][_newTokenId] = 0;
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      hasMerged[_tokenIds[i]] = true;

      tokenStaminas[_nftContractAddress][_newTokenId] += tokenStaminas[_nftContractAddress][_tokenIds[i]];
    }
  }
}