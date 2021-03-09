/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

// We will be using Solidity version 0.5.4
// pragma solidity 0.5.4;
// Importing OpenZeppelin's SafeMath Implementation
// import 'https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol';

contract Crowdfunding {
    // using SafeMath for uint256;

    // List of existing projects
    Project[] private projects;

    // Event that will be emitted whenever a new project is started
    event ProjectStarted(
        address contractAddress,
        address projectStarter,
        string projectTitle,
        string projectDesc,
        uint256 deadline,
        uint256 goalAmount
    );

    function startProject(
        string calldata title,
        string calldata description,
        uint256 durationInDays,
        uint256 amountToRaise
    ) external {
        uint256 raiseUntil = block.timestamp +(durationInDays * (1 days));
        Project newProject =
            new Project(
                msg.sender,
                title,
                description,
                raiseUntil,
                amountToRaise
            );
        projects.push(newProject);
        emit ProjectStarted(
            address(newProject),
            msg.sender,
            title,
            description,
            raiseUntil,
            amountToRaise
        );
    }

    function returnAllProjects() external view returns (Project[] memory) {
        return projects;
    }
}

contract Project {
    // using SafeMath for uint256;

    // Data structures
    enum State {Fundraising, Expired, Successful}

    // State variables
    address payable public creator;
    uint256 public amountGoal; // required to reach at least this much, else everyone gets refund
    uint256 public completeAt;
    uint256 public currentBalance;
    uint256 public raiseBy;
    string public title;
    string public description;
    State public state = State.Fundraising; // initialize on create
    mapping(address => uint256) public contributions;

    // Event that will be emitted whenever funding will be received
    event FundingReceived(
        address contributor,
        uint256 amount,
        uint256 currentTotal
    );
    // Event that will be emitted whenever the project starter has received the funds
    event CreatorPaid(address recipient);

    // Modifier to check current state
    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    // Modifier to check if the function caller is the project creator
    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    constructor(
        address payable projectStarter,
        string memory projectTitle,
        string memory projectDesc,
        uint256 fundRaisingDeadline,
        uint256 goalAmount
    ) public {
        creator = projectStarter;
        title = projectTitle;
        description = projectDesc;
        amountGoal = goalAmount;
        raiseBy = fundRaisingDeadline;
        currentBalance = 0;
    }

    function contribute() external payable inState(State.Fundraising) {
        require(msg.sender != creator);
        contributions[msg.sender] = contributions[msg.sender] + (msg.value);
        currentBalance = currentBalance + (msg.value);
        emit FundingReceived(msg.sender, msg.value, currentBalance);
        checkIfFundingCompleteOrExpired();
    }

    function checkIfFundingCompleteOrExpired() public {
        if (currentBalance >= amountGoal) {
            state = State.Successful;
            payOut();
        } else if (block.timestamp  > raiseBy) {
            state = State.Expired;
        }
        completeAt = block.timestamp ;
    }

    function payOut() internal inState(State.Successful) returns (bool) {
        uint256 totalRaised = currentBalance;
        currentBalance = 0;

        if (creator.send(totalRaised)) {
            emit CreatorPaid(creator);
            return true;
        } else {
            currentBalance = totalRaised;
            state = State.Successful;
        }

        return false;
    }

    function getRefund() public inState(State.Expired) returns (bool) {
        require(contributions[msg.sender] > 0);

        uint256 amountToRefund = contributions[msg.sender];
        contributions[msg.sender] = 0;

        if (!msg.sender.send(amountToRefund)) {
            contributions[msg.sender] = amountToRefund;
            return false;
        } else {
            currentBalance = currentBalance-(amountToRefund);
        }

        return true;
    }

    function getDetails()
        public
        view
        returns (
            address payable projectStarter,
            string memory projectTitle,
            string memory projectDesc,
            uint256 deadline,
            State currentState,
            uint256 currentAmount,
            uint256 goalAmount
        )
    {
        projectStarter = creator;
        projectTitle = title;
        projectDesc = description;
        deadline = raiseBy;
        currentState = state;
        currentAmount = currentBalance;
        goalAmount = amountGoal;
    }
}