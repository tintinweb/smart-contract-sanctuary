/**
 *Submitted for verification at polygonscan.com on 2021-07-31
*/

// File: @openzeppelin\contracts\security\ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: node_modules\@openzeppelin\contracts\utils\Context.sol


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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol


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
    constructor () {
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

// File: @openzeppelin\contracts\utils\Strings.sol


pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// File: contracts\VoteMaster.sol


pragma solidity 0.8.6;




contract VoteMaster is ReentrancyGuard, Ownable {

    using Strings for uint256;

    struct Bet {
        uint256 option;
        uint256 amount;
        uint256 winnings;
    }

    struct Vote {
        uint256 category;
        uint256 result;
        uint256 startTime;
        uint256 endTime;   
        uint256 resultTime;
        uint256 totalBet;
        string title;
        string [] options;
        uint256 [] percentages;
        uint256 [] totals;
        address [] addresses;
        mapping (address => Bet) bets;
    }
    
    struct VoteInfo {
        uint256 category;
        uint256 result;
        uint256 startTime;
        uint256 endTime;   
        uint256 resultTime;
        string title;
        string [] options;
        uint256 [] percentages;
        uint256 numBets;
        uint256 totalBet;
        Bet bet;
    }

    uint256 public voteID;
    uint256 private accruedFees;
    mapping (uint256 => Vote) private votes;

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "VoteMaster: Only EOA.");
        _;
    }

    constructor() { }

    function openVote(uint256 category, string memory title, string [] memory options, uint256 startTime, uint256 endTime, uint256 resultTime)
        public
        onlyOwner
        onlyEOA
    {
        voteID++;
        Vote storage vote = votes[voteID];
        vote.category = category;
        vote.title = title;
        vote.options = options;
        vote.startTime = startTime;
        vote.endTime = endTime;
        vote.resultTime = resultTime;
        vote.percentages = new uint256 [](options.length);
        vote.totals = new uint256 [](options.length);
    }

    function closeVote(uint256 id, uint256 option) 
        public
        onlyOwner
        onlyEOA
    {
        // Initial checks
        require (id > 0 && id <= voteID, "VoteMaster: Invalid ID.");
        require (option > 0, "VoteMater: Wrong option.");

        // Get vote and check requirements
        Vote storage vote = votes[id];
        //require (block.number >= vote.endBlock, "VoteMaster: Vote not finished.");
        require (vote.result == 0, "VoteMaster: Already closed");

        // Set the result
        vote.result = option;
        if (vote.endTime > block.timestamp) vote.endTime = block.timestamp;
        if (vote.resultTime > block.timestamp) vote.resultTime = block.timestamp;

        // Set the winnings
        calculateWinnings(vote);
    }

    function claimFees(address payable addr) 
        public
        onlyOwner
        onlyEOA
    {
        require (accruedFees > 0, "VoteMaster: No fees to claim");
        require(addr.send(accruedFees) == true, "VoteMaster: Send failed.");
        accruedFees = 0;
    }

    function calculateWinnings(Vote storage vote)
        internal
        onlyOwner
        onlyEOA
    {   
        // Calculate winnings for every correct bet. TODO: Check calculations
        uint256 total = vote.totals[vote.result - 1];
        for (uint256 i = 0; i < vote.addresses.length; i++) {
            Bet storage b = vote.bets[vote.addresses[i]];
            if (b.option == vote.result) {
                b.winnings = vote.totalBet * b.amount / total;
            }
        }
    }

    function getVoteIds(uint256 category, uint256 status)
        public
        view
        onlyEOA
        returns (string memory)
    {   
        bytes memory temp;
    
        for (uint256 i = 1; i <= voteID; i++) {
            if (category == 0 || votes[i].category == category) {
                if (
                    status == 0 ||
                    (status == 1 && block.timestamp >= votes[i].startTime && block.timestamp <= votes[i].endTime) ||
                    (status == 2 && block.timestamp < votes[i].startTime) ||
                    (status == 3 && block.timestamp > votes[i].endTime)
                ) {
                    temp = temp.length == 0 ? bytes.concat(temp, bytes(i.toString())) : bytes.concat(temp, bytes(","), bytes(i.toString()));
                }
            }
        }
        
        return string(temp);
    }

    function claim(uint256 id, address payable addr) 
        public
        onlyEOA
    {
        require (id > 0 && id <= voteID, "VoteMaster: Invalid ID.");

        Vote storage vote = votes[id];
        require (block.timestamp >= vote.resultTime, "VoteMaster: No result.");
        require (vote.result > 0, "VoteMaster: No result.");
        require (vote.bets[msg.sender].amount > 0, "VoteMaster: No bet placed.");
        require (vote.bets[msg.sender].option == vote.result, "VoteMaster: Incorrect option.");
        require (vote.bets[msg.sender].winnings > 0, "VoteMaster: Nothing to claim.");

        // Send the winnings
        require(addr.send(vote.bets[msg.sender].winnings) == true, "VoteMaster: Send failed.");

        // Set winnings to 0
        vote.bets[msg.sender].winnings = 0;
    }

    function getVoteInfo(address addr, uint256 id) 
        public
        view
        onlyEOA
        returns (VoteInfo memory)
    {
        require (id > 0 && id <= voteID, "VoteMaster: Invalid ID.");
        Vote storage vote = votes[id];
        return VoteInfo({
            category: vote.category,
            result: vote.result,
            startTime: vote.startTime,
            endTime: vote.endTime,
            resultTime: vote.resultTime,
            title: vote.title,
            options: vote.options,
            percentages: vote.percentages,
            numBets: vote.addresses.length,
            totalBet: vote.totalBet,
            bet: Bet(vote.bets[addr].option, vote.bets[addr].amount, vote.bets[addr].winnings)
        });
    }

    function bet(uint256 id, uint256 option)
        public
        payable
        onlyEOA
    {
        // Initial checks
        require (msg.value > 0, "VoteMaster: Bet cannot be 0.");
        require (id > 0 && id <= voteID, "VoteMaster: Invalid ID.");

        // Get vote and check requirements
        Vote storage vote = votes[id];
        require (block.timestamp >= vote.startTime && block.timestamp < vote.endTime, "VoteMaster: Vote not active.");
        require (option > 0 && option <= vote.options.length, "VoteMaster: Invalid option.");

        // Check if we already betted
        require (vote.bets[msg.sender].amount == 0, "VoteMaster: You can only bet once.");

        // Add to the list of addresses
        vote.addresses.push(msg.sender);

        // Handle Fee. Hardcoded for security 2.0%
        uint256 fee = msg.value * 200 / 10000;
        accruedFees += fee;

        // Place bet
        uint256 value = msg.value - fee;
        vote.bets[msg.sender].option = option;
        vote.bets[msg.sender].amount = value;
        vote.bets[msg.sender].winnings = 0;

        // Add bet to totalBet
        vote.totalBet += value;

        // Update percentages
        vote.totals[option - 1] += value;
        vote.percentages[option - 1] += 1;
    }

}