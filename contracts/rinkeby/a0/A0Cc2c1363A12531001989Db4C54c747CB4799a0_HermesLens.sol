// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IgOHM is IERC20 {
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
    function index() external view returns (uint256);
    function balanceFrom(uint256 _amount) external view returns (uint256);
    function balanceTo(uint256 _amount) external view returns (uint256);
    function migrate( address _staking, address _sOHM ) external;
}

interface IsOHM is IERC20 {
    function rebase( uint256 ohmProfit_, uint epoch_) external returns (uint256);
    function circulatingSupply() external view returns (uint256);
    function gonsForBalance( uint amount ) external view returns ( uint );
    function balanceForGons( uint gons ) external view returns ( uint );
    function index() external view returns ( uint );
    function toG(uint amount) external view returns (uint);
    function fromG(uint amount) external view returns (uint);
    function changeDebt(
        uint256 amount,
        address debtor,
        bool add
    ) external;
    function debtBalances(address _address) external view returns (uint256);
}

interface IBondingCalculator {
    function markdown( address _LP ) external view returns ( uint );
    function valuation( address pair_, uint amount_ ) external view returns ( uint _value );
}


interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256);
    function claim(address _recipient, bool _rebasing) external returns (uint256);
    function forfeit() external returns (uint256);
    function toggleLock() external;
    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);
    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);
    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);
    function rebase() external;
    function index() external view returns (uint256);
    function contractBalance() external view returns (uint256);
    function totalStaked() external view returns (uint256);
    function supplyInWarmup() external view returns (uint256);
}

interface IDepository {
    struct Bond {
        IERC20 principal; // token to accept as payment
        address calculator; // contract to value principal
        Terms terms; // terms of bond
        bool termsSet; // have terms been set
        uint256 capacity; // capacity remaining
        bool capacityIsPayout; // capacity limit is for payout vs principal
        uint256 totalDebt; // total debt from bond
        uint256 lastDecay; // last block when debt was decayed
    }

    struct Terms {
        uint256 controlVariable; // scaling variable for price
        bool fixedTerm; // fixed term or fixed expiration
        uint256 vestingTerm; // term in blocks (fixed-term)
        uint256 expiration; // block number bond matures (fixed-expiration)
        uint256 conclusion; // block number bond no longer offered
        uint256 minimumPrice; // vs principal value
        uint256 maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint256 maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    }


    function bonds(uint256 _BID) external view returns(Bond memory bond);

    function deposit(
        uint256 _amount,
        uint256 _maxPrice,
        address _depositor,
        uint256 _BID,
        address _feo
    ) external returns(uint256 payout, uint256 index);
}

interface ITeller {
    struct Bond {
        address principal;
        uint256 principalPaid;
        uint256 payout;
        uint256 vested;
        uint256 created;
        uint256 redeemed;
    }

    function bonderInfo(address _bonder, uint256 _index) external view returns(Bond memory bond);
    function newBond( 
        address _bonder, 
        address _principal,
        uint _principalPaid,
        uint _payout, 
        uint _expires,
        address _feo
    ) external returns ( uint index_ );
    function redeemAll(address _bonder) external returns (uint256);
    function redeem(address _bonder, uint256[] memory _indexes) external returns (uint256);
    function getReward() external;
    function setFEReward(uint256 reward) external;
    function updateIndexesFor(address _bonder) external;
    function pendingFor(address _bonder, uint256 _index) external view returns (uint256);
    function pendingForIndexes(address _bonder, uint256[] memory _indexes) external view returns (uint256 pending_);
    function totalPendingFor(address _bonder) external view returns (uint256 pending_);
    function percentVestedFor(address _bonder, uint256 _index) external view returns (uint256 percentVested_);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IHermesLens {
    struct Round {
        uint256 roundId;

        // Target gOHM amount for ending the round.
        uint256 targetAmount;

        // Accumulated gOHM amount for the round.
        uint256 accumulatedAmount;

        uint256 totalPlayerCount;

        // The block number that the round ends. 0 if the round does not end yet.
        uint256 endBlockNumber;

        // The winner address of the round. "" if the round does not end yet.
        address winnerAddress;
    }

    struct Win {
        uint256 roundId;

        // The winner's address.
        address winner;

        // gOHM amount that wins.
        uint256 amount;

        // Whether the winner has claimed or not.
        bool claimed;
    }

    struct ParticipatedRound {
        uint256 roundId;

        // Total bond payouts in gOHM during the round.
        uint256 bondPayout;
    }

    struct Nft {
        uint256 tokenId;

        string imageUrl;

        // The block number when the NFT was created.
        uint256 createdBlock;

        // The block number when the bond will be/was vested.
        uint256 vestedBlock;

        // The payout in gOHM.
        uint256 payout;
    }
    
    // Returns the current going round.
    function getCurrentRound() external view returns (Round memory);

    // Returns a round.
    function getRound(uint256 roundId) external view returns (Round memory);

    function getWins() external view returns (Win[] memory);

    // Returns rounds that the address participated.
    function getParticipatedRounds(address addr) external view returns(ParticipatedRound[] memory);

    function getNft(uint256 tokenId) external view returns (Nft memory);

    function getNfts(address addr) external view returns (Nft[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IHermesLotteryPeriphery {
    struct Round {
        bytes32 tree;
        uint256 totalPayout;
        uint256 totalParticipants;
        uint256 endThreshold;
        uint256 baseAmount;
        uint256 endBlockNumber;
        address winner;
        bool claimed;
    }
    event NewRound(uint256 indexed round);
    event EndRound(uint256 indexed round);
    event Winner(uint256 indexed round, address indexed winner);
    event LotteryParamChanged(uint256 threshold, uint256 baseamount);
    event EnterRound(uint256 indexed round, address indexed participant, uint256 tickets);

    function currentRound() external view returns(uint256 id);
    function roundInfo(uint256 _round) external view returns(Round memory);
    function lotteryTickets(uint256 _round, address _owner) external view returns(uint256 tickets);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IHermesNFT {
    /// @notice emmited when user is trying to claim the bond twice
    /// @param nftId nft id user is trying to claim
    /// @param claimedAt unixTimestamp when nft was claimed before
    error AlreadyClaimed(uint256 nftId, uint64 claimedAt);

    /// @notice function to buy olympus v2 bonds
    /// @dev should transfer principal token before calling this function
    /// @param _depositor address 
    /// @param _maxPrice maximum price input to save user from being front ran hardly
    /// @param _BID id of bond, get detail from bondDepository.bonds(_BID)
    /// @return payout amount of sOHM that will be paid after bond ends
    /// @return nftId nftId equals to indexId of bonds owned by address(this), get details in bondTeller.bonderInfo(address(this), nftId)
    function deposit(
        address _depositor,
        uint256 _maxPrice,
        uint256 _BID
    ) external returns(uint256 payout, uint256 nftId);

    /// @notice function to claim redeemed sOHM
    /// @dev bondTeller.redeem() can be called by anyone. claimed sOHM will be sent to msg.sender
    /// @param _nftIds nft ids to claim the sOHM, should be owned or approved to msg.sender
    /// @return claimed total amount of sOHM claimed
    function claim(
        uint256[] calldata _nftIds
    ) external returns(uint256 claimed);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import { IHermesLens } from "../interfaces/IHermesLens.sol";
import { IHermesLotteryPeriphery } from "../interfaces/IHermesLotteryPeriphery.sol";
import { IHermesNFT } from "../interfaces/IHermesNFT.sol";
import { ITeller, IgOHM } from "../external/OlympusV2Interfaces.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
contract HermesLens is IHermesLens {
    IHermesLotteryPeriphery public immutable lottery;
    IHermesNFT public immutable nft;
    ITeller public immutable teller;
    IgOHM public immutable gOHM;

    constructor(IHermesLotteryPeriphery _lottery, IHermesNFT _nft, ITeller _teller, IgOHM _gOHM) {
        lottery = _lottery;
        nft = _nft;
        teller = _teller;
        gOHM = _gOHM;
    }

    // Returns the current going round.
    function getCurrentRound() public view returns (Round memory) {
        uint256 id = lottery.currentRound();
        IHermesLotteryPeriphery.Round memory round  = lottery.roundInfo(id);

        return Round({
            roundId: id,
            targetAmount: round.endThreshold,
            accumulatedAmount: gOHM.balanceOf(address(lottery)),
            totalPlayerCount: round.totalParticipants,
            endBlockNumber: round.endBlockNumber,
            winnerAddress: round.winner
        });
    }

    // Returns a round.
    function getRound(uint256 _roundId) public view returns (Round memory) {
        uint256 id = lottery.currentRound();
        IHermesLotteryPeriphery.Round memory round  = lottery.roundInfo(id);
        uint256 accumulated = round.endThreshold;
        if(id == _roundId) {
            accumulated = gOHM.balanceOf(address(lottery));
        }
        return Round({
            roundId: id,
            targetAmount: round.endThreshold,
            accumulatedAmount: accumulated,
            totalPlayerCount: round.totalParticipants,
            endBlockNumber: round.endBlockNumber,
            winnerAddress: round.winner
        });
    }

    function getWins() public view returns (Win[] memory) {
        uint256 currentId = lottery.currentRound();
        Win[] memory wins = new Win[](currentId - 1);
        for(uint256 i = 0; i<currentId - 1; i++){
            IHermesLotteryPeriphery.Round memory round  = lottery.roundInfo(i);
            wins[i] = Win({
                roundId:i,
                winner: round.winner,
                amount: round.endThreshold,
                claimed: round.claimed
            });
        }
        return wins;
    }

    function getParticipatedRounds(address _addr) public view returns (ParticipatedRound[] memory) {
        uint256 currentId = lottery.currentRound();
        ParticipatedRound[] memory rounds = new ParticipatedRound[](currentId);
        for(uint256 i = 0; i<currentId; i++){
            uint256 tickets = lottery.lotteryTickets(i, _addr);
            if(tickets == 0) {
                continue;
            }
            IHermesLotteryPeriphery.Round memory round = lottery.roundInfo(i);
            rounds[i] = ParticipatedRound({
                roundId : i,
                bondPayout: round.baseAmount * tickets
            });
        }
        return rounds;
    }

    function getNft(uint256 _tokenId) public view override returns(Nft memory) {
        return Nft({
            tokenId : _tokenId,
            imageUrl : IERC721Metadata(address(nft)).tokenURI(_tokenId),
            createdBlock : teller.bonderInfo(address(nft), _tokenId).created,
            vestedBlock : teller.bonderInfo(address(nft), _tokenId).vested,
            payout : teller.bonderInfo(address(nft), _tokenId).payout
        });
    }

    function getNfts(address _addr) external view returns(Nft[] memory) {
        uint256 balance = IERC721Enumerable(address(nft)).balanceOf(_addr);
        Nft[] memory nfts = new Nft[](balance);
        for(uint256 i = 0; i<balance; i++){
            nfts[i] = getNft(IERC721Enumerable(address(nft)).tokenOfOwnerByIndex(_addr, i));
        }
        return nfts;
    }
}