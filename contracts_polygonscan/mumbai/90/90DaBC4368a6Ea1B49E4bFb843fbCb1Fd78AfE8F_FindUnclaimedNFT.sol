/**
 *Submitted for verification at polygonscan.com on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC721 {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract FindUnclaimedNFT {
  function unclaimed(
    address _addr,
    uint256 _start,
    uint256 _end
  ) public view returns (uint256[] memory) {
    require(_end > _start, 'unclaimed: end id < start id');

    IERC721 erc721 = IERC721(_addr);
    uint256 index = 0;
    uint256[] memory ids;
    ids = new uint256[](_end - _start);

    for (uint256 i = _start; i < _end; i++) {
      try erc721.ownerOf(i) {
        // do nothing
      } catch {
        ids[index] = i;
        index++;
      }
    }
    return ids;
  }
}