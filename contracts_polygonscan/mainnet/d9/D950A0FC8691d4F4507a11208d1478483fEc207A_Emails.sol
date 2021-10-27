/**
 *Submitted for verification at polygonscan.com on 2021-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

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

contract Emails is Ownable {
    string[] public emails;
    mapping(string => bool) public emailExists;
    string[] public winners;
    uint256 public round;

    event EmailAdded(string indexed emailAdded, uint256 roundNumber);
    event WinnerChosen(string indexed emailAdded, uint256 roundNumber, uint256 blockNumber);
    event DataCleared(uint256 roundNumber);


    function emailsLength() external view returns(uint256) {
        return emails.length;
    }

    function winnersLength() external view returns(uint256) {
        return winners.length;
    }

    /**
     * @dev Function to fill the list with emails. Checks the uniqueness
     * @param _emails List with emails
     */
    function pushEmails(string[] memory _emails) external onlyOwner {
        for (uint256 i = 0; i < _emails.length; i++) {
            require(!emailExists[_emails[i]], "Email already included");
            emails.push(_emails[i]);
            emailExists[_emails[i]] = true;

            emit EmailAdded(_emails[i], round);
        }
    }

    /**
     * @dev Picks the random winner, clears the data and increases the round number
     * @return The winner email
     */
    function pickWinner() external onlyOwner returns (string memory) {
        require(emails.length > 0, "No emails to choose");
        require(winners.length == round, "Incorrect round number");

        uint256 randomNumber = getRandomNumber();

        string memory winner = emails[randomNumber];
        winners.push(winner);
        emit WinnerChosen(winner, round, block.number);

        _clearData();
        round++;

        return winner;
    }

    /**
     * @dev The function clears data in case the list of emails should be re-written
     * called by owner only
     */
    function clearData() external onlyOwner {
        _clearData();
    }

    /**
     * @dev Pick pseudo-random number based on several input parameters
     */
    function getRandomNumber() public view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, emails.length, round))
        ) % emails.length;
        return randomNumber;
    }

    /**
     * @dev Internal function to clear the storage with emails
     */
    function _clearData() internal {
        uint256 initialLength = emails.length;
        require(initialLength > 0, "Nothing to clear");

        for (uint256 i = 0; i < initialLength; i++) {
            emailExists[emails[emails.length - 1]] = false;
            emails.pop();
        }
        emit DataCleared(round);
    }
}