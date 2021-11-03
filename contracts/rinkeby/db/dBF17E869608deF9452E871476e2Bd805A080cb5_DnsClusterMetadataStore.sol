pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../escrow/IEscrow.sol";
import "../resource-feed/IResourceFeed.sol";
import "../escrow/EscrowLib.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/// @title DnsClusterMetadataStore is a Contract which is ownership functionality
/// @notice Used for maintaining state of Clusters & there voting
contract DnsClusterMetadataStore is Ownable {
    using SafeMath for uint256;
    address public stakingContract;
    address public escrowAddress;
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
        string clusterType;
        bool isPrivate;
    }

    mapping(bytes32 => mapping(address => uint256)) public clusterUpvotes;
    mapping(bytes32 => mapping(address => uint256)) public clusterDownvotes;
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
     * @param deployed Address of Escrow Contract
     * @dev Could only be called by the Owner of contract
     */
    function setAddressSetting(address _stakingContract, address _escrow)
        public
        onlyOwner
    {
        stakingContract = _stakingContract;
        escrowAddress = _escrow;
    }

    /*
     * @title creates new dns entry
     * @param dns name
     * @param cluster owner address
     * @param IPAddress of dns
     * @param whitelisted IP
     * @param cluster type
     * @param isPrivate
     * @dev Could only be invoked by the staking contract
     */
    function addDnsToClusterEntry(
        bytes32 _dns,
        address _clusterOwner,
        string memory _ipAddress,
        string memory _whitelistedIps,
        string memory _clusterType,
        bool _isPrivate
    ) public onlyStakingContract {
        ClusterMetadata memory clusterMetadata = dnsToClusterMetadata[_dns];
        require(clusterMetadata.clusterOwner == address(0));
        ClusterMetadata memory metadata = ClusterMetadata(
            _clusterOwner,
            _ipAddress,
            _whitelistedIps,
            0,
            0,
            false,
            100,
            true,
            _clusterType,
            _isPrivate
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
        EscrowLib.Deposit memory deposit = IEscrow(escrowAddress).getDeposits(
            msg.sender,
            _dns
        );
        // make this a function of utilised funds
        uint256 votingCapacity = getTotalVotes(
            deposit.resourceOneUnits,
            deposit.resourceTwoUnits,
            deposit.resourceThreeUnits,
            deposit.resourceFourUnits, // memoryUnits
            deposit.resourceFiveUnits,
            deposit.resourceSixUnits,
            deposit.resourceSevenUnits,
            deposit.resourceEightUnits,
            _dns
        );
        require(
            clusterUpvotes[_dns][msg.sender] <= votingCapacity,
            "Already upvoted"
        );

        if (
            clusterDownvotes[_dns][msg.sender] > 0 &&
            dnsToClusterMetadata[_dns].downvotes > 0
        ) {
            clusterDownvotes[_dns][msg.sender] -= 1;
            dnsToClusterMetadata[_dns].downvotes -= 1;
        }

        clusterUpvotes[_dns][msg.sender] += 1;
        dnsToClusterMetadata[_dns].upvotes += 1;
    }

    /*
     * @title downvote a particular cluster , depicting a bad service
     * @param dns name of the cluster
     */
    function downvoteCluster(bytes32 _dns) public {
        EscrowLib.Deposit memory deposit = IEscrow(escrowAddress).getDeposits(
            msg.sender,
            _dns
        );

        uint256 votingCapacity = getTotalVotes(
            deposit.resourceOneUnits,
            deposit.resourceTwoUnits,
            deposit.resourceThreeUnits,
            deposit.resourceFourUnits, // memoryUnits
            deposit.resourceFiveUnits,
            deposit.resourceSixUnits,
            deposit.resourceSevenUnits,
            deposit.resourceEightUnits,
            _dns
        );
        require(
            clusterDownvotes[_dns][msg.sender] <= votingCapacity,
            "Already downVoted"
        );

        if (
            clusterUpvotes[_dns][msg.sender] > 0 &&
            dnsToClusterMetadata[_dns].upvotes > 0
        ) {
            clusterUpvotes[_dns][msg.sender] -= 1;
            dnsToClusterMetadata[_dns].upvotes -= 1;
        }
        clusterDownvotes[_dns][msg.sender] += 1;
        dnsToClusterMetadata[_dns].downvotes += 1;
    }

    /*
     * @title Make a cluster defaulter
     * @param dns name
     * @dev Could only be invoked by the contract owner
     */
    //  Removed for this release.
    // function markClusterAsDefaulter(bytes32 _dns) public onlyOwner {
    //     require(
    //         dnsToClusterMetadata[_dns].clusterOwner != address(0),
    //         "Cluster not found"
    //     );
    //     dnsToClusterMetadata[_dns].isDefaulter = true;
    // }

    function _calculateVotesPerResource(
        bytes32 clusterDns,
        string memory name,
        uint256 resourceUnits
    ) internal view returns (uint256) {
        require(
            resourceFeed.getResourceVotingWeight(clusterDns, name) != 0,
            "Voting not allowed"
        );
        return
            resourceUnits
                .mul(resourceFeed.getResourceVotingWeight(clusterDns, name))
                .div(10**18);
    }

    /*
     * @title Fetches total number of votes based on the resources

     * @return number of votes
     */
    function getTotalVotes(
        uint256 resourceOneUnits, // cpuCoresUnits
        uint256 resourceTwoUnits, // diskSpaceUnits
        uint256 resourceThreeUnits, // bandwidthUnits
        uint256 resourceFourUnits, // memoryUnits
        uint256 resourceFiveUnits,
        uint256 resourceSixUnits,
        uint256 resourceSevenUnits,
        uint256 resourceEightUnits,
        bytes32 clusterDns
    ) public returns (uint256 votes) {
        votes =
            _calculateVotesPerResource(
                clusterDns,
                IEscrow(escrowAddress).getResouceVar(1),
                resourceOneUnits
            ) +
            _calculateVotesPerResource(
                clusterDns,
                IEscrow(escrowAddress).getResouceVar(2),
                resourceTwoUnits
            ) +
            _calculateVotesPerResource(
                clusterDns,
                IEscrow(escrowAddress).getResouceVar(3),
                resourceThreeUnits
            ) +
            _calculateVotesPerResource(
                clusterDns,
                IEscrow(escrowAddress).getResouceVar(4),
                resourceFourUnits
            );
        votes =
            votes +
            _calculateVotesPerResource(
                clusterDns,
                IEscrow(escrowAddress).getResouceVar(5),
                resourceFiveUnits
            ) +
            _calculateVotesPerResource(
                clusterDns,
                IEscrow(escrowAddress).getResouceVar(6),
                resourceSixUnits
            ) +
            _calculateVotesPerResource(
                clusterDns,
                IEscrow(escrowAddress).getResouceVar(7),
                resourceSevenUnits
            ) +
            _calculateVotesPerResource(
                clusterDns,
                IEscrow(escrowAddress).getResouceVar(8),
                resourceEightUnits
            );
    }

    function getClusterOwner(bytes32 clusterDns) public view returns (address) {
        return dnsToClusterMetadata[clusterDns].clusterOwner;
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

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "../escrow/EscrowLib.sol";

interface IEscrow {
    function getDeposits(address depositer, bytes32 clusterDns)
        external
        returns (EscrowLib.Deposit memory);

    function getResouceVar(uint8 _id) external returns (string memory);
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "../escrow/EscrowLib.sol";

interface IResourceFeed {

    function getResourceDripRateUSDT(bytes32 clusterDns, string calldata name)
        external
        view
        returns (uint256);

    function getResourceVotingWeight(bytes32 clusterDns, string calldata name)
        external
        view
        returns (uint256);

    function getResourceMaxCapacity(bytes32 clusterDns)
        external
        returns (EscrowLib.ResourceUnits memory);
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

library EscrowLib {
    struct Deposit {
        uint256 resourceOneUnits; // cpuCoresUnits
        uint256 resourceTwoUnits; // diskSpaceUnits
        uint256 resourceThreeUnits; // bandwidthUnits
        uint256 resourceFourUnits; // memoryUnits
        uint256 resourceFiveUnits;
        uint256 resourceSixUnits;
        uint256 resourceSevenUnits;
        uint256 resourceEightUnits;
        uint256 totalDeposit;
        uint256 lastTxTime;
        uint256 totalDripRatePerSecond;
        uint256 notWithdrawable;
    }

    // Address of Token contract.
    // What percentage is exchanged to this token on withdrawl.
    struct WithdrawSetting {
        address token;
        uint256 percent;
    }

    struct ResourceUnits {
        uint256 resourceOne; // cpuCoresUnits
        uint256 resourceTwo; // diskSpaceUnits
        uint256 resourceThree; // bandwidthUnits
        uint256 resourceFour; // memoryUnits
        uint256 resourceFive;
        uint256 resourceSix;
        uint256 resourceSeven;
        uint256 resourceEight;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
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