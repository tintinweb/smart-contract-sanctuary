pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED

import "../governance/interfaces/IRateGovernor.sol";
import "../utils/interfaces/IDAOAccess.sol";
import "../proposals/Proposals.sol";
import "./interfaces/IProposalManager.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ProposalManager is IProposalManager {
    /// @notice Import from libraries
    using Counters for Counters.Counter;
    using Proposals for Proposals.ProductProposal;
    using Proposals for Proposals.DevelopmentProposal;
    using Proposals for Proposals.Rate;
    using Proposals for Proposals.DevDays;
    using Proposals for Proposals.ProposalState;
    using Proposals for Proposals.EntityType;
    using SafeMath for uint256;

    // contracts needed
    IRateGovernor rateGovernor;
    IDAOAccess daoAccess;

    // addresses of who can set proposal states/votes.
    address daoVoting;
    address askoDAO;

    // proposal ID
    Counters.Counter private proposalIds;

    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => Proposals.DevelopmentProposal)
        public developmentProposals;
    mapping(uint256 => Proposals.ProductProposal) public productProposals;

    /// @notice Record to make sure each person has only 1 active proposal
    mapping(address => bool) public hasActiveProposal;

    /// @notice An event emitted when a new proposal is created
    event ProductProposalCreated(
        uint256 id,
        string name,
        address receiver,
        address proposer,
        uint256 budget,
        string description,
        string developer,
        uint256 devDays,
        uint256 interval,
        string TGHandle,
        string URL
    );

    /// @notice An event emitted when a new proposal is created
    event DevelopmentProposalCreated(
        uint256 id,
        address receiver,
        address proposer,
        uint256 budget,
        string description
    );

    /**
     * TODO: Complete
     */
    modifier onlyAskoDAO() {
        require(msg.sender == askoDAO, "Must be the AskoDAO contract");
        _;
    }

    modifier onlyDAOVoting() {
        require(msg.sender == daoVoting, "Must be the AskoDAO voting contract");
        _;
    }

    modifier onlyDAOOrVoting() {
        require(msg.sender == daoVoting || msg.sender == askoDAO, "Must be AskoDAO or AskoDAO voting contract");
        _;
    }

    modifier hasNoActiveProposals(address proposer) {
        require(!hasActiveProposal[proposer], "Already has an active proposal");
        _;
    }

    /**
     * Restricts access to only the guardian
     */
    modifier onlyGuardian() {
        require(
            daoAccess.isGuardian(msg.sender),
            "Must have guardian permissions"
        );
        _;
    }

    /**
     * Restricts access to only the DDF
     */
    modifier onlyDDF(address sender, uint256 blockNumber) {
        require(daoAccess.isDDF(sender, blockNumber), "Must have DDF permissionsguardian permissions");
        _;
    }

    /**
     * Restricted to only valid proposals
     */
    modifier onlyValidProposals(uint256 proposalId) {
        _validateProposal(proposalId);
        _;
    }

    /**
     * @notice TODO: Complete
     */
    constructor(address _daoAccess, address _rateGovernor) {
        // initalize rate governor
        rateGovernor = IRateGovernor(_rateGovernor);
        daoAccess = IDAOAccess(_daoAccess);

        // ensure proposalIds do not match each other at the start
        productProposals[0].id = 1;
        developmentProposals[0].id = 1;
    }

    function setAskoDAO(address _askoDAO) public onlyGuardian {
        askoDAO = _askoDAO;
    }

    function setDAOVoting(address _daoVoting) public onlyGuardian {
        daoVoting = _daoVoting;
    }

    /**
     * @notice Propose a new development proposal.
     * @param receiver address of budget reciever
     * @param proposer proposer who proposed the proposal
     * @param budget budget needed for the proposal
     * @param description description of proposal
     */
    function proposeDevelopment(
        address receiver,
        address proposer,
        uint256 budget,
        string memory description
    ) public override onlyAskoDAO hasNoActiveProposals(proposer) onlyDDF(proposer, block.number - 1) {
        uint256 proposalId = _proposeDevelopment(receiver, proposer, budget, description);
        hasActiveProposal[proposer] = true;
        emit DevelopmentProposalCreated(
            proposalId,
            receiver,
            proposer,
            budget,
            description
        );
    }

    /**
     * @notice Propose a new product proposal
     * @param name Name of the product
     * @param receiver address of budget reciever
     * @param proposer proposer who proposed the proposal
     * @param budget budget needed for the proposal
     * @param description description of proposal
     * @param developer name of developer if possible
     * @param devDays number of dev days
     * @param interval length of development
     * @param TGHandle telegram handle
     * @param URL url of the project
     */
    function proposeProduct(
        string memory name,
        address receiver,
        address proposer,
        uint256 budget,
        string memory description,
        string memory developer,
        uint256 devDays,
        uint256 interval,
        string memory TGHandle,
        string memory URL
    ) public override onlyAskoDAO hasNoActiveProposals(proposer) {
        uint256 proposalId = _proposeProduct(
            name,
            receiver,
            proposer,
            budget,
            description,
            developer,
            devDays,
            interval,
            TGHandle,
            URL
        );
        hasActiveProposal[proposer] = true;
        emit ProductProposalCreated(
            proposalId,
            name,
            receiver,
            proposer,
            budget,
            description,
            developer,
            devDays,
            interval,
            TGHandle,
            URL
        );
        //timelock.queue(shut it down in 30 days)
    }

    /**
     * @notice Returns threshold
     * @param proposalId id of the proposal
     * @param rateId id of the rate which corresponds to the following:
     *      2 - Yes Rate (product only)
     *      3 - Approval Rate
     *      4 - Product Proposal Continuation Rate (product only)
     *      5 - Admin veto rate (product only)
     * @return number of for votes
     */
    function getVoteThreshold(uint256 proposalId, uint8 rateId)
        public
        view
        override
        onlyValidProposals(proposalId)
        returns (uint256)
    {
        return _getProposalVotes(proposalId, rateId, 2);
    }

    /**
     * @notice Returns for votes for the given rate.
     * @param proposalId id of the proposal
     * @param rateId id of the rate which corresponds to the following:
     *      2 - Yes Rate
     *      3 - Approval Rate
     *      4 - Product Proposal Continuation Rate
     *      5 - Admin veto rate
     * @param support get votes in support of the proposal or not.
     * @return number of for votes
     */
    function getVotes(
        uint256 proposalId,
        uint8 rateId,
        bool support
    ) public view override onlyValidProposals(proposalId) returns (uint256) {
        if (support) {
            return _getProposalVotes(proposalId, rateId, 0);
        }
        return _getProposalVotes(proposalId, rateId, 1);
    }

    /**
     * @notice Returns the proposal URL of the proposal.
     * @param proposalId id of the proposal
     * @return URL of proposal
     */
    function getURL(uint256 proposalId)
        public
        view
        onlyValidProposals(proposalId)
        returns (string memory)
    {
        require(
            _getProposalType(proposalId) == Proposals.EntityType.PRODUCT,
            "Must be a product proposal"
        );
        return productProposals[proposalId].URL;
    }

    /**
     * @notice Returns the proposal name of the proposal.
     * @param proposalId id of the proposal
     * @return proposal name
     */
    function getName(uint256 proposalId)
        public
        view
        onlyValidProposals(proposalId)
        returns (string memory)
    {
        require(
            _getProposalType(proposalId) == Proposals.EntityType.PRODUCT,
            "Must be a product proposal"
        );
        return productProposals[proposalId].name;
    }

    /**
     * @notice Returns the description of the proposal.
     * @param proposalId id of the proposal
     * @return description
     */
    function getDescription(uint256 proposalId)
        public
        view
        onlyValidProposals(proposalId)
        returns (string memory)
    {
        Proposals.EntityType entityType = _getProposalType(proposalId);
        if (entityType == Proposals.EntityType.PRODUCT) {
            return productProposals[proposalId].description;
        }
        return developmentProposals[proposalId].description;
    }

    /**
     * @notice Returns the telegram handle of the proposal.
     * @param proposalId id of the proposal
     * @return telegram handle
     */
    function getTGHandle(uint256 proposalId)
        public
        view
        onlyValidProposals(proposalId)
        returns (string memory)
    {
        require(
            _getProposalType(proposalId) == Proposals.EntityType.PRODUCT,
            "Must be a product proposal"
        );
        return productProposals[proposalId].TGHandle;
    }

    /**
     * @notice Returns the proposal state.
     * @param proposalId id of the proposal
     * @return proposal state id, see Proposals.sol
     */
    function getState(uint256 proposalId)
        public
        view
        override
        onlyValidProposals(proposalId)
        returns (uint256)
    {
        Proposals.EntityType entityType = _getProposalType(proposalId);
        if (entityType == Proposals.EntityType.PRODUCT) {
            return uint256(productProposals[proposalId].proposalState);
        }
        return uint256(developmentProposals[proposalId].proposalState);
    }

    /**
     * @notice Returns the proposal state.
     * @param proposalId id of the proposal
     * @return DEVELOPMENT or PRODUCT.
     */
    function getType(uint256 proposalId)
        public
        view
        override
        onlyValidProposals(proposalId)
        returns (uint256)
    {
        return uint256(_getProposalType(proposalId));
    }

    /** TODO: Complete this docstring
     */
    function getBudget(uint256 proposalId)
        public
        view
        override
        onlyValidProposals(proposalId)
        returns (uint256)
    {
        Proposals.EntityType entityType = _getProposalType(proposalId);
        if (entityType == Proposals.EntityType.PRODUCT) {
            return productProposals[proposalId].budget;
        }
        return developmentProposals[proposalId].budget;
    }

    /** TODO: Complete this docstring
     */
    function getReceiver(uint256 proposalId)
        public
        view
        override
        onlyValidProposals(proposalId)
        returns (address)
    {
        Proposals.EntityType entityType = _getProposalType(proposalId);
        if (entityType == Proposals.EntityType.PRODUCT) {
            return productProposals[proposalId].receiver;
        }
        return developmentProposals[proposalId].receiver;
    }

    /**
     * @notice sets the proposal state. See enum in Proposals.sol.
     *
     */
    function setState(uint256 proposalId, uint256 proposalState)
        public
        override
        onlyDAOOrVoting
        onlyValidProposals(proposalId)
    {
        Proposals.EntityType entityType = _getProposalType(proposalId);
        if (entityType == Proposals.EntityType.PRODUCT) {
            productProposals[proposalId].proposalState = Proposals
            .ProposalState(proposalState);
        }
        developmentProposals[proposalId].proposalState = Proposals
        .ProposalState(proposalState);
    }

    /**
     * @notice sets the proposal vote
     *
     */
    function setVotes(
        uint256 proposalId,
        uint8 rateId,
        bool support,
        uint256 amount
    ) public override onlyDAOVoting onlyValidProposals(proposalId) {
        _setProposalVotes(proposalId, rateId, support, amount);
    }

    /** 
     * @notice Gets voting start block based on the first voting system they enter.
     * For development, it would be the DDF approval voting system.
     * For product, it would be the yes voting system.
     */
    function getVotingStartBlock(uint256 proposalId)
        public
        view
        override
        onlyValidProposals(proposalId)
        returns (uint256)
    {
        if(
            getType(proposalId) == uint256(Proposals.EntityType.PRODUCT)

        ){
            return productProposals[proposalId].proposalRates.yes.startBlock;
        }
        return developmentProposals[proposalId].approval.startBlock;
    }

    /** TODO: Complete this docstring
     */
    function getDevDays(uint256 proposalId)
        public
        view
        override
        onlyValidProposals(proposalId)
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(
            getType(proposalId) == uint256(Proposals.EntityType.PRODUCT),
            "only product proposals have dev days/intervals"
        );
        return (
            productProposals[proposalId].devDays.devDays,
            productProposals[proposalId].devDays.interval,
            productProposals[proposalId].devDays.currentInterval
        );
    }

    /** TODO: Complete this docstring
     */
    function incrementInterval(uint256 proposalId)
        public
        override
        onlyValidProposals(proposalId)
    {
        productProposals[proposalId].devDays.currentInterval += 1;
    }

    function _proposeDevelopment(
        address receiver,
        address proposer,
        uint256 budget,
        string memory description
    ) internal returns (uint256) {
        // increment id
        uint256 proposalId = proposalIds.current();
        proposalIds.increment();

        // init base proposal
        developmentProposals[proposalId].id = proposalId;
        developmentProposals[proposalId].receiver = receiver;
        developmentProposals[proposalId].proposer = proposer;
        developmentProposals[proposalId].budget = budget;
        developmentProposals[proposalId].description = description;
        developmentProposals[proposalId].proposalState = Proposals
        .ProposalState
        .PROPOSED;

        // init simple rates
        developmentProposals[proposalId].daoTaxRate = rateGovernor.getRate(0);
        developmentProposals[proposalId].devTaxRate = rateGovernor.getRate(1);

        // init voting rates
        developmentProposals[proposalId].approval = Proposals.Rate({
            threshold: rateGovernor.getRate(3),
            forVotes: 0,
            againstVotes: 0,
            startTime: block.timestamp,
            startBlock: block.number
        });

        return proposalId;
    }

    function _proposeProduct(
        string memory name,
        address receiver,
        address proposer,
        uint256 budget,
        string memory description,
        string memory developer,
        uint256 devDays,
        uint256 interval,
        string memory TGHandle,
        string memory URL
    ) internal returns (uint256) {
        // increment proposal
        uint256 proposalId = proposalIds.current();
        proposalIds.increment();

        // create base
        productProposals[proposalId].name = name;
        productProposals[proposalId].URL = URL;
        productProposals[proposalId].TGHandle = TGHandle;
        productProposals[proposalId].developer = developer;
        productProposals[proposalId].id = proposalId;
        productProposals[proposalId].receiver = receiver;
        productProposals[proposalId].proposer = proposer;
        productProposals[proposalId].budget = budget;
        productProposals[proposalId].description = description;
        productProposals[proposalId].proposalState = Proposals
        .ProposalState
        .PROPOSED;

        // initalize rates and dev days
        _initProductProposalRates(proposalId);
        _initDevDays(proposalId, devDays, interval);
        return proposalId;
    }

    function _initProductProposalRates(uint256 proposalId) internal {
        Proposals.ProductProposalRates storage proposalRates = productProposals[
            proposalId
        ]
        .proposalRates;
        proposalRates.daoTaxRate = rateGovernor.getRate(0);
        proposalRates.devTaxRate = rateGovernor.getRate(1);
        proposalRates.yes = Proposals.Rate({
            threshold: rateGovernor.getRate(2),
            forVotes: 0,
            againstVotes: 0,
            startTime: block.timestamp,
            startBlock: block.number
        });
        proposalRates.approval = Proposals.Rate({
            threshold: rateGovernor.getRate(3),
            forVotes: 0,
            againstVotes: 0,
            startTime: block.timestamp,
            startBlock: block.number
        });
        proposalRates.productCont = Proposals.Rate({
            threshold: rateGovernor.getRate(4),
            forVotes: 0,
            againstVotes: 0,
            startTime: block.timestamp,
            startBlock: block.number
        });
        proposalRates.adminVetos = Proposals.Rate({
            //temp change for testing
            threshold: 3,
            forVotes: 0,
            againstVotes: 0,
            startTime: block.timestamp,
            startBlock: block.number
        });
    }

    function _initDevDays(
        uint256 proposalId,
        uint256 devDays,
        uint256 interval
    ) internal {
        productProposals[proposalId].devDays = Proposals.DevDays({
            devDays: devDays,
            interval: interval,
            currentInterval: 0
        });
    }

    function _getProposalType(uint256 proposalId)
        internal
        view
        returns (Proposals.EntityType)
    {
        Proposals.EntityType entityType;
        if (proposalId == productProposals[proposalId].id) {
            entityType = Proposals.EntityType.PRODUCT;
        } else if (proposalId == developmentProposals[proposalId].id) {
            entityType = Proposals.EntityType.DEVELOPMENT;
        }
        require(
            entityType == Proposals.EntityType.PRODUCT ||
                entityType == Proposals.EntityType.DEVELOPMENT,
            "Not a valid proposal type"
        );
        return entityType;
    }

    function _validateProposal(uint256 proposalId) internal view {
        require(proposalId < proposalIds.current(), "Not a valid proposal Id");
        Proposals.EntityType proposalType = _getProposalType(proposalId);
        if (proposalType == Proposals.EntityType.PRODUCT) {
            require(
                productProposals[proposalId].proposalState !=
                    Proposals.ProposalState.REMOVED, "Proposal has been removed"
            );
        } else {
            require(
                developmentProposals[proposalId].proposalState !=
                    Proposals.ProposalState.REMOVED
            );
        }
    }

    function _getProposalVotes(
        uint256 proposalId,
        uint8 rateId,
        uint8 returnType
    ) internal view returns (uint256) {
        require(
            rateId <= 5 && rateId >= 2,
            "Invalid rateId (must be between 2-5)"
        );
        require(
            0 <= returnType && returnType <= 2,
            "Invalid returnType (must be between 0-2)"
        );
        Proposals.Rate storage rate;
        Proposals.EntityType proposalType = _getProposalType(proposalId);

        // determine type of proposal
        if (proposalType == Proposals.EntityType.PRODUCT) {
            Proposals.ProductProposalRates storage rates = productProposals[
                proposalId
            ]
            .proposalRates;
            // determine type of rate
            if (rateId == 2) {
                rate = rates.yes;
            } else if (rateId == 3) {
                rate = rates.approval;
            } else if (rateId == 4) {
                rate = rates.productCont;
            } else {
                rate = rates.adminVetos;
            }
        } else {
            require(
                rateId == 3,
                "Invalid rateId. Only Development proposals have approval rate (rateId=3)."
            );
            rate = developmentProposals[proposalId].approval;
        }

        // return either for/against/threshold
        if (returnType == 0) {
            return rate.forVotes;
        } else if (returnType == 1) {
            return rate.againstVotes;
        }
        return rate.threshold;
    }

    function _setProposalVotes(
        uint256 proposalId,
        uint8 rateId,
        bool support,
        uint256 amount
    ) internal {
        _validateProposal(proposalId);
        require(
            rateId <= 5 && rateId >= 2,
            "Invalid rateId (must be between 2-5)"
        );
        Proposals.Rate storage rate;
        Proposals.EntityType proposalType = _getProposalType(proposalId);

        // determine type of proposal
        if (proposalType == Proposals.EntityType.PRODUCT) {
            Proposals.ProductProposalRates storage rates = productProposals[
                proposalId
            ]
            .proposalRates;
            // determine type of rate
            if (rateId == 2) {
                rate = rates.yes;
            } else if (rateId == 3) {
                rate = rates.approval;
            } else if (rateId == 4) {
                rate = rates.productCont;
            } else {
                rate = rates.adminVetos;
            }
        } else {
            require(
                rateId == 3,
                "Invalid rateId. Only Development proposals have approval rate (rateId=3)."
            );
            rate = developmentProposals[proposalId].approval;
        }

        // return either for/against/threshold
        if (support) {
            rate.forVotes = amount;
        } else {
            rate.againstVotes = amount;
        }
    }

    function getTaxRates(uint256 proposalId) public view override returns(uint256, uint256) {
        uint daoTaxRate;
        uint devTaxRate;
        if(getType(proposalId) == uint256(Proposals.EntityType.PRODUCT))
        {
            daoTaxRate = productProposals[proposalId].proposalRates.daoTaxRate;
            devTaxRate = productProposals[proposalId].proposalRates.devTaxRate;
        }
        else{
            daoTaxRate = developmentProposals[proposalId].daoTaxRate;
            devTaxRate = developmentProposals[proposalId].devTaxRate;
        }
        return(daoTaxRate, devTaxRate);
    }

    function resetHasActiveProposal(uint256 proposalId) public override onlyDAOVoting {
        if(getType(proposalId) == uint256(Proposals.EntityType.PRODUCT))
        {
            hasActiveProposal[productProposals[proposalId].proposer] = false;
        }
        else{
            hasActiveProposal[developmentProposals[proposalId].proposer] = false;
        }
    }

    function getLatestId() public view override returns(uint256){
        require(proposalIds.current() > 0, "nothing has been proposed yet");
        return(proposalIds.current() - 1);
    }
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED

interface IRateGovernor {
    function getRate(uint8 rateId) external view returns (uint256);
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSED

interface IDAOAccess {

    function isGuardian(address sender) external view returns (bool);

    function isDDF(address sender, uint256 blockNumber) external view returns (bool);

    function isAdmin(address sender) external view returns (bool);

}

pragma solidity ^0.8.0;

//SPDX-License-Identifier: Unlicensed

library Proposals {
    /// @notice For determining type of entity
    enum EntityType {
        DEVELOPMENT,
        PRODUCT,
        RATE,
        NULL
    }

    /** @notice For proposal states
     * PROPOSED: For proposals not approved by an admin (product only)
     *     OPEN: For product proposals that have been approved by an admin
     *           For development proposals that have been opened up
     * ACCEPTED: For proposals that meet the yes rate (product only)
     * APPROVED: For proposals that have been approved for the current interval (product only)
     * EXECUTED: For proposals that recieved their budget in whole
     *  REMOVED: For proposals that have expired or have been vetoed out
     */
    enum ProposalState {
        PROPOSED,
        OPEN,      
        ACCEPTED,  
        APPROVED,  
        EXECUTED,  
        REMOVED    
    }

    /// @notice Rate types
    enum RateType {
        DAO_TAX_RATE,
        DEVELOPMENT_TAX_RATE,
        YES_RATE,
        APPROVAL_RATE,
        CONTINUATION_RATE
    }

    /// @notice For rates
    struct Rate {
        // rate for action to take place (needs RateGovernor) * 100
        uint256 threshold;
        // current votes for
        uint256 forVotes;
        // current votes against
        uint256 againstVotes;
        // start time
        uint256 startTime;
        // starting block
        uint256 startBlock;
    }

    /// @notice for storing proposal rates
    struct ProductProposalRates {
        // DAO Tax Rate
        uint256 daoTaxRate;
        // Development Tax Rate
        uint256 devTaxRate;
        // yes rate at the time it was proposed
        Rate yes;
        // Number of vetoes for the proposal (Product only)
        Rate adminVetos;
        // Approval rate at the time it was proposed (Product only)
        Rate approval;
        // Product proposal continuation rate at the time it was proposed (Product only)
        Rate productCont;
    }

    /// @notice for storing dev days information
    struct DevDays {
        // Interval for recieving budget (product only)
        uint256 interval;
        // The current interval (product only)
        uint256 currentInterval;
        // Number of dev days (product only)
        uint256 devDays;
    }

    struct DevelopmentProposal {
        // Unique id for looking up a development proposal
        uint256 id;
        // Budget
        uint256 budget;
        // address for where the budget should go
        address receiver;
        // address for who proposed
        address proposer;
        // Description
        string description;
        // DAO Tax Rate
        uint256 daoTaxRate;
        // Development Tax Rate
        uint256 devTaxRate;
        // DDF Approval rate
        Rate approval;
        // proposal state
        ProposalState proposalState;
    }

    struct ProductProposal {
        // name of the proposal (product only)
        string name;
        // Unique id for looking up a product proposal
        uint256 id;
        // Budget
        uint256 budget;
        // Telegram Handle
        string TGHandle;
        // url to project/product
        string URL;
        // address for where the budget should go
        address receiver;
        // address for who proposed
        address proposer;
        // Developer
        string developer;
        // Description
        string description;
        // Stores devDays information (product only)
        DevDays devDays;
        // Rates
        ProductProposalRates proposalRates;
        // proposal state
        ProposalState proposalState;
    }

    /// @notice Ballot receipt record for a rate
    struct RateReceipt {
        // Whether or not a vote has been cast
        bool hasVoted;
        // The number of votes the voter had, which were cast
        uint96 votes;
        // Which proposal/rate they voted for
        uint256 entityId;
        // At which block number (corresponds to voting period)
        uint256 blockPeriod;
    }

    /// @notice Ballot receipt record for a proposal
    struct ProposalReceipt {
        // Whether or not a vote has been cast
        bool hasVoted;
        // The number of votes the voter had, which were cast
        uint96 votes;
        // Which proposal/rate they voted for
        uint256 entityId;
        // At which block period
        uint256 blockPeriod;
        // At which state was the vote cast?
        ProposalState proposalState;
    }

}

pragma solidity ^0.8.0;

//SPDX-License-Identifier: UNLICENSED

interface IProposalManager {
    function proposeDevelopment(
        address receiver,
        address proposer,
        uint256 budget,
        string memory description
    ) external;

    function proposeProduct(
        string memory name,
        address receiver,
        address proposer,
        uint256 budget,
        string memory description,
        string memory developer,
        uint256 devDays,
        uint256 interval,
        string memory TGHandle,
        string memory URL
    ) external;

    function getType(uint256 proposalId) external view returns (uint256);

    function getState(uint256 proposalId) external view returns (uint256);

    function getVoteThreshold(uint256 proposalId, uint8 rateId)
        external
        view
        returns (uint256);

    function getVotes(
        uint256 proposalId,
        uint8 rateId,
        bool support
    ) external view returns (uint256);

    function getBudget(uint256 proposalId) external view returns (uint256);

    function getReceiver(uint256 proposalId) external view returns (address);

    function setState(uint256 proposalId, uint256 proposalState) external;

    function getVotingStartBlock(uint256 proposalId) external view returns (uint256);

    function getDevDays(uint256 proposalId) external view returns (uint256, uint256, uint256);

    function incrementInterval(uint256 proposalId) external;

    function setVotes(
        uint256 proposalId,
        uint8 rateId,
        bool support,
        uint256 amount
    ) external;

    function getTaxRates(uint256 proposalId) external view returns (uint256, uint256);

    function resetHasActiveProposal(uint256 proposalId) external;

    function getLatestId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

{
  "optimizer": {
    "enabled": false,
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