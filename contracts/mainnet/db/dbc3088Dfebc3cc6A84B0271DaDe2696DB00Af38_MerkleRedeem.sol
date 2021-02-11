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

// SPDX-License-Identifier: MIT

/**
 * Original code taken from: https://github.com/balancer-labs/erc20-redeemable/blob/13d478a043ec7bfce7abefe708d027dfe3e2ea84/merkle/contracts/MerkleRedeem.sol
 * Only comments and events were added, some variable names changed for clarity and the compiler version was upgraded to 0.7.x.
 *
 * @reviewers: [@hbarcelos]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 */
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Distribution of tokens in a recurrent fashion.
 */
contract MerkleRedeem is Ownable {
    /// @dev The address of the token being distributed.
    IERC20 public token;

    /**
     * @dev To be emitted when a claim is made.
     * @param _claimant The address of the claimant.
     * @param _balance The amount being claimed.
     */
    event Claimed(address _claimant, uint256 _balance);

    /// @dev The merkle roots of each week. weekMerkleRoots[week].
    mapping(uint => bytes32) public weekMerkleRoots;

    /// @dev Keeps track of the claim status for the given period and claimant. claimed[period][claimant].
    mapping(uint => mapping(address => bool)) public claimed;

    /**
     * @param _token The address of the token being distributed.
     */
    constructor(
        address _token
    ) public {
        token = IERC20(_token);
    }

    /**
     * @dev Effectively pays a claimant.
     * @param _liquidityProvider The address of the claimant.
     * @param _balance The amount being claimed.
     */
    function disburse(
        address _liquidityProvider,
        uint _balance
    )
        private
    {
        if (_balance > 0) {
            emit Claimed(_liquidityProvider, _balance);
            require(token.transfer(_liquidityProvider, _balance), "ERR_TRANSFER_FAILED");
        }
    }

    /**
     * @notice Makes a claim for a given claimant in a week.
     * @param _liquidityProvider The address of the claimant.
     * @param _week The week for the claim.
     * @param _claimedBalance The amount being claimed.
     * @param _merkleProof The merkle proof for the claim, sorted from the leaf to the root of the tree.
     */
    function claimWeek(
        address _liquidityProvider,
        uint _week,
        uint _claimedBalance,
        bytes32[] memory _merkleProof
    )
        public
    {
        require(!claimed[_week][_liquidityProvider]);
        require(verifyClaim(_liquidityProvider, _week, _claimedBalance, _merkleProof), 'Incorrect merkle proof');

        claimed[_week][_liquidityProvider] = true;
        disburse(_liquidityProvider, _claimedBalance);
    }

    struct Claim {
        // The week the claim is related to.
        uint week;
        // The amount being claimed.
        uint balance;
        // The merkle proof for the claim, sorted from the leaf to the root of the tree.
        bytes32[] merkleProof;
    }

    /**
     * @notice Makes multiple claims for a given claimant.
     * @param _liquidityProvider The address of the claimant.
     * @param claims An array of claims containing the week, balance and the merkle proof.
     */
    function claimWeeks(
        address _liquidityProvider,
        Claim[] memory claims
    )
        public
    {
        uint totalBalance = 0;
        Claim memory claim ;
        for(uint i = 0; i < claims.length; i++) {
            claim = claims[i];

            require(!claimed[claim.week][_liquidityProvider]);
            require(verifyClaim(_liquidityProvider, claim.week, claim.balance, claim.merkleProof), 'Incorrect merkle proof');

            totalBalance += claim.balance;
            claimed[claim.week][_liquidityProvider] = true;
        }
        disburse(_liquidityProvider, totalBalance);
    }

    /**
     * @notice Gets the claim status for given claimant from `_begin` to `_end` weeks.
     * @param _liquidityProvider The address of the claimant.
     * @param _begin The week to start with (inclusive).
     * @param _end The week to end with (inclusive).
     */
    function claimStatus(
        address _liquidityProvider,
        uint _begin,
        uint _end
    )
        external
        view
        returns (bool[] memory)
    {
        uint size = 1 + _end - _begin;
        bool[] memory arr = new bool[](size);
        for(uint i = 0; i < size; i++) {
            arr[i] = claimed[_begin + i][_liquidityProvider];
        }
        return arr;
    }

    /**
     * @notice Gets all merkle roots for from `_begin` to `_end` weeks.
     * @param _begin The week to start with (inclusive).
     * @param _end The week to end with (inclusive).
     */
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
            arr[i] = weekMerkleRoots[_begin + i];
        }
        return arr;
    }

    /**
     * @notice Verifies a claim.
     * @param _liquidityProvider The address of the claimant.
     * @param _week The week for the claim.
     * @param _claimedBalance The amount being claimed.
     * @param _merkleProof The merkle proof for the claim, sorted from the leaf to the root of the tree.
     */
    function verifyClaim(
        address _liquidityProvider,
        uint _week,
        uint _claimedBalance,
        bytes32[] memory _merkleProof
    )
        public
        view
        returns (bool valid)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_liquidityProvider, _claimedBalance));
        return MerkleProof.verify(_merkleProof, weekMerkleRoots[_week], leaf);
    }

    /**
     * @notice Seeds a new round for the airdrop.
     * @dev Will transfer tokens from the owner to this contract.
     * @param _week The airdrop week.
     * @param _merkleRoot The merkle root of the claims for that period.
     * @param _totalAllocation The amount of tokens allocated for the distribution.
     */
    function seedAllocations(
        uint _week,
        bytes32 _merkleRoot,
        uint _totalAllocation
    )
        external
        onlyOwner
    {
        require(weekMerkleRoots[_week] == bytes32(0), "cannot rewrite merkle root");
        weekMerkleRoots[_week] = _merkleRoot;

        require(token.transferFrom(msg.sender, address(this), _totalAllocation), "ERR_TRANSFER_FAILED");
    }
}