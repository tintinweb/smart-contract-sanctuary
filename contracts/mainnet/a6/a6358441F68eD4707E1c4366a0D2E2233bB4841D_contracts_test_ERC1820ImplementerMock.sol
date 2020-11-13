pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts-ethereum-package/contracts/introspection/IERC1820Implementer.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC777/IERC777Recipient.sol";

import "../Constants.sol";

contract ERC1820ImplementerMock is IERC1820Implementer, IERC777Recipient {

  constructor () public {
    Constants.REGISTRY.setInterfaceImplementer(address(this), Constants.TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
  }

  function canImplementInterfaceForAddress(bytes32, address) external view virtual override returns(bytes32) {
    return Constants.ACCEPT_MAGIC;
  }

  function tokensReceived(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes calldata userData,
    bytes calldata operatorData
  ) external override {
  }
}