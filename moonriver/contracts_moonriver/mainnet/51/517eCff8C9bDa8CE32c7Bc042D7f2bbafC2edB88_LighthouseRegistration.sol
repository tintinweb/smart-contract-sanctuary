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