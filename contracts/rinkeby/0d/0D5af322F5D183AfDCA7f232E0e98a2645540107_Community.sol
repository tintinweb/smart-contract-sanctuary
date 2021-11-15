// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./interfaces/ICommunity.sol";

/* solhint-disable not-rely-on-time */

/**
 * Module for coordinating investment groups on HomeFi protocol
 */
contract Community is ICommunity {
    using SafeERC20Upgradeable for IToken20;

    /// CONSTRUCTOR ///

    function initialize(address _homeFi, address _eventsContract)
        external
        override
        initializer
        nonZero(_homeFi)
        nonZero(_eventsContract)
    {
        homeFiInstance = IHomeFi(_homeFi);
        eventsInstance = IEvents(_eventsContract);
        etherCurrency = homeFiInstance.etherCurrency();
        daiCurrency = homeFiInstance.daiCurrency();
        usdcCurrency = homeFiInstance.usdcCurrency();
    }

    /// MUTABLE FUNCTIONS ///

    function createCommunity(bytes calldata _hash, address _currency)
        external
        override
    {
        homeFiInstance.validCurrency(_currency);
        communities[communityCount].hash = _hash;
        communities[communityCount].owner = msgSender();
        communities[communityCount].currency = _currency;
        communities[communityCount].memberCount = 1;
        communities[communityCount].members[0] = msgSender();
        communities[communityCount].isMember[msgSender()] = true;
        communityCount++;
        eventsInstance.communityAdded(
            communityCount - 1,
            msgSender(),
            _currency,
            _hash
        );
    }

    function updateCommunityHash(uint256 _communityID, bytes calldata _hash)
        external
        override
    {
        require(
            communities[_communityID].owner == msgSender(),
            "Community::!Owner"
        );
        bytes memory _oldHash = communities[_communityID].hash;
        communities[_communityID].hash = _hash;
        eventsInstance.updateCommunityHash(_communityID, _oldHash, _hash);
    }

    function addMember(bytes calldata _data, bytes calldata _signature)
        external
        override
    {
        bytes32 _hash = keccak256(_data);
        address _a1 = SignatureDecoder.recoverKey(_hash, _signature, 0);
        address _a2 = SignatureDecoder.recoverKey(_hash, _signature, 1);
        address _ownerRecovered;
        address _memberToAdd = address(0);
        (uint256 _communityID, address _newMemberAddr) = abi.decode(
            _data,
            (uint256, address)
        );
        if (_a1 == communities[_communityID].owner) {
            _ownerRecovered = _a1;
            _memberToAdd = _a2;
        } else if (_a2 == communities[_communityID].owner) {
            _ownerRecovered = _a2;
            _memberToAdd = _a1;
        } else {
            revert("Community::!Admin");
        }
        require(
            !communities[_communityID].isMember[_memberToAdd],
            "Community::Member Exists"
        );
        require(_memberToAdd == _newMemberAddr, "Community::!Signature");
        uint256 _communityCount = communities[_communityID].memberCount;
        communities[_communityID].memberCount = _communityCount + 1;
        communities[_communityID].members[_communityCount] = _memberToAdd;
        communities[_communityID].isMember[_memberToAdd] = true;
        eventsInstance.memberAdded(_communityID, _memberToAdd);
    }

    function publishProject(
        uint256 _communityID,
        address _project,
        uint256[] calldata _projectDetails
    ) external override checkMember(_communityID, msgSender()) {
        require(
            homeFiInstance.projectExist((_project)),
            "Community::Project !Exists"
        );
        require(
            !communities[_communityID].projectDetails[_project].exists,
            "Community::Published"
        );
        IProject _projectInstance = IProject(_project);
        require(
            _projectInstance.currency() == communities[_communityID].currency,
            "Community::!Currency"
        );
        require(
            msgSender() == _projectInstance.builder(),
            "Community::!Builder"
        );
        require(_projectDetails.length == 4, "Community::Details !OK");
        uint256 _projectCount = communities[_communityID].projectCount;
        communities[_communityID].projectCount = _projectCount + 1;
        communities[_communityID].projects[_projectCount] = _project;
        communities[_communityID].projectDetails[_project].exists = true;
        communities[_communityID]
            .projectDetails[_project]
            .apr = _projectDetails[0];
        communities[_communityID]
            .projectDetails[_project]
            .repaymentStartDate = _projectDetails[1];
        communities[_communityID]
            .projectDetails[_project]
            .repaymentEndDate = _projectDetails[2];
        communities[_communityID]
            .projectDetails[_project]
            .investmentNeeded = _projectDetails[3];
        eventsInstance.projectPublished(
            _communityID,
            _project,
            _projectDetails[0]
        );
    }

    function investInProject(
        uint256 _communityID,
        address _project,
        uint256 _investment
    )
        external
        payable
        override
        nonReentrant
        checkMember(_communityID, msgSender())
    {
        require(
            communities[_communityID].projectDetails[_project].exists,
            "Community::Project !Exists"
        );
        require(
            communities[_communityID]
                .projectDetails[_project]
                .repaymentStartDate > block.timestamp,
            "Community::Investment Closed"
        );
        IProject _projectInstance = IProject(_project);
        require(
            msgSender() != _projectInstance.builder(),
            "Community::Builder"
        );
        uint256 _investmentNeeded = communities[_communityID]
            .projectDetails[_project]
            .investmentNeeded;

        uint256 _investorFee = (_investment * _projectInstance.investorFee()) /
            1000;
        uint256 _amountInvested = _investment - _investorFee;
        require(
            _amountInvested <= _investmentNeeded,
            "Community::Investment>needed"
        );
        address _currency = communities[_communityID].currency;
        address payable _treasury = homeFiInstance.treasury();

        if (_currency == etherCurrency) {
            require(msg.value == _investment, "Community::!msg.value");
            _treasury.transfer(_investorFee);
            _projectInstance.investInProject{value: _amountInvested}(
                _amountInvested
            );
        } else {
            IToken20 _token = IToken20(_currency);
            _token.safeTransferFrom(msgSender(), _treasury, _investorFee);
            _token.safeTransferFrom(msgSender(), _project, _amountInvested);
            _projectInstance.investInProject(_amountInvested);
        }

        IToken20 _wrappedToken = IToken20(
            homeFiInstance.wrappedToken(_currency)
        );
        _wrappedToken.mint(msgSender(), _amountInvested);
        communities[_communityID].projectDetails[_project].investmentNeeded =
            _investmentNeeded -
            _amountInvested;

        if (
            communities[_communityID]
                .projectDetails[_project]
                .investmentDetails[msgSender()]
                .investedAmount > 0
        ) {
            claimInterest(_communityID, _project, msgSender(), _wrappedToken);
        }

        communities[_communityID]
            .projectDetails[_project]
            .investmentDetails[msgSender()]
            .investedAmount += _amountInvested;

        communities[_communityID]
            .projectDetails[_project]
            .investmentDetails[msgSender()]
            .investmentTimestamp = block.timestamp;

        eventsInstance.investorInvested(
            _communityID,
            _project,
            msgSender(),
            _amountInvested,
            block.timestamp
        );
    }

    function repayInvestor(
        uint256 _communityID,
        address _project,
        address _investor,
        uint256 _repayAmount
    ) external payable override nonReentrant nonZero(_investor) {
        require(
            communities[_communityID].projectDetails[_project].exists,
            "Community::Project !Exists"
        );
        IProject _projectInstance = IProject(_project);
        require(
            msgSender() == _projectInstance.builder(),
            "Community::!Builder"
        );
        require(
            communities[_communityID]
                .projectDetails[_project]
                .repaymentStartDate <= block.timestamp,
            "Community::Repayment !started"
        );

        address _currency = communities[_communityID].currency;
        IToken20 _wrappedToken = IToken20(
            homeFiInstance.wrappedToken(_currency)
        );

        claimInterest(_communityID, _project, _investor, _wrappedToken);

        uint256 _amountToReturn = communities[_communityID]
            .projectDetails[_project]
            .investmentDetails[_investor]
            .investedAmount;

        require(_repayAmount <= _amountToReturn, "Community::!Liquid");
        communities[_communityID]
            .projectDetails[_project]
            .investmentDetails[_investor]
            .investedAmount = _amountToReturn - _repayAmount;
        _wrappedToken.burn(_investor, _repayAmount);
        if (_currency == etherCurrency) {
            require(msg.value == _repayAmount, "Community::!msg.value");
            payable(_investor).transfer(msg.value);
        } else {
            IToken20 _token = IToken20(_currency);
            _token.safeTransferFrom(msgSender(), _investor, _repayAmount);
        }

        eventsInstance.repayInvestor(
            _communityID,
            _project,
            _investor,
            _repayAmount,
            block.timestamp
        );
    }

    function transferFraction(
        uint256 _communityID,
        address _project,
        address _to,
        uint256 _amount
    )
        external
        override
        nonReentrant
        nonZero(_to)
        checkMember(_communityID, _to)
        returns (bool)
    {
        require(
            communities[_communityID].projectDetails[_project].exists,
            "Community::Project !Exists"
        );
        address _currency = communities[_communityID].currency;
        IToken20 _wrappedToken = IToken20(
            homeFiInstance.wrappedToken(_currency)
        );
        claimInterest(_communityID, _project, msgSender(), _wrappedToken);
        uint256 _userInvestedAmount = communities[_communityID]
            .projectDetails[_project]
            .investmentDetails[msgSender()]
            .investedAmount;
        uint256 _toInvestedAmount = communities[_communityID]
            .projectDetails[_project]
            .investmentDetails[_to]
            .investedAmount;
        require(
            _amount > 0 && _amount <= _userInvestedAmount,
            "Community::!Balance"
        );

        if (_toInvestedAmount > 0) {
            claimInterest(_communityID, _project, _to, _wrappedToken);
        }

        communities[_communityID]
            .projectDetails[_project]
            .investmentDetails[msgSender()]
            .investedAmount = _userInvestedAmount - _amount;
        communities[_communityID]
            .projectDetails[_project]
            .investmentDetails[_to]
            .investedAmount += _amount;

        _wrappedToken.safeTransferFrom(msgSender(), _to, _amount);

        eventsInstance.debtTransferred(
            _communityID,
            _project,
            msgSender(),
            _to,
            _amount
        );
        return true;
    }

    /// VIEWABLE FUNCTIONS ///

    function returnToInvestor(
        uint256 _communityID,
        address _project,
        address _investor
    ) public view override returns (uint256 _return, uint256 _invested) {
        InvestmentDetails storage _investment = communities[_communityID]
            .projectDetails[_project]
            .investmentDetails[_investor];
        uint256 _endDate = communities[_communityID]
            .projectDetails[_project]
            .repaymentEndDate;
        uint256 _apr = communities[_communityID].projectDetails[_project].apr;
        uint256 _dateOfInvestment = _investment.investmentTimestamp;
        uint256 _investedAmount = _investment.investedAmount;

        uint256 _noOfDays = (block.timestamp - _dateOfInvestment) / 86400; // 24*60*60
        uint256 _noOfPenaltyDays = 0;
        uint256 _daysSinceEnd = 0;
        if (block.timestamp > _endDate) {
            _daysSinceEnd = (block.timestamp - _endDate) / 86400;
        }
        if (_dateOfInvestment < _endDate) {
            _noOfDays = _noOfDays - _daysSinceEnd;
            _noOfPenaltyDays = _daysSinceEnd;
        } else {
            _noOfPenaltyDays = _noOfDays;
            _noOfDays = 0;
        }

        uint256 _amountToReturn = _investedAmount +
            ((_investedAmount * _apr * _noOfDays) / 365000) +
            ((_investedAmount * 2 * _apr * _noOfPenaltyDays) / 365000); // double interest rate after endDate
        return (_amountToReturn, _investedAmount);
    }

    function communityDetails(uint256 _communityID)
        external
        view
        override
        returns (
            address[] memory,
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        address[] memory _membersArray = new address[](
            communities[_communityID].memberCount
        );
        address[] memory _projectArray = new address[](
            communities[_communityID].projectCount
        );
        uint256[] memory _projectApr = new uint256[](
            communities[_communityID].projectCount
        );
        uint256[] memory _projectRepaymentStartDate = new uint256[](
            communities[_communityID].projectCount
        );
        uint256[] memory _projectRepaymentEndDate = new uint256[](
            communities[_communityID].projectCount
        );
        uint256[] memory _investmentNeeded = new uint256[](
            communities[_communityID].projectCount
        );

        for (uint256 i = 0; i < communities[_communityID].memberCount; i++) {
            _membersArray[i] = communities[_communityID].members[i];
        }
        for (uint256 i = 0; i < communities[_communityID].projectCount; i++) {
            _projectArray[i] = communities[_communityID].projects[i];
            _projectApr[i] = communities[_communityID]
                .projectDetails[_projectArray[i]]
                .apr;
            _projectRepaymentStartDate[i] = communities[_communityID]
                .projectDetails[_projectArray[i]]
                .repaymentStartDate;
            _projectRepaymentEndDate[i] = communities[_communityID]
                .projectDetails[_projectArray[i]]
                .repaymentEndDate;
            _investmentNeeded[i] = communities[_communityID]
                .projectDetails[_projectArray[i]]
                .investmentNeeded;
        }
        return (
            _membersArray,
            _projectArray,
            _projectApr,
            _projectRepaymentStartDate,
            _projectRepaymentEndDate,
            _investmentNeeded
        );
    }

    /// INTERNAL FUNCTIONS ///

    function claimInterest(
        uint256 _communityID,
        address _project,
        address _user,
        IToken20 _wrappedToken
    ) internal override {
        (uint256 _amountToReturn, uint256 _invested) = returnToInvestor(
            _communityID,
            _project,
            _user
        );
        require(_invested > 0, "Community::Claimed");
        if (_amountToReturn > _invested) {
            communities[_communityID]
                .projectDetails[_project]
                .investmentDetails[_user]
                .investedAmount = _amountToReturn;
            communities[_communityID]
                .projectDetails[_project]
                .investmentDetails[_user]
                .investmentTimestamp = block.timestamp;
            uint256 _interestEarned = _amountToReturn - _invested;
            _wrappedToken.mint(_user, _interestEarned);
            eventsInstance.claimedInterest(
                _communityID,
                _project,
                _user,
                _interestEarned,
                _amountToReturn
            );
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IHomeFi.sol";
import "./IToken20.sol";
import "./IProject.sol";
import "../external/BasicMetaTransaction.sol";

// import "../external/proxy/OwnedUpgradeabilityProxy.sol";

/**
 * Interface defining module for coordinating investment groups on HomeFi protocol
 */
abstract contract ICommunity is
    Initializable,
    BasicMetaTransaction,
    ReentrancyGuardUpgradeable
{
    /// MODIFIERS ///

    modifier checkMember(uint256 _communityID, address _user) {
        // determine whether an address is enrolled as a member in a community
        require(
            communities[_communityID].isMember[_user],
            "Community::!Member"
        );
        _;
    }

    modifier nonZero(address _address) {
        // ensure an address is not the zero address (0x00)
        require(_address != address(0), "Community::0 address");
        _;
    }

    /// STRUCTS ///

    struct InvestmentDetails {
        // object storing data for individual investment event
        address investor;
        uint256 investedAmount;
        uint256 investmentTimestamp;
        bool status; //if true, block has been repaid by builder already
    }

    struct ProjectDetails {
        // object storing data about project for investors in community
        bool exists;
        uint256 apr; //interest rate for the project (in per thousand)
        uint256 repaymentStartDate; //unix timestamp when repayment starts
        uint256 repaymentEndDate; //unix timestamp when repayment is late
        uint256 investmentNeeded; //total investment requirement in community currency to launch
        uint256 investmentCount; // from index 1
        mapping(address => InvestmentDetails) investmentDetails;
    }

    struct CommunityStruct {
        // object storing all data relevant to an investment community
        bytes hash; //dont get this yet
        address owner;
        address currency;
        uint256 memberCount; // from index 0
        uint256 projectCount; // from index 0
        mapping(uint256 => address) members;
        mapping(address => bool) isMember;
        mapping(uint256 => address) projects;
        mapping(address => ProjectDetails) projectDetails;
    }

    address internal etherCurrency; //vanity address, Ether is not a contract
    address internal daiCurrency;
    address internal usdcCurrency;
    IEvents internal eventsInstance;
    IHomeFi public homeFiInstance;

    uint256 public communityCount; //starts from 1
    mapping(uint256 => CommunityStruct) public communities;

    /// CONSTRUCTOR ///

    /**
     * Initialize a new communities contract
     * @notice THIS IS THE CONSTRUCTOR thanks upgradable proxies
     * @dev modifier initializer
     *
     * @param _homeFi address - instance of main HomeFi contract. Can be accessed with raw address
     * @param _eventsContract address - instance of events contract. Can be accessed with raw address
     */
    function initialize(address _homeFi, address _eventsContract)
        external
        virtual;

    /// MUTABLE FUNCTIONS ///

    /**
     * Create a new investment community on HomeFi
     *
     * @param _hash bytes - the identifying hash of the community
     * @param _currency address - the currency accepted for creating new HomeFi debt tokens
     */
    function createCommunity(bytes calldata _hash, address _currency)
        external
        virtual;

    /**
     * Update the internal identifying hash of a community
     * @notice IDK why exactly this exists yet
     *
     * @param _communityID uint256 - the the uuid of the community
     * @param _hash bytes - the new hash to update the community hash to
     */
    function updateCommunityHash(uint256 _communityID, bytes calldata _hash)
        external
        virtual;

    /**
     * Add a new member to an investment community
     * @notice Comprises of both request to join and join.
     *
     * @param _data bytes - data encoded:
     * - _communityID community count
     * - _memberAddr member address to add
     * @param _signature bytes - _data signed by the community owner
     */
    function addMember(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * Add a new project to an investment community
     * @dev modifier onlyBuilder
     * @dev modifier checkMember
     *
     * @param _communityID uint256 - the the uuid (serial) of the community being published to
     * @param _project address - the project contract being added to the community for investment
     * @param _projectDetails uint256[] - integer metadata for project
     *  - [0] = APR; [1]: Min repayment timestamp; [2]: Max repayment timestamp; [3]: investment needed
     *  - NOTE: APR is in per thousand. Ex: 5% interest => APR = 50
     */
    function publishProject(
        uint256 _communityID,
        address _project,
        uint256[] calldata _projectDetails
    ) external virtual;

    /**
     * As a community member, invest in a project and create new HomeFi debt tokens
     * @notice this is where funds flow into contracts for investors
     * @dev modifier checkMember
     * @dev modifier nonReentrant
     * @dev users MUST call approve on USDC or Dai token contracts for the community contract first
     *
     * @param _communityID uint256 - the the uuid (serial) of the community
     * @param _project address - the address of the deployed project contract
     * @param _cost uint256 - the number of tokens of the community currency to invest
     */
    function investInProject(
        uint256 _communityID,
        address _project,
        uint256 _cost
    ) external payable virtual;

    /**
     * As a builder, repay an investor for their investment with interest
     * @notice this is where funds flow out of contracts for investors
     * @dev modifier onlyBuilder
     * @dev modifier nonReentrant
     * @dev modifier nonZero(_investor)
     *
     * @param _communityID uint256 - the the uuid of the community
     * @param _project address - the address of the deployed project contract
     * @param _investor address - the address of the investor to repay + interest
     * @param _repayAmount uint256 - the amount of funds repaid to the investor, in the project currency
     */
    function repayInvestor(
        uint256 _communityID,
        address _project,
        address _investor,
        uint256 _repayAmount
    ) external payable virtual;

    /**
     * Transfer ownership of investments from one user to another
     * @dev modifier nonReentrant
     * @dev modifier nonZero(_to)
     * @notice in practice transfer debt erc20 tokens + update references in custom nft logic
     *
     * @param _communityID uint256 - the the uuid (serial) of the community
     * @param _project address - the address of the deployed project contract
     * @param _to address - the address recieving ownership of the specified investments
     * @param _amount amount of debt token he want to transfer
     * @return bool - will always return true if does not revert during execution
     */
    function transferFraction(
        uint256 _communityID,
        address _project,
        address _to,
        uint256 _amount
    ) external virtual returns (bool);

    /// VIEWABLE FUNCTIONS ///

    /**
     * Calculate the payout for a given investor on their investments as queried
     * @dev modifier onlyBuilder
     * @dev modifier nonZero(_investor)
     *
     * @param _communityID uint256 - the the uuid (serial) of the community where the investment took place
     * @param _project address - the address of the deployed project contract
     * @param _investor address - the address of the investor to repay + interest
     * @return _return uint256 - the amount invested by _address + interest paid (the amount of tokens reclaimed)
     * @return _invested uint256 - the amount _address invested initially
     */
    function returnToInvestor(
        uint256 _communityID,
        address _project,
        address _investor
    ) public view virtual returns (uint256 _return, uint256 _invested);

    /**
     * Return all info about a specific community
     *
     * @param _communityID uint256 - the uuid (serial) of the community to query
     * @return _members address[] - array of all member accounts
     * @return _projects address[] - array of all projects the community can invest in
     * @return _apr uint256[] - array of interest rates with index relating to _projects
     * @return _min uint256[] - array of starting date of debt repayments with index relating to _projects
     * @return _max uint256[] - array of final date of debt repayment with index relating to _projects (double APR after)
     * @return _investment uint256[] - array of amounts needed by projects before investment completes with index relating to _projects
     */
    function communityDetails(uint256 _communityID)
        external
        view
        virtual
        returns (
            address[] memory _members,
            address[] memory _projects,
            uint256[] memory _apr,
            uint256[] memory _min,
            uint256[] memory _max,
            uint256[] memory _investment
        );

    /// INTERNAL FUNCTIONS ///

    /**
     * @dev interest of investor
     * @param _communityID uint256 - uuid of community the project is held in
     * @param _project address - address of project where debt/ loan is held
     * @param _user address - address of investor claiming interest
     * @param _wrappedToken address - debt token investor is claiming
     */
    function claimInterest(
        uint256 _communityID,
        address _project,
        address _user,
        IToken20 _wrappedToken
    ) internal virtual;
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "./IEvents.sol";
import "../external/BasicMetaTransaction.sol";

interface IProjectFactory {
    function createProject(
        bytes memory _hash,
        address _currency,
        address _sender
    ) external returns (address _clone);
}

/**
 * @title HomeFi v0.1.0 ERC721 Contract Interface
 * @notice Interface for main on-chain client for HomeFi protocol
 * Interface for administrative controls and project deployment
 */
abstract contract IHomeFi is BasicMetaTransaction, ReentrancyGuardUpgradeable {
    modifier onlyAdmin() {
        require(admin == msgSender(), "HomeFi::!Admin");
        _;
    }

    modifier nonZero(address _address) {
        require(_address != address(0), "HomeFi::0 address");
        _;
    }

    /// VARIABLES ///
    address public etherCurrency;
    address public daiCurrency;
    address public usdcCurrency;

    IEvents public eventsInstance;
    IProjectFactory public projectFactoryInstance;
    address public disputeContract;
    address public communityContract;

    address public admin;
    address payable public treasury;
    uint256 public builderFee;
    uint256 public investorFee;
    mapping(uint256 => address) public projects;
    mapping(address => bool) public projectExist;

    mapping(address => uint256) public projectTokenId;

    mapping(address => address) public wrappedToken;

    uint256 public projectCount;
    bool public addrSet;
    uint256 public tokenCount;

    /**
     * Pass addresses of other deployed modules into the HomeFi contract
     * @dev can only be called once
     * @param _eventsContract address - contract address of Events.sol
     * @param _projectFactory contract address of ProjectFactory.sol
     * @param _communityContract contract address of Community.sol
     * @param _disputeContract contract address of Dispute.sol
     * @param _hETHAddress Ether debt token address
     * @param _hDAIAddress Dai debt token address
     * @param _hUSDCAddress USDC debt token address
     */
    function setAddr(
        address _eventsContract,
        address _projectFactory,
        address _communityContract,
        address _disputeContract,
        address _hETHAddress,
        address _hDAIAddress,
        address _hUSDCAddress
    ) external virtual;

    /**
     * @dev to validate the currency is supported by HomeFi or not
     * @param _currency currency address
     */
    function validCurrency(address _currency) public view virtual;

    /// ADMIN MANAGEMENT ///
    /**
     * @notice only called by admin
     * @dev replace admin
     * @param _newAdmin new admin address
     */
    function replaceAdmin(address _newAdmin) external virtual;

    /**
     * @notice only called by admin
     * @dev address which will receive HomeFi builder and investor fee
     * @param _treasury new treasury address
     */
    function replaceTreasury(address _treasury) external virtual;

    /**
     * @notice this is only called by admin
     * @dev to reset the builder and investor fee for HomeFi deployment
     * @param _builderFee percentage of fee builder have to pay to HomeFi treasury
     * @param _investorFee percentage of fee investor have to pay to HomeFi treasury
     */
    function replaceNetworkFee(uint256 _builderFee, uint256 _investorFee)
        external
        virtual;

    /// PROJECT ///
    /**
     * @dev to create a project
     * @param _hash IPFS hash of project details
     * @param _currency address of currency which this project going to use
     */
    function createProject(bytes memory _hash, address _currency)
        external
        virtual;

    /**
     * @dev make every project NFT
     * @param _to to which user this NFT belong to first time it will builder
     * @param _tokenURI ipfs hash of project which contain project details like name, description etc.
     * @return _tokenIds NFT Id of project
     */
    function mintNFT(address _to, string memory _tokenURI)
        internal
        virtual
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface of the ERC20 standard with mint & burn methods
 */
interface IToken20 is IERC20Upgradeable {
    /**
     * Create new tokens and sent to an address
     *
     * @param _to address - the address receiving the minted tokens
     * @param _total uint256 - the amount of tokens to mint to _to
     */
    function mint(address _to, uint256 _total) external;

    /**
     * Destroy tokens at an address
     *
     * @param _to address - the address where tokens are burned from
     * @param _total uint256 - the amount of tokens to burn from _to
     */
    function burn(address _to, uint256 _total) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IToken20.sol";
import "./IDisputes.sol";
import "../external/BasicMetaTransaction.sol";
import "../libraries/SignatureDecoder.sol";
import {Tasks, Task, TaskStatus} from "../libraries/Tasks.sol";

/**
 * HomeFI v0.1.0 Deployable Project Escrow Contract Interface
 *
 * Interface for child contract from HomeFi service contract; escrows all funds
 * Use task library to store hashes of data within project
 */
abstract contract IProject is
    Initializable,
    BasicMetaTransaction,
    ReentrancyGuardUpgradeable
{
    // struct to store phase related details
    struct Phase {
        uint256 phaseCost;
        uint256[] phaseToTaskList;
        bool paid;
    }

    // Fixed //

    // HomeFi NFT contract instance
    IHomeFi public homeFi;

    // Event contract instance
    IEvents internal eventsInstance;

    // Dispute contract instance
    address internal disputes;

    // Address of project currency
    address public currency;

    // builder fee inherited from HomeFi
    uint256 public builderFee;

    // investor fee inherited from HomeFi
    uint256 public investorFee;

    // address of builder
    address public builder;

    // Variable //

    // bytes encoded ipfs hash of project
    bytes public projectHash;

    // address of invited contractor
    address public contractor;

    // bool that indicated if contractor has accepted invite
    bool public contractorConfirmed;

    // nonce that is used for signature security related to hash change
    uint256 public hashChangeNonce;

    // total amount invested in project
    uint256 public totalInvested;

    // total amount allocated in project
    uint256 public totalAllocated;

    // phase count of project. starts from 1.
    uint256 public phaseCount;

    // task count/serial. Starts from 1.
    uint256 public taskCount;

    // the index in nonFundedPhase from which phases are not funded
    uint256 internal nonFundedCounter;

    // array of phase index that are non funded.
    uint256[] internal nonFundedPhase;

    // sorted array of phase with non funded tasks
    uint256[] internal nonFundedTaskPhases;

    // mapping for each index of nonFundedTaskPhases to array of non funded task indexes.
    mapping(uint256 => uint256[]) internal nonFundedPhaseToTask;

    // mapping of phase index to Phase struct
    mapping(uint256 => Phase) public phases;

    // mapping of tasks index to Task struct.
    mapping(uint256 => Task) public tasks;

    /// MODIFIERS ///

    /**
     * @dev only allow if sender is project builder
     */
    modifier onlyBuilder() {
        require(msgSender() == builder, "Project::!Builder");
        _;
    }

    /**
     * @dev only allow if contractor has not accepted invite request
     */
    modifier contractorNotAccepted() {
        require(!contractorConfirmed, "Project::GC accepted");
        _;
    }

    /**
     * @dev only allow if contractor has accepted invite request
     */
    modifier contractorAccepted() {
        require(contractorConfirmed, "Project::GC !accepted");
        _;
    }

    /**
     * @notice initialize this contract with required parameters. This is initialized by HomeFi contract
     * @dev modifier initializer
     * @param _hash bytes ipfs hash of this project
     * @param _currency currency address for this project
     * @param _sender address of the creator / builder for this project
     * @param _homeFiAddress address of the HomeFi contract
     */
    function initialize(
        bytes memory _hash,
        address _currency,
        address _sender,
        address _homeFiAddress
    ) external virtual;

    /**
     * @notice builder can invite a contractor with fee schedule
     * @dev modifier contractorNotAccepted
     * @param _contractor address of contractor to invite
     * @param _feeSchedule uint256 array whose length represent number of phases and each element represent the phase cost
     */
    function inviteContractor(
        address _contractor,
        uint256[] calldata _feeSchedule
    ) external virtual;

    /**
     * @notice contractor can accept the invite sent by builder
     * @dev modifier contractorNotAccepted.
     * Investment must be equal to total of all phase cost
     */
    function acceptInviteContractor() external virtual;

    /**
     * @notice update project ipfs hash with adequate signatures.
     * @dev If contractor is approved then both builder and contractor signature needed. Else only builder's.
     * @param _data bytes encoded from-
     * - bytes _hash bytes encoded ipfs hash.
     * - uint256 _nonce current hashChangeNonce
     * @param _signature bytes representing signature on _data by required members.
     */
    function updateProjectHash(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * @notice change order to add phases in project. signature of both builder and contractor required.
     * @dev modifier contractorAccepted.
     * @param _data bytes encoded from-
     * - uint256[] _phaseCosts array where each element represent phase cost, length of this array is number of phase to be added
     * - uint256 _phaseCount current phase count, for signature security
     * - address _projectAddress this project address, for signature security
     * @param _signature bytes representing signature on _data by builder and contractor.
     */
    function addPhasesGC(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * @notice change order to change cost of existing phases. signature of both builder and contractor required.
     * @dev modifier contractorAccepted.
     * @param _data bytes encoded from-
     * - uint256[] _phaseList array of phase indexes that needs to be updated
     * - uint256[] _phaseCosts cost that needs to be updated for each phase index in _phaseList
     * - address _projectAddress this project address, for signature security
     * @param _signature bytes representing signature on _data by builder and contractor.
     */
    function changeCostGC(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * @notice release phase payment of a contractor
     * @dev modifier onlyBuilder, contractorAccepted
     * @param _phaseID the phase index for which the payment needs to be released
     */
    function releaseFeeContractor(uint256 _phaseID) external virtual;

    /**
     * @notice allows investing in the project, also funds 50 phase and tasks. If the project currency is ERC20 token,
     * then before calling this function the sender must approve the tokens to this contract.
     * @dev can only be called by builder or community contract(via investor).
     * @param _cost the cost that is needed to be invested
     */
    function investInProject(uint256 _cost) external payable virtual;

    // Task-Specific //

    /**
     * @notice adds tasks in a particular phase. Needs both builder and contractor signature.
     * @dev contractor must be approved.
     * @param _data bytes encoded from-
     * - uint256 _phaseID phase number in which tasks are added
     * - bytes32[] _hash1 an array whose length is equal to number of task that you want to add,
     *   and each element is 1st part of Base58 converted ipfs hash.
     * - bytes32[] _hash2 an array similar to 2, but this time the 2nd part of Base58 converted ipfs hash.
     * - uint256[] _cost an array of cost for each task index
     * - address[] _sc an array subcontractor address for each task index
     * - uint256 _taskCount current task count before adding these tasks. Can be fetched by taskCount.
     *   For signature security.
     * - address _projectAddress the address of this contract. For signature security.
     * @param _signature bytes representing signature on _data by builder and contractor.
     */
    function addTasks(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * @dev If subcontractor is approved then builder, contractor and subcontractor signature needed.
     * Else only builder and contractor.
     * @notice update ipfs hash for a particular task
     * @param _data bytes encoded from-
     * - bytes32[2] _taskHash Base58 converted ipfs hash divided into two parts of bytes32
     * - uint256 _nonce current hashChangeNonce
     * - uint256 _taskID task index
     * @param _signature bytes representing signature on _data by required members.
     */
    function updateTaskHash(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * @notice invite subcontractors for existing tasks. This can be called by builder or contractor.
     * @dev this function internally calls _inviteSC.
     * _taskList must not have a task which already has approved subcontractor.
     * @param _taskList array the task index for which subcontractors needs to be assigned.
     * @param _scList array of addresses of subcontractor for the respective task index.
     */
    function inviteSC(uint256[] calldata _taskList, address[] calldata _scList)
        external
        virtual;

    /**
     * @notice invite subcontractors for a single task. This can be called by builder or contractor.
     * @dev invite subcontractors for a single task. This can be called by builder or contractor.
     * _taskList must not have a task which already has approved subcontractor.
     * @param _task uint256 task index
     * @param _sc address addresses of subcontractor for the respective task
     * @param _emitEvent whether to emit event for each sc added or not
     */
    function _inviteSC(
        uint256 _task,
        address _sc,
        bool _emitEvent
    ) internal virtual;

    /**
     * @notice accept invite as subcontractor for a particular task.
     * Only subcontractor invited can call this.
     * @dev subcontractor must be unapproved.
     * @param _taskList the task list of indexes for which sender wants to accept invite.
     */
    function acceptInviteSC(uint256[] calldata _taskList) external virtual;

    /**
     * @notice mark a task a complete and release subcontractor payment.
     * Needs builder,contractor and subcontractor signature.
     * @dev task must be in active state.
     * @param _data bytes encoded from-
     * - uint256 _taskID the index of task
     * - address _projectAddress the address of this contract. For signature security.
     * @param _signature bytes representing signature on _data by builder,contractor and subcontractor.
     */
    function setComplete(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * @notice allocates funds for unallocated tasks and phases, and mark them as funded.
     * @dev this is by default called by investInProject.
     * But when unallocated task/phase count are beyond 50 then this is needed to be called externally.
     */
    function fundProject() public virtual;

    /**
     * @notice recover any amount sent mistakenly to this contract. Funds are transferred to builder account.
     * If _tokenAddress is equal to this project currency, then we will first check is
     * all the phases are complete.
     * @dev If _tokenAddress is equal to this project currency, then we will first check is
     * all the phases are complete
     * @param _tokenAddress - address address for the token user wants to recover.
     */
    function recoverTokens(address _tokenAddress) external virtual;

    /**
     * @notice change order to change a task's subcontractor, cost or both.
     * Needs builder,contractor and subcontractor signature.
     * @param _data bytes encoded from-
     * - uint256 _phaseID index of phase in which the task is present
     * - uint256 _taskID index of the task
     * - address _newSC address of new subcontractor.
     *   If do not want to replace subcontractor, then pass address of existing subcontractor.
     * - uint256 _newCost new cost for the task.
     *   If do not want to change cost, then pass existing cost.
     * - address _project address of project
     * @param _signature bytes representing signature on _data by builder,contractor and subcontractor.
     */
    function changeOrder(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * Raise a dispute to arbitrate & potentially enforce requested state changes
     * @dev prolly reentrant
     *
     * @param _data bytes
     *   - 0: project address, 1: task id (0 if none), 2: action type, 3: action data, 5: ipfs cid of pdf
     *   - const types = ["address", "uint256", "uint8", "bytes", "bytes"]
     * @param _signature bytes - hash of _data signed by the address raising dispute
     */
    function raiseDispute(bytes calldata _data, bytes calldata _signature)
        external
        virtual
        returns (uint256);

    /**
     * @dev transfer excess funds back to builder wallet.
     * Called internally-
     * 1. Change in already funded phases with lower overall cost
     * 2. Phase changeOrder when new phase cost is lower than older cost
     * 3. Task changeOrder when new task cost is lower than older cost
     * @param _amount uint256 - amount of excess fund
     */
    function autoWithdraw(uint256 _amount) internal virtual;

    /**
     * @dev transfer funds to contractor or subcontract, on completion of phase or task respectively.
     */
    function payFee(address _recipient, uint256 _amount) internal virtual;

    /// VIEWABLE FUNCTIONS ///

    /**
     * @notice returns Lifecycle statuses of a task
     * @param _taskID task index
     * @return _alerts bool[3] array of bool representing whether Lifecycle alert has been reached.
     * Lifecycle alerts- [None, TaskFunded, SCConfirmed]
     */
    function getAlerts(uint256 _taskID)
        public
        view
        virtual
        returns (bool[3] memory _alerts);

    /**
     * @notice returns task ipfs hash
     * @param _taskID task index
     * @return _taskHash bytes32[2] array divided Base58 ipfs hash
     */
    function getTaskHash(uint256 _taskID)
        external
        view
        virtual
        returns (bytes32[2] memory _taskHash);

    /**
     * @notice returns cost of project. Cost of project is sum of phase and task costs.
     * @return _cost uint256 cost of project.
     */
    function projectCost() external view virtual returns (uint256 _cost);

    /**
     * @notice returns tasks index array in a phase.
     * @param _phaseID phase index for fetching tasks
     * @return _taskList uint256[] task indexes.
     */
    function getPhaseToTaskList(uint256 _phaseID)
        external
        view
        virtual
        returns (uint256[] memory _taskList);

    /**
     * @dev returns address recovered from _data and _signature
     * @param _data bytes encoded parameters
     * @param _signature bytes appended signatures
     * @param _count number of addresses to recover
     * @return _recoveredArray address[3] array of recovered address
     */
    function recoverAddresses(
        bytes memory _data,
        bytes memory _signature,
        uint256 _count
    ) internal pure virtual returns (address[3] memory _recoveredArray);

    /**
     * @dev check if recovered signatures match with builder and contractor address.
     * reverts if signature do not match.
     * @param _data bytes encoded parameters
     * @param _signature bytes appended signatures
     */
    function checkSignature(bytes calldata _data, bytes calldata _signature)
        internal
        view
        virtual;

    /**
     * @dev check if recovered signatures match with builder, contractor and subcontractor address for a task.
     * reverts if signatures do not match.
     * @param _data bytes encoded parameters
     * @param _signature bytes appended signatures
     * @param _taskID index of the task.
     */
    function checkSignatureTask(
        bytes calldata _data,
        bytes calldata _signature,
        uint256 _taskID
    ) internal view virtual;

    /**
     * @dev Insertion Sort, in ascending order.
     * @param arr_ uint256[] array needed to be sorted.
     * @return _arr uint256[] array sorted in ascending order.
     */
    function sortArray(uint256[] memory arr_)
        internal
        pure
        virtual
        returns (uint256[] memory);

    /**
     * @dev check if precision is greater than 1000, if so it reverts
     * @param _amount amount needed to be checked for precision.
     */
    function checkPrecision(uint256 _amount) internal pure virtual;

    /**
     * @dev returns the amount after adding builder fee
     * @param _amount amount to upon which builder fee is taken
     */
    function _costWithBuilderFee(uint256 _amount)
        internal
        view
        virtual
        returns (uint256 _amountWithFee);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

contract BasicMetaTransaction {
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) private nonces;

    function getChainID() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Main function to be called when user wants to execute meta transaction.
     * The actual function to be called should be passed as param with name functionSignature
     * Here the basic signature recovery is being used. Signature is expected to be generated using
     * personal_sign method.
     * @param userAddress Address of user trying to do meta transaction
     * @param functionSignature Signature of the actual function to be called via meta transaction
     * @param sigR R part of the signature
     * @param sigS S part of the signature
     * @param sigV V part of the signature
     */
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory) {
        require(
            verify(
                userAddress,
                nonces[userAddress],
                getChainID(),
                functionSignature,
                sigR,
                sigS,
                sigV
            ),
            "Meta::Invalid Signature"
        );
        nonces[userAddress] = nonces[userAddress] + 1;

        // Append userAddress at the end to extract it from calling context
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );

        require(success, "Meta::!Successful");
        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );
        return returnData;
    }

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function verify(
        address owner,
        uint256 nonce,
        uint256 chainID,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public view returns (bool) {
        bytes32 hash = prefixed(
            keccak256(abi.encodePacked(nonce, this, chainID, functionSignature))
        );
        address signer = ecrecover(hash, sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
        return (owner == signer);
    }

    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721URIStorage_init_unchained();
    }

    function __ERC721URIStorage_init_unchained() internal initializer {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
    uint256[49] private __gap;
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
    event SCConfirmed(address indexed _project, uint256[] _taskList);
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
     * @param _taskList uint256[] - the uuid's of the taskList joined by the subcontractor
     */
    function scConfirmed(uint256[] calldata _taskList) external virtual;

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

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./IHomeFi.sol";
import "../external/BasicMetaTransaction.sol";
import "../libraries/SignatureDecoder.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IProjectContract {
    function addPhasesGC(bytes calldata, bytes calldata) external;

    function changeCostGC(bytes calldata, bytes calldata) external;

    function releaseFeeContractor(uint256 _phaseID) external;

    function addTasks(bytes calldata, bytes calldata) external;

    function changeOrder(bytes calldata, bytes calldata) external;

    function setComplete(bytes calldata, bytes calldata) external;

    function tasks(uint256)
        external
        view
        returns (
            uint256,
            address,
            uint8
        );

    function builder() external view returns (address);

    function contractor() external view returns (address);
}

/**
 * Module for raising disputes for arbitration within HomeFi projects
 */
abstract contract IDisputes is
    Initializable,
    BasicMetaTransaction,
    ReentrancyGuardUpgradeable
{
    /// INTERFACES ///

    IHomeFi public homeFi;
    IEvents public eventsInstance;

    /// MODIFIERS ///

    modifier nonZero(address _address) {
        // ensure an address is not the zero address (0x00)
        require(_address != address(0), "Dispute::0 address");
        _;
    }

    modifier onlyAdmin() {
        // ensure that only HomeFi admins can arbitrate disputes
        require(homeFi.admin() == msgSender(), "Dispute::!Admin");
        _;
    }

    modifier onlyProject() {
        // ensure the call originates from a valid project contract
        require(homeFi.projectExist(msgSender()), "Dispute::!Project");
        _;
    }

    /**
     * Affirm that a given dispute is currently resolvable
     * @param _disputeID uint256 - the serial/id of the dispute
     */
    modifier resolvable(uint256 _disputeID) {
        require(
            _disputeID < disputeCount &&
                disputes[_disputeID].status == Status.Active,
            "Disputes::!Resolvable"
        );
        _;
    }

    /// ENUMERATIONS ///

    enum Status {
        None,
        Active,
        Accepted,
        Rejected
    }

    //determines how dispute action params are parsed and executed
    enum ActionType {
        None,
        PhaseAdd,
        PhaseChange,
        PhasePay,
        TaskAdd,
        TaskChange,
        TaskPay
    }

    /// STRUCTS ///

    struct Dispute {
        // Object storing metadata around disputes
        Status status; //the ruling on the dispute (see Status enum for all possible cases)
        address project; //project the dispute occurred in
        uint256 taskID; // task the dispute occurred in
        address raisedBy; // user who raised the dispute
        bytes reason; //cid of the document registered when dispute was raised
        bytes judgement; //cid of document used to mark the dispute arbitrated
        uint256 attachmentsCount;
        mapping(uint256 => bytes) attachments;
        ActionType actionType;
        bytes actionData;
    }

    /// DATA STORAGE ///

    mapping(uint256 => Dispute) public disputes;
    uint256 public disputeCount; //starts from 0

    /// CONSTRUCTOR ///

    /**
     * Initialize a new communities contract
     * @notice THIS IS THE CONSTRUCTOR thanks upgradable proxies
     * @dev modifier initializer
     *
     * @param _homeFi address - address of main homeFi contract
     * @param _eventsContract address - address of events contract
     */
    function initialize(address _homeFi, address _eventsContract)
        external
        virtual;

    /// MUTABLE FUNCTIONS ///

    /**
     * Asserts whether a given address is a member of a project,
     * Reverts if address not a member
     *
     * @param _project address - the project being queried for membership
     * @param _task uint256 - the index/serial of the task
     *  - if not querying for subcontractor, set as 0
     * @param _address address - the address being checked for membership
     */
    function assertMember(
        address _project,
        uint256 _task,
        address _address
    ) public virtual;

    /**
     * Raise a new dispute
     * @dev modifier
     * @dev modifier onlyMember (must be decoded first)
     *
     * @param _data bytes
     *   - 0: project address, 1: task id (0 if none), 2: action disputeType, 3: action data, 5: ipfs cid of pdf
     *   - const types = ["address", "uint256", "uint8", "bytes", "bytes"]
     * @param _signature bytes - hash of _data signed by the address raising dispute
     */
    function raiseDispute(bytes calldata _data, bytes calldata _signature)
        external
        virtual
        returns (uint256);

    /**
     * Attach cid of arbitrary documents used to arbitrate disputes
     *
     * @param _disputeID uint256 - the uuid/serial of the dispute within this contract
     * @param _attachment bytes - the URI of the document being added
     */
    function attachDocument(uint256 _disputeID, bytes calldata _attachment)
        external
        virtual;

    /**
     * Attach cid of arbitrary documents used to arbitrate disputes
     *
     * @param _disputeID uint256 - the uuid/serial of the dispute within this contract
     * @param _attachments bytes[] - the URIs of the document being added
     */
    function attachMultipleDocuments(
        uint256 _disputeID,
        bytes[] calldata _attachments
    ) external virtual;

    /**
     * Arbitrate a dispute & execute accompanying enforcement logic to achieve desired project state
     * @dev modifier onlyAdmin
     *
     * @param _disputeID uint256 - the uuid (serial) of the dispute in this contract
     * @param _judgement bytes - the URI hash of the document to be used to close the dispute
     * @param _ratify bool - true if status should be set to accepted, and false if rejected
     */
    function resolveDispute(
        uint256 _disputeID,
        bytes calldata _judgement,
        bool _ratify
    ) external virtual;

    /// INTERNAL FUNCTIONS ///

    /**
     * Given an id, attempt to execute the action to enforce the arbitration
     * @dev modifier actionUsed
     * @dev needs reentrant check
     * @notice logic for decoding and enforcing outcome of arbitration judgement
     *
     * @param _disputeID uint256 - the dispute to attempt to
     */
    function resolveHandler(uint256 _disputeID) internal virtual;

    /**
     * Arbitration enforcement of changing costs of phases
     * @notice should only ever be used by resolveHandler
     *
     * @param _project address - the project address of the dispute
     * @param _actionData bytes - the phase add transaction data stored when dispute was raised
     * - uint256[] _phaseCosts array where each element represent phase cost, length of this array is number of phase to be added
     * - uint256 _phaseCount current phase count, for signature security
     * - address _projectAddress this project address, for signature security
     */
    function executePhaseAdd(address _project, bytes memory _actionData)
        internal
        virtual;

    /**
     * Arbitration enforcement of changing costs of phases
     * @notice should only ever be used by resolveHandler
     *
     * @param _project address - the project address of the dispute
     * @param _actionData bytes - the phase change transaction data stored when dispute was raised
     *   - 0: array indexes of tasks under dispute, 1: costs to set corresponding to first array, 2: project address
     *   - const types = ["uint256[]", "uint256[]", "address"]
     */
    function executePhaseChange(address _project, bytes memory _actionData)
        internal
        virtual;

    /**
     * Arbitration enforcement of paying General Contractor phase fees
     * @notice should only ever be used by resolveHandler
     *
     * @param _project address - the project address of the dispute
     * @param _actionData bytes - the phase payout transaction data stored when dispute was raised
     *   - 0: phase under payment dispute, 2: project address
     *   - const types = ["uint256", "address"]
     */
    function executePhasePay(address _project, bytes memory _actionData)
        internal
        virtual;

    /**
     * Arbitration enforcement of task change orders
     * @notice should only ever be used by resolveHandler
     *
     * @param _project address - the project address of the dispute
     * @param _actionData bytes - the task add transaction data stored when dispute was raised
     * - uint256 _phaseID phase number in which tasks are added
     * - bytes32[] _hash1 an array whose length is equal to number of task that you want to add,
     *   and each element is 1st part of Base58 converted ipfs hash.
     * - bytes32[] _hash2 an array similar to 2, but this time the 2nd part of Base58 converted ipfs hash.
     * - uint256[] _cost an array of cost for each task index
     * - address[] _sc an array subcontractor address for each task index
     * - uint256 _taskSerial current task count/serial before adding these tasks. Can be fetched by taskSerial.
     * - address _projectAddress the address of this contract. For signature security.
     */
    function executeTaskAdd(address _project, bytes memory _actionData)
        internal
        virtual;

    /**
     * Arbitration enforcement of task change orders
     * @notice should only ever be used by resolveHandler
     *
     * @param _project address - the project address of the dispute
     * @param _actionData bytes - the task change order transaction data stored when dispute was raised
     * - 0: index of phase; 1: index of task; 2: task subcontractor; 3: task cost; 4: project address
     * - ["uint256", "uint256", "address", "uint256", "address"]
     */
    function executeTaskChange(address _project, bytes memory _actionData)
        internal
        virtual;

    /**
     * Arbitration enforcement of task payout
     * @notice should only ever be used by resolveHandler
     *
     * @param _project address - the project address of the dispute
     * @param _actionData bytes - the task payout transaction data stored when dispute was raised
     * - 0: index of task; 2: project address
     * - ["uint256", "address"]
     */
    function executeTaskPay(address _project, bytes memory _actionData)
        internal
        virtual;

    /// VIEWABLE FUNCTIONS ///

    /**
     * Return the URI hash of a document given a specific query
     *
     * @param _disputeID uint256 - the uuid/ serial of the dispute in this contract
     * @param _index uint256 - the index of the attachment within the dispute
     * @return bytes - the URI (IPFS CID) hash of the attachment
     */
    function getAttachment(uint256 _disputeID, uint256 _index)
        external
        view
        virtual
        returns (bytes memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes

library SignatureDecoder {
    /// @dev Recovers address who signed the message
    /// @param messageHash keccak256 hash of message
    /// @param messageSignatures concatenated message signatures
    /// @param pos which signature to read
    function recoverKey(
        bytes32 messageHash,
        bytes memory messageSignatures,
        uint256 pos
    ) internal pure returns (address) {
        if (messageSignatures.length % 65 != 0) {
            return (address(0));
        }

        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = signatureSplit(messageSignatures, pos);

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(toEthSignedMessageHash(messageHash), v, r, s);
        }
    }

    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := byte(0, mload(add(signatures, add(signaturePos, 0x60))))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

library Tasks {
    /// MODIFIERS ///

    /// @dev only allow inactive tasks. Task are inactive if SC is unconfirmed.
    modifier onlyInactive(Task storage _self) {
        require(_self.state == TaskStatus.Inactive, "Task::active");
        _;
    }

    /// @dev only allow active tasks. Task are inactive if SC is confirmed.
    modifier onlyActive(Task storage _self) {
        require(_self.state == TaskStatus.Active, "Task::!Active");
        _;
    }

    /// @dev only allow funded tasks.
    modifier onlyFunded(Task storage _self) {
        require(_self.alerts[uint256(Lifecycle.TaskFunded)], "Task::!funded");
        _;
    }

    /// MUTABLE FUNCTIONS ///

    // Task Status Changing Functions //

    /**
     * Create a new Task object
     * @dev cannot operate on initialized tasks
     * @param _self Task the task struct being mutated
     * @param _cost uint the number of tokens to be escrowed in this contract
     */
    function initialize(
        Task storage _self,
        bytes32[2] memory _taskHash,
        uint256 _cost
    ) public {
        _self.taskHash = _taskHash;
        _self.cost = _cost;
        _self.state = TaskStatus.Inactive;
        _self.alerts[uint256(Lifecycle.None)] = true;
    }

    /**
     * Attempt to transition task state from Payment Pending to Complete
     * @dev modifier onlyActive
     * @param _self Task the task whose state is being mutated
     */
    function setComplete(Task storage _self) internal onlyActive(_self) {
        // State/ Lifecycle //
        _self.alerts[uint256(Lifecycle.None)] = true;
        _self.state = TaskStatus.Complete;
    }

    // Subcontractor Joining //

    /**
     * Invite a subcontractor to the task
     * @dev modifier onlyInactive
     * @param _self Task the task being joined by subcontractor
     * @param _sc address the subcontractor being invited
     */
    function inviteSubcontractor(Task storage _self, address _sc)
        internal
        onlyInactive(_self)
    {
        _self.subcontractor = _sc;
    }

    /**
     * As a subcontractor, accept an invitation to participate in a task.
     * @dev modifier onlyInactive and onlyFunded
     * @param _self Task the task being joined by subcontractor
     * @param _sc Address of sender
     */
    function acceptInvitation(Task storage _self, address _sc)
        internal
        onlyInactive(_self)
        onlyFunded(_self)
    {
        // Prerequisites //
        require(_self.subcontractor == _sc, "Task::!SC");

        // State/ lifecycle //
        _self.alerts[uint256(Lifecycle.SCConfirmed)] = true;
        _self.state = TaskStatus.Active;
    }

    // Task Funding //

    /**
     * Set a task as funded
     * @dev modifier onlyInactive
     * @param _self Task the task being set as funded
     */
    function fundTask(Task storage _self) internal onlyInactive(_self) {
        // State/ Lifecycle //
        _self.alerts[uint256(Lifecycle.TaskFunded)] = true;
        _self.alerts[uint256(Lifecycle.None)] = false;
    }

    /**
     * Set a task as un-funded
     * @dev modifier onlyFunded
     * @param _self Task the task being set as funded
     */
    function unFundTask(Task storage _self) internal onlyFunded(_self) {
        // State/ lifecycle //
        _self.alerts[uint256(Lifecycle.TaskFunded)] = false;
        _self.alerts[uint256(Lifecycle.None)] = true;
    }

    /**
     * Set a task as un accepted/approved for SC
     * @dev modifier onlyActive
     * @param _self Task the task being set as funded
     */
    function unApprove(Task storage _self) internal onlyActive(_self) {
        // State/ lifecycle //
        _self.alerts[uint256(Lifecycle.SCConfirmed)] = false;
        _self.state = TaskStatus.Inactive;
    }

    /// VIEWABLE FUNCTIONS ///

    /**
     * Determine the current state of all alerts in the project
     * @param _self Task the task being queried for alert status
     * @return _alerts bool[3] array of bool representing whether Lifecycle alert has been reached
     */
    function getAlerts(Task storage _self)
        internal
        view
        returns (bool[3] memory _alerts)
    {
        for (uint256 i = 0; i < _alerts.length; i++)
            _alerts[i] = _self.alerts[i];
    }

    /**
     * Return the numerical encoding of the TaskStatus enumeration stored as state in a task
     * @param _self Task the task being queried for state
     * @return _state uint 0: none, 1: inactive, 2: active, 3: complete
     */
    function getState(Task storage _self)
        internal
        view
        returns (uint256 _state)
    {
        return uint256(_self.state);
    }
}

// Task metadata
struct Task {
    // Metadata //
    bytes32[2] taskHash;
    uint256 cost;
    address subcontractor;
    // Lifecycle //
    TaskStatus state;
    mapping(uint256 => bool) alerts;
}

enum TaskStatus {
    None,
    Inactive,
    Active,
    Complete
}

enum Lifecycle {
    None,
    TaskFunded,
    SCConfirmed
}

