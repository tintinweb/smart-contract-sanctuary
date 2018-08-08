pragma solidity ^0.4.4;

contract EthereumDIDRegistry {

  mapping(address => address) public owners;
  mapping(address => mapping(bytes32 => mapping(address => uint))) public delegates;
  mapping(address => uint) public changed;
  mapping(address => uint) public nonce;

  modifier onlyOwner(address identity, address actor) {
    require (actor == identityOwner(identity));
    _;
  }

  event DIDOwnerChanged(
    address indexed identity,
    address owner,
    uint previousChange
  );

  event DIDDelegateChanged(
    address indexed identity,
    string delegateType,
    address delegate,
    uint validTo,
    uint previousChange
  );

  event DIDAttributeChanged(
    address indexed identity,
    string name,
    bytes value,
    uint validTo,
    uint previousChange
  );

  function EthereumDIDRegistry() public {
  }

  function identityOwner(address identity) public view returns(address) {
     address owner = owners[identity];
     if (owner != 0x0) {
       return owner;
     }
     return identity;
  }

  function checkSignature(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, bytes32 hash) internal returns(address) {
    address signer = ecrecover(hash, sigV, sigR, sigS);
    require(signer == identityOwner(identity));
    nonce[identity]++;
    return signer;
  }

  function validDelegate(address identity, string delegateType, address delegate) public view returns(bool) {
    uint validity = delegates[identity][keccak256(delegateType)][delegate];
    return (validity >= block.timestamp);
  }

  function validDelegateSignature(address identity, string delegateType, uint8 sigV, bytes32 sigR, bytes32 sigS, bytes32 hash) public returns(address) {
    address signer = ecrecover(hash, sigV, sigR, sigS);
    require(validDelegate(identity, delegateType, signer));
    nonce[signer]++;
    return signer;
  }

  function changeOwner(address identity, address actor, address newOwner) internal onlyOwner(identity, actor) {
    owners[identity] = newOwner;
    DIDOwnerChanged(identity, newOwner, changed[identity]);
    changed[identity] = block.number;
  }

  function changeOwner(address identity, address newOwner) public {
    changeOwner(identity, msg.sender, newOwner);
  }

  function changeOwnerSigned(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, address newOwner) public {
    bytes32 hash = keccak256(byte(0x19), byte(0), this, nonce[identityOwner(identity)], identity, "changeOwner", newOwner); 
    changeOwner(identity, checkSignature(identity, sigV, sigR, sigS, hash), newOwner);
  }

  function addDelegate(address identity, address actor, string delegateType, address delegate, uint validity ) internal onlyOwner(identity, actor) {
    delegates[identity][keccak256(delegateType)][delegate] = block.timestamp + validity;
    DIDDelegateChanged(identity, delegateType, delegate, block.timestamp + validity, changed[identity]);
    changed[identity] = block.number;
  }

  function addDelegate(address identity, string delegateType, address delegate, uint validity) public {
    addDelegate(identity, msg.sender, delegateType, delegate, validity);
  }

  function addDelegateSigned(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, string delegateType, address delegate, uint validity) public {
    bytes32 hash = keccak256(byte(0x19), byte(0), this, nonce[identityOwner(identity)], identity, "addDelegate", delegateType, delegate, validity); 
    addDelegate(identity, checkSignature(identity, sigV, sigR, sigS, hash), delegateType, delegate, validity);
  }

  function revokeDelegate(address identity, address actor, string delegateType, address delegate) internal onlyOwner(identity, actor) {
    delegates[identity][keccak256(delegateType)][delegate] = 0;
    DIDDelegateChanged(identity, delegateType, delegate, 0, changed[identity]);
    changed[identity] = block.number;
  }

  function revokeDelegate(address identity, string delegateType, address delegate) public {
    revokeDelegate(identity, msg.sender, delegateType, delegate);
  }

  function revokeDelegateSigned(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, string delegateType, address delegate) public {
    bytes32 hash = keccak256(byte(0x19), byte(0), this, nonce[identityOwner(identity)], identity, "revokeDelegate", delegateType, delegate); 
    revokeDelegate(identity, checkSignature(identity, sigV, sigR, sigS, hash), delegateType, delegate);
  }

  function setAttribute(address identity, address actor, string name, bytes value, uint validity ) internal onlyOwner(identity, actor) {
    DIDAttributeChanged(identity, name, value, block.timestamp + validity, changed[identity]);
    changed[identity] = block.number;
  }

  function setAttribute(address identity, string name, bytes value, uint validity) public {
    setAttribute(identity, msg.sender, name, value, validity);
  }

  function setAttributeSigned(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, string name, bytes value, uint validity) public {
    bytes32 hash = keccak256(byte(0x19), byte(0), this, nonce[identity], identity, "setAttribute", name, value, validity); 
    setAttribute(identity, checkSignature(identity, sigV, sigR, sigS, hash), name, value, validity);
  }

  function revokeAttribute(address identity, address actor, string name, bytes value ) internal onlyOwner(identity, actor) {
    DIDAttributeChanged(identity, name, value, 0, changed[identity]);
    changed[identity] = block.number;
  }

  function revokeAttribute(address identity, string name, bytes value) public {
    revokeAttribute(identity, msg.sender, name, value);
  }

 function revokeAttributeSigned(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS, string name, bytes value) public {
    bytes32 hash = keccak256(byte(0x19), byte(0), this, nonce[identity], identity, "revokeAttribute", name, value); 
    revokeAttribute(identity, checkSignature(identity, sigV, sigR, sigS, hash), name, value);
  }

}