// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./Ownable.sol";

contract CovapTrazability is Ownable{

  mapping(uint256 => bytes32) public proofRegistry;

    /**
     * @dev Uploads a proof in the form of the tree root of a merkle patricia tree 
     * (`root`) associated to a specific name used as a date in EPOCH (`id`).
     * Function is only callable by contract owner.
     */
  function uploadProof(uint256 id, bytes32 root) onlyOwner() public returns (bool){
      proofRegistry[id] = root;
      return true;
  }


    /**
     * @dev Provided the hash of the data to be verified (`leaf`), the epoch where it was registered (`rootId`)
     * and the required proofs (`proof`) and positions (`positions`) in the tree, returns the validity of the data 
     */
  function verify(
    bytes32 leaf,
    uint256 rootId,
    //bytes32 root,
    bytes32[] memory proof,
    uint256[] memory positions
  )
    public
    view
    returns (bool)
  {
    bytes32 root = proofRegistry[rootId];
    bytes32 computedHash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (positions[i] == 1) {
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    return computedHash == root;
  }
}