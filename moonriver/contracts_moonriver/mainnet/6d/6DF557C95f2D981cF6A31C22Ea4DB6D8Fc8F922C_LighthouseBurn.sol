// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LighthouseAuction.sol";
import "./LighthousePrefund.sol";
import "./LighthouseNft.sol";
import "./LighthouseProject.sol";
import "./crowns/CrownsInterface.sol";

/**
 * @title LighthouseBurn
 * @notice The Lighthouse Manager of tokens by Seascape Network team, investors.
 * It distributes the tokens to the game devs.
 * 
 * This smartcontract gets active for a project, only after its prefunding is finished.
 *
 * This smartcontract determines how much PCC (Player created coin) the investor would get, 
 * and an amount of compensation in case PCC failure.
 * The determination is described as a Lighthouse NFT.
 */
contract LighthouseBurn is Ownable {
    LighthouseAuction   private lighthouseAuction;
    LighthousePrefund   private lighthousePrefund;
    LighthouseProject   private lighthouseProject;
    CrownsInterface     private crowns;

    uint256 private constant SCALER = 10 ** 18;

    /// @notice Some PCC goes to staking contract
    /// @dev PCC address => reserve amount
    mapping(address => uint256) public stakeReserves;
    /// @notice The contract to where the staked tokens will go
    address public staker;

    /// @notice Check whether the user minted nft for the project or not
    mapping(uint256 => mapping(address => uint256)) public mintedNfts;

    event SetStaker(address indexed staker);
    event BurnForPCC(uint256 indexed projectId, address indexed lighthouse, uint256 indexed nftId, address owner, address pcc, uint256 allocation);
    event BurnForCWS(uint256 indexed projectId, address indexed lighthouse, uint256 indexed nftId, address owner, uint256 compensation);

    constructor(address _lighthouseAuction, address _lighthousePrefund, address _project, address _crowns) {
        require(_lighthouseAuction != address(0) && _crowns != address(0) && _lighthousePrefund != address(0) && _project != address(0), "Lighthouse: ZERO_ADDRESS");

        lighthouseAuction   = LighthouseAuction(_lighthouseAuction);
        lighthousePrefund   = LighthousePrefund(_lighthousePrefund);
        lighthouseProject   = LighthouseProject(_project);
        crowns              = CrownsInterface(_crowns);
    }

    function setStaker(address _staker) external onlyOwner {
        require(_staker != address(0), "Lighthouse: ZERO_ADDRESS");

        staker = _staker;

        emit SetStaker(_staker);
    }

    function transferStakeReserve(address pccAddress, uint256 amount) external {
        require(amount > 0, "Lighthouse: ZERO_PARAMETER");
        require(pccAddress != address(0) && staker != address(0), "Lighthouse: NO_STAKER_ADDRESS");
        require(msg.sender == owner() || msg.sender == staker, "Lighthouse: FORBIDDEN");
        require(stakeReserves[pccAddress] > 0, "Lighthouse: INVALID_PCC");
        require(stakeReserves[pccAddress] >= amount, "Lighthouse: NOT_ENOUGH_BALANCE");

        CrownsInterface pcc = CrownsInterface(pccAddress);
        require(pcc.transferFrom(address(this), staker, amount), "Lighthouse: FAILED_TO_TRANSFER");

        stakeReserves[pccAddress] = stakeReserves[pccAddress] - amount;
    }

    function transferMaxReserve(address pccAddress) external {
        require(pccAddress != address(0) && staker != address(0), "Lighthouse: NO_STAKER_ADDRESS");
        require(msg.sender == owner() || msg.sender == staker, "Lighthouse: FORBIDDEN");
        require(stakeReserves[pccAddress] > 0, "Lighthouse: INVALID_PCC");

        CrownsInterface pcc = CrownsInterface(pccAddress);
        require(pcc.transferFrom(address(this), staker, stakeReserves[pccAddress]), "LighthouseBurn: FAILED_TO_TRANSFER");

        stakeReserves[pccAddress] = 0;
    }

    //////////////////////////////////////////////////////////////////////
    //
    // The investor functions
    //
    //////////////////////////////////////////////////////////////////////

    function burnForPcc(uint256 projectId, uint256 nftId) external {
        address pccAddress = lighthouseProject.pcc(projectId);
        require(pccAddress != address(0), "Lighthouse: NO_PCC");
        require(lighthouseProject.allocationCompensationInitialized(projectId), "Lighthouse: ALLOCATION_NOT_INITIALIZED_YET");

        CrownsInterface pcc = CrownsInterface(pccAddress);

        // Nft address after initiation of Allocation should work.
        LighthouseNft nft = LighthouseNft(lighthouseProject.nft(projectId));
        require(nft.ownerOf(nftId) == msg.sender, "Lighthouse: NOT_NFT_OWNER");
        require(nft.mintType(nftId) <= 2, "Lighthouse: FORBIDDEN_MINT_TYPE");

        uint256 allocation = nft.scaledAllocation(nftId) / SCALER;
        uint256 compensation = nft.scaledCompensation(nftId) / SCALER;
        require(allocation > 0, "Lighthouse: NFT_ZERO_ALLOCATION");
        require(compensation > 0, "Lighthouse: NFT_ZERO_COMPENSATION");

        require(pcc.balanceOf(address(this)) >= allocation, "Lighthouse: NOT_ENOUGH_PCC");
        require(crowns.balanceOf(address(this)) >= compensation, "Lighthouse: NOT_ENOUGH_CROWNS");

        nft.burn(nftId);

        require(pcc.transfer(msg.sender, allocation), "Lighthouse: FAILED_TO_TRANSFER");
        require(crowns.spend(compensation), "Lighthouse: FAILED_TO_BURN");

        emit BurnForPCC(projectId, lighthouseProject.nft(projectId), nftId, msg.sender, pccAddress, allocation);
    }

    function burnForCws(uint256 projectId, uint256 nftId) external {
        address pccAddress = lighthouseProject.pcc(projectId);
        require(pccAddress != address(0), "Lighthouse: NO_PCC");
        require(lighthouseProject.allocationCompensationInitialized(projectId), "Lighthouse: ALLOCATION_NOT_INITIALIZED_YET");

        CrownsInterface pcc = CrownsInterface(pccAddress);

        LighthouseNft nft = LighthouseNft(lighthouseProject.nft(projectId));
        require(nft.ownerOf(nftId) == msg.sender, "Lighthouse: NOT_NFT_OWNER");
        require(nft.mintType(nftId) <= 2, "Lighthouse: FORBIDDEN_MINT_TYPE");

        uint256 allocation = nft.scaledAllocation(nftId) / SCALER;
        uint256 compensation = nft.scaledCompensation(nftId) / SCALER;
        require(compensation > 0, "Lighthouse: NFT_ZERO_COMPENSATION");

        require(pcc.balanceOf(address(this)) >= allocation, "Lighthouse: NOT_ENOUGH_PCC");
        require(crowns.balanceOf(address(this)) >= compensation, "Lighthouse: NOT_ENOUGH_CROWNS");

        stakeReserves[pccAddress] = stakeReserves[pccAddress] + allocation;

        nft.burn(nftId);
        require(crowns.transfer(msg.sender, compensation), "Lighthouse: FAILED_TO_TRANSFER");

        emit BurnForCWS(projectId, lighthouseProject.nft(projectId), nftId, msg.sender, compensation);
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
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./crowns/CrownsInterface.sol";
import "./LighthousePrefund.sol";
import "./LighthouseRegistration.sol";
import "./LighthouseProject.sol";
import "./GiftNft.sol";

/**
 *  @title Lighthouse Public Auction
 *  @notice Public Auction - the third phase of fundraising. It's the final stage.
 */
contract LighthouseAuction is Ownable {
    LighthouseRegistration private lighthouseRegistration;
    LighthousePrefund private lighthousePrefund;
    LighthouseProject private lighthouseProject;
    CrownsInterface private crowns;
    GiftNft private nft;

    uint256 public chainID;

    struct AuctionData {
        bool set;                       // whether it was set or not.
        uint16 gifted;                  // Amount of users that are gifted
        uint16 giftAmount;              // Amount of users that could be gifted

        uint256 min;                    // Minimum amount of CWS allowed to spend. Could be 0.
    }

    mapping(uint256 => mapping(address => uint256)) public spents;
    /// @notice Whether user is eligable for minting or not
    /// project id => user => bool
    mapping(uint256 => mapping(address => uint16)) public giftOrder;
    /// @notice Gifted NFT id for the user per project
    /// project id => user => nft id 
    mapping(uint256 => mapping(address => uint256)) public gifts;

    mapping(uint256 => AuctionData) public auctionData;


    event Participate(uint256 indexed projectId, address indexed participant, uint256 amount, uint256 time);
    event SetAuctionData(uint256 indexed projectId, uint256 min, uint16 giftAmount);
    event Gift(uint256 indexed projectId, address indexed participant, uint256 indexed tokenId);

    constructor(address _crowns, address submission, address prefund, address project, uint256 _chainID) {
        require(_crowns != address(0) && prefund != address(0) && submission != address(0) && project != address(0), "Lighthouse: ZERO_ADDRESS");
        require(submission != prefund, "Lighthouse: SAME_ADDRESS");
        require(submission != _crowns, "Lighthouse: SAME_ADDRESS");
        require(submission != project, "Lighthouse: SAME_ADDRESS");
        require(prefund != project, "Lighthouse: SAME_ADDRESS");

        lighthouseRegistration = LighthouseRegistration(submission);
        lighthousePrefund = LighthousePrefund(prefund);
        lighthouseProject = LighthouseProject(project);
        crowns = CrownsInterface(_crowns);
        chainID = _chainID;
    }

    function setAuctionData(uint256 projectId, uint256 min, uint16 giftAmount) external onlyOwner {
        require(lighthouseProject.auctionInitialized(projectId), "Lighthouse: AUCTION_NOT_INITIALIZED");
        require(!auctionData[projectId].set, "Lighthouse: ALREADY_SET");

        AuctionData storage data = auctionData[projectId];
        data.set = true;
        data.giftAmount = giftAmount;
        data.min = min;

        emit SetAuctionData(projectId, min, giftAmount);
    }

    function setGiftNft(address giftNft) external onlyOwner {
        nft = GiftNft(giftNft);
    }

    /// @notice User participates in the Public Auction.
    /// @param amount of Crowns that user wants to spend
    function participate(uint256 projectId, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        require(lighthouseProject.auctionInitialized(projectId), "Lighthouse: AUCTION_NOT_INITIALIZED");
        require(lighthouseProject.transferredPrefund(projectId), "Lighthouse: NOT_TRANSFERRED_PREFUND_YET");
        require(auctionData[projectId].set, "Lighthouse: AUCTION_NOT_SET");
        require(!participated(projectId, msg.sender), "Lighthouse: ALREADY_PARTICIPATED");
        require(amount > 0, "Lighthouse: ZERO_VALUE");

        {   // Avoid stack too deep.
        uint256 startTime;
        uint256 endTime;
        
        (startTime, endTime) = lighthouseProject.auctionTimeInfo(projectId);

        require(block.timestamp >= startTime,   "Lighthouse: NOT_STARTED_YET");
        require(block.timestamp <= endTime,     "Lighthouse: FINISHED");

        require(amount >= auctionData[projectId].min, "Lighthouse: LESS_THAN_MIN");
        }


        require(lighthouseRegistration.registered(projectId, msg.sender), "Lighthouse: NOT_REGISTERED");
        // Lottery winners are not joining to public auction
        require(!lighthousePrefund.prefunded(projectId, msg.sender), "Lighthouse: PREFUNDED");

        // investor, project verification
	    bytes memory prefix     = "\x19Ethereum Signed Message:\n32";
	    bytes32 message         = keccak256(abi.encodePacked(msg.sender, address(this), projectId, chainID));
	    bytes32 hash            = keccak256(abi.encodePacked(prefix, message));
	    address recover         = ecrecover(hash, v, r, s);

        AuctionData storage data = auctionData[projectId];

        if (data.giftAmount > 0) {
            require(address(nft) != address(0), "Lighthouse: NO_NFT_ADDRESS");
        }

        if (data.gifted < data.giftAmount) {
            uint256 nftId = nft.mint(projectId, msg.sender);
            require(nftId > 0, "Lighthouse: NOT_MINTED");
            giftOrder[projectId][msg.sender] = data.gifted + 1;
            gifts[projectId][msg.sender] = nftId;

            data.gifted = data.gifted + 1;
        }

        lighthouseProject.collectAuctionAmount(projectId, amount);

        spents[projectId][msg.sender] = amount;

	    require(recover == lighthouseProject.getKYCVerifier(), "Lighthouse: SIG");

        require(crowns.spendFrom(msg.sender, amount), "Lighthouse: CWS_UNSPEND");

        emit Participate(projectId, msg.sender, amount, block.timestamp);
    }

    /// @notice Return spent tokens
    /// @dev First returned parameter is investor's spent amount.
    /// Second parameter is total spent amount
    function getSpent(uint256 projectId, address investor) external view returns(uint256) {
        return spents[projectId][investor];
    }

    function participated(uint256 projectId, address investor) public view returns(bool) {
        return spents[projectId][investor] > 0;
    }

    function participantGiftOrder(uint256 projectId, address participant) external view returns(uint16) {
        return giftOrder[projectId][participant];
    }

    /// @notice Returns the information about the minted amounts of NFTs and limit of them
    /// per project.
    function giftInfo(uint256 projectId) external view returns(uint16, uint16) {
        return (auctionData[projectId].gifted, auctionData[projectId].giftAmount);
    }
}

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

// Seascape NFT
// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

/// @title Lighthouse NFT
/// @notice LighthouseNFT is the NFT used in Lighthouse platform.
/// @author Medet Ahmetson
contract LighthouseNft is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    // Base URI
    string private _baseURIextended;

    Counters.Counter private tokenId;

    uint256 public projectId;  // project to which it's used	

    struct Params {
	    uint256 scaledAllocation;       // allocation among total pool of investors.
        uint256 scaledCompensation;     // compensation
        uint8 mintType;                 // mint type: 1 = prefund pool, 2 = auction pool, 3 = private investor
    }

    mapping(address => bool) public minters;
    mapping(address => bool) public burners;

    /// @dev returns parameters of Seascape NFT by token id.
    mapping(uint256 => Params) public paramsOf;

    event Minted(address indexed owner, uint256 indexed id, uint256 allocation, uint256 compensation, uint8 mintType, uint256 projectId);
    
    /**
     * @dev Sets the {name} and {symbol} of token.
     * Mints all tokens.
     */
    constructor(uint256 _projectId, string memory nftName, string memory nftSymbol) ERC721(nftName, nftSymbol) {
	    require(_projectId > 0, "Lighthouse: ZERO_VALUE");
        tokenId.increment(); // set to 1 the incrementor, so first token will be with id 1.

        projectId = _projectId;
    }

    modifier onlyMinter() {
        require(minters[_msgSender()], "Lighthouse: NOT_MINTER");
        _;
    }

    modifier onlyBurner() {
        require(burners[_msgSender()], "Lighthouse: NOT_BURNER");
        _;
    }

    /// @dev ensure that all parameters are checked on factory smartcontract
    function mint(uint256 _projectId, uint256 _tokenId, address _to, uint256 _allocation, uint256 _compensation, uint8 _type) external onlyMinter returns(bool) {
	    require(_projectId == projectId, "Lighthouse: PROJECT_ID_MISMATCH");
        uint256 _nextTokenId = tokenId.current();
        require(_tokenId == _nextTokenId, "LighthouseNFT: INVALID_TOKEN");

        _safeMint(_to, _tokenId);

        paramsOf[_tokenId] = Params(_allocation, _compensation, _type);

        tokenId.increment();

        emit Minted(_to, _tokenId, _allocation, _compensation, _type, projectId);
        
        return true;
    }

    function burn(uint256 id) public virtual override onlyBurner {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), id), "ERC721Burnable: caller is not owner nor approved");
        _burn(id);
    }

    function getNextTokenId() external view returns(uint256) {
        return tokenId.current();
    }

    function setOwner(address _owner) external onlyOwner {
	    transferOwnership(_owner);
    }

    function setMinter(address _minter) external onlyOwner {
	    minters[_minter] = true;
    }

    function unsetMinter(address _minter) external onlyOwner {
	    minters[_minter] = false;
    }

    function setBurner(address _burner) external onlyOwner {
	    burners[_burner] = true;
    }

    function unsetBurner(address _burner) external onlyOwner {
	    burners[_burner] = false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function scaledAllocation(uint256 nftId) external view returns(uint256) {
        return paramsOf[nftId].scaledAllocation;
    }

    function scaledCompensation(uint256 nftId) external view returns(uint256) {
        return paramsOf[nftId].scaledCompensation;
    }

    function mintType(uint256 nftId) external view returns(uint8) {
        return paramsOf[nftId].mintType;
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

// Seascape NFT
// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./LighthouseAuction.sol";

/// @title Lighthouse NFT given as a gift
/// @notice LighthouseNFT is the NFT used in Lighthouse platform.
/// @author Medet Ahmetson
contract GiftNft is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    // Base URI
    string private _baseURIextended;

    Counters.Counter private tokenId;

    LighthouseAuction public auction;

    // Whether user claimed his NFT for the project or not.
    // project id => user => bool
    mapping(uint256 => mapping(address => bool)) public claimed;

    mapping(address => bool) public minters;
    mapping(address => bool) public burners;

    event Gifted(address indexed owner, uint256 indexed id, uint256 indexed projectId);
    
    /**
     * @dev Sets the {name} and {symbol} of token.
     * Mints all tokens.
     */
    constructor(string memory nftName, string memory nftSymbol, address _auction) ERC721(nftName, nftSymbol) {
	    require(_auction != address(0), "Lighthouse: ZERO_ADDRESS");
        tokenId.increment(); // set to 1 the incrementor, so first token will be with id 1.

        auction = LighthouseAuction(_auction);
        minters[_auction] = true;
    }

    
    modifier onlyMinter() {
        require(minters[_msgSender()], "Lighthouse: NOT_MINTER");
        _;
    }

    modifier onlyBurner() {
        require(burners[_msgSender()], "Lighthouse: NOT_BURNER");
        _;
    }

    function auctionAddress() external view returns(address) {
        return address(auction);
    }

    /// @dev ensure that all parameters are checked on factory smartcontract
    /// WARNING! Potentially could be minted endless tokens.
    function mint(uint256 _projectId, address _to) external onlyMinter returns(uint256) {
        require(_projectId > 0, "GiftNFT: ZERO_ID");
        require(!claimed[_projectId][_to], "GiftNFT: MINTED");

        uint256 _tokenId = tokenId.current();
        _safeMint(_to, _tokenId);
        tokenId.increment();

        claimed[_projectId][_to] = true;

        emit Gifted(_to, _tokenId, _projectId);
        
        return _tokenId;
    }

    function burn(uint256 id) public virtual override onlyBurner {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), id), "ERC721Burnable: caller is not owner nor approved");
        
        address _nftOwner = ownerOf(id);
        
        _burn(id);

        delete claimed[id][_nftOwner];
    }

    function setOwner(address _owner) external onlyOwner {
	    transferOwnership(_owner);
    }

    function setMinter(address _minter) external onlyOwner {
	    minters[_minter] = true;
    }

    function unsetMinter(address _minter) external onlyOwner {
	    minters[_minter] = false;
    }

    function setBurner(address _burner) external onlyOwner {
	    burners[_burner] = true;
    }

    function unsetBurner(address _burner) external onlyOwner {
	    burners[_burner] = false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
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

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
interface IERC721Receiver {
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
 * @dev String operations.
 */
library Strings {
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

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
interface IERC165 {
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