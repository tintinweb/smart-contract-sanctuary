// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import './Itoken.sol';

contract BridgeJax {
  
  address public admin;
  IToken public token;

  mapping(bytes => bool) public processedNonces;

  enum Step { Deposit, Withdraw }

  event Deposit(
    address from,
    bytes to,
    uint amount
  );

  event Withdraw(
    bytes from,
    address to,
    uint amount
  );

  constructor(address _token) {
    admin = msg.sender;
    token = IToken(_token);
  }

  modifier onlyAdmin() {
    require(admin == msg.sender, "Only Admin can perform this operation.");
    _;
  }

  function deposit(uint amount) external onlyAdmin {
    token.transferFrom(admin, address(this), amount);
  }

  function withdraw(uint amount) external onlyAdmin {
    token.transfer(admin, amount);
  }

  function deposit(bytes memory to, uint amount) external {
    token.transferFrom(msg.sender, address(this), amount);
    emit Deposit(
      msg.sender,
      to,
      amount
    );
  }

  function withdraw(
    bytes memory from, 
    address to, 
    uint amount, 
    bytes memory signature
  ) external {
    bytes32 message = prefixed(keccak256(abi.encodePacked(
      from,
      to, 
      amount
    )));
    require(recoverSigner(message, signature) == msg.sender , 'wrong signature');
    require(processedNonces[from] == false, 'transfer already processed');
    processedNonces[from] = true;
    require(token.balanceOf(address(this)) >= amount, 'insufficient pool');
    token.transfer(to, amount);
    emit Withdraw(from, to, amount);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IToken {
  function transfer(address to, uint amount) external returns (bool);
  function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
  function balanceOf(address owner) external view returns(uint);
}