/**
 *Submitted for verification at polygonscan.com on 2021-12-11
*/

// File: contracts/ILocker.sol




pragma solidity ^0.8.0;

struct LockerState {
    uint256 currentLockingAmount;
    uint256 lockTime;
    uint256 delegatedTo;
    uint256 delegatedFrom;
}


interface ILocker {
    function getLockerState(address) external view returns(LockerState memory);
}
// File: openzeppelin-solidity/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/Governance.sol

pragma solidity ^0.8.0;







struct Options {
    uint256 voted;
    string metadataURI;
}

struct Proposal {
    uint256 votingDeadline;
    uint256 rewardDistributionDeadline;
    string proposalMetadataURI;
    uint256 knigthReward;
    uint256 totalVotedPower;
    Options[] options;
}

struct VoteHistory {
    uint256 votePower;
    uint256 claimedReward;
}

contract Governance is Ownable{
    using SafeMath for uint256;

    mapping (uint256 => Proposal) public proposals;
    uint256 public mappingNonce;
    mapping (uint256 => mapping (address => VoteHistory)) public voteStatus;

    IERC20 public knightToken;
    ILocker public lockerContract;

    event AddProposal(uint256 indexed index,string indexed proposalMetadataURI, uint256 votingDeadline,uint256 rewardDistributionDeadline,uint256 knigthReward, string[] optionsMetadataURI);
    event AddVote(address indexed voter, uint256 indexed indexOfProposal, uint256[] votedOptionsIndices, uint256[] votedPower);
    event ClaimReward(address indexed voter, uint256 indexed indexOfProposal, uint256 amount);

    constructor (address _knightToken, address _lockerContract) {
        knightToken = IERC20(_knightToken);
        lockerContract = ILocker(_lockerContract);
    }

    function addProposal(string memory proposalMetadataURI, uint256 votingDeadline,uint256 rewardDistributionDeadline, uint256 knigthReward, string[] memory optionsMetadataURI) public onlyOwner{
        require(optionsMetadataURI.length > 0, "Not Enough options!");
        require(rewardDistributionDeadline > votingDeadline);
        knightToken.transferFrom(msg.sender,address(this), knigthReward);
        proposals[mappingNonce].votingDeadline = votingDeadline;
        proposals[mappingNonce].rewardDistributionDeadline = rewardDistributionDeadline;
        proposals[mappingNonce].proposalMetadataURI = proposalMetadataURI;

        proposals[mappingNonce].knigthReward = knigthReward;
        for (uint256 index = 0; index < optionsMetadataURI.length; index++) {
            proposals[mappingNonce].options.push(Options(0, optionsMetadataURI[index]));
        }

        emit AddProposal(mappingNonce, proposalMetadataURI, votingDeadline, rewardDistributionDeadline, knigthReward, optionsMetadataURI);


        mappingNonce += 1;


    }

    function vote(uint256 indexOfProposal, uint256[] memory votedOptionsIndices, uint256[] memory votedPower) public {
        require(mappingNonce > indexOfProposal, "Wrong proposal index!");
        require(block.timestamp <= proposals[indexOfProposal].votingDeadline, "To late to vote!");
        require(voteStatus[indexOfProposal][msg.sender].votePower == 0, "You already voted!");
        require(votedOptionsIndices.length == votedPower.length, "votedOptionsIndices and votedPower should be the same size!");
        LockerState memory lockerState = lockerContract.getLockerState(msg.sender);
        require(lockerState.currentLockingAmount > 0, "You don't have any vote power!");
        require(block.timestamp.sub(lockerState.lockTime) > 14 days, "You can not vote until 14 days afer your stake!");
        Options[] storage options = proposals[mappingNonce].options;
        uint256 accumolativeVotePower;
        for (uint256 index = 0; index < votedOptionsIndices.length; index++) {
            options[votedOptionsIndices[index]].voted = options[votedOptionsIndices[index]].voted.add(votedPower[index]);
            accumolativeVotePower = accumolativeVotePower.add(votedPower[index]);
        }
        require(accumolativeVotePower == lockerState.currentLockingAmount,"Your voting fractions is not 100%");
        proposals[indexOfProposal].totalVotedPower = proposals[indexOfProposal].totalVotedPower.add(lockerState.currentLockingAmount);
        voteStatus[indexOfProposal][msg.sender].votePower = voteStatus[indexOfProposal][msg.sender].votePower.add(lockerState.currentLockingAmount);

        emit AddVote(msg.sender, indexOfProposal, votedOptionsIndices, votedPower);
        //emit events
    }

    function claimReward(uint256 indexOfProposal) public returns (uint256) {
        require(mappingNonce > indexOfProposal, "Wrong proposal index!");
        require(block.timestamp > proposals[indexOfProposal].votingDeadline, "To soon to claim reward!");
        require(voteStatus[indexOfProposal][msg.sender].votePower > 0, "You didn't vote to this propsal!");
        uint256 claimingReward = calculateClaimingReward(msg.sender, indexOfProposal);
        if (claimingReward > 0) {
            voteStatus[indexOfProposal][msg.sender].claimedReward = voteStatus[indexOfProposal][msg.sender].claimedReward.add(claimingReward);
            knightToken.transfer(msg.sender, claimingReward);

            emit ClaimReward(msg.sender, indexOfProposal, claimingReward);
        }
        return claimingReward;
    }

    function batchClaimReward(uint256[] memory proposalIndices) public{
        for (uint256 index = 0; index < proposalIndices.length; index++) {
            claimReward(proposalIndices[index]);
        }
    }

    function calculateReward(address addr, uint256 indexOfProposal) public view returns(uint256) {
        return voteStatus[indexOfProposal][addr].votePower.
        mul(proposals[indexOfProposal].knigthReward).div(proposals[indexOfProposal].totalVotedPower);
    }

    function calculateUnlockedReward(address addr, uint256 indexOfProposal) public view returns(uint256) {
        uint256 unlockedTime = block.timestamp; 
        Proposal memory proposal = proposals[indexOfProposal];
        if (block.timestamp < proposal.votingDeadline) {
            return 0;
        }
        if (block.timestamp > proposal.rewardDistributionDeadline) {
            unlockedTime = proposal.rewardDistributionDeadline;
        }
        uint256 ditributionPeriod = proposal.rewardDistributionDeadline.sub(proposal.votingDeadline);
        uint256 unlockedReward = calculateReward(addr, indexOfProposal).mul(unlockedTime).div(ditributionPeriod);
        return unlockedReward;
    }

    function calculateClaimingReward(address addr, uint256 indexOfProposal) public view returns(uint256) {
        return calculateUnlockedReward(addr, indexOfProposal).sub(voteStatus[indexOfProposal][addr].claimedReward);
    }

    function getVoteResult(uint256 indexOfProposal) public view returns(Options[] memory) {
        return proposals[indexOfProposal].options;
    }
}