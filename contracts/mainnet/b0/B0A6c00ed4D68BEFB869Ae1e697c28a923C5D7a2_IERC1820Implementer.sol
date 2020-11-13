pragma solidity 0.5.12;

// As defined in https://eips.ethereum.org/EIPS/eip-1820 for use in contracts the 1820 registry needs to call
interface IERC1820Implementer {
  function canImplementInterfaceForAddress(bytes32 interfaceHash, address account) external view returns (bytes32);
}