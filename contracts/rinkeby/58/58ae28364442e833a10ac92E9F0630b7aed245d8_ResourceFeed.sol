pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IDnsClusterMetadataStore {
    function dnsToClusterMetadata(bytes32)
        external
        returns (
            address,
            string memory,
            string memory,
            uint256,
            uint256,
            bool,
            uint256,
            bool
        );

    function addDnsToClusterEntry(
        bytes32 _dns,
        address _clusterOwner,
        string memory ipAddress,
        string memory _whitelistedIps
    ) external;

    function removeDnsToClusterEntry(bytes32 _dns) external;

    function upvoteCluster(bytes32 _dns) external;

    function downvoteCluster(bytes32 _dns) external;

    function markClusterAsDefaulter(bytes32 _dns) external;

    function getClusterOwner(bytes32 clusterDns) external returns (address);
}

pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../cluster-metadata/IDnsClusterMetadataStore.sol";

/// @title ResourceFeed is a Contract which is ownership functionality
/// @notice Used for maintaining state of StackOS Resource's components prices
contract ResourceFeed is Ownable {
    address public stackToken;
    address public clusterMetadataStore;

    // votingWeightPerUtilisedFUnds;

    struct Resource {
        string name;
        uint256 dripRatePerUnit;
        uint256 votingWeightPerUnit;
    }

    mapping(bytes32 => mapping(string => Resource)) public resources;

    struct ResourceUnits {
        uint256 resourceOneUnits; // cpuCoresUnits
        uint256 resourceTwoUnits; // diskSpaceUnits
        uint256 resourceThreeUnits; // bandwidthUnits
        uint256 resourceFourUnits; // memoryUnits
        uint256 resourceFiveUnits;
        uint256 resourceSixUnits;
        uint256 resourceSevenUnits;
        uint256 resourceEightUnits;
    }

    mapping(bytes32 => mapping(address => ResourceUnits))
        public resourcesMaxPerDNSforAddress;

    mapping(bytes32 => ResourceUnits) public resourcesMaxPerDNS;

    function setResourceMaxCapacity(
        bytes32 clusterDns,
        ResourceUnits memory maxUnits
    ) public {
        address clusterOwner = IDnsClusterMetadataStore(clusterMetadataStore)
        .getClusterOwner(clusterDns);
        require(clusterOwner == msg.sender, "Not the cluster owner!");
        resourcesMaxPerDNS[clusterDns] = maxUnits;
    }

    function getResourceMaxCapacity(bytes32 clusterDns)
        external
        view
        returns (ResourceUnits memory)
    {
        return resourcesMaxPerDNS[clusterDns];
    }

    function setResourceAddressMaxCapacity(
        bytes32 clusterDns,
        address wallet,
        ResourceUnits memory maxUnits
    ) public {
        address clusterOwner = IDnsClusterMetadataStore(clusterMetadataStore)
        .getClusterOwner(clusterDns);
        require(clusterOwner == msg.sender, "Not the cluster owner!");
        resourcesMaxPerDNSforAddress[clusterDns][wallet] = maxUnits;
    }

    /*
     * @dev - constructor (being called at contract deployment)
     * @param Address of stackToken deployed contract
     */
    constructor(address _stackToken, address _USDToken) public {
        stackToken = _stackToken;
    }

    /*
     * @title Add a new resource component
     * @param name of the resource
     * @param Drip Rate for a single unit
     * @param Vote weightage of a single unit
     * @return True if successfully invoked
     * @dev Could only be invoked by the contract owner
     */

    function setclusterMetadataStore(address _clustermetadatastore)
        public
        onlyOwner
    {
        clusterMetadataStore = _clustermetadatastore;
    }

    // Added in Dollar value.
    function addResource(
        bytes32 clusterDns,
        string memory name,
        uint256 dripRatePerUnit
    ) public returns (bool) {
        address clusterOwner = IDnsClusterMetadataStore(clusterMetadataStore)
        .getClusterOwner(clusterDns);
        require(clusterOwner == msg.sender, "Not the cluster owner!");
        Resource storage resource = resources[clusterDns][name];
        resource.name = name;
        resource.dripRatePerUnit = dripRatePerUnit;
        return true;
    }

    /*
     * @title Remove a resource from the list
     * @param name of the resource
     * @return True if successfully invoked
     * @dev Could only be invoked by the contract owner
     */
    function removeResource(bytes32 clusterDns, string memory name)
        public
        returns (bool)
    {
        address clusterOwner = IDnsClusterMetadataStore(clusterMetadataStore)
        .getClusterOwner(clusterDns);
        require(clusterOwner == msg.sender, "Not the cluster owner!");
        delete resources[clusterDns][name];
        return true;
    }

    /*
     * @title Update resource's drip rate
     * @param name of the resource
     * @param New DripRate for the resource
     * @return True if successfully invoked
     */
    function setResourceDripRateUSDT(
        bytes32 clusterDns,
        string memory name,
        uint256 dripRatePerUnit
    ) public returns (bool) {
        address clusterOwner = IDnsClusterMetadataStore(clusterMetadataStore)
        .getClusterOwner(clusterDns);
        require(clusterOwner == msg.sender, "Not the cluster owner!");
        Resource storage resource = resources[clusterDns][name];
        require(
            keccak256(abi.encodePacked(resource.name)) ==
                keccak256(abi.encodePacked(name)),
            "Resource not added."
        );
        resource.dripRatePerUnit = dripRatePerUnit;
        return true;
    }

    /*
     * @title Fetches a Resource's Drip Rate
     * @param name of the resource
     * @return Resource Drip rate
     */
    function getResourceDripRateUSDT(bytes32 clusterDns, string calldata name)
        external
        view
        returns (uint256)
    {
        Resource storage resource = resources[clusterDns][name];
        return resource.dripRatePerUnit;
    }

    /*
     * @title Update resource's voting weight
     * @param name of the resource
     * @param New voting weight for the resource
     * @return True if successfully invoked
     * @dev Could only be invoked by the contract owner
     */
    function setResourceVotingWeight(
        bytes32 clusterDns,
        string calldata name,
        uint256 votingWeightPerUnit
    ) public returns (bool) {
        address clusterOwner = IDnsClusterMetadataStore(clusterMetadataStore)
        .getClusterOwner(clusterDns);
        require(clusterOwner == msg.sender, "Not the cluster owner!");
        Resource storage resource = resources[clusterDns][name];
        require(
            keccak256(abi.encodePacked(resource.name)) ==
                keccak256(abi.encodePacked(name)),
            "Resource not added."
        );
        resource.votingWeightPerUnit = votingWeightPerUnit;
        return true;
    }

    /*
     * @title Fetches a Resource's voting weight
     * @param name of the resource
     * @return Resource voting weight
     */
    function getResourceVotingWeight(bytes32 clusterDns, string calldata name)
        public
        view
        returns (uint256)
    {
        Resource storage resource = resources[clusterDns][name];
        require(
            keccak256(abi.encodePacked(resource.name)) ==
                keccak256(abi.encodePacked(name)),
            "Resource not added."
        );
        return resource.votingWeightPerUnit;
    }

    /*
     * @dev - converts string to bytes32
     * @param string
     * @return bytes32 - converted bytes
     */
    function stringToBytes32(string memory source)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    /*
     * @dev - converts bytes32 to string
     * @param bytes32
     * @return string - converted string
     */
    function bytes32ToString(bytes32 x)
        public
        pure
        returns (string memory, uint256)
    {
        bytes memory bytesString = new bytes(32);
        uint256 charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            bytes1 char = bytes1(bytes32(uint256(x) * 2**(8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return (string(bytesStringTrimmed), charCount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
}

// SPDX-License-Identifier: MIT

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

