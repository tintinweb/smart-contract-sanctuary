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

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../escrow/IEscrow.sol";
import "../resource-feed/IResourceFeed.sol";

/// @title DnsClusterMetadataStore is a Contract which is ownership functionality
/// @notice Used for maintaining state of Clusters & there voting
contract DnsClusterMetadataStore is Ownable {
    address public stakingContract;
    IEscrow public escrow;
    IResourceFeed public resourceFeed;

    struct ClusterMetadata {
        address clusterOwner;
        string ipAddress;
        string whitelistedIps;
        uint256 upvotes;
        uint256 downvotes;
        bool isDefaulter;
        uint256 qualityFactor;
        bool active;
    }

    mapping(bytes32 => mapping(address => uint256)) public clusterUpvotes;
    mapping(bytes32 => ClusterMetadata) public dnsToClusterMetadata;

    /*
     * @dev - constructor (being called at contract deployment)
     * @param resourceFeed - deployed Address of Resource Feed Contract
     */
    constructor(IResourceFeed _resourceFeed) public {
        resourceFeed = _resourceFeed;
    }

    modifier onlyStakingContract() {
        require(
            msg.sender == stakingContract,
            "Invalid Caller: Not a staking contract"
        );
        _;
    }

    /*
     * @title - Modifies the staking contract Address
     * @param deployed Address of Staking Contract
     * @dev Could only be called by the Owner of contract
     */
    function setStakingContract(address _stakingContract) public onlyOwner {
        stakingContract = _stakingContract;
    }

    /*
     * @title Modifies the escrow contract Address
     * @param deployed Address of Escrow Contract
     * @dev Could only be called by the Owner of contract
     */
    function setEscrowContract(IEscrow _escrow) public onlyOwner {
        escrow = _escrow;
    }

    /*
     * @title creates new dns entry
     * @param dns name
     * @param cluster owner address
     * @param IPAddress of dns
     * @param whitelisted IP
     * @dev Could only be invoked by the staking contract
     */
    function addDnsToClusterEntry(
        bytes32 _dns,
        address _clusterOwner,
        string memory _ipAddress,
        string memory _whitelistedIps
    ) public onlyStakingContract {
        ClusterMetadata memory metadata = ClusterMetadata(
            _clusterOwner,
            _ipAddress,
            _whitelistedIps,
            0,
            0,
            false,
            100,
            true
        );

        dnsToClusterMetadata[_dns] = metadata;
    }

    function changeClusterStatus(bytes32 _dns, bool _status) public {
        require(dnsToClusterMetadata[_dns].clusterOwner == msg.sender);
        dnsToClusterMetadata[_dns].active = _status;
    }

    /*
     * @title removes the pre added dns entry
     * @param dns name
     * @dev Could only be invoked by the staking contract
     */
    function removeDnsToClusterEntry(bytes32 _dns) public onlyStakingContract {
        delete dnsToClusterMetadata[_dns];
    }

    /*
     * @title upvote a particular cluster , depicting a good service
     * @param dns name of a cluster
     */
    function upvoteCluster(bytes32 _dns) public {
        // check here if _dns = deposit.clusterDns
        (
            bytes32 clusterDns,
            uint256 cpuCoresUnits,
            uint256 diskSpaceUnits,
            uint256 bandwithUnits,
            uint256 memoryUnits,
            ,
            ,
            ,

        ) = escrow.deposits(msg.sender);
        require(
            _dns == clusterDns,
            "Invalid Deposit to cluster mapping in escrow"
        );

        // make this a function of utilised funds
        uint256 votingCapacity = getTotalVotes(
            clusterDns,
            cpuCoresUnits,
            diskSpaceUnits,
            bandwithUnits,
            memoryUnits
        );
        require(
            clusterUpvotes[_dns][msg.sender] < votingCapacity,
            "Already upvoted"
        );
        clusterUpvotes[_dns][msg.sender] = clusterUpvotes[_dns][msg.sender] + 1;
        dnsToClusterMetadata[_dns].upvotes += 1;
    }

    /*
     * @title downvote a particular cluster , depicting a bad service
     * @param dns name of the cluster
     */
    function downvoteCluster(bytes32 _dns) public {
        require(clusterUpvotes[_dns][msg.sender] > 0, "Not a upvoter");
        clusterUpvotes[_dns][msg.sender] = clusterUpvotes[_dns][msg.sender] - 1;
        dnsToClusterMetadata[_dns].downvotes += 1;
    }

    /*
     * @title Make a cluster defaulter
     * @param dns name
     * @dev Could only be invoked by the contract owner
     */
    function markClusterAsDefaulter(bytes32 _dns) public onlyOwner {
        require(
            dnsToClusterMetadata[_dns].clusterOwner != address(0),
            "Cluster not found"
        );
        dnsToClusterMetadata[_dns].isDefaulter = true;
    }

    function _calculateVotesPerResource(
        bytes32 clusterDns,
        string calldata name,
        uint256 resourceUnits
    ) internal view returns (uint256) {
        return
            (resourceUnits * 1e18) /
            resourceFeed.getResourceVotingWeight(clusterDns, name);
    }

    /*
     * @title Fetches total number of votes based on the resources
     * @param number of cpu core units
     * @param number of disk space units
     * @param number of bandwidth units
     * @param number of memory units
     * @return number of votes
     */
    function getTotalVotes(
        bytes32 clusterDns,
        uint256 cpuCoresUnits,
        uint256 diskSpaceUnits,
        uint256 bandwidthUnits,
        uint256 memoryUnits
    ) public view returns (uint256 votes) {
        votes = _calculateVotesPerResource(clusterDns, "cpu", cpuCoresUnits);
        votes =
            votes +
            _calculateVotesPerResource(clusterDns, "memory", memoryUnits);
        votes =
            votes +
            _calculateVotesPerResource(clusterDns, "bandwidth", bandwidthUnits);
        votes =
            votes +
            _calculateVotesPerResource(clusterDns, "disk", diskSpaceUnits);
    }

    function getClusterOwner(bytes32 clusterDns) public view returns (address) {
        return dnsToClusterMetadata[clusterDns].clusterOwner;
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

pragma solidity ^0.6.12;

interface IEscrow {
    function deposits(address depositer)
        external
        returns (
            bytes32,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IResourceFeed {
    struct ResourceCapacity {
        uint256 resourceOneUnits; // cpuCoresUnits
        uint256 resourceTwoUnits; // diskSpaceUnits
        uint256 resourceThreeUnits; // bandwidthUnits
        uint256 resourceFourUnits; // memoryUnits
        uint256 resourceFiveUnits;
        uint256 resourceSixUnits;
        uint256 resourceSevenUnits;
        uint256 resourceEightUnits;
    }

    function getResourcePriceUSDT(bytes32 clusterDns, string calldata name)
        external
        view
        returns (uint256);

    function getResourceDripRateUSDT(bytes32 clusterDns, string calldata name)
        external
        view
        returns (uint256);

    function getResourceVotingWeight(bytes32 clusterDns, string calldata name)
        external
        view
        returns (uint256);

    function USDToken() external view returns (address);

    function getResourceMaxCapacity(bytes32 clusterDns)
        external
        returns (ResourceCapacity memory);
}

