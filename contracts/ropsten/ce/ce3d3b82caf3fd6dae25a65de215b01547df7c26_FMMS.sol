contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
contract FMMS is Ownable {
    
    /**
     * Storage Struct to store user data 
    */
    struct fmmsData{
        address modifyingAddress;
        address userAddress;
        bytes32 dataHash;
        uint256 dataType;
        uint256 currentBlock;
    }
    
    mapping(bytes32 => fmmsData) private fmmsDetail; //Mapping unique id to the Data
    mapping(address => bool) public whitelist;  // map to whitelist a participant 

    bytes32[] private fmmsDetails;
    
    
    /**
     * @dev verifies the signature of the user and saves hash of the user data in contract storage 
     * @param _dataType is the type of fmms data 
     * @param _msgHash is the hash of the user data object
     * @param _v _r, _s is the signature of the user 
     * @param _uniqueId is the id of the data (Eg: IC number)
     * @param _userAddress is the address of the user 
     * 
    */
    function saveData(uint256 _dataType, bytes32 _msgHash, uint8 _v, bytes32 _r, bytes32 _s, bytes32 _uniqueId, address _userAddress, address _modifierAddress) external onlyOwner returns (bool) {
        
        address modifyingAddress = ecrecover(_msgHash, _v, _r, _s);

        if(_dataType == 1) {
            require(modifyingAddress == _userAddress , "The signature should be user signature");
        }else {
            require(whitelist[_modifierAddress] == true, "account is not whitelisted");
            require(modifyingAddress == _modifierAddress , "The signature should be signed by the whitelisted account");
        }

        _saveData(modifyingAddress, _uniqueId, _userAddress, _msgHash, _dataType);
        
        return true;
    }
    
    ///  @dev Function to whitelist modifiers 
    ///  @param _modifier_addresses Array of addresses to whitelist
    function addToWhitelist(address[] _modifier_addresses) external onlyOwner {
        for (uint32 i = 0; i < _modifier_addresses.length; i++) {
            if(_modifier_addresses[i] != address(0) && whitelist[_modifier_addresses[i]] == false){
                whitelist[_modifier_addresses[i]] = true;
            }
        }
    }

    ///  @dev Function to remove the whitelististed participants
    ///  @param _modifier_addresses is an array of accounts to remove form the whitelist
    function removeFromWhitelist(address[] _modifier_addresses) external onlyOwner {
        for (uint32 i = 0; i < _modifier_addresses.length; i++) {
            if(_modifier_addresses[i] != address(0) && whitelist[_modifier_addresses[i]] == true){
                whitelist[_modifier_addresses[i]] = false;
            }
        }
    }

    /**
     * @dev internal function to save user&#39;s data
    */
    function _saveData(address _modifyingAddress,bytes32 _uniqueId, address _userAddress,bytes32 _dataHash, uint256 _dataType) internal{
       
        fmmsData storage user = fmmsDetail[_uniqueId];
        
        user.modifyingAddress = _modifyingAddress;
        user.userAddress = _userAddress;
        user.dataHash = _dataHash;
        user.dataType = _dataType;
        user.currentBlock = block.number;
        
        fmmsDetails.push(_uniqueId)-1;
        
    }

    /**
     * @dev returns the user details by address 
    */
    function getFmmsDetail(bytes32 _uniqueId)public view returns(address, address, bytes32 ,uint256) {
        return (fmmsDetail[_uniqueId].modifyingAddress, fmmsDetail[_uniqueId].userAddress ,fmmsDetail[_uniqueId].dataHash,fmmsDetail[_uniqueId].currentBlock);
    }
    
}