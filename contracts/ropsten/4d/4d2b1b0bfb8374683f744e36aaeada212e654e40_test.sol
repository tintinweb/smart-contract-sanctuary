/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

contract test {
    struct addressStake {
    uint16 tokenId;
  }
mapping(address => addressStake[]) public stakeIndices;

function add(address _address, uint16 _tokenId) public {
    _addtoStakeIndex(_address, _tokenId);
}

function remove(address _address, uint16 _tokenId) public {
    _removetoStakeIndex(_address, _tokenId);
}

function _addtoStakeIndex(address _address, uint16 _tokenId) internal {
    uint actt = stakeIndices[_address].length;
    uint next = actt+1;
    stakeIndices[_address][next] = addressStake({
      tokenId: uint16(_tokenId)
    });
  }

  function _removetoStakeIndex(address _address, uint16 _tokenId) internal {
    uint actt = stakeIndices[_address].length;
    for (uint i = 0; i<actt; i++) {
      if (stakeIndices[_address][i].tokenId==_tokenId) {
        delete stakeIndices[_address][i];
      }
    }
  }

  function showIndex(address _address) public view returns (addressStake[] memory) {
    return stakeIndices[_address];
  }
}