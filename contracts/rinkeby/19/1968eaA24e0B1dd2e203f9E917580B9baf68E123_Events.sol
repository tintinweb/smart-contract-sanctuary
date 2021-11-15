// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./interfaces/IEvents.sol";

contract Events is IEvents {
    /// CONSTRUCTOR ///

    function initialize(address _homeFi) external override initializer {
        require(_homeFi != address(0), "Events::0 address");
        homeFi = IHomeFiContract(_homeFi);
    }

    /// FUNCTIONS ///

    function addressSet() external override onlyHomeFi {
        emit AddressSet();
    }

    function projectAdded(
        uint256 _projectID,
        address _project,
        address _builder,
        address _currency,
        bytes calldata _hash
    ) external override onlyHomeFi {
        emit ProjectAdded(_projectID, _project, _builder, _currency, _hash);
    }

    function nftCreated(uint256 _id, address _owner)
        external
        override
        onlyHomeFi
    {
        emit NftCreated(_id, _owner);
    }

    function adminReplaced(address _newAdmin) external override onlyHomeFi {
        emit AdminReplaced(_newAdmin);
    }

    function treasuryReplaced(address _newTreasury)
        external
        override
        onlyHomeFi
    {
        emit TreasuryReplaced(_newTreasury);
    }

    function networkFeeReplaced(uint256 _newBuilderFee, uint256 _newInvestorFee)
        external
        override
        onlyHomeFi
    {
        emit NetworkFeeReplaced(_newBuilderFee, _newInvestorFee);
    }

    function hashUpdated(bytes calldata _updatedHash)
        external
        override
        validProject
    {
        emit HashUpdated(msg.sender, _updatedHash);
    }

    function contractorInvited(
        address _contractor,
        uint256[] calldata _phaseCosts
    ) external override validProject {
        emit ContractorInvited(msg.sender, _contractor, _phaseCosts);
    }

    function contractorConfirmed(address _contractor)
        external
        override
        validProject
    {
        emit ContractorConfirmed(msg.sender, _contractor);
    }

    function phasesAdded(uint256[] calldata _phaseCosts)
        external
        override
        validProject
    {
        emit PhasesAdded(msg.sender, _phaseCosts);
    }

    function phasesUpdated(
        uint256[] calldata _phaseList,
        uint256[] calldata _phaseCosts
    ) external override validProject {
        emit PhasesUpdated(msg.sender, _phaseList, _phaseCosts);
    }

    function taskHashUpdated(uint256 _taskID, bytes32[2] calldata _taskHash)
        external
        override
        validProject
    {
        emit TaskHashUpdated(msg.sender, _taskID, _taskHash);
    }

    function tasksAdded(uint256 _phaseID, uint256[] calldata _taskCosts)
        external
        override
        validProject
    {
        emit TasksAdded(msg.sender, _phaseID, _taskCosts);
    }

    function investedInProject(uint256 _cost) external override validProject {
        emit InvestedInProject(msg.sender, _cost);
    }

    function multipleSCInvited(
        uint256[] calldata _taskList,
        address[] calldata _scList
    ) external override validProject {
        emit MultipleSCInvited(msg.sender, _taskList, _scList);
    }

    function singleSCInvited(uint256 _taskID, address _sc)
        external
        override
        validProject
    {
        emit SingleSCInvited(msg.sender, _taskID, _sc);
    }

    function scConfirmed(uint256 _taskID) external override validProject {
        emit SCConfirmed(msg.sender, _taskID);
    }

    function taskFunded(uint256 _taskID) external override validProject {
        emit TaskFunded(msg.sender, _taskID);
    }

    function taskComplete(uint256 _taskID) external override validProject {
        emit TaskComplete(msg.sender, _taskID);
    }

    function contractorFeeReleased(uint256 _phaseID)
        external
        override
        validProject
    {
        emit ContractorFeeReleased(msg.sender, _phaseID);
    }

    function changeOrderFee(uint256 _taskID, uint256 _newCost)
        external
        override
        validProject
    {
        emit ChangeOrderFee(msg.sender, _taskID, _newCost);
    }

    function changeOrderSC(uint256 _taskID, address _sc)
        external
        override
        validProject
    {
        emit ChangeOrderSC(msg.sender, _taskID, _sc);
    }

    function autoWithdrawn(uint256 _amount) external override validProject {
        emit AutoWithdrawn(msg.sender, _amount);
    }

    function disputeRaised(uint256 _disputeID)
        external
        override
        onlyDisputeContract
    {
        emit DisputeRaised(_disputeID);
    }

    function disputeResolved(uint256 _disputeID, bool _ratified)
        external
        override
        onlyDisputeContract
    {
        emit DisputeResolved(_disputeID, _ratified);
    }

    function disputeAttachmentAdded(
        uint256 _disputeID,
        address _user,
        uint256 _attachmentID,
        bytes calldata _attachment
    ) external override onlyDisputeContract {
        emit DisputeAttachmentAdded(
            _disputeID,
            _user,
            _attachmentID,
            _attachment
        );
    }

    function communityAdded(
        uint256 _communityID,
        address _owner,
        address _currency,
        bytes calldata _hash
    ) external override onlyCommunityContract {
        emit CommunityAdded(_communityID, _owner, _currency, _hash);
    }

    function updateCommunityHash(
        uint256 _communityID,
        bytes calldata _oldHash,
        bytes calldata _newHash
    ) external override onlyCommunityContract {
        emit UpdateCommunityHash(_communityID, _oldHash, _newHash);
    }

    function memberAdded(uint256 _communityID, address _member)
        external
        override
        onlyCommunityContract
    {
        emit MemberAdded(_communityID, _member);
    }

    function projectPublished(
        uint256 _communityID,
        address _project,
        uint256 _apr
    ) external override onlyCommunityContract {
        emit ProjectPublished(_communityID, _project, _apr);
    }

    function investorInvested(
        uint256 _communityID,
        address _project,
        address _investor,
        uint256 _cost,
        uint256 _investmentDate
    ) external override onlyCommunityContract {
        emit InvestorInvested(
            _communityID,
            _project,
            _investor,
            _cost,
            _investmentDate
        );
    }

    function repayInvestor(
        uint256 _communityID,
        address _project,
        address _investor,
        uint256 _tAmount,
        uint256 _repayDate
    ) external override onlyCommunityContract {
        emit RepayInvestor(
            _communityID,
            _project,
            _investor,
            _tAmount,
            _repayDate
        );
    }

    function debtTransferred(
        uint256 _communityID,
        address _project,
        address _investor,
        address _to,
        uint256 _totalAmount
    ) external override onlyCommunityContract {
        emit DebtTransferred(
            _communityID,
            _project,
            _investor,
            _to,
            _totalAmount
        );
    }

    function claimedInterest(
        uint256 _communityID,
        address _project,
        address _investor,
        uint256 _interestEarned,
        uint256 _totalAmount
    ) external override onlyCommunityContract {
        emit ClaimedInterest(
            _communityID,
            _project,
            _investor,
            _interestEarned,
            _totalAmount
        );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IHomeFiContract {
    function projectExist(address _project) external returns (bool);

    function communityContract() external returns (address);

    function disputeContract() external returns (address);
}

abstract contract IEvents is Initializable {
    /// EVENTS ///

    // HomeFi.sol Events //
    event AddressSet();
    event ProjectAdded(
        uint256 _projectID,
        address indexed _project,
        address indexed _builder,
        address indexed _currency,
        bytes _hash
    );
    event NftCreated(uint256 _id, address _owner);
    event AdminReplaced(address _newAdmin);
    event TreasuryReplaced(address _newTreasury);
    event NetworkFeeReplaced(uint256 _newBuilderFee, uint256 _newInvestorFee);

    // Project.sol Events //
    event HashUpdated(address indexed _project, bytes _hash);
    event ContractorInvited(
        address indexed _project,
        address indexed _newContractor,
        uint256[] _phaseCosts
    );
    event ContractorConfirmed(
        address indexed _project,
        address indexed _contractor
    );
    event PhasesAdded(address indexed _project, uint256[] _phaseCosts);
    event PhasesUpdated(
        address indexed _project,
        uint256[] _phaseList,
        uint256[] _phaseCosts
    );
    event InvestedInProject(address indexed _project, uint256 _cost);
    event TasksAdded(
        address indexed _project,
        uint256 _phaseID,
        uint256[] _taskCosts
    );
    event TaskHashUpdated(
        address indexed _project,
        uint256 _taskID,
        bytes32[2] _taskHash
    );
    event MultipleSCInvited(
        address indexed _project,
        uint256[] _taskList,
        address[] _scList
    );
    event SingleSCInvited(
        address indexed _project,
        uint256 _taskID,
        address _sc
    );
    event SCConfirmed(address indexed _project, uint256 _taskID);
    event TaskFunded(address indexed _project, uint256 _taskID);
    event TaskComplete(address indexed _project, uint256 _taskID);
    event ContractorFeeReleased(address indexed _project, uint256 _phaseID);
    event ChangeOrderFee(
        address indexed _project,
        uint256 _taskID,
        uint256 _newCost
    );
    event ChangeOrderSC(address indexed _project, uint256 _taskID, address _sc);
    event AutoWithdrawn(address indexed _project, uint256 _amount);

    // Disputes.sol Events //
    event DisputeRaised(uint256 indexed _disputeID);
    event DisputeResolved(uint256 indexed _disputeID, bool _ratified);
    event DisputeAttachmentAdded(
        uint256 indexed _disputeID,
        address _user,
        uint256 _attachmentID,
        bytes _attachment
    );

    // Community.sol Events //
    event CommunityAdded(
        uint256 _communityID,
        address indexed _owner,
        address indexed _currency,
        bytes _hash
    );
    event UpdateCommunityHash(
        uint256 _communityID,
        bytes _oldHash,
        bytes _newHash
    );
    event MemberAdded(uint256 indexed _communityID, address indexed _member);
    event ProjectPublished(
        uint256 indexed _communityID,
        address indexed _project,
        uint256 _apr
    );
    event InvestorInvested(
        uint256 indexed _communityID,
        address indexed _project,
        address indexed _investor,
        uint256 _cost,
        uint256 _investmentDate
    );
    event RepayInvestor(
        uint256 indexed _communityID,
        address indexed _project,
        address indexed _investor,
        uint256 _tAmount,
        uint256 _repayDate
    );
    event DebtTransferred(
        uint256 indexed _communityID,
        address indexed _project,
        address indexed _investor,
        address _to,
        uint256 _totalAmount
    );
    event ClaimedInterest(
        uint256 indexed _communityID,
        address indexed _project,
        address indexed _investor,
        uint256 _interestEarned,
        uint256 _totalAmount
    );

    /// MODIFIERS ///
    modifier validProject() {
        // ensure that the caller is an instance of Project.sol
        require(homeFi.projectExist(msg.sender), "Events::!ProjectContract");
        _;
    }

    modifier onlyDisputeContract() {
        // ensure that the caller is deployed instance of Dispute.sol
        require(
            homeFi.disputeContract() == msg.sender,
            "Events::!DisputeContract"
        );
        _;
    }

    modifier onlyHomeFi() {
        // ensure that the caller is the deployed instance of HomeFi.sol
        require(address(homeFi) == msg.sender, "Events::!HomeFiContract");
        _;
    }

    modifier onlyCommunityContract() {
        // ensure that the caller is the deployed instance of Community.sol
        require(
            homeFi.communityContract() == msg.sender,
            "Events::!CommunityContract"
        );
        _;
    }

    IHomeFiContract public homeFi;

    /// CONSTRUCTOR ///

    /**
     * Initialize a new events contract
     * @notice THIS IS THE CONSTRUCTOR thanks upgradable proxies
     * @dev modifier initializer
     *
     * @param _homeFi IHomeFi - instance of main Rigor contract. Can be accessed with raw address
     */
    function initialize(address _homeFi) external virtual;

    /// FUNCTIONS ///

    /**
     * Call to event when address is set
     * @dev modifier onlyHomeFi
     */
    function addressSet() external virtual;

    /**
     * Call to emit when a project is created (new NFT is minted)
     * @dev modifier onlyHomeFi
     *
     * @param _projectID uint256 - the ERC721 enumerable index/ uuid of the project
     * @param _project address - the address of the newly deployed project contract
     * @param _builder address - the address of the user permissioned as the project's builder
     */
    function projectAdded(
        uint256 _projectID,
        address _project,
        address _builder,
        address _currency,
        bytes calldata _hash
    ) external virtual;

    /**
     * Call to emit when a new project & accompanying ERC721 token have been created
     * @dev modifier onlyHomeFi
     *
     * @param _id uint256 - the ERC721 enumerable serial/ project id
     * @param _owner address - address permissioned as project's builder/ nft owner
     */
    function nftCreated(uint256 _id, address _owner) external virtual;

    /**
     * Call to emit when HomeFi admin is replaced
     * @dev modifier onlyHomeFi
     *
     * @param _newAdmin address - address of the new admin
     */
    function adminReplaced(address _newAdmin) external virtual;

    /**
     * Call to emit when HomeFi treasury is replaced
     * @dev modifier onlyHomeFi
     *
     * @param _newTreasury address - address of the new treasury
     */
    function treasuryReplaced(address _newTreasury) external virtual;

    /**
     * Call to emit when HomeFi treasury network fee is updated
     * @dev modifier onlyHomeFi
     *
     * @param _newBuilderFee uint256 - percentage of fee builder have to pay to rigor system
     * @param _newInvestorFee uint256 - percentage of fee investor have to pay to rigor system
     */
    function networkFeeReplaced(uint256 _newBuilderFee, uint256 _newInvestorFee)
        external
        virtual;

    /**
     * Call to emit when the hash of a project is updated
     *
     * @param _updatedHash bytes - hash of project metadata used to identify the project
     */
    function hashUpdated(bytes calldata _updatedHash) external virtual;

    /**
     * Call to emit when a new General Contractor is invited to a HomeFi project
     * @dev modifier validProject
     *
     * @param _contractor address - the address invited to the project as the general contractor
     * @param _phaseCosts uint256[] - array (length = number of phases) of contractor fees to be paid per phase
     */
    function contractorInvited(
        address _contractor,
        uint256[] calldata _phaseCosts
    ) external virtual;

    /**
     * Call to emit when a project's general contractor is confirmed
     * @dev modifier validProject
     *
     * @param _contractor address - the address confirmed as the project general contractor
     */
    function contractorConfirmed(address _contractor) external virtual;

    /**
     * Call to emit when a project has phases added
     * @dev modifier validProject
     *
     * @param _phaseCosts uint256[] - array of added phases' costs
     */
    function phasesAdded(uint256[] calldata _phaseCosts) external virtual;

    /**
     * Call to emit when a project's phases are updated
     * @dev modifier validProject
     *
     * @param _phaseList uint256[] - array of phase indices to mutate cost for
     * @param _phaseCosts uint256[] - array of phaseCosts to change with array index corresponding to _phaseList[index] task
     */
    function phasesUpdated(
        uint256[] calldata _phaseList,
        uint256[] calldata _phaseCosts
    ) external virtual;

    /**
     * Call to emit when a task's identifying hash is changed
     * @dev modifier validProject
     *
     * @param _taskID uint256 - the uuid of the updated task
     * @param _taskHash bytes[32] - a 64 byte hash that is split in two given max bytes size of 32
     */
    function taskHashUpdated(uint256 _taskID, bytes32[2] calldata _taskHash)
        external
        virtual;

    /**
     * Call to emit when a new task is created in a project
     * @dev modifier validProject
     *
     * @param _phaseID uint256 - the phase to which the task was added
     * @param _taskCosts uint256[] - array of added tasks' costs
     */
    function tasksAdded(uint256 _phaseID, uint256[] calldata _taskCosts)
        external
        virtual;

    /**
     * Call to emit when an investor has loaned funds to a project
     * @dev modifier validProject
     *
     * @param _cost uint256 - the amount of currency invested in the project (depends on project currency)
     */
    function investedInProject(uint256 _cost) external virtual;

    /**
     * Call to emit when subcontractors are invited to tasks
     * @dev modifier validProject
     *
     * @param _taskList uint256[] - the list of uuids of the tasks the subcontractors are being invited to
     * @param _scList address[] - the addresses of the users being invited as subcontractor to the tasks
     */
    function multipleSCInvited(
        uint256[] calldata _taskList,
        address[] calldata _scList
    ) external virtual;

    /**
     * Call to emit when a subcontractor is invited to a task
     * @dev modifier validProject
     *
     * @param _taskID uint256 - the uuid of the task the subcontractor is being invited to
     * @param _sc address - the address of the user being invited as subcontractor to the task
     */
    function singleSCInvited(uint256 _taskID, address _sc) external virtual;

    /**
     * Call to emit when a subcontractor is confirmed for a task
     * @dev modifier validProject
     *
     * @param _taskID uint256 - the uuid of the task joined by the subcontractor
     */
    function scConfirmed(uint256 _taskID) external virtual;

    /**
     * Call to emit when a task is funded
     * @dev modifier validProject
     *
     * @param _taskID uint256 - the uuid of the funded task
     */
    function taskFunded(uint256 _taskID) external virtual;

    /**
     * Call to emit when a task has been completed
     * @dev modifier validProject
     *
     * @param _taskID uint256 - the uuid of the completed task
     */
    function taskComplete(uint256 _taskID) external virtual;

    /**
     * Call to emit when a phase has been completed/ the contractor fee for the phase has been released from escrow
     * @dev modifier validProject
     *
     * @param _phaseID uint256 - the index of the completed phase
     */
    function contractorFeeReleased(uint256 _phaseID) external virtual;

    /**
     * Call to emit when a task has a change order changing the cost of a task
     * @dev modifier validProject
     *
     * @param _taskID uint256 - the uuid of the task where the change order occurred
     * @param _newCost uint256 - the new cost of the task (in the project currency)
     */
    function changeOrderFee(uint256 _taskID, uint256 _newCost) external virtual;

    /**
     * Call to emit when a task has a change order that swaps the subcontractor on the task
     * @dev modifier validProject
     *
     * @param _taskID uint256 - the uuid of the task where the change order occurred
     * @param _sc uint256 - the subcontractor being added to the task in the change order
     */
    function changeOrderSC(uint256 _taskID, address _sc) external virtual;

    /**
     * Call to event when transfer excess funds back to builder wallet
     * @dev modifier validProject
     *
     * @param _amount uint256 - amount of excess fund
     */
    function autoWithdrawn(uint256 _amount) external virtual;

    /**
     * Call to emit when an investor's loan is repaid with interest
     * @dev modifier onlyCommunityContract
     *
     * @param _communityID uint256 - the uuid of the community that the project loan occurred in
     * @param _project address - the address of the deployed contract address where the loan was escrowed
     * @param _investor address - the address that supplied the loan/ is receiving repayment
     * @param _tAmount uint256 - the amount repaid to the investor (principal + interest) in the project currency
     * @param _repayDate uint256 - timestamp of block that contains the repayment transaction
     */
    function repayInvestor(
        uint256 _communityID,
        address _project,
        address _investor,
        uint256 _tAmount,
        uint256 _repayDate
    ) external virtual;

    /**
     * Call to emit when a new dispute is raised
     * @dev modifier onlyDisputeContract
     *
     * @param _disputeID uint256 - the uuid/ serial of the dispute within the dispute contract
     */
    function disputeRaised(uint256 _disputeID) external virtual;

    /**
     * Call to emit when a dispute has been arbitrated and funds have been directed to the correct address
     * @dev modifier onlyDisputeContract
     *
     * @param _disputeID uint256 - the uuid/serial of the dispute within the dispute contract
     * @param _ratified bool - true if disputed action was enforced by arbitration, and false otherwise
     */
    function disputeResolved(uint256 _disputeID, bool _ratified)
        external
        virtual;

    /**
     * Call to emit when a document is attached to a dispute
     * @dev modifier onlyDisputeContract
     *
     * @param _disputeID uint256 - the uuid/ serial of the dispute
     * @param _user address - the address of the user uploading the document
     * @param _attachment uint256 - the index of the dispute attachment document
     * @param _attachment bytes - the IPFS cid of the dispute attachment document
     */
    function disputeAttachmentAdded(
        uint256 _disputeID,
        address _user,
        uint256 _attachmentID,
        bytes calldata _attachment
    ) external virtual;

    /**
     * Call to emit when a new investment community is created
     * @dev modifier onlyCommunityContract
     *
     * @param _communityID uint256 - the uuid/ serial of the created investment community
     * @param _owner address - the address of the user who manages the investment community
     * @param _currency address - the address of the currency used as collateral in projects within the community
     * @param _hash bytes - the hash of community metadata used to identify the community
     */
    function communityAdded(
        uint256 _communityID,
        address _owner,
        address _currency,
        bytes calldata _hash
    ) external virtual;

    /**
     * Call to emit when a community's identifying hash is updated
     * @dev modifier onlyCommunityContract
     *
     * @param _communityID uint256 - the uuid/ serial of the investment community whose hash is being updated
     * @param _oldHash bytes - the old hash of community metadata used to identify the community being removed
     * @param _newHash bytes - the new hash of community metadata used to identify the community being added
     */
    function updateCommunityHash(
        uint256 _communityID,
        bytes calldata _oldHash,
        bytes calldata _newHash
    ) external virtual;

    /**
     * Call to emit when a member has been added to an investment community as a new investor
     * @dev modifier onlyCommunityContract
     *
     * @param _communityID uint256 - the uuid/ serial of the investment community being joined
     * @param _member address - the address of the user joining the community as an investor
     */
    function memberAdded(uint256 _communityID, address _member)
        external
        virtual;

    /**
     * Call to emit when a project is added to an investment community for fund raising
     * @dev modifier onlyCommunityContract
     *
     * @param _communityID uint256 - the uuid/ serial of the community being published to
     * @param _project address - the address of the deployed project contract where loans are escrowed
     * @param _apr uint256 - the annual percentage return (interest rate) on loans made to the project
     */
    function projectPublished(
        uint256 _communityID,
        address _project,
        uint256 _apr
    ) external virtual;

    /**
     * Call to emit when an investor loans funds to a project
     * @dev modifier onlyCommunityContract
     *
     * @param _communityID uint256 - the uuid/ serial of the community the project is published in
     * @param _project address - the address of the deployed project contract the investor loaned funds to
     * @param _investor address - the address of the investing user
     * @param _cost uint256 - the amount of funds invested by _investor, in the project currency
     * @param _investmentDate - the timestamp of the block containing the investment transaction
     */
    function investorInvested(
        uint256 _communityID,
        address _project,
        address _investor,
        uint256 _cost,
        uint256 _investmentDate
    ) external virtual;

    /**
     * Call to emit when fractional ownership of a project's debt is transferred
     * @dev modifier onlyCommunityContract
     *
     * @param _communityID uint256 - the uuid/ serial of the community the project is published in
     * @param _project address - the address of the deployed project contract tracked by the NFT
     * @param _investor address - the current owner who is sending the fractional ownership of the NFT
     * @param _to address - the new owner who is the recipient of fractional ownership of the NFT
     * @param _totalAmount uint256 - the amount of debt tokens transferred (in the project's wrapped currency)
     */
    function debtTransferred(
        uint256 _communityID,
        address _project,
        address _investor,
        address _to,
        uint256 _totalAmount
    ) external virtual;

    /**
     * Call to emit when an investor claims their repayment with interest
     * @dev modifier onlyCommunityContract
     *
     * @param _communityID uint256 - the uuid/ serial of the community the project is published in
     * @param _project address - the address of the deployed project contract the investor loaned to
     * @param _investor address - the address of the investor claiming interest
     * @param _interestEarned uint256 - the amount of collateral tokens earned in interest (in project's currency)
     * @param _totalAmount uint256 - collateral tokens: principal + interest returned to investor
     */
    function claimedInterest(
        uint256 _communityID,
        address _project,
        address _investor,
        uint256 _interestEarned,
        uint256 _totalAmount
    ) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

