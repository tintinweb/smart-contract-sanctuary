/**
 *Submitted for verification at FtmScan.com on 2021-11-16
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/utils/math/[email protected]

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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


// File contracts/PrizeManager.sol

/**
 * @dev A piece of a contract to store prizes, to be used for raffles/lotteries, etc
 *  - this ONLY handles adding/removing prizes.  It doesn't handle ticketing or awarding prizes. Take care of that yo'self fool
 */
abstract contract PrizeManager is Ownable {

    event PrizeAdded(uint place, PrizeType prizeType, address tokenContract, uint tokenIdOrValue);
    event PrizeRemoved(uint place);

    enum PrizeType{ NATIVE_CURRENCY, ERC20, ERC721 }

    /**
    * @dev The details of a single prize (there may be multiple prizes per place)
    *  - each prize could be an amount of native token, an amount of an ERC20, or a single NFT token
    */
    struct Prize {
        PrizeType prizeType; // is the prize the native currency
        uint tokenIdOrValue; // tokenId if ERC721, value if ERC20 or isNativeCurrency
        address tokenContract; // could be ERC721 or ERC20. Use zero address if none
    }

    /**
    * @dev [place][index]: Prize
    * so a place getter can have more than one prize
    */
    mapping(uint => mapping(uint => Prize)) public prizes;

    /**
    * @dev [place]: numberOfPrizes
    * so we can iterate over prizes per place without going past the last one
    */
    mapping(uint => uint) public numberOfPrizesPerPlace;

    /**
    * @dev this to make iterating easier
    */
    function getPrizeAtIndexForPlace(uint place, uint index) public view returns (Prize memory) {
        require(index < numberOfPrizesPerPlace[place], "There aren't that many prizes for the provided place");
        return prizes[place][index];
    }

    /**
    * @dev add a single prize for a given place
    */
    function addPrizeForPlace(uint place, PrizeType prizeType, uint tokenIdOrValue, address tokenContract) public virtual onlyOwner {
        uint index = numberOfPrizesPerPlace[place];
        prizes[place][index] = Prize(prizeType, tokenIdOrValue, tokenContract);
        numberOfPrizesPerPlace[place]++;
        emit PrizeAdded(place, prizeType, tokenContract, tokenIdOrValue);
    }

    /**
    * @dev remove a single prize for a given place
    */
    function removePrizeAtIndexForPlace(uint place, uint index) public virtual onlyOwner {
        uint lastIndex = numberOfPrizesPerPlace[place] - 1;
        if (index != lastIndex) {
            Prize memory lastPrize = prizes[place][lastIndex];
            prizes[place][index] = lastPrize;
        }
        delete prizes[place][lastIndex];
        numberOfPrizesPerPlace[place]--;
        emit PrizeRemoved(place);
    }
}


// File contracts/Ticketable.sol

/**
 * @dev A piece of a contract to store prizes, to be used for raffles/lotteries, etc
 *  - this ONLY handles adding/removing prizes.  It doesn't handle ticketing or awarding prizes. Take care of that yo'self fool
 */
abstract contract Ticketable is Ownable {

    /**
    * @dev the max number of tickets we can issue.  0 for unlimited
    */
    uint public maxTickets = 0;

    /**
    * @dev the number of tickets we have issued so far
    */
    uint public ticketsIssued = 0;

    /**
    * @dev [ticketNumber]: address of holder
    *  so we can look up the winner easily
    */
    mapping(uint => address) public ticketHolders;

    /**
    * @dev [owner]: array of ticket numbers
    *  so we can enumerate through them if required
    */
    mapping(address => uint[]) public ticketsHeld;

    /**
    * @dev issue a number of new tickets to a single address
    *  - no logic here for payment for the ticket. That should be handled by consuming contract
    */
    function issueTickets(address ticketHolder, uint numberOfTickets) internal {
        require(maxTickets == 0 || ticketsIssued + numberOfTickets <= maxTickets, "Cannot issue this many tickets under current max supply");
        for (uint i = ticketsIssued; i < ticketsIssued + numberOfTickets; i++) {
            ticketHolders[i] = ticketHolder;
            ticketsHeld[ticketHolder].push(i);
        }
        ticketsIssued+= numberOfTickets;
    }

    /**
    * @dev burn a ticket, in case its been gained unfairly or by error
    *  - this isn't written to be efficient. We shouldn't need it a lot
    */
    function burnTicket(uint ticketNumber) public onlyOwner {
        require(ticketsIssued > ticketNumber, "Ticket does not exist");
        address ticketOwner = ticketHolders[ticketNumber];

        uint[] memory oldTicketsHeld = ticketsHeld[ticketOwner];

        for (uint i = 0; i < oldTicketsHeld.length; i++) {
            if (oldTicketsHeld[i] != ticketNumber) {
                ticketsHeld[ticketOwner][i] = oldTicketsHeld[i];
            }
        }
        ticketsHeld[ticketOwner].pop();
        ticketHolders[ticketNumber] = address(0);
    }

    function ticketForOwnerAtIndex(address owner, uint index) public view returns (uint) {
        return ticketsHeld[owner][index];
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


// File contracts/Pausable.sol


abstract contract Pausable is Ownable {

    bool public isPaused;

    /**
    * @dev a modifier to restrict function access to wallets holding tokens for a specific contract
    */
    modifier isNotPaused() {
        require(isPaused == false, "This function cannot be performed when the contract is paused");
        _;
    }

    function setIsPaused(bool newValue) public onlyOwner {
        isPaused = newValue;
    }
}


// File contracts/Raffle.sol

// A raffle contract - can sell tickets, assign prizes, and award the prizes (does not include selecting winning ticket)
contract Raffle is Ownable, Pausable, PrizeManager, Ticketable, IERC721Receiver {
    using SafeMath for uint256;

    event TicketSale(address purchasor, uint numberOfTickets);
    event PrizeAwarded(uint place, uint ticketNumber);

    uint public ticketPrice;

    /**
    * @dev award the prizes for getting a place (selecting winner happens outside the contract for now) TODO: use Chainlink VRF
    */
    function awardPrize(uint place, uint ticketNumber) public onlyOwner {
        address winningAddress = ticketHolders[ticketNumber];
        require(winningAddress != address(0), "The winning ticket is not owned by a valid wallet");
        uint numberOfPrizes = numberOfPrizesPerPlace[place];

        for (uint i = 0; i < numberOfPrizes; i++) {
            Prize memory prize = prizes[place][i];
            if (prize.prizeType == PrizeType.NATIVE_CURRENCY) {
                require(address(this).balance >= prize.tokenIdOrValue, "Insufficient funds to pay prize");
                payable(winningAddress).transfer(prize.tokenIdOrValue);
            }
            if (prize.prizeType == PrizeType.ERC20) {
                require(IERC20(prize.tokenContract).balanceOf(address(this)) >= prize.tokenIdOrValue, "Insufficient funds to pay prize");
                IERC20(prize.tokenContract).transfer(winningAddress, prize.tokenIdOrValue);
            }
            if (prize.prizeType == PrizeType.ERC721) {
                require(IERC721(prize.tokenContract).ownerOf(prize.tokenIdOrValue) == address(this), "The prize token is not in this contract");
                IERC721(prize.tokenContract).safeTransferFrom(address(this), winningAddress, prize.tokenIdOrValue);
            }
        }
        emit PrizeAwarded(place, ticketNumber);
    }

    /**
    * @dev purchase tickets (the Ticketable extension handles managing them)
    */
    function buyTickets(uint numberOfTickets) public virtual payable isNotPaused {
        require(ticketPrice == 0 || msg.value >= numberOfTickets.mul(ticketPrice), "Incorrect payable amount for number of tickets bought");
        issueTickets(msg.sender, numberOfTickets);
        emit TicketSale(msg.sender, numberOfTickets);
    }

    function depositERC20(address tokenContract, uint amount) external {
        IERC20(tokenContract).transferFrom(msg.sender, address(this), amount);
    }

    function depositERC721(address tokenContract, uint tokenId) external {
        IERC721(tokenContract).safeTransferFrom(msg.sender, address(this), tokenId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) public override view returns (bytes4) {
        return IERC721Receiver(this).onERC721Received.selector;
    }

    function setTicketPrice(uint price) public onlyOwner {
        ticketPrice = price;
    }

    function withdrawProceeds(address toWallet, uint amount) public onlyOwner {
        payable(toWallet).transfer(amount);
    }
}