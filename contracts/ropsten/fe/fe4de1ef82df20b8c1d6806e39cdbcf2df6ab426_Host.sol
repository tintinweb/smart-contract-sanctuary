contract Ownable {
  address private _owner;


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
    _owner = msg.sender;
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
    emit OwnershipRenounced(_owner);
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

contract Host is Ownable {
    
    event HostUserUpdated(address indexed oldUser, address indexed newUser);
    event HostChecksumUpdated(address indexed user, bytes32 indexed oldChecksum, bytes32 indexed newChecksum);
    
    address private _user;
    bytes32 private _checksum;
    
    function getUser() public view returns(address) {
        return _user;
    }
    
    function getChecksum() public view returns(bytes32) {
        return _checksum;
    }
    
    function isUser() public view returns(bool) {
        return msg.sender == _user;
    }
    
    function hasBiometric() public view returns(bool) {
        return _checksum.length != 0;
    }
    
    function isChecksumValid(bytes32 checksum) public view returns(bool) {
        return _checksum == checksum;
    }
    
    function setUser(address user) public onlyOwner {
        emit HostUserUpdated(_user, user);
        _user = user;
    }
    
    function setChecksum(bytes32 checksum) public onlyOwner {
        emit HostChecksumUpdated(_user, _checksum, checksum);
        _checksum = checksum;
    }
    
}