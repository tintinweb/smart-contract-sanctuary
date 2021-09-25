/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

// File: IStagedMerkleDistributor.sol

pragma solidity >=0.5.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IStagedMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 airdropID, uint256 index, address account, uint256 amount);
}

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

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol

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

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: StagedMerkleDistributor.sol

pragma solidity ^0.8.4;

/**
 *     ____  __           __  _       __      __       __  
 *    / __ )/ /___  _____/ /_| |     / /___ _/ /______/ /_ 
 *   / __  / / __ \/ ___/ //_/ | /| / / __ `/ __/ ___/ __ \
 *  / /_/ / / /_/ / /__/ ,<  | |/ |/ / /_/ / /_/ /__/ / / /
 * /_____/_/\____/\___/_/|_| |__/|__/\__,_/\__/\___/_/ /_/ 
 * 
 * Blockwatch Finance Transparency Focused Staged Airdrop
 * 
 * Staged airdrop contract that allows us to send multiple rounds of airdrops
 * In a very transparent way.
 * 
 * Modified version of Uniswap's merkle-distributor to allow for multiple stages: https://github.com/Uniswap/merkle-distributor
 * 
 * 
 * Once we "initiate" an airdrop, anyone can see the new merkle root, and with the
 * rewards mapping we will publicly publish, anyone with a keen eye can easily
 * detect foul play with these transparency focused features by building the root themselves
 * and comparing.
 * 
 * The actual claiming of an airdrop reward can only be done after 14 days from
 * initiating the airdrop. This gives users plenty of time to revoke
 * their investment in BlockWatch Finance, if foul play is detected.
 * 
 * Hint: This will never happen!
 * 
 * 
 * This contract is well documented, so even if you don't know much solidity,
 * it should be very easy to determine how this contract operates. We encourage
 * you to analyse the behaviour of this contract, and let us know if there are any concerns.
 */

contract StagedMerkleDistributor is IStagedMerkleDistributor, Ownable {
    event AirdropInitiated(bytes32 newMerkleRoot);
    
    // Address of ERC20 token we are distributing
    address public immutable override token;

    // Incremented each time we initiate a new airdrop to allow us to index a new merkle root of
    // Assigned rewards each time we update it
    uint256 public airdropID = 0;

    // Array of packed arrays of booleans denoting whether each address has claimed
    // their tokens. Indexed by airdropID -> claimWord -> claimBit
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;

    // Store a different merkle root for each aidrop we give out.
    // Indexed by airdropID. This also allows us to store a history of airdropped merkle roots
    mapping(uint256 => bytes32) public merkleRoots;
    
    // Keep track of when the last airdrop was initiated, to check if 14 days has elapsed before rewards can be claimed
    uint256 public timeInitiated;
    
    constructor(address tokenAddress) {
        token = tokenAddress;
    }
    
    // !!!! Once an airdrop has been initiated, 14 DAYS MUST BE ELAPSED BEFORE ANY AIRDROPS CAN BE CLAIMED !!!!
    // This is done to allow users to find any foul play, such as giving ourselves the airdrop fund or any similar malicious actions
    // Far before they actually happen, due to this hard coded cooling off period
    // This allows us to be completely transparent in the way we give out airdrops, and misallows us from abusing this system
    function initiateAirdrop (bytes32 newMerkleRoot) onlyOwner public {
        // Disallow us from initiating another airdrop until users have had atleast 2 weeks to claim their rewards from the last airdrop initiation
        require(block.timestamp > (timeInitiated + (28 days)), "Not enough time has been given for users to collect their airdrop!");
        
        // Increment airdrop id to allow us to index new merkle root and claimed bitmap
        airdropID += 1;
        
        // Set new merkle root
        merkleRoots[airdropID] = newMerkleRoot;
        
        // Record time initiated to enforce cooling off period
        timeInitiated = block.timestamp;
        
        // Emit event that the airdrop has been "initiated"
        emit AirdropInitiated(newMerkleRoot);
    }
    
    // Assuming an airdrop has been initiated, the user may claim their airdrop once 14 days since initiation has passed
    // This is where the actual tokens will be transferred out of this contract to the winners
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external override {
        require(merkleRoots[airdropID] != 0, "StagedMerkleDistributor: No airdrop has been initiated yet.");
        require(block.timestamp > (timeInitiated + (14 days)), "You must wait atleast 14 days from initiation to claim your rewards!");
        require(!isClaimed(index), 'StagedMerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoots[airdropID], node), 'StagedMerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'StagedMerkleDistributor: Transfer failed.');
        
        emit Claimed(airdropID, index, account, amount);
    }

    function merkleRoot() public view override returns (bytes32) {
        return merkleRoots[airdropID];
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[airdropID][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[airdropID][claimedWordIndex] = claimedBitMap[airdropID][claimedWordIndex] | (1 << claimedBitIndex);
    }
}