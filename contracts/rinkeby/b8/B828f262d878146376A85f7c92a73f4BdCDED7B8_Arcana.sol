// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Arcana is OwnableUpgradeable {
    mapping(bytes32 => address) public owners; // file owners
    // file id => access type => user => validity
    mapping(bytes32 => mapping(bytes32 => mapping(address => uint256))) public accessSpecifier;
    // It is used to get all users of a particular type with particular access
    mapping(bytes32 => mapping(bytes32 => address[])) public userAccess;
    mapping(bytes32 => File) public files;
    mapping(bytes32 => bool) public isDeleted;
    mapping(address => bool) public isNode;

    struct File {
        uint256 n;
        uint256 k;
        uint256 fileSize;
    }

    modifier onlyFileOwner(bytes32 _file) {
        require(msg.sender == owners[_file], "This function can only be called by file owner");
        _;
    }

    event NewFileUpdate(address indexed identity, bytes32 indexed file, uint256 n, uint256 k, uint256 fileSize);

    event NewDownload(address indexed identity, bytes32 indexed file, uint256 validity, bytes32 accessType);

    event DeleteFileEvent(address indexed identity, bytes32 indexed file);

    event NewShare(
        address indexed identity,
        bytes32 indexed file,
        address indexed user,
        bytes32 accessType,
        uint256 validity
    );

    event NewUpdateACK(address indexed identity, bytes32 indexed file, address indexed user, bytes32 accessType);

    function initialize() public initializer {
        OwnableUpgradeable.__Ownable_init();
    }

    function createDID(
        bytes32 _file,
        uint256 n,
        uint256 k,
        uint256 _fileSize
    ) public {
        require(owners[_file] == address(0), "Owner already exist for this file");
        require(n > k, "n>k");
        require(k > 1, "k should not be 0");
        require(_fileSize != 0, "Should not be 0");
        owners[_file] = msg.sender;
        files[_file] = File(n, k, _fileSize);
        isDeleted[_file] = false;
        emit NewFileUpdate(owners[_file], _file, n, k, _fileSize);
    }

    function download(
        address _identity,
        bytes32 _file,
        bytes32 _accessType
    ) public returns (uint256) {
        uint256 validity = accessSpecifier[_file][_accessType][_identity];
        if (_identity == owners[_file]) {
            validity = block.timestamp + 1000000;
        } else {
            require(validity != uint256(0), "Validity is 0");
        }
        emit NewDownload(_identity, _file, validity, _accessType);
        return validity;
    }

    function share(
        bytes32[] memory _files,
        address[] memory _user,
        bytes32[] memory _accessType,
        uint256[] memory _validity
    ) public {
        require(_user.length == _accessType.length, "User array length does not matches with access type length");
        require(_user.length == _validity.length, "User array length does not matches with validity length");
        for (uint256 j = 0; j < _files.length; j++) {
            for (uint256 i = 0; i < _user.length; i++) {
                require(msg.sender == owners[_files[i]], "Not file owner");
                require(_validity[i] != 0, "Validity must be non zero");
                accessSpecifier[_files[j]][_accessType[i]][_user[i]] = block.timestamp + _validity[i];
                userAccess[_files[j]][_accessType[i]].push(_user[i]);
                emit NewShare(msg.sender, _files[j], _user[i], _accessType[i], _validity[i]);
            }
        }
    }

    function deleteFileSigned(bytes32 _file) public onlyFileOwner(_file) {
        delete owners[_file];
        emit DeleteFileEvent(msg.sender, _file);
    }

    function getAllUsers(bytes32 _file, bytes32 _accessType) public view returns (address[] memory) {
        address[] memory users = userAccess[_file][_accessType];
        address user;
        for (uint256 i = 0; i < users.length; i++) {
            user = userAccess[_file][_accessType][i];
            if (accessSpecifier[_file][_accessType][user] <= block.timestamp) {
                delete users[i];
            }
        }
        return users;
    }

    function indexOf(address[] memory values, address value) internal pure returns (uint256) {
        uint256 i = 0;
        while (values[i] != value) {
            i++;
        }
        return i;
    }

    function revoke(
        bytes32 _file,
        address _user,
        bytes32 _accessType
    ) public {
        delete accessSpecifier[_file][_accessType][_user];
        uint256 index = indexOf(userAccess[_file][_accessType], _user);
        delete userAccess[_file][_accessType][index];
        emit NewUpdateACK(msg.sender, _file, _user, _accessType);
    }

    /**
     * @dev Change file Owner
     * @return bool
     */
    function changeFileOwner(bytes32 _file, address _newOwner) public onlyFileOwner(_file) returns (bool) {
        require(_newOwner != address(0), "Invalid address");
        owners[_file] = _newOwner;
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

{
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}