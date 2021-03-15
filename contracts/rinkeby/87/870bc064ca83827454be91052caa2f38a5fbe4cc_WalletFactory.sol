// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
import './WalletSimple.sol';
import './CloneFactory.sol';

contract WalletFactory is CloneFactory {
  address public implementationAddress;

  event WalletCreated(address newWalletAddress, address[] allowedSigners);

  constructor(address _implementationAddress) {
    implementationAddress = _implementationAddress;
  }

  function createWallet(address[] calldata allowedSigners, bytes32 salt)
    external
  {
    // include the signers in the salt so any contract deployed to a given address must have the same signers
    bytes32 finalSalt = keccak256(abi.encodePacked(allowedSigners, salt));

    address payable clone = createClone(implementationAddress, finalSalt);
    WalletSimple(clone).init(allowedSigners);
    emit WalletCreated(clone, allowedSigners);
  }
}