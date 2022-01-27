// SPDX-License-Identifier: MIT
// Developed by KG Technologies (https://kgtechnologies.io)

pragma solidity 0.8.11;

/**
   _____ _      ____ _______ _____ ______        _ _    _ _   _ _____ ____  _____     _____         _      ______ 
  / ____| |    / __ \__   __|_   _|  ____|      | | |  | | \ | |_   _/ __ \|  __ \   / ____|  /\   | |    |  ____|
 | (___ | |   | |  | | | |    | | | |__         | | |  | |  \| | | || |  | | |__) | | (___   /  \  | |    | |__   
  \___ \| |   | |  | | | |    | | |  __|    _   | | |  | | . ` | | || |  | |  _  /   \___ \ / /\ \ | |    |  __|  
  ____) | |___| |__| | | |   _| |_| |____  | |__| | |__| | |\  |_| || |__| | | \ \   ____) / ____ \| |____| |____ 
 |_____/|______\____/  |_|  |_____|______|  \____/ \____/|_| \_|_____\____/|_|  \_\ |_____/_/    \_\______|______|                                                                                                                                                                                                                                                                                                         
                             
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @notice Represents Slotie Junior Smart Contract
 */
contract ISlotieJr {
    /** 
     * @dev ERC-721 INTERFACE 
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}

    /** 
     * @dev CUSTOM INTERFACE 
     */
    function mintTo(uint256 amount, address _to) external {}
    function maxMintPerTransaction() public returns (uint256) {}
}

/**
 * @title SlotieJrTicketSale.
 *
 * @author KG Technologies (https://kgtechnologies.io).
 *
 * @notice This Smart Contract can be used to sell a fixed amount of tickets where some of them are 
 * sold to permissioned wallets and the others are sold to the general public. 
 * The tickets can then be used to mint a corresponding amount of NFTs.
 *
 * @dev The primary mode of verifying permissioned actions is through Merkle Proofs
 * which are generated off-chain.
 */
contract SlotieJrTicketSale is Ownable {

    /** 
     * @notice The Smart Contract of the NFT being sold 
     * @dev ERC-721 Smart Contract 
     */
    ISlotieJr public immutable nft;
    
    /** 
     * @dev MINT DATA 
     */
    uint256 public maxSupplyPermissioned = 5000;
    uint256 public maxSupplyOpen = 5000;
    
    uint256 public boughtPermissioned = 0;
    uint256 public boughtOpen = 0;

    uint256 public limitOpen = 2;

    uint256 public priceOpen = 0.08 ether;
    
    mapping(address => uint256) public addressToTickets;
    mapping(address => uint256) public addressToMints;

    /// @dev Initial value is randomly generated from https://www.random.org/
    bytes32 public merkleRoot = 0xe788a23866da0e903934d723c44efe9da3f7265d053a8fed5c1036a78665f9c1;

    /**
     * @dev GIVEAWAY 
     */
    uint256 public maxSupplyGiveaway = 50;
    uint256 public giveAwayRedeemed = 0;
    mapping(address => uint256) public addressToGiveawayRedeemed;
    bytes32 public giveAwayMerkleRoot = "";

    /**
     * @dev Events
     */
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event Purchase(address indexed buyer, uint256 indexed amount, bool indexed permissioned);
    event RedeemTickets(address indexed redeemer, uint256 amount);
    event RedeemGiveAway(address indexed redeemer, uint256 amount);
    event setMaxSupplyPermissionedEvent(uint256 indexed maxSupply);
    event setMaxSupplyOpenEvent(uint256 indexed maxSupply);
    event setLimitOpenEvent(uint256 indexed limit);
    event setPriceOpenEvent(uint256 indexed price);
    event setMerkleRootEvent(bytes32 indexed merkleRoot);
    event setGiveAwayMerkleRootEvent(bytes32 indexed merkleRoot);
    event setGiveAwayMaxSupplyEvent(uint256 indexed newSupply);
    event WithdrawAllEvent(address indexed to, uint256 amount);

    constructor(
        address _nftaddress
    ) Ownable() {
        nft = ISlotieJr(_nftaddress);
    }
 
    /**
     * @dev SALE
     */

    /**
     * @notice Function to buy one or more tickets.
     * @dev First the Merkle Proof is verified.
     * Then the buy is verified with the data embedded in the Merkle Proof.
     * Finally the tickets are bought to the user's wallet.
     *
     * @param amount. The amount of tickets to buy.
     * @param buyStart. The start date of the buy.
     * @param buyEnd. The end date of the buy.
     * @param buyPrice. The buy price for the user.
     * @param buyMaxAmount. The max amount the user can buy.
     * @param proof. The Merkle Proof of the user.
     */
    function buyPermissioned(uint256 amount, uint256 buyStart, uint256 buyEnd, uint256 buyPrice, uint256 buyMaxAmount, bytes32[] calldata proof) 
        external 
        payable {

        /// @dev Verifies Merkle Proof submitted by user.
        /// @dev All mint data is embedded in the merkle proof.

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, buyStart, buyEnd, buyPrice, buyMaxAmount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "INVALID PROOF");

        /// @dev Verifies that user can perform permissioned sale based on the provided parameters.

        require(address(nft) != address(0), "NFT SMART CONTRACT NOT SET");
        require(merkleRoot != "", "PERMISSIONED SALE CLOSED");

        require(block.timestamp >= buyStart, "PERMISSIONED SALE HASN'T STARTED YET");
        require(block.timestamp < buyEnd, "PERMISSIONED SALE IS CLOSED");
        require(amount > 0, "HAVE TO BUY AT LEAST 1");

        require(addressToTickets[_msgSender()] + amount <= buyMaxAmount, "BUY AMOUNT EXCEEDS MAX FOR USER");
        require(boughtPermissioned + amount <= maxSupplyPermissioned, "BUY AMOUNT GOES OVER MAX SUPPLY");
        require(msg.value >= buyPrice * amount, "ETHER SENT NOT CORRECT");

        /// @dev Updates contract variables and buys `amount` tickets to users wallet

        boughtPermissioned += amount;
        addressToTickets[msg.sender] += amount;

        emit Purchase(msg.sender, amount, true);
    }

    /**
     * @notice Function to buy one or more tickets.
     *
     * @param amount. The amount of tickets to buy.
     */
    function buyOpen(uint256 amount) 
        external 
        payable {
        
        /// @dev Verifies that user can perform open sale based on the provided parameters.

        require(address(nft) != address(0), "NFT SMART CONTRACT NOT SET");
        require(merkleRoot == "", "OPEN SALE CLOSED");

        require(amount > 0, "HAVE TO BUY AT LEAST 1");

        require(addressToTickets[_msgSender()] + amount <= limitOpen, "BUY AMOUNT EXCEEDS MAX FOR USER");
        require(boughtOpen + amount <= maxSupplyOpen, "BUY AMOUNT GOES OVER MAX SUPPLY");
        require(msg.value >= priceOpen * amount, "ETHER SENT NOT CORRECT");

        /// @dev Updates contract variables and buys `amount` tickets to users wallet

        boughtOpen += amount;
        addressToTickets[msg.sender] += amount;

        emit Purchase(msg.sender, amount, false);
    }

    /**
     * @dev MINTING 
     */

    /**
     * @notice Allows users to redeem their tickets for NFTs.
     *
     */
    function redeemTickets() external {
        uint256 ticketsOfSender = addressToTickets[msg.sender];
        uint256 mintsOfSender = addressToMints[msg.sender];
        uint256 mintable = ticketsOfSender - mintsOfSender;

        require(mintable > 0, "NO MINTABLE TICKETS");

        uint256 maxMintPerTx = nft.maxMintPerTransaction();
        uint256 toMint = mintable >= maxMintPerTx ? maxMintPerTx : mintable;
        
        addressToMints[msg.sender] = addressToMints[msg.sender] + toMint;

        nft.mintTo(toMint, msg.sender);
        emit RedeemTickets(msg.sender, toMint);
    }

    /**
     * @notice Function to redeem giveaway.
     * @dev First the Merkle Proof is verified.
     * Then the redeem is verified with the data embedded in the Merkle Proof.
     * Finally the juniors are minted to the user's wallet.
     *
     * @param redeemStart. The start date of the redeem.
     * @param redeemEnd. The end date of the redeem.
     * @param redeemAmount. The amount to redeem.
     * @param proof. The Merkle Proof of the user.
     */
    function redeemGiveAway(uint256 redeemStart, uint256 redeemEnd, uint256 redeemAmount, bytes32[] calldata proof) external {
        /// @dev Verifies Merkle Proof submitted by user.
        /// @dev All giveaway data is embedded in the merkle proof.

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, redeemStart, redeemEnd, redeemAmount));
        require(MerkleProof.verify(proof, giveAwayMerkleRoot, leaf), "INVALID PROOF");

        /// @dev Verifies that user can perform giveaway based on the provided parameters.

        require(address(nft) != address(0), "NFT SMART CONTRACT NOT SET");
        require(giveAwayMerkleRoot != "", "GIVEAWAY CLOSED");

        require(block.timestamp >= redeemStart, "GIVEAWAY HASN'T STARTED YET");
        require(block.timestamp < redeemEnd, "GIVEAWAY IS CLOSED");
        require(redeemAmount > 0, "HAVE TO REDEEM AT LEAST 1");

        require(addressToGiveawayRedeemed[msg.sender] == 0, "GIVEAWAY ALREADY REDEEMED");
        require(giveAwayRedeemed + redeemAmount <= maxSupplyGiveaway, "GIVEAWAY AMOUNT GOES OVER MAX SUPPLY");

        /// @dev Updates contract variables and mints `redeemAmount` juniors to users wallet

        giveAwayRedeemed += redeemAmount;
        addressToGiveawayRedeemed[msg.sender] = 1;

        nft.mintTo(redeemAmount, msg.sender);
        emit RedeemGiveAway(msg.sender, redeemAmount);
    }

    /** 
     * @dev OWNER ONLY 
     */

    /**
     * @notice Change the maximum supply of tickets that are for sale in permissioned sale.
     *
     * @param newMaxSupply. The new max supply.
     */
    function setMaxSupplyPermissioned(uint256 newMaxSupply) external onlyOwner {
        maxSupplyPermissioned = newMaxSupply;
        emit setMaxSupplyPermissionedEvent(newMaxSupply);
    }

    /**
     * @notice Change the maximum supply of tickets that are for sale in open sale.
     *
     * @param newMaxSupply. The new max supply.
     */
    function setMaxSupplyOpen(uint256 newMaxSupply) external onlyOwner {
        maxSupplyOpen = newMaxSupply;
        emit setMaxSupplyOpenEvent(newMaxSupply);
    }

    /**
     * @notice Change the limit of tickets per wallet in open sale.
     *
     * @param newLimitOpen. The new max supply.
     */
    function setLimitOpen(uint256 newLimitOpen) external onlyOwner {
        limitOpen = newLimitOpen;
        emit setLimitOpenEvent(newLimitOpen);
    }

    /**
     * @notice Change the price of tickets that are for sale in open sale.
     *
     * @param newPriceOpen. The new max supply.
     */
    function setPriceOpen(uint256 newPriceOpen) external onlyOwner {
        priceOpen = newPriceOpen;
        emit setPriceOpenEvent(newPriceOpen);
    }

    /**
     * @notice Change the merkleRoot of the sale.
     *
     * @param newRoot. The new merkleRoot.
     */
    function setMerkleRoot(bytes32 newRoot) external onlyOwner {
        merkleRoot = newRoot;
        emit setMerkleRootEvent(newRoot);
    }

    /**
     * @notice Change the merkleRoot of the giveaway.
     *
     * @param newRoot. The new merkleRoot.
     */
    function setGiveAwayMerkleRoot(bytes32 newRoot) external onlyOwner {
        giveAwayMerkleRoot = newRoot;
        emit setGiveAwayMerkleRootEvent(newRoot);
    }

    /**
     * @notice Change the max supply for the giveaway.
     *
     * @param newSupply. The new giveaway max supply.
     */
    function setGiveAwayMaxSupply(uint256 newSupply) external onlyOwner {
        maxSupplyGiveaway = newSupply;
        emit setGiveAwayMaxSupplyEvent(newSupply);
    }

    /**
     * @dev FINANCE
     */

    /**
     * @notice Allows owner to withdraw funds generated from sale.
     *
     * @param _to. The address to send the funds to.
     */
    function withdrawAll(address _to) external onlyOwner {
        require(_to != address(0), "CANNOT WITHDRAW TO ZERO ADDRESS");

        uint256 contractBalance = address(this).balance;

        require(contractBalance > 0, "NO ETHER TO WITHDRAW");

        payable(_to).transfer(contractBalance);

        emit WithdrawAllEvent(_to, contractBalance);
    }

    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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