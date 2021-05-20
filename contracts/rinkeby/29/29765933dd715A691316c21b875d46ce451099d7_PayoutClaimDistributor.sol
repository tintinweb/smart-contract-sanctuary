/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

// Sources flattened with hardhat v2.1.2 https://hardhat.org

// File @openzeppelin/contracts/GSN/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/cryptography/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
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


// File contracts/payout/IPayoutClaim.sol
pragma solidity >=0.6.8;

interface IPayoutClaim {
    // methods
    function setTokenToClaim(IERC20 _tokenAddress) external;

    function setMerkleRoot(bytes32 _merkleRoot) external;

    function setLocked(bool lock) external;

    function setDistributorAddress(address _distAddress) external;

    function claimPayout(
        uint256 index,
        address _address,
        uint256 amount,
        bytes32 salt,
        bytes32[] calldata merkleProof
    ) external;

    // events
    event SetMerkleRoot(bytes32 indexed _merkleRoot);
    event SetTokenToClaim(address _tokenAddress);
    event ClaimedPayout(address indexed _address, uint256 amount, bytes32 salt);
    event DistributionLocked(bool _isLocked);
    event SetDistributorAddress(address indexed _ownerAddress, address indexed _distAddress);
}


// File contracts/payout/PayoutClaimDistributor.sol
pragma solidity >=0.6.8;




/// @title PayoutClaimDistributor
contract PayoutClaimDistributor is IPayoutClaim, Ownable {
    bytes32 public merkleRoot;
    IERC20 public ercToken;
    address public distAddress;
    bool public isLocked;

    /*
     * Mapping for hash for (index,  address, amount, salt) for claimed status
     */
    mapping(bytes32 => bool) public claimed;

    /// @dev Constructor for setting ERC token address and merkleroot on deployment
    /// @param _ercToken Address for token to distribute
    /// @param _merkleRoot String of initial merkle root
    /// @dev `distAddress` deployer address will be distributor address by default
    constructor(IERC20 _ercToken, bytes32 _merkleRoot) public {
        ercToken = _ercToken;
        merkleRoot = _merkleRoot;
        distAddress = msg.sender;
    }

    /// @notice Token address that user could claim
    /// @dev Owner sets  `ercToken` token address to claim
    /// @param _ercToken Token address for token to distribute
    function setTokenToClaim(IERC20 _ercToken) public override onlyOwner {
        ercToken = _ercToken;
        emit SetTokenToClaim(address(_ercToken));
    }

    /// @notice Merkle Root for current period to use for payout
    /// @dev Owner sets merkle hash generated based on the payout set
    /// @param _merkleRoot bytes32 string of merkle root to set for specific period
    function setMerkleRoot(bytes32 _merkleRoot) public override onlyOwner {
        merkleRoot = _merkleRoot;
        emit SetMerkleRoot(merkleRoot);
    }

    /// @notice Set locked/unlocked status  for PayoutClaim Distributor
    /// @dev Owner lock/unlock each time new merkle root is being generated
    /// @param _isLocked = true/false status
    function setLocked(bool _isLocked) public override onlyOwner {
        isLocked = _isLocked;
        emit DistributionLocked(_isLocked);
    }

    /// @notice Distributor address in PayoutClaim Distributor
    /// @dev Wallet that holds erctoken for distribution
    /// @param _distributorAddress Distributor address used for distribution of `ercToken` token
    function setDistributorAddress(address _distributorAddress) public override onlyOwner {
        distAddress = _distributorAddress;
        emit SetDistributorAddress(msg.sender, _distributorAddress);
    }

    /// @notice Generate Claim hash for each leaf
    /// @dev Generate claim hash of the leaf based on index, address, amount and salt
    /// @param index Index assigned for the address for the merkle root
    /// @param _address Address of the user to claim the payout
    /// @param amount Claimable amount of address
    /// @param salt Unique value for user for each new merkle root generating
    /// @return bytes32 string hash of the leaf
    function _generateClaimHash(
        uint256 index,
        address _address,
        uint256 amount,
        bytes32 salt
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(index, _address, amount, salt));
    }

    /// @notice Get total supply that the distributor address has
    /// @dev Get balance of the distributor address set
    /// @return uint balance of distributor address
    function supply() public view returns (uint256) {
        return ercToken.balanceOf(address(distAddress));
    }

    /// @notice Payout method that user calls to claim
    /// @dev Method user calls for claiming the payout for user
    /// @param index Index assigned for the address for the merkle root
    /// @param _address Address of the user to claim the payout
    /// @param amount Claimable amount of address
    /// @param salt Unique value for user for each new merkle root generating
    /// @param merkleProof Merkle proof of the user based on the merkle root
    function claimPayout(
        uint256 index,
        address _address,
        uint256 amount,
        bytes32 salt,
        bytes32[] calldata merkleProof
    ) external override {
        require(isLocked == false, "Payout locked");
        require(amount > 0, "Invalid Amount");
        require(supply() > amount, "Token supply < amount");

        bytes32 leafHash = _generateClaimHash(index, _address, amount, salt);

        require(!claimed[leafHash], "Payout already claimed.");
        require(MerkleProof.verify(merkleProof, merkleRoot, leafHash), "Invalid proof.");

        claimed[leafHash] = true;

        require(ercToken.transferFrom(distAddress, _address, amount), "Payout failed.");

        emit ClaimedPayout(_address, amount, salt);
    }
}