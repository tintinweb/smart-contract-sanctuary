/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

pragma solidity ^0.8.0;

interface IToken {
  function transferFrom(address from, address to, uint amount) external returns (bool);
  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint256 value) external returns (bool);
}

contract BridgeBase {
  IToken public token;
  mapping(address => mapping(uint => bool)) public processedNonces;
  mapping(address => uint) public tokenLocked;

  enum Step { Burn, Mint }
  event Transfer(
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce,
    bytes signature,
    Step indexed step
  );

  constructor(address _token) {
    token = IToken(_token);
  }

  function burn(address to, uint amount, uint nonce, bytes calldata signature) external {
    require(processedNonces[msg.sender][nonce] == false, 'transfer already processed');
    processedNonces[msg.sender][nonce] = true;
    require(token.transferFrom(msg.sender, address(this), amount), 'failed to lock token');
    tokenLocked[to] = tokenLocked[to] + amount;

    emit Transfer(
      msg.sender,
      to,
      amount,
      block.timestamp,
      nonce,
      signature,
      Step.Burn
    );
  }

  function mint(
    address from, 
    address to, 
    uint amount, 
    uint nonce,
    bytes calldata signature
  ) external {
    bytes32 message = prefixed(keccak256(abi.encodePacked(
      from, 
      to, 
      amount,
      nonce
    )));
    require(recoverSigner(message, signature) == from , 'wrong signature');
    require(processedNonces[from][nonce] == false, 'transfer already processed');
    require(tokenLocked[from] >= amount, 'insufficient token locked');
    processedNonces[from][nonce] = true;
    token.transfer(to, amount);
    tokenLocked[from] = tokenLocked[from] - amount;

    emit Transfer(
      from,
      to,
      amount,
      block.timestamp,
      nonce,
      signature,
      Step.Mint
    );
  }

  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      '\x19Ethereum Signed Message:\n32', 
      hash
    ));
  }

  function recoverSigner(bytes32 message, bytes memory sig)
    internal
    pure
    returns (address)
  {
    uint8 v;
    bytes32 r;
    bytes32 s;
  
    (v, r, s) = splitSignature(sig);
  
    return ecrecover(message, v, r, s);
  }

  function splitSignature(bytes memory sig)
    internal
    pure
    returns (uint8, bytes32, bytes32)
  {
    require(sig.length == 65);
  
    bytes32 r;
    bytes32 s;
    uint8 v;
  
    assembly {
        // first 32 bytes, after the length prefix
        r := mload(add(sig, 32))
        // second 32 bytes
        s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
        v := byte(0, mload(add(sig, 96)))
    }
  
    return (v, r, s);
  }
}

contract BridgeEth is BridgeBase {
  constructor(address token) BridgeBase(token) {}
}