// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC1155} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {ERC165Checker} from '@openzeppelin/contracts/introspection/ERC165Checker.sol';
import {AuctionBase} from './misc/AuctionBase.sol';
import {IStakedAave} from './interfaces/IStakedAave.sol';
import {IERC20Permit} from './interfaces/IERC20Permit.sol';
import {IVault} from './interfaces/IVault.sol';
import {DataTypes} from './libraries/DataTypes.sol';
import {Errors} from './libraries/Errors.sol';
import {InitUpgradeable} from './upgradeability/InitUpgradeable.sol';

contract StakeAuction is InitUpgradeable, AuctionBase {
    using SafeERC20 for IERC20Permit;
    using SafeERC20 for IStakedAave;
    using SafeMath for uint256;

    uint256 public constant STAKEAUCTION_REVISION = 0x1;
    bytes4 public constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 public constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    IERC20Permit internal constant _aave = IERC20Permit(0xB597cd8D3217ea6477232F9217fa70837ff667Af);
    IStakedAave internal constant _stkAave =
        IStakedAave(0xf2fbf9A6710AfDa1c4AaB2E922DE9D69E0C97fd2);

    mapping(address => mapping(uint256 => DataTypes.AuctionData)) internal _auctionsByNft;
    mapping(address => mapping(uint256 => DataTypes.StakeData)) internal _stakeDataByNft;
    address internal _vaultLogic;
    uint16 internal _burnPenaltyBps;

    /**
     * @notice Emitted when a new auction is scheduled on a given NFT.
     *
     * @param nft The NFT address of the token to auction.
     * @param nftId The NFT ID of the token to auction.
     * @param startTimestamp The auction's starting timestamp.
     * @param endTimestamp The auction's ending timestamp.
     * @param startPrice The auction's starting price.
     */
    event AuctionCreated(
        address nft,
        uint256 nftId,
        uint40 startTimestamp,
        uint40 endTimestamp,
        uint256 startPrice
    );

    /**
     * @notice Emitted when a new bid or outbid is created on a given NFT.
     *
     * @param nft The NFT address of the token bid on.
     * @param nftId The NFT ID of the token bid on.
     * @param bidder The bidder address.
     * @param amount The amount used to bid.
     */
    event Bid(address nft, uint256 nftId, address bidder, uint256 amount);

    /**
     * @notice Emitted when an NFT is won and claimed.
     *
     * @param nft The NFT address of the token claimed.
     * @param nftId The NFT ID of the token claimed.
     * @param winner The winner of the NFT.
     */
    event WonNftClaimed(address nft, uint256 nftId, address winner);

    /**
     * @notice Emitted when an NFT is redeemed for the underlying stake in it's corresponding vault.
     *
     * @param nft The NFT address redeemed.
     * @param nftId The NFT ID redeemed.
     */
    event Redeemed(address nft, uint256 nftId);

    /**
     * @dev Initializes the contract.
     *
     * @param vaultLogic The vault logic implementation address to clone.
     * @param treasury The treasury to send fees to.
     * @param treasuryFeeBps The treasury fee basis points sent upon claiming and burning.
     * @param burnPenaltyBps The amount of stkAAVE to distribute upon burning.
     * @param overtimeWindow The overtime window, triggers when a bid is sent within endTimestamp - overtimeWindow.
     * @param minimumAuctionDuration The minimum auction duration.
     * @param admin The administrator address to set, allows pausing.
     */
    function initialize(
        address vaultLogic,
        address treasury,
        uint16 treasuryFeeBps,
        uint16 burnPenaltyBps,
        uint40 overtimeWindow,
        uint40 minimumAuctionDuration,
        address admin,
        uint8 distributionCap
    ) public initializer {
        require(
            admin != address(0) &&
                treasury != address(0) &&
                vaultLogic != address(0) &&
                treasuryFeeBps < BPS_MAX &&
                burnPenaltyBps < BPS_MAX &&
                overtimeWindow < minimumAuctionDuration &&
                distributionCap > 0,
            Errors.INVALID_INIT_PARAMS
        );

        _vaultLogic = vaultLogic;
        _treasury = treasury;
        _treasuryFeeBps = treasuryFeeBps;
        _burnPenaltyBps = burnPenaltyBps;
        _overtimeWindow = overtimeWindow;
        _minimumAuctionDuration = minimumAuctionDuration;
        _aave.approve(address(_stkAave), type(uint256).max);
        _admin = admin;
        _distributionCap = distributionCap;
        _paused = false;
    }

    /**
     * @notice Creates an auction on a given NFT with specified parameters. Initiator must be the owner of the NFT.
     *
     * @param nft The NFT address to auction.
     * @param nftId The NFT ID to auction.
     * @param startTimestamp The starting auction timestamp.
     * @param endTimestamp The ending auction timestamp.
     * @param startPrice The starting price for the auction.
     * @param distribution The distribution to follow upon completion
     */
    function createAuction(
        address nft,
        uint256 nftId,
        uint40 startTimestamp,
        uint40 endTimestamp,
        uint256 startPrice,
        DataTypes.DistributionData[] memory distribution
    ) external whenNotPaused {
        DataTypes.AuctionData storage auction = _auctionsByNft[nft][nftId];

        // Validate that an auction does not already exist for this NFT.
        require(auction.owner == address(0), Errors.AUCTION_EXISTS);

        // Validate that there is no stake data associated with this NFT.
        require(_stakeDataByNft[nft][nftId].owner == address(0), Errors.STAKE_EXISTS);

        // Validate distribution cap.
        require(distribution.length <= _distributionCap, Errors.TOO_MANY_DISTRIBUTIONS);

        // Validate timestamps
        require(
            startTimestamp > block.timestamp && endTimestamp > startTimestamp,
            Errors.INVALID_AUCTION_TIMESTAMPS
        );

        // Validate duration
        require(
            endTimestamp - startTimestamp >= _minimumAuctionDuration,
            Errors.INVALID_AUCTION_DURATION
        );

        // Validate distribution
        uint256 neededBps = uint256(BPS_MAX).sub(_treasuryFeeBps);
        uint256 totalBps;
        for (uint256 i = 0; i < distribution.length; i++) {
            totalBps = totalBps.add(distribution[i].bps);
        }
        require(totalBps == neededBps, Errors.INVALID_DISTRIBUTION_BPS);

        // We can't copy a memory struct array into storage, so we just edit storage manually.
        auction.startTimestamp = startTimestamp;
        auction.endTimestamp = endTimestamp;
        auction.currentBid = startPrice;
        auction.owner = msg.sender;
        for (uint256 i = 0; i < distribution.length; i++) {
            auction.distribution.push(distribution[i]);
        }

        // Determine ERC721 or ERC1155 interface
        if (ERC165Checker.supportsInterface(nft, _INTERFACE_ID_ERC721)) {
            auction.interfaceId = _INTERFACE_ID_ERC721;
            //IERC721 nftContract = IERC721(nft);
            //require(nftContract.ownerOf(nftId) == msg.sender, Errors.NOT_NFT_OWNER);
            IERC721(nft).transferFrom(msg.sender, address(this), nftId);
        } else if (ERC165Checker.supportsInterface(nft, _INTERFACE_ID_ERC1155)) {
            auction.interfaceId = _INTERFACE_ID_ERC1155;
            //IERC1155 nftContract = IERC1155(nft);
            IERC1155(nft).safeTransferFrom(msg.sender, address(this), nftId, 1, '');
        } else {
            revert(Errors.INVALID_INTERFACE);
        }

        emit AuctionCreated(nft, nftId, startTimestamp, endTimestamp, startPrice);
    }

    /**
     * @notice Bids using EIP-2612 permit to approve within the same function call.
     *
     * @param params The BidWithPermitParams struct containing the necessary information.
     */
    function bidWithPermit(DataTypes.BidWithPermitParams memory params) external whenNotPaused {
        _aave.permit(
            msg.sender,
            address(this),
            params.amount,
            params.deadline,
            params.v,
            params.r,
            params.s
        );
        _bid(msg.sender, params.onBehalfOf, params.nft, params.nftId, params.amount);
    }

    /**
     * @notice Claims a won NFT after an auction. Can be called either by anyone.
     * This function initializes the vault and staking mechanism.
     *
     * @param nft The NFT address of the token to claim.
     * @param nftId The NFT ID of the token to claim.
     */
    function claimWonNFT(address nft, uint256 nftId) external whenNotPaused {
        DataTypes.AuctionData storage auction = _auctionsByNft[nft][nftId];

        address winner = auction.currentBidder;
        address owner = auction.owner;
        uint256 endTimestamp = auction.endTimestamp;
        uint256 currentBid = auction.currentBid;
        bytes4 interfaceId = auction.interfaceId;
        DataTypes.DistributionData[] memory distribution = auction.distribution;

        require(block.timestamp > endTimestamp, Errors.AUCTION_ONGOING);

        // Create the vault
        address clone = Clones.clone(_vaultLogic);

        // We can't copy a memory struct array into storage, so we must edit storage values manually and push.
        _stakeDataByNft[nft][nftId].vault = clone;
        _stakeDataByNft[nft][nftId].owner = owner;
        for (uint256 i = 0; i < distribution.length; i++) {
            _stakeDataByNft[nft][nftId].distribution.push(distribution[i]);
        }

        // Stake AAVE and transfer NFT
        _stkAave.stake(clone, currentBid);

        if (interfaceId == _INTERFACE_ID_ERC721) {
            _stakeDataByNft[nft][nftId].interfaceId = _INTERFACE_ID_ERC721;
            IERC721(nft).safeTransferFrom(address(this), winner, nftId);
        } else {
            _stakeDataByNft[nft][nftId].interfaceId = _INTERFACE_ID_ERC1155;
            IERC1155(nft).safeTransferFrom(address(this), winner, nftId, 1, '');
        }

        // Clear out the auction struct
        delete (_auctionsByNft[nft][nftId]);
        emit WonNftClaimed(nft, nftId, winner);
    }

    /**
     * @notice Reclaims an NFT in the unlikely event that an auction did not result in any bids.
     *
     * @param nft The NFT address of the token to reclaim.
     * @param nftId The NFT ID of the token to reclaim.
     */
    function reclaimEndedAuction(address nft, uint256 nftId) external whenNotPaused {
        DataTypes.AuctionData storage auction = _auctionsByNft[nft][nftId];
        address currentBidder = auction.currentBidder;
        address artist = auction.owner;
        uint256 endTimestamp = auction.endTimestamp;
        bytes4 interfaceId = auction.interfaceId;

        require(block.timestamp > endTimestamp, Errors.AUCTION_ONGOING);
        require(currentBidder == address(0), Errors.VALID_BIDDER);
        //address artist = auction.owner;
        if (interfaceId == _INTERFACE_ID_ERC721) {
            IERC721(nft).safeTransferFrom(address(this), artist, nftId);
        } else {
            IERC1155(nft).safeTransferFrom(address(this), artist, nftId, 1, '');
        }

        delete (_auctionsByNft[nft][nftId]);
    }

    /**
     * @notice Redeems an NFT to unlock the stake less penalty.
     *
     * @param nft The NFT address of the token to redeem.
     * @param nftId The NFT ID of the token to redeem.
     */
    function redeem(address nft, uint256 nftId) external whenNotPaused {
        // require(msg.sender == IERC721(nft).ownerOf(nftId), Errors.NOT_NFT_OWNER);

        DataTypes.StakeData storage stakeData = _stakeDataByNft[nft][nftId];
        address vault = stakeData.vault;
        bytes4 interfaceId = stakeData.interfaceId;
        address artist = stakeData.owner;
        DataTypes.DistributionData[] memory distribution = stakeData.distribution;

        require(vault != address(0), Errors.NONEXISTANT_VAULT);

        //IVault vault = IVault(vaultAddress);
        uint256 rewardsBalance = _stkAave.getTotalRewardsBalance(vault);
        uint256 stkAaveVaultBalance = _stkAave.balanceOf(vault);

        _claimAndRedeem(vault, stkAaveVaultBalance);

        // Transfer out stkAAVE, less the penalty
        uint256 penaltyAmount = uint256(_burnPenaltyBps).mul(stkAaveVaultBalance).div(BPS_MAX);
        _stkAave.safeTransfer(msg.sender, stkAaveVaultBalance.sub(penaltyAmount));

        // Distribute AAVE rewards, rounding errors accounted for in _distribute.
        _distribute(address(_aave), rewardsBalance, distribution);

        // Distribute stkAAVE stake penalty, rounding errors accounted for in _distribute.
        _distribute(address(_stkAave), penaltyAmount, distribution);

        // Add stakeData interfaceId field
        if (interfaceId == _INTERFACE_ID_ERC721) {
            IERC721(nft).safeTransferFrom(msg.sender, artist, nftId);
        } else {
            IERC1155(nft).safeTransferFrom(msg.sender, artist, nftId, 1, '');
        }

        delete (_stakeDataByNft[nft][nftId]);

        // No need to waste gas on a vault selfDestruct call, gas refunds are likely disappearing.
        emit Redeemed(nft, nftId);
    }

    /**
     * @notice Claims rewards associated with a given NFT.
     *
     * @param nft The NFT address to claim for.
     * @param nftId The NFT Id to claim for.
     */
    function claimRewards(address nft, uint256 nftId) external whenNotPaused {
        DataTypes.StakeData storage stakeData = _stakeDataByNft[nft][nftId];
        address vault = stakeData.vault;
        DataTypes.DistributionData[] memory distribution = stakeData.distribution;
        require(vault != address(0), Errors.NONEXISTANT_VAULT);

        uint256 rewardsBalance = _stkAave.getTotalRewardsBalance(vault);
        bytes memory rewardFunctionData = _buildClaimRewardsParams(address(this));
        address[] memory targets = new address[](1);
        bytes[] memory params = new bytes[](1);
        DataTypes.CallType[] memory callTypes = new DataTypes.CallType[](1);

        targets[0] = address(_stkAave);
        params[0] = rewardFunctionData;
        callTypes[0] = DataTypes.CallType.Call;
        IVault(vault).execute(targets, params, callTypes);

        _distribute(address(_aave), rewardsBalance, distribution);
    }

    /**
     * @dev Admin function to set the burn penalty BPS.
     *
     * @param newBurnPenaltyBps The new burn penalty BPS to use.
     */
    function setBurnPenaltyBps(uint16 newBurnPenaltyBps) external onlyAdmin {
        require(newBurnPenaltyBps < BPS_MAX, Errors.INVALID_INIT_PARAMS);
        _burnPenaltyBps = newBurnPenaltyBps;
    }

    /**
     * @dev Admin function to set the vault logic address.
     *
     * @param newVaultLogic The new vault logic address.
     */
    function setNewVaultLogic(address newVaultLogic) external onlyAdmin {
        require(newVaultLogic != address(0), Errors.INVALID_INIT_PARAMS);
        _vaultLogic = newVaultLogic;
    }

    /**
     * @notice Returns the current configuration of the auction's internal parameters.
     *
     * @return An StakeAuctionConfiguration struct containing the configuration.
     */
    function getConfiguration() external view returns (DataTypes.StakeAuctionConfiguration memory) {
        return
            DataTypes.StakeAuctionConfiguration(
                _vaultLogic,
                _treasury,
                _minimumAuctionDuration,
                _overtimeWindow,
                _treasuryFeeBps,
                _burnPenaltyBps
            );
    }

    /**
     * @notice Returns the auction data for a given NFT.
     *
     * @param nft The NFT address to query.
     * @param nftId The NFT ID to query.
     */
    function getAuctionByNft(address nft, uint256 nftId)
        external
        view
        returns (DataTypes.AuctionData memory)
    {
        require(_auctionsByNft[nft][nftId].owner != address(0), Errors.ZERO_ARTIST);
        return _auctionsByNft[nft][nftId];
    }

    /**
     * @notice Returns the vault connected with a stkNFT ID. A stkNFT with ID "id" must exist.
     *
     * @param nft The NFT address to query a vault for.
     * @param nftId The NFT ID to query.
     */
    function getStakeData(address nft, uint256 nftId)
        external
        view
        returns (DataTypes.StakeData memory)
    {
        require(_stakeDataByNft[nft][nftId].vault != address(0), Errors.NONEXISTANT_VAULT);
        return _stakeDataByNft[nft][nftId];
    }

    /**
     * @notice Returns its own function selector. Necessary to allow ERC1155 auctions.
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        //return IERC1155Receiver(address(0)).onERC1155Received.selector;
        return 0xf23a6e61;
    }

    function _bid(
        address spender,
        address onBehalfOf,
        address nft,
        uint256 nftId,
        uint256 amount
    ) internal override {
        require(onBehalfOf != address(0), Errors.INVALID_BIDDER);
        DataTypes.AuctionData storage auction = _auctionsByNft[nft][nftId];
        uint256 currentBid = auction.currentBid;
        address currentBidder = auction.currentBidder;
        uint40 endTimestamp = auction.endTimestamp;
        uint40 startTimestamp = auction.startTimestamp;

        require(
            block.timestamp > startTimestamp && block.timestamp < endTimestamp,
            Errors.INVALID_BID_TIMESTAMPS
        );
        require(amount > currentBid, Errors.INVALID_BID_AMOUNT);

        // Check for overtime, will underflow if _overtimeWindow > endTimestamp.
        if (_overtimeWindow > 0 && block.timestamp > endTimestamp - _overtimeWindow) {
            uint40 newEndTimestamp = endTimestamp + _overtimeWindow;
            auction.endTimestamp = newEndTimestamp;
        }

        // Update storage
        auction.currentBidder = onBehalfOf;
        auction.currentBid = amount;

        // If there was a previous bidder, send AAVE back
        if (currentBidder != address(0)) {
            _aave.safeTransfer(currentBidder, currentBid);
        }

        // Transfer in the bid
        _aave.safeTransferFrom(spender, address(this), amount);
        emit Bid(nft, nftId, onBehalfOf, amount);
    }

    /**
     * @dev Internal function that handles the vault call upon NFT redemption. Does not distribute.
     *
     * @param vault The vault address to call.
     * @param stkAaveAmount The amount (equivalent to the stkAAVE balance of the vault) to transfer in.
     */
    function _claimAndRedeem(address vault, uint256 stkAaveAmount) internal {
        bytes memory rewardFunctionData = _buildClaimRewardsParams(address(this));
        bytes memory transferFunctionData = _buildTransferParams(address(this), stkAaveAmount);

        address[] memory targets = new address[](2);
        bytes[] memory params = new bytes[](2);
        DataTypes.CallType[] memory callTypes = new DataTypes.CallType[](2);

        targets[0] = address(_stkAave);
        targets[1] = address(_stkAave);
        params[0] = rewardFunctionData;
        params[1] = transferFunctionData;
        callTypes[0] = DataTypes.CallType.Call;
        callTypes[1] = DataTypes.CallType.Call;

        // Call with both claim rewards & send stkAave to this address
        IVault(vault).execute(targets, params, callTypes);
    }

    /**
     * @dev Internal function that builds stkAAVE claim reward params.
     *
     * @param to The address to claim rewards to.
     *
     * @return Bytes containing the claimRewards data needed.
     */
    function _buildClaimRewardsParams(address to) internal pure returns (bytes memory) {
        bytes4 claimRewardsSelector = 0x9a99b4f0; //IStakedAave.claimRewards.selector;
        bytes memory rewardFunctionData =
            abi.encodeWithSelector(claimRewardsSelector, to, type(uint256).max);
        return rewardFunctionData;
    }

    /**
     * @dev Internal function that builds ERC20 transfer params.
     *
     * @param to The address to transfer to.
     * @param amount The amount to transfer.
     *
     * @return Bytes containing the transfer data needed.
     */
    function _buildTransferParams(address to, uint256 amount) internal pure returns (bytes memory) {
        bytes4 transferSelector = 0xa9059cbb; //IERC20.transfer.selector;
        bytes memory transferFunctionData = abi.encodeWithSelector(transferSelector, to, amount);
        return transferFunctionData;
    }

    function getRevision() internal pure override returns (uint256) {
        return STAKEAUCTION_REVISION;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // success determines whether the staticcall succeeded and result determines
        // whether the contract at account indicates support of _interfaceId
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

    /**
     * @notice Calls the function with selector 0x01ffc9a7 (ERC165) and suppresses throw
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return success true if the STATICCALL succeeded, false otherwise
     * @return result true if the STATICCALL succeeded and the contract at account
     * indicates support of the interface with identifier interfaceId, false otherwise
     */
    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool, bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return (false, false);
        return (success, abi.decode(result, (bool)));
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {IERC20Permit} from '../interfaces/IERC20Permit.sol';
import {Errors} from '../libraries/Errors.sol';
import {DataTypes} from '../libraries/DataTypes.sol';
import {AdminPausableUpgradeSafe} from './AdminPausableUpgradeSafe.sol';

abstract contract AuctionBase is AdminPausableUpgradeSafe {
    using SafeERC20 for IERC20Permit;
    using SafeMath for uint256;

    uint16 public constant BPS_MAX = 10000;

    address internal _treasury;
    uint40 internal _minimumAuctionDuration;
    uint40 internal _overtimeWindow;
    uint16 internal _treasuryFeeBps;
    uint8 internal _distributionCap;

    /**
     * @dev Admin function to change the treasury fee BPS.
     *
     * @param newTreasuryFeeBps The new treasury fee to use.
     */
    function changeTreasuryFeeBps(uint16 newTreasuryFeeBps) external onlyAdmin {
        require(newTreasuryFeeBps < BPS_MAX, Errors.INVALID_INIT_PARAMS);
        _treasuryFeeBps = newTreasuryFeeBps;
    }

    /**
     * @dev Admin function to change the treasury address.
     *
     * @param newTreasury The new treasury address to use.
     */
    function changeTreasuryAddress(address newTreasury) external onlyAdmin {
        require(newTreasury != address(0), Errors.INVALID_INIT_PARAMS);
        _treasury = newTreasury;
    }

    /**
     * @dev Admin function to change the minimum auction duration.
     *
     * @param newMinimumDuration The new minimum auction duration to set.
     */
    function changeMinimumAuctionDuration(uint40 newMinimumDuration) external onlyAdmin {
        require(newMinimumDuration > _overtimeWindow, Errors.INVALID_INIT_PARAMS);
        _minimumAuctionDuration = newMinimumDuration;
    }

    /**
     * @dev Admin function to set the auction overtime window.
     *
     * @param newOvertimeWindow The new overtime window to set.
     */
    function changeOvertimeWindow(uint40 newOvertimeWindow) external onlyAdmin {
        require(newOvertimeWindow < _minimumAuctionDuration, Errors.INVALID_INIT_PARAMS);
        _overtimeWindow = newOvertimeWindow;
    }

    /**
     * @dev Admin function to change the distribution cap.
     *
     * @param newDistributionCap The new distribution cap to set.
     */
    function changeDistributionCap(uint8 newDistributionCap) external onlyAdmin {
        require(newDistributionCap > 0, Errors.INVALID_INIT_PARAMS);
        _distributionCap = newDistributionCap;
    }

    /**
     * @notice Bids on a given NFT with a given amount.
     *
     * @param onBehalfOf The address to bid on behalf of.
     * @param nft The NFT address to bid on.
     * @param nftId The NFT ID to bid on.
     * @param amount The amount to bid with.
     */
    function bid(
        address onBehalfOf,
        address nft,
        uint256 nftId,
        uint256 amount
    ) external whenNotPaused {
        _bid(msg.sender, onBehalfOf, nft, nftId, amount);
    }

    /**
     * @dev Internal function that distributes a given ERC20 token and token amount according to a given
     * distribution array.
     *
     * @param currency The currency address to distribute.
     * @param amount The total amount to distribute.
     * @param distribution The distribution array.
     */
    function _distribute(
        address currency,
        uint256 amount,
        DataTypes.DistributionData[] memory distribution
    ) internal {
        IERC20Permit token = IERC20Permit(currency);
        uint256 leftover = amount;
        uint256 distributionAmount;
        for (uint256 i = 0; i < distribution.length; i++) {
            distributionAmount = amount.mul(distribution[i].bps).div(BPS_MAX);
            leftover = leftover.sub(distributionAmount);
            token.safeTransfer(distribution[i].recipient, distributionAmount);
        }

        // Treasury gets the leftovers, equal to amount.mul(_treasuryFeeBps).div(BPS_MAX) for rounding errors.
        token.safeTransfer(_treasury, leftover);
    }

    function _bid(
        address spender,
        address onBehalfOf,
        address nft,
        uint256 nftId,
        uint256 amount
    ) internal virtual;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev This interface allows the auction contract to interact with staked AAVE.
 */
interface IStakedAave is IERC20 {
    function stake(address onBehalfOf, uint256 amount) external;

    function claimRewards(address to, uint256 amount) external;

    function getTotalRewardsBalance(address staker)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC20Permit is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IVault {
    function execute(
        address[] calldata targets,
        bytes[] calldata datas,
        DataTypes.CallType[] calldata callTypes
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

/// Library containing data types needed for the NFT controller & vaults
library DataTypes {
    // struct RankedBidData {
    //     address higherBidder;
    //     address bidder;
    //     address lowerBidder;
    //     uint256 amount;
    // }

    struct DistributionData {
        address recipient;
        uint256 bps;
    }

    struct StakeData {
        DistributionData[] distribution;
        address vault;
        address owner;
        bytes4 interfaceId;
    }

    struct AuctionData {
        DistributionData[] distribution;
        uint256 currentBid;
        address owner;
        address currentBidder;
        uint40 startTimestamp;
        uint40 endTimestamp;
        bytes4 interfaceId;
    }

    struct GenericAuctionData {
        DistributionData[] distribution;
        uint256 currentBid;
        address currency;
        address owner;
        address currentBidder;
        uint40 startTimestamp;
        uint40 endTimestamp;
        bytes4 interfaceId;
    }

    struct StakeAuctionConfiguration {
        address vaultLogic;
        address treasury;
        uint40 minimumAuctionDuration;
        uint40 overtimeWindow;
        uint16 treasuryFeeBps;
        uint16 burnPenaltyBps;
    }

    struct GenericAuctionConfiguration {
        address treasury;
        uint40 minimumAuctionDuration;
        uint40 overtimeWindow;
        uint16 treasuryFeeBps;
    }

    struct BidWithPermitParams {
        uint256 amount;
        uint256 deadline;
        uint256 nftId;
        address onBehalfOf;
        address nft;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    enum CallType {Call, DelegateCall}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

// Contains error code strings

library Errors {
  string public constant NOT_ARTIST = '1';
  string public constant NOT_NFT_OWNER = '2';
  string public constant INVALID_AUCTION_TIMESTAMPS = '3';
  string public constant INVALID_BID_TIMESTAMPS = '4';
  string public constant INVALID_BID_AMOUNT = '5';
  string public constant AUCTION_INCOMPLETE = '6';
  string public constant NOT_ARTIST_OR_WINNING_BIDDER = '7';
  string public constant AUCTION_ONGOING = '8';
  string public constant VALID_BIDDER = '9';
  string public constant NOT_STKNFT_OWNER = '10';
  string public constant NONEXISTANT_VAULT = '11';
  string public constant INVALID_DISTRIBUTION_BPS = '12';
  string public constant AUCTION_EXISTS = '13';
  string public constant STAKE_EXISTS = '14';
  string public constant ZERO_ARTIST = '15';
  string public constant NOT_STAKE_AUCTION = '16';
  string public constant INVALID_CALL_TYPE = '17';
  string public constant ARRAY_MISMATCH = '18';
  string public constant COULD_NOT_FIT_BID = '19';
  string public constant ALL_NFTS_CLAIMED = '20';
  string public constant UNCLAIMED_NFTS = '21';
  string public constant AUCTION_DOES_NOT_EXIST = '22';
  string public constant INVALID_INTERFACE = '23';
  string public constant INVALID_AUCTION_DURATION = '24';
  string public constant INVALID_BIDDER = '25';
  string public constant PAUSED = '26';
  string public constant NOT_ADMIN = '27';
  string public constant INVALID_INIT_PARAMS = '28';
  string public constant TOO_MANY_DISTRIBUTIONS = '29';
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

abstract contract InitUpgradeable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  uint256 private lastInitializedRevision = 0;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    uint256 revision = getRevision();
    require(
      initializing || isConstructor() || revision > lastInitializedRevision,
      'Contract instance has already been initialized'
    );

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      lastInitializedRevision = revision;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /**
   * @dev returns the revision number of the contract
   * Needs to be defined in the inherited class as a constant.
   **/
  function getRevision() internal pure virtual returns (uint256);

  /**
   * @dev Returns true if and only if the function is running in the constructor
   **/
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    //solium-disable-next-line
    assembly {
      cs := extcodesize(address())
    }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import {Errors} from '../libraries/Errors.sol';

contract AdminPausableUpgradeSafe {
    address internal _admin;
    bool internal _paused;
    
    /**
     * @notice Emitted when the contract is paused.
     * 
     * @param admin The current administrator address.
     */
    event Paused(address admin);

    /**
     * @notice Emitted when the contract is unpaused.
     *
     * @param admin The current administrator address.
     */
    event Unpaused(address admin);

    /**
     * @notice Emitted when the admin is set to a different address.
     * 
     * @param to The address of the new administrator. 
     */
    event AdminChanged(address to);

    /**
     * @dev Modifier to only allow functions to be called when not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, Errors.PAUSED);
        _;
    }

    /**
     * @dev Modifier to only allow the admin as the caller.
     */
    modifier onlyAdmin() {
        require(msg.sender == _admin, Errors.NOT_ADMIN);
        _;
    }

    /**
     * @dev Admin function pauses the contract.
     */
    function pause() external onlyAdmin {
        _paused = true;
        emit Paused(_admin);
    }

    /**
     * @dev Admin function unpauses the contract.
     */
    function unpause() external onlyAdmin {
        _paused = false;
        emit Unpaused(_admin);
    }

    /**
     * @dev Admin function that changes the administrator.
     */
    function changeAdmin(address to) external onlyAdmin {
        _admin = to;
        emit AdminChanged(to);
    }

    /**
     * @dev View function that returns the current admin.
     */
    function getAdmin() external view returns (address) {
        return _admin;
    }
}

