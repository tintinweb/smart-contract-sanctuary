/**
 *Submitted for verification at Etherscan.io on 2021-12-12
*/

pragma solidity ^0.8.0;

interface IToken {
  function transferFrom(address from, address to, uint amount) external returns (bool);
  function transfer(address to, uint256 value) external returns (bool);
}

contract BridgeBase {
  address public admin;
  IToken public token;
  uint public nonce;
  mapping(uint => bool) public processedNonces;

  enum Step { Burn, Mint }
  event Transfer(
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce,
    Step indexed step
  );

  constructor(address _token) {
    admin = msg.sender;
    token = IToken(_token);
  }

  function burn(address to, uint amount) external {
    require(token.transferFrom(msg.sender, address(this), amount), 'failed to lock token');
    emit Transfer(
      msg.sender,
      to,
      amount,
      block.timestamp,
      nonce,
      Step.Burn
    );
    nonce++;
  }

  function mint(address to, uint amount, uint otherChainNonce) external {
    require(msg.sender == admin, 'only admin');
    require(processedNonces[otherChainNonce] == false, 'transfer already processed');
    processedNonces[otherChainNonce] = true;
    token.transfer(to, amount);
    emit Transfer(
      msg.sender,
      to,
      amount,
      block.timestamp,
      otherChainNonce,
      Step.Mint
    );
  }
}

contract BridgeEth is BridgeBase {
  constructor(address token) BridgeBase(token) {}
}