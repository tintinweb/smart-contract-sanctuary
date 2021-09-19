/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

// SPDX-License-Identifier: GPL-v3.0

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: lock.sol


pragma solidity >=0.8.4;
pragma abicoder v2;

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager {
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

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
}


pragma solidity >=0.8.4;

library Position {
    struct Info {
        uint256 tokenId;
        // duration in which fees can't be claimed
        uint256 cliff;
        // start timestamp
        uint256 start;
        // total lock duration
        uint256 duration;
        // allow fees to be claimed at feeReciever address
        bool allowFeeClaim;
        // allow owner to transfer ownership or update feeReciever
        bool allowBeneficiaryUpdate;
        // address to receive earned fees
        address feeReciever;
        // owner of the position
        address owner;
    }

    function isPositionValid(Info memory self) internal view {
        require(self.owner != address(0), "ULL::OWNER_ZERO_ADDRESS");
        require(self.duration >= self.cliff, "ULL::CLIFF_GT_DURATION");
        require(self.duration > 0, "ULL::INVALID_DURATION");
        require((self.start + self.duration) > block.timestamp, "ULL::INVALID_ENDING_TIME");
    }

    function isOwner(Info memory self) internal view {
        require(self.owner == msg.sender && self.allowBeneficiaryUpdate, "ULL::NOT_AUTHORIZED");
    }

    function isTokenIdValid(Info memory self, uint256 tokenId) internal pure {
        require(self.tokenId == tokenId, "ULL::INVALID_TOKEN_ID");
    }

    function isTokenUnlocked(Info memory self) internal view {
        require((self.start + self.duration) < block.timestamp, "ULL::NOT_UNLOCKED");
    }

    function isFeeClaimAllowed(Info memory self) internal view {
        require(self.allowFeeClaim, "ULL::FEE_CLAIM_NOT_ALLOWED");
        require((self.start + self.cliff) < block.timestamp, "ULL::CLIFF_NOT_ENDED");
    }
}

pragma solidity >=0.8.4;

contract UniswapV3LiquidityLocker{
    using Position for Position.Info;

    mapping(uint256 => Position.Info) public lockedLiquidityPositions;

    INonfungiblePositionManager private _uniswapNFPositionManager;
    uint128 private constant MAX_UINT128 = type(uint128).max;
    address nftAdd;

    event PositionUpdated(Position.Info position);
    event FeeClaimed(uint256 tokenId);
    event TokenUnlocked(uint256 tokenId);
    event Transfer(address from,address to,uint256 tokenId);

    constructor(address _nftadd) {
        _uniswapNFPositionManager = INonfungiblePositionManager(_nftadd);
    }
    
    function setNftAdd(address _nftadd) external{
        _uniswapNFPositionManager = INonfungiblePositionManager(_nftadd);
    }
    
    function getNftAdd() external view returns (address){
        return nftAdd;
    }
    
    function lockLPToken(Position.Info calldata params) external {
        _uniswapNFPositionManager.transferFrom(msg.sender, address(this), params.tokenId);

        params.isPositionValid();

        lockedLiquidityPositions[params.tokenId] = params;

        emit PositionUpdated(params);
    }

    function claimLPFee(uint256 tokenId) external returns (uint256 amount0, uint256 amount1) {
        Position.Info memory llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isFeeClaimAllowed();

        (amount0, amount1) = _uniswapNFPositionManager.collect(
            INonfungiblePositionManager.CollectParams(tokenId, llPosition.feeReciever, MAX_UINT128, MAX_UINT128)
        );

        emit FeeClaimed(tokenId);
    }

    
    function updateFeeReciever(uint256 tokenId, address feeReciever) external {
        Position.Info storage llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isOwner();

        llPosition.feeReciever = feeReciever;

        emit PositionUpdated(llPosition);
    }

    function renounceBeneficiaryUpdate(uint256 tokenId) external {
        Position.Info storage llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isOwner();

        llPosition.allowBeneficiaryUpdate = false;

        emit PositionUpdated(llPosition);
    }

    function unlockToken(uint256 tokenId) external {
        Position.Info memory llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isTokenUnlocked();

        _uniswapNFPositionManager.transferFrom(address(this), llPosition.owner, tokenId);

        delete lockedLiquidityPositions[tokenId];

        emit TokenUnlocked(tokenId);
    }
}