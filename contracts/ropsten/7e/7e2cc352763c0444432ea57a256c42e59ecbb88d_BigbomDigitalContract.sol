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
    uint expiredTimestamp;
  }
  // mapping document Id, BBODocument
  mapping(bytes32 => BBODocument) private bboDocuments;

  // mapping address, list of document Id
  mapping(address => bytes32[]) private userBBODocuments;

  // check the user is owner of his signature
  modifier userIsOwnerSign(bytes bboDocHash, bytes userSign){
  	require(toEthSignedMessageHashBytes(bboDocHash).recover(userSign) == msg.sender);
  	_;
  }

  // get BBODocument by docHash
  function verifyBBODocument(bytes _bboDocHash, bytes userSign) public view returns (bool) {
    bytes32 bboDocHash = fromBytesToBytes32(_bboDocHash);
  	BBODocument storage doc = bboDocuments[bboDocHash];
  	address userAddr = toEthSignedMessageHashBytes(_bboDocHash).recover(userSign);
  	return toEthSignedMessageHashBytes(_bboDocHash).recover(doc.signedAddresses[userAddr]) == toEthSignedMessageHashBytes(_bboDocHash).recover(userSign);
  }
  // create bboDocuments
  function createBBODocument(bytes32 bboDocHash, uint expiredTimestamp) private {
  	require(bboDocuments[bboDocHash].docHash != bboDocHash);
  	bboDocuments[bboDocHash].docHash = bboDocHash;
    bboDocuments[bboDocHash].expiredTimestamp = expiredTimestamp;
  }
  // TODO get list address & status by docHash
  function getAddressesByDocHash(bytes _bboDocHash) public view returns(address[], bool[]){
    bytes32 bboDocHash = fromBytesToBytes32(_bboDocHash);
    address[] memory addresses = bboDocuments[bboDocHash].addresses;
    bool[] memory status = new bool[](addresses.length);
    for(uint i=0;i<addresses.length;i++){
      status[i] = (keccak256(bboDocuments[bboDocHash].signedAddresses[addresses[i]])!=keccak256(&quot;&quot;));
    }
    return (addresses, status);
  }

  // TODO get list signed document of user
  function getDocuments(address user) public view returns(bytes32[], uint[]){
  	bytes32[] memory docHashes = userBBODocuments[user];
    uint[] memory expiredTimestamps = new uint[] (docHashes.length);
    for(uint i=0;i<docHashes.length;i++){
      expiredTimestamps[i] = bboDocuments[docHashes[i]].expiredTimestamp;
    }
    return (docHashes, expiredTimestamps);
  }

  // Convert an hexadecimal character to their value
  function fromHexChar(uint c) internal pure returns (uint) {
      if (byte(c) >= byte(&#39;0&#39;) && byte(c) <= byte(&#39;9&#39;)) {
          return c - uint(byte(&#39;0&#39;));
      }
      if (byte(c) >= byte(&#39;a&#39;) && byte(c) <= byte(&#39;f&#39;)) {
          return 10 + c - uint(byte(&#39;a&#39;));
      }
      if (byte(c) >= byte(&#39;A&#39;) && byte(c) <= byte(&#39;F&#39;)) {
          return 10 + c - uint(byte(&#39;A&#39;));
      }
  }
  // Convert an hexadecimal string to raw bytes
  function fromBytesToBytes32(bytes s) internal pure returns (bytes32 result) {
      bytes memory ss = bytes(s);
      require(ss.length%2 == 0); // length must be even
      bytes memory r = new bytes(ss.length/2);
      for (uint i=0; i<ss.length/2; ++i) {
          r[i] = byte(fromHexChar(uint(ss[2*i])) * 16 +
                      fromHexChar(uint(ss[2*i+1])));
      }
      assembly {
        result := mload(add(r, 32))
      }
  }

  //
  function toEthSignedMessageHashBytes(bytes hash)
    internal
    pure
    returns (bytes32)
  {
    // 64 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      abi.encodePacked(&quot;\x19Ethereum Signed Message:\n64&quot;, hash)
    );
  }

  
  // user Sign The Document
  event BBODocumentSigned(bytes32 bboDocHash, address indexed user);
  function createAndSignBBODocument(bytes _bboDocHash, bytes userSign, address[] pendingAddresses, uint expiredTimestamp) public 
   userIsOwnerSign(_bboDocHash, userSign)
   {
     bytes32 bboDocHash = fromBytesToBytes32(_bboDocHash);
     // expiredTimestamp must > now
     require(expiredTimestamp > now);
     // docHash not existing
  	 require(bboDocuments[bboDocHash].docHash != bboDocHash);
     // list pendingAddresses 
     require(pendingAddresses.length > 0);
  	 
     bool pendingAddressesIsValid = false;
     for(uint i=0;i<pendingAddresses.length;i++){
       if(msg.sender!=pendingAddresses[i]){
        // add docHash to Pending sign address
        userBBODocuments[pendingAddresses[i]].push(bboDocHash);
        bboDocuments[bboDocHash].addresses.push(pendingAddresses[i]);
        pendingAddressesIsValid = true;
       }
     }
  	 
     require(pendingAddressesIsValid==true);
     createBBODocument(bboDocHash, expiredTimestamp);
     bboDocuments[bboDocHash].signedAddresses[msg.sender] = userSign;
     bboDocuments[bboDocHash].addresses.push(msg.sender);
     userBBODocuments[msg.sender].push(bboDocHash);     
     emit BBODocumentSigned(bboDocHash, msg.sender);
  }

  function signBBODocument(bytes _bboDocHash, bytes userSign)public 
   userIsOwnerSign(_bboDocHash, userSign)
   {
     bytes32 bboDocHash = fromBytesToBytes32(_bboDocHash);
     require(bboDocuments[bboDocHash].docHash == bboDocHash);
     require(keccak256(bboDocuments[bboDocHash].signedAddresses[msg.sender])!=keccak256(userSign));
     require(bboDocuments[bboDocHash].expiredTimestamp > now);
     bool userHasDocHash = false;
     for(uint i=0;i<userBBODocuments[msg.sender].length;i++){
      if(userBBODocuments[msg.sender][i] == bboDocHash){
        userHasDocHash = true;
      }
     }
     require(userHasDocHash==true);
     bboDocuments[bboDocHash].signedAddresses[msg.sender] = userSign;
     emit BBODocumentSigned(bboDocHash, msg.sender);
  }

}