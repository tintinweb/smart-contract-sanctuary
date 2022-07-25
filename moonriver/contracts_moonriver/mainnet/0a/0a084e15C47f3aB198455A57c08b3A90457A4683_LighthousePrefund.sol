// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LighthouseTier.sol";
import "./LighthouseRegistration.sol";
import "./LighthouseProject.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice The second phase of the Project Fund raising is to prefund. 
 */
contract LighthousePrefund is Ownable {
    LighthouseTier private lighthouseTier;
    LighthouseRegistration private lighthouseRegistration;
    LighthouseProject private lighthouseProject;

    uint256 public chainID;

    /// @notice The investor prefunds in the project
    /// @dev Project -> Investor -> funded
    mapping(uint256 => mapping(address => bool)) public investments;
    mapping(uint256 => mapping(address => int8)) public tiers;

    event Prefund(uint256 indexed projectId, address indexed investor, int8 tier, uint256 time);

    address payable public fundCollector;

    constructor(address _tier, address _submission, address _project, address payable _fundCollector, uint256 _chainID) {
        require(_tier != address(0) && _submission != address(0) && _project != address(0) && _fundCollector != address(0), "Lighthouse: ZERO_ADDRESS");
        require(_tier != _submission, "Lighthouse: SAME_ADDRESS");
        require(_tier != _project, "Lighthouse: SAME_ADDRESS");
        require(_chainID > 0, "Lighthouse: ZERO_VALUE");
        require(fundCollector != _fundCollector, "Lighthouse: USED_OWNER");

        lighthouseTier = LighthouseTier(_tier);
        lighthouseRegistration = LighthouseRegistration(_submission);
        lighthouseProject = LighthouseProject(_project);
        fundCollector = _fundCollector;
        chainID = _chainID;
    }

    function setFundCollector(address payable _fundCollector) external onlyOwner {
        require(_fundCollector != address(0), "Lighthouse: ZERO_ADDRESS");
        require(_fundCollector != owner(), "Lighthouse: USED_OWNER");

        fundCollector = _fundCollector;
    }

    function setLighthouseTier(address newTier) external onlyOwner {
        lighthouseTier = LighthouseTier(newTier);
    }

    /// @dev v, r, s are used to ensure on server side that user passed KYC
    function prefund(uint256 projectId, int8 certainTier, uint8 v, bytes32 r, bytes32 s) external payable {
        require(lighthouseProject.prefundInitialized(projectId), "Lighthouse: PREFUND_NOT_INITIALIZED");
        require(!prefunded(projectId, msg.sender), "Lighthouse: ALREADY_PREFUNDED");
        require(certainTier > 0 && certainTier < 4, "Lighthouse: INVALID_CERTAIN_TIER");

        {   // Avoid stack too deep.
        uint256 startTime;
        uint256 endTime;
        
        (startTime, endTime) = lighthouseProject.prefundTimeInfo(projectId);

        require(block.timestamp >= startTime,   "Lighthouse: NOT_STARTED_YET");
        require(block.timestamp <= endTime,     "Lighthouse: FINISHED");
        }
        require(lighthouseRegistration.registered(projectId, msg.sender), "Lighthouse: NOT_REGISTERED");

        int8 tier = lighthouseTier.getTierLevel(msg.sender);
        require(tier > 0 && tier < 4, "Lighthouse: NO_TIER");
        require(certainTier <= tier, "Lighthouse: INVALID_CERTAIN_TIER");
        tier = certainTier;

        uint256 collectedAmount;        // Tier investment amount
        uint256 pool;                   // Tier investment cap
        (collectedAmount, pool) = lighthouseProject.prefundPoolInfo(projectId, tier);

        require(collectedAmount < pool, "Lighthouse: TIER_CAP");
 
        {   // avoid stack too deep
        // investor, project verification
	    bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
	    bytes32 message         = keccak256(abi.encodePacked(msg.sender, address(this), chainID, projectId, uint8(certainTier)));
	    bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
	    address recover         = ecrecover(hash, v, r, s);

	    require(recover == lighthouseProject.getKYCVerifier(), "Lighthouse: SIG");
        }


        uint256 investAmount;
        address investToken;
        (investAmount, investToken) = lighthouseProject.prefundInvestAmount(projectId, tier);

        if (investToken == address(0)) {
            require(msg.value == investAmount, "Lighthouse: NOT_ENOUGH_NATIVE");
            fundCollector.transfer(msg.value);
        } else {
            IERC20 token = IERC20(investToken);
            require(token.transferFrom(msg.sender, fundCollector, investAmount), "Lighthouse: FAILED_TO_TRANSER");
        }


        lighthouseTier.use(msg.sender, uint8(lighthouseTier.getTierLevel(msg.sender)));

        lighthouseProject.collectPrefundInvestment(projectId, tier);
        investments[projectId][msg.sender] = true;
        tiers[projectId][msg.sender] = tier;

        emit Prefund(projectId, msg.sender, tier, block.timestamp);
    }

    /// @notice checks whether the user had prefunded or not.
    /// @param id of the project
    /// @param investor who prefuned
    function prefunded(uint256 id, address investor) public view returns(bool) {
        return investments[id][investor];
    }

    function getPrefundTier(uint256 id, address investor) external view returns (int8) {
        return tiers[id][investor];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./crowns/CrownsInterface.sol";

/**
 *  @title Lighthouse Tier
 *  @author Medet Ahmetson ([email protected])
 *  @notice This contract tracks the tier of every user, tier allocation by each project.
 */
contract LighthouseTier is Ownable {
    using Counters for Counters.Counter;

    CrownsInterface private immutable crowns;

    uint256 public chainID;

    struct Tier {
        uint8 level;
        bool usable;
        uint256 nonce;
    }

    /// @notice Investor tier level
    /// @dev Investor address => TIER Level
    mapping(address => Tier) public tiers;

    /// @notice Amount of Crowns (CWS) that user would spend to claim the fee
    mapping(uint8 => uint256) public fees;

    /// @notice The Lighthouse contracts that can use the user Tier.
    /// @dev Smartcontract address => can use or not
    mapping(address => bool) public editors;

    /// @notice An account that tracks and prooves the Tier level to claim
    /// It tracks the requirements on the server side.
    /// @dev Used with v, r, s
    address public claimVerifier;

    event Fees(uint256 feeZero, uint256 feeOne, uint256 feeTwo, uint256 feeThree);
    event TierEditer(address indexed user, bool allowed);
    event Claim(address indexed investor, uint8 indexed tier);
    event Use(address indexed investor, uint8 indexed tier);

    constructor(address _crowns, address _claimVerifier, uint256[4] memory _fees, uint256 _chainID) {
        require(_crowns != address(0),          "LighthouseTier: ZERO_ADDRESS");
        require(_claimVerifier != address(0),   "LighthouseTier: ZERO_ADDRESS");
        require(_chainID > 0,                   "LighthouseTier: ZERO_VALUE");

        // Fee for claiming Tier
        setFees(_fees);

        crowns          = CrownsInterface(_crowns);
        claimVerifier   = _claimVerifier;
        chainID         = _chainID;
    }

    ////////////////////////////////////////////////////////////////////////////
    //
    // Management functions: change verifier, fee, editors.
    //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Fee for claiming Tier
    function setFees(uint256[4] memory _fees) public onlyOwner {
        require(_fees[0] > 0, "LighthouseTier: ZERO_FEE_0");
        require(_fees[1] > 0, "LighthouseTier: ZERO_FEE_1");
        require(_fees[2] > 0, "LighthouseTier: ZERO_FEE_2");
        require(_fees[3] > 0, "LighthouseTier: ZERO_FEE_3");

        fees[0] = _fees[0];
        fees[1] = _fees[1];
        fees[2] = _fees[2];
        fees[3] = _fees[3];

        emit Fees(_fees[0], _fees[1], _fees[2], _fees[3]);
    }

    /// @notice Who verifies the tier from the server side.
    function setClaimVerifier(address _claimVerifier) external onlyOwner {
        require(_claimVerifier != address(0),       "LighthouseTier: ZERO_ADDRESS");
        require(claimVerifier != _claimVerifier,    "LighthouseTier: SAME_ADDRESS");

        claimVerifier = _claimVerifier;
    }

    /// @notice Who can update tier of user? It's another smartcontract from Seapad.
    function addEditor(address _user) external onlyOwner {
        require(_user != address(0),                "LighthouseTier: ZERO_ADDRESS");
        require(!editors[_user],                    "LighthouseTier: ALREADY_ADDED");

        editors[_user] = true;

        TierEditer(_user, true);
    }

    /// @notice Remove the tier user.
    function deleteEditor(address _user) external onlyOwner {
        require(_user != address(0),                "LighthouseTier: ZERO_ADDRESS");
        require(editors[_user],                     "LighthouseTier: NO_USER");

        editors[_user] = false;

        TierEditer(_user, false);
    }

    ////////////////////////////////////////////////////////////////////////////
    //
    // User functions.
    //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Investor claims his Tier.
    /// This function intended to be called from the website directly
    function claim(uint8 level, uint8 v, bytes32 r, bytes32 s) external {
        require(level >= 0 && level < 4,        "LighthouseTier: INVALID_PARAMETER");
        Tier storage tier = tiers[msg.sender];

        // You can't Skip tiers.        
        if (level != 0) {
            require(tier.level + 1 == level,                "LighthouseTier: INVALID_LEVEL");
        } else {
            require(tier.usable == false,                   "LighhouseTier: 0_CLAIMED");
        }

        // investor, level verification with claim verifier
	    bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
	    bytes32 message         = keccak256(abi.encodePacked(msg.sender, tier.nonce, level, chainID, address(this)));
	    bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
	    address recover         = ecrecover(hash, v, r, s);
	    require(recover == claimVerifier,                   "LighthouseTier: SIG");

        tier.level = level;
        tier.usable = true;
        tier.nonce = tier.nonce + 1;      // Prevent "double-spend".

        // Charging fee
        require(crowns.spendFrom(msg.sender, fees[level]),  "LighthouseTier: CWS_UNSPEND");

        emit Claim(msg.sender, level);
    }

    ////////////////////////////////////////////////////////////////////////////
    //
    // Editor functions
    //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Other Smartcontracts of Lighthouse use the Tier of user.
    /// It's happening, when user won the lottery.
    function use(address investor, uint8 level) external {
        require(level >= 0 && level < 4,    "LighthouseTier: INVALID_PARAMETER");
        require(investor != address(0),     "LighthouseTier: ZERO_ADDRESS");
        require(editors[msg.sender],        "LighthouseTier: FORBIDDEN");

        Tier storage tier     = tiers[investor];

        require(tier.level == level,        "LighthouseTier: INVALID_LEVEL");
        require(tier.usable,                "LighthouseTier: ALREADY_USED");

        // Reset Tier to 0.
        tier.usable            = false;
        tier.level             = 0;

        emit Use(investor, level);
    }

    ////////////////////////////////////////////////////////////////////////////
    //
    // Public functions
    //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Return Tier Level of the investor.
    function getTierLevel(address investor) external view returns(int8) {
        if (tiers[investor].usable) {
            return int8(tiers[investor].level);
        }
        return -1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./LighthouseProject.sol";

/**
 * @notice This contract initiates the first stage of the Project funding.
 * Users are registertion for the lottery within the given time period for the project.
 * Registration for lottery.
 * 
 * @dev In order to start a new project funding, the first thing to do is add project here.
 */
contract LighthouseRegistration is Ownable {
    LighthouseProject private lighthouseProject;

    uint public chainID;

    /// @notice Amount of participants
    mapping(uint256 => uint256) public participantsAmount;
    mapping(uint256 => mapping(address => bool)) public registrations;

    event Register(uint256 indexed projectId, address indexed participant, uint256 indexed registrationId, uint256 registrationTime);

    constructor(address _lighthouseProject, uint _chainID) {
        lighthouseProject = LighthouseProject(_lighthouseProject);
        chainID = _chainID;
    }

    ////////////////////////////////////////////////////////////////////////////
    //
    // Investor functions: register for the prefund in the project.
    //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice User registers to join the fund.
    /// @param id is the project id to join
    function register(uint256 id, int8 tierLevel, uint8 v, bytes32 r, bytes32 s) external {
        require(lighthouseProject.registrationInitialized(id), "Lighthouse: REGISTRATION_NOT_INITIALIZED");

        uint256 startTime;
        uint256 endTime;
        
        (startTime, endTime) = lighthouseProject.registrationInfo(id);

        require(block.timestamp >= startTime, "Lighthouse: NOT_STARTED_YET");
        require(block.timestamp <= endTime, "Lighthouse: FINISHED");
        require(!registered(id, msg.sender), "Lighthouse: ALREADY_REGISTERED");

        {   // avoid stack too deep
        // investor, project verification
	    bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
	    bytes32 message         = keccak256(abi.encodePacked(msg.sender, address(this), chainID, id, uint8(tierLevel)));
	    bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
	    address recover         = ecrecover(hash, v, r, s);

	    require(recover == lighthouseProject.getKYCVerifier(), "Lighthouse: SIG");
        }
        
        participantsAmount[id] = participantsAmount[id] + 1;

        registrations[id][msg.sender] = true;

        emit Register(id, msg.sender, participantsAmount[id], block.timestamp);
    }

    ////////////////////////////////////////////////////////////////////////////
    //
    // Public functions
    //
    ////////////////////////////////////////////////////////////////////////////

    function registered(uint256 id, address investor) public view returns(bool) {
        bool r = registrations[id][investor];
        return r;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @notice This contract keeps project information.
 * @dev In order to start a new project funding, the first thing to do is add project here.
 */
contract LighthouseProject is Ownable {
    using Counters for Counters.Counter;

    uint256 private constant SCALER = 10 ** 18;

    Counters.Counter private projectId;

    /// @notice An account that tracks user's KYC pass
    /// @dev Used with v, r, s
    address public kycVerifier;

    /// @dev Smartcontract address => can use or not
    mapping(address => bool) public editors;

    struct Registration {
        uint256 startTime;
        uint256 endTime;
    }

    struct Prefund {
        uint256 startTime;
        uint256 endTime;
        uint256[3] investAmounts;       // Amount of tokens that user can invest, depending on his tier
        uint256[3] collectedAmounts;    // Amount of tokens that users invested so far.
        uint256[3] pools;               // Amount of tokens that could be invested in the pool.
        address token;                  // Token to accept from investor

        uint256 scaledAllocation;       // prefund PCC allocation
        uint256 scaledCompensation;     // prefund Crowns compensation
    }

    struct Auction {
        uint256 startTime;
        uint256 endTime;
        uint256 spent;                  // Total Spent Crowns for this project

        uint256 scaledAllocation;       // auction PCC allocation
        uint256 scaledCompensation;     // auction Crowns compensation

        bool transferredPrefund;        // Prefund allocation transferred to aution pool
    }

    mapping(uint256 => Registration) public registrations;
    mapping(uint256 => Prefund) public prefunds;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => bool) public mintable;

    // Lighthouse Investment NFT for each project.
    mapping(uint256 => address) public nfts;
    mapping(address => uint256) public usedNfts;

    /// PCC of each project.
    mapping(uint256 => address) public pccs;
    mapping(address => uint256) public usedPccs;

    event SetKYCVerifier(address indexed verifier);
    event ProjectEditor(address indexed user, bool allowed);
    event InitRegistration(uint256 indexed id, uint256 startTime, uint256 endTime);
    event InitPrefund(uint256 indexed id, address indexed token, uint256 startTime, uint256 endTime, uint256[3] pools, uint256[3] investAmounts);
    event InitAuction(uint256 indexed id, uint256 startTime, uint256 endTime);
    event InitAllocationCompensation(uint256 indexed id, address indexed nftAddress, uint256 prefundAllocation, uint256 prefundCompensation, uint256 auctionAllocation, uint256 auctionCompensation);
    event TransferPrefund(uint256 indexed id, uint256 scaledPrefundAmount, uint256 scaledCompensationAmount);
    event SetPCC(uint256 indexed id, address indexed pccAddress);
    event InitMint(uint256 indexed id);

    constructor(address verifier) {
        setKYCVerifier(verifier);
        projectId.increment(); 	// starts at value 1
    }

    ////////////////////////////////////////////////////////////////////////////
    //
    // Manager: adds project parameters, changes the permission for other smartcontracts
    //
    ////////////////////////////////////////////////////////////////////////////

    function setKYCVerifier(address verifier) public onlyOwner {
        require(verifier != address(0), "Lighthouse: ZERO_ADDRESS");
        require(kycVerifier != verifier, "Lighthouse: SAME_ADDRESS");

        kycVerifier = verifier;

        emit SetKYCVerifier(verifier);
    }

    /// @notice Who can update project? It's another smartcontract from Seapad.
    function addEditor(address _user) external onlyOwner {
        require(_user != address(0),                "Lighthouse: ZERO_ADDRESS");
        require(!editors[_user],                    "Lighthouse: ALREADY_ADDED");

        editors[_user] = true;

        emit ProjectEditor(_user, true);
    }

    /// @notice Remove the project updater.
    function deleteEditor(address _user) external onlyOwner {
        require(_user != address(0),                "Lighthouse: ZERO_ADDRESS");
        require(editors[_user],                     "Lighthouse: NO_USER");

        editors[_user] = false;

        emit ProjectEditor(_user, false);
    }

    /// @notice Opens a registration entrance for a new project
    /// @param startTime of the registration entrance
    /// @param endTime of the registration. This is not th end of the project funding.
    function initRegistration(uint256 startTime, uint256 endTime) external onlyOwner {
        require(block.timestamp < startTime,    "Lighthouse: TIME_PASSED");
        require(endTime > startTime,            "Lighthouse: INCORRECT_END_TIME");

        uint256 id                      = projectId.current();
        registrations[id].startTime     = startTime;
        registrations[id].endTime       = endTime;

        projectId.increment();

        emit InitRegistration(id, startTime, endTime);
    }

    /// @notice Add the second phase of the project
    function initPrefund(uint256 id, uint256 startTime, uint256 endTime, uint256[3] calldata investAmounts, uint256[3] calldata pools, address _token) external onlyOwner {
        require(validProjectId(id), "Lighthouse: INVALID_PROJECT_ID");
        require(block.timestamp < startTime, "Lighthouse: INVALID_START_TIME");
        require(startTime < endTime, "Lighthouse: INVALID_END_TIME");
        require(pools[0] > 0 && pools[1] > 0 && pools[2] > 0, "Lighthouse: ZERO_POOL_CAP");
        require(investAmounts[0] > 0 && investAmounts[1] > 0 && investAmounts[2] > 0, "Lighthouse: ZERO_FIXED_PRICE");
        Prefund storage prefund = prefunds[id];
        require(prefund.startTime == 0, "Lighthouse: ALREADY_ADDED");

        uint256 regEndTime = registrations[id].endTime;
        require(regEndTime > 0, "Lighthouse: NO_REGISTRATION_YET");
        require(startTime > regEndTime, "Lighthouse: NO_REGISTRATION_END_YET");

        prefund.startTime   = startTime;
        prefund.endTime     = endTime;
        prefund.investAmounts = investAmounts;
        prefund.pools       = pools;
        prefund.token       = _token;

        emit InitPrefund(id, _token, startTime, endTime, pools, investAmounts);
    }

    /// @notice Add the last stage period for the project
    function initAuction(uint256 id, uint256 startTime, uint256 endTime) external onlyOwner {
        require(validProjectId(id), "Lighthouse: INVALID_PROJECT_ID");
        require(block.timestamp < startTime, "Lighthouse: INVALID_START_TIME");
        require(startTime < endTime, "Lighthouse: INVALID_END_TIME");
        Auction storage auction = auctions[id];
        require(auction.startTime == 0, "Lighthouse: ALREADY_ADDED");

        // prefundEndTime is already used as the name of function 
        uint256 prevEndTime = prefunds[id].endTime;
        require(prevEndTime > 0, "Lighthouse: NO_PREFUND_YET");
        require(startTime > prevEndTime, "Lighthouse: NO_REGISTRATION_END_YET");
    
        auction.startTime = startTime;
        auction.endTime = endTime;

        emit InitAuction(id, startTime, endTime);
    }

    /// @notice add allocation for prefund, auction.
    /// @dev Called after initAuction.
    /// Separated function for allocation to avoid stack too deep in other functions.
    function initAllocationCompensation(uint256 id, uint256 prefundAllocation, uint256 prefundCompensation, uint256 auctionAllocation, uint256 auctionCompensation, address nftAddress) external onlyOwner {
        require(auctionInitialized(id), "Lighthouse: NO_AUCTION");
        require(!allocationCompensationInitialized(id), "Lighthouse: ALREADY_INITIATED");
        require(prefundAllocation > 0 && prefundCompensation > 0 && auctionAllocation > 0 && auctionCompensation > 0, "Lighthouse: ZERO_PARAMETER");
        require(nftAddress != address(0), "Lighthouse: ZERO_ADDRESS");
        require(usedNfts[nftAddress] == 0, "Lighthouse: NFT_USED");

        Prefund storage prefund     = prefunds[id];
        Auction storage auction     = auctions[id];

        prefund.scaledAllocation    = prefundAllocation * SCALER;
        prefund.scaledCompensation  = prefundCompensation * SCALER;

        auction.scaledAllocation    = auctionAllocation * SCALER;
        auction.scaledCompensation  = auctionCompensation * SCALER;

        nfts[id]                    = nftAddress; 
        usedNfts[nftAddress]        = id;                   

        emit InitAllocationCompensation(id, nftAddress, prefundAllocation, prefundCompensation, auctionAllocation, auctionCompensation);
    }

    function setPcc(uint256 id, address pccAddress) external onlyOwner {
        require(validProjectId(id), "Lighthouse: INVALID_PROJECT_ID");
        require(pccAddress != address(0), "Lighthouse: ZERO_ADDRESS");
        require(usedPccs[pccAddress] == 0, "Lighthouse: PCC_USED");

        pccs[id]                    = pccAddress;
        usedPccs[pccAddress]        = id;

        emit SetPCC(id, pccAddress);
    }

    function initMinting(uint256 id) external onlyOwner {
        require(validProjectId(id), "Lighthouse: INVALID_PROJECT_ID");
        require(!mintable[id], "Lighthouse: ALREADY_MINTED");

        mintable[id] = true;

        emit InitMint(id);
    }

    /// @dev Should be called from other smartcontracts that are doing security check-ins.
    function collectPrefundInvestment(uint256 id, int8 tier) external {
        require(editors[msg.sender], "Lighthouse: FORBIDDEN");
        Prefund storage x = prefunds[id];

        // index
        uint8 i = uint8(tier) - 1;

        x.collectedAmounts[i] = x.collectedAmounts[i] + x.investAmounts[i];
    }

    /// @dev Should be called from other smartcontracts that are doing security check-ins.
    function collectAuctionAmount(uint256 id, uint256 amount) external {
        require(editors[msg.sender], "Lighthouse: FORBIDDEN");
        Auction storage x = auctions[id];

        x.spent = x.spent + amount;
    }

    // auto transfer prefunded and track it in the Prefund
    function transferPrefund(uint256 id) external onlyOwner {
        if (auctions[id].transferredPrefund) {
            return;
        }
        require(validProjectId(id), "Lighthouse: INVALID_PROJECT_ID");

        require(prefunds[id].endTime < block.timestamp, "Lighthouse: PREFUND_PHASE");

        uint256 cap;
        uint256 amount;
        (cap, amount) = prefundTotalPool(id);
        
        if (amount < cap) {
            // We apply SCALER multiplayer, if the cap is less than 100
            // It could happen if investing goes in NATIVE token.
            uint256 scaledPercent = (cap - amount) * SCALER / (cap * SCALER / 100);

            // allocation = 10 * SCALER / 100 * SCALED percent;
            uint256 scaledTransferAmount = (prefunds[id].scaledAllocation * scaledPercent / 100) / SCALER;

            auctions[id].scaledAllocation = auctions[id].scaledAllocation + scaledTransferAmount;
            prefunds[id].scaledAllocation = prefunds[id].scaledAllocation - scaledTransferAmount;

            uint256 scaledCompensationAmount = (prefunds[id].scaledCompensation * scaledPercent / 100) / SCALER;

            auctions[id].scaledCompensation = auctions[id].scaledCompensation + scaledCompensationAmount;
            prefunds[id].scaledCompensation = prefunds[id].scaledCompensation - scaledCompensationAmount;

            emit TransferPrefund(id, scaledTransferAmount, scaledCompensationAmount);
        }

        auctions[id].transferredPrefund = true;
    }    

    ////////////////////////////////////////////////////////////////////////////
    //
    // Public functions
    //
    ////////////////////////////////////////////////////////////////////////////
    
    function totalProjects() external view returns(uint256) {
        return projectId.current() - 1;
    }

    function validProjectId(uint256 id) public view returns(bool) {
        return (id > 0 && id < projectId.current());
    }

    function registrationInitialized(uint256 id) public view returns(bool) {
        if (!validProjectId(id)) {
            return false;
        }

        Registration storage x = registrations[id];
        return (x.startTime > 0);
    }

    function prefundInitialized(uint256 id) public view returns(bool) {
        if (!validProjectId(id)) {
            return false;
        }

        Prefund storage x = prefunds[id];
        return (x.startTime > 0);
    }

    function auctionInitialized(uint256 id) public view returns(bool) {
        if (!validProjectId(id)) {
            return false;
        }

        Auction storage x = auctions[id];
        return (x.startTime > 0);
    }

    function mintInitialized(uint256 id) public view returns(bool) {
        return mintable[id];
    }

    function allocationCompensationInitialized(uint256 id) public view returns(bool) {
        if (!validProjectId(id)) {
            return false;
        }

        Prefund storage x = prefunds[id];
        Auction storage y = auctions[id];
        return (x.scaledAllocation > 0 && y.scaledAllocation > 0);
    }

    /// @notice Returns Information about Registration: start time, end time
    function registrationInfo(uint256 id) external view returns(uint256, uint256) {
        Registration storage x = registrations[id];
        return (x.startTime, x.endTime);
    }

    function registrationEndTime(uint256 id) external view returns(uint256) {
        return registrations[id].endTime;
    }

    /// @notice Returns Information about Prefund Time: start time, end time
    function prefundTimeInfo(uint256 id) external view returns(uint256, uint256) {
        Prefund storage x = prefunds[id];
        return (x.startTime, x.endTime);
    }

    /// @notice Returns Information about Auction Time: start time, end time
    function auctionTimeInfo(uint256 id) external view returns(uint256, uint256) {
        Auction storage x = auctions[id];
        return (x.startTime, x.endTime);
    }

    /// @notice Returns Information about Prefund Pool: invested amount, investment cap
    function prefundPoolInfo(uint256 id, int8 tier) external view returns(uint256, uint256) {
        Prefund storage x = prefunds[id];

        // index
        uint8 i = uint8(tier) - 1;

        return (x.collectedAmounts[i], x.pools[i]);
    }

    /// @notice Returns Information about Prefund investment info: amount for tier, token to invest
    function prefundInvestAmount(uint256 id, int8 tier) external view returns(uint256, address) {
        Prefund storage x = prefunds[id];

        // index
        uint8 i = uint8(tier) - 1;

        return (x.investAmounts[i], x.token);
    }

    function prefundEndTime(uint256 id) external view returns(uint256) {
        return prefunds[id].endTime;
    }

    /// @notice returns total pool, and invested pool
    /// @dev the first returning parameter is total pool. The second returning parameter is invested amount so far.
    function prefundTotalPool(uint256 id) public view returns(uint256, uint256) {
        Prefund storage x = prefunds[id];

        uint256 totalPool = x.pools[0] + x.pools[1] + x.pools[2];
        uint256 totalInvested = x.collectedAmounts[0] + x.collectedAmounts[1] + x.collectedAmounts[2];

        return (totalPool, totalInvested);
    }

    /// @dev Prefund PCC distributed per Invested token.
    function prefundScaledUnit(uint256 id) external view returns(uint256, uint256) {
        Prefund storage x = prefunds[id];
        uint256 totalInvested = x.collectedAmounts[0] + x.collectedAmounts[1] + x.collectedAmounts[2];
    
        return (x.scaledAllocation / totalInvested, x.scaledCompensation / totalInvested);
    }

    function auctionEndTime(uint256 id) external view returns(uint256) {
        return auctions[id].endTime;
    }

    /// @notice returns total auction
    function auctionTotalPool(uint256 id) external view returns(uint256) {
        return auctions[id].spent;
    }

    function transferredPrefund(uint256 id) external view returns(bool) {
        return auctions[id].transferredPrefund;
    }

    /// @dev Prefund PCC distributed per Invested token.
    function auctionScaledUnit(uint256 id) external view returns(uint256, uint256) {
        Auction storage x = auctions[id];
        return (x.scaledAllocation / x.spent, x.scaledCompensation / x.spent);
    }

    function nft(uint256 id) external view returns(address) {
        return nfts[id];
    }

    function pcc(uint256 id) external view returns(address) {
        return pccs[id];
    }

    function getKYCVerifier() external view returns(address) {
        return kycVerifier;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
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

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// contracts/Crowns.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface CrownsInterface {
    function addBridge(address _bridge) external returns(bool);
    function removeBridge(address _bridge) external returns(bool);

    function setLimitSupply(uint256 _newLimit) external returns(bool);

    function mint(address to, uint256 amount) external  ;

    function burn(uint256 _amount) external  ;

    function burnFrom(address account, uint256 amount) external  ;
    function toggleBridgeAllowance() external  ;

    function payWaveOwing (address account) external view returns(uint256);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function spend(uint256 amount) external returns(bool);

    function spendFrom(address sender, uint256 amount) external returns(bool);

    function getLastPayWave(address account) external view returns (uint256);

    function payWave() external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}