// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./libs/math/SafeMath.sol";
import "./libs/access/Ownable.sol";
import "./libs/utils/EnumerableSet.sol";
import "./libs/cryptography/MerkleProof.sol";
import "./libs/token/ERC721/IERC721.sol";
import "./libs/token/ERC721/ERC721Holder.sol";

import "./interfaces/IElpisHeroStakingFactory.sol";
import "./interfaces/IElpisBattle.sol";
import "./interfaces/IElpisHeroStakingPool.sol";

contract ElpisHeroStakingPool is IElpisHeroStakingPool, ERC721Holder, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    // Info of each user.
    struct UserInfo {
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardToClaim; //When stake or unstake, add pending reward to rewardToClaim.
        EnumerableSet.UintSet holderTokens; // Mapping from holder address to their (enumerable) set of owned tokens
        //
        // We do some fancy math here. Basically, any point in time, the amount of EBAs
        // entitled to a user but is pending to be distributed is:
        //   amount = holderTokens.length() // The amount of tokens in ``owner``'s account.
        //   pending reward = (amount * accEbaPerShare) - user.rewardDebt
        //
        // Whenever a user stake NFT to farm or unstake NFT token from farm. Here's what happens:
        //   1. The farm's `accEbaPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User's `rewardToClaim` gets updated..
        //   3. User's `holderTokens` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    uint256 public totalSupply = 0;
    string public name;
    // The ElpisMetaverseHeroes NFT
    IERC721 public elpisHeroes;
    // The Elpis Battle TOKEN!
    IElpisBattle public eba;
    // EBA tokens created per block.
    uint256 public ebaPerBlock;
    // Bonus muliplier for early eba makers.
    uint256 public BONUS_MULTIPLIER = 1;
    // The block number when EBAs mining starts.
    uint256 public startBlock;
    // The ElpisHeroStakingFactory address
    IElpisHeroStakingFactory public factory;
    // Last block number that EBAs distribution occurs.
    uint256 public lastRewardBlock;
    // EBA Accumulated per share.
    uint256 public accEbaPerShare;
    bytes32 public merkleRoot;

    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) private _userInfo;

    constructor() {
        factory = IElpisHeroStakingFactory(msg.sender);
    }

    function initialize(
        IERC721 _elpisHeroes,
        IElpisBattle _eba,
        string calldata _name,
        uint256 _ebaPerBlock,
        uint256 _startBlock,
        bytes32 _merkleRoot,
        address _owner
    ) external override {
        require(IElpisHeroStakingFactory(msg.sender) == factory, "FORBIDDEN"); // sufficient check

        elpisHeroes = _elpisHeroes;
        eba = _eba;
        name = _name;
        ebaPerBlock = _ebaPerBlock;
        startBlock = _startBlock;
        merkleRoot = _merkleRoot;
        lastRewardBlock = startBlock;
        accEbaPerShare = 0;
        transferOwnership(_owner);
    }

    function updateMultiplier(uint256 multiplierNumber) external onlyOwner {
        updateStakingPool();
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function updateEbaPerBlock(uint256 _ebaPerBlock)
        external
        override
        onlyOwner
    {
        updateStakingPool();
        ebaPerBlock = _ebaPerBlock;
        emit EbaPerBlockChanged(_ebaPerBlock);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    //View function to see user info
    function getUserInfo(address _user)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardToClaim,
            uint256 rewardDebt
        )
    {
        UserInfo storage user = _userInfo[_user];
        amount = user.holderTokens.length();
        rewardToClaim = user.rewardToClaim;
        rewardDebt = user.rewardDebt;
    }

    function unclaimed(address _user) external view override returns (uint256) {
        UserInfo storage user = _userInfo[_user];
        return user.rewardToClaim;
    }

    function pendingEbaReward(address _user)
        external
        view
        override
        returns (uint256)
    {
        UserInfo storage user = _userInfo[_user];
        uint256 _accEbaPerShare = accEbaPerShare;
        uint256 lpSupply = elpisHeroes.balanceOf(address(this));
        if (block.number > lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
            uint256 ebaReward = multiplier.mul(ebaPerBlock);
            _accEbaPerShare = _accEbaPerShare.add(ebaReward.div(lpSupply));
        }
        uint256 amount = user.holderTokens.length();
        return amount.mul(_accEbaPerShare).sub(user.rewardDebt);
    }

    /// Update pool reward variables
    function updateStakingPool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (totalSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
        uint256 ebaReward = multiplier.mul(ebaPerBlock);
        accEbaPerShare = accEbaPerShare.add(ebaReward.div(totalSupply));
        lastRewardBlock = block.number;
    }

    function claim() external override {
        updateStakingPool();

        UserInfo storage user = _userInfo[msg.sender];
        uint256 amount = user.holderTokens.length();
        if (amount > 0) {
            uint256 pending = amount.mul(accEbaPerShare).sub(user.rewardDebt);
            if (pending > 0) {
                user.rewardToClaim = user.rewardToClaim.add(pending);
            }
            user.rewardDebt = amount.mul(accEbaPerShare);
        }
        eba.mint(msg.sender, user.rewardToClaim);
        user.rewardToClaim = 0;

        emit Claimed(msg.sender, user.rewardToClaim);
    }

    function stake(
        uint256 _index,
        uint256 _tokenId,
        bytes32[] calldata _merkleProof
    ) external override {
        updateStakingPool();

        UserInfo storage user = _userInfo[msg.sender];
        if (user.holderTokens.length() > 0) {
            uint256 pending = user
                .holderTokens
                .length()
                .mul(accEbaPerShare)
                .sub(user.rewardDebt);
            if (pending > 0) {
                user.rewardToClaim = user.rewardToClaim.add(pending);
            }
        }

        require(_tokenId < 20000, "The tokenId is not in the Genesis");
        require(
            _tokenIsValid(_index, _tokenId, _merkleProof),
            "Verify tokenId failed"
        );
        totalSupply = totalSupply.add(1);
        elpisHeroes.safeTransferFrom(
            address(msg.sender),
            address(this),
            _tokenId
        );
        user.holderTokens.add(_tokenId);
        user.rewardDebt = user.holderTokens.length().mul(accEbaPerShare);

        emit Staked(msg.sender, _tokenId);
    }

    function batchStake(
        uint256[] calldata _indexes,
        uint256[] calldata _tokenIds,
        bytes32[][] calldata _merkleProofs
    ) external override {
        require(
            _indexes.length == _tokenIds.length &&
                _indexes.length == _merkleProofs.length,
            "indexess, tokenIds and merkleProofs length mismatch"
        );
        updateStakingPool();

        UserInfo storage user = _userInfo[msg.sender];
        if (user.holderTokens.length() > 0) {
            uint256 pending = user
                .holderTokens
                .length()
                .mul(accEbaPerShare)
                .sub(user.rewardDebt);
            if (pending > 0) {
                user.rewardToClaim = user.rewardToClaim.add(pending);
            }
        }

        for (uint256 i = 0; i < _indexes.length; ++i) {
            require(_tokenIds[i] < 20000, "The tokenId is not in the Genesis");
            require(
                _tokenIsValid(_indexes[i], _tokenIds[i], _merkleProofs[i]),
                "Verify tokenId failed"
            );
            totalSupply = totalSupply.add(1);
            elpisHeroes.safeTransferFrom(
                address(msg.sender),
                address(this),
                _tokenIds[i]
            );
            user.holderTokens.add(_tokenIds[i]);
        }
        user.rewardDebt = user.holderTokens.length().mul(accEbaPerShare);

        emit BatchStaked(msg.sender, _tokenIds);
    }

    function unstake(uint256 _tokenId) external override {
        updateStakingPool();

        UserInfo storage user = _userInfo[msg.sender];
        require(
            user.holderTokens.contains(_tokenId),
            "The tokenId hasn't been staked by the caller"
        );
        if (user.holderTokens.length() > 0) {
            uint256 pending = user
                .holderTokens
                .length()
                .mul(accEbaPerShare)
                .sub(user.rewardDebt);
            if (pending > 0) {
                user.rewardToClaim = user.rewardToClaim.add(pending);
            }
        }
        totalSupply = totalSupply.sub(1);
        user.holderTokens.remove(_tokenId);
        elpisHeroes.safeTransferFrom(
            address(this),
            address(msg.sender),
            _tokenId
        );
        user.rewardDebt = user.holderTokens.length().mul(accEbaPerShare);

        emit UnStaked(msg.sender, _tokenId);
    }

    function batchUnstake(uint256[] calldata _tokenIds) external override {
        updateStakingPool();

        UserInfo storage user = _userInfo[msg.sender];
        if (user.holderTokens.length() > 0) {
            uint256 pending = user
                .holderTokens
                .length()
                .mul(accEbaPerShare)
                .sub(user.rewardDebt);
            if (pending > 0) {
                user.rewardToClaim = user.rewardToClaim.add(pending);
            }
        }

        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            require(
                user.holderTokens.contains(_tokenIds[i]),
                "The tokenId hasn't been staked by caller"
            );
            totalSupply = totalSupply.sub(1);
            user.holderTokens.remove(_tokenIds[i]);
            elpisHeroes.safeTransferFrom(
                address(this),
                address(msg.sender),
                _tokenIds[i]
            );
        }
        user.rewardDebt = user.holderTokens.length().mul(accEbaPerShare);

        emit BatchUnStaked(msg.sender, _tokenIds);
    }

    function _tokenIsValid(
        uint256 _index,
        uint256 _tokenId,
        bytes32[] calldata _merkleProof
    ) internal view returns (bool) {
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(_index, _tokenId));
        return MerkleProof.verify(_merkleProof, merkleRoot, node);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
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
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IElpisHeroStakingFactory {
    /// @notice Emitted when a pool is created.
    /// @param name The name of pool.
    /// @param pool The address of the created pool.
    event PoolCreated(string name, address pool);

    /// @notice Creates a pool for the given paremeters.
    /// @param _name Pool's name.
    /// @param _ebaPerBlock EBA tokens created per block.
    /// @param _startBlock The block number when EBAs mining starts.
    /// @param _merkleRoot The block number when EBAs mining starts.
    /// @param _owner The owner of staking pool.
    /// @return pool The address of the newly created pool.
    function createPool(
        string calldata _name,
        uint256 _ebaPerBlock,
        uint256 _startBlock,
        bytes32 _merkleRoot,
        address _owner
    ) external returns (address pool);

    /// @return The number of pools created.
    function getStakingPoolsLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../libs/token/BEP20/IBEP20.sol";

interface IElpisBattle is IBEP20 {
    /**
     * @dev Creates `amount` tokens and assigns them to `_to`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token minter
     */
    function mint(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../libs/token/ERC721/IERC721.sol";
import "./IElpisBattle.sol";

interface IElpisHeroStakingPool {
    /// @notice Emitted when someone stake in the pool.
    event Staked(address indexed staker, uint256 tokenId);

    /// @notice Emitted when someone batch stake in the pool.
    event BatchStaked(address indexed staker, uint256[] tokenId);

    /// @notice Emitted when someone unstake from the pool.
    event UnStaked(address indexed staker, uint256 tokenId);

    /// @notice Emitted when someone batch unstake from the pool.
    event BatchUnStaked(address indexed staker, uint256[] tokenId);

    /// @notice Emitted when someone claim reward from the pool.
    event Claimed(address indexed staker, uint256 amount);

    /// @notice Emitted when the amount of EBA tokens created per block is changed.
    event EbaPerBlockChanged(uint256 ebaPerBlock);

    /// @notice update the amount EBA tokens created per block. Should only be called by the owner
    /// @param eabPerBlock The amount of EBAs tokens created per block.
    function updateEbaPerBlock(uint256 eabPerBlock) external;

    /// @notice View function to see pending eba on frontend.
    /// @param user The address of user.
    /// @return the pending reward of user.
    function pendingEbaReward(address user) external view returns (uint256);

    /// @notice View function to see the reward users have accumulated so far.
    /// @param user The address of user.
    /// @return the reward unclaimed of user.
    function unclaimed(address user) external view returns (uint256);

    /// @notice Stake NFT token to pool for EBA allocation.
    /// @param index The index of tokenId in the merkle tree.
    /// @param tokenId The token id of NFT asset.
    /// @param merkleProof A proof containing: sibling hashes on the branch from the leaf to the root of the merkle tree.
    function stake(
        uint256 index,
        uint256 tokenId,
        bytes32[] calldata merkleProof
    ) external;

    /// @notice batch stake implementation
    function batchStake(
        uint256[] calldata indexs,
        uint256[] calldata tokenIds,
        bytes32[][] calldata merkleProofs
    ) external;

    /// @notice UnStake NFT token from pool for EBA allocation.
    /// @param tokenId The token id of NFT asset.
    function unstake(uint256 tokenId) external;

    /// @notice batch unstake implementation
    function batchUnstake(uint256[] calldata tokenIds) external;

    /// @notice claim user rewards.
    function claim() external;

    /// @notice Called once by the factory at time of deployment.
    /// @param _elpisHeroes The ElpisMetaverseHeroes NFT address.
    /// @param _eba The EBA token address.
    /// @param _name The name of the pool.
    /// @param _ebaPerBlock EBA tokens created per block.
    /// @param _startBlock The block number when EBAs mining starts.
    /// @param _merkleRoot A proof containing: sibling hashes on the branch from the leaf to the root of the merkle tree.
    /// @param _owner The owner of staking pool.
    function initialize(
        IERC721 _elpisHeroes,
        IElpisBattle _eba,
        string calldata _name,
        uint256 _ebaPerBlock,
        uint256 _startBlock,
        bytes32 _merkleRoot,
        address _owner
    ) external;
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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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