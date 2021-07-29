/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

pragma solidity >0.8.0;


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

contract Election {
    using SafeMath for uint;
    // Model a proposal
    struct Proposal {
        uint id;
        string title;
        string description;
        // Store vote Count
        uint voteCount;
        // created at
        uint256 createdTime;
        //start date
        uint256 startTime;
        //end date
        uint256 endTime;
    }
    // Model a vote
    struct Vote{
        bool voted;
        bool opinion;
    }
    // Store accounts that have voted
    mapping(uint256=>mapping(address => Vote)) public voters;
    // Store Candidates
    // Fetch Candidate
    Proposal[] public proposals;
    
    uint256 public proposalCount = 0;
    
    mapping(address=>bool) public isAdmin;

    // add proposal event
    event proposalCreatedEvent (
        uint indexed _proposalId
    );

    // voted event
    event votedEvent (
        uint indexed _proposalId,
        address indexed voter,
        bool indexed opinion
    );

    constructor () public {
        isAdmin[msg.sender] = true;
    }
    
    function setAdmin(address newAdmin,bool enable) public {
        if(enable && isAdmin[msg.sender])
        {
            isAdmin[msg.sender] = true;
        }
        else if(!enable && isAdmin[msg.sender] && msg.sender == newAdmin)
        {
            isAdmin[msg.sender] = false;
        }
    }

    function addProposal (string memory _title,string memory _description,uint256 startTime,uint256 endTime) public {
        require(isAdmin[msg.sender], "Only admin can add a new proposal");
        proposalCount++;
        proposals.push(Proposal(proposalCount, _title, _description, 0, block.timestamp, startTime, endTime));
    }
    
    function getStatus (uint _proposalId) public view returns(uint8 status){
        status = 1; // pending
        if(proposals[_proposalId].startTime.add(proposals[_proposalId].createdTime) <= block.timestamp)
        {
            if(proposals[_proposalId].endTime.add(proposals[_proposalId].createdTime) >= block.timestamp)
            {
                status = 2; //active; 
            }
            else
            {
                status = 0; //close
            }
        }
    }

    function vote (uint _proposalId, bool opinion) public {
        // require that the proposal is active
        require(getStatus(_proposalId) == 2);
        // require that they haven't voted before
        require(!voters[_proposalId][msg.sender].voted);

        // require a valid candidate
        require(_proposalId > 0 && _proposalId <= proposals.length);

        // record that voter has voted
        voters[_proposalId][msg.sender].opinion = opinion;

        // update candidate vote Count
        proposals[_proposalId].voteCount ++;

        // trigger voted event
        emit votedEvent(_proposalId, msg.sender, opinion);
    }
}