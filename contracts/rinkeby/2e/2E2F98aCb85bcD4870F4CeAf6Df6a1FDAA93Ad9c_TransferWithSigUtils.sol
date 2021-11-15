pragma solidity ^0.5.2;


library TransferWithSigUtils {
  function getTokenTransferOrderHash(address token, address spender, uint256 amount, bytes32 data, uint256 expiration)
    public
    pure
    returns (bytes32 orderHash)
  {
    orderHash = hashEIP712Message(token, hashTokenTransferOrder(spender, amount, data, expiration));
  }

  function hashTokenTransferOrder(address spender, uint256 amount, bytes32 data, uint256 expiration)
    internal
    pure
    returns (bytes32 result)
  {
    string memory EIP712_TOKEN_TRANSFER_ORDER_SCHEMA =  "TokenTransferOrder(address spender,uint256 tokenIdOrAmount,bytes32 data,uint256 expiration)";
    bytes32 EIP712_TOKEN_TRANSFER_ORDER_SCHEMA_HASH = keccak256(abi.encodePacked(EIP712_TOKEN_TRANSFER_ORDER_SCHEMA));
    bytes32 schemaHash = EIP712_TOKEN_TRANSFER_ORDER_SCHEMA_HASH;
    assembly {
      // Load free memory pointer
      let memPtr := mload(64)
      mstore(memPtr, schemaHash)                                                         // hash of schema
      mstore(add(memPtr, 32), and(spender, 0xffffffffffffffffffffffffffffffffffffffff))  // spender
      mstore(add(memPtr, 64), amount)                                           // amount
      mstore(add(memPtr, 96), data)                                                      // hash of data
      mstore(add(memPtr, 128), expiration)                                               // expiration
      // Compute hash
      result := keccak256(memPtr, 160)
    }
  }

  function hashEIP712Message(address token, bytes32 hashStruct)
    internal
    pure
    returns (bytes32 result)
  {
    string memory EIP712_DOMAIN_SCHEMA = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    bytes32 EIP712_DOMAIN_SCHEMA_HASH = keccak256(abi.encodePacked(EIP712_DOMAIN_SCHEMA));
    string memory EIP712_DOMAIN_NAME = "Shib Network";
    string memory EIP712_DOMAIN_VERSION = "1";
    uint256 EIP712_DOMAIN_CHAINID = 6973;
    bytes32 EIP712_DOMAIN_HASH = keccak256(abi.encode(
      EIP712_DOMAIN_SCHEMA_HASH,
      keccak256(bytes(EIP712_DOMAIN_NAME)),
      keccak256(bytes(EIP712_DOMAIN_VERSION)),
      EIP712_DOMAIN_CHAINID,
      token
    ));
    bytes32 domainHash = EIP712_DOMAIN_HASH;
    assembly {
      // Load free memory pointer
      let memPtr := mload(64)
      mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000)  // EIP191 header
      mstore(add(memPtr, 2), domainHash)                                          // EIP712 domain hash
      mstore(add(memPtr, 34), hashStruct)                                                 // Hash of struct
      // Compute hash
      result := keccak256(memPtr, 66)
    }
  }
}

