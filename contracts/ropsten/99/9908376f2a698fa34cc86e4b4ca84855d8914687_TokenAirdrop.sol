// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IDistributor.sol";

/**
 * @title Token Airdrop contract
 */
contract TokenAirdrop is IDistributor, Ownable {
  address public immutable override token;
  bytes32 public immutable override merkleRoot;

  uint256 public override totalClaimed;
  uint256 public immutable startTime;
  uint256 public constant claimWindow = 21 days;

  mapping(uint256 => uint256) private claimedBitMap;

  constructor(address token_, bytes32 merkleRoot_) {
    token = token_;
    merkleRoot = merkleRoot_;
    startTime = block.timestamp;
  }

  function isClaimed(uint256 index) public view override returns (bool) {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    uint256 claimedWord = claimedBitMap[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  function claim(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external override {
    require(!isClaimed(index), "TokenAirdrop: Already claimed");
    require(block.timestamp - startTime <= claimWindow, "TokenAirdrop: Too late");

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, account, amount));
    require(MerkleProof.verify(merkleProof, merkleRoot, node), "TokenAirdrop: Invalid proof");

    // Mark it claimed and send the token.
    totalClaimed = totalClaimed + amount;
    _setClaimed(index);
    require(IERC20(token).transfer(account, amount), "TokenAirdrop: Transfer failed");

    emit Claimed(index, account, amount);
  }

  // collect any token send by mistake, collect target after 90 days
  function collectDust(address _token) external {
    if (_token == address(0)) { // token address(0) = ETH
      payable(owner()).transfer(address(this).balance);
    } else {
      if (_token == token) {
        require(block.timestamp > startTime + claimWindow, "TokenAirdrop: Not ready");
      }
      uint256 balance = IERC20(_token).balanceOf(address(this));
      IERC20(_token).transfer(owner(), balance);
    }
  }

  function _setClaimed(uint256 index) private {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
  }
}