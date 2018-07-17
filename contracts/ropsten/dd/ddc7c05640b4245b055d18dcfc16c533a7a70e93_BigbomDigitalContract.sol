pragma solidity ^0.4.24;

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
    // modify by chris to make sure the proxy contract can set the first owner
    require(msg.sender == owner);
    _;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwnerProxyCall() {
    // modify by chris to make sure the proxy contract can set the first owner
    if(owner!=address(0)){
      require(msg.sender == owner);
    }
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
  function transferOwnership(address _newOwner) public onlyOwnerProxyCall {
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

contract BBStorage is Ownable {


    /**** Storage Types *******/

    mapping(bytes32 => uint256)    private uIntStorage;
    mapping(bytes32 => string)     private stringStorage;
    mapping(bytes32 => address)    private addressStorage;
    mapping(bytes32 => bytes)      private bytesStorage;
    mapping(bytes32 => bool)       private boolStorage;
    mapping(bytes32 => int256)     private intStorage;
    mapping(bytes32 => bool)       private admins;


    /*** Modifiers ************/
   
    /// @dev Only allow access from the latest version of a contract in the network after deployment
    modifier onlyAdminStorage() {
        // // The owner is only allowed to set the storage upon deployment to register the initial contracts, afterwards their direct access is disabled
        require(admins[keccak256(abi.encodePacked(&#39;admin:&#39;,msg.sender))] == true);
        _;
    }

    function addAdmin(address adm) public onlyOwner {
        require(adm!=address(0x0));
        require(admins[keccak256(abi.encodePacked(&#39;admin:&#39;,adm))]!=true);

        admins[keccak256(abi.encodePacked(&#39;admin:&#39;,adm))] = true;
    }
    function removeAdmin(address adm) public onlyOwner {
        require(adm!=address(0x0));
        require(admins[keccak256(abi.encodePacked(&#39;admin:&#39;,adm))]==true);

        admins[keccak256(abi.encodePacked(&#39;admin:&#39;,adm))] = false;
    }

    /**** Get Methods ***********/

    /// @param _key The key for the record
    function getAddress(bytes32 _key) external view returns (address) {
        return addressStorage[_key];
    }

    /// @param _key The key for the record
    function getUint(bytes32 _key) external view returns (uint) {
        return uIntStorage[_key];
    }

    /// @param _key The key for the record
    function getString(bytes32 _key) external view returns (string) {
        return stringStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes(bytes32 _key) external view returns (bytes) {
        return bytesStorage[_key];
    }

    /// @param _key The key for the record
    function getBool(bytes32 _key) external view returns (bool) {
        return boolStorage[_key];
    }

    /// @param _key The key for the record
    function getInt(bytes32 _key) external view returns (int) {
        return intStorage[_key];
    }


    /**** Set Methods ***********/


    /// @param _key The key for the record
    function setAddress(bytes32 _key, address _value) onlyAdminStorage external {
        addressStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setUint(bytes32 _key, uint _value) onlyAdminStorage external {
        uIntStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setString(bytes32 _key, string _value) onlyAdminStorage external {
        stringStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes(bytes32 _key, bytes _value) onlyAdminStorage external {
        bytesStorage[_key] = _value;
    }
    
    /// @param _key The key for the record
    function setBool(bytes32 _key, bool _value) onlyAdminStorage external {
        boolStorage[_key] = _value;
    }
    
    /// @param _key The key for the record
    function setInt(bytes32 _key, int _value) onlyAdminStorage external {
        intStorage[_key] = _value;
    }


    /**** Delete Methods ***********/
    
    /// @param _key The key for the record
    function deleteAddress(bytes32 _key) onlyAdminStorage external {
        delete addressStorage[_key];
    }

    /// @param _key The key for the record
    function deleteUint(bytes32 _key) onlyAdminStorage external {
        delete uIntStorage[_key];
    }

    /// @param _key The key for the record
    function deleteString(bytes32 _key) onlyAdminStorage external {
        delete stringStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes(bytes32 _key) onlyAdminStorage external {
        delete bytesStorage[_key];
    }
    
    /// @param _key The key for the record
    function deleteBool(bytes32 _key) onlyAdminStorage external {
        delete boolStorage[_key];
    }
    
    /// @param _key The key for the record
    function deleteInt(bytes32 _key) onlyAdminStorage external {
        delete intStorage[_key];
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
  function toEthSignedMessageHashBytes(bytes hash)
    internal
    pure
    returns (bytes32)
  {
    // 64 is the length in bytes of hash,
    // enforced by the type signature above

    return keccak256(
      abi.encodePacked(&quot;\x19Ethereum Signed Message:\n&quot;, uint2str(hash.length), hash)
    );
  }

  function uint2str(uint i) internal pure returns (string){
    if (i == 0) return &quot;0&quot;;
    uint j = i;
    uint length;
    while (j != 0){
        length++;
        j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint k = length - 1;
    while (i != 0){
        bstr[k--] = byte(48 + i % 10);
        i /= 10;
    }
    return string(bstr);
  }
}

contract BigbomDigitalContract is Ownable {
  using ECRecovery for *;
  BBStorage bbs = BBStorage(0x0);
  function setStorage(address storageAddress) onlyOwner public {
    bbs = BBStorage(storageAddress);
  }
event Debug(address addr);
  function getStorage() public returns(address){
  emit Debug(msg.sender);
    emit Debug(owner);
    return bbs;
  }
  // check the user is owner of his signature
  modifier userIsOwnerSign(bytes bboDocHash, bytes userSign){
  	require(bboDocHash.toEthSignedMessageHashBytes().recover(userSign) == msg.sender);
  	_;
  }

  // get BBODocument by docHash
  function verifyBBODocument(bytes bboDocHash, bytes userSign) public view returns (bool) {
  	address userAddr = bboDocHash.toEthSignedMessageHashBytes().recover(userSign);
  	return keccak256(bbs.getBytes(keccak256(abi.encodePacked(bboDocHash,&#39;signature&#39;, userAddr))))==keccak256(userSign);
  }

  // get list address & status by docHash
  function getAddressesByDocHash(bytes bboDocHash) public view returns(address[], bool[]){

    uint docNum = bbs.getUint(keccak256(abi.encodePacked(bboDocHash)));
    address[] memory addresses = new address[](docNum);
    bool[] memory status = new bool[](docNum);
    for(uint i=0;i<docNum;i++){
      if(i==0)
      addresses[i] = bbs.getAddress(keccak256(abi.encodePacked(bboDocHash,&#39;address&#39;)));
      else
      addresses[i] = bbs.getAddress(keccak256(abi.encodePacked(bboDocHash,&#39;address&#39;, i)));

      status[i] = (keccak256(bbs.getBytes(keccak256(abi.encodePacked(bboDocHash,&#39;signature&#39;, addresses[i]))))!=keccak256(&quot;&quot;));
    }
    return (addresses, status);
  }
  
  
  //get list signed document of user
  function getDocuments(address addr) public view returns(bytes, uint[]){
    // get number of doc already
    bytes memory docReturn = &#39;&#39;;
    uint256 docNumber = bbs.getUint(keccak256(abi.encodePacked(addr)));
    uint[] memory expiredTimestamps = new uint[] (docNumber);
    for(uint256 i=1;i<=docNumber;i++){
     bytes memory dochash = bbs.getBytes(keccak256(abi.encodePacked(addr, i)));
     docReturn = abi.encodePacked(docReturn, abi.encodePacked(dochash,&#39;,&#39;));
     expiredTimestamps[i-1]=bbs.getUint(keccak256(abi.encodePacked(dochash, &#39;expiredTimestamp&#39;)));
    }
    return (docReturn, expiredTimestamps);
  }
  
  // user Sign The Document
  event BBODocumentSigned(bytes bboDocHash, address indexed user);
  function createAndSignBBODocument(bytes bboDocHash, bytes userSign, address[] pendingAddresses, uint expiredTimestamp) public 
   userIsOwnerSign(bboDocHash, userSign)
   {
     // expiredTimestamp must > now
     require(expiredTimestamp > now);
     // docHash not existing
  	 require(bbs.getUint(keccak256(abi.encodePacked(bboDocHash))) == 0x0);

     // list pendingAddresses 
     require(pendingAddresses.length > 0);
  	 

     //new storage implements
     // save number user of this docs
     bbs.setUint(keccak256(abi.encodePacked(bboDocHash)), pendingAddresses.length + 1);
     // set time
     bbs.setUint(keccak256(abi.encodePacked(bboDocHash, &#39;expiredTimestamp&#39;)), expiredTimestamp);
     // save first address is owner of the docs
     bbs.setAddress(keccak256(abi.encodePacked(bboDocHash,&#39;address&#39;)), msg.sender);
     // save owner sign
     bbs.setBytes(keccak256(abi.encodePacked(bboDocHash,&#39;signature&#39;, msg.sender)), userSign);
     // todo save bboDocHash to user address
     setDocToAddress(msg.sender, bboDocHash);

     bool pendingAddressesIsValid = true;

     // loop & save in pendingAddresses 
     for(uint i=0;i<pendingAddresses.length;i++){
        if(msg.sender==pendingAddresses[i]){
         pendingAddressesIsValid = false;
         require(pendingAddressesIsValid==true);
        }
        bbs.setAddress(keccak256(abi.encodePacked(bboDocHash, &#39;address&#39;, i+1)), pendingAddresses[i]);
        // save bboDocHash to user address
        setDocToAddress(pendingAddresses[i], bboDocHash);

     }
     emit BBODocumentSigned(bboDocHash, msg.sender);
     
  }

  function setDocToAddress(address adr, bytes docHash) internal {
    // get number of doc already
     uint256 docNumber = bbs.getUint(keccak256(abi.encodePacked(adr)));
     docNumber++;
     // incres 1
     bbs.setUint(keccak256(abi.encodePacked(adr)), docNumber);
     // set doc hash
     bbs.setBytes(keccak256(abi.encodePacked(adr, docNumber)), docHash);
  }

  function signBBODocument(bytes bboDocHash, bytes userSign)public 
   userIsOwnerSign(bboDocHash, userSign)
   {
     // check already docHash
     require(bbs.getUint(keccak256(abi.encodePacked(bboDocHash)))!=0x0);
     // check already sign
     require(keccak256(bbs.getBytes(keccak256(abi.encodePacked(bboDocHash,&#39;signature&#39;, msg.sender))))!=keccak256(userSign));
     // check expired 
     require(bbs.getUint(keccak256(abi.encodePacked(bboDocHash, &#39;expiredTimestamp&#39;))) > now);
     // save signature
     bbs.setBytes(keccak256(abi.encodePacked(bboDocHash,&#39;signature&#39;, msg.sender)), userSign);
     emit BBODocumentSigned(bboDocHash, msg.sender);
  }

}