// Dependency file: contracts/interfaces/IERC20.sol

// pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// Dependency file: contracts/ballots/DemaxBallot.sol

// pragma solidity >=0.6.6;

// import '../interfaces/IERC20.sol';

/**
 * @title DemaxBallot
 * @dev Implements voting process along with vote delegation
 */
contract DemaxBallot {

    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
    }

    mapping(address => Voter) public voters;
    mapping(uint => uint) public proposals;

    address public governor;
    address public proposer;
    uint public value;
    uint public endBlockNumber;
    bool public ended;
    string public subject;
    string public content;

    uint private constant NONE = 0;
    uint private constant YES = 1;
    uint private constant NO = 2;

    uint public total;
    uint public createTime;

    modifier onlyGovernor() {
        require(msg.sender == governor, 'DemaxBallot: FORBIDDEN');
        _;
    }

    /**
     * @dev Create a new ballot.
     */
    constructor(address _proposer, uint _value, uint _endBlockNumber, address _governor, string memory _subject, string memory _content) public {
        proposer = _proposer;
        value = _value;
        endBlockNumber = _endBlockNumber;
        governor = _governor;
        subject = _subject;
        content = _content;
        proposals[YES] = 0;
        proposals[NO] = 0;
        createTime = block.timestamp;
    }

    /**
     * @dev Give 'voter' the right to vote on this ballot.
     * @param voter address of voter
     */
    function _giveRightToVote(address voter) private returns (Voter storage) {
        require(block.number < endBlockNumber, "Bollot is ended");
        Voter storage sender = voters[voter];
        require(!sender.voted, "You already voted");
        sender.weight += IERC20(governor).balanceOf(voter);
        require(sender.weight != 0, "Has no right to vote");
        return sender;
    }

    /**
     * @dev Delegate your vote to the voter 'to'.
     * @param to address to which vote is delegated
     */
    function delegate(address to) public {
        Voter storage sender = _giveRightToVote(msg.sender);
        require(to != msg.sender, "Self-delegation is disallowed");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            proposals[delegate_.vote] += sender.weight;
            total += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
            total += sender.weight;
        }
    }

    /**
     * @dev Give your vote (including votes delegated to you) to proposal 'proposals[proposal].name'.
     * @param proposal index of proposal in the proposals array
     */
    function vote(uint proposal) public {
        Voter storage sender = _giveRightToVote(msg.sender);
        require(proposal==YES || proposal==NO, 'Only vote 1 or 2');
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal] += sender.weight;
        total += sender.weight;
    }

    /**
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return winningProposal_ index of winning proposal in the proposals array
     */
    function winningProposal() public view returns (uint) {
        if (proposals[YES] > proposals[NO]) {
            return YES;
        } else if (proposals[YES] < proposals[NO]) {
            return NO;
        } else {
            return NONE;
        }
    }

    function result() public view returns (bool) {
        uint winner = winningProposal();
        if (winner == YES) {
            return true;
        }
        return false;
    }

    function end() public onlyGovernor returns (bool) {
        require(block.number >= endBlockNumber, "ballot not yet ended");
        require(!ended, "end has already been called");
        ended = true;
        return result();
    }

    function weight(address user) external view returns (uint) {
        Voter memory voter = voters[user];
        return voter.weight;
    }

}

// Dependency file: contracts/modules/Governable.sol

// pragma solidity >=0.5.16;

contract Governable {
    address public governor;

    event ChangeGovernor(address indexed _old, address indexed _new);

    modifier onlyGovernor() {
        require(msg.sender == governor, 'Governable: FORBIDDEN');
        _;
    }

    // called after deployment
    function initGovernorAddress(address _governor) internal {
        require(governor == address(0), 'Governable: INITIALIZED');
        require(_governor != address(0), 'Governable: INPUT_ADDRESS_IS_ZERO');
        governor = _governor;
    }

    function changeGovernor(address _new) public onlyGovernor {
        _changeGovernor(_new);
    }

    function _changeGovernor(address _new) internal {
        require(_new != address(0), 'Governable: INVALID_ADDRESS');
        require(_new != governor, 'Governable: NO_CHANGE');
        address old = governor;
        governor = _new;
        emit ChangeGovernor(old, _new);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;

// import '../modules/Governable.sol';
// import "./DemaxBallot.sol";

contract DemaxBallotFactory is Governable {

    event Created(address indexed proposer, address indexed ballotAddr, uint createTime);

    constructor (address _governor) public {
        initGovernorAddress(_governor);
    }

    function create(address _proposer, uint _value, uint _endBlockNumber, string calldata _subject, string calldata _content) external onlyGovernor returns (address) {
        require(_value >= 0 && _endBlockNumber > block.number, 'DemaxBallotFactory: INVALID_PARAMTERS');
        address ballotAddr = address(
            new DemaxBallot(_proposer, _value, _endBlockNumber, governor, _subject, _content)
        );
        emit Created(_proposer, ballotAddr, block.timestamp);
        return ballotAddr;
    }
}