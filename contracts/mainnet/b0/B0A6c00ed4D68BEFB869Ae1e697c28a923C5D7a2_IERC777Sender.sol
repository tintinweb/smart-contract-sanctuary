pragma solidity 0.5.12;

// As defined in the 'ERC777TokensSender And The tokensToSend Hook' section of https://eips.ethereum.org/EIPS/eip-777
interface IERC777Sender {
  function tokensToSend(address operator, address from, address to, uint256 amount, bytes calldata data,
      bytes calldata operatorData) external;
}