/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function ownerOf(uint256) external view returns (address);
}

interface IERC1155 {
    function balanceOf(address, uint256) external view returns (uint256);
}
/**
 * @title NFTRevert
 * @author Anish Agnihotri
 */
contract NFTRevert {
  /**
   * @param _nftContract address of token contract
   * @param _owner address of expected owner
   * @param _nftIds to check ownership
   */
  function verifyOwnershipAndPay721(
    address _nftContract,
    address _owner,
    uint256[] calldata _nftIds
  ) external payable {
    // Success starts as true by default
    bool _success = true;
    for (uint256 i = 0; i < _nftIds.length; i++) {
      if (IERC721(_nftContract).ownerOf(_nftIds[i]) != _owner) {
        _success = false;
      }
    }
    require(_success, "NFTRevert: Address does not own all nfts in array");
    (bool sent, ) = payable(block.coinbase).call{value: msg.value}("");
    require(sent, "NFTRevert: Unable to bribe miner");
  }
  /**
   * @param _nftContract address of token contract
   * @param _owner address of expected owner
   * @param _nftIds to check ownership
   * @param _expectedBalances to check increase
   */
  function verifyOwnershipAndPay1155(
    address _nftContract,
    address _owner,
    uint256[] calldata _nftIds,
    uint256[] calldata _expectedBalances
  ) external payable {
    // Success starts as true by default
    bool _success = true;
    for (uint256 i = 0; i < _nftIds.length; i++) {
      if (IERC1155(_nftContract).balanceOf(_owner, _nftIds[i]) != _expectedBalances[i]) {
        _success = false;
      }
    }
    require(_success, "NFTRevert: Address does not own all nfts in array");
    (bool sent, ) = payable(block.coinbase).call{value: msg.value}("");
    require(sent, "NFTRevert: Unable to bribe miner");
  }
}