// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EIP712External {
  //  address admin = 0x41DD4e50c9a07eF0441e47c4164E2d3346845587; // local
  address admin = 0xE116d01dA012AcF6ffa505165325289BF016db1B; // testnet

  mapping (address => uint) public nonces;
  mapping (address => uint) public levels;
  function verify(
    uint8 v,
    bytes32 r,
    bytes32 s,
    uint256 _level
  ) external {
    bytes32 eip712DomainHash = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("FOTA")),
        keccak256(bytes("1")),
        block.chainid,
        address(this)
      )
    );

    bytes32 hashStruct = keccak256(
      abi.encode(
        keccak256("LevelUp(uint256 level)"),
        _level
      )
    );

    bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
    address signer = ecrecover(hash, v, r, s);
    require(signer == admin, "MyFunction: invalid signature");
    require(signer != address(0), "ECDSA: invalid signature");

    nonces[msg.sender]++;
    levels[msg.sender] = _level;
  }

  function getChainId() public view returns (uint) {
    return block.chainid;
  }
}

