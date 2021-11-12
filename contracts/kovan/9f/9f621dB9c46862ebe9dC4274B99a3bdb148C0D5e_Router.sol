// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

//import "hardhat/console.sol";
import "./interface/IRouter.sol";
import "./interface/ILP.sol";
import "./interface/IFeeder.sol";
import "./interface/IAzuroBet.sol";
import "./interface/IAgreement.sol";
import "./ProxyLP.sol";
import "./ProxyFEED.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Router is OwnableUpgradeable, IRouter {
    /**
     * @dev Azuro token
     */
    address public protocolToken;

    /**
     * @dev beacon for LP actual implementation
     */
    address public beaconLP;

    /**
     * @dev beacon for FEED actual implementation
     */
    address public beaconFEED;

    /**
     * @dev NFT Azuro Bet Token
     */
    address public nftAzuroBetToken;

    /**
     * @dev Agreement contract
     */

    IAgreement public agreement;

    /**
     * @dev Time resolve period latency for checking result accuracy from FEED porovider
     */
    uint64 public timeResolvePeriod;

    /**
     * @dev Time dispute period latency for approving / disapproving and voting result from FEED provider
     */
    uint64 public timeDisputePeriod;

    /**
     * @dev lpData consists of pair of LP
     */
    struct lpData {
        address pool;
        address paymentToken;
        uint256 period;
        address owner;
        bool isActive;
    }
    lpData[] public lpRegistry;
    //uint256 lastLP;
    // lp address => number of registgry
    mapping(address => uint256) lpRegistrytoNumberMap;

    struct stakedClaimed {
        bool isStaked;
        bool isClaimed;
    }

    /**
     * @dev staker address => tokenId => stakedClaimed()
     */
    mapping(address => mapping(uint256 => stakedClaimed)) stakerAzuroClaimed;

    /**
     * @dev feedData common info about the feed
     */
    struct feedData {
        address feedAddress;
        bool isActive;
    }

    feedData[] public feedRegistry;
    mapping(address => uint256) feedtoNumberMap;

    // store core addresses in array. Order number is core type
    address[] public coreTypes;

    // CORE => CoreTypeID
    mapping(address => uint256) COREtocoreType;

    /**
     * @dev LP -> COREs link structures purpose
     * 1. from LP get coreType's list
     * 2. check from LP is exact coreType active
     * 3. for LP activate/deactivate coreType
     */

    // from LP get coreType's list
    // LPreg => CORE
    mapping(uint256 => uint256[]) LPRegAllCoreTypes;

    // check from LP is exact coreType active
    // for LP activate/deactivate coreType
    // LPreg => (CORE => active)
    mapping(uint256 => mapping(uint256 => bool)) LPRegtoCoreType;

    // FEED => CoreTypeID
    //mapping(address => uint256) FEEDtocoreType; - not used, think again and remove

    /**
     * @dev FEED -> COREs link structures purpose
     * 1. from FEED get coreType's list
     * 2. check from FEED is exact coreType active
     * 3. for FEED activate/deactivate coreType
     */

    // from FEED get coreType's list
    // FEED => CORE
    //mapping(address => uint256[]) FeedAllCoreTypes; - not used, think again and remove

    // check from FEED is exact coreType active
    // for FEED activate/deactivate coreType
    // FEED => (CORE => active)
    mapping(address => mapping(uint256 => bool)) FeedtoCoreType;

    uint256 public FeedSecurity;

    /**
     * @dev LP <-> FEED agreement job details
     * @param timeStop - stop data, =0 for inactive agreement
     * @param timePeriod - latency
     * @param coreType - core type
     * @param jobConditionResolves - number of condition resolves rest in job
     * @param jobFund - amount of full job payment, supplied by LP owner
     * @param jobSecurity - job security, supplied by FEED provider, must be > 0 for active job proposal
     * @param taskResultPenalty - whole penalty = jobs * ResultPenalty
     */

    /* struct agreement {
        uint256 timeStop;
        uint32 timePeriod;
        uint32 coreType;
        uint32 jobs;
        uint32 jobConditionResolves;
        uint128 jobFund;
        uint128 jobPenalty;
        uint128 taskResultPenalty;
    } */

    /**
     * @dev public agreements list
     */
    //agreement[] public agreements;

    /**
     * @dev agreementID => LP
     */
    //mapping(uint256 => address) AgreementtoLP;

    /**
     * @dev agreementID => accepted
     */
    //mapping(uint256 => bool) AcceptedAgreement;

    /**
     * @dev  agreementID => FEED
     */
    //mapping(uint256 => address) AgreementtoFeed;

    event LPRegisterd(
        uint256 lpID,
        address pool,
        address paymentToken,
        address lpOwner,
        bool isActive
    );
    event FeedRegistered(address feedAddress, address feedOwner, bool isActive);

    event ProposalCreated(
        address feedAdress,
        uint256 agreementID,
        string agreementName
    );
    event ProposalCanceled(address feedAdress, uint256 agreementID);

    event disputeStarted(
        address disputeWqallet,
        uint256 lpID,
        uint256 conditionID,
        uint256 disputeStakeAmount,
        uint128 disputeOutcomeID
    );

    modifier onlyFeed(address feedAddress) {
        require(
            feedtoNumberMap[feedAddress] != 0 &&
                feedRegistry[feedtoNumberMap[feedAddress]].isActive,
            "only active feed allowed"
        );
        _;
    }

    modifier onlyAgreedFeed(uint256 inAgreement) {
        //agreement storage _agreement = agreements[inAgreement];
        require(
            //_agreement.timeStop
            agreement.getAgreementData(inAgreement).timeStop >=
                block.timestamp &&
                agreement.getAgreementData(inAgreement).jobConditionResolves !=
                0,
            "Agreement: not allowed"
        );
        require(
            agreement.isAgreementAccepted(inAgreement),
            "Agreement: not work"
        );
        require(
            agreement.getAgreementtoFEED(inAgreement) == msg.sender,
            "Agreement: feed not allowed"
        );
        _;
    }

    modifier onlyLPowner(uint256 lpID) {
        require(
            lpRegistry[lpID].owner == msg.sender && lpRegistry[lpID].isActive,
            "only lp owner allowed"
        );
        _;
    }

    /**
     * @dev router initialize start values
     * @param _beaconLP LP logic (beacon)
     * @param _beaconFEED FEED logic (beacon)
     * @param _nftAzuroBetToken bet NFT
     * @param _protocolToken security token
     * @param _initFeedSecurity FEED security value
     */

    function initialize(
        address _owner,
        address _beaconLP,
        address _beaconFEED,
        address _nftAzuroBetToken,
        address _protocolToken,
        uint256 _initFeedSecurity
    ) public virtual initializer {
        __Ownable_init();
        transferOwnership(_owner);
        beaconLP = _beaconLP;
        beaconFEED = _beaconFEED;
        nftAzuroBetToken = _nftAzuroBetToken;
        FeedSecurity = _initFeedSecurity;
        protocolToken = _protocolToken;
        feedRegistry.push(feedData(address(0), false));
        timeResolvePeriod = 900; // 15 min
        timeDisputePeriod = 604800; // 1 week
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /**
     * @dev registerLP - register new LP contract(s)
     * @param paymentToken liquidity pool token
     * @param period LP PERIOD
     * @param reinforcement value
     * @param marginality value
     * @param LPOwner address of owner to assign to
     * @param isActive active flag
     */

    function registerLP(
        address paymentToken,
        uint256 period,
        uint256[] calldata _coreTypes,
        uint256 reinforcement,
        uint256 marginality,
        address LPOwner,
        bool isActive
    ) external override {
        require(
            paymentToken != address(0) &&
                period > 0 &&
                reinforcement > 0 &&
                marginality > 0 &&
                LPOwner != address(0),
            "#6" /* "incorrect input data!" */
        );

        // call proxyLP to create LP-contract proxies
        address lpPool = address(new ProxyLP(beaconLP, ""));

        ILP(lpPool).initialize(
            address(this),
            reinforcement,
            marginality,
            LPOwner
        ); //azurobet

        lpRegistry.push(
            lpData(lpPool, paymentToken, period, LPOwner, isActive)
        );
        //lastLP = lpRegistry.length;
        lpRegistrytoNumberMap[lpPool] = lpRegistry.length - 1;
        // fill up coreTypes for LP registry
        for (uint256 index = 0; index < _coreTypes.length; index++) {
            LPRegtoCoreType[lpRegistry.length - 1][
                _coreTypes[index]
            ] = isActive;
        }

        IAzuroBet(nftAzuroBetToken).setLP(lpPool);
        emit LPRegisterd(
            lpRegistry.length - 1,
            lpPool,
            paymentToken,
            LPOwner,
            isActive
        );
    }

    /**
     * @dev change LP period calls same LP function
     * @param lpID LP id
     * @param newPeriod new period length
     */

    function changeLPPeriod(uint256 lpID, uint256 newPeriod)
        external
        override
        onlyLPowner(lpID)
    {
        ILP(lpRegistry[lpID].pool).changePeriod(msg.sender);
        /* ILP(lpRegistry[lpRegistrytoNumberMap[lp]].lpSecond).changePeriod(
            msg.sender
        ); */
        lpRegistry[lpID].period = newPeriod;
    }

    /**
     * @dev registerFeed - register new feed contract
     * @param feedOwner address
     * @param feedDescription feed text description
     * @param feedCoreTypes supported core types list
     * @param isActive active flag
     * @param penaltyAllowed is penalty security enabled
     */

    function registerFeed(
        address feedOwner,
        string calldata feedDescription,
        uint256[] calldata feedCoreTypes,
        bool isActive,
        bool penaltyAllowed
    ) external override {
        // call proxyFEED to create FEED-contract proxies
        address feedAddress = address(new ProxyFEED(beaconFEED, ""));

        IFeeder(feedAddress).initialize(
            address(this),
            feedOwner,
            feedDescription,
            penaltyAllowed
        );

        // uncomment for feed tests require(feedAddress != address(0) && _isContract(feedAddress), "feed not set");
        require(
            feedtoNumberMap[feedAddress] == 0,
            "#7" /* "feed exist" */
        );
        feedRegistry.push(feedData(feedAddress, isActive));
        feedtoNumberMap[feedAddress] = feedRegistry.length - 1;
        // fill up coreTypes for FEED
        for (uint256 index = 0; index < feedCoreTypes.length; index++) {
            FeedtoCoreType[feedAddress][feedCoreTypes[index]] = isActive;
        }
        emit FeedRegistered(feedAddress, feedOwner, isActive);
    }

    function addLiquidity(uint256 lpID, uint256 _amount) external override {
        TransferHelper.safeTransferFrom(
            lpRegistry[lpID].paymentToken,
            msg.sender,
            lpRegistry[lpID].pool,
            _amount
        ); //place to router
        ILP(lpRegistry[lpID].pool).addLiquidity(msg.sender, _amount);
    }

    function withdrawLiquidity(uint256 lpID, uint256 valueLP)
        external
        override
    {
        ILP(lpRegistry[lpID].pool).withdrawLiquidity(msg.sender, valueLP);
    }

    function liquidityRequest(uint256 lpID, uint256 valueLP) external override {
        ILP(lpRegistry[lpID].pool).liquidityRequest(msg.sender, valueLP);
    }

    function _createCondition(
        uint256 inAgreement,
        uint256 oracleConditionID,
        uint256 coreType,
        uint256[] calldata rates,
        uint256 timestamp,
        string memory ipfsHash
    ) internal onlyAgreedFeed(inAgreement) {
        // check feed working with exact coreType
        require(
            FeedtoCoreType[msg.sender][coreType],
            "Agreement: not active coreType"
        );
        //get lp from lpRegs list
        if (
            checkLPtoCoreType(
                lpRegistrytoNumberMap[agreement.getAgreementtoLP(inAgreement)],
                coreType
            )
        ) {
            uint256 jobResultPenalty = agreement.getJobResultPenalty(
                inAgreement
            );
            ILP(agreement.getAgreementtoLP(inAgreement)).createConditionTest(
                oracleConditionID,
                coreType,
                rates,
                timestamp,
                ipfsHash,
                jobResultPenalty
            );
        }
    }

    /**
     * @dev createCondition - create new condition
     * @param inAgreements agreements list
     * @param oracleConditionID condition id
     * @param rates rate array
     * @param timestamp date
     * @param ipfsHash hash
     */

    function createCondition(
        uint256[] calldata inAgreements,
        uint256 oracleConditionID,
        uint256 coreType,
        uint256[] calldata rates,
        uint256 timestamp,
        string memory ipfsHash
    ) external override onlyFeed(msg.sender) {
        for (uint256 index = 0; index < inAgreements.length; index++) {
            _createCondition(
                inAgreements[index],
                oracleConditionID,
                coreType,
                rates,
                timestamp,
                ipfsHash
            );
        }
    }

    function _resolveCondition(
        uint256 inAgreement,
        uint256 conditionID,
        uint128 outcomeWin
    ) internal onlyAgreedFeed(inAgreement) returns (uint256 feedProfit) {
        //agreement storage _agreement = agreements[inAgreement];
        //get lp in state true
        ILP(agreement.getAgreementtoLP(inAgreement)).resolveConditionTest(
            conditionID,
            outcomeWin,
            timeResolvePeriod
        );

        uint128 _profit = agreement.resolveCondition(inAgreement);
        feedProfit += _profit;
    }

    /**
     * @dev resolveCondition - resolve condition
     * @param inAgreements agreements registration list
     * @param conditionID condition id
     * @param outcomeWin condition outcome result
     */

    function resolveCondition(
        uint256[] calldata inAgreements,
        uint256 conditionID,
        uint128 outcomeWin
    ) external override onlyFeed(msg.sender) {
        uint256 feedProfit;
        for (uint256 index = 0; index < inAgreements.length; index++) {
            feedProfit += _resolveCondition(
                inAgreements[index],
                conditionID,
                outcomeWin
            );
        }
        // FEED receive profit for creating/resolving condition, while resolving can be disputed
        IERC20(protocolToken).transfer(
            IFeeder(msg.sender).getOwner(),
            feedProfit
        );
        //emit testresolveCondition(msg.sender); //think about remove it
    }

    /**
     * @dev make bet
     * @param lpID id of LP contract
     * @param conditionID condition ID
     * @param amount stake amount
     * @param outcomeID bet outcome ID
     * @param deadline bet deadline time
     * @param minRate min bet rate
     */

    function bet(
        uint256 lpID,
        uint256 conditionID,
        uint256 amount,
        uint256 outcomeID,
        uint256 deadline,
        uint256 minRate,
        bool doMintNFT
    ) external override {
        // get LP lpRegistry by conditionID
        //console.log("bet 01", gasleft());
        TransferHelper.safeTransferFrom(
            lpRegistry[lpID].paymentToken,
            msg.sender,
            lpRegistry[lpID].pool,
            amount
        ); // 33875 gas
        //console.log("bet 02", gasleft());
        IAzuroBet(nftAzuroBetToken).inclastBetNumber(); // 20537 gas
        //console.log("bet 03", gasleft());
        uint256 tokenId = IAzuroBet(nftAzuroBetToken).getlastBetNumber();
        //console.log("bet 04", gasleft());

        if (doMintNFT) {
            IAzuroBet(nftAzuroBetToken).mint(msg.sender, tokenId); //126461 gas
        } else {
            // just save tokenId for staker (isStaked=true, isClaimed=false)
            // mint must be done for withdraw prize!!!
            //console.log("bet 04 01", gasleft());
            stakerAzuroClaimed[msg.sender][tokenId].isStaked = true; // 23018
        }
        //console.log("bet 05", gasleft());
        // Mode()
        ILP(lpRegistry[lpID].pool).bet(
            msg.sender,
            conditionID,
            amount,
            outcomeID,
            deadline,
            minRate,
            tokenId
        ); //167077 gas
        //console.log("bet 06", gasleft());
    }

    /**
     * @dev withdraw prize interface function, only for AzuroNFT token owner (token must be minted)!!!
     * @param lpID LP registry index
     * @param tokenId bet token id
     */
    function withdrawPrize(uint256 lpID, uint256 tokenId) external override {
        ILP(lpRegistry[lpID].pool).withdrawPrize(msg.sender, tokenId);
    }

    function disputeStake(
        uint256 lpID,
        uint256 conditionID,
        uint256 disputeStakeAmount,
        uint128 disputeOutcomeID
    ) external override {
        // check condition state, stake, outcome
        // require conditionID is resolved and not in dispute
        require(
            disputeStakeAmount ==
                ILP(lpRegistry[lpID].pool).getJobResultPenalty(conditionID),
            "Dispute: incorrect stake"
        );
        IERC20(protocolToken).transferFrom(
            msg.sender,
            address(this),
            disputeStakeAmount
        );
        ILP(lpRegistry[lpID].pool).startDispute(
            msg.sender,
            conditionID,
            disputeStakeAmount,
            disputeOutcomeID,
            timeDisputePeriod
        );
        emit disputeStarted(
            msg.sender,
            lpID,
            conditionID,
            disputeStakeAmount,
            disputeOutcomeID
        );
    }

    function resolveDispute() public {}

    /**
     * @dev claim NFT stake token if not claimed
     * @param tokenId - token ID
     */
    function claimAzuroBetToken(uint256 tokenId) external override {
        require(
            stakerAzuroClaimed[msg.sender][tokenId].isStaked &&
                !stakerAzuroClaimed[msg.sender][tokenId].isClaimed
        );
        stakerAzuroClaimed[msg.sender][tokenId].isClaimed = true;
        IAzuroBet(nftAzuroBetToken).mint(msg.sender, tokenId);
    }

    /**
     * @dev fill up core type contracts list
     */
    function addCoreType(address core) external override onlyOwner {
        require(_isContract(core));
        coreTypes.push(core);
        COREtocoreType[core] = coreTypes.length - 1;
    }

    function setAgreement(address _agreement) external override onlyOwner {
        require(
            _agreement != address(0) &&
                _isContract(_agreement) &&
                address(_agreement) != address(agreement)
        );
        agreement = IAgreement(_agreement);
    }

    function setLPCoreType(
        uint256 lpID,
        uint256 coreType,
        bool isActive
    ) external override onlyLPowner(lpID) {
        LPRegtoCoreType[lpID][coreType] = isActive;
        ILP(lpRegistry[lpID].pool).setCoreType(
            uint64(coreType),
            coreTypes[coreType]
        );
    }

    /**
     * @dev creates job proposal
     * @param timePeriod job period length
     * @param coreType job core type
     * @param jobTaskCount number of creates/resolves conditions
     * @param jobFund job payment, will be paid to Feeder by executiong tasks
     * @param jobPenalty job penalty, must paid by Feeder for job proposal
     * @param taskResultPenalty penalty for task incorrectness, one task penalty is taskResultPenalty / jobTaskCount
     * @param agreementName symbolic name for UI proposal market
     */

    function FEEDcreateAgreement(
        uint32 timePeriod,
        uint32 coreType,
        uint32 jobTaskCount,
        uint128 jobFund,
        uint128 jobPenalty,
        uint128 taskResultPenalty,
        string memory agreementName
    ) external override onlyFeed(msg.sender) {
        uint256 agreementId = agreement.FEEDcreateAgreement(
            timePeriod,
            coreType,
            jobTaskCount,
            jobFund,
            jobPenalty,
            taskResultPenalty,
            msg.sender
        );
        emit ProposalCreated(msg.sender, agreementId, agreementName);
    }

    /**
     * @dev cancel inactivated job proposal
     * @param agreementID agreement id for cancel
     */

    function FEEDcancelAgreement(uint256 agreementID)
        external
        override
        onlyFeed(msg.sender)
    {
        IERC20(protocolToken).transfer(
            IFeeder(msg.sender).getOwner(),
            agreement.FEEDcancelAgreement(agreementID, msg.sender)
        );
        emit ProposalCanceled(msg.sender, agreementID);
    }

    function LPAcceptAgreement(uint256 lpID, uint256 agreementID)
        external
        override
        onlyLPowner(lpID)
    {
        IERC20(protocolToken).transferFrom(
            lpRegistry[lpID].owner,
            address(this),
            agreement.LPAcceptAgreement(lpRegistry[lpID].pool, agreementID)
        );
    }

    function LPCloseAgreement(uint256 lpID, uint256 agreementID)
        external
        override
        onlyLPowner(lpID)
    {
        (uint256 penaltyAmount, uint256 returntoFeed, address feed) = agreement
            .LPCloseAgreement(lpRegistry[lpID].pool, agreementID);

        if (penaltyAmount > 0) {
            IERC20(protocolToken).transfer(
                lpRegistry[lpID].owner,
                penaltyAmount
            );
        }

        if (returntoFeed > 0) {
            IERC20(protocolToken).transfer(
                IFeeder(feed).getOwner(),
                returntoFeed
            );
        }
    }

    /**
     * @dev Returns the current implementation address.
     */
    function getAzuroToken() public view virtual override returns (address) {
        return nftAzuroBetToken;
    }

    function getLPRegistry(uint256 lpID)
        external
        view
        override
        returns (
            address pool,
            address paymentToken,
            uint256 period,
            bool isActive
        )
    {
        lpData memory _lpData = lpRegistry[lpID];
        return (
            _lpData.pool,
            _lpData.paymentToken,
            _lpData.period,
            _lpData.isActive
        );
    }

    function getLPpaymentToken(address lp)
        external
        view
        override
        returns (address paymentToken)
    {
        return (lpRegistry[lpRegistrytoNumberMap[lp]].paymentToken);
    }

    function getLPperiod(address lp)
        external
        view
        override
        returns (uint256 period)
    {
        //console.log("getLPperiod period %s", lpRegistry[lpRegistrytoNumberMap[lp]].period);
        return (lpRegistry[lpRegistrytoNumberMap[lp]].period);
    }

    function getLPIDowner(uint256 lpID)
        external
        view
        override
        returns (address owner)
    {
        return (lpRegistry[lpID].owner); //TODO: think to remove LP owner registry from router to LP contract
    }

    function getLPowner(address lp)
        external
        view
        override
        returns (address owner)
    {
        return (lpRegistry[lpRegistrytoNumberMap[lp]].owner);
    }

    /**
     * @dev get core address by coreType ID
     * @param typeId coreType ID
     */
    function getCorebyType(uint256 typeId)
        external
        view
        override
        returns (address core)
    {
        return coreTypes[typeId];
    }

    /**
     * @dev get core coreType ID by core address
     * @param core address
     */
    function getCoreTypebyCore(address core)
        external
        view
        override
        returns (uint256 typeId)
    {
        return COREtocoreType[core];
    }

    /**
     * @dev check LP working with coreType
     * @param lpID LP id
     * @param coreType coreType
     * @return OK - if lpID have coreType
     */
    function checkLPtoCoreType(uint256 lpID, uint256 coreType)
        public
        view
        returns (bool OK)
    {
        return (
            LPRegtoCoreType[lpRegistrytoNumberMap[lpRegistry[lpID].pool]][
                coreType
            ]
        );
    }

    function getLiquidityRequests(uint256 lpID, address wallet)
        external
        view
        override
        returns (uint256 total, uint256 personal)
    {
        (total, personal) = ILP(lpRegistry[lpID].pool).getLiquidityRequests(
            wallet
        );
    }

    function getLPReserve(uint256 lpID)
        external
        view
        override
        returns (uint256 reserve)
    {
        reserve = ILP(lpRegistry[lpID].pool).getReserve();
    }

    function getLPSupply(uint256 lpID)
        external
        view
        override
        returns (uint256 totalSupply)
    {
        totalSupply = ILP(lpRegistry[lpID].pool).getSupply();
    }

    function getLPcount() external view override returns (uint256 LPcount) {
        return lpRegistry.length;
    }

    function getFeedSecurity()
        external
        view
        override
        returns (uint256 securityValue)
    {
        return FeedSecurity;
    }

    function getProtocolToken()
        external
        view
        override
        returns (address _protocolToken)
    {
        return protocolToken;
    }

    function getAgreementsLength()
        external
        view
        override
        returns (uint256 agreementsLength)
    {
        return agreement.getAgreementsLength();
    }

    /* function getTimeResolvePeriod()
        external
        view
        override
        returns (uint256 resolvePeriod)
    {
        return uint256(timeResolvePeriod);
    } */
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IRouter {
    function registerLP(
        address paymentToken,
        uint256 period,
        uint256[] calldata _coreTypes,
        uint256 reinforcement,
        uint256 marginality,
        address LPOwner,
        bool isActive
    ) external;

    function changeLPPeriod(uint256 lpID, uint256 newPeriod) external;

    function registerFeed(
        address feedOwner,
        string calldata feedDescription,
        uint256[] calldata feedCoreTypes,
        bool isActive,
        bool penaltyAllowed
    ) external;

    function addLiquidity(uint256 lpID, uint256 _amount) external;

    function withdrawLiquidity(uint256 lpID, uint256 valueLP) external;

    function liquidityRequest(uint256 lpID, uint256 valueLP) external;

    function createCondition(
        uint256[] calldata agreements,
        uint256 oracleConditionID,
        uint256 coreType,
        uint256[] calldata rates,
        uint256 timestamp,
        string memory ipfsHash
    ) external;

    function resolveCondition(
        uint256[] calldata agreements,
        uint256 conditionID,
        uint128 outcomeWin
    ) external;

    function bet(
        uint256 lpID,
        uint256 conditionID,
        uint256 amount,
        uint256 outcomeID,
        uint256 deadline,
        uint256 minRate,
        bool mintNFT
    ) external;

    function withdrawPrize(uint256 lpID, uint256 tokenId) external;

    function claimAzuroBetToken(uint256 tokenId) external;

    function addCoreType(address core) external;

    function setAgreement(address _agreement) external;

    function setLPCoreType(
        uint256 lpID,
        uint256 coreType,
        bool isActive
    ) external;

    function FEEDcreateAgreement(
        uint32 timePeriod,
        uint32 coreType,
        uint32 jobTaskCount,
        uint128 jobFund,
        uint128 jobPenalty,
        uint128 taskResultPenalty,
        string memory agreementName
    ) external;

    function FEEDcancelAgreement(uint256 agreementID) external;

    function LPAcceptAgreement(uint256 lpID, uint256 agreementID) external;

    function LPCloseAgreement(uint256 lpID, uint256 agreementID) external;

    function getAzuroToken() external returns (address);

    function getLPRegistry(uint256 lpID)
        external
        view
        returns (
            address pool,
            address paymentToken,
            uint256 period,
            bool isActive
        );

    function getLPpaymentToken(address lp)
        external
        view
        returns (address paymentToken);

    function getLPperiod(address lp) external view returns (uint256 period);

    function getLPowner(address lp) external view returns (address owner);

    function getLPIDowner(uint256 lpID) external view returns (address owner);

    function getCorebyType(uint256 typeId) external view returns (address core);

    function getCoreTypebyCore(address core)
        external
        view
        returns (uint256 typeId);

    function getLiquidityRequests(uint256 lpID, address wallet)
        external
        view
        returns (uint256 total, uint256 personal);

    function getLPReserve(uint256 lpID) external view returns (uint256 reserve);

    function getLPSupply(uint256 lpID)
        external
        view
        returns (uint256 totalSupply);

    function getLPcount() external view returns (uint256 LPcount);

    function getFeedSecurity() external view returns (uint256 FEEDSecurity);

    function getProtocolToken() external view returns (address _protocolToken);

    function getAgreementsLength()
        external
        view
        returns (uint256 agreementsLength);

    function disputeStake(
        uint256 lpID,
        uint256 conditionID,
        uint256 disputeStakeAmount,
        uint128 disputeOutcomeID
    ) external;

    /* function getTimeResolvePeriod()
        external
        view
        returns (uint256 timeResolvePeriod); */
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ILP {
    function initialize(
        address _router,
        uint256 _reinforcement,
        uint256 _marginality,
        address _owner
    ) external;

    function addLiquidity(address sender, uint256 _amount) external;

    function liquidityRequest(address sender, uint256 valueLP) external;

    function withdrawLiquidity(address sender, uint256 _amount) external;

    function createConditionTest(
        uint256 oracleConditionID,
        uint256 _coreType,
        uint256[] calldata rates,
        uint256 timestamp,
        string memory ipfsHash,
        uint256 jobResultPenalty
    ) external;

    function resolveConditionTest(
        uint256 conditionID_,
        uint128 outcomeWin_,
        uint64 _timeResolvePeriod
    ) external;

    function startDispute(
        address disputeWallet,
        uint256 conditionID_,
        uint256 disputeStakeAmount,
        uint128 disputeOutcomeID,
        uint64 diputeLatency
    ) external;

    function withdrawPrize(address sender, uint256 betID) external;

    function bet(
        address sender,
        uint256 conditionID,
        uint256 amount,
        uint256 outcomeID,
        uint256 deadline,
        uint256 minRate,
        uint256 tokenId
    ) external returns (uint256);

    function changePeriod(address owner) external;

    function getLiquidityRequests(address wallet)
        external
        view
        returns (uint256 total, uint256 personal);

    function setCoreType(uint64 coreType, address core) external;

    function getReserve() external view returns (uint256);

    function getSupply() external view returns (uint256);

    function PERIOD() external view returns (uint256);

    function getJobResultPenalty(uint256 oracleConditionID)
        external
        view
        returns (uint256 _jobResultPenalty);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IFeeder {
    function initialize(
        address _router,
        address _owner,
        string calldata _feedDescription,
        bool _penaltyAllowed
    ) external;

    function createCondition(
        uint256[] calldata agreements,
        uint256 oracleConditionID,
        uint256 coreType,
        uint256[] calldata rates,
        uint256 timestamp,
        string memory ipfsHash
    ) external;

    function resolveCondition(
        uint256[] calldata agreements,
        uint256 conditionID,
        uint128 outcomeWin
    ) external;

    function punish(uint256 punishmentValue) external;

    function createAgreement(
        uint32 timePeriod,
        uint32 coreType,
        uint32 jobTaskCount,
        uint128 jobFund,
        uint128 jobPenalty,
        uint128 taskResultPenalty,
        string memory agreementName
    ) external;

    function cancelAgreement(uint256 agreementID) external;

    function deposite(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getOwner() external view returns (address ownerWallet);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IAzuroBet {
    function setRouter(address _router) external;

    function setLP(address lpAddress_) external;

    function burn(uint256 id) external;

    function mint(address account, uint256 id) external;

    function ownerOftoken(uint256 tokenId) external view returns (address);

    function inclastBetNumber() external;

    function getlastBetNumber() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IAgreement {
    /**
     * @dev LP <-> FEED agreement job details
     * @param timeStop - stop data, =0 for inactive agreement
     * @param timePeriod - latency
     * @param coreType - core type
     * @param jobConditionResolves - number of condition resolves rest in job
     * @param jobFund - amount of full job payment, supplied by LP owner
     * @param jobSecurity - job security, supplied by FEED provider, must be > 0 for active job proposal
     * @param taskResultPenalty - whole penalty = jobs * ResultPenalty
     */

    struct agreement {
        uint256 timeStop;
        uint32 timePeriod;
        uint32 coreType;
        uint32 jobs;
        uint32 jobConditionResolves;
        uint128 jobFund;
        uint128 jobPenalty;
        uint128 taskResultPenalty;
    }

    function FEEDcreateAgreement(
        uint32 timePeriod,
        uint32 coreType,
        uint32 jobTaskCount,
        uint128 jobFund,
        uint128 jobPenalty,
        uint128 taskResultPenalty,
        address feed
    ) external returns (uint256 agreementId);

    function FEEDcancelAgreement(uint256 agreementID, address feed)
        external
        returns (uint256 returnAmount);

    function LPAcceptAgreement(address lp, uint256 agreementID)
        external
        returns (uint256 jobFund);

    function LPCloseAgreement(address lp, uint256 agreementID)
        external
        returns (
            uint256 penaltyAmount,
            uint256 returntoFeed,
            address feed
        );

    function resolveCondition(uint256 inAgreement)
        external
        returns (uint128 _profit);

    function getAgreementsLength()
        external
        view
        returns (uint256 agreementsLength);

    function getAgreementData(uint256 agreementID)
        external
        view
        returns (agreement memory);

    function getAgreementtoLP(uint256 agreementID)
        external
        view
        returns (address lp);

    function getAgreementtoFEED(uint256 agreementID)
        external
        view
        returns (address feed);

    function isAgreementAccepted(uint256 agreementID)
        external
        view
        returns (bool accepted);

    function getJobResultPenalty(uint256 agreementID)
        external
        view
        returns (uint256 jobResultPenalty);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract ProxyLP is BeaconProxy {
    constructor(address beacon, bytes memory data)
        payable
        BeaconProxy(beacon, data)
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract ProxyFEED is BeaconProxy {
    constructor(address beacon, bytes memory data)
        payable
        BeaconProxy(beacon, data)
    {}
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
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