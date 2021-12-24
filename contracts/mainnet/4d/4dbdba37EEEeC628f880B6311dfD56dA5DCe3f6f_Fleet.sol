// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


import "./interfaces/IPnG.sol";
import "./interfaces/ICACAO.sol";
import "./interfaces/IFleet.sol";
import "./interfaces/IRandomizer.sol";

import "./utils/Accessable.sol";


contract Fleet is IFleet, Accessable, ReentrancyGuard, IERC721Receiver, Pausable {
    uint8[4] private _ranks = [5,6,7,8];
    
    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    uint256 private totalRankStaked;
    uint256 private numGalleonsStaked;

    event TokenStaked(address indexed owner, uint256 indexed tokenId, bool indexed isGalleon, uint256 value);
    event GalleonClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event PirateClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);

    IPnG public nftContract;
    // reference to the WnD NFT contract
    address public pirateGame;
    // reference to the $CACAO contract for minting $CACAO earnings
    ICACAO public cacao;
    // reference to Randomer 
    IRandomizer public randomizer;

    // maps tokenId to stake
    mapping(uint256 => Stake) private fleet; 
    // maps rank to all Pirate staked with that rank
    mapping(uint256 => Stake[]) private sea; 
    // tracks location of each Pirate in Sea
    mapping(uint256 => uint256) private seaIndices; 
    // any rewards distributed when no pirates are staked
    uint256 private unaccountedRewards = 0; 
    // amount of $CACAO due for each rank point staked
    uint256 private cacaoPerRank = 0; 


    // galleons earn 10000 $CACAO per day
    uint256 public constant DAILY_CACAO_RATE = 10000 ether;
    // pirates take a 20% tax on all $CACAO claimed
    uint256 public constant CACAO_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 2.4 billion $CACAO earned through staking
    uint256 public constant MAXIMUM_GLOBAL_CACAO = 2400000000 ether;

    // // galleons must have 2 days worth of $CACAO to unstake or else they're still in the sea
    uint256 public minimumToExit = 2 days;
    uint256 public minimumToClaim = 2 days;


    

    // amount of $CACAO earned so far
    uint256 public totalCacaoEarned;
    // the last time $CACAO was claimed
    uint256 private lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $CACAO
    bool public rescueEnabled = false;

    /**
     */
    constructor() {
        _pause();
    }

    /** CRITICAL TO SETUP */

    modifier requireContractsSet() {
            require(address(nftContract) != address(0) && address(cacao) != address(0) 
                && address(pirateGame) != address(0) && address(randomizer) != address(0), "Contracts not set");
            _;
    }

    function setContracts(address _cacao, address _nft, address _pirateGame, address _rand) external onlyAdmin {
        nftContract = IPnG(_nft);
        cacao = ICACAO(_cacao);
        pirateGame = _pirateGame;
        randomizer = IRandomizer(_rand);
    }


    /** STAKING */

    /**
     * adds Galleons and Pirates to the Fleet and Sea
     * @param account the address of the staker
     * @param tokenIds the IDs of the Galleons and Pirates to stake
     */
    function addManyToFleet(address account, uint16[] calldata tokenIds) external override 
        nonReentrant 
        onlyEOA
    {
        require(account == tx.origin, "account to sender mismatch");
        for (uint i = 0; i < tokenIds.length; i++) {
            if (_msgSender() != address(pirateGame)) { // dont do this step if its a mint + stake
                require(nftContract.ownerOf(tokenIds[i]) == _msgSender(), "You don't own this token");
                nftContract.transferFrom(_msgSender(), address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }

            if (nftContract.isGalleon(tokenIds[i])) 
                _addGalleonToFleet(account, tokenIds[i]);
            else 
                _addPirateToSea(account, tokenIds[i]);
        } 
    }

    /**
     * adds a single Galleon to the Fleet
     * @param account the address of the staker
     * @param tokenId the ID of the Galleon to add to the Fleet
     */
    function _addGalleonToFleet(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
        fleet[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });
        numGalleonsStaked += 1;
        emit TokenStaked(account, tokenId, true, block.timestamp);
    }

    /**
     * adds a single Pirate to the Sea
     * @param account the address of the staker
     * @param tokenId the ID of the Pirate to add to the Sea
     */
    function _addPirateToSea(address account, uint256 tokenId) internal {
        uint8 rank = _rankForPirate(tokenId);
        totalRankStaked += rank; // Portion of earnings ranges from 8 to 5
        seaIndices[tokenId] = sea[rank].length; // Store the location of the pirate in the Sea
        sea[rank].push(Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(cacaoPerRank)
        })); // Add the pirate to the Sea
        emit TokenStaked(account, tokenId, false, cacaoPerRank);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $CACAO earnings and optionally unstake tokens from the Fleet / Sea
     * to unstake a Galleon it will require it has 2 days worth of $CACAO unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimManyFromFleetAndSea(uint16[] calldata tokenIds, bool unstake) external 
        whenNotPaused 
        _updateEarnings 
        nonReentrant 
        onlyEOA
    {
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (nftContract.isGalleon(tokenIds[i])) {
                owed += _claimGalleonFromFleet(tokenIds[i], unstake);
            }
            else {
                owed += _claimPirateFromSea(tokenIds[i], unstake);
            }
        }
        cacao.updateInblockGuard();
        if (owed == 0) {
            return;
        }
        cacao.mint(_msgSender(), owed);
    }

    function calculateRewards(uint256 tokenId) external view returns (uint256 owed) {
        uint64 lastTokenWrite = nftContract.getTokenWriteBlock(tokenId);
        // Must check this, as getTokenTraits will be allowed since this contract is an admin
        require(lastTokenWrite < block.number, "hmmmm what doing?");

        Stake memory stake = fleet[tokenId];
        if (stake.owner == address(0) && stake.value == 0) {
            return 0;
        }

        if(nftContract.isGalleon(tokenId)) {
            if (totalCacaoEarned < MAXIMUM_GLOBAL_CACAO) {
                owed = (block.timestamp - stake.value) * DAILY_CACAO_RATE / 1 days;
            } else if (stake.value > lastClaimTimestamp) {
                owed = 0; // $CACAO production stopped already
            } else {
                owed = (lastClaimTimestamp - stake.value) * DAILY_CACAO_RATE / 1 days; // stop earning additional $CACAO if it's all been earned
            }
        }
        else {
            uint8 rank = _rankForPirate(tokenId);
            owed = (rank) * (cacaoPerRank - stake.value); // Calculate portion of tokens based on Rank
        }
    }

    function calculatePirateReward(uint256 tokenId) external view returns (uint256 owed) {
        require(!nftContract.isGalleon(tokenId), "Not Pirate");
        uint8 rank = _rankForPirate(tokenId);
        Stake memory stake = sea[rank][seaIndices[tokenId]];
        if (stake.owner == address(0) && stake.value == 0) {
            return 0;
        }
        owed = (rank) * (cacaoPerRank - stake.value);            // Calculate portion of tokens based on Rank
    }

    /**
     * realize $CACAO earnings for a single Galleon and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Pirates
     * if unstaking, there is a 50% chance all $CACAO is stolen
     * @param tokenId the ID of the Galleons to claim earnings from
     * @param unstake whether or not to unstake the Galleons
     * @return owed - the amount of $CACAO earned
     */
    function _claimGalleonFromFleet(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        Stake memory stake = fleet[tokenId];
        require(stake.owner == _msgSender(), "Don't own the given token");
        require(block.timestamp - stake.value > minimumToClaim, "Claiming: Still in the sea");
        require(!(unstake && block.timestamp - stake.value < minimumToExit), "Witdraw: Still in the sea");

        if (unstake) {
            require(randomizer.canOperate(_msgSender(), tokenId), "Randomizer: cannot operate");
        }

        if (totalCacaoEarned < MAXIMUM_GLOBAL_CACAO) {
            owed = (block.timestamp - stake.value) * DAILY_CACAO_RATE / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $CACAO production stopped already
        } else {
            owed = (lastClaimTimestamp - stake.value) * DAILY_CACAO_RATE / 1 days; // stop earning additional $CACAO if it's all been earned
        }
        if (unstake) {
            if (randomizer.random(tokenId) & 1 == 1) { // 50% chance of all $CACAO stolen
                _payPirateTax(owed);
                owed = 0;
            }
            delete fleet[tokenId];
            numGalleonsStaked -= 1;
            // Always transfer last to guard against reentrance
            nftContract.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Galleon
        } else {
            _payPirateTax(owed * CACAO_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked pirates
            owed = owed * (100 - CACAO_CLAIM_TAX_PERCENTAGE) / 100; // remainder goes to Galleon owner
            fleet[tokenId] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp)
            }); // reset stake
        }
        emit GalleonClaimed(tokenId, unstake, owed);
    }

    /**
     * realize $CACAO earnings for a single Pirate and optionally unstake it
     * Pirates earn $CACAO proportional to their rank
     * @param tokenId the ID of the Pirate to claim earnings from
     * @param unstake whether or not to unstake the Pirate
     * @return owed - the amount of $CACAO earned
     */
    function _claimPirateFromSea(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        require(nftContract.ownerOf(tokenId) == address(this), "Doesn't own token");
        uint8 rank = _rankForPirate(tokenId);
        Stake memory stake = sea[rank][seaIndices[tokenId]];
        require(stake.owner == _msgSender(), "Doesn't own token");
        owed = (rank) * (cacaoPerRank - stake.value); // Calculate portion of tokens based on Rank
        if (unstake) {
            totalRankStaked -= rank; // Remove rank from total staked
            Stake memory lastStake = sea[rank][sea[rank].length - 1];
            sea[rank][seaIndices[tokenId]] = lastStake; // Shuffle last Pirate to current position
            seaIndices[lastStake.tokenId] = seaIndices[tokenId];
            sea[rank].pop(); // Remove duplicate
            delete seaIndices[tokenId]; // Delete old mapping
            // Always remove last to guard against reentrance
            nftContract.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Pirate
        } else {
            sea[rank][seaIndices[tokenId]] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(cacaoPerRank)
            }); // reset stake
        }
        emit PirateClaimed(tokenId, unstake, owed);
    }
    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    function rescue(uint256[] calldata tokenIds) external nonReentrant {
        require(rescueEnabled, "RESCUE DISABLED");
        uint256 tokenId;
        Stake memory stake;
        Stake memory lastStake;
        uint8 rank;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (nftContract.isGalleon(tokenId)) {
                stake = fleet[tokenId];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                delete fleet[tokenId];
                numGalleonsStaked -= 1;
                nftContract.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Galleons
                emit GalleonClaimed(tokenId, true, 0);
            } else {
                rank = _rankForPirate(tokenId);
                stake = sea[rank][seaIndices[tokenId]];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                totalRankStaked -= rank; // Remove Rank from total staked
                lastStake = sea[rank][sea[rank].length - 1];
                sea[rank][seaIndices[tokenId]] = lastStake; // Shuffle last Pirate to current position
                seaIndices[lastStake.tokenId] = seaIndices[tokenId];
                sea[rank].pop(); // Remove duplicate
                delete seaIndices[tokenId]; // Delete old mapping
                nftContract.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Pirate
                emit PirateClaimed(tokenId, true, 0);
            }
        }
    }

    /** ACCOUNTING */

    /** 
     * add $CACAO to claimable pot for the Sea
     * @param amount $CACAO to add to the pot
     */
    function _payPirateTax(uint256 amount) internal {
        if (totalRankStaked == 0) { // if there's no staked pirates
            unaccountedRewards += amount; // keep track of $CACAO due to pirates
            return;
        }
        // makes sure to include any unaccounted $CACAO 
        cacaoPerRank += (amount + unaccountedRewards) / totalRankStaked;
        unaccountedRewards = 0;
    }

    /**
     * tracks $CACAO earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalCacaoEarned < MAXIMUM_GLOBAL_CACAO) {
            totalCacaoEarned += 
                (block.timestamp - lastClaimTimestamp)
                * numGalleonsStaked
                * DAILY_CACAO_RATE / 1 days; 
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    /** ADMIN */

    /**
     * allows owner to enable "rescue mode"
     * simplifies accounting, prioritizes tokens out in emergency
     */
    function _setRescueEnabled(bool _enabled) external onlyAdmin {
        rescueEnabled = _enabled;
    }

    /**
     * enables owner to pause / unpause contract
     */
    function setPaused(bool _paused) external requireContractsSet onlyAdmin {
        if (_paused) _pause();
        else _unpause();
    }

    function _setRanks(uint8[4] memory ranks) external onlyAdmin {
        _ranks = ranks;
    }

    function _setTimeRestrictions(uint256 _toClaim, uint256 _toExit) external onlyAdmin {
        minimumToClaim = _toClaim;
        minimumToExit = _toExit;
    }



    /** READ ONLY */

    /**
     * gets the rank score for a Pirate
     * @param tokenId the ID of the Pirate to get the rank score for
     * @return the rank score of the Pirate (5-8)
     */
    function _rankForPirate(uint256 tokenId) internal view returns (uint8) {
        IPnG.GalleonPirate memory s = nftContract.getTokenTraits(tokenId);
        return _ranks[s.alphaIndex]; // rank index is 0-3
    }

    /**
     * chooses a random Pirate thief when a newly minted token is stolen
     * @param seed a random value to choose a Pirate from
     * @return the owner of the randomly selected Pirate thief
     */
    function randomPirateOwner(uint256 seed) external view override returns (address) {
        if (totalRankStaked == 0) {
            return address(0x0);
        }
        uint256 bucket = (seed & 0xFFFFFFFF) % totalRankStaked; // choose a value from 0 to total rank staked
        uint256 cumulative;
        seed >>= 32;
        uint8 rank;
        // loop through each bucket of Pirates with the same rank score
        for (uint8 j = 0; j < _ranks.length; j++) {
            rank = _ranks[j];
            cumulative += sea[rank].length * rank;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Pirate with that rank score
            return sea[rank][seed % sea[rank].length].owner;
        }
        return address(0x0);
    }

    function onERC721Received(address,address from,uint256,bytes calldata) 
        external pure override 
        returns (bytes4) 
    {
        require(from == address(0x0), "Cannot send to Fleet directly");
        return IERC721Receiver.onERC721Received.selector;
    }


    /**
     * allows owner to withdraw funds
     */
    function _withdraw() external onlyTokenClaimer {
        payable(_msgSender()).transfer(address(this).balance);
    }


    modifier onlyEOA {
        require(tx.origin == _msgSender() || _msgSender() == address(pirateGame), "Only EOA");
        _;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";


contract Owned is Context {
    address private _contractOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() { 
        _contractOwner = payable(_msgSender()); 
    }

    function owner() public view virtual returns(address) {
        return _contractOwner;
    }

    function _transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Owned: Address can not be 0x0");
        __transferOwnership(newOwner);
    }


    function _renounceOwnership() external virtual onlyOwner {
        __transferOwnership(address(0));
    }

    function __transferOwnership(address _to) internal {
        emit OwnershipTransferred(owner(), _to);
        _contractOwner = _to;
    }


    modifier onlyOwner() {
        require(_msgSender() == _contractOwner, "Owned: Only owner can operate");
        _;
    }
}



contract Accessable is Owned {
    mapping(address => bool) private _admins;
    mapping(address => bool) private _tokenClaimers;

    constructor() {
        _admins[_msgSender()] = true;
        _tokenClaimers[_msgSender()] = true;
    }

    function isAdmin(address user) public view returns(bool) {
        return _admins[user];
    }

    function isTokenClaimer(address user) public view returns(bool) {
        return _tokenClaimers[user];
    }


    function _setAdmin(address _user, bool _isAdmin) external onlyOwner {
        _admins[_user] = _isAdmin;
        require( _admins[owner()], "Accessable: Contract owner must be an admin" );
    }

    function _setTokenClaimer(address _user, bool _isTokenCalimer) external onlyOwner {
        _tokenClaimers[_user] = _isTokenCalimer;
        require( _tokenClaimers[owner()], "Accessable: Contract owner must be an token claimer" );
    }


    modifier onlyAdmin() {
        require(_admins[_msgSender()], "Accessable: Only admin can operate");
        _;
    }

    modifier onlyTokenClaimer() {
        require(_tokenClaimers[_msgSender()], "Accessable: Only Token Claimer can operate");
        _;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    function random(uint256) external returns (uint256);

    function canOperate(address addr, uint256 tokenId) external returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPnG is IERC721 {

    struct GalleonPirate {
        bool isGalleon;

        // Galleon traits
        uint8 base;
        uint8 deck;
        uint8 sails;
        uint8 crowsNest;
        uint8 decor;
        uint8 flags;
        uint8 bowsprit;

        // Pirate traits
        uint8 skin;
        uint8 clothes;
        uint8 hair;
        uint8 earrings;
        uint8 mouth;
        uint8 eyes;
        uint8 weapon;
        uint8 hat;
        uint8 alphaIndex;
    }


    function updateOriginAccess(uint16[] memory tokenIds) external;

    function totalSupply() external view returns(uint256);

    function mint(address recipient, uint256 seed) external;
    function burn(uint256 tokenId) external;
    function minted() external view returns (uint16);

    function getMaxTokens() external view returns (uint256);
    function getPaidTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (GalleonPirate memory);
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function isGalleon(uint256 tokenId) external view returns(bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;


interface IInblockGuard {
    function updateInblockGuard() external;
}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface IFleet {
    function addManyToFleet(address account, uint16[] calldata tokenIds) external;
    function randomPirateOwner(uint256 seed) external view returns (address);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IInblockGuard.sol";


interface ICACAO is IInblockGuard {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}