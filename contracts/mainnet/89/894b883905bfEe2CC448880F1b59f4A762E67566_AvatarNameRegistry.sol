/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

// File: zos-lib/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: openzeppelin-eth/contracts/ownership/Ownable.sol

pragma solidity ^0.5.2;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Initializable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
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
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

    uint256[50] private ______gap;
}

// File: contracts/AvatarNameStorage.sol

pragma solidity ^0.5.0;

contract ERC20Interface {
    function balanceOf(address from) public view returns (uint256);
    function transferFrom(address from, address to, uint tokens) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function burn(uint256 amount) public;
}

contract AvatarNameStorage {
    // Storage
    ERC20Interface public manaToken;
    uint256 public price;

    struct Data {
        string username;
        string metadata;
    }

    // Stores usernames used
    mapping (string => address) usernames;
    // Stores account data
    mapping (address => Data) public user;
    // Stores account roles
    mapping (address => bool) public allowed;

    // Events
    event Register(
        address indexed _owner,
        string _username,
        string _metadata,
        address indexed _caller
    );
    event MetadataChanged(address indexed _owner, string _metadata);
    event Allow(address indexed _caller, address indexed _account, bool _allowed);
}

// File: contracts/AvatarNameRegistry.sol

pragma solidity ^0.5.0;




contract AvatarNameRegistry is Ownable, AvatarNameStorage {

    /**
    * @dev Initializer of the contract
    * @param _mana - address of the mana token
    * @param _owner - address of the owner allowed to register usernames and assign the role
    */
    function initialize(
        ERC20Interface _mana,
        address _owner
    )
    public initializer
    {
        manaToken = _mana;
        price = 100000000000000000000; // 100 in wei

        // Allow owner to register usernames
        allowed[_owner] = true;

        // Owner
        Ownable.initialize(_owner);
    }

    /**
    * @dev Check if the sender is an allowed account
    */
    modifier onlyAllowed() {
        require(
            allowed[msg.sender] == true,
            "The sender is not allowed to register a username"
        );
        _;
    }

    /**
    * @dev Manage role for an account
    * @param _account - address of the account to be managed
    * @param _allowed - bool whether the account should be allowed or not
    */
    function setAllowed(address _account, bool _allowed) external onlyOwner {
        require(_account != msg.sender, "You can not manage your role");
        allowed[_account] = _allowed;
        emit Allow(msg.sender, _account, _allowed);
    }

    /**
    * @dev Register a usename
    * @notice that the username should be less than or equal 32 bytes and blanks are not allowed
    * @param _beneficiary - address of the account to be managed
    * @param _username - string for the username
    * @param _metadata - string for the metadata
    */
    function _registerUsername(
        address _beneficiary,
        string memory _username,
        string memory _metadata
    )
    internal
    {
        _requireBalance(_beneficiary);
        _requireUsernameValid(_username);
        require(isUsernameAvailable(_username), "The username was already taken");

        manaToken.transferFrom(_beneficiary, address(this), price);
        manaToken.burn(price);

        // Save username
        usernames[_username] = _beneficiary;

        Data storage data = user[_beneficiary];

        // Free previous username
        delete usernames[data.username];

        // Set data
        data.username = _username;

        bytes memory metadata = bytes(_metadata);
        if (metadata.length > 0) {
            data.metadata = _metadata;
        }

        emit Register(
            _beneficiary,
            _username,
            data.metadata,
            msg.sender
        );
    }

    /**
    * @dev Register a usename
    * @notice that the username can only be registered by an allowed account
    * @param _beneficiary - address of the account to be managed
    * @param _username - string for the username
    * @param _metadata - string for the metadata
    */
    function registerUsername(
        address _beneficiary,
        string calldata _username,
        string calldata _metadata
    )
    external
    onlyAllowed
    {
        _registerUsername(_beneficiary, _username, _metadata);
    }

    /**
    * @dev Set metadata for an existing user
    * @param _metadata - string for the metadata
    */
    function setMetadata(string calldata _metadata) external {
        require(userExists(msg.sender), "The user does not exist");

        user[msg.sender].metadata = _metadata;
        emit MetadataChanged(msg.sender, _metadata);
    }

    /**
    * @dev Check whether a user exist or not
    * @param _user - address for the user
    * @return bool - whether the user exist or not
    */
    function userExists(address _user) public view returns (bool) {
        Data memory data = user[_user];
        bytes memory username = bytes(data.username);
        return username.length > 0;
    }

    /**
    * @dev Check whether a username is available or not
    * @param _username - string for the username
    * @return bool - whether the username is available or not
    */
    function isUsernameAvailable(string memory _username) public view returns (bool) {
        return usernames[_username] == address(0);
    }

    /**
    * @dev Validate a username
    * @param _username - string for the username
    */
    function _requireUsernameValid(string memory _username) internal pure {
        bytes memory tempUsername = bytes(_username);
        require(tempUsername.length <= 15, "Username should be less than or equal 15 characters");
        for(uint256 i = 0; i < tempUsername.length; i++) {
            require(tempUsername[i] > 0x20, "Invalid Character");
        }
    }

    /**
    * @dev Validate if a user has balance and the contract has enough allowance
    * to use user MANA on his belhalf
    * @param _user - address of the user
    */
    function _requireBalance(address _user) internal view {
        require(
            manaToken.balanceOf(_user) >= price,
            "Insufficient funds"
        );
        require(
            manaToken.allowance(_user, address(this)) >= price,
            "The contract is not authorized to use MANA on sender behalf"
        );
    }
}