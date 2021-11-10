/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

// File: https://github.com/adorsys/p2p-lending/blob/master/contracts/ProposalManagement/ContractFeeProposal.sol

pragma solidity ^0.5.0;

contract ContractFeeProposal {
    mapping(address => bool) private voted;

    address payable private management;
    uint8 private majorityMargin;
    uint16 private minimumNumberOfVotes;
    uint16 public numberOfVotes;
    uint16 public numberOfPositiveVotes;
    uint256 public proposedFee;
    bool public proposalPassed;
    bool public proposalExecuted;

    constructor(
        uint256 _proposedFee,
        uint16 _minimumNumberOfVotes,
        uint8 _majorityMargin,
        address payable _managementContract
    ) public {
        proposedFee = _proposedFee;
        minimumNumberOfVotes = _minimumNumberOfVotes;
        majorityMargin = _majorityMargin;
        management = _managementContract;
    }

    /**
     * @notice destroys the proposal contract and forwards the remaining funds to the management contract
     */
    function kill() external {
        require(msg.sender == management, "invalid caller");
        require(proposalExecuted, "!executed");
        selfdestruct(management);
    }

    /**
     * @notice registers a vote for the proposal and triggers execution if conditions are met
     * @param _stance true for a positive vote - false otherwise
     * @param _origin the address of the initial function call
     * @return propPassed true if proposal met the required number of positive votes - false otherwise
     * @return propExecuted true if proposal met the required minimum number of votes - false otherwise
     */
    function vote(bool _stance, address _origin) external returns (bool propPassed, bool propExecuted) {
        // check input parameters
        require(msg.sender == management, "invalid caller");
        require(!proposalExecuted, "executed");
        require(!voted[_origin], "second vote");

        // update internal state
        voted[_origin] = true;
        numberOfVotes += 1;
        if (_stance) numberOfPositiveVotes++;

        // check if execution of proposal should be triggered and update return values
        if ((numberOfVotes >= minimumNumberOfVotes)) {
            execute();
            propExecuted = true;
            propPassed = proposalPassed;
        }
    }

    /**
     * @notice executes the proposal and updates the internal state
     */
    function execute() private {
        // check internal state
        require(!proposalExecuted, "executed");
        require(
            numberOfVotes >= minimumNumberOfVotes,
            "cannot execute"
        );

        // update the internal state
        proposalExecuted = true;
        proposalPassed = ((numberOfPositiveVotes * 100) / numberOfVotes) >= majorityMargin;
    }
}

// File: https://github.com/adorsys/p2p-lending/blob/master/contracts/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: https://github.com/adorsys/p2p-lending/blob/master/contracts/IcoContract/EIP20Interface.sol

// Directory: P2P-Lending/contracts/IcoContract/EIP20Interface.sol
// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
pragma solidity ^0.5.0; // Solidity compiler version

contract EIP20Interface {
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice Send '_value' token to '_to' from 'msg.sender'
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice Send '_value' token to '_to' from '_from' on the condition it is approved by '_from'
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice 'msg.sender' approves '_spender' to spend '_value' tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // Display transactions and approvals
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// File: lending.sol

pragma solidity ^0.5.0;                                                                             // Solidity compiler version



contract TrustToken is EIP20Interface {
    using SafeMath for uint256;

    modifier calledByProposalManagement {
        require(msg.sender == proposalManagement, "invalid caller");
        _;
    }

    mapping (address => bool) public isUserLocked;                              // are token of address locked
    mapping (address => uint256) private tokenBalances;                         // token balance of trustees
    mapping (address => uint256) public etherBalances;                          // invested ether of trustees
    mapping (address => mapping (address => uint256)) public allowed;           // register of all permissions form one user to another
    mapping (address => bool) public isTrustee;

    address public proposalManagement;
    address[] public participants;
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint256 public trusteeCount;
    uint256 public goal = 10 ether;
    uint256 public contractEtherBalance;
    uint8 public decimals;
    bool public isIcoActive;

    /// Display transactions and approvals
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    /// Track Participation & ICO Status
    event Participated();
    event ICOFinished();

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) public {
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
        totalSupply = _initialAmount.mul(10 ** uint256(decimals));
        isIcoActive = true;
    }

    /**
     * @notice Sets the proposalManagement address
     * @param _management The address of the proposalManagement
     */
    function setManagement(address _management) external {
        if (proposalManagement != address(0)) {
            require(msg.sender == proposalManagement, "invalid caller");
        }
        proposalManagement = _management;
    }

    /**
     * @notice Locks the token of '_user'
     * @param _user Address of user to lock
     */
    function lockUser(address _user) external calledByProposalManagement returns(bool) {
        isUserLocked[_user] = true;
        return isUserLocked[_user];
    }

    /**
     * @notice Unlocks token of a list of users
     * @param _users List of users to unlock
     */
    function unlockUsers(address[] calldata _users) external calledByProposalManagement {
        for(uint256 i; i < _users.length; i++) {
            isUserLocked[_users[i]] = false;
        }
    }

    /**
     * @notice Invest Ether to become a Trustee and get token when ICO finishes
     */
    function participate () external payable {
        require(isIcoActive, "ICO inactive");

        uint256 allowedToAdd = msg.value;
        uint256 returnAmount;

        if( (contractEtherBalance.add(msg.value)) > goal) {                     // update allowedToAdd when goal is reached
            allowedToAdd = goal.sub(contractEtherBalance);
            returnAmount = msg.value.sub(allowedToAdd);                         // save the amount of ether that is to be returned afterwards
        }

        etherBalances[msg.sender] = etherBalances[msg.sender].add(allowedToAdd);
        contractEtherBalance = contractEtherBalance.add(allowedToAdd);

        if(!isTrustee[msg.sender]) {
            participants.push(msg.sender);                                      // add msg.sender to participants
            isTrustee[msg.sender] = true;
        }

        emit Participated();

        if(contractEtherBalance >= goal) {                                      // distribute token after goal was reached
            isIcoActive = false;
            trusteeCount = participants.length;
            distributeToken();
            emit ICOFinished();
        }

        if (returnAmount > 0) {
            msg.sender.transfer(returnAmount);                                  // transfer ether over limit back to sender
        }
    }

    /**
     * @notice Send '_value' token to '_to' from 'msg.sender'
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(tokenBalances[msg.sender] >= _value, "insufficient funds");

        tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(_value);
        tokenBalances[_to] = tokenBalances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        if (!isTrustee[_to]) {
            trusteeCount = trusteeCount.add(1);
            isTrustee[_to] = true;                                              // register recipient as new trustee
        }

        if (tokenBalances[msg.sender] == 0) {
            isTrustee[msg.sender] = false;                                      // remove sender from trustees if balance of token equals zero
            trusteeCount = trusteeCount.sub(1);
        }

        return true;
    }

    /**
     * @notice Send '_value' token to '_to' from '_from' on the condition it is approved by '_from'
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        uint256 allowance = allowed[_from][msg.sender];
        require(allowance >= _value, "insufficient allowance");
        require(tokenBalances[_from] >= _value, "invalid transfer amount");

        tokenBalances[_to] = tokenBalances[_to].add(_value);
        tokenBalances[_from] = tokenBalances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        if (!isTrustee[_to]) {
            trusteeCount = trusteeCount.add(1);                                                     // register recipient as new trustee
            isTrustee[_to] = true;
        }

        if (tokenBalances[_from] == 0) {
            isTrustee[_from] = false;                                                               // remove sender from trustees if balance of token equals zero
            trusteeCount = trusteeCount.sub(1);
        }

        return true;
    }

    /**
     * @notice 'msg.sender' approves '_spender' to spend '_value' tokens
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(balanceOf(msg.sender) >= _value, "insufficient funds");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * @param _owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return tokenBalances[_owner];
    }

    /**
     * @notice get all initialization parameters for ico contract
     */
    function getICOParameters()
        public
        view
        returns
            (uint256 icoGoal, uint256 icoEtherBalance, bool isActive, uint256 totalTokenSupply,
             uint256 icoParticipantCount, string memory tokenSymbol, uint256 tokenBalanceUser,
             uint256 etherBalanceUser, string memory icoName, uint256 numDecimals, uint256 numTrustees)
    {
            icoGoal = goal;
            icoEtherBalance = address(this).balance;
            isActive = isIcoActive;
            totalTokenSupply = totalSupply;
            icoParticipantCount = participants.length;
            tokenSymbol = symbol;
            tokenBalanceUser = balanceOf(msg.sender);
            etherBalanceUser = getEtherBalances();
            icoName = name;
            numDecimals = decimals;
            numTrustees = trusteeCount;
    }

    /**
     * @return Ether balance of 'msg.sender'
     */
    function getEtherBalances() public view returns(uint256) {
        return etherBalances[msg.sender];
    }

    /**
     * @notice Distribute tokenSupply between all Trustees
     */
    function distributeToken() private {
        for(uint256 i; i < participants.length; i++) {
            tokenBalances[participants[i]] = (etherBalances[participants[i]].mul(totalSupply)).div(contractEtherBalance);
            emit Transfer(address(this), participants[i], tokenBalances[participants[i]]);
        }
    }
}
pragma solidity ^0.5.0;

interface TrustTokenInterface {
    function setManagement(address) external;
    function isTrustee(address) external view returns(bool);
    function trusteeCount() external view returns(uint256);
    function lockUser(address) external returns(bool);
    function unlockUsers(address[] calldata) external;
}

interface ProposalFactoryInterface {
    function newContractFeeProposal(uint256, uint16, uint8) external returns(address);
    function newMemberProposal(address, bool, uint256, uint8) external returns(address);
}

interface ContractFeeProposalInterface {
    function vote(bool, address) external returns(bool, bool);
    function proposedFee() external view returns(uint256);
    function kill() external;
}

interface MemberProposalInterface {
    function vote(bool, address) external returns(bool, bool);
    function memberAddress() external view returns(address);
    function kill() external;
}

contract ProposalManagement {
    /*
     * proposalType == 0 -> invalid proposal
     * proposalType == 1 -> contractFee proposal
     * proposalType == 2 -> addMember proposal
     * proposalType == 3 -> removeMember proposal
     */
    mapping(address => uint256) public proposalType;
    mapping(address => uint256) public memberId;
    mapping(address => address[]) private lockedUsersPerProposal;
    mapping(address => uint256) private userProposalLocks;
    mapping(address => address[]) private unlockUsers;
    mapping(address => uint256) private proposalIndex;

    address[] private proposals;
    address private trustTokenContract;
    address private proposalFactory;
    uint256 public contractFee;
    uint16 public minimumNumberOfVotes = 1;
    uint8 public majorityMargin = 50;
    address[] public members;

    event ProposalCreated();
    event ProposalExecuted();
    event NewContractFee();
    event MembershipChanged();

    constructor(address _proposalFactoryAddress, address _trustTokenContract) public {
        members.push(address(0));
        memberId[msg.sender] = members.length;
        members.push(msg.sender);
        contractFee = 1 ether;
        proposalFactory = _proposalFactoryAddress;
        trustTokenContract = _trustTokenContract;
        TrustTokenInterface(trustTokenContract).setManagement(address(this));
    }

    /**
     * @notice creates a proposal contract to change the fee used in LendingRequests
     * @param _proposedFee the new fee
     */
    function createContractFeeProposal(uint256 _proposedFee) external {
        // validate input
        require(memberId[msg.sender] != 0, "not a member");
        require(_proposedFee > 0, "invalid fee");

        address proposal = ProposalFactoryInterface(proposalFactory)
            .newContractFeeProposal(_proposedFee, minimumNumberOfVotes, majorityMargin);

        // add created proposal to management structure and set correct proposal type
        proposalIndex[proposal] = proposals.length;
        proposals.push(proposal);
        proposalType[proposal] = 1;

        emit ProposalCreated();
    }

    /**
     * @notice creates a proposal contract to change membership status for the member
     * @param _memberAddress the address of the member
     * @param _adding true if member is to be added false otherwise
     * @dev only callable by registered members
     */
    function createMemberProposal(address _memberAddress, bool _adding) external {
        // validate input
        require(TrustTokenInterface(trustTokenContract).isTrustee(msg.sender), "invalid caller");
        require(_memberAddress != address(0), "invalid memberAddress");
        if(_adding) {
            require(memberId[_memberAddress] == 0, "cannot add twice");
        } else {
            require(memberId[_memberAddress] != 0, "no member");
        }

        uint256 trusteeCount = TrustTokenInterface(trustTokenContract).trusteeCount();
        address proposal = ProposalFactoryInterface(proposalFactory).newMemberProposal(_memberAddress, _adding, trusteeCount, majorityMargin);

        // add created proposal to management structure and set correct proposal type
        proposalIndex[proposal] = proposals.length;
        proposals.push(proposal);
        proposalType[proposal] = _adding ? 2 : 3;

        emit ProposalCreated();
    }

    /**
     * @notice vote for a proposal at the specified address
     * @param _stance true if you want to cast a positive vote, false otherwise
     * @param _proposalAddress the address of the proposal you want to vote for
     * @dev only callable by registered members
     */
    function vote(bool _stance, address _proposalAddress) external {
        // validate input
        uint256 proposalParameter = proposalType[_proposalAddress];
        require(proposalParameter != 0, "Invalid address");

        bool proposalPassed;
        bool proposalExecuted;

        if (proposalParameter == 1) {
            require(memberId[msg.sender] != 0, "not a member");

            (proposalPassed, proposalExecuted) = ContractFeeProposalInterface(_proposalAddress).vote(_stance, msg.sender);
        } else if (proposalParameter == 2 || proposalParameter == 3) {
            require(TrustTokenInterface(trustTokenContract).isTrustee(msg.sender), "invalid caller");
            require(TrustTokenInterface(trustTokenContract).lockUser(msg.sender), "userlock failed");

            (proposalPassed, proposalExecuted) = MemberProposalInterface(_proposalAddress).vote(_stance, msg.sender);
            lockedUsersPerProposal[_proposalAddress].push(msg.sender);

            // update number of locks for voting user
            userProposalLocks[msg.sender]++;
        }

        emit ProposalExecuted();

        // handle return values of voting call
        if (proposalExecuted) {
            require(
                handleVoteReturn(proposalParameter, proposalPassed, _proposalAddress),
                "voteReturn failed"
            );
        }
    }

    /**
     * @notice returns number of proposals
     * @return proposals.length
     */
    function getProposalsLength() external view returns (uint256) {
        return proposals.length;
    }

    /**
     * @notice returns all saved proposals
     * @return proposals or [] if empty
     */
    function getProposals() external view returns (address[] memory props) {
        return proposals.length != 0 ? proposals : props;
    }

    /**
     * @notice returns the number of current members
     * @return number of members
     */
    function getMembersLength() external view returns (uint256) {
        return members.length;
    }

    /**
     * @notice returns the proposal parameters
     * @param _proposal the address of the proposal to get the parameters for
     * @return proposalAddress the address of the queried proposal
     * @return propType the type of the proposal
     * @return proposalFee proposed contractFee if type is fee proposal
     * @return memberAddress address of the member if type is member proposal
     */
    function getProposalParameters(address _proposal)
        external
        view
        returns (address proposalAddress, uint256 propType, uint256 proposalFee, address memberAddress) {
        // verify input parameters
        propType = proposalType[_proposal];
        require(propType != 0, "invalid input");

        proposalAddress = _proposal;
        if (propType == 1) {
            proposalFee = ContractFeeProposalInterface(_proposal).proposedFee();
        } else if (propType == 2 || propType == 3) {
            memberAddress = MemberProposalInterface(_proposal).memberAddress();
        }
    }

    /**
     * @dev handles the return value of the vote function
     * @param _parameter internal representation of proposal type
     * @param _passed true if proposal passed false otherwise
     * @param _proposalAddress address of the proposal currently being executed
     */
    function handleVoteReturn(uint256 _parameter, bool _passed, address _proposalAddress)
        private returns (bool) {
        /// case: contractFeeProposal
        if (_parameter == 1) {
            if(_passed) {
                uint256 newContractFee = ContractFeeProposalInterface(_proposalAddress).proposedFee();
                // update contract fee
                contractFee = newContractFee;
                emit NewContractFee();
            }
            // remove proposal from management contract
            removeProposal(_proposalAddress);
            return true;

        /// case: memberProposal
        } else if (_parameter == 2 || _parameter == 3) {
            if(_passed) {
                address memberAddress = MemberProposalInterface(_proposalAddress).memberAddress();
                // add | remove member
                _parameter == 2 ? addMember(memberAddress) : removeMember(memberAddress);
            }
            // get locked users for proposal
            address[] memory lockedUsers = lockedUsersPerProposal[_proposalAddress];
            for(uint256 i; i < lockedUsers.length; i++) {
                // if user is locked for 1 proposal remember user for unlocking
                if (userProposalLocks[lockedUsers[i]] == 1) {
                    unlockUsers[_proposalAddress].push(lockedUsers[i]);
                }
                // decrease locked count for all users locked for the current proposal
                userProposalLocks[lockedUsers[i]]--;
            }
            TrustTokenInterface(trustTokenContract).unlockUsers(unlockUsers[_proposalAddress]);
            // remove proposal from mangement contract
            removeProposal(_proposalAddress);
            return true;
        }

        return false;
    }

    /**
     * @dev adds the member at the specified address to current members
     * @param _memberAddress the address of the member to add
     */
    function addMember(address _memberAddress) private {
        // validate input
        require(_memberAddress != address(0), "invalid address");
        require(memberId[_memberAddress] == 0, "already a member");

        memberId[_memberAddress] = members.length;
        members.push(_memberAddress);

        // if necessary: update voting parameters
        if (((members.length / 2) - 1) >= minimumNumberOfVotes) {
            minimumNumberOfVotes++;
        }

        emit MembershipChanged();
    }

    /**
     * @dev removes the member at the specified address from current members
     * @param _memberAddress the address of the member to remove
     */
    function removeMember(address _memberAddress) private {
        // validate input
        uint256 mId = memberId[_memberAddress];
        require(mId != 0, "no member");

        // move member to the end of members array
        memberId[members[members.length - 1]] = mId;
        members[mId] = members[members.length - 1];
        // removes last element of storage array
        members.pop();
        // mark memberId as invalid
        memberId[_memberAddress] = 0;

        // if necessary: update voting parameters
        if (((members.length / 2) - 1) <= minimumNumberOfVotes) {
            minimumNumberOfVotes--;
        }

        emit MembershipChanged();
    }

    /**
     * @notice removes the proposal from the management structures
     * @param _proposal address of the proposal to remove
     */
    function removeProposal(address _proposal) private {
        // validate input
        uint256 propType = proposalType[_proposal];
        require(propType != 0, "invalid request");
        if (propType == 1) {
            ContractFeeProposalInterface(_proposal).kill();
        } else if (propType == 2 || propType == 3) {
            MemberProposalInterface(_proposal).kill();
        }

        // remove _proposal from the management contract
        uint256 idx = proposalIndex[_proposal];
        if (proposals[idx] == _proposal) {
            proposalIndex[proposals[proposals.length - 1]] = idx;
            proposals[idx] = proposals[proposals.length - 1];
            proposals.pop();
        }

        // mark _proposal as invalid proposal
        proposalType[_proposal] = 0;
    }
}
pragma solidity ^0.5.0;

//import "https://github.com/adorsys/p2p-lending/blob/master/contracts/ProposalManagement/MemberProposal.sol";

contract ProposalFactory {
    /**
     * @notice creates a new contractFee proposal
     * @param _proposedFee the suggested new fee
     * @param _minimumNumberOfVotes the minimum number of votes needed to execute the proposal
     * @param _majorityMargin the percentage of positive votes needed for proposal to pass
     */
    function newContractFeeProposal(
        uint256 _proposedFee,
        uint16 _minimumNumberOfVotes,
        uint8 _majorityMargin
    ) external returns(address proposal) {
        proposal = address(
            new ContractFeeProposal(
                _proposedFee,
                _minimumNumberOfVotes,
                _majorityMargin,
                msg.sender
            )
        );
    }

    /**
     * @notice creates a new member proposal
     * @param _memberAddress address of the member
     * @param _adding true to add member - false to remove member
     * @param _trusteeCount the current number of TrustToken-Holders
     * @param _majorityMargin the percentage of positive votes needed for proposal to pass
     */
    function newMemberProposal(
        address _memberAddress,
        bool _adding,
        uint256 _trusteeCount,
        uint8 _majorityMargin
    ) external returns (address proposal) {
        // calculate minimum number of votes for member proposal
        uint256 minVotes = _trusteeCount / 2;

        // ensure that minVotes > 0
        minVotes = minVotes == 0 ? (minVotes + 1) : minVotes;

        proposal = address(
            new MemberProposal(
                _memberAddress,
                _adding,
                minVotes,
                _majorityMargin,
                msg.sender
            )
        );
    }
}
pragma solidity ^0.5.0;

contract MemberProposal {
    mapping(address => bool) private voted;

    address private management;
    address public memberAddress;
    bool public proposalPassed;
    bool public proposalExecuted;
    bool public adding;
    uint8 private majorityMargin;
    uint16 public numberOfVotes;
    uint16 public numberOfPositiveVotes;
    uint256 private minimumNumberOfVotes;

    constructor(
        address _memberAddress,
        bool _adding,
        uint256 _minimumNumberOfVotes,
        uint8 _majorityMargin,
        address _managementContract
    ) public {
        memberAddress = _memberAddress;
        adding = _adding;
        minimumNumberOfVotes = _minimumNumberOfVotes;
        majorityMargin = _majorityMargin;
        management = _managementContract;
    }

    /**
     * @notice destroys the proposal contract and forwards the remaining funds to the management contract
     */
    function kill() external {
        require(msg.sender == management, "invalid caller");
        require(proposalExecuted, "!executed");
        selfdestruct(msg.sender);
    }

    /**
     * @notice registers a vote for the proposal and triggers execution if conditions are met
     * @param _stance true for a positive vote - false otherwise
     * @param _origin the address of the initial function call
     * @return propPassed true if proposal met the required number of positive votes - false otherwise
     * @return propExecuted true if proposal met the required minimum number of votes - false otherwise
     */
    function vote(bool _stance, address _origin) external returns (bool propPassed, bool propExecuted) {
        // check input parameters
        require(msg.sender == management, "invalid caller");
        require(!proposalExecuted, "executed");
        require(!voted[_origin], "second vote");

        // update internal state
        voted[_origin] = true;
        numberOfVotes += 1;
        if (_stance) numberOfPositiveVotes++;

        // check if execution of proposal should be triggered and update return values
        if ((numberOfVotes >= minimumNumberOfVotes)) {
            execute();
            propExecuted = true;
            propPassed = proposalPassed;
        }
    }

    /**
     * @notice executes the proposal and updates the internal state
     */
    function execute() private {
        require(!proposalExecuted, "executed");
        require(
            numberOfVotes >= minimumNumberOfVotes,
            "cannot execute"
        );
        proposalExecuted = true;
        proposalPassed = ((numberOfPositiveVotes * 100) / numberOfVotes) >= majorityMargin;
    }
}
pragma solidity ^0.5.0;

interface RequestFactoryInterface {
    function createLendingRequest(uint256, uint256, string calldata, address payable) external returns(address);
}

interface LendingRequestInterface {
    function deposit(address payable) external payable returns(bool, bool);
    function withdraw(address) external;
    function cleanUp() external;
    function cancelRequest() external;
    function asker() external view returns(address payable);
    function withdrawnByLender() external view returns(bool);
    function getRequestParameters() external view returns(address payable, address payable, uint256, uint256, uint256, string memory);
    function getRequestState() external view returns(bool, bool, bool, bool);
}

contract RequestManagement {
    event RequestCreated();
    event RequestGranted();
    event DebtPaid();
    event Withdraw();

    mapping(address => uint256) private requestIndex;
    mapping(address => uint256) private userRequestCount;
    mapping(address => bool) private validRequest;

    address private requestFactory;
    address[] private lendingRequests;

    constructor(address _factory) public {
        requestFactory = _factory;
    }

    /**
     * @notice Creates a lending request for the amount you specified
     * @param _amount the amount you want to borrow in Wei
     * @param _paybackAmount the amount you are willing to pay back - has to be greater than _amount
     * @param _purpose the reason you want to borrow ether
     */
    function ask (uint256 _amount, uint256 _paybackAmount, string memory _purpose) public {
        // validate the input parameters
        require(_amount > 0, "invalid amount");
        require(_paybackAmount > _amount, "invalid payback");
        // require(lendingRequests[msg.sender].length < 5, "too many requests");
        require(userRequestCount[msg.sender] < 5, "too many requests");

        // create new lendingRequest
        address request = RequestFactoryInterface(requestFactory).createLendingRequest(
            _amount,
            _paybackAmount,
            _purpose,
            msg.sender
        );

        // update number of requests for asker
        userRequestCount[msg.sender]++;
        // add created lendingRequest to management structures
        requestIndex[request] = lendingRequests.length;
        lendingRequests.push(request);
        // mark created lendingRequest as a valid request
        validRequest[request] = true;

        emit RequestCreated();
    }

    /**
     * @notice Lend or payback the ether amount of the lendingRequest (costs ETHER)
     * @param _lendingRequest the address of the lendingRequest you want to deposit ether in
     */
    function deposit(address payable _lendingRequest) public payable {
        // validate input
        require(validRequest[_lendingRequest], "invalid request");
        require(msg.value > 0, "invalid value");

        (bool lender, bool asker) = LendingRequestInterface(_lendingRequest).deposit.value(msg.value)(msg.sender);
        require(lender || asker, "Deposit failed");

        if (lender) {
            emit RequestGranted();
        } else if (asker) {
            emit DebtPaid();
        }
    }

    /**
     * @notice withdraw Ether from the lendingRequest
     * @param _lendingRequest the address of the lendingRequest to withdraw from
     */
    function withdraw(address payable _lendingRequest) public {
        // validate input
        require(validRequest[_lendingRequest], "invalid request");

        LendingRequestInterface(_lendingRequest).withdraw(msg.sender);

        // if paybackAmount was withdrawn by lender reduce number of openRequests for asker
        if(LendingRequestInterface(_lendingRequest).withdrawnByLender()) {
            address payable asker = LendingRequestInterface(_lendingRequest).asker();
            // call selfdestruct of lendingRequest
            LendingRequestInterface(_lendingRequest).cleanUp();
            // remove lendingRequest from managementContract
            removeRequest(_lendingRequest, asker);
        }

        emit Withdraw();
    }

    /**
     * @notice cancels the request
     * @param _lendingRequest the address of the request to cancel
     */
    function cancelRequest(address payable _lendingRequest) public {
        // validate input
        require(validRequest[_lendingRequest], "invalid Request");

        LendingRequestInterface(_lendingRequest).cancelRequest();
        removeRequest(_lendingRequest, msg.sender);

        emit Withdraw();
    }

    /**
     * @notice gets the lendingRequests for the specified user
     * @return all lendingRequests
     */
    function getRequests() public view returns(address[] memory) {
        return lendingRequests;
    }

    /**
     * @notice gets askAmount, paybackAmount and purpose to given proposalAddress
     * @param _lendingRequest the address to get the parameters from
     * @return asker address of the asker
     * @return lender address of the lender
     * @return askAmount of the proposal
     * @return paybackAmount of the proposal
     * @return contractFee the contract fee for the lending request
     * @return purpose of the proposal
     * @return lent wheather the money was lent or not
     * @return debtSettled wheather the debt was settled by the asker
     */
    function getRequestParameters(address payable _lendingRequest)
        public
        view
        returns (address asker, address lender, uint256 askAmount, uint256 paybackAmount, uint256 contractFee, string memory purpose) {
        (asker, lender, askAmount, paybackAmount, contractFee, purpose) = LendingRequestInterface(_lendingRequest).getRequestParameters();
    }

    function getRequestState(address payable _lendingRequest)
        public
        view
        returns (bool verifiedAsker, bool lent, bool withdrawnByAsker, bool debtSettled) {
        return LendingRequestInterface(_lendingRequest).getRequestState();
    }

    /**
     * @notice removes the lendingRequest from the management structures
     * @param _request the lendingRequest that will be removed
     */
    function removeRequest(address _request, address _sender) private {
        // validate input
        require(validRequest[_request], "invalid request");

        // update number of requests for asker
        userRequestCount[_sender]--;
        // remove _request from the management contract
        uint256 idx = requestIndex[_request];
        if(lendingRequests[idx] == _request) {
            requestIndex[lendingRequests[lendingRequests.length - 1]] = idx;
            lendingRequests[idx] = lendingRequests[lendingRequests.length - 1];
            lendingRequests.pop();
        }
        // mark _request as invalid lendingRequest
        validRequest[_request] = false;
    }
}
pragma solidity ^0.5.0;

contract LendingRequest {
    address payable private managementContract;
    address payable private trustToken;
    address payable public asker;
    address payable public lender;
    bool private withdrawnByAsker;
    bool public withdrawnByLender;
    bool private verifiedAsker;
    bool public moneyLent;
    bool public debtSettled;
    uint256 public amountAsked;
    uint256 public paybackAmount;
    uint256 public contractFee;
    string public purpose;

    constructor(
        address payable _asker,
        bool _verifiedAsker,
        uint256 _amountAsked,
        uint256 _paybackAmount,
        uint256 _contractFee,
        string memory _purpose,
        address payable _managementContract,
        address payable _trustToken
    ) public {
        asker = _asker;
        verifiedAsker = _verifiedAsker;
        amountAsked = _amountAsked;
        paybackAmount = _paybackAmount;
        contractFee = _contractFee;
        purpose = _purpose;
        managementContract = _managementContract;
        trustToken = _trustToken;
    }

    /**
     * @notice deposit the ether that is being sent with the function call
     * @param _origin the address of the initial caller of the function
     * @return true on success - false otherwise
     */
    function deposit(address payable _origin) external payable returns (bool originIsLender, bool originIsAsker) {
        /*
         * Case 1:
         *          Lending Request is being covered by lender
         *          checks:
         *              must not be covered twice (!moneyLent)
         *              must not be covered if the debt has been settled
         *              must not be covered by the asker
         *              has to be covered with one transaction
         * Case 2:
         *          Asker pays back the debt
         *          checks:
         *              cannot pay back the debt if money has yet to be lent
         *              must not be paid back twice
         *              has to be paid back by the asker
         *              must be paid back in one transaction and has to include contractFee
         */
        if (!moneyLent) {
            require(_origin != asker, "invalid lender");
            require(msg.value == amountAsked, "msg.value");
            moneyLent = true;
            lender = _origin;
            originIsLender = true;
            originIsAsker = false;
        } else if (moneyLent && !debtSettled) {
            require(_origin == asker, "invalid paybackaddress");
            require(msg.value == (paybackAmount + contractFee), "invalid payback");
            debtSettled = true;
            originIsLender = false;
            originIsAsker = true;
        } else {
            revert("Error");
        }
    }

    /**
     * @notice withdraw the current balance of the contract
     * @param _origin the address of the initial caller of the function
     */
    function withdraw(address _origin) external {
        /*
         * Case 1: ( asker withdraws amountAsked )
         *      checks:
         *          must only be callable by asker
         *          money has to be lent first
         * Case 2.1: ( lender withdraws amountAsked )
         *      checks:
         *          must only be callable by the lender
         *          asker must not have withdrawn amountAsked
         *      reset moneyLent status
         * Case 2.2: ( lender withdraws paybackAmount )
         *      checks:
         *          must only be callable by the lender
         *          debt has to be repaid first
         *      contractFee has to remain with the contract
         */
        require(moneyLent, "invalid state");
        require(lender != address(0), "invalid lender");
        if (_origin == asker) {
            require(!debtSettled, "debt settled");
            withdrawnByAsker = true;
            asker.transfer(address(this).balance);
        } else if (_origin == lender) {
            if (!debtSettled) {
                require(!withdrawnByAsker, "WithdrawnByAsker");
                moneyLent = false;
                lender.transfer(address(this).balance);
                lender = address(0);
            } else {
                withdrawnByLender = true;
                lender.transfer(address(this).balance - contractFee);
            }
        } else {
            revert("Error");
        }
    }

    /**
     * @notice destroys the lendingRequest contract and forwards all remaining funds to the management contract
     */
    function cleanUp() external {
        require(msg.sender == managementContract, "cleanUp failed");
        selfdestruct(trustToken);
    }

    /**
     * @notice cancels the request if possible
     */
    function cancelRequest() external {
        require(msg.sender == managementContract, "invalid caller");
        require(moneyLent == false && debtSettled == false, "invalid conditions");
        selfdestruct(asker);
    }

    /**
     * @notice getter for all relevant information of the lending request
     */
    function getRequestParameters() external view
        returns (address payable, address payable, uint256, uint256, uint256, string memory) {
        return (asker, lender, amountAsked, paybackAmount, contractFee, purpose);
    }

    /**
     * @notice getter for proposal state
     */
    function getRequestState() external view returns (bool, bool, bool, bool) {
        return (verifiedAsker, moneyLent, withdrawnByAsker, debtSettled);
    }
}