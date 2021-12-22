/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/// @title TicketNFT contract interface
interface ITicketNFT {
    function mintNFT(string memory tokenURI) external returns (uint256);
}


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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

/// @title RaffleCampaign
contract RaffleCampaign is Ownable {

    /// @dev safemath library
    using SafeMath for uint256;
    
    /// @dev declare ticketNFT of ITicketNFT interface
    ITicketNFT ticketNFT;

    /// @notice raffle's name
    string public raffleName;

    /// @notice raffle's description
    string public raffleDescription;

    /// @notice campaign's start time
    uint public campaignStart;

    /// @notice campaign's end time
    uint public campaignEnd;

    /// @notice price per ticket
    uint public ticketPrice;

    /// @notice one owner's maximum purchase amount per raffle
    uint public maxBuyAmount = 9000;

    /// @notice total number of tickets per raffle
    uint public totalTickets;

    /// @notice total number of winners per raffle
    uint public totalWinners;

    /// @notice bought tickets array
    uint[] public tickets;

    /// @notice drawn tickets array
    uint[] public drawnTickets;

    /// @notice evaluate campaign to be expired or not
    bool public campaignFinished;

    /// @notice campaign manager's address
    address public manager;

    /// @dev specified mappings of this contract
    mapping (uint => address) public ticketOwner;
    mapping (address => uint) public ownerTicketCount;
    mapping (uint => string) public tokenUriMap;

    /// @dev Events of each function
    event CreateCampaign(bool finished, address tokenaddress);
    event TicketBought(uint ticketNum, uint256 tokenId, string tokenUri);
    event TicketDrawn(uint ticketId, uint ticketNum);
    event DeleteCampaign(bool finished);

    /// @dev modifier to evaluate campaign's finish
    modifier finishedCampaign(bool _finished) {
        require(!_finished, "Raffle campaign finished.");
        _;
    }

    /// @dev modifier to confirm campaign period
    modifier fixedTimeline() {
        require(block.timestamp > campaignStart && block.timestamp < campaignEnd, "User can't buy ticket.");
        _;
    }

    /// @dev modifier to confirm manager can draw tickets
    modifier isDrawTicket() {
        require(tickets.length >= 1 && block.timestamp > campaignEnd, "Manager can't draw ticket.");
        _;
    }

    /// @notice this contract constructor
    /// @param _ticketNFT is TicketNFT contract address.
    constructor(string memory _raffleName, string memory _raffleDescription, uint _campaignStart, uint _campaignEnd, uint _ticketPrice, uint _totalTickets, uint _totalWinners, address _ticketNFT) {
        require(_campaignStart < _campaignEnd, "Input correct campaign time.");
        require(_totalTickets > 1 && _totalTickets < 25000, "Total tickets range is 1 ~ 25000.");
        require(_totalTickets > _totalWinners, "Total tickets should be more than total winners.");

        campaignFinished = false;
        manager = msg.sender;

        raffleName = _raffleName;
        raffleDescription = _raffleDescription;
        campaignStart = _campaignStart;
        campaignEnd = _campaignEnd;
        ticketPrice = _ticketPrice;
        totalTickets = _totalTickets;
        totalWinners = _totalWinners;

        ticketNFT = ITicketNFT(_ticketNFT);

        // emit CreateCampaign event
        emit CreateCampaign(campaignFinished, _ticketNFT);
    }

    /// @notice forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
    function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
    @notice function to buy a ticket.
    @dev only users not managers.
    @param _ticketNum is ticket's number to be bought by user.
    @param _tokenUri is ticket NFT ipfs url.
    */
    function buyTicket(uint _ticketNum, string memory _tokenUri) public fixedTimeline finishedCampaign(campaignFinished) {
        require(ticketOwner[_ticketNum] == address(0), "One ticket can't be sold more than twice.");
        require(manager != msg.sender, "Manager can't buy ticket.");
        require(ownerTicketCount[msg.sender] < maxBuyAmount / ticketPrice, "Number of tickets one user can buy is limited.");
        require(tickets.length < totalTickets, "All the tickets were sold.");
        
        tickets.push(_ticketNum);
        tokenUriMap[_ticketNum] = _tokenUri;
        ticketOwner[_ticketNum] = msg.sender;
        ownerTicketCount[msg.sender] = ownerTicketCount[msg.sender].add(1);

        uint256 _tokenId = ticketNFT.mintNFT(_tokenUri);

        // emit TicketBought event
        emit TicketBought(_ticketNum, _tokenId, _tokenUri);
    }

    /**
    @notice function to delete a raffle campaign when it is expired.
    @dev only manager.
    */
    function deleteCampaign() public onlyOwner finishedCampaign(campaignFinished) {
        require(tickets.length < 1, "Raffle campaign can't delete as one more tickets were sold.");
        require(block.timestamp < campaignEnd, "Raffle campaign expired can't delete.");

        campaignFinished = true;

        // emit DeleteCampaign event
        emit DeleteCampaign(campaignFinished);
    }

    /**
    @notice function to draw a ticket manually.
    @dev only manager.
    @param _ticketNum is a bought ticket number to be drawn by manager.
    */
    function manualDrawTicket(uint _ticketNum) public onlyOwner isDrawTicket finishedCampaign(campaignFinished) {
        uint idx;
        uint isMatched;
        for (uint id = 0; id < tickets.length; id++) {
            if (tickets[id] == _ticketNum) {
                drawnTickets.push(tickets[id]);
                _removeTicket(id);
                idx = id;
                isMatched = isMatched.add(1);
            }
        }
        require(isMatched == 1, "There are no matches.");
        
        // emit TicketDrawn event
        emit TicketDrawn(idx, _ticketNum);
    }

    /**
    @notice function to draw a ticket randomly.
    @dev only manager.
    */
    function autoDrawnTicket() public onlyOwner isDrawTicket finishedCampaign(campaignFinished) {
        uint id = _randomTicketId();
        uint drawnTicketNum = tickets[id];
        drawnTickets.push(drawnTicketNum);
        _removeTicket(id);

        // emit TicketDrawn event
        emit TicketDrawn(id, drawnTicketNum);
    }

    /**
    @notice internal function to remove a ticket from tickets array sold.
    @param _ticketId is index of ticket sold to be drawn by manager.
    */
    function _removeTicket(uint _ticketId) internal {
        require(_ticketId < tickets.length, "Tickets array index is out of bound.");
        
        for (uint i = _ticketId; i < tickets.length - 1; i++) {
            tickets[i] = tickets[i+1];
        }

        tickets.pop();
    }

    /// @notice internal function to get a random ticket index.
    function _randomTicketId() internal view returns (uint) {
        uint idx = _random() % tickets.length;
        return idx;
    }

    /// @notice internal function to get a random number using block number.
    function _random() internal view returns (uint) {
        uint seed = block.number;

        uint a = 1103515245;
        uint c = 12345;
        uint m = 2 ** 32;

        return (a * seed + c) % m;
    }

    /// @notice function to get current drawn ticket number.
    function getCurrentWinner() public view returns (uint) {
        require(drawnTickets.length > 0);
        return drawnTickets[drawnTickets.length - 1];
    }

    /// @notice function to get current drawn ticket's owner address.
    function getCurrentWinnerAddress() public view returns (address) {
        require(drawnTickets.length > 0);
        uint drawnTicketNum = drawnTickets[drawnTickets.length - 1];
        return ticketOwner[drawnTicketNum];
    }

    /// @notice function to get total sold tickets count.
    function getBoughtTicketsCount() public view returns (uint) {
        return tickets.length + drawnTickets.length;
    }

    /// @notice function to get undrawned tickets count in sold tickets.
    function getUndrawnTicketsCount() public view returns (uint) {
        return tickets.length;
    }

    /// @notice function to get total drawn tickets count.
    function getDrawnTicketsCount() public view returns (uint) {
        return drawnTickets.length;
    }

    /// @notice function to get one owner's total tickets count.
    /// @param _owner is one owner's address.
    function getOwnerTicketsCount(address _owner) public view returns (uint) {
        return ownerTicketCount[_owner];
    }

    /// @notice function to get one owner's total tickets price.
    /// @param _owner is one owner's address.
    function getOwnerTicketsPrice(address _owner) public view returns (uint) {
        return ticketPrice * ownerTicketCount[_owner];
    }

    /// @notice function to get one ticket's token uri.
    /// @param _ticketNum is one ticket's number.
    function getTicketUri(uint _ticketNum) public view returns (string memory) {
        return tokenUriMap[_ticketNum];
    }

    /// @notice function to get remained tickets count.
    function getRemainTickets() public view returns (uint) {
        return totalTickets - (tickets.length + drawnTickets.length);
    }

    /// @notice function to get total sold tickets price.
    function getBoughtTicketsPrice() public view returns (uint) {
        return ticketPrice * (tickets.length + drawnTickets.length);
    }

    /// @notice function to get total tickets price.
    function getTotalTicketsPrice() public view returns (uint) {
        return ticketPrice * totalTickets;
    }

}