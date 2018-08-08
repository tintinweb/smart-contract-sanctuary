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

    function isValidTenant(
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

    function isValid(address _userAddress, uint256 _minTimestamp) view public returns(bool) {

        // check valid address
        if(!userAddressExists(_userAddress)) {
            return false;
        }

        User memory currentUser = tenantAddressMapping[_userAddress];

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

contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract CorpCoin is EIP20Interface {
    
    IdentityStore idStore;
    uint256 expiration = 30 days;
    uint numberOfCoins = 4;
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    mapping (address => bool) private coinAllocated;

    function CorpCoin(address addr, uint256 _initialAmount) public {
        idStore = IdentityStore(addr);
        balances[msg.sender] = _initialAmount;
        totalSupply = _initialAmount;
    }

    function InitializeCoinToUser(address _to) public {
        require(coinAllocated[_to] == false);
        require(idStore.isValid(_to, 0), "User not valid for transfer");
        if( totalSupply - numberOfCoins >= 0) {
            balances[_to] += numberOfCoins;
            totalSupply -= numberOfCoins;
            coinAllocated[_to] = true;
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        require(idStore.isValid(_to, 0), "User not valid for transfer");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); 
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); 
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); 
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}