/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

pragma solidity 0.5.16;

contract MinimalInitializableProxyFactory {
  event ProxyCreated(address indexed implementation, address proxy);

  function create(address target) external {
    address clone = createClone(target);
    emit ProxyCreated(target, clone);
  }

  function createAndCall(address target, string calldata initSignature, bytes calldata initData) external {
    address clone = createClone(target);
    bytes memory callData = abi.encodePacked(bytes4(keccak256(bytes(initSignature))), initData);

    // solium-disable-next-line security/no-call-value
    (bool success,) = clone.call(callData);
    require(success, "Initialization reverted");
    emit ProxyCreated(target, clone);
  }

  // taken from:
  // https://github.com/optionality/clone-factory/blob/ffa4dedcec53b68b11450b07685b4df80c33edcc/contracts/CloneFactory.sol#L32
  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  // taken from:
  // https://github.com/optionality/clone-factory/blob/ffa4dedcec53b68b11450b07685b4df80c33edcc/contracts/CloneFactory.sol#L43
  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}