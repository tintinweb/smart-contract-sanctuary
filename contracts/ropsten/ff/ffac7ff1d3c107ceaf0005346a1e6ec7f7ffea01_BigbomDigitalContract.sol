pragma solidity ^0.4.4;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title Eliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with &quot;\x19Ethereum Signed Message:&quot;
   * and hash the result
   */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      abi.encodePacked(&quot;\x19Ethereum Signed Message:\n32&quot;, hash)
    );
  }
}

contract BigbomDigitalContract is Ownable {
  using ECRecovery for bytes32;
  // BBODocument Struct
  struct BBODocument{
  	bytes32 docHash; //document Hash 
  	address[] addresses;
  	mapping(address => bytes) signedAddresses; // mapping address, userSign
  }

  // mapping document Id, BBODocument
  mapping(bytes32 => BBODocument) private bboDocuments;

  // mapping address, list of document Id
  mapping(address => bytes32[]) private userBBODocuments;

  // check the user is owner of his signature
  modifier userIsOwnerSign(bytes _bboDocHash, bytes userSign){
  	bytes32 bboDocHash = keccak256(_bboDocHash);
  	require(bboDocHash.toEthSignedMessageHash().recover(userSign) == msg.sender);
  	_;
  }

  // get BBODocument by docHash
  function verifyBBODocument(bytes _bboDocHash, bytes userSign) public view returns (bool) {
  	require(bboDocHash.length == 32);
  	bytes32 bboDocHash = keccak256(_bboDocHash);
  	BBODocument storage doc = bboDocuments[bboDocHash];
  	address userAddr = bboDocHash.toEthSignedMessageHash().recover(userSign);
  	return keccak256(doc.signedAddresses[userAddr]) == keccak256(userSign);
  }
  // create bboDocuments
  function createBBODocument(bytes32 bboDocHash) private {
  	require(bboDocuments[bboDocHash].docHash != bboDocHash);
  	bboDocuments[bboDocHash].docHash = bboDocHash;
  }
  // get list address by docHash
  function getUsersByDocHash(bytes _bboDocHash) public view onlyOwner returns(address[] userSigneds){
  	bytes32 bboDocHash = keccak256(_bboDocHash);
    userSigneds = bboDocuments[bboDocHash].addresses;
  }

  // get list signed document of user
  function getUserSignedDocuments() public view returns(bytes32[] docHashes){
  	require (msg.sender!= address(0x0));
  	docHashes = userBBODocuments[msg.sender];
  }

  // user Sign The Document
  event BBODocumentSigned(bytes32 bboDocHash, address indexed user);
  function signBBODocument(bytes _bboDocHash, bytes userSign) public 
   userIsOwnerSign(_bboDocHash, userSign)
   {
   	 bytes32 bboDocHash = keccak256(_bboDocHash);
  	 if(bboDocuments[bboDocHash].docHash == bboDocHash){
  	 	// check user not sign this document yet
  	 	require(keccak256(bboDocuments[bboDocHash].signedAddresses[msg.sender])!=keccak256(userSign));
  	 }else{
  	 	createBBODocument(bboDocHash);
  	 }
  	 bboDocuments[bboDocHash].signedAddresses[msg.sender] = userSign;
  	 bboDocuments[bboDocHash].addresses.push(msg.sender);
  	 userBBODocuments[msg.sender].push(bboDocHash);
  	 emit BBODocumentSigned(bboDocHash, msg.sender);
  }

}