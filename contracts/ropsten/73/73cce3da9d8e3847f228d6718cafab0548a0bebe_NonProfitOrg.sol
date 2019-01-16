pragma solidity ^0.4.25;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract DummyVoter is Ownable {
    function giveProjectMoreVotes(address project, uint256 votes) public {
        NonProfitOrg(owner()).giveProjectMoreVotes(project, votes);
    }
}

contract NonProfitOrg is Ownable {

    DummyVoter[] public dummyVoters;
    
    enum VotingStage {
        Initial,
        Open,
        Closed
    }
    
    VotingStage public stage;

    uint256 public totalVotes;
    
    uint256 public votesLeftToAssign;
    
    uint256 public totalVotesGiven;
    
    mapping (address => uint256) public voterVotesLeftToGive;

    mapping (address => bool) public isProject;
    
    address[] public projects;
    
    mapping (address => uint256) public projectVotes;
    
    function markAsProject(address project) public onlyOwner {
        require(stage == VotingStage.Initial, "Wrong state");
        require(!isProject[project], "Cannot add project twice");
        isProject[project] = true;
        projects.push(project);
    }
    
    function assignVoterMoreVotes(address voter, uint256 count) public onlyOwner {
        require(stage == VotingStage.Initial, "Wrong state");
        require(count <= votesLeftToAssign, "Not enough votes");
        voterVotesLeftToGive[voter] = SafeMath.add(voterVotesLeftToGive[voter], count);
        votesLeftToAssign = SafeMath.sub(votesLeftToAssign, count);
    }

    function openVoting() public onlyOwner {
        require(stage == VotingStage.Initial, "Wrong state");
        require(votesLeftToAssign == 0, "Some votes have not been assigned to a voter");
        stage = VotingStage.Open;
    }
    
    function giveProjectMoreVotes(address project, uint256 votes) public {
        require(stage == VotingStage.Open, "Wrong state");
        require(isProject[project], "Not a project");
        require(votes <= voterVotesLeftToGive[msg.sender], "Not enough votes");
        voterVotesLeftToGive[msg.sender] = SafeMath.sub(voterVotesLeftToGive[msg.sender], votes);
        projectVotes[project] = SafeMath.add(projectVotes[project], votes);
        totalVotesGiven = SafeMath.add(totalVotesGiven, votes);
    }
    
    function closeVoting() public onlyOwner {
        require(stage == VotingStage.Open, "Wrong state");
        require(totalVotesGiven == totalVotes, "Some voters still have votes to give");
        stage = VotingStage.Closed;
    }
    
    event ChangeGiven(uint256 amount);
    
    function donate() public payable {
        uint256 amountLeft = msg.value;
        for (uint256 i = 0; i < projects.length; i++) {
            address project = projects[i];
            uint256 votes = projectVotes[project];
            uint256 donation = SafeMath.div(SafeMath.mul(msg.value, votes), totalVotes);
            amountLeft = SafeMath.sub(amountLeft, donation);
            project.transfer(donation);
        }
        msg.sender.transfer(amountLeft);
        emit ChangeGiven(amountLeft);
    }

    address constant ADDRESS_2 = 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c;
    address constant ADDRESS_3 = 0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db;
    address constant ADDRESS_4 = 0x583031d1113ad414f02576bd6afabfb302140225;
    address constant ADDRESS_5 = 0xdd870fa1b7c4700f2bd7f44238821c26f7392148;

    address constant ADDRESS_6 = 0x6e135d053bfdabb3a68f005c2f5fbb4060d4eed3;
    address constant ADDRESS_7 = 0xd5573a959cf43e020c57ac60f0365abfa3662d40;
    address constant ADDRESS_8 = 0x0b0f68037f1389b6f5f96dd1f4ef6e422bd1a6b0;
    address constant ADDRESS_9 = 0x5fbe066c10f7257253b6a379f0bf52610365be34;
    
    address constant PROJECT_1 = ADDRESS_2;
    address constant PROJECT_2 = ADDRESS_3;
    address constant PROJECT_3 = ADDRESS_4;
    address constant PROJECT_4 = ADDRESS_5;
    
    address constant VOTER_1 = ADDRESS_6;
    address constant VOTER_2 = ADDRESS_7;
    address constant VOTER_3 = ADDRESS_8;
    address constant VOTER_4 = ADDRESS_9;
    
    constructor() public {
        totalVotes = 100;  // This will come as an argument
        votesLeftToAssign = totalVotes;
        totalVotesGiven = 0;
    }
    
    // function test() public {
    //     markAsProject(PROJECT_1);
    //     markAsProject(PROJECT_2);
    //     markAsProject(PROJECT_3);
    //     markAsProject(PROJECT_4);

    //     DummyVoter voter1 = new DummyVoter();
    //     DummyVoter voter2 = new DummyVoter();
    //     DummyVoter voter3 = new DummyVoter();
    //     DummyVoter voter4 = new DummyVoter();
        
    //     // Only for debugging
    //     dummyVoters.push(voter1);
    //     dummyVoters.push(voter2);
    //     dummyVoters.push(voter3);
    //     dummyVoters.push(voter4);
        
    //     assignVoterMoreVotes(voter1, 50);
    //     assignVoterMoreVotes(voter2, 25);
    //     assignVoterMoreVotes(voter3, 15);
    //     assignVoterMoreVotes(voter4, 10);
        
    //     // giveProjectMoreVotes()
    //     openVoting();
        
    //     voter1.giveProjectMoreVotes(PROJECT_1, 20);
    //     voter1.giveProjectMoreVotes(PROJECT_2, 10);
    //     voter1.giveProjectMoreVotes(PROJECT_3, 10);
    //     voter1.giveProjectMoreVotes(PROJECT_4, 10);
        
    //     voter2.giveProjectMoreVotes(PROJECT_1, 10);
    //     voter2.giveProjectMoreVotes(PROJECT_2, 5);
    //     voter2.giveProjectMoreVotes(PROJECT_3, 5);
    //     voter2.giveProjectMoreVotes(PROJECT_4, 5);
        
    //     voter3.giveProjectMoreVotes(PROJECT_1, 6);
    //     voter3.giveProjectMoreVotes(PROJECT_2, 3);
    //     voter3.giveProjectMoreVotes(PROJECT_3, 3);
    //     voter3.giveProjectMoreVotes(PROJECT_4, 3);
        
    //     voter4.giveProjectMoreVotes(PROJECT_1, 4);
    //     voter4.giveProjectMoreVotes(PROJECT_2, 2);
    //     voter4.giveProjectMoreVotes(PROJECT_3, 2);
    //     voter4.giveProjectMoreVotes(PROJECT_4, 2);
        
    //     closeVoting();
    // }
    
    
    function bulkInit(address[] _projects, address[] _voters, uint256[] _votes) public onlyOwner {
        for (uint256 i = 0; i < _projects.length; i++) {
            markAsProject(_projects[i]);
        }
        require(_voters.length == _votes.length, "Arrays have unequal lengths");
        for (uint256 j = 0; j < _voters.length; j++) {
            assignVoterMoreVotes(_voters[j], _votes[j]);
        }
        openVoting();
    }
    
    function bulkVote(uint256[] _votes) public {
        require(_votes.length == projects.length, "Wrong array length");
        for (uint256 i = 0; i < projects.length; i++) {
            giveProjectMoreVotes(projects[i], _votes[i]);
        }        
    }

}

contract Util {
    function getBalance() public view returns (uint256) {
        return address(msg.sender).balance;   
    }
}