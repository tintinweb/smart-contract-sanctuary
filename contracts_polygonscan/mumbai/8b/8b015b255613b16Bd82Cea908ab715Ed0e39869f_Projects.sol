/*
 * SPDX-License-Identitifer: GPL-3.0-or-later
 */

pragma solidity 0.4.24;

import "@aragon/os/contracts/apps/AragonApp.sol";
import "@aragon/apps-vault/contracts/Vault.sol";
import "@aragon/os/contracts/common/EtherTokenConstant.sol";
import "@aragon/os/contracts/lib/math/SafeMath.sol";

/**
  * @title Bounties Interface
  * @dev Defines a minimal interface blueprint for the StandardBounties contract
  */
interface Bounties {
    /**
     * @notice Submit a fulfillment for issue #`_bountyId` with the following info: `_data`
     */
    function fulfillBounty(
        address _sender,
        uint _bountyId,
        address[] _fulfillers,
        string _data
    ) external; //{}

    /**
     * @notice Update fulfillment for issue #`_bountyId` with the following info: `_data`
     */
    function updateFulfillment(
        address _sender,
        uint _bountyId,
        uint _fulfillmentId,
        address[] _fulfillers,
        string _data
    ) external; //{}

    function issueBounty(
        address sender,
        address[] _issuers,
        address[] _approvers,
        string _data,
        uint _deadline,
        address _token,
        uint _tokenVersion
    ) external returns (uint);

    function contribute(
        address _sender,
        uint _bountyId,
        uint _amount
    ) external payable;

    function issueAndContribute(
        address sender,
        address[] _issuers,
        address[] _approvers,
        string _data,
        uint _deadline,
        address _token,
        uint _tokenVersion,
        uint _depositAmount
    ) external payable returns (uint);

    function performAction(
        address _sender,
        uint _bountyId,
        string _data
    ) external;

    function acceptFulfillment(
        address _sender,
        uint _bountyId,
        uint _fulfillmentId,
        uint _approverId,
        uint[] _tokenAmounts
    ) external;

    function drainBounty(
        address _sender,
        uint _bountyId,
        uint _issuerId,
        uint[] _amounts
    ) external;

    function changeDeadline(
        address _sender,
        uint _bountyId,
        uint _issuerId,
        uint _deadline
    ) external;

    function changeData(
        address _sender,
        uint _bountyId,
        uint _issuerId,
        string _data
    ) external;
}

/**
  * @title ERC20 Interface
  * @dev Defines a minimal interface blueprint for ERC20 tokens interaction
  */
interface ERC20Token {
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transfer(address to, uint tokens) external returns (bool success);
}


/**
  * @title Projects App
  * @author Autark
  * @dev Defines a registry for project tasks in addition to
  * applying bounties in bulk and accepting fulfillment via this contract
  */
contract Projects is AragonApp, DepositableStorage {

    using SafeMath for uint256;

    Bounties public bountiesRegistry;
    BountySettings public settings;
    Vault public vault;
    // Auth roles
    bytes32 public constant FUND_ISSUES_ROLE =  keccak256("FUND_ISSUES_ROLE");
    bytes32 public constant REMOVE_ISSUES_ROLE = keccak256("REMOVE_ISSUES_ROLE");
    bytes32 public constant ADD_REPO_ROLE = keccak256("ADD_REPO_ROLE");
    bytes32 public constant CHANGE_SETTINGS_ROLE =  keccak256("CHANGE_SETTINGS_ROLE");
    bytes32 public constant CURATE_ISSUES_ROLE = keccak256("CURATE_ISSUES_ROLE");
    bytes32 public constant REMOVE_REPO_ROLE =  keccak256("REMOVE_REPO_ROLE");
    bytes32 public constant REVIEW_APPLICATION_ROLE = keccak256("REVIEW_APPLICATION_ROLE");
    bytes32 public constant WORK_REVIEW_ROLE = keccak256("WORK_REVIEW_ROLE");
    bytes32 public constant FUND_OPEN_ISSUES_ROLE = keccak256("FUND_OPEN_ISSUES_ROLE");
    bytes32 public constant UPDATE_BOUNTIES_ROLE = keccak256("UPDATE_BOUNTIES_ROLE");

    string private constant ERROR_PROJECTS_VAULT_NOT_CONTRACT = "PROJECTS_VAULT_NOT_CONTRACT";
    string private constant ERROR_STANDARD_BOUNTIES_NOT_CONTRACT = "STANDARD_BOUNTIES_NOT_CONTRACT";
    string private constant ERROR_LENGTH_EXCEEDED = "LENGTH_EXCEEDED";
    string private constant ERROR_LENGTH_MISMATCH = "ARRAY_LENGTH_MISMATCH";
    string private constant ERROR_CID_LENGTH = "IPFS_ADDRESSES_LENGTH";
    string private constant ERROR_ISSUE_INACTIVE = "ISSUE_NOT_ACTIVE";
    string private constant ERROR_ISSUE_ACTIVE = "ISSUE_HAS_BOUNTY";
    string private constant ERROR_BOUNTY_FULFILLED = "BOUNTY_FULFILLED";
    string private constant ERROR_BOUNTY_REMOVED = "BOUNTY_REMOVED";
    string private constant ERROR_INVALID_AMOUNT = "INVALID_TOKEN_AMOUNT";
    string private constant ERROR_ETH_CONTRACT = "WRONG_ETH_TOKEN";
    string private constant ERROR_REPO_MISSING = "REPO_NOT_ADDED";
    string private constant ERROR_REPO_EXISTS = "REPO_ALREADY_ADDED";
    string private constant ERROR_USER_APPLIED = "USER_ALREADY_APPLIED";
    string private constant ERROR_NO_APPLICATION = "USER_APPLICATION_MISSING";
    string private constant ERROR_NO_ERC721 = "ERC_721_FORBIDDEN";
    string private constant ERROR_PENDING_BOUNTIES = "REPO_HAS_PENDING_BOUNTIES";
    string private constant ERROR_OPEN_BOUNTY = "CANNOT_ASSIGN_OPEN_BOUNTY";


    // IPFS length const
    uint256 private constant CID_LENGTH = 46;

    // The entries in the repos registry.
    mapping(bytes32 => Repo) private repos;
    // issue counter to track how many open issues a repo has
    mapping (bytes32 => uint256) openBounties;
    // Gives us a repos array-like contruct so we can both "iterate" and upgrade gracefully
    mapping(uint256 => bytes32) private repoIndex;
    uint256 private repoIndexLength;
    enum SubmissionStatus { Unreviewed, Accepted, Rejected }  // 0: unreviewed 1: Accepted 2: Rejected

    // Structs
    struct BountySettings {
        uint256[] expMultipliers;
        bytes32[] expLevels;
        uint256 baseRate;
        uint256 bountyDeadline;
        address bountyCurrency;
    }

    struct Repo {
        mapping(uint256 => Issue) issues;
        uint index;
    }

    struct AssignmentRequest {
        SubmissionStatus status;
        string requestHash; //IPFS hash of the application data
        bool exists;
    }

    struct Issue {
        bytes32 repo;  // This is the internal repo identifier
        uint256 number; // May be redundant tracking this
        bool hasBounty;
        bool fulfilled;
        address tokenContract;
        uint256 bountySize;
        uint256 priority;
        address bountyWallet; // Not sure if we'll have a way to "retrieve" this value from status open bounties
        uint standardBountyId;
        address assignee;
        address[] applicants;
        //uint256 submissionQty;
        uint256[] submissionIndices;
        mapping(address => AssignmentRequest) assignmentRequests;
    }

    // Fired when a repository is added to the registry.
    event RepoAdded(bytes32 indexed repoId, uint index);
    // Fired when a repository is removed from the registry.
    event RepoRemoved(bytes32 indexed repoId, uint index);
    // Fired when a repo is updated in the registry
    event RepoUpdated(bytes32 indexed repoId, uint newIndex);
    // Fired when a bounty is added to a repo
    event BountyAdded(bytes32 repoId, uint256 issueNumber, uint256 bountySize, uint256 registryId, string ipfsHash);
    // Fired when a bounty is removed
    event BountyRemoved(bytes32 repoId, uint256 issueNumber, uint256 oldBountySize);
    // Fired when an issue is curated
    event IssueCurated(bytes32 repoId);
    // Fired when settings are changed
    event BountySettingsChanged();
    // Fired when user requests issue assignment
    event AssignmentRequested(bytes32 indexed repoId, uint256 issueNumber);
    // Fired when Task Manager approves assignment request
    event AssignmentApproved(address applicant, bytes32 indexed repoId, uint256 issueNumber);
    // Fired when Task Manager rejects assignment request
    event AssignmentRejected(address applicant, bytes32 indexed repoId, uint256 issueNumber);
    // Fired when a reviewer accepts accepts a submission
    event SubmissionAccepted(uint256 submissionNumber, bytes32 repoId, uint256 issueNumber);
    // Fired when a reviewer rejects a submission
    event SubmissionRejected(uint256 submissionNumber, bytes32 repoId, uint256 issueNumber);
    // Fired when a bounty is opened up to work submissions from anyone
    event AwaitingSubmissions(bytes32 repoId, uint256 issueNumber);


    /**
     * @notice Initialize Projects app for StandardBounties at `_bountiesAddr`
     * @dev Initializes the Projects app, this is the Aragon custom constructor
     * @param _bountiesAddr Address of the StandardBounties deployed instance Projects will rely on (changeable)
     * @param _vault Address of the vault Projects will rely on (non changeable)
     */
    function initialize(
        address _bountiesAddr,
        Vault _vault
    ) external onlyInit
    {
        require(isContract(_vault), ERROR_PROJECTS_VAULT_NOT_CONTRACT);
        require(isContract(_bountiesAddr), ERROR_STANDARD_BOUNTIES_NOT_CONTRACT);

        vault = _vault;

        bountiesRegistry = Bounties(_bountiesAddr); // Standard Bounties instance

        _addExperienceLevel(100, bytes32("Beginner"));
        _addExperienceLevel(300, bytes32("Intermediate"));
        _addExperienceLevel(500, bytes32("Advanced"));

        _changeBountySettings(
            0, // baseRate
            336, // bountyDeadline
            ETH, // default bounty currency inits to ETH
            _bountiesAddr // bountyAllocator
        );

        setDepositable(true);
        initialized();
    }

///////////////////////
// Set state functions
///////////////////////


    /**
     * @notice Update settings for the Projects app
     */
    function changeBountySettings(
        uint256[] _expMultipliers,
        bytes32[] _expLevels,
        uint256 _baseRate,
        uint256 _bountyDeadline,
        address _bountyCurrency,
        address _bountyAllocator
    ) external auth(CHANGE_SETTINGS_ROLE)
    {
        require(_expMultipliers.length == _expLevels.length, ERROR_LENGTH_MISMATCH);
        require(_isBountiesContractValid(_bountyAllocator), ERROR_STANDARD_BOUNTIES_NOT_CONTRACT);
        settings.expLevels.length = 0;
        settings.expMultipliers.length = 0;
        for (uint i = 0; i < _expLevels.length; i++) {
            _addExperienceLevel(_expMultipliers[i], _expLevels[i]);
        }
        _changeBountySettings(_baseRate, _bountyDeadline, _bountyCurrency, _bountyAllocator);
    }

///////////////////////
// View state functions
///////////////////////

    /**
     * @notice Get issue data from the registry.
     * @param _repoId The id of the repo in the projects registry
     */
    function getIssue(bytes32 _repoId, uint256 _issueNumber) external view isInitialized
    returns(bool hasBounty, uint standardBountyId, bool fulfilled, uint balance, address assignee)
    {
        Issue storage issue = repos[_repoId].issues[_issueNumber];
        hasBounty = issue.hasBounty;
        fulfilled = issue.fulfilled;
        standardBountyId = issue.standardBountyId;
        balance = issue.bountySize;
        assignee = issue.assignee;
    }

    /**
     * @notice Get registry size.
     */
    function getReposCount() external view isInitialized returns (uint count) {
        return repoIndexLength;
    }

    /**
     * @notice Get an entry from the registry.
     * @param _repoId The id of the repo in the projects registry
     * @return index the repo registry index
     */
    function getRepo(bytes32 _repoId) external view isInitialized returns (uint256 index, uint256 openIssueCount) {
        require(isRepoAdded(_repoId), ERROR_REPO_MISSING);
        index = repos[_repoId].index;
        openIssueCount = openBounties[_repoId];
    }

    /**
     * @notice Get general settings.
     * @return BountySettings
     */

    function getSettings() external view isInitialized returns (
        uint256[] expMultipliers,
        bytes32[] expLevels,
        uint256 baseRate,
        uint256 bountyDeadline,
        address bountyCurrency,
        address bountyAllocator
        //address bountyArbiter
    )
    {
        return (
            settings.expMultipliers,
            settings.expLevels,
            settings.baseRate,
            settings.bountyDeadline,
            settings.bountyCurrency,
            bountiesRegistry
            //settings.bountyArbiter
        );
    }

///////////////////////
// Repository functions
///////////////////////
    /**
     * @notice Add repository
     * @param _repoId The id of the repo in the projects registry
     * @return index for the added repo at the registry
     */
    function addRepo(
        bytes32 _repoId
    ) external auth(ADD_REPO_ROLE) returns (uint index)
    {
        require(!isRepoAdded(_repoId), ERROR_REPO_EXISTS);
        repoIndex[repoIndexLength] = _repoId;
        repos[_repoId].index = repoIndexLength++;
        //repos[_repoId].index = repoIndex.push(_repoId) - 1;
        emit RepoAdded(_repoId, repos[_repoId].index);
        return repoIndexLength - 1;
    }

    /**
     * @notice Remove repository
     * @param _repoId The id of the repo in the projects registry
     */
    function removeRepo(
        bytes32 _repoId
    ) external auth(REMOVE_REPO_ROLE) returns (bool success)
    {
        require(isRepoAdded(_repoId), ERROR_REPO_MISSING);
        require(openBounties[_repoId] == 0, ERROR_PENDING_BOUNTIES);
        uint rowToDelete = repos[_repoId].index;

        if (repoIndexLength != 1) {
            bytes32 repoToMove = repoIndex[repoIndexLength - 1];
            repoIndex[rowToDelete] = repoToMove;
            repos[repoToMove].index = rowToDelete;
        }

        repoIndexLength--;
        emit RepoRemoved(_repoId, rowToDelete);
        return true;
    }

///////////////////
// External Bounty functions
///////////////////

    /**
     * @notice Submit application for issue `_issueNumber` with application `_application`
     * @param _repoId the repo id of the issue
     * @param _issueNumber the issue up for assignment
     * @param _application IPFS hash for the applicant's proposed timeline and strategy
     */
    function requestAssignment(
        bytes32 _repoId,
        uint256 _issueNumber,
        string _application
    ) external isInitialized
    {
        Issue storage issue = repos[_repoId].issues[_issueNumber];

        require(!issue.fulfilled,ERROR_BOUNTY_FULFILLED);
        require(issue.hasBounty, ERROR_ISSUE_INACTIVE);
        require(issue.assignee != address(-1), ERROR_OPEN_BOUNTY);
        require(issue.assignmentRequests[msg.sender].exists == false, ERROR_USER_APPLIED);

        issue.applicants.push(msg.sender);
        issue.assignmentRequests[msg.sender] = AssignmentRequest(
            SubmissionStatus.Unreviewed,
            _application,
            true
        );
        bountiesRegistry.performAction(
            address(this),
            issue.standardBountyId,
            _application
        );
        emit AssignmentRequested(_repoId, _issueNumber);
    }

    /**
     * @notice `_approved ? 'Accept' : 'Reject'` `_requestor` for issue `_issueNumber`
     * @param _repoId the repo id of the issue
     * @param _issueNumber the issue up for assignment
     * @param _requestor address of user that will be assigned the issue
     * @param _updatedApplication IPFS hash of the application containing optional feedback
     */
    function reviewApplication(
        bytes32 _repoId,
        uint256 _issueNumber,
        address _requestor,
        string _updatedApplication,
        bool _approved
    ) external auth(REVIEW_APPLICATION_ROLE)
    {
        Issue storage issue = repos[_repoId].issues[_issueNumber];
        require(issue.assignee != address(-1), ERROR_OPEN_BOUNTY);
        require(issue.assignmentRequests[_requestor].exists == true, ERROR_NO_APPLICATION);
        issue.assignmentRequests[_requestor].requestHash = _updatedApplication;

        if (_approved) {
            issue.assignee = _requestor;
            issue.assignmentRequests[_requestor].status = SubmissionStatus.Accepted;
            emit AssignmentApproved(_requestor, _repoId, _issueNumber);
        } else {
            issue.assignmentRequests[_requestor].status = SubmissionStatus.Rejected;
            emit AssignmentRejected(_requestor, _repoId, _issueNumber);
        }
        bountiesRegistry.performAction(
            address(this),
            issue.standardBountyId,
            _updatedApplication
        );

    }

    /**
     * @notice `_approved ? 'Accept' : 'Reject'` work for issue `_issueNumber` with info: `_updatedSubmissionHash`
     * @dev add a submission to local state after it's been added to StandardBounties.sol
     * @param _repoId the repo id of the issue
     * @param _issueNumber the issue up for resolution
     * @param _submissionNumber submission index of the submitted work for review
     * @param _approved decision to accept the contribution
     * @param _updatedSubmissionHash IPFS hash of the submission containing optional feedback
     * @param _tokenAmounts array of amounts???
     */
    function reviewSubmission(
        bytes32 _repoId,
        uint256 _issueNumber,
        uint256 _submissionNumber,
        bool _approved,
        string _updatedSubmissionHash,
        uint256[] _tokenAmounts
    ) external auth(WORK_REVIEW_ROLE)
    {
        Issue storage issue = repos[_repoId].issues[_issueNumber];

        require(!issue.fulfilled,ERROR_BOUNTY_FULFILLED);
        require(issue.assignee != address(0), ERROR_ISSUE_INACTIVE);

        if (_approved) {
            uint256 tokenTotal;
            for (uint256 i = 0; i < _tokenAmounts.length; i++) {
                tokenTotal = tokenTotal.add(_tokenAmounts[i]);
            }
            require(tokenTotal >= issue.bountySize, ERROR_INVALID_AMOUNT);

            issue.fulfilled = true;
            bountiesRegistry.acceptFulfillment(
                address(this),
                issue.standardBountyId,
                _submissionNumber,
                0,
                _tokenAmounts
            );
            openBounties[_repoId] = openBounties[_repoId].sub(1);
            emit SubmissionAccepted(_submissionNumber, _repoId, _issueNumber);
        } else {
            emit SubmissionRejected(_submissionNumber, _repoId, _issueNumber);
        }

        bountiesRegistry.performAction(
            address(this),
            issue.standardBountyId,
            _updatedSubmissionHash
        );
    }

    /**
     * @notice Update bounty for issue `_issueNumber`: `_description`
     * @param _repoId The id of the repos in the projects registry
     * @param _issueNumber issue number the bounty is assigned to
     * @param _data Information hash stored in the bounty
     * @param _deadline new deadline for bounty fulfillments
     * @param _description Utilized when forwarded to give background to the
     *                     issues up for removal
     */
    function updateBounty(
        bytes32 _repoId,
        uint256 _issueNumber,
        string _data,
        uint256 _deadline,
        string _description
    ) external auth(UPDATE_BOUNTIES_ROLE)
    {
        Issue storage issue = repos[_repoId].issues[_issueNumber];

        require(!issue.fulfilled,ERROR_BOUNTY_FULFILLED);
        require(issue.hasBounty, ERROR_ISSUE_INACTIVE);

        bountiesRegistry.changeData(
            address(this),
            issue.standardBountyId,
            0,
            _data
        );
        bountiesRegistry.changeDeadline(
            address(this),
            issue.standardBountyId,
            0,
            _deadline
        );
    }

    /**
     * @notice Remove funding from issues: `_description`
     * @param _repoIds The ids of the repos in the projects registry
     * @param _issueNumbers an array of bounty indexes
     * @param _description Utilized when forwarded to give background to the
     *                     issues up for removal
     */
    function removeBounties(
        bytes32[] _repoIds,
        uint256[] _issueNumbers,
        string _description
    ) external auth(REMOVE_ISSUES_ROLE)
    {
        require(_repoIds.length < 256, ERROR_LENGTH_EXCEEDED);
        require(_issueNumbers.length < 256, ERROR_LENGTH_EXCEEDED);
        require(_repoIds.length == _issueNumbers.length, ERROR_LENGTH_MISMATCH);
        for (uint8 i = 0; i < _issueNumbers.length; i++) {
            _removeBounty(_repoIds[i], _issueNumbers[i]);
        }
    }

///////////////////////
// External utility functions
///////////////////////

    /**
     * @notice Returns Applicant array length
     * @param _repoId the repo id of the issue
     * @param _issueNumber the issue up for assignmen
     * @return  array length of the applicants array
     */
    function getApplicantsLength(
        bytes32 _repoId,
        uint256 _issueNumber
    ) external view isInitialized returns(uint256 applicantQty)
    {
        applicantQty = repos[_repoId].issues[_issueNumber].applicants.length;
    }

    /**
     * @notice Returns Applicant Address
     * @param _repoId The repo id of the issue
     * @param _issueNumber The issue up for assignment
     * @param _idx The applicant's position in the array
     * @return  applicant address
     */
    function getApplicant(
        bytes32 _repoId,
        uint256 _issueNumber,
        uint256 _idx
    ) external view isInitialized returns(address applicant, string application, SubmissionStatus status)
    {
        Issue storage issue = repos[_repoId].issues[_issueNumber];
        applicant = issue.applicants[_idx];
        application = issue.assignmentRequests[applicant].requestHash;
        status = issue.assignmentRequests[applicant].status;
    }

///////////////////
// Public Bounty functions
///////////////////

    /**
     * @notice Fund issues: `_description`
     * @param _repoIds The ids of the repos in the projects registry
     * @param _issueNumbers An array of bounty indexes
     * @param _bountySizes An array of bounty sizes
     * @param _deadlines An array of bounty deadlines
     * @param _tokenTypes An array of currency types: 0=ETH from user's wallet, 1=ETH from vault, 20=ERC20 token from vault
     * @param _tokenContracts An array of token contracts
     * @param _ipfsAddresses A string of IPFS addresses
     * @param _description parsed and display to user when this function is forwarded
     */
    function addBounties(
        bytes32[] _repoIds,
        uint256[] _issueNumbers,
        uint256[] _bountySizes,
        uint256[] _deadlines,
        uint256[] _tokenTypes,
        address[] _tokenContracts,
        string _ipfsAddresses,
        string _description
    ) public payable auth(FUND_ISSUES_ROLE)
    {
        // ensure the transvalue passed equals transaction value
        //checkTransValueEqualsMessageValue(msg.value, _bountySizes,_tokenBounties);
        string memory ipfsHash;
        uint standardBountyId;
        require(bytes(_ipfsAddresses).length == (CID_LENGTH * _bountySizes.length), ERROR_CID_LENGTH);

        for (uint i = 0; i < _bountySizes.length; i++) {
            ipfsHash = getHash(_ipfsAddresses, i);

            // submit the bounty to the StandardBounties contract
            standardBountyId = _issueBounty(
                ipfsHash,
                _deadlines[i],
                _tokenContracts[i],
                _tokenTypes[i],
                _bountySizes[i]
            );

            //Add bounty to local registry
            _addBounty(
                _repoIds[i],
                _issueNumbers[i],
                standardBountyId,
                _tokenContracts[i],
                _bountySizes[i],
                ipfsHash
            );
        }
    }

    /**
     * @notice Fund open-submission issues: `_description`
     * @param _repoIds The ids of the repos in the projects registry
     * @param _issueNumbers an array of bounty indexes
     * @param _bountySizes an array of bounty sizes
     * @param _deadlines an array of bounty deadlines
     * @param _tokenTypes array of currency types: 0=ETH, 20=ERC20
     * @param _tokenContracts an array of token contracts
     * @param _ipfsAddresses a string of ipfs addresses
     * @param _description parsed and display to user when this function is forwarded
     */
    function addBountiesNoAssignment(
        bytes32[] _repoIds,
        uint256[] _issueNumbers,
        uint256[] _bountySizes,
        uint256[] _deadlines,
        uint256[] _tokenTypes,
        address[] _tokenContracts,
        string _ipfsAddresses,
        string _description
    ) public payable auth(FUND_OPEN_ISSUES_ROLE)
    {
        string memory ipfsHash;
        uint standardBountyId;

        for (uint i = 0; i < _bountySizes.length; i++) {
            ipfsHash = getHash(_ipfsAddresses, i);

            // submit the bounty to the StandardBounties contract
            standardBountyId = _issueBounty(
                ipfsHash,
                _deadlines[i],
                _tokenContracts[i],
                _tokenTypes[i],
                _bountySizes[i]
            );

            //Add bounty to local registry
            _addBounty(
                _repoIds[i],
                _issueNumbers[i],
                standardBountyId,
                _tokenContracts[i],
                _bountySizes[i],
                ipfsHash
            );

            repos[_repoIds[i]].issues[_issueNumbers[i]].assignee = address(-1);
            emit AwaitingSubmissions(_repoIds[i], _issueNumbers[i]);
        }

    }

    /**
     * @notice Issue curation: `_description`
     * @dev curateIssues(): This function conforms to the upcoming
     *                      specId 2 forwarder interface
     *                      and it is meant to be forwarded to a dot
     *                      voting app instance or another voting app
     *                      that utilizes dynamic forwarding.
     *                      The unused parameters are in place to conform
     *                      to the above specification.
     * @param _description The description of the issue curation
     */
    function curateIssues(
        address[] /*unused_Addresses*/,
        uint256[] issuePriorities,
        uint256[] issueDescriptionIndices,
        string /* unused_issueDescriptions*/,
        string _description,
        uint256[] issueRepos,
        uint256[] issueNumbers,
        uint256 /* unused_curationId */
    ) public auth(CURATE_ISSUES_ROLE)
    {
        bytes32 repoId;
        uint256 issueLength = issuePriorities.length;
        require(issueLength == issueDescriptionIndices.length, "LENGTH_MISMATCH: issuePriorites and issueDescriptionIdx");
        require(issueLength == issueRepos.length, "LENGTH_MISMATCH: issuePriorites and issueRepos");
        require(issueLength == issueNumbers.length, "LENGTH_MISMATCH: issuePriorites and issueNumbers");

        for (uint256 i = 0; i < issueLength; i++) {
            repoId = bytes32(issueRepos[i]);
            repos[repoId].issues[uint256(issueNumbers[i])].priority = issuePriorities[i];
            emit IssueCurated(repoId);
        }
    }

///////////////////////
// Public utility functions
///////////////////////

    /**
     * @notice Checks if a repo exists in the registry
     * @param _repoId The repo id to check
     * @return _repoId Id for newly added repo
     */
    function isRepoAdded(bytes32 _repoId) public view isInitialized returns(bool isAdded) {
        uint256 repoIdxVal = repos[_repoId].index;
        if (repoIndexLength == 0)
            return false;
        if (repoIdxVal >= repoIndexLength)
            return false;
        return (repoIndex[repos[_repoId].index] == _repoId);
    }

///////////////////////
// Internal functions
///////////////////////

    /**
     * @dev checks the hashed contract code to ensure it matches the provided hash
     */
    function _isBountiesContractValid(address _bountyRegistry) internal view returns(bool) {
        if (_bountyRegistry == address(0)) {
            return false;
        }
        if (_bountyRegistry == address(bountiesRegistry)) {
            return true;
        }
        uint256 size;
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(_bountyRegistry) }
        if (size != 23406) {
            return false;
        }
        uint256 segments = 4;
        uint256 segmentLength = size / segments;
        bytes memory registryCode = new bytes(segmentLength);
        bytes32[4] memory validRegistryHashes = [
            bytes32(0x9904de0ff2a8144b30f80f0de9184731b7c39116b1f021bad12dcbb740f8371d),
            bytes32(0xd2319fa5b8b5614a3634c84ff340d27fa6e5921162e44bc2256f379ad86608f3),
            bytes32(0x0fd4c8d32b2c21b41989666a6d19f7a5f4987ae6d915dd96698de62db8a79643),
            bytes32(0x6af9efdc22f9352086c68a7b5c270db4f0fdc2b5ab18984a2d17b92ae327e144)
        ];
        for (uint256 i = 0; i < segments; i++) {
            // solium-disable-next-line security/no-inline-assembly
            assembly{ extcodecopy(_bountyRegistry,add(0x20,registryCode),div(mul(i,segmentLength),segments),segmentLength) }
            if (validRegistryHashes[i] != keccak256(registryCode)) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice Update bounty setting values
     * @dev _changeBountySettings(): update app settings by changing contract setting state
     */
    function _changeBountySettings(
        uint256 _baseRate,
        uint256 _bountyDeadline,
        address _bountyCurrency,
        address _bountyAllocator
    ) internal
    {
        settings.baseRate = _baseRate;
        settings.bountyDeadline = _bountyDeadline;
        settings.bountyCurrency = _bountyCurrency;
        bountiesRegistry = Bounties(_bountyAllocator);

        emit BountySettingsChanged();
    }

    /**
     * @notice create a new experience level containing the multiplier and description
     * @dev _addExperienceLevel():  Push new entries into the expMultiplier and expLevel
     *                              arrays
     */
    function _addExperienceLevel(
        uint _multiplier,
        bytes32 _description
    ) internal
    {
        settings.expMultipliers.push(_multiplier);
        settings.expLevels.push(_description);
    }

    /**
     * @notice passes provided info to the linked Standard Bounties contract
     * @dev _issueBounty(): There are three forms of the contribute call.
     *                      The first is used if ETH from the user is used as the bounty contribution
     *                      The second is used if ETH from the vault is the bounty currency
     *                      The third is used if an ERC20 token from the vault is the bounty currency
     */
    function _issueBounty(
        string _ipfsHash,
        uint256 _deadline,
        address _tokenContract,
        uint256 _tokenType,
        uint256 _bountySize
    ) internal returns (uint256 bountyId)
    {
        require(_tokenType != 721, ERROR_NO_ERC721);
        uint256 registryTokenType;
        if (_tokenType == 0) {
            require(_tokenContract == ETH, ERROR_ETH_CONTRACT);
            registryTokenType = _tokenType;
        } else if (_tokenType == 1) {
            require(_tokenContract == ETH, ERROR_ETH_CONTRACT);
            registryTokenType = 0;
        } else {
            registryTokenType = _tokenType;
        }

        address[] memory issuers = new address[](1);
        issuers[0] = address(this);

        if (_tokenType > 0) {
            vault.transfer(_tokenContract, this, _bountySize);
            if (registryTokenType != 0) {
                require(ERC20Token(_tokenContract).approve(bountiesRegistry, _bountySize), "ERROR_ERC20_TRANSFER");
            }
        }

        if (registryTokenType == 0) {
            bountyId = bountiesRegistry.issueAndContribute.value(_bountySize)(
                address(this),      // address payable _sender
                issuers,            // address payable [] memory _issuers
                issuers,            // address [] memory _approvers
                _ipfsHash,          // string memory _data
                _deadline,          // uint _deadline
                _tokenContract,     // address _token
                registryTokenType,   // uint _tokenVersion
                _bountySize
            );
        } else {
            bountyId = bountiesRegistry.issueAndContribute(
                address(this),      // address payable _sender
                issuers,            // address payable [] memory _issuers
                issuers,            // address [] memory _approvers
                _ipfsHash,          // string memory _data
                _deadline,          // uint _deadline
                _tokenContract,     // address _token
                registryTokenType,   // uint _tokenVersion
                _bountySize
            );
        }
    }

    /**
     * @notice internal function that adds the bounty info to contract state
     * @dev _addBounty():   Creates a new Issue instance in the specified Repo
     *                      and initializes the the state parameters that aren't
     *                      passed in
     */
    function _addBounty(
        bytes32 _repoId,
        uint256 _issueNumber,
        uint _standardBountyId,
        address _tokenContract,
        uint256 _bountySize,
        string _ipfsHash
    ) internal
    {
        address[] memory emptyAddressArray = new address[](0);
        uint256[] memory emptySubmissionIndexArray = new uint256[](0);
        //Issue storage issue = repos[_repoId].issues[_issueNumber];
        require(isRepoAdded(_repoId), ERROR_REPO_MISSING);
        require(!repos[_repoId].issues[_issueNumber].hasBounty, ERROR_ISSUE_ACTIVE);

        repos[_repoId].issues[_issueNumber] = Issue(
            _repoId,
            _issueNumber,
            true,
            false,
            _tokenContract,
            _bountySize,
            999,
            ETH,
            _standardBountyId,
            ETH,
            emptyAddressArray,
            //address(0),
            //0,
            emptySubmissionIndexArray
        );
        openBounties[_repoId] = openBounties[_repoId].add(1);
        emit BountyAdded(
            _repoId,
            _issueNumber,
            _bountySize,
            _standardBountyId,
            _ipfsHash
        );
    }

    /**
     * @notice remove bounty from StandardBounties and local registry
     * @dev _removeBounty():    First transfers the bounty value from
     *                          the StandardBounties registry back
     *                          to the Project's integrated vault.
     *                          Next resets the issue's contract state.
     * @param _repoId the repo id of the issue
     * @param _issueNumber the issue up for assignment
     */
    function _removeBounty(
        bytes32 _repoId,
        uint256 _issueNumber
    ) internal
    {
        Issue storage issue = repos[_repoId].issues[_issueNumber];
        require(issue.hasBounty, ERROR_BOUNTY_REMOVED);
        require(!issue.fulfilled, ERROR_BOUNTY_FULFILLED);
        issue.hasBounty = false;
        uint256[] memory originalAmount = new uint256[](1);
        originalAmount[0] = issue.bountySize;
        bountiesRegistry.drainBounty(
            address(this),
            issue.standardBountyId,
            0,
            originalAmount
        );
        _returnValueToVault(originalAmount[0], issue.tokenContract);
        issue.bountySize = 0;
        bountiesRegistry.changeDeadline(
            address(this),
            issue.standardBountyId,
            0,
            getTimestamp()
        );
        openBounties[_repoId] = openBounties[_repoId].sub(1);
        emit BountyRemoved(
            _repoId,
            _issueNumber,
            originalAmount[0]
        );
    }

    function _returnValueToVault(uint256 _amount, address _token) internal {
        if (_token == ETH)
            vault.deposit.value(_amount)(_token, _amount);
        else {
            require(ERC20Token(_token).approve(vault, _amount), "ERROR_ERC20__APPROVAL");
            vault.deposit(_token, _amount);
        }
    }

    /**
     * @notice parses InfoStrings for the CID hash
     * @dev getHash():  First copies over the first 32 bytes.
     *                  Next copies the remaining 14 bytes and
     *                  and masks the remainder of the word
     * @param _str The raw string to be parsed by the function
     * @param _hashIndex The index of the hash to be parsed from
     *                   the string of combined hashes
     */
    function getHash(
        string _str,
        uint256 _hashIndex
    ) internal pure returns (string)
    {
        // first char is at location 0
        //IPFS addresses span from 0 (startindex) to 46 (endIndex)
        uint256 startIndex = _hashIndex * CID_LENGTH;
        uint256 endIndex = startIndex + CID_LENGTH;
        bytes memory strBytes = bytes(_str);
        bytes memory result = new bytes(endIndex-startIndex);
        uint256 length = endIndex - startIndex;
        // destination in memory for the returned hash
        uint256 dest;
        // source location in memory for the returned hash
        uint256 src;
        // need to offset by 0x20 (32 bytes) to account for the first
        // 32 "header" bytes
        // then copy the first 32 bytes of the hash into the destination location
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            dest := add(result,0x20)
            src := add(strBytes,add(0x20,startIndex))
            mstore(dest, mload(src))
        }
        // copy the remaining 14 bytes and ensure the remaining
        // 18 bytes of the word are set to "00" using a mask
        src += 32;
        dest += 32;
        length -= 32;
        uint mask = 256 ** (32 - length) - 1;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }

        return string(result);
    }

}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;

import "./AppStorage.sol";
import "../acl/ACLSyntaxSugar.sol";
import "../common/Autopetrified.sol";
import "../common/ConversionHelpers.sol";
import "../common/ReentrancyGuard.sol";
import "../common/VaultRecoverable.sol";
import "../evmscript/EVMScriptRunner.sol";


// Contracts inheriting from AragonApp are, by default, immediately petrified upon deployment so
// that they can never be initialized.
// Unless overriden, this behaviour enforces those contracts to be usable only behind an AppProxy.
// ReentrancyGuard, EVMScriptRunner, and ACLSyntaxSugar are not directly used by this contract, but
// are included so that they are automatically usable by subclassing contracts
contract AragonApp is AppStorage, Autopetrified, VaultRecoverable, ReentrancyGuard, EVMScriptRunner, ACLSyntaxSugar {
    string private constant ERROR_AUTH_FAILED = "APP_AUTH_FAILED";

    modifier auth(bytes32 _role) {
        require(canPerform(msg.sender, _role, new uint256[](0)), ERROR_AUTH_FAILED);
        _;
    }

    modifier authP(bytes32 _role, uint256[] _params) {
        require(canPerform(msg.sender, _role, _params), ERROR_AUTH_FAILED);
        _;
    }

    /**
    * @dev Check whether an action can be performed by a sender for a particular role on this app
    * @param _sender Sender of the call
    * @param _role Role on this app
    * @param _params Permission params for the role
    * @return Boolean indicating whether the sender has the permissions to perform the action.
    *         Always returns false if the app hasn't been initialized yet.
    */
    function canPerform(address _sender, bytes32 _role, uint256[] _params) public view returns (bool) {
        if (!hasInitialized()) {
            return false;
        }

        IKernel linkedKernel = kernel();
        if (address(linkedKernel) == address(0)) {
            return false;
        }

        return linkedKernel.hasPermission(
            _sender,
            address(this),
            _role,
            ConversionHelpers.dangerouslyCastUintArrayToBytes(_params)
        );
    }

    /**
    * @dev Get the recovery vault for the app
    * @return Recovery vault address for the app
    */
    function getRecoveryVault() public view returns (address) {
        // Funds recovery via a vault is only available when used with a kernel
        return kernel().getRecoveryVault(); // if kernel is not set, it will revert
    }
}

pragma solidity 0.4.24;

import "@aragon/os/contracts/apps/AragonApp.sol";
import "@aragon/os/contracts/common/DepositableStorage.sol";
import "@aragon/os/contracts/common/EtherTokenConstant.sol";
import "@aragon/os/contracts/common/SafeERC20.sol";
import "@aragon/os/contracts/lib/token/ERC20.sol";


contract Vault is EtherTokenConstant, AragonApp, DepositableStorage {
    using SafeERC20 for ERC20;

    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    string private constant ERROR_DATA_NON_ZERO = "VAULT_DATA_NON_ZERO";
    string private constant ERROR_NOT_DEPOSITABLE = "VAULT_NOT_DEPOSITABLE";
    string private constant ERROR_DEPOSIT_VALUE_ZERO = "VAULT_DEPOSIT_VALUE_ZERO";
    string private constant ERROR_TRANSFER_VALUE_ZERO = "VAULT_TRANSFER_VALUE_ZERO";
    string private constant ERROR_SEND_REVERTED = "VAULT_SEND_REVERTED";
    string private constant ERROR_VALUE_MISMATCH = "VAULT_VALUE_MISMATCH";
    string private constant ERROR_TOKEN_TRANSFER_FROM_REVERTED = "VAULT_TOKEN_TRANSFER_FROM_REVERT";
    string private constant ERROR_TOKEN_TRANSFER_REVERTED = "VAULT_TOKEN_TRANSFER_REVERTED";

    event VaultTransfer(address indexed token, address indexed to, uint256 amount);
    event VaultDeposit(address indexed token, address indexed sender, uint256 amount);

    /**
    * @dev On a normal send() or transfer() this fallback is never executed as it will be
    *      intercepted by the Proxy (see aragonOS#281)
    */
    function () external payable isInitialized {
        require(msg.data.length == 0, ERROR_DATA_NON_ZERO);
        _deposit(ETH, msg.value);
    }

    /**
    * @notice Initialize Vault app
    * @dev As an AragonApp it needs to be initialized in order for roles (`auth` and `authP`) to work
    */
    function initialize() external onlyInit {
        initialized();
        setDepositable(true);
    }

    /**
    * @notice Deposit `_value` `_token` to the vault
    * @param _token Address of the token being transferred
    * @param _value Amount of tokens being transferred
    */
    function deposit(address _token, uint256 _value) external payable isInitialized {
        _deposit(_token, _value);
    }

    /**
    * @notice Transfer `_value` `_token` from the Vault to `_to`
    * @param _token Address of the token being transferred
    * @param _to Address of the recipient of tokens
    * @param _value Amount of tokens being transferred
    */
    /* solium-disable-next-line function-order */
    function transfer(address _token, address _to, uint256 _value)
        external
        authP(TRANSFER_ROLE, arr(_token, _to, _value))
    {
        require(_value > 0, ERROR_TRANSFER_VALUE_ZERO);

        if (_token == ETH) {
            require(_to.send(_value), ERROR_SEND_REVERTED);
        } else {
            require(ERC20(_token).safeTransfer(_to, _value), ERROR_TOKEN_TRANSFER_REVERTED);
        }

        emit VaultTransfer(_token, _to, _value);
    }

    function balance(address _token) public view returns (uint256) {
        if (_token == ETH) {
            return address(this).balance;
        } else {
            return ERC20(_token).staticBalanceOf(address(this));
        }
    }

    /**
    * @dev Disable recovery escape hatch, as it could be used
    *      maliciously to transfer funds away from the vault
    */
    function allowRecoverability(address) public view returns (bool) {
        return false;
    }

    function _deposit(address _token, uint256 _value) internal {
        require(isDepositable(), ERROR_NOT_DEPOSITABLE);
        require(_value > 0, ERROR_DEPOSIT_VALUE_ZERO);

        if (_token == ETH) {
            // Deposit is implicit in this case
            require(msg.value == _value, ERROR_VALUE_MISMATCH);
        } else {
            require(
                ERC20(_token).safeTransferFrom(msg.sender, address(this), _value),
                ERROR_TOKEN_TRANSFER_FROM_REVERTED
            );
        }

        emit VaultDeposit(_token, msg.sender, _value);
    }
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


// aragonOS and aragon-apps rely on address(0) to denote native ETH, in
// contracts where both tokens and ETH are accepted
contract EtherTokenConstant {
    address internal constant ETH = address(0);
}

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/d51e38758e1d985661534534d5c61e27bece5042/contracts/math/SafeMath.sol
// Adapted to use pragma ^0.4.24 and satisfy our linter rules

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, ERROR_MUL_OVERFLOW);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;

import "../common/UnstructuredStorage.sol";
import "../kernel/IKernel.sol";


contract AppStorage {
    using UnstructuredStorage for bytes32;

    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_POSITION = keccak256("aragonOS.appStorage.kernel");
    bytes32 internal constant APP_ID_POSITION = keccak256("aragonOS.appStorage.appId");
    */
    bytes32 internal constant KERNEL_POSITION = 0x4172f0f7d2289153072b0a6ca36959e0cbe2efc3afe50fc81636caa96338137b;
    bytes32 internal constant APP_ID_POSITION = 0xd625496217aa6a3453eecb9c3489dc5a53e6c67b444329ea2b2cbc9ff547639b;

    function kernel() public view returns (IKernel) {
        return IKernel(KERNEL_POSITION.getStorageAddress());
    }

    function appId() public view returns (bytes32) {
        return APP_ID_POSITION.getStorageBytes32();
    }

    function setKernel(IKernel _kernel) internal {
        KERNEL_POSITION.setStorageAddress(address(_kernel));
    }

    function setAppId(bytes32 _appId) internal {
        APP_ID_POSITION.setStorageBytes32(_appId);
    }
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


contract ACLSyntaxSugar {
    function arr() internal pure returns (uint256[]) {
        return new uint256[](0);
    }

    function arr(bytes32 _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(bytes32 _a, bytes32 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(address _a, address _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), _b, _c);
    }

    function arr(address _a, uint256 _b, uint256 _c, uint256 _d) internal pure returns (uint256[] r) {
        return arr(uint256(_a), _b, _c, _d);
    }

    function arr(address _a, uint256 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, address _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), _c, _d, _e);
    }

    function arr(address _a, address _b, address _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(address _a, address _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(uint256 _a) internal pure returns (uint256[] r) {
        r = new uint256[](1);
        r[0] = _a;
    }

    function arr(uint256 _a, uint256 _b) internal pure returns (uint256[] r) {
        r = new uint256[](2);
        r[0] = _a;
        r[1] = _b;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        r = new uint256[](3);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d) internal pure returns (uint256[] r) {
        r = new uint256[](4);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        r = new uint256[](5);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
        r[4] = _e;
    }
}


contract ACLHelpers {
    function decodeParamOp(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 30));
    }

    function decodeParamId(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 31));
    }

    function decodeParamsList(uint256 _x) internal pure returns (uint32 a, uint32 b, uint32 c) {
        a = uint32(_x);
        b = uint32(_x >> (8 * 4));
        c = uint32(_x >> (8 * 8));
    }
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;

import "./Petrifiable.sol";


contract Autopetrified is Petrifiable {
    constructor() public {
        // Immediately petrify base (non-proxy) instances of inherited contracts on deploy.
        // This renders them uninitializable (and unusable without a proxy).
        petrify();
    }
}

pragma solidity ^0.4.24;


library ConversionHelpers {
    string private constant ERROR_IMPROPER_LENGTH = "CONVERSION_IMPROPER_LENGTH";

    function dangerouslyCastUintArrayToBytes(uint256[] memory _input) internal pure returns (bytes memory output) {
        // Force cast the uint256[] into a bytes array, by overwriting its length
        // Note that the bytes array doesn't need to be initialized as we immediately overwrite it
        // with the input and a new length. The input becomes invalid from this point forward.
        uint256 byteLength = _input.length * 32;
        assembly {
            output := _input
            mstore(output, byteLength)
        }
    }

    function dangerouslyCastBytesToUintArray(bytes memory _input) internal pure returns (uint256[] memory output) {
        // Force cast the bytes array into a uint256[], by overwriting its length
        // Note that the uint256[] doesn't need to be initialized as we immediately overwrite it
        // with the input and a new length. The input becomes invalid from this point forward.
        uint256 intsLength = _input.length / 32;
        require(_input.length == intsLength * 32, ERROR_IMPROPER_LENGTH);

        assembly {
            output := _input
            mstore(output, intsLength)
        }
    }
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;

import "../common/UnstructuredStorage.sol";


contract ReentrancyGuard {
    using UnstructuredStorage for bytes32;

    /* Hardcoded constants to save gas
    bytes32 internal constant REENTRANCY_MUTEX_POSITION = keccak256("aragonOS.reentrancyGuard.mutex");
    */
    bytes32 private constant REENTRANCY_MUTEX_POSITION = 0xe855346402235fdd185c890e68d2c4ecad599b88587635ee285bce2fda58dacb;

    string private constant ERROR_REENTRANT = "REENTRANCY_REENTRANT_CALL";

    modifier nonReentrant() {
        // Ensure mutex is unlocked
        require(!REENTRANCY_MUTEX_POSITION.getStorageBool(), ERROR_REENTRANT);

        // Lock mutex before function call
        REENTRANCY_MUTEX_POSITION.setStorageBool(true);

        // Perform function call
        _;

        // Unlock mutex after function call
        REENTRANCY_MUTEX_POSITION.setStorageBool(false);
    }
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;

import "../lib/token/ERC20.sol";
import "./EtherTokenConstant.sol";
import "./IsContract.sol";
import "./IVaultRecoverable.sol";
import "./SafeERC20.sol";


contract VaultRecoverable is IVaultRecoverable, EtherTokenConstant, IsContract {
    using SafeERC20 for ERC20;

    string private constant ERROR_DISALLOWED = "RECOVER_DISALLOWED";
    string private constant ERROR_VAULT_NOT_CONTRACT = "RECOVER_VAULT_NOT_CONTRACT";
    string private constant ERROR_TOKEN_TRANSFER_FAILED = "RECOVER_TOKEN_TRANSFER_FAILED";

    /**
     * @notice Send funds to recovery Vault. This contract should never receive funds,
     *         but in case it does, this function allows one to recover them.
     * @param _token Token balance to be sent to recovery vault.
     */
    function transferToVault(address _token) external {
        require(allowRecoverability(_token), ERROR_DISALLOWED);
        address vault = getRecoveryVault();
        require(isContract(vault), ERROR_VAULT_NOT_CONTRACT);

        uint256 balance;
        if (_token == ETH) {
            balance = address(this).balance;
            vault.transfer(balance);
        } else {
            ERC20 token = ERC20(_token);
            balance = token.staticBalanceOf(this);
            require(token.safeTransfer(vault, balance), ERROR_TOKEN_TRANSFER_FAILED);
        }

        emit RecoverToVault(vault, _token, balance);
    }

    /**
    * @dev By default deriving from AragonApp makes it recoverable
    * @param token Token address that would be recovered
    * @return bool whether the app allows the recovery
    */
    function allowRecoverability(address token) public view returns (bool) {
        return true;
    }

    // Cast non-implemented interface to be public so we can use it internally
    function getRecoveryVault() public view returns (address);
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;

import "./IEVMScriptExecutor.sol";
import "./IEVMScriptRegistry.sol";

import "../apps/AppStorage.sol";
import "../kernel/KernelConstants.sol";
import "../common/Initializable.sol";


contract EVMScriptRunner is AppStorage, Initializable, EVMScriptRegistryConstants, KernelNamespaceConstants {
    string private constant ERROR_EXECUTOR_UNAVAILABLE = "EVMRUN_EXECUTOR_UNAVAILABLE";
    string private constant ERROR_PROTECTED_STATE_MODIFIED = "EVMRUN_PROTECTED_STATE_MODIFIED";

    /* This is manually crafted in assembly
    string private constant ERROR_EXECUTOR_INVALID_RETURN = "EVMRUN_EXECUTOR_INVALID_RETURN";
    */

    event ScriptResult(address indexed executor, bytes script, bytes input, bytes returnData);

    function getEVMScriptExecutor(bytes _script) public view returns (IEVMScriptExecutor) {
        return IEVMScriptExecutor(getEVMScriptRegistry().getScriptExecutor(_script));
    }

    function getEVMScriptRegistry() public view returns (IEVMScriptRegistry) {
        address registryAddr = kernel().getApp(KERNEL_APP_ADDR_NAMESPACE, EVMSCRIPT_REGISTRY_APP_ID);
        return IEVMScriptRegistry(registryAddr);
    }

    function runScript(bytes _script, bytes _input, address[] _blacklist)
        internal
        isInitialized
        protectState
        returns (bytes)
    {
        IEVMScriptExecutor executor = getEVMScriptExecutor(_script);
        require(address(executor) != address(0), ERROR_EXECUTOR_UNAVAILABLE);

        bytes4 sig = executor.execScript.selector;
        bytes memory data = abi.encodeWithSelector(sig, _script, _input, _blacklist);

        bytes memory output;
        assembly {
            let success := delegatecall(
                gas,                // forward all gas
                executor,           // address
                add(data, 0x20),    // calldata start
                mload(data),        // calldata length
                0,                  // don't write output (we'll handle this ourselves)
                0                   // don't write output
            )

            output := mload(0x40) // free mem ptr get

            switch success
            case 0 {
                // If the call errored, forward its full error data
                returndatacopy(output, 0, returndatasize)
                revert(output, returndatasize)
            }
            default {
                switch gt(returndatasize, 0x3f)
                case 0 {
                    // Need at least 0x40 bytes returned for properly ABI-encoded bytes values,
                    // revert with "EVMRUN_EXECUTOR_INVALID_RETURN"
                    // See remix: doing a `revert("EVMRUN_EXECUTOR_INVALID_RETURN")` always results in
                    // this memory layout
                    mstore(output, 0x08c379a000000000000000000000000000000000000000000000000000000000)         // error identifier
                    mstore(add(output, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020) // starting offset
                    mstore(add(output, 0x24), 0x000000000000000000000000000000000000000000000000000000000000001e) // reason length
                    mstore(add(output, 0x44), 0x45564d52554e5f4558454355544f525f494e56414c49445f52455455524e0000) // reason

                    revert(output, 100) // 100 = 4 + 3 * 32 (error identifier + 3 words for the ABI encoded error)
                }
                default {
                    // Copy result
                    //
                    // Needs to perform an ABI decode for the expected `bytes` return type of
                    // `executor.execScript()` as solidity will automatically ABI encode the returned bytes as:
                    //    [ position of the first dynamic length return value = 0x20 (32 bytes) ]
                    //    [ output length (32 bytes) ]
                    //    [ output content (N bytes) ]
                    //
                    // Perform the ABI decode by ignoring the first 32 bytes of the return data
                    let copysize := sub(returndatasize, 0x20)
                    returndatacopy(output, 0x20, copysize)

                    mstore(0x40, add(output, copysize)) // free mem ptr set
                }
            }
        }

        emit ScriptResult(address(executor), _script, _input, output);

        return output;
    }

    modifier protectState {
        address preKernel = address(kernel());
        bytes32 preAppId = appId();
        _; // exec
        require(address(kernel()) == preKernel, ERROR_PROTECTED_STATE_MODIFIED);
        require(appId() == preAppId, ERROR_PROTECTED_STATE_MODIFIED);
    }
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


library UnstructuredStorage {
    function getStorageBool(bytes32 position) internal view returns (bool data) {
        assembly { data := sload(position) }
    }

    function getStorageAddress(bytes32 position) internal view returns (address data) {
        assembly { data := sload(position) }
    }

    function getStorageBytes32(bytes32 position) internal view returns (bytes32 data) {
        assembly { data := sload(position) }
    }

    function getStorageUint256(bytes32 position) internal view returns (uint256 data) {
        assembly { data := sload(position) }
    }

    function setStorageBool(bytes32 position, bool data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageAddress(bytes32 position, address data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageBytes32(bytes32 position, bytes32 data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageUint256(bytes32 position, uint256 data) internal {
        assembly { sstore(position, data) }
    }
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;

import "../acl/IACL.sol";
import "../common/IVaultRecoverable.sol";


interface IKernelEvents {
    event SetApp(bytes32 indexed namespace, bytes32 indexed appId, address app);
}


// This should be an interface, but interfaces can't inherit yet :(
contract IKernel is IKernelEvents, IVaultRecoverable {
    function acl() public view returns (IACL);
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);

    function setApp(bytes32 namespace, bytes32 appId, address app) public;
    function getApp(bytes32 namespace, bytes32 appId) public view returns (address);
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


interface IACL {
    function initialize(address permissionsCreator) external;

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


interface IVaultRecoverable {
    event RecoverToVault(address indexed vault, address indexed token, uint256 amount);

    function transferToVault(address token) external;

    function allowRecoverability(address token) external view returns (bool);
    function getRecoveryVault() external view returns (address);
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;

import "./Initializable.sol";


contract Petrifiable is Initializable {
    // Use block UINT256_MAX (which should be never) as the initializable date
    uint256 internal constant PETRIFIED_BLOCK = uint256(-1);

    function isPetrified() public view returns (bool) {
        return getInitializationBlock() == PETRIFIED_BLOCK;
    }

    /**
    * @dev Function to be called by top level contract to prevent being initialized.
    *      Useful for freezing base contracts when they're used behind proxies.
    */
    function petrify() internal onlyInit {
        initializedAt(PETRIFIED_BLOCK);
    }
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;

import "./TimeHelpers.sol";
import "./UnstructuredStorage.sol";


contract Initializable is TimeHelpers {
    using UnstructuredStorage for bytes32;

    // keccak256("aragonOS.initializable.initializationBlock")
    bytes32 internal constant INITIALIZATION_BLOCK_POSITION = 0xebb05b386a8d34882b8711d156f463690983dc47815980fb82aeeff1aa43579e;

    string private constant ERROR_ALREADY_INITIALIZED = "INIT_ALREADY_INITIALIZED";
    string private constant ERROR_NOT_INITIALIZED = "INIT_NOT_INITIALIZED";

    modifier onlyInit {
        require(getInitializationBlock() == 0, ERROR_ALREADY_INITIALIZED);
        _;
    }

    modifier isInitialized {
        require(hasInitialized(), ERROR_NOT_INITIALIZED);
        _;
    }

    /**
    * @return Block number in which the contract was initialized
    */
    function getInitializationBlock() public view returns (uint256) {
        return INITIALIZATION_BLOCK_POSITION.getStorageUint256();
    }

    /**
    * @return Whether the contract has been initialized by the time of the current block
    */
    function hasInitialized() public view returns (bool) {
        uint256 initializationBlock = getInitializationBlock();
        return initializationBlock != 0 && getBlockNumber() >= initializationBlock;
    }

    /**
    * @dev Function to be called by top level contract after initialization has finished.
    */
    function initialized() internal onlyInit {
        INITIALIZATION_BLOCK_POSITION.setStorageUint256(getBlockNumber());
    }

    /**
    * @dev Function to be called by top level contract after initialization to enable the contract
    *      at a future block number rather than immediately.
    */
    function initializedAt(uint256 _blockNumber) internal onlyInit {
        INITIALIZATION_BLOCK_POSITION.setStorageUint256(_blockNumber);
    }
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;

import "./Uint256Helpers.sol";


contract TimeHelpers {
    using Uint256Helpers for uint256;

    /**
    * @dev Returns the current block number.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
    * @dev Returns the current block number, converted to uint64.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber64() internal view returns (uint64) {
        return getBlockNumber().toUint64();
    }

    /**
    * @dev Returns the current timestamp.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp() internal view returns (uint256) {
        return block.timestamp; // solium-disable-line security/no-block-members
    }

    /**
    * @dev Returns the current timestamp, converted to uint64.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp64() internal view returns (uint64) {
        return getTimestamp().toUint64();
    }
}

pragma solidity ^0.4.24;


library Uint256Helpers {
    uint256 private constant MAX_UINT64 = uint64(-1);

    string private constant ERROR_NUMBER_TOO_BIG = "UINT64_NUMBER_TOO_BIG";

    function toUint64(uint256 a) internal pure returns (uint64) {
        require(a <= MAX_UINT64, ERROR_NUMBER_TOO_BIG);
        return uint64(a);
    }
}

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/a9f910d34f0ab33a1ae5e714f69f9596a02b4d91/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
        public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


contract IsContract {
    /*
    * NOTE: this should NEVER be used for authentication
    * (see pitfalls: https://github.com/fergarrui/ethereum-security/tree/master/contracts/extcodesize).
    *
    * This is only intended to be used as a sanity check that an address is actually a contract,
    * RATHER THAN an address not being a contract.
    */
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }
}

// Inspired by AdEx (https://github.com/AdExNetwork/adex-protocol-eth/blob/b9df617829661a7518ee10f4cb6c4108659dd6d5/contracts/libs/SafeERC20.sol)
// and 0x (https://github.com/0xProject/0x-monorepo/blob/737d1dc54d72872e24abce5a1dbe1b66d35fa21a/contracts/protocol/contracts/protocol/AssetProxy/ERC20Proxy.sol#L143)

pragma solidity ^0.4.24;

import "../lib/token/ERC20.sol";


library SafeERC20 {
    // Before 0.5, solidity has a mismatch between `address.transfer()` and `token.transfer()`:
    // https://github.com/ethereum/solidity/issues/3544
    bytes4 private constant TRANSFER_SELECTOR = 0xa9059cbb;

    string private constant ERROR_TOKEN_BALANCE_REVERTED = "SAFE_ERC_20_BALANCE_REVERTED";
    string private constant ERROR_TOKEN_ALLOWANCE_REVERTED = "SAFE_ERC_20_ALLOWANCE_REVERTED";

    function invokeAndCheckSuccess(address _addr, bytes memory _calldata)
        private
        returns (bool)
    {
        bool ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            let success := call(
                gas,                  // forward all gas
                _addr,                // address
                0,                    // no value
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
                // Check number of bytes returned from last function call
                switch returndatasize

                // No bytes returned: assume success
                case 0 {
                    ret := 1
                }

                // 32 bytes returned: check if non-zero
                case 0x20 {
                    // Only return success if returned data was true
                    // Already have output in ptr
                    ret := eq(mload(ptr), 1)
                }

                // Not sure what was returned: don't mark as success
                default { }
            }
        }
        return ret;
    }

    function staticInvoke(address _addr, bytes memory _calldata)
        private
        view
        returns (bool, uint256)
    {
        bool success;
        uint256 ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            success := staticcall(
                gas,                  // forward all gas
                _addr,                // address
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
                ret := mload(ptr)
            }
        }
        return (success, ret);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transfer() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransfer(ERC20 _token, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferCallData = abi.encodeWithSelector(
            TRANSFER_SELECTOR,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(_token, transferCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transferFrom() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransferFrom(ERC20 _token, address _from, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferFromCallData = abi.encodeWithSelector(
            _token.transferFrom.selector,
            _from,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(_token, transferFromCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.approve() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeApprove(ERC20 _token, address _spender, uint256 _amount) internal returns (bool) {
        bytes memory approveCallData = abi.encodeWithSelector(
            _token.approve.selector,
            _spender,
            _amount
        );
        return invokeAndCheckSuccess(_token, approveCallData);
    }

    /**
    * @dev Static call into ERC20.balanceOf().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticBalanceOf(ERC20 _token, address _owner) internal view returns (uint256) {
        bytes memory balanceOfCallData = abi.encodeWithSelector(
            _token.balanceOf.selector,
            _owner
        );

        (bool success, uint256 tokenBalance) = staticInvoke(_token, balanceOfCallData);
        require(success, ERROR_TOKEN_BALANCE_REVERTED);

        return tokenBalance;
    }

    /**
    * @dev Static call into ERC20.allowance().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticAllowance(ERC20 _token, address _owner, address _spender) internal view returns (uint256) {
        bytes memory allowanceCallData = abi.encodeWithSelector(
            _token.allowance.selector,
            _owner,
            _spender
        );

        (bool success, uint256 allowance) = staticInvoke(_token, allowanceCallData);
        require(success, ERROR_TOKEN_ALLOWANCE_REVERTED);

        return allowance;
    }
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


interface IEVMScriptExecutor {
    function execScript(bytes script, bytes input, address[] blacklist) external returns (bytes);
    function executorType() external pure returns (bytes32);
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;

import "./IEVMScriptExecutor.sol";


contract EVMScriptRegistryConstants {
    /* Hardcoded constants to save gas
    bytes32 internal constant EVMSCRIPT_REGISTRY_APP_ID = apmNamehash("evmreg");
    */
    bytes32 internal constant EVMSCRIPT_REGISTRY_APP_ID = 0xddbcfd564f642ab5627cf68b9b7d374fb4f8a36e941a75d89c87998cef03bd61;
}


interface IEVMScriptRegistry {
    function addScriptExecutor(IEVMScriptExecutor executor) external returns (uint id);
    function disableScriptExecutor(uint256 executorId) external;

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function getScriptExecutor(bytes script) public view returns (IEVMScriptExecutor);
}

/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.4.24;


contract KernelAppIds {
    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_CORE_APP_ID = apmNamehash("kernel");
    bytes32 internal constant KERNEL_DEFAULT_ACL_APP_ID = apmNamehash("acl");
    bytes32 internal constant KERNEL_DEFAULT_VAULT_APP_ID = apmNamehash("vault");
    */
    bytes32 internal constant KERNEL_CORE_APP_ID = 0x3b4bf6bf3ad5000ecf0f989d5befde585c6860fea3e574a4fab4c49d1c177d9c;
    bytes32 internal constant KERNEL_DEFAULT_ACL_APP_ID = 0xe3262375f45a6e2026b7e7b18c2b807434f2508fe1a2a3dfb493c7df8f4aad6a;
    bytes32 internal constant KERNEL_DEFAULT_VAULT_APP_ID = 0x7e852e0fcfce6551c13800f1e7476f982525c2b5277ba14b24339c68416336d1;
}


contract KernelNamespaceConstants {
    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_CORE_NAMESPACE = keccak256("core");
    bytes32 internal constant KERNEL_APP_BASES_NAMESPACE = keccak256("base");
    bytes32 internal constant KERNEL_APP_ADDR_NAMESPACE = keccak256("app");
    */
    bytes32 internal constant KERNEL_CORE_NAMESPACE = 0xc681a85306374a5ab27f0bbc385296a54bcd314a1948b6cf61c4ea1bc44bb9f8;
    bytes32 internal constant KERNEL_APP_BASES_NAMESPACE = 0xf1f3eb40f5bc1ad1344716ced8b8a0431d840b5783aea1fd01786bc26f35ac0f;
    bytes32 internal constant KERNEL_APP_ADDR_NAMESPACE = 0xd6f028ca0e8edb4a8c9757ca4fdccab25fa1e0317da1188108f7d2dee14902fb;
}

pragma solidity 0.4.24;

import "./UnstructuredStorage.sol";


contract DepositableStorage {
    using UnstructuredStorage for bytes32;

    // keccak256("aragonOS.depositableStorage.depositable")
    bytes32 internal constant DEPOSITABLE_POSITION = 0x665fd576fbbe6f247aff98f5c94a561e3f71ec2d3c988d56f12d342396c50cea;

    function isDepositable() public view returns (bool) {
        return DEPOSITABLE_POSITION.getStorageBool();
    }

    function setDepositable(bool _depositable) internal {
        DEPOSITABLE_POSITION.setStorageBool(_depositable);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}