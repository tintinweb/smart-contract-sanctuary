pragma solidity ^0.4.19;

// A 2/3 multisig contract which is compatible with Trezor-signed messages.
//
// To authorize a spend, two signtures must be provided by 2 of the 3 owners.
// To generate the message to be signed, provide the destination address and
// spend amount (in wei) to the generateMessageToSignmethod.
// The signatures must be provided as the (v, r, s) hex-encoded coordinates.
// The S coordinate must be 0x00 or 0x01 corresponding to 0x1b and 0x1c, respectively.
// See the test file for example inputs.
//
// If you use other software than the provided dApp or scripts to sign the message,
// verify that the message shown by the trezor device matches the generated message in hex.
//
// WARNING: The generated message is only valid until the next spend is executed.
//          after that, a new message will need to be calculated.
//
// WARNING: The signing algorithm Trezor uses is different than that
// of Ledger, Geth, Etc. This contract is for Trezor managed private
// keys ONLY.
//
// ADDITIONAL WARNING: This contract is **NOT** ERC20 compatible.
// Tokens sent to this contract will be lost forever.
//
contract TrezorMultiSig2of3 {

  // The 3 addresses which control the funds in this contract.  The
  // owners of 2 of these addresses will need to both sign a message
  // allowing the funds in this contract to be spent.
  mapping(address => bool) private owners;

  // The contract nonce is not accessible to the contract so we
  // implement a nonce-like variable for replay protection.
  uint256 public spendNonce = 0;

  // Contract Versioning
  uint256 public unchainedMultisigVersionMajor = 1;
  uint256 public unchainedMultisigVersionMinor = 0;   
  
  // An event sent when funds are received.
  event Funded(uint new_balance);
  
  // An event sent when a spend is triggered to the given address.
  event Spent(address to, uint transfer);

  // Instantiate a new Trezor Multisig 2 of 3 contract owned by the
  // three given addresses
  function TrezorMultiSig2of3(address owner1, address owner2, address owner3) public {
    address zeroAddress = 0x0;
    
    require(owner1 != zeroAddress);
    require(owner2 != zeroAddress);
    require(owner3 != zeroAddress);

    require(owner1 != owner2);
    require(owner2 != owner3);
    require(owner1 != owner3);
    
    owners[owner1] = true;
    owners[owner2] = true;
    owners[owner3] = true;
  }

  // The fallback function for this contract.
  function() public payable {
    Funded(this.balance);
  }

  // Generates the message to sign given the output destination address and amount.
  // includes this contract&#39;s address and a nonce for replay protection.
  // One option to  independently verify: https://leventozturk.com/engineering/sha3/ and select keccak
  function generateMessageToSign(address destination, uint256 value) public constant returns (bytes32) {
    require(destination != address(this));
    bytes32 message = keccak256(spendNonce, this, value, destination);
    return message;
  }
  
  // Send the given amount of ETH to the given destination using
  // the two triplets (v1, r1, s1) and (v2, r2, s2) as signatures.
  // s1 and s2 should be 0x00 or 0x01 corresponding to 0x1b and 0x1c respectively.
  function spend(address destination, uint256 value, uint8 v1, bytes32 r1, bytes32 s1, uint8 v2, bytes32 r2, bytes32 s2) public {
    // This require is handled by generateMessageToSign()
    // require(destination != address(this));
    require(this.balance >= value);
    require(_validSignature(destination, value, v1, r1, s1, v2, r2, s2));
    spendNonce = spendNonce + 1;
    destination.transfer(value);
    Spent(destination, value);
  }

  // Confirm that the two signature triplets (v1, r1, s1) and (v2, r2, s2)
  // both authorize a spend of this contract&#39;s funds to the given
  // destination address.
  function _validSignature(address destination, uint256 value, uint8 v1, bytes32 r1, bytes32 s1, uint8 v2, bytes32 r2, bytes32 s2) private constant returns (bool) {
    bytes32 message = _messageToRecover(destination, value);
    address addr1   = ecrecover(message, v1+27, r1, s1);
    address addr2   = ecrecover(message, v2+27, r2, s2);
    require(_distinctOwners(addr1, addr2));
    return true;
  }

  // Generate the the unsigned message (in bytes32) that each owner&#39;s
  // Trezor would have signed for the given destination and amount.
  //
  // The generated message from generateMessageToSign is converted to
  // ascii when signed by a trezor.
  //
  // The required Trezor signing prefix, the length of this
  // unsigned message, and the unsigned ascii message itself are
  // then concatenated and hashed with keccak256.
  function _messageToRecover(address destination, uint256 value) private constant returns (bytes32) {
    bytes32 hashedUnsignedMessage = generateMessageToSign(destination, value);
    bytes memory unsignedMessageBytes = _hashToAscii(hashedUnsignedMessage);
    bytes memory prefix = "\x19Ethereum Signed Message:\n";
    return keccak256(prefix,bytes1(unsignedMessageBytes.length),unsignedMessageBytes);
  }

  
  // Confirm the pair of addresses as two distinct owners of this contract.
  function _distinctOwners(address addr1, address addr2) private constant returns (bool) {
    // Check that both addresses are different
    require(addr1 != addr2);
    // Check that both addresses are owners
    require(owners[addr1]);
    require(owners[addr2]);
    return true;
  }


  // Construct the byte representation of the ascii-encoded
  // hashed message written in hex.
   function _hashToAscii(bytes32 hash) private pure returns (bytes) {
    bytes memory s = new bytes(64);
    for (uint i = 0; i < 32; i++) {
      byte b  = hash[i];
      byte hi = byte(uint8(b) / 16);
      byte lo = byte(uint8(b) - 16 * uint8(hi));
      s[2*i]   = _char(hi);
      s[2*i+1] = _char(lo);            
    }
    return s;    
  }
  
  // Convert from byte to ASCII of 0-f
  // http://www.unicode.org/charts/PDF/U0000.pdf
  function _char(byte b) private pure returns (byte c) {
    if (b < 10) return byte(uint8(b) + 0x30);
    else return byte(uint8(b) + 0x57);
  }
}