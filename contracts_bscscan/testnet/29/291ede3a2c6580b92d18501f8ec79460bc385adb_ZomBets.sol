/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

pragma solidity ^0.8.4;

// ZombieToken interface.
interface IZombieToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function decimals() external view returns (uint8);
}

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
    
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

// File: contracts\ZomBets.sol


pragma solidity 0.8.4;



contract ZomBets is ReentrancyGuard, Ownable {

    using Strings for uint256;

    struct Bet {
        uint256 option;
        uint256 amount;
        bool winningsClaimed;
    }

    struct Vote {
        address createdBy;
        uint256 category;
        string title;
        string [] options;
        uint256 [] percentages; // number of times each option has been voted upon(according to index, the index of options variable and percentages variable is the same.).
        uint256 createdAt;
        uint256 endTime;   
        uint256 result; // the winning option index.
        uint256 totalBet;
        address [] addresses;
        mapping (address => Bet) bets;
        uint256 totalNumberOfBets;
        uint approved; // all votes need approval, 0 means pending, 1 means approved, 2 means disapproved, 3 means closed by one address, 4 means its done or closed by second address too.
        uint256 accruedFee; // total fees of the vote
        address victim; // victim wallet address
    }

    uint256 public voteID = 1;
    string[] public categories;
    // uint256 private accruedFees; // total fee of all votes.
    mapping (uint256 => Vote) public votes;
    address treasury;
    address zombieTokenContractAddress;
    address secondaryApprover;
    
    constructor(address _treasury, address _zombieTokenContractAddress, address _secondaryApprover) {
        treasury = _treasury;
        zombieTokenContractAddress = _zombieTokenContractAddress;
        secondaryApprover = _secondaryApprover;
    }
    
    function addCategory(string calldata categoryName) public onlyOwner returns(bool){
        require(!categoryExists(categoryName), "Category already exists.");
        categories.push(categoryName);
        return true;
    }
    
    function removeCategory(string calldata categoryName) public onlyOwner returns(bool) {
        require(categoryExists(categoryName), "Category does not exists.");
        string[] memory newCategories = new string[](categories.length - 1);
        bool deleted = false;
        for (uint256 index = 0; index < categories.length; index++) {
            if (deleted) {
                newCategories[index - 1] = categories[index];
            } else {
                if (Strings.compareStrings(categories[index], categoryName)) {
                    newCategories[index] = categories[index];
                } else {
                    deleted = true;
                }
            }
        }
        categories = newCategories;
        return true;
    }
    
    function categoryExists(string calldata categoryName) private view returns(bool) {
        for (uint256 index = 0; index < categories.length; index++) {
            if (Strings.compareStrings(categories[index], categoryName)) {
                return true;
            }
        }
        return false;
    }

    // anyone is able to open/create a vote.
    // category should be integer representing the index of the selected category.
    function openVote(uint256 category, string memory title, string [] memory options, uint256 endTime, address victim)
        external
    {
        require(category > 0 && category < categories.length, "category does not exist.");
        Vote storage vote = votes[voteID];
        vote.createdBy = msg.sender;
        vote.category = category;
        vote.title = title;
        vote.options = options;
        vote.createdAt = block.timestamp;
        vote.endTime = endTime;
        vote.percentages = new uint256 [](options.length);
        vote.approved = 0; //pending approval
        vote.victim = victim;
        voteID++;
    }
    
    function approveVote(uint id) public onlyOwner {
        require (id > 0 && id <= voteID, "ZomBets: Invalid ID.");
        votes[id].approved = 1; // 1 means approved
    }
    
    function disapproveVote(uint id) public onlyOwner {
        require (id > 0 && id <= voteID, "ZomBets: Invalid ID.");
        votes[id].approved = 2; // 2 means disapproved
    }

    // close the vote with the given option as the winning option.
    function closeVote(uint256 id, uint256 option) 
        external
        onlyOwner
    {
        // check voteID and option is good.
        require (id > 0 && id <= voteID, "ZomBets: Invalid ID.");
        require (option >= 0 && option < votes[id].options.length, "VoteMater: Wrong option.");

        // Get vote and check if already closed.
        Vote storage vote = votes[id];
        //require (block.number >= vote.endBlock, "ZomBets: Vote not finished.");
        require (vote.result == 0, "ZomBets: Already closed.");
        require (vote.approved == 1, "ZomBets: Vote not approved yet.");
        
        // Set the result
        vote.result = option;
        // Set approved to approved by first member => 3.
        vote.approved = 3;
        if (vote.endTime > block.timestamp) vote.endTime = block.timestamp;
    }
    
    function closeVoteApproval(uint256 id, bool _approve) 
        external
    {
        require(msg.sender == secondaryApprover, "ZomBets: Only the secondaryApprover can call this function.");
        // check voteID.
        require (id > 0 && id <= voteID, "ZomBets: Invalid ID.");

        // Get vote and check if already closed by owner.
        Vote storage vote = votes[id];
        require (vote.approved == 3, "ZomBets: Vote not approved by the owner yet.");
        
        if (_approve) {
            // set final closed status.
            vote.approved = 4;
            if (vote.endTime > block.timestamp) vote.endTime = block.timestamp;
        } else {
            // rollback the result and set it to zero.
            vote.result = 0;
            // rollback the approval status.
            vote.approved = 1;
        }
        
    }

    // winnings should only be claimed by the depositing address
    function claimWinnings(uint256 id) 
        external
    {
        require (id > 0 && id <= voteID, "ZomBets: Invalid ID.");
        Vote storage vote = votes[id];
        // require (block.timestamp >= vote.resultTime, "ZomBets: No result.");
        require (vote.approved == 4, "ZomBets: Vote not closed yet.");
        require (vote.bets[msg.sender].amount > 0, "ZomBets: No bet placed.");
        require (vote.bets[msg.sender].option == vote.result, "ZomBets: Incorrect option.");
        require (vote.bets[msg.sender].winningsClaimed == false, "ZomBets: Winnings already claimed.");
        // calculate Winnings
        uint256 winnings = calculateWinnings(id, msg.sender);
        // Send the winnings
        require(IZombieToken(zombieTokenContractAddress).transfer(msg.sender, winnings) == true, "ZomBets: Send failed.");
        // Set winnings claimed to true
        vote.bets[msg.sender].winningsClaimed = true;
    }
    
    function calculateWinnings(uint256 _voteID, address claimant) internal view returns(uint256){
        Vote storage vote = votes[_voteID];
        uint256 totalWinnersAmount = 0;
        for (uint256 index = 0; index < votes[voteID].totalNumberOfBets; index++) {
            if (vote.bets[vote.addresses[index]].option == vote.result) {
                totalWinnersAmount += vote.bets[vote.addresses[index]].amount;
            }
        }
        // see explanation in the document.
        uint256 percentWon = (100 / totalWinnersAmount) * vote.bets[claimant].amount;
        return percentWon * (vote.totalBet / 100);
    }

    function bet(uint256 id, uint256 option, uint256 amount)
        external
        payable
    {
        // Initial checks
        require (IZombieToken(zombieTokenContractAddress).balanceOf(msg.sender) > amount, "ZomBets: Not enough balance.");
        require (id > 0 && id <= voteID, "ZomBets: Invalid ID.");
        // Get vote and check requirements
        Vote storage vote = votes[id];
        // check if vote is approved for betting
        require(vote.approved == 1, "ZomBets: Vote not approved yet.");
        require(block.timestamp >= vote.createdAt && block.timestamp < vote.endTime, "ZomBets: Vote not active.");
        require(option >= 0 && option <= vote.options.length, "ZomBets: Invalid option.");

        // Check if already bet
        require (vote.bets[msg.sender].amount == 0, "ZomBets: You can only bet once.");
        
        // calculate 0.2% fee and send it.
        uint256 fee = ((amount) / 100) / 5;
        require(IZombieToken(zombieTokenContractAddress).transferFrom(msg.sender, vote.createdBy, fee * 10 / 100) == true, "ZomBets: Filer token transfer failed."); // 10% goes to the complaint filer
        require(IZombieToken(zombieTokenContractAddress).transferFrom(msg.sender, treasury, fee * 40 / 100) == true, "ZomBets: Treasury token transfer failed."); // 40% goes to the treasury
        if (vote.victim == address(0)) {
            require(IZombieToken(zombieTokenContractAddress).transferFrom(msg.sender, treasury, fee * 50 / 100) == true, "ZomBets: treasury token transfer failed."); // 50% In case there is no victim then all goes to treasury.
        } else {
            require(IZombieToken(zombieTokenContractAddress).transferFrom(msg.sender, vote.victim, fee * 50 / 100) == true, "ZomBets: Victim token transfer failed."); // 50% goes to the victim wallet if any.    
        }
        
        // transferring the reamining amount to this contract address
        require(IZombieToken(zombieTokenContractAddress).transferFrom(msg.sender, address(this), (amount - fee)) == true, "ZomBets: Token transfer failed.");

        // Record bet
        uint256 value = amount - fee;
        vote.accruedFee += fee;
        vote.addresses.push(msg.sender);
        vote.bets[msg.sender].option = option;
        vote.bets[msg.sender].amount = value;
        vote.bets[msg.sender].winningsClaimed = false;
        vote.totalNumberOfBets += 1;
        // Add bet amount to totalBet
        vote.totalBet += value;
        // Update percentages
        vote.percentages[option] += 1;
    }
    
    
}