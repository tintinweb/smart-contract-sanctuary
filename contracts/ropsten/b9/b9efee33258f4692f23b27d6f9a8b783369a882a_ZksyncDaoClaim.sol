// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { IERC20 } from "IERC20.sol"; 
import { MerkleProof } from "MerkleProof.sol"; 

contract ZksyncDaoClaim {

  address public immutable token;
  bytes32 public immutable merkleRoot;

  mapping(address => bool) public hasClaimed;

  error AlreadyClaimed();
  error NotInMerkle();

  constructor(address token_, bytes32 merkleRoot_) public {
        token = token_;
        merkleRoot = merkleRoot_;
    }
    
  event Claim(address indexed to, uint256 amount);

  function claim(address to, uint256 amount, bytes32[] calldata proof) external {

    if (hasClaimed[to]) revert AlreadyClaimed();

    bytes32 leaf = keccak256(abi.encodePacked(to, amount));
    bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
    if (!isValidLeaf) revert NotInMerkle();

    hasClaimed[to] = true;

    IERC20(token).transfer(to, amount);
  
    emit Claim(to, amount);
  }
}