// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract NodeList is OwnableUpgradeable {
    uint256 public currentEpoch;

    struct Details {
        string declaredIp;
        uint256 position;
        uint256 pubKx;
        uint256 pubKy;
        string tmP2PListenAddress;
        string p2pListenAddress;
    }

    struct Epoch {
        uint256 id;
        uint256 n;
        uint256 k;
        uint256 t;
        address[] nodeList;
        uint256 prevEpoch;
        uint256 nextEpoch;
    }

    event NodeListed(address publicKey, uint256 epoch, uint256 position);
    event EpochChanged(uint256 oldEpoch, uint256 newEpoch);

    mapping(uint256 => mapping(address => bool)) public whitelist;

    mapping(uint256 => Epoch) public epochInfo;

    mapping(address => Details) public nodeDetails;

    mapping(uint256 => mapping(uint256 => uint256)) public pssStatus;

    modifier epochValid(uint256 epoch) {
        require(epoch != 0, "Epoch can't be 0");
        _;
    }

    modifier epochCreated(uint256 epoch) {
        require(epochInfo[epoch].id == epoch, "Epoch already created");
        _;
    }

    modifier whitelisted(uint256 epoch) {
        require(isWhitelisted(epoch, msg.sender), "Node isn't whitelisted for epoch");
        _;
    }

    // @dev Act like a constructor for upgradable contract.
    function initialize(uint256 _epoch) public initializer {
        OwnableUpgradeable.__Ownable_init();
        currentEpoch = _epoch;
    }

    function setCurrentEpoch(uint256 _newEpoch) external onlyOwner {
        uint256 oldEpoch = currentEpoch;
        currentEpoch = _newEpoch;
        emit EpochChanged(oldEpoch, _newEpoch);
    }

    function listNode(
        uint256 epoch,
        string calldata declaredIp,
        uint256 pubKx,
        uint256 pubKy,
        string calldata tmP2PListenAddress,
        string calldata p2pListenAddress
    ) external whitelisted(epoch) epochValid(epoch) epochCreated(epoch) {
        require(!nodeRegistered(epoch, msg.sender), "Node is already registered");
        Epoch storage epochI = epochInfo[epoch];
        epochI.nodeList.push(msg.sender);
        nodeDetails[msg.sender] = Details({
            declaredIp: declaredIp,
            position: epochI.nodeList.length,
            pubKx: pubKx,
            pubKy: pubKy,
            tmP2PListenAddress: tmP2PListenAddress,
            p2pListenAddress: p2pListenAddress
        });
        emit NodeListed(msg.sender, epoch, epochI.nodeList.length);
    }

    function getNodes(uint256 epoch) external view epochValid(epoch) returns (address[] memory) {
        return epochInfo[epoch].nodeList;
    }

    function getNodeDetails(address nodeAddress)
        external
        view
        returns (
            string memory declaredIp,
            uint256 position,
            string memory tmP2PListenAddress,
            string memory p2pListenAddress
        )
    {
        Details memory nodeDetail;
        nodeDetail = nodeDetails[nodeAddress];
        return (nodeDetail.declaredIp, nodeDetail.position, nodeDetail.tmP2PListenAddress, nodeDetail.p2pListenAddress);
    }

    function getPssStatus(uint256 oldEpoch, uint256 newEpoch) external view returns (uint256) {
        return pssStatus[oldEpoch][newEpoch];
    }

    function getEpochInfo(uint256 epoch)
        external
        view
        epochValid(epoch)
        returns (
            uint256 id,
            uint256 n,
            uint256 k,
            uint256 t,
            address[] memory nodeList,
            uint256 prevEpoch,
            uint256 nextEpoch
        )
    {
        Epoch memory epochI = epochInfo[epoch];
        return (epochI.id, epochI.n, epochI.k, epochI.t, epochI.nodeList, epochI.prevEpoch, epochI.nextEpoch);
    }

    function updatePssStatus(
        uint256 oldEpoch,
        uint256 newEpoch,
        uint256 status
    ) public onlyOwner epochValid(oldEpoch) epochValid(newEpoch) {
        pssStatus[oldEpoch][newEpoch] = status;
    }

    function updateWhitelist(
        uint256 epoch,
        address nodeAddress,
        bool allowed
    ) public onlyOwner epochValid(epoch) {
        whitelist[epoch][nodeAddress] = allowed;
    }

    function updateEpoch(
        uint256 epoch,
        uint256 n,
        uint256 k,
        uint256 t,
        address[] memory nodeList,
        uint256 prevEpoch,
        uint256 nextEpoch
    ) public onlyOwner epochValid(epoch) {
        epochInfo[epoch] = Epoch(epoch, n, k, t, nodeList, prevEpoch, nextEpoch);
    }

    function isWhitelisted(uint256 epoch, address nodeAddress) public view returns (bool) {
        return whitelist[epoch][nodeAddress];
    }

    function nodeRegistered(uint256 epoch, address nodeAddress) public view returns (bool) {
        Epoch storage epochI = epochInfo[epoch];
        for (uint256 i = 0; i < epochI.nodeList.length; i++) {
            if (epochI.nodeList[i] == nodeAddress) {
                return true;
            }
        }
        return false;
    }

    function clearAllEpoch() public {
        for (uint256 i = 0; i <= currentEpoch; i++) {
            delete epochInfo[i];
        }
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

