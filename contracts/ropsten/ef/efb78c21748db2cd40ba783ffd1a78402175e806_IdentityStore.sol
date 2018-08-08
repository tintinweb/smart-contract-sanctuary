pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
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

contract IdentityStore is Ownable {
  
    struct User {
        bytes32 tenantHash;
        uint256 timestamp;
        string tenantId;
    }

    mapping(address => User) private tenantAddressMapping;
    mapping(bytes32 => address) private tenantHashMapping; 

    function setTenant(
        bytes32 _tenantHash,
        address _userAddress,
        uint256 _timestamp,
        string _tenantId) onlyOwner public {

        // Completely new user
        if (!userAddressExists(_userAddress) && !userTenantHashExists(_tenantHash)) {
            
            User memory newUser = User(_tenantHash, _timestamp, _tenantId);
            tenantAddressMapping[_userAddress] = newUser;
            tenantHashMapping[_tenantHash] = _userAddress;
            return;
        }

        // Update user hash.
        if (userAddressExists(_userAddress) && !userTenantHashExists(_tenantHash)) {
            
            bytes32 oldHash = tenantAddressMapping[_userAddress].tenantHash;
            updateHash(oldHash, _tenantHash, _timestamp);
            return;
        }
        
        // Update user address.
        if (userTenantHashExists(_tenantHash) && !userAddressExists(_userAddress)) {
            address oldAddress = tenantHashMapping[_tenantHash];
            updateAddress(oldAddress, _userAddress);
            return;
        }
        
        // Update timestamp
        if (userTenantHashExists(_tenantHash) && userAddressExists(_userAddress)) {
            updateTimestamp(_tenantHash, _timestamp);
            return;
        }
    }

    function isValid(
        string _tenantId, 
        address _userAddress,
        uint256 _minTimestamp) view public returns(bool) {

        // check valid address
        if(!userAddressExists(_userAddress)) {
            return false;
        }

        User memory currentUser = tenantAddressMapping[_userAddress];

        // check valid tenant id
        if(keccak256(currentUser.tenantId) != keccak256(_tenantId)) {
            return false;
        }
        
        // check minimum timestamp
        if(currentUser.timestamp < _minTimestamp) {
            return false;
        }

        return true;
    }

    function getUserTenantId(
        address _userAddress) view public returns(string) {
        require(userAddressExists(_userAddress), "There&#39;s no account tied to the address");
        return tenantAddressMapping[_userAddress].tenantId;
    }

    function updateHash(
        bytes32 _oldHash, 
        bytes32 _newHash, 
        uint256 _timestamp) internal {

        require(userTenantHashExists(_oldHash), "Old hash does not exist.");
        require(!userTenantHashExists(_newHash), "New hash is already registered.");
        address currentAddress = tenantHashMapping[_oldHash];
        User memory oldUserInfo = tenantAddressMapping[currentAddress];
        User memory newUserInfo = User(_newHash, _timestamp, oldUserInfo.tenantId);

        // update address mapping to user
        tenantAddressMapping[currentAddress] = newUserInfo;

        // delete old hash mapping to address
        delete tenantHashMapping[_oldHash];

        // add new hash mapping to address
        tenantHashMapping[_newHash] = currentAddress;
    }

    function updateAddress(address oldUserAddress, address newUserAddress) onlyOwner internal {
        User memory existingUser = tenantAddressMapping[oldUserAddress];
        
        require(!userAddressExists(newUserAddress), "There&#39;s already an account tied to this address");
        require(userAddressExists(oldUserAddress), "There&#39;s no account tied to the address origin");

        tenantHashMapping[existingUser.tenantHash] = newUserAddress;
        tenantAddressMapping[newUserAddress] = existingUser;
        delete tenantAddressMapping[oldUserAddress];
    }

    function updateTimestamp(bytes32 _tenantHash, uint256 _timestamp) onlyOwner internal {
        tenantAddressMapping[tenantHashMapping[_tenantHash]].timestamp = _timestamp;
    }

    function userAddressExists(address userAddress) view internal returns(bool) {       
        if(tenantAddressMapping[userAddress].tenantHash == 0) {
            return false;
        }
        return true;
    }

    function userTenantHashExists(bytes32 tenantHash) view internal returns(bool){
        // pray it be who can find the 0X Address
        if(tenantHashMapping[tenantHash] == 0) {
            return false;
        }
        return true;
    }
}