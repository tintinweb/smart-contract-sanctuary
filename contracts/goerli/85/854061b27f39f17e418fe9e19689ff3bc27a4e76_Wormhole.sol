/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;

struct WormholeGUID {
  bytes32 sourceDomain;
  bytes32 targetDomain;
  address receiver;
  address operator;
  uint128 amount;
  uint80 nonce;
  uint48 timestamp;
}

contract Wormhole {
  event WormholeInitialized(WormholeGUID wormhole);

  uint80 nonce;

  function emitRandomEvent() external {
    nonce++;
    uint256 seed = block.timestamp + nonce;

    WormholeGUID memory wormhole = WormholeGUID({
      sourceDomain: keccak256(abi.encodePacked(seed+1)),
      targetDomain: keccak256(abi.encodePacked(seed+2)),
      receiver: address(bytes20(keccak256(abi.encodePacked(seed+3)))),
      operator: address(bytes20(keccak256(abi.encodePacked(seed+4)))),
      amount: uint128(bytes16(keccak256(abi.encodePacked(seed+5)))),
      nonce: nonce,
      timestamp: uint48(seed)
    });

    emit WormholeInitialized(wormhole);
  }
}