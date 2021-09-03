// SPDX-License-Identifier: LGPL
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MerkleRedeem is Ownable {

    IERC20 public token;

    event Claimed(address indexed claimant, uint256 indexed rewardEpoch, uint256 balance);
    event RootAdded(address indexed depositor, uint256 indexed rewardEpoch, uint256 totalAllocation);

    // Recorded epochs
    mapping(uint => bytes32) public epochMerkleRoots;
    mapping(uint => mapping(address => bool)) public claimed;

    constructor(
        address _token
    ) public {
        token = IERC20(_token);
    }


    // PRIVATE FUNCTIONS
    /// @notice sends token amount to recipient if _balance is greater than 0
    /// @param _recipient address to send to
    /// @param _balance amount to send
    function _disburse(
        address _recipient,
        uint _balance
    )
        private
    {
        require(token.transfer(_recipient, _balance), "ERR_TRANSFER_FAILED");
    }

    /// @notice performs internal verification checks that the proof is valid and marks claim as claimed
    /// @param _recipient address to check
    /// @param _epoch epoch to check
    /// @param _claimedBalance amount that address wants to claim
    /// @param _merkleProof merkle proof for claim
    function _claimEpoch(
        address _recipient,
        uint _epoch,
        uint _claimedBalance,
        bytes32[] memory _merkleProof
    ) private {
        require(!claimed[_epoch][_recipient]);
        require(verifyClaim(_recipient, _epoch, _claimedBalance, _merkleProof), 'Incorrect merkle proof');

        claimed[_epoch][_recipient] = true;
        emit Claimed(_recipient, _epoch, _claimedBalance);
    }

    // PUBLIC FUNCTIONS
    /// @notice public function to claim tokens for a single epoch
    /// @param _recipient address to check
    /// @param _epoch epoch to check
    /// @param _claimedBalance amount that address wants to claim
    /// @param _merkleProof merkle proof for claim
    function claimEpoch(
        address _recipient,
        uint _epoch,
        uint _claimedBalance,
        bytes32[] memory _merkleProof
    )
        public
    {
        _claimEpoch(_recipient, _epoch, _claimedBalance, _merkleProof);
        _disburse(_recipient, _claimedBalance);
    }

    struct Claim {
        uint epoch;
        uint balance;
        bytes32[] merkleProof;
    }

    /// @notice public function to claim for multiple epochs
    /// @param claims an array of Claim structs with data for each epoch
    function claimEpochs(
        address _recipient,
        Claim[] memory claims
    )
        public
    {
        uint totalBalance = 0;
        Claim memory claim ;
        for(uint i = 0; i < claims.length; i++) {
            claim = claims[i];
            _claimEpoch(_recipient, claim.epoch, claim.balance, claim.merkleProof);
            totalBalance += claim.balance;
        }
        _disburse(_recipient, totalBalance);
    }

    // VIEWS
    /// @notice returns merkleRoots for epochs in the specified range
    /// @param _begin first epoch
    /// @param _end last epoch
    /// @return array of merkle roots
    function merkleRoots(
        uint _begin,
        uint _end
    ) 
        external
        view 
        returns (bytes32[] memory)
    {
        uint size = 1 + _end - _begin;
        bytes32[] memory arr = new bytes32[](size);
        for(uint i = 0; i < size; i++) {
            arr[i] = epochMerkleRoots[_begin + i];
        }
        return arr;
    }

    /// @notice verifies that the token claim and merkle proof are valid for the recipient
    /// @param _recipient address to check
    /// @param _epoch epoch to check
    /// @param _claimedBalance amount that address wants to claim
    /// @param _merkleProof merkle proof for claim
    /// @return valid true or false if the claim is valid
    function verifyClaim(
        address _recipient,
        uint _epoch,
        uint _claimedBalance,
        bytes32[] memory _merkleProof
    )
        public
        view
        returns (bool valid)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_recipient, _claimedBalance));
        return MerkleProof.verify(_merkleProof, epochMerkleRoots[_epoch], leaf);
    }

    // OWNER ONLY
    /// @notice writes merkle root for the selected epoch, requires contract to already be funded
    /// @param _epoch new epoch number
    /// @param _merkleRoot merkle root for the new epoch
    /// @param _totalAllocation total number of tokens required
    function newRoot(
        uint _epoch,
        bytes32 _merkleRoot,
        uint _totalAllocation
    )
        external
        onlyOwner
    {
        require(epochMerkleRoots[_epoch] == bytes32(0), "cannot rewrite merkle root");
        epochMerkleRoots[_epoch] = _merkleRoot;

        require(token.balanceOf(address(this)) >= _totalAllocation, "contract hasn't been funded");
        emit RootAdded(msg.sender, _epoch, _totalAllocation);
    }
}

// SPDX-License-Identifier: MIT

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