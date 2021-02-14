//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract SwapETH {
  struct DepositId {
    Testnet testnet;
    uint64 nonce;
  }
  enum Testnet{ ROPSTEN, RINKEBY, KOVAN, GOERLI }
  event Received(uint64, address, uint256, Testnet);

  uint64 public nonce;
  address public owner;
  mapping(Testnet => mapping (uint64 => bool)) swapsCompleted;

  modifier onlyOwner {
    require(msg.sender == owner, "Unauthorized");
    _;
  }

  constructor() { owner = msg.sender; }

  function swap(Testnet to) external payable {
    uint64 newNonce = nonce + 1;
    nonce = newNonce;
    emit Received(newNonce, msg.sender, msg.value, to);
  }

  function transfer(address payable to, uint256 amount, Testnet from, uint64 fromNonce) external onlyOwner {
    _transfer(to, amount, from, fromNonce);
  }

  function batchTransfer(address payable[] memory to, uint256[] memory amount, Testnet[] memory from, uint64[] memory fromNonce) external onlyOwner {
    require(to.length == amount.length && amount.length == from.length && from.length == fromNonce.length);
    for (uint256 i = 0; i < to.length; i++) {
      _transfer(to[i], amount[i], from[i], fromNonce[i]);
    }
  }

  function passBaton(address newOwner) external onlyOwner {
    owner = newOwner;
  }

  function _transfer(address payable to, uint256 amount, Testnet from, uint64 fromNonce) internal {
    if (!swapsCompleted[from][fromNonce]) {
      swapsCompleted[from][fromNonce] = true;
      (bool success,) = to.call{value: amount, gas: 3000}("");
      // Shut the fuck up Solidity
      success;
    }
  }

  receive() external payable {}
}