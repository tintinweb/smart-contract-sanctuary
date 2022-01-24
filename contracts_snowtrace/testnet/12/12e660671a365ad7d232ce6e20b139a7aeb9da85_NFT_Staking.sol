/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-23
*/

// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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


// File contracts/libraries/SafeMath.sol


// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File contracts/NFT_Staking.sol

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.0 <0.9.0;

interface INFT {
    function getWeight(uint256 nftId) external view returns (uint16);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

interface Shady {
    function mint(address _to, uint256 _amount) external;
}

contract NFT_Staking is Ownable {
    using SafeMath for uint256;

    INFT public nft;
    Shady public shady;
    address public devAddress;

    uint256 public constant YIELD_CPS = 10185674340; // tokens created per nft weight per second
    uint256 public constant CLAIM_TOKEN_TAX_PERCENTAGE = 2; // 2%
    uint256 public constant UNSTAKE_COOLDOWN_DURATION = 2 days; // TODO: do we have cool down and how long?

    struct StakeDetails {
        address owner;
        uint256 tokenId;
        uint256 startTimestamp;
        bool staked;
    }

    struct OwnedStakeInfo {
        uint256 tokenId;
        uint256 weight;
        uint256 accrual;
    }

    mapping(uint256 => StakeDetails) public stakes;

    struct UnstakeCooldown {
        address owner;
        uint256 tokenId;
        uint256 startTimestamp;
        bool present;
    }

    struct OwnedCooldownInfo {
        uint256 tokenId;
        uint256 weight;
        uint256 startTimestamp;
    }

    mapping(uint256 => UnstakeCooldown) public unstakeCooldowns;

    mapping(address => mapping(uint256 => uint256)) private ownedStakes; // (user, index) => stake
    mapping(uint256 => uint256) private ownedStakesIndex; // token id => index in its owner's stake list
    mapping(address => uint256) public ownedStakesBalance; // user => stake count

    mapping(address => mapping(uint256 => uint256)) private ownedCooldowns; // (user, index) => cooldown
    mapping(uint256 => uint256) private ownedCooldownsIndex; // token id => index in its owner's cooldown list
    mapping(address => uint256) public ownedCooldownsBalance; // user => cooldown count

    constructor(
        INFT _nft,
        Shady _shady,
        address _devAddress
    ) {
        nft = _nft;
        shady = _shady;
        devAddress = _devAddress;
    }

    /* View */
    function getTokensAccruedForMany(uint256[] calldata _tokenIds)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokenAmounts = new uint256[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenAmounts[i] = _getTokensAccruedFor(_tokenIds[i], false);
        }
        return tokenAmounts;
    }

    function _getTokensAccruedFor(uint256 _tokenId, bool checkOwnership)
        internal
        view
        returns (uint256)
    {
        StakeDetails memory stake = stakes[_tokenId];
        require(stake.staked, "This token isn't staked");
        if (checkOwnership) {
            require(stake.owner == _msgSender(), "You don't own this token");
        }
        return
            (block.timestamp - stake.startTimestamp) *
            nft.getWeight(_tokenId) * // TODO: add / fix logic
            YIELD_CPS;
    }

    /* Mutators */

    function stakeMany(uint256[] calldata _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(
                nft.ownerOf(tokenId) == _msgSender(),
                "You don't own this token"
            );

            nft.transferFrom(_msgSender(), address(this), tokenId);
            _addNftToStaking(tokenId, _msgSender());
        }
    }

    function claimTokensAndMaybeUnstake(
        uint256[] calldata _tokenIds,
        bool unstake
    ) external {
        uint256 totalClaimed = 0;
        uint256 totalTaxed = 0;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 tokens = _getTokensAccruedFor(tokenId, true); // also checks that msg.sender owns this token
            uint256 taxAmount = (tokens * CLAIM_TOKEN_TAX_PERCENTAGE + 99) /
                100; // +99 to round the division up

            totalClaimed += tokens - taxAmount;
            totalTaxed += taxAmount;
            stakes[tokenId].startTimestamp = block.timestamp;

            if (unstake) {
                _moveNftToCooldown(tokenId);
            }
        }

        shady.mint(_msgSender(), totalClaimed);
        shady.mint(devAddress, totalTaxed);
    }

    function withdrawNfts(uint256[] calldata _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            UnstakeCooldown memory cooldown = unstakeCooldowns[tokenId];

            require(cooldown.present, "Token is not in cooldown");
            require(_msgSender() == cooldown.owner, "You don't own this token");
            require(
                block.timestamp >=
                    cooldown.startTimestamp + UNSTAKE_COOLDOWN_DURATION,
                "Token is still in cooldown"
            );

            nft.transferFrom(address(this), _msgSender(), tokenId);
            _removeNftFromCooldown(tokenId);
        }
    }

    function _addNftToStaking(uint256 _tokenId, address _owner) internal {
        stakes[_tokenId] = StakeDetails({
            owner: _owner,
            tokenId: _tokenId,
            startTimestamp: block.timestamp,
            staked: true
        });
        _addStakeToOwnerEnumeration(_owner, _tokenId);
    }

    function _moveNftToCooldown(uint256 _tokenId) internal {
        address owner = stakes[_tokenId].owner;
        unstakeCooldowns[_tokenId] = UnstakeCooldown({
            owner: stakes[_tokenId].owner,
            tokenId: _tokenId,
            startTimestamp: block.timestamp,
            present: true
        });

        delete stakes[_tokenId];
        _removeStakeFromOwnerEnumeration(owner, _tokenId);
        _addCooldownToOwnerEnumeration(owner, _tokenId);
    }

    function _removeNftFromCooldown(uint256 _tokenId) internal {
        address owner = unstakeCooldowns[_tokenId].owner;
        delete unstakeCooldowns[_tokenId];
        _removeCooldownFromOwnerEnumeration(owner, _tokenId);
    }

    /* Enumeration, adopted from OpenZeppelin ERC721Enumerable */

    function stakeOfOwnerByIndex(address _owner, uint256 _index)
        public
        view
        returns (uint256)
    {
        require(
            _index < ownedStakesBalance[_owner],
            "owner index out of bounds"
        );
        return ownedStakes[_owner][_index];
    }

    function batchedStakesOfOwner(
        address _owner,
        uint256 _offset,
        uint256 _maxSize
    ) public view returns (OwnedStakeInfo[] memory) {
        if (_offset >= ownedStakesBalance[_owner]) {
            return new OwnedStakeInfo[](0);
        }

        uint256 outputSize = _maxSize;
        if (_offset + _maxSize >= ownedStakesBalance[_owner]) {
            outputSize = ownedStakesBalance[_owner] - _offset;
        }
        OwnedStakeInfo[] memory outputs = new OwnedStakeInfo[](outputSize);

        for (uint256 i = 0; i < outputSize; i++) {
            uint256 tokenId = stakeOfOwnerByIndex(_owner, _offset + i);

            outputs[i] = OwnedStakeInfo({
                tokenId: tokenId,
                weight: nft.getWeight(tokenId),
                accrual: _getTokensAccruedFor(tokenId, false)
            });
        }

        return outputs;
    }

    function _addStakeToOwnerEnumeration(address _owner, uint256 _tokenId)
        internal
    {
        uint256 length = ownedStakesBalance[_owner];
        ownedStakes[_owner][length] = _tokenId;
        ownedStakesIndex[_tokenId] = length;
        ownedStakesBalance[_owner]++;
    }

    function _removeStakeFromOwnerEnumeration(address _owner, uint256 _tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ownedStakesBalance[_owner] - 1;
        uint256 tokenIndex = ownedStakesIndex[_tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownedStakes[_owner][lastTokenIndex];

            ownedStakes[_owner][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            ownedStakesIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete ownedStakesIndex[_tokenId];
        delete ownedStakes[_owner][lastTokenIndex];
        ownedStakesBalance[_owner]--;
    }

    function cooldownOfOwnerByIndex(address _owner, uint256 _index)
        public
        view
        returns (uint256)
    {
        require(
            _index < ownedCooldownsBalance[_owner],
            "owner index out of bounds"
        );
        return ownedCooldowns[_owner][_index];
    }

    function batchedCooldownsOfOwner(
        address _owner,
        uint256 _offset,
        uint256 _maxSize
    ) public view returns (OwnedCooldownInfo[] memory) {
        if (_offset >= ownedCooldownsBalance[_owner]) {
            return new OwnedCooldownInfo[](0);
        }

        uint256 outputSize = _maxSize;
        if (_offset + _maxSize >= ownedCooldownsBalance[_owner]) {
            outputSize = ownedCooldownsBalance[_owner] - _offset;
        }
        OwnedCooldownInfo[] memory outputs = new OwnedCooldownInfo[](
            outputSize
        );

        for (uint256 i = 0; i < outputSize; i++) {
            uint256 tokenId = cooldownOfOwnerByIndex(_owner, _offset + i);

            outputs[i] = OwnedCooldownInfo({
                tokenId: tokenId,
                weight: nft.getWeight(tokenId),
                startTimestamp: unstakeCooldowns[tokenId].startTimestamp
            });
        }

        return outputs;
    }

    function _addCooldownToOwnerEnumeration(address _owner, uint256 _tokenId)
        internal
    {
        uint256 length = ownedCooldownsBalance[_owner];
        ownedCooldowns[_owner][length] = _tokenId;
        ownedCooldownsIndex[_tokenId] = length;
        ownedCooldownsBalance[_owner]++;
    }

    function _removeCooldownFromOwnerEnumeration(
        address _owner,
        uint256 _tokenId
    ) private {
        uint256 lastTokenIndex = ownedCooldownsBalance[_owner] - 1;
        uint256 tokenIndex = ownedCooldownsIndex[_tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownedCooldowns[_owner][lastTokenIndex];
            ownedCooldowns[_owner][tokenIndex] = lastTokenId;
            ownedCooldownsIndex[lastTokenId] = tokenIndex;
        }

        delete ownedCooldownsIndex[_tokenId];
        delete ownedCooldowns[_owner][lastTokenIndex];
        ownedCooldownsBalance[_owner]--;
    }
}