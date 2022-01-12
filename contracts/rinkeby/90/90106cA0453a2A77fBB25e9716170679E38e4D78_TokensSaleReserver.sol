/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)


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


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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

interface IRebelBots {
    function balanceOf(address owner) view external returns (uint256);
}


/**
 * @dev Contract that allows users who holds Rebel Bots NFTs, when the sale is open, to buy the reservation of the RBLS tokens,
 * based on the amount of Rebel Bots in the wallet. Contract accept ETH payments for this operation and stores the data about
 * the buyer, tokens number, and address for the RBLS token receiving ('airdrop' address on Polygon network) in the blockchain.
 * If the buyer makes several reservations, the 'airdrop' address for the RBLS tokens will be taken from the last reservation
 * operation for all reserved RBLS tokens payout
 *
 * After the sale is closed, appropriate amounts of RBLS token will be sent to each buyer to their airdrop address
 * on the Polygon network.
*/
contract TokensSaleReserver is Ownable, Pausable {

    using SafeMath for uint256;

    // Rebel Bots ERC721 contract reference
    IRebelBots private _rebelBotsContract;

    // Reservation start timestamp
    uint _saleStartTs;
    // Reservation end timestamp
    uint _saleEndTs;

    // RBLS token reservation price
    uint256 private _tokenPrice = 3200000; // 0.0000000000032 ETH

    // Limit of max amount of RBLS tokens that is allowed to reserve for users that holds less or equal then {_rbNumbersPriceThreshold} Rebel Bots tokens
    uint256 private _plainRbHolderTokensLimit = 250000000000;
    // Limit of max amount of RBLS tokens that is allowed to reserve for users that holds more then {_rbNumbersPriceThreshold} Rebel Bots tokens
    uint256 private _majorRbHoldersTokensLimit = 750000000000;
    // Threshold of the owned Rebel Bots NFTs that regulates limit of the RBLS tokens that is possible to reserve
    uint256 private _rbNumbersPriceThreshold = 5;

    // Mapping from buyer address to number of reserved RBLS tokens
    mapping(address => uint256) private reservedTokens;

    // Mapping from buyer address to address where this user will get an airdrop of RBLS tokens
    mapping(address => address) private airdropAddresses;

    // Array with all buyers addresses, used for enumeration
    address[] private _allBuyers;

    /**
     * @dev Emitted when `buyer` reserves 'tokensNumber' RBLS tokens
    */
    event TokensSell(
        address indexed buyer,
        address airdropAddress,
        uint tokensNumber,
        uint256 rbOwnedNumber
    );

    constructor(address rbContractAddress, uint saleStartTs, uint saleEndTs) {
        _rebelBotsContract = IRebelBots(rbContractAddress);
        _saleStartTs = saleStartTs;
        _saleEndTs = saleEndTs;
    }

    /**
     * @dev updates limits of RBLS tokens allowed for the reservation
    */
    function updateLimits(uint256 plainRbHolderTokensLimit, uint256 majorRbHoldersTokensLimit, uint rbNumbersPriceThreshold) public onlyOwner {
        require(plainRbHolderTokensLimit >= 0, "plainRbHolderTokensLimit should be positive");
        require(majorRbHoldersTokensLimit >= 0, "majorRbHoldersTokensLimit should be positive");
        require(rbNumbersPriceThreshold > 0, "rbNumbersPriceThreshold should be positive");
        _plainRbHolderTokensLimit = plainRbHolderTokensLimit;
        _majorRbHoldersTokensLimit = majorRbHoldersTokensLimit;
        _rbNumbersPriceThreshold = rbNumbersPriceThreshold;
    }

   /**
     * @dev updates RBLS token reservation price
    */
    function updatePrice(uint256 tokenPrice) public onlyOwner {
        require(tokenPrice >= 0, "tokenPrice should be positive");
        _tokenPrice = tokenPrice;
    }

    /**
     * @dev returns the maximum possible amount of RBLS tokens that is allowed to reserve for 'rbHolder' address
    */
    function getMaxTokensBuyLimit(address rbHolder) public view returns (uint256) {
        uint256 rbTokensBalance = _rebelBotsContract.balanceOf(rbHolder);

        return getMaxTokensBuyLimit(rbHolder, rbTokensBalance);
    }

    /**
     * @dev returns the maximum possible amount of RBLS tokens that is allowed to reserve for 'rbHolder' address
     * 'rbTokensBalance' - balance of th Rebel Bots NFT tokens of the 'rbHolder' address
    */
    function getMaxTokensBuyLimit(address rbHolder, uint256 rbTokensBalance) private view returns (uint256) {
        uint256 totalTokensLimit;
        if (rbTokensBalance == 0) {
            return 0;
        } else if (rbTokensBalance <= _rbNumbersPriceThreshold) {
            totalTokensLimit = _plainRbHolderTokensLimit;
        } else {
            totalTokensLimit = _majorRbHoldersTokensLimit;
        }
        uint256 reservedTokensNumber = reservedTokens[rbHolder];
        return totalTokensLimit.sub(reservedTokensNumber);
    }

    /**
     * @dev reserves 'tokensNumber' RBLS tokens for the airdrop to the 'airdropAddress' address
    */
    function reserveTokens(uint256 tokensNumber, address airdropAddress) whenNotPaused public payable {
        require(airdropAddress != address(this) && airdropAddress != address(0), "Incorrect airdrop address");
        require(_tokenPrice.mul(tokensNumber) == msg.value, "Ether value sent is too low");
        require(block.timestamp >= _saleStartTs && block.timestamp <= _saleEndTs, "Token sale is not available now");

        address buyer = _msgSender();
        uint256 rbTokensBalance = _rebelBotsContract.balanceOf(buyer);
        uint256 maxTokensBuyLimit = getMaxTokensBuyLimit(buyer, rbTokensBalance);

        require(tokensNumber <= maxTokensBuyLimit, "Tokens number exceeds the allowed number to reserve");

        if (reservedTokens[buyer] == 0) {
            _allBuyers.push(buyer);
        }
        reservedTokens[buyer] = reservedTokens[buyer] + tokensNumber;
        airdropAddresses[buyer] = airdropAddress;

        emit TokensSell(buyer, airdropAddress, tokensNumber, rbTokensBalance);
    }


    /**
     * @dev returns airdrop address for RBLS token for certain buyer address
    */
    function getAirdropAddress(address buyer) public view returns(address) {
        return airdropAddresses[buyer];
    }

    /**
     * @dev returns reserved RBLS tokens number for certain buyer address
    */
    function getReservedTokens(address buyer) public view returns(uint256) {
        return reservedTokens[buyer];
    }

    /**
    * @dev returns total count of addresses that made the reservation
    */
    function buyersCount() public view returns(uint256) {
        return _allBuyers.length;
    }

    /**
    * @dev returns buyer address at a given `index` of all the reservation addresses
    */
    function buyerByIndex(uint256 index) public view returns(address) {
        return _allBuyers[index];
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}