// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


import "./interfaces/IFleet.sol";
import "./interfaces/ICACAO.sol";
import "./interfaces/IPnG.sol";

import "./utils/Accessable.sol";
import "./utils/Wnitelist.sol";


contract PirateGame is Accessable, Whitelist, ReentrancyGuard, Pausable {

    event MintCommitted(address indexed owner, uint256 indexed amount);
    event MintRevealed(address indexed owner, uint256 indexed amount);

    //$CACAO cost 
    uint256[3] private _cacaoCost = [20000 ether, 40000 ether, 80000 ether];
    uint16 public maxBunchSize = 10;

    bool public allowCommits = true;

    bool public isWhitelistSale = true;
    bool public isPublicSale = false;
    uint256 public presalePrice = 0.06 ether;
    uint256 public treasureChestTypeId;


    uint256 public startedTime = 0;

    uint256 private maxPrice = 0.3266 ether;
    uint256 private minPrice = 0.0666 ether;
    uint256 private priceDecrementAmt = 0.01 ether;
    uint256 private timeToDecrementPrice = 30 minutes;



    mapping(address => uint16) public whitelistMinted;
    uint16 public whitelistAmountPerUser = 5;

    struct MintCommit {
        bool exist;
        uint16 amount;
        uint256 blockNumber;
        bool stake;
    }
    mapping(address => MintCommit) private _mintCommits;
    uint16 private _commitsAmount;

    struct MintCommitReturn {
        bool exist;
        bool notExpired;
        bool nextBlockReached;
        uint16 amount;
        uint256 blockNumber;
        bool stake;
    }


    IFleet public fleet;
    ICACAO public cacao;
    IPnG public nftContract;



    constructor() {
        _pause();
    }

    /** CRITICAL TO SETUP */

    function setContracts(address _cacao, address _nft, address _fleet) external onlyAdmin {
        cacao = ICACAO(_cacao);
        nftContract = IPnG(_nft);
        fleet = IFleet(_fleet);
    }



    function currentEthPriceToMint() view public returns(uint256) {        
        uint16 minted = nftContract.minted();
        uint256 paidTokens = nftContract.getPaidTokens();

        if (minted >= paidTokens) {
            return 0;
        }
        
        uint256 numDecrements = (block.timestamp - startedTime) / timeToDecrementPrice;
        uint256 decrementAmt = (priceDecrementAmt * numDecrements);
        if(decrementAmt > maxPrice) {
            return minPrice;
        }
        uint256 adjPrice = maxPrice - decrementAmt;
        return adjPrice;
    }

    function whitelistPrice() view public returns(uint256) {
        uint16 minted = nftContract.minted();
        uint256 paidTokens = nftContract.getPaidTokens();

        if (minted >= paidTokens) {
            return 0;
        }
        return presalePrice;
    }


    function avaliableWhitelistTokens(address user, bytes32[] memory whitelistProof) external view returns (uint256) {
        if (!inWhitelist(user, whitelistProof) || !isWhitelistSale)
            return 0;
        return whitelistAmountPerUser - whitelistMinted[user];
    }


    function mintCommitWhitelist(uint16 amount, bool isStake, bytes32[] memory whitelistProof) 
        external payable
        nonReentrant
        publicSaleStarted
    {   
        require(isWhitelistSale, "Whitelist sale disabled");
        require(whitelistMinted[_msgSender()] + amount <= whitelistAmountPerUser, "Too many mints");
        require(inWhitelist(_msgSender(), whitelistProof), "Not in whitelist");
        whitelistMinted[_msgSender()] += amount;
        return _commit(amount, isStake, presalePrice);
    }

    function mintCommit(uint16 amount, bool isStake) 
        external payable 
        nonReentrant
        publicSaleStarted
    {
        return _commit(amount, isStake, currentEthPriceToMint());
    }

    function _mintCommitAirdrop(uint16 amount) 
        external payable 
        nonReentrant
        onlyAdmin
    {
        return _commit(amount, false, 0);
    }


    function _commit(uint16 amount, bool isStake, uint256 price) internal
        whenNotPaused 
        onlyEOA
        commitsEnabled
    {
        require(amount > 0 && amount <= maxBunchSize, "Invalid mint amount");
        require( !_hasCommits(_msgSender()), "Already have commit");

        uint16 minted = nftContract.minted() + _commitsAmount;
        uint256 maxTokens = nftContract.getMaxTokens();
        require( minted + amount <= maxTokens, "All tokens minted");

        uint256 paidTokens = nftContract.getPaidTokens();

        if (minted < paidTokens) {
            require(minted + amount <= paidTokens, "All tokens on-sale already sold");
            uint256 price_ = amount * price;
            require(msg.value >= price_, "Invalid payment amount");

            if (msg.value > price_) {
                payable(_msgSender()).transfer(msg.value - price_);
            }
        } 
        else {
            require(msg.value == 0, "");
            uint256 totalCacaoCost = 0;
             // YCDB
            for (uint16 i = 1; i <= amount; i++) {
                totalCacaoCost += mintCost(minted + i, maxTokens);
            }
            if (totalCacaoCost > 0) {
                cacao.burn(_msgSender(), totalCacaoCost);
                cacao.updateInblockGuard();
            }           
        }

        _mintCommits[_msgSender()] = MintCommit(true, amount, block.number, isStake);
        _commitsAmount += amount;
        emit MintCommitted(_msgSender(), amount);
    }


    function mintReveal() external 
        whenNotPaused 
        nonReentrant 
        onlyEOA
    {
        return reveal(_msgSender());
    }

    function _mintRevealAirdrop(address _to)  external
        whenNotPaused 
        nonReentrant
        onlyAdmin
        onlyEOA
    {
        return reveal(_to);
    }


    function reveal(address addr) internal {
        require(_hasCommits(addr), "No pending commit");
        uint16 minted = nftContract.minted();
        uint256 paidTokens = nftContract.getPaidTokens();
        MintCommit memory commit = _mintCommits[addr];

        uint16[] memory tokenIds = new uint16[](commit.amount);
        uint16[] memory tokenIdsToStake = new uint16[](commit.amount);

        uint256 seed = uint256(blockhash(commit.blockNumber));
        for (uint k = 0; k < commit.amount; k++) {
            minted++;
            // scramble the random so the steal / treasure mechanic are different per mint
            seed = uint256(keccak256(abi.encode(seed, addr)));
            address recipient = selectRecipient(seed, minted, paidTokens);
            tokenIds[k] = minted;
            if (!commit.stake || recipient != addr) {
                nftContract.mint(recipient, seed);
            } else {
                nftContract.mint(address(fleet), seed);
                tokenIdsToStake[k] = minted;
            }
        }
        // nftContract.updateOriginAccess(tokenIds);
        if(commit.stake) {
            fleet.addManyToFleet(addr, tokenIdsToStake);
        }

        _commitsAmount -= commit.amount;
        delete _mintCommits[addr];
        emit MintRevealed(addr, tokenIds.length);
    }



    /** 
     * @param tokenId the ID to check the cost of to mint
     * @return the cost of the given token ID
     */
    function mintCost(uint256 tokenId, uint256 maxTokens) public view returns (uint256) {
        if (tokenId <= nftContract.getPaidTokens()) return 0;
        if (tokenId <= maxTokens * 2 / 5) return _cacaoCost[0];
        if (tokenId <= maxTokens * 4 / 5) return _cacaoCost[1];
        return _cacaoCost[2];
    }





    /** ADMIN */

    function _setPaused(bool _paused) external requireContractsSet onlyAdmin {
        if (_paused) _pause();
        else _unpause();
    }

    function _setCacaoCost(uint256[3] memory costs) external onlyAdmin {
        _cacaoCost = costs;
    }

    function _setAllowCommits(bool allowed) external onlyAdmin {
        allowCommits = allowed;
    }

    function _setPublicSaleStart(bool started) external onlyAdmin {
        isPublicSale = started;
        if(isPublicSale) {
            startedTime = block.timestamp;
        }
    }

    function setWhitelistSale(bool isSale) external onlyAdmin {
        isWhitelistSale = isSale;
    }

    function _setMaxBunchSize(uint16 size) external onlyAdmin {
        maxBunchSize = size;
    }

    function _setWhitelistAmountPerUser(uint16 amount) external onlyAdmin {
        whitelistAmountPerUser = amount;
    }

    function _cancelCommit(address user) external onlyAdmin {
        _commitsAmount -= _mintCommits[user].amount;
        delete _mintCommits[user];
    }



    /************************************* */


    /**
     * the first 20% (ETH purchases) go to the minter
     * the remaining 80% have a 10% chance to be given to a random staked pirate
     * @param seed a random value to select a recipient from
     * @return the address of the recipient (either the minter or the Pirate thief's owner)
     */
    function selectRecipient(uint256 seed, uint256 minted, uint256 paidTokens) internal view returns (address) { //TODO
        if (minted <= paidTokens || ((seed >> 245) % 10) != 0) // top 10 bits haven't been used
            return _msgSender(); 

        address thief = address(fleet) == address(0) ? address(0) : fleet.randomPirateOwner(seed >> 144); // 144 bits reserved for trait selection
        if (thief == address(0)) 
            return _msgSender();
        else
            return thief;
    }



    /**----------------------------- */

    function getTotalPendingCommits() external view returns (uint256) {
        return _commitsAmount;
    }

    function getCommit(address addr) external view returns (MintCommitReturn memory) {
        MintCommit memory m = _mintCommits[addr];
        (bool ex, bool ne, bool nb) = _commitStatus(m);
        return MintCommitReturn(ex, ne, nb, m.amount, m.blockNumber, m.stake);
    }

    function hasMintPending(address addr) external view returns (bool) {
        return _hasCommits(addr);
    }

    function canMint(address addr) external view returns (bool) {
        return _hasCommits(addr);
    }



    function _hasCommits(address addr) internal view returns (bool) {
        MintCommit memory m = _mintCommits[addr];
        (bool a, bool b, bool c) = _commitStatus(m);
        return a && b && c;
    }

    function _commitStatus(MintCommit memory m) 
        internal view 
        returns (bool exist, bool notExpired, bool nextBlockReached) 
    {        
        exist = m.blockNumber != 0;
        notExpired = blockhash(m.blockNumber) != bytes32(0);
        nextBlockReached = block.number > m.blockNumber;
    }




    /**
     * allows owner to withdraw funds from minting
     */
    function _withdrawAll() external onlyTokenClaimer {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function _withdraw(uint256 amount) external onlyTokenClaimer {
        payable(_msgSender()).transfer(amount);
    }



    modifier requireContractsSet() {
        require(
            address(cacao) != address(0) && address(nftContract) != address(0) && address(fleet) != address(0),
            "Contracts not set"
        );
        _;
    }

    modifier onlyEOA() {
        require(_msgSender() == tx.origin, "Only EOA");
        _;
    }

    modifier commitsEnabled() {
        require(allowCommits, "Adding minting commits disalolwed");
        _;
    }

    modifier publicSaleStarted() {
        require(isPublicSale, "Public sale not started yet");
        _;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


import "./Accessable.sol";


contract Whitelist is Accessable {
    bytes32 _whitelistRoot = 0;

    constructor() {}

    function _setWhitelistRoot(bytes32 root) external onlyAdmin {
        _whitelistRoot = root;
    }

    function isWhitelistRootSeted() public view returns(bool){
        return (_whitelistRoot != bytes32(0));
    }

    function inWhitelist(address addr, bytes32[] memory proof) public view returns (bool) {
        require(isWhitelistRootSeted(), "Whitelist merkle proof root not setted");
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(proof, _whitelistRoot, leaf);
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
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
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