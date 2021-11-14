/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
  function mint(address to, uint amount) external;
  function burn(address owner, uint amount) external;
}

contract MonsterVillageBridge {
  address public admin;
  IToken public token;
  uint public nonce;
  mapping(uint => bool) public processedNonces;

  event Mint(
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce
  );

  event Burn(
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce
  );

  constructor(address _token) {
    admin = msg.sender;
    token = IToken(_token);
  }

  function burn(address to, uint amount) external {
    token.burn(msg.sender, amount);
    emit Burn(
      msg.sender,
      to,
      amount,
      block.timestamp,
      nonce
    );
    nonce++;
  }

  function mint(address to, uint amount, uint otherChainNonce) external {
    require(msg.sender == admin, 'only admin');
    require(processedNonces[otherChainNonce] == false, 'transfer already processed');
    processedNonces[otherChainNonce] = true;
    token.mint(to, amount);
    emit Mint(
      msg.sender,
      to,
      amount,
      block.timestamp,
      otherChainNonce
    );
  }
}