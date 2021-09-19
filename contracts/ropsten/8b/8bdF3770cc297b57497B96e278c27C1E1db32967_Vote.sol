/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

pragma solidity 0.7.2;

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract PolvenStaking {
    struct Stake {
        uint256 amount;
        uint256 normalizedAmount;
    }

    struct StakeTimeframe {
        uint256 amount;
        uint256 normalizedAmount;
        uint256 lastStakeTime;
    }

    mapping(address => Stake) public userStakes;
    mapping(address => StakeTimeframe) public userStakesTimeframe;
}

contract Vote is Ownable {
    using SafeMath for uint256;
    
    uint256 counter;
    
    enum Choice { YES, NO, ABSTAINED }
    enum AdminStatus { OPEN, CLOSED }
    enum ProposalStatus { OPEN, CLOSED }
    
    event CreateVote(uint256 expirationDate, string title, string description);
    event Voting (Choice _choice, address voter, uint256 count, uint256 counter);
    event CloseProposal(uint256 counter);
    
    struct Voter {
        uint256 count;
        Choice choice;
    }
    
    struct Proposal {
        uint256 expirationDate;
        string title;
        string description;
        AdminStatus adminStatus;
        // or use separate mapping
        uint256 yes;
        uint256 no;
        uint256 abstained;
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => Voter) ) public votes;
    mapping(uint256 => address[]) public voters;
    
    PolvenStaking public stacking;
    
    constructor(address _stacking) public {
        counter = 0;
        stacking = PolvenStaking(_stacking);
    }
    
    function create(uint256 expirationDate, string memory title, string memory description) external onlyOwner {
        require(expirationDate > block.timestamp, "Incorrect expiration date");
        
        if(counter > 0) {
            require(getProposalStatus(counter) == ProposalStatus.CLOSED, "The previous vote is not over yet");
        }
        
        counter++;
        
        proposals[counter].expirationDate = expirationDate;
        proposals[counter].title = title;
        proposals[counter].description = description;
        proposals[counter].adminStatus = AdminStatus.OPEN;
        proposals[counter].yes = 0;
        proposals[counter].no = 0;
        proposals[counter].abstained = 0;
        
        emit CreateVote(expirationDate, title, description);
    }
    
    function closeLastProposal() external onlyOwner {
        proposals[counter].adminStatus = AdminStatus.CLOSED;
        
        emit CloseProposal(counter);
    }
    
    function voting(Choice _choice) external {
        require(getProposalStatus(counter) == ProposalStatus.OPEN, "Voting closed");
        require(isVoted(msg.sender) == false, "Account has already been voted");

        uint256 stakesAmount;
        uint256 stakesTimeframeAmount;
        (stakesAmount,) = stacking.userStakes(msg.sender);
        (stakesTimeframeAmount,,) = stacking.userStakesTimeframe(msg.sender);
        
        uint256 sum = stakesAmount + stakesTimeframeAmount;
        require(sum > 0, "You have no staked tokens");
        require(counter > 0, "Proposal has not been created yet");
        
        votes[counter][msg.sender].count = sum;
        votes[counter][msg.sender].choice = _choice;
        
        Proposal memory _proposal = proposals[counter];
        
        if(_choice == Choice.YES) {
            proposals[counter].yes = _proposal.yes.add(sum);
        }else if(_choice == Choice.NO) {
            proposals[counter].no = _proposal.no.add(sum);
        } else {
            proposals[counter].abstained = _proposal.abstained.add(sum);
        }
        
        voters[counter].push(msg.sender);
        
        emit Voting (_choice, msg.sender, sum, counter);
    }
    
    function getCounter() public view returns (uint256) {
        return counter;
    }
    
    function getLastProposal() public view returns(uint256, string memory, string memory, uint256, uint256, uint256, ProposalStatus) {
        return getItem(counter);
    }
    
    function getProposal(uint256 index) public view returns(uint256, string memory, string memory, uint256, uint256, uint256, ProposalStatus) {
        require(index > 0, "");
        require(index <= counter, "");
        return getItem(index);
    }

    function isVoted(address voter) public view returns (bool) {
        return votes[counter][voter].count != 0;
    }
    
    function getVoteForLastProposal() public view returns (uint256, Choice) {
        return getVote(counter, msg.sender);
    }
    
    function getVote(uint256 index, address voter) public view returns (uint256, Choice) {
        return (votes[index][voter].count, votes[index][voter].choice);
    }
    
    function getVotersForLastProposal() public view returns (address [] memory) {
        return getVoters(counter);
    }
    
    function getVoters(uint256 index) public view returns (address [] memory) {
        return voters[index];
    }
  
    function getItem(uint256 index) private view returns(uint256, string memory, string memory, uint256, uint256, uint256, ProposalStatus) {
        return (proposals[index].expirationDate, 
        proposals[index].title, 
        proposals[index].description, 
        proposals[index].yes, 
        proposals[index].no, 
        proposals[index].abstained,
        getProposalStatus(index));
    }
    
    function getProposalStatus(uint256 index) private view returns(ProposalStatus) {
        if(proposals[index].adminStatus == AdminStatus.CLOSED) {
            return ProposalStatus.CLOSED;
        }
     
        if(proposals[index].expirationDate <= block.timestamp) {
            return ProposalStatus.CLOSED;
        }
     
        return ProposalStatus.OPEN;
    }
}