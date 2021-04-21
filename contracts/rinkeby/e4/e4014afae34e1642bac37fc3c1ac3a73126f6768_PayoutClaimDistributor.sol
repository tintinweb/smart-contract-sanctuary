// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "./IPayoutClaim.sol";

contract PayoutClaimDistributor is IPayoutClaim, Ownable {
	bytes32 public merkleRoot;
	IERC20 public ercToken;
	address public distAddress;
	bool public isLocked;

	/*
	* Mapping for hash for (index,  address, amount, salt) for claimed status
	*/
	mapping(bytes32 => bool) public claimed;

	/*
	* Constructor for PayoutClaim Distributor
	*   _ercToken - ERC token address to distribute
	*   _merkleRoot - Merkle root for specific week
	*
	*   distAddress - deployer address that is used for distribution
	*/
	constructor(IERC20 _ercToken, bytes32 _merkleRoot)
	public {
		ercToken = _ercToken;
		merkleRoot = _merkleRoot;
		distAddress = msg.sender;
	}

	/*
	* Set token that payout claim distributor distributes
	* _ercToken - address of token to be distributed
	*/
	function setTokenToClaim(IERC20 _ercToken)
	onlyOwner public override {
		ercToken = _ercToken;
		emit SetTokenToClaim(address(_ercToken));
	}

	/*
	* Set latest merkle root for PayoutClaim Distributor
	*   _merkleRoot - merkleroot of dataset
	*/
	function setMerkleRoot(bytes32 _merkleRoot)
	onlyOwner public override {
		merkleRoot = _merkleRoot;
		emit SetMerkleRoot(merkleRoot);
	}

	/*
	* Set locked/unlocked status  for PayoutClaim Distributor
	*   _isLocked  - true/false - locked / unlocked  status
	*/
	function setLocked(bool _isLocked)
	onlyOwner public override {
		isLocked = _isLocked;
		emit DistributionLocked(_isLocked);
	}

	/*
	* Set distributor address in PayoutClaim Distributor
	*   _distributorAddress - distributor address used for distribution of `ercToken` token
	*/
	function setDistributorAddress (address _distributorAddress)
	onlyOwner public override {
		distAddress = _distributorAddress;
		emit SetDistributorAddress(msg.sender, _distributorAddress);
	}

	/*
	* generate claim hash for specific address
	*   index - index assigned for the address for the merkle root
	*   _address - address that user will claim
	*   amount - claimable amount of address
	*   salt - unique value for user for each new merkle root generating
	*/
	function _generateClaimHash(
		uint256 index,
		address _address,
		uint256 amount,
		bytes32 salt
	) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked(index, _address, amount, salt));
	}

	/*
	* total amount of tokens that the distributor has
	*/
	function supply() public view returns (uint) {
		return ercToken.balanceOf(address(distAddress));
	}

	/*
	* Method user calls for claiming the payout for user
	*   index, _address, amount, salt - same as in above method
	*   merkleProof - array of hashes for merkle proof, ["a","b","c"]
	*/
	function claimPayout(uint256 index, address _address, uint256 amount, bytes32 salt, bytes32[] calldata merkleProof)
	external override {
		require(isLocked == false, 'Payout is currently locked.');
		require(amount > 0, 'Amount should be greater than 0.' );
		require(supply() > amount, 'Token supply is not enough.');

		bytes32 leafHash = _generateClaimHash(index, _address, amount, salt);

		require(!claimed[leafHash], 'Payout already claimed.');
		require(MerkleProof.verify(merkleProof, merkleRoot, leafHash), 'Invalid proof.');

		claimed[leafHash] = true;

		require(ercToken.transferFrom(distAddress, _address, amount), 'Payout failed.');

		emit ClaimedPayout(_address, amount, salt);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPayoutClaim {
	// methods
	function setTokenToClaim(IERC20 _tokenAddress) external;

	function setMerkleRoot(bytes32 _merkleRoot) external;

	function setLocked(bool lock) external ;

	function setDistributorAddress(address _distAddress) external;

	function claimPayout(uint256 index, address _address, uint256 amount, bytes32 salt, bytes32[] calldata merkleProof) external;

	// events
	event SetMerkleRoot(bytes32 indexed _merkleRoot);
	event SetTokenToClaim(address _tokenAddress);
	event ClaimedPayout(address indexed _address, uint256 amount, bytes32 salt);
	event DistributionLocked(bool _isLocked);
	event SetDistributorAddress(address indexed _ownerAddress, address indexed _distAddress);
}

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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}