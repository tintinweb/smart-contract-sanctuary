// File: openzeppelin-solidity/contracts/GSN/Context.sol



pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
}

// File: original_contracts/IAugustusRegistry.sol

pragma solidity 0.7.5;


interface IAugustusRegistry {

    function addAugustus(string calldata version, address augustus, bool isLatest) external;

    function banAugustus(address augustus) external;

    function isAugustusBanned(address augustus) external view returns (bool);

    function isValidAugustus(address augustus) external view returns (bool);

    function getAugustusCount() external view returns (uint256);

    function getLatestVersion() external view returns (string memory);

    function getLatestAugustus() external view returns (address);

    function getAugustusByVersion(string calldata version) external view returns (address);
}

// File: original_contracts/AugustusRegistry.sol

pragma solidity 0.7.5;



contract AugustusRegistry is IAugustusRegistry, Ownable {

    mapping(bytes32 => address) private versionVsAugustus;

    mapping(address => bool) private augustusVsValid;

    //mapping of banned Augustus
    mapping(address => bool) private banned;

    string private latestVersion;

    uint256 private count;

    event AugustusAdded(string version, address indexed augustus, bool isLatest);
    event AugustusBanned(address indexed augustus);

    function addAugustus(
        string calldata version,
        address augustus,
        bool isLatest
    )
        external
        override
        onlyOwner
    {   
        bytes32 keccakedVersion = keccak256(abi.encodePacked(version));
        require(augustus != address(0), "Invalid augustus address");
        require(versionVsAugustus[keccakedVersion] == address(0), "Version already exists");
        require(!augustusVsValid[augustus], "Augustus already exists");

        versionVsAugustus[keccakedVersion] = augustus;
        augustusVsValid[augustus] = true;
        count = count + 1;

        if (isLatest) {
            latestVersion = version;
        }

        emit AugustusAdded(version, augustus, isLatest);
    }

    function banAugustus(address augustus) external override onlyOwner {
        banned[augustus] = true;
        emit AugustusBanned(augustus);
    }

    function isValidAugustus(address augustus) external override view returns (bool) {
        return (augustusVsValid[augustus] && !banned[augustus]);
    }

    function isAugustusBanned(address augustus) external override view returns (bool) {
        return banned[augustus];
    }

    function getAugustusCount() external override view returns (uint256) {
        return count;
    }

    function getLatestVersion() external override view returns (string memory) {
        return latestVersion;
    }

    function getLatestAugustus() external override view returns (address) {
        return versionVsAugustus[keccak256(abi.encodePacked(latestVersion))];
    }

    function getAugustusByVersion(string calldata version) external override view returns (address) {
        return versionVsAugustus[keccak256(abi.encodePacked(version))];
    }
}

