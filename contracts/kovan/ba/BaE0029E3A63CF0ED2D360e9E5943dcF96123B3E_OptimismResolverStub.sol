pragma solidity ^0.8.7;
pragma abicoder v2;
import "./OptimismVerifierI.sol";

contract OptimismResolverStub {
  string public gateway;
  address public l2resolver;
  OptimismVerifierI public verifier;

  constructor(OptimismVerifierI _verifier, string memory _gateway, address _l2resolver) {
    verifier = _verifier;
    gateway = _gateway;
    l2resolver = _l2resolver;
  }

  error OffchainLookup(bytes prefix, string url);

  function addr(bytes32 node) external view returns(address) {
    bytes memory prefix = abi.encodeWithSelector(OptimismResolverStub.addrWithProof.selector, node);
    revert OffchainLookup(prefix, gateway);
  }

  function addrWithProof(bytes32 node, OptimismVerifierI.L2StateProof memory proof) external view returns(address) {
    bytes32 slot = keccak256(abi.encodePacked(node, uint256(1)));
    bytes32 value = verifier.getVerifiedValue(l2resolver, slot, proof);
    return address(uint160(uint256(value)));
  }
}

pragma solidity ^0.8.7;
pragma abicoder v2;

interface OptimismVerifierI{
  struct ChainBatchHeader {
    uint256 batchIndex;
    bytes32 batchRoot;
    uint256 batchSize;
    uint256 prevTotalElements;
    bytes extraData;
  }

  struct ChainInclusionProof {
    uint256 index;
    bytes32[] siblings;
  }

  struct L2StateProof {
    bytes32 stateRoot;
    ChainBatchHeader stateRootBatchHeader;
    ChainInclusionProof stateRootProof;
    bytes stateTrieWitness;
    bytes storageTrieWitness;
  }

  function getVerifiedValue(address l2resolver, bytes32 slot, L2StateProof memory proof) external view returns(bytes32);
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}