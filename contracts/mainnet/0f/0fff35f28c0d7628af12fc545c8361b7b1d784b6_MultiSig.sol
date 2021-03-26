/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity >=0.8;

import "./Address.sol";
import "./RLPEncode.sol";
import "./Nonce.sol";

contract MultiSig is Nonce {

  mapping (address => uint8) public signers; // The addresses that can co-sign transactions and the number of signatures needed

  uint16 public signerCount;
  bytes public contractId; // most likely unique id of this contract

  event SignerChange(
    address indexed signer,
    uint8 cosignaturesNeeded
  );

  event Transacted(
    address indexed toAddress,  // The address the transaction was sent to
    bytes4 selector, // selected operation
    address[] signers // Addresses of the signers used to initiate the transaction
  );

  constructor (address owner) {
    // We use the gas price to get a unique id into our transactions.
    // Note that 32 bits do not guarantee that no one can generate a contract with the
    // same id, but it practically rules out that someone accidentally creates two
    // two multisig contracts with the same id, and that's all we need to prevent
    // replay-attacks.
    contractId = toBytes(uint32(uint160(address(this))));
    _setSigner(owner, 1); // set initial owner
  }

  /**
   * It should be possible to store ether on this address.
   */
  receive() external payable {
  }

  /**
   * Checks if the provided signatures suffice to sign the transaction and if the nonce is correct.
   */
  function checkSignatures(uint128 nonce, address to, uint value, bytes calldata data,
    uint8[] calldata v, bytes32[] calldata r, bytes32[] calldata s) public view returns (address[] memory) {
    bytes32 transactionHash = calculateTransactionHash(nonce, contractId, to, value, data);
    return verifySignatures(transactionHash, v, r, s);
  }

  /**
   * Checks if the execution of a transaction would succeed if it was properly signed.
   */
  function checkExecution(address to, uint value, bytes calldata data) public {
    Address.functionCallWithValue(to, data, value);
    require(false, "Test passed. Reverting.");
  }

  function execute(uint128 nonce, address to, uint value, bytes calldata data, uint8[] calldata v, bytes32[] calldata r, bytes32[] calldata s) public returns (bytes memory) {
    bytes32 transactionHash = calculateTransactionHash(nonce, contractId, to, value, data);
    address[] memory found = verifySignatures(transactionHash, v, r, s);
    bytes memory returndata = Address.functionCallWithValue(to, data, value);
    flagUsed(nonce);
    emit Transacted(to, extractSelector(data), found);
    return returndata;
  }

  function extractSelector(bytes calldata data) private pure returns (bytes4){
    if (data.length < 4){
      return bytes4(0);
    } else {
      return bytes4(data[0]) | (bytes4(data[1]) >> 8) | (bytes4(data[2]) >> 16) | (bytes4(data[3]) >> 24);
    }
  }

  function toBytes(uint number) internal pure returns (bytes memory){
    uint len = 0;
    uint temp = 1;
    while (number >= temp){
      temp = temp << 8;
      len++;
    }
    temp = number;
    bytes memory data = new bytes(len);
    for (uint i = len; i>0; i--) {
      data[i-1] = bytes1(uint8(temp));
      temp = temp >> 8;
    }
    return data;
  }

  // Note: does not work with contract creation
  function calculateTransactionHash(uint128 sequence, bytes memory id, address to, uint value, bytes calldata data)
    internal view returns (bytes32){
    bytes[] memory all = new bytes[](9);
    all[0] = toBytes(sequence); // sequence number instead of nonce
    all[1] = id; // contract id instead of gas price
    all[2] = toBytes(21000); // gas limit
    all[3] = abi.encodePacked(to);
    all[4] = toBytes(value);
    all[5] = data;
    all[6] = toBytes(block.chainid);
    all[7] = toBytes(0);
    for (uint i = 0; i<8; i++){
      all[i] = RLPEncode.encodeBytes(all[i]);
    }
    all[8] = all[7];
    return keccak256(RLPEncode.encodeList(all));
  }

  function verifySignatures(bytes32 transactionHash, uint8[] calldata v, bytes32[] calldata r, bytes32[] calldata s)
    public view returns (address[] memory) {
    address[] memory found = new address[](r.length);
    for (uint i = 0; i < r.length; i++) {
      address signer = ecrecover(transactionHash, v[i], r[i], s[i]);
      uint8 cosignaturesNeeded = signers[signer];
      require(cosignaturesNeeded > 0 && cosignaturesNeeded <= r.length, "cosigner error");
      found[i] = signer;
    }
    requireNoDuplicates(found);
    return found;
  }

  function requireNoDuplicates(address[] memory found) private pure {
    for (uint i = 0; i < found.length; i++) {
      for (uint j = i+1; j < found.length; j++) {
        require(found[i] != found[j], "duplicate signature");
      }
    }
  }

  /**
   * Call this method through execute
   */
  function setSigner(address signer, uint8 cosignaturesNeeded) public authorized {
    _setSigner(signer, cosignaturesNeeded);
    require(signerCount > 0);
  }

  function migrate(address destination) public {
    _migrate(msg.sender, destination);
  }

  function migrate(address source, address destination) public authorized {
    _migrate(source, destination);
  }

  function _migrate(address source, address destination) private {
    require(signers[destination] == 0); // do not overwrite existing signer!
    _setSigner(destination, signers[source]);
    _setSigner(source, 0);
  }

  function _setSigner(address signer, uint8 cosignaturesNeeded) private {
    require(!Address.isContract(signer), "signer cannot be a contract");
    uint8 prevValue = signers[signer];
    signers[signer] = cosignaturesNeeded;
    if (prevValue > 0 && cosignaturesNeeded == 0){
      signerCount--;
    } else if (prevValue == 0 && cosignaturesNeeded > 0){
      signerCount++;
    }
    emit SignerChange(signer, cosignaturesNeeded);
  }

  modifier authorized() {
    require(address(this) == msg.sender || signers[msg.sender] == 1, "not authorized");
    _;
  }

}