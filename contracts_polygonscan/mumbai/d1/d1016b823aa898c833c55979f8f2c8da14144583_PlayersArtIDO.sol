// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IPlayersArtIDOFactory.sol";

/** @title IDO contract does IDO
 * @notice
 */

contract PlayersArtIDO is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct User {
        uint256 totalFunded; // total funded amount of user
        uint256 released; // currently released token amount
    }

    struct PlayersArtNFT {
        IERC721 nft;
        uint256 basePoint;
    }

    PlayersArtNFT[] public nfts;

    bool public cancelled;

    uint256 public constant ROUNDS_COUNT = 2; // 1: whitelist, 2: fcfs

    IPlayersArtIDOFactory public factory;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public claimTime;

    IERC20 public saleToken;
    uint256 public saleTarget;
    uint256 public saleRaised;

    // 0x0 MATIC, other: ERC20
    address public fundToken;
    uint256 public fundTarget;
    uint256 public fundRaised;
    uint256 public totalReleased;

    //
    uint256 public fcfsAmount; // users' fcfs allocation
    uint256 public minFundAmount;

    string public meta; // meta data json url

    // all funder Addresses
    address[] public funderAddresses;

    mapping(address => User) public whitelistFunders;

    mapping(address => User) public fcfsFunders;

    // vesting info
    uint256 public cliffTime;
    // 15 = 1.5%, 1000 = 100%
    uint256 public distributePercentAtClaim;
    uint256 public vestingDuration;
    uint256 public vestingPeriodicity;

    // whitelist
    mapping(address => uint256) public whitelistAmount;

    mapping(uint256 => uint256) public roundsFundRaised;

    event IDOInitialized(uint256 saleTarget, address fundToken, uint256 fundTarget);

    event IDOBaseDataChanged(
        uint256 startTime,
        uint256 endTime,
        uint256 claimTime,
        uint256 minFundAmount,
        uint256 fcfsAmount,
        string meta
    );

    event IDOTokenInfoChanged(uint256 saleTarget, uint256 fundTarget);

    event SaleTokenAddressSet(address saleToken);

    event VestingSet(
        uint256 cliffTime,
        uint256 distributePercentAtClaim,
        uint256 vestingDuration,
        uint256 vestingPeriodicity
    );

    event IDOProgressChanged(address buyer, uint256 amount, uint256 fundRaised, uint256 saleRaised, uint256 roundId);

    event IDOClaimed(address to, uint256 amount);

    event IDOCancelled(bool cancelled);

    modifier onlyOwnerOrAdmin() {
        require(factory.isAdmin(msg.sender) || owner() == msg.sender, "Not owner or admin");

        _;
    }

    modifier isNotStarted() {
        require(startTime > block.timestamp, "Already started");

        _;
    }

    modifier isOngoing() {
        require(startTime <= block.timestamp && block.timestamp <= endTime, "Not onging");

        _;
    }

    modifier isEnded() {
        require(block.timestamp >= endTime, "Not ended");

        _;
    }

    modifier isNotEnded() {
        require(block.timestamp < endTime, "Ended");

        _;
    }

    modifier isClaimable() {
        require(block.timestamp >= claimTime, "Not claimable");

        _;
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "should be EOA");
        _;
    }

    modifier canRaise(address addr, uint256 amount) {
        uint256 currentRoundId = getCurrentRoundId();

        uint256 maxAllocation = getMaxAllocation(addr);

        require(amount > 0, "0 amount");

        require(fundRaised + amount <= fundTarget, "Target hit!");

        uint256 personalTotal;
        if (currentRoundId == 1) {
            personalTotal = amount + whitelistFunders[addr].totalFunded;
        } else if (currentRoundId == 2) {
            personalTotal = amount + fcfsFunders[addr].totalFunded;
        }

        require(personalTotal >= minFundAmount, "Low amount");
        require(personalTotal <= maxAllocation, "Too much amount");

        _;
    }

    /**
     * @notice constructor
     *
     * @param _factory {address} Controller address
     * @param _saleTarget {uint256} Total token amount to sell
     * @param _fundToken {address} Fund token address
     * @param _fundTarget {uint256} Total amount of fund Token
     */
    constructor(
        IPlayersArtIDOFactory _factory,
        uint256 _saleTarget,
        address _fundToken,
        uint256 _fundTarget
    ) {
        require(address(_factory) != address(0), "Invalid");
        require(_saleTarget > 0 && _fundTarget > 0, "Invalid");

        saleTarget = _saleTarget;

        fundToken = _fundToken;
        fundTarget = _fundTarget;

        factory = _factory;

        emit IDOInitialized(saleTarget, fundToken, fundTarget);
    }

    /**
     * @notice setBaseData
     *
     * @param _startTime {uint256}  timestamp of IDO start time
     * @param _endTime {uint256}  timestamp of IDO end time
     * @param _claimTime {uint256}  timestamp of IDO claim time
     * @param _minFundAmount {uint256}  mimimum fund amount of users
     * @param _fcfsAmount {uint256}  fcfsAmount of buy
     * @param _meta {string}  url of meta data
     */
    function setBaseData(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _claimTime,
        uint256 _minFundAmount,
        uint256 _fcfsAmount,
        string memory _meta
    ) external onlyOwnerOrAdmin {
        require(_minFundAmount > 0, "0 minFund");
        require(_fcfsAmount > 0, "0 base");

        require(_startTime > block.timestamp && _startTime < _endTime && _endTime < _claimTime, "Invalid times");

        startTime = _startTime;
        endTime = _endTime;
        claimTime = _claimTime;
        minFundAmount = _minFundAmount;
        meta = _meta;
        fcfsAmount = _fcfsAmount;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, fcfsAmount, meta);
    }

    function getCurrentRoundId() public view returns (uint256) {
        if (block.timestamp < startTime || block.timestamp > endTime) {
            return 0; // not started
        }
        uint256 roundDuration = (endTime - startTime) / ROUNDS_COUNT;
        uint256 index = (block.timestamp - startTime) / roundDuration;

        // 1: white, 2: fcfs

        return index + 1;
    }

    function getRoundTotalAllocation(uint256 currentRoundId) public view returns (uint256) {
        if (currentRoundId == 0) {
            return 0;
        }
        if (currentRoundId == 1) {
            return fundTarget;
        }
        return fundTarget - roundsFundRaised[1];
    }

    function getMaxAllocation(address addr) public view returns (uint256) {
        uint256 currentRoundId = getCurrentRoundId();

        if (currentRoundId == 0) {
            return 0;
        }

        if (currentRoundId == 1) {
            // whitelist period
            uint256 allocation = getNFTBasedAllocation(addr);
            if (allocation < whitelistAmount[addr]) {
                allocation = whitelistAmount[addr];
            }
            return allocation;
        }

        return fcfsAmount;
    }

    function getFundersCount() external view returns (uint256) {
        return funderAddresses.length;
    }

    function getFunderInfo(address funder) external view returns (User memory) {
        User memory info;

        info.totalFunded = whitelistFunders[funder].totalFunded + fcfsFunders[funder].totalFunded;

        info.released = whitelistFunders[funder].released + fcfsFunders[funder].released;

        return info;
    }

    function getNftCount() external view returns (uint256) {
        return nfts.length;
    }

    function addNft(IERC721 _nft, uint256 _basePoint) external onlyOwnerOrAdmin {
        require(address(_nft) != address(0), "Invalid nft");
        require(_basePoint > 0, "Invalid point");
        PlayersArtNFT memory nft = PlayersArtNFT({ nft: _nft, basePoint: _basePoint });
        nfts.push(nft);
    }

    function removeNFT(uint256 index) external onlyOwnerOrAdmin {
        require(index < nfts.length, "Invalid index");
        if (index != nfts.length - 1) {
            nfts[index].nft = nfts[nfts.length - 1].nft;
            nfts[index].basePoint = nfts[nfts.length - 1].basePoint;
        }
        nfts.pop();
    }

    function getNFTBasedAllocation(address addr) public view returns (uint256) {
        uint256 total = 0;

        for (uint256 index = 0; index < nfts.length; index++) {
            total = total + nfts[index].nft.balanceOf(addr) * nfts[index].basePoint;
        }

        return total;
    }

    function setStartTime(uint256 _startTime) external onlyOwnerOrAdmin isNotStarted {
        require(_startTime > block.timestamp, "Invalid");
        startTime = _startTime;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, fcfsAmount, meta);
    }

    function setEndTime(uint256 _endTime) external onlyOwnerOrAdmin isNotEnded {
        require(_endTime > block.timestamp && _endTime > startTime, "Invalid");

        endTime = _endTime;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, fcfsAmount, meta);
    }

    function setClaimTime(uint256 _claimTime) external onlyOwnerOrAdmin {
        require(_claimTime > block.timestamp && _claimTime > endTime, "Invalid");

        claimTime = _claimTime;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, fcfsAmount, meta);
    }

    function setFcFsAmount(uint256 _fcfsAmount) external onlyOwnerOrAdmin {
        require(_fcfsAmount > 0, "Invalid");

        fcfsAmount = _fcfsAmount;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, fcfsAmount, meta);
    }

    function setMinFundAmount(uint256 _minFundAmount) external onlyOwnerOrAdmin {
        require(_minFundAmount > 0, "Invalid");

        minFundAmount = _minFundAmount;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, fcfsAmount, meta);
    }

    function setMeta(string memory _meta) external onlyOwnerOrAdmin {
        meta = _meta;

        emit IDOBaseDataChanged(startTime, endTime, claimTime, minFundAmount, fcfsAmount, meta);
    }

    function setSaleToken(IERC20 _saleToken) external onlyOwnerOrAdmin {
        require(address(_saleToken) != address(0), "Invalid");

        saleToken = _saleToken;
        emit SaleTokenAddressSet(address(saleToken));
    }

    function setSaleTarget(uint256 _saleTarget) external onlyOwnerOrAdmin {
        require(_saleTarget > 0, "Invalid");
        saleTarget = _saleTarget;
        emit IDOTokenInfoChanged(saleTarget, fundTarget);
    }

    function setFundTarget(uint256 _fundTarget) external onlyOwnerOrAdmin {
        require(_fundTarget > 0, "Invalid");
        fundTarget = _fundTarget;
        emit IDOTokenInfoChanged(saleTarget, fundTarget);
    }

    function setVestingInfo(
        uint256 _cliffTime,
        uint256 _distributePercentAtClaim,
        uint256 _vestingDuration,
        uint256 _vestingPeriodicity
    ) external onlyOwnerOrAdmin {
        require(_cliffTime > claimTime, "Invalid Cliff");
        require(_distributePercentAtClaim <= 1000, "Invalid tge");
        require(_vestingDuration > 0 && _vestingPeriodicity > 0, "0 Duration or Period");
        require(
            (_vestingDuration - (_vestingDuration / _vestingPeriodicity) * _vestingPeriodicity) == 0,
            "Not divided"
        );

        cliffTime = _cliffTime;
        distributePercentAtClaim = _distributePercentAtClaim;
        vestingDuration = _vestingDuration;
        vestingPeriodicity = _vestingPeriodicity;

        emit VestingSet(cliffTime, distributePercentAtClaim, vestingDuration, vestingPeriodicity);
    }

    function withdrawRemainingSaleToken() external onlyOwnerOrAdmin {
        require(block.timestamp > endTime, "IDO has not yet ended");
        saleToken.safeTransfer(msg.sender, saleToken.balanceOf(address(this)) + totalReleased - saleRaised);
    }

    function withdrawFundedBNB() external onlyOwnerOrAdmin isEnded {
        require(fundToken == address(0), "It's not Matic-buy pool!");

        uint256 balance = address(this).balance;

        (address feeRecipient, uint256 feePercent) = factory.getFeeInfo();

        uint256 fee = (balance * (feePercent)) / (1000);
        uint256 restAmount = balance - (fee);

        (bool success, ) = payable(feeRecipient).call{ value: fee }("");
        require(success, "Matic fee pay failed");
        (bool success1, ) = payable(msg.sender).call{ value: restAmount }("");
        require(success1, "Matic withdraw failed");
    }

    function withdrawFundedToken() external onlyOwnerOrAdmin isEnded {
        require(fundToken != address(0), "It's not token-buy pool!");

        uint256 balance = IERC20(fundToken).balanceOf(address(this));

        (address feeRecipient, uint256 feePercent) = factory.getFeeInfo();

        uint256 fee = (balance * feePercent) / 1000;
        uint256 restAmount = balance - fee;

        IERC20(fundToken).safeTransfer(feeRecipient, fee);
        IERC20(fundToken).safeTransfer(msg.sender, restAmount);
    }

    function getUnlockedTokenAmount(address addr, uint256 fundedAmount) private view returns (uint256) {
        require(addr != address(0), "Invalid address!");

        if (block.timestamp < claimTime) return 0;

        uint256 totalSaleToken = (fundedAmount * saleTarget) / fundTarget;

        uint256 distributeAmountAtClaim = (totalSaleToken * distributePercentAtClaim) / 1000;

        if (cliffTime > block.timestamp) {
            return distributeAmountAtClaim;
        }

        if (cliffTime == 0) {
            // vesting info is not set yet
            return 0;
        }

        uint256 finalTime = cliffTime + vestingDuration - vestingPeriodicity;

        if (block.timestamp >= finalTime) {
            return totalSaleToken;
        }

        uint256 lockedAmount = totalSaleToken - distributeAmountAtClaim;

        uint256 totalPeridicities = vestingDuration / vestingPeriodicity;
        uint256 periodicityAmount = lockedAmount / totalPeridicities;
        uint256 currentperiodicityCount = (block.timestamp - cliffTime) / vestingPeriodicity + 1;
        uint256 availableAmount = periodicityAmount * currentperiodicityCount;

        return distributeAmountAtClaim + availableAmount;
    }

    function getWhitelistClaimableAmount(address addr) private view returns (uint256) {
        return getUnlockedTokenAmount(addr, whitelistFunders[addr].totalFunded) - whitelistFunders[addr].released;
    }

    function getFCFSClaimableAmount(address addr) private view returns (uint256) {
        return getUnlockedTokenAmount(addr, fcfsFunders[addr].totalFunded) - fcfsFunders[addr].released;
    }

    function getClaimableAmount(address addr) public view returns (uint256) {
        return getWhitelistClaimableAmount(addr) + getFCFSClaimableAmount(addr);
    }

    function _claimTo(address to) private {
        require(to != address(0), "Invalid address");
        uint256 claimableAmount = getClaimableAmount(to);
        if (claimableAmount > 0) {
            whitelistFunders[to].released = whitelistFunders[to].released + getWhitelistClaimableAmount(to);
            fcfsFunders[to].released = fcfsFunders[to].released + getFCFSClaimableAmount(to);

            saleToken.safeTransfer(to, claimableAmount);
            totalReleased = totalReleased + claimableAmount;
            emit IDOClaimed(to, claimableAmount);
        }
    }

    function claim() external isClaimable nonReentrant onlyEOA {
        uint256 claimableAmount = getClaimableAmount(msg.sender);
        require(claimableAmount > 0, "Nothing to claim");
        _claimTo(msg.sender);
    }

    function batchClaim(address[] calldata addrs) external isClaimable nonReentrant onlyEOA {
        for (uint256 index = 0; index < addrs.length; index++) {
            _claimTo(addrs[index]);
        }
    }

    function _processBuy(address buyer, uint256 amount) private {
        uint256 saleTokenAmount = (amount * saleTarget) / fundTarget;
        uint256 currentRoundId = getCurrentRoundId();

        fundRaised = fundRaised + amount;
        saleRaised = saleRaised + saleTokenAmount;

        uint256 roundId = currentRoundId;

        if (currentRoundId == 1) {
            // whitelist
            if (whitelistFunders[buyer].totalFunded == 0) {
                funderAddresses.push(buyer);
            }

            whitelistFunders[buyer].totalFunded = whitelistFunders[buyer].totalFunded + amount;
        } else if (currentRoundId == 2) {
            // fcfs
            if (whitelistFunders[buyer].totalFunded == 0 && fcfsFunders[buyer].totalFunded == 0) {
                funderAddresses.push(buyer);
            }

            fcfsFunders[buyer].totalFunded = fcfsFunders[buyer].totalFunded + amount;
        }

        roundsFundRaised[roundId] = roundsFundRaised[roundId] + amount;

        emit IDOProgressChanged(buyer, amount, fundRaised, saleRaised, currentRoundId);
    }

    function buyWithBNB() public payable isOngoing canRaise(msg.sender, msg.value) onlyEOA {
        require(fundToken == address(0), "It's not BNB-buy pool!");

        _processBuy(msg.sender, msg.value);
    }

    function buy(uint256 amount) public isOngoing canRaise(msg.sender, amount) onlyEOA {
        require(fundToken != address(0), "It's not token-buy pool!");

        _processBuy(msg.sender, amount);

        IERC20(fundToken).safeTransferFrom(msg.sender, address(this), amount);
    }

    function setWhitelist(address[] calldata addrs, uint256[] calldata amounts) external onlyOwnerOrAdmin {
        require(addrs.length == amounts.length, "Invalid params");

        for (uint256 index = 0; index < addrs.length; index++) {
            whitelistAmount[addrs[index]] = amounts[index];
        }
    }

    function setCancelled(bool _cancelled) external onlyOwnerOrAdmin {
        cancelled = _cancelled;
        emit IDOCancelled(cancelled);
    }

    function withdrawAny(IERC20 _token, uint256 _amount) external onlyOwnerOrAdmin {
        _token.safeTransfer(msg.sender, _amount);
    }

    function withdrawEther(uint256 _amount) external onlyOwnerOrAdmin {
        payable(msg.sender).call{ value: _amount }("");
    }

    receive() external payable {
        revert("Something went wrong!");
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor () {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPlayersArtIDOFactory {
    event NewIDOCreated(address indexed pool, address creator);

    function isAdmin(address) external view returns (bool);

    function getFeeInfo() external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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