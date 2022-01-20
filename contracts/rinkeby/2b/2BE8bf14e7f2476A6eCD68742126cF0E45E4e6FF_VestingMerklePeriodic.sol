// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity 0.8.9;

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
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
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

pragma solidity 0.8.9;

contract OwnableData {
    address public owner;
    address public pendingOwner;
}

contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev `owner` defaults to msg.sender on construction.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
     *      Can only be invoked by the current `owner`.
     * @param _newOwner Address of the new owner.
     * @param _direct True if `_newOwner` should be set immediately. False if `_newOwner` needs to use `claimOwnership`.
     * @param _renounce Allows the `_newOwner` to be `address(0)` if `_direct` and `_renounce` is True. Has no effect otherwise
     */
    function transferOwnership(
        address _newOwner,
        bool _direct,
        bool _renounce
    ) external onlyOwner {
        if (_direct) {
            require(_newOwner != address(0) || _renounce, "zero address");

            emit OwnershipTransferred(owner, _newOwner);
            owner = _newOwner;
            pendingOwner = address(0);
        } else {
            pendingOwner = _newOwner;
        }
    }

    /**
     * @dev Needs to be called by `pendingOwner` to claim ownership.
     */
    function claimOwnership() external {
        address _pendingOwner = pendingOwner;
        require(msg.sender == _pendingOwner, "caller != pending owner");

        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /**
     * @dev Throws if called by any account other than the Owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IERC20 } from "./IERC20.sol";
import { Ownable } from "./Ownable.sol";
import { MerkleProof } from "./MerkleProof.sol";

/**
 * @title   VestingMerklePeriodic
 */
contract VestingMerklePeriodic is Ownable {
    /// @notice address of vested token
    address public token;
    /// @notice total tokens vested in contract
    uint256 public totalVested;
    /// @notice total tokens already claimed form vesting
    uint256 public totalClaimed;

    bytes32 public merkleRoot;
    mapping(uint256 => uint256) public vestedBitMap;

    uint256 public dateStart;
    uint256 public dateEnd;
    uint256 public startBPS;
    uint256 public period;
    uint256 public recurrences;

    struct Vest {
        uint256 totalTokens; // total tokens to claim
        uint256 startTokens; // tokens to claim on start
        uint256 claimedTokens; // tokens already claimed
    }
    /// @notice storage of vestings
    Vest[] internal vestings;
    /// @notice map of vestings for user
    mapping(address => uint256) internal user2vesting;

    /// @dev events
    event Claimed(address indexed user, uint256 amount);
    event Vested(address indexed user, uint256 totalAmount);

    /**
     * @dev Contract initiator
     * @param _token address of vested token
     */
    function init(
        address _token,
        uint256 _dateStart,
        uint256 _startBPS,
        uint256 _period,
        uint256 _recurrences,
        bytes32 _merkleRoot
    ) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        require(token == address(0), "init already done");
        token = _token;
        dateStart = _dateStart;
        startBPS = _startBPS;
        period = _period;
        recurrences = _recurrences;
        dateEnd = dateStart + (period * recurrences * 3600);
        merkleRoot = _merkleRoot;
    }

    function isVested(uint256 index) public view returns (bool) {
        uint256 vestedWordIndex = index / 256;
        uint256 vestedBitIndex = index % 256;
        uint256 vestedWord = vestedBitMap[vestedWordIndex];
        uint256 mask = (1 << vestedBitIndex);
        return vestedWord & mask == mask;
    }

    function _setVested(uint256 index) private {
        uint256 vestedWordIndex = index / 256;
        uint256 vestedBitIndex = index % 256;
        vestedBitMap[vestedWordIndex] = vestedBitMap[vestedWordIndex] | (1 << vestedBitIndex);
    }

    /**
     * @dev Add new vesting to contract
     * @param _user address of a holder
     * @param _startTokens how many tokens are claimable at start date
     * @param _totalTokens total number of tokens in added vesting
     */
    function _addVesting(
        address _user,
        uint256 _startTokens,
        uint256 _totalTokens
    ) internal {
        require(_user != address(0), "account address cannot be 0");
        Vest memory v;
        v.startTokens = _startTokens;
        v.totalTokens = _totalTokens;

        totalVested += _totalTokens;
        vestings.push(v);
        user2vesting[_user] = vestings.length; // we are skipping index "0" for reasons
        emit Vested(_user, v.totalTokens);
    }

    /**
     * @dev Claim tokens from account vestings
     */
    function claim(
        address account,
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (!isVested(index)) {
            // Verify the merkle proof.
            bytes32 node = keccak256(abi.encodePacked(index, account, amount));
            require(MerkleProof.verify(merkleProof, merkleRoot, node), "invalid proof");

            // Add Vesting
            _addVesting(account, ((amount * startBPS) / 10000), amount);

            // Mark as vested.
            _setVested(index);
        }

        _claim(account);
    }

    /**
     * @dev internal claim function
     * @param _user address of holder
     * @return amt number of tokens claimed
     */
    function _claim(address _user) internal returns (uint256 amt) {
        require(user2vesting[_user] > 0, "no vestings for user");

        Vest storage v = vestings[user2vesting[_user] - 1];
        amt = _claimable(v);
        v.claimedTokens += amt;

        if (amt > 0) {
            totalClaimed += amt;
            _transfer(_user, amt);
            emit Claimed(_user, amt);
        } else revert("nothing to claim");
    }

    /**
     * @dev Internal function to send out claimed tokens
     * @param _user address that we send tokens
     * @param _amt amount of tokens
     */
    function _transfer(address _user, uint256 _amt) internal {
        require(IERC20(token).transfer(_user, _amt), "token transfer failed");
    }

    /**
     * @dev Count how many tokens can be claimed from vesting to date
     * @param _vesting Vesting object
     * @return canWithdraw number of tokens
     */
    function _claimable(Vest memory _vesting) internal view returns (uint256 canWithdraw) {
        uint256 currentTime = block.timestamp;

        // not started
        if (dateStart > currentTime) return 0;

        if (currentTime < dateEnd) {
            // we are somewhere in the middle
            uint256 vestedAmount = _vesting.totalTokens - _vesting.startTokens;
            uint256 everyRecurrenceReleaseAmount = vestedAmount / recurrences;

            uint256 occurrences = diffDays(dateStart, currentTime) / period;
            uint256 vestingUnlockedAmount = occurrences * everyRecurrenceReleaseAmount;

            canWithdraw = vestingUnlockedAmount + _vesting.startTokens; // total unlocked amount
        } else {
            // time has passed, we can take all tokens
            canWithdraw = _vesting.totalTokens;
        }

        // but maybe we take something earlier?
        canWithdraw -= _vesting.claimedTokens;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp, "fromTimestamp > toTimestamp");
        _days = (toTimestamp - fromTimestamp) / 3600;
    }

    /**
     * @dev Read total amount of tokens that user can claim to date from all vestings
     *      Function also includes tokens to claim from sale contracts that were not
     *      yet initiated for user.
     * @return amount number of tokens
     */
    function getAllClaimable(
        address account_,
        uint256 index_,
        uint256 amount_,
        bytes32[] calldata merkleProof_
    ) public view returns (uint256 amount) {
        if (!isVested(index_)) {
            // Verify the merkle proof.
            bytes32 node = keccak256(abi.encodePacked(index_, account_, amount_));
            if (MerkleProof.verify(merkleProof_, merkleRoot, node)) {
                Vest memory v;
                v.startTokens = (amount_ * startBPS) / 10000;
                v.totalTokens = amount_;
                amount = _claimable(v);
            }
        } else {
            amount = _claimable(vestings[user2vesting[account_] - 1]);
        }
    }

    struct VestReturn {
        uint256 dateStart; // start of claiming, can claim startTokens
        uint256 dateEnd; // after it all tokens can be claimed
        uint256 totalTokens; // total tokens to claim
        uint256 startTokens; // tokens to claim on start
        uint256 claimedTokens; // tokens already claimed
    }

    /**
     * @dev Extract all the vestings for the user
     *      Also extract not initialized vestings from
     *      sale contracts.
     * @return v array of Vest objects
     */
    function getVestings(
        address account_,
        uint256 index_,
        uint256 amount_,
        bytes32[] calldata merkleProof_
    ) external view returns (VestReturn[] memory v) {
        if (!isVested(index_)) {
            // Verify the merkle proof.
            bytes32 node = keccak256(abi.encodePacked(index_, account_, amount_));
            if (MerkleProof.verify(merkleProof_, merkleRoot, node)) {
                v = new VestReturn[](1);
                v[0].dateStart = dateStart;
                v[0].dateEnd = dateEnd;
                v[0].startTokens = (amount_ * startBPS) / 10000;
                v[0].totalTokens = amount_;
            }
        } else {
            v = new VestReturn[](1);
            v[0].dateStart = dateStart;
            v[0].dateEnd = dateEnd;
            v[0].totalTokens = vestings[user2vesting[account_] - 1].totalTokens;
            v[0].startTokens = vestings[user2vesting[account_] - 1].startTokens;
            v[0].claimedTokens = vestings[user2vesting[account_] - 1].claimedTokens;
        }
    }

    /**
     * @dev Recover ETH from contract to owner address.
     */
    function recoverETH() external {
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev Recover given ERC20 token from contract to owner address.
     *      Can't recover vested tokens.
     * @param _token address of ERC20 token to recover
     */
    function recoverErc20(address _token) external onlyOwner {
        uint256 amt = IERC20(_token).balanceOf(address(this));
        require(amt > 0, "nothing to recover");
        IBadErc20(_token).transfer(owner, amt);
    }
}

/**
 * @title IBadErc20
 * @dev Interface for emergency recover any ERC20-tokens,
 *      even non-erc20-compliant like USDT not returning boolean
 */
interface IBadErc20 {
    function transfer(address _recipient, uint256 _amount) external;
}