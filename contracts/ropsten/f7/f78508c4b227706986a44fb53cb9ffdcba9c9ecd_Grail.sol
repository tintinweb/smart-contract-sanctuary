/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: contracts/raffle.sol


pragma solidity ^0.8.0;


interface InterfaceRainbows {
    function burn(address user, uint256 amount) external;
}

contract Grail is Ownable {

    // Interfaces to interact with the other contracts
    InterfaceRainbows public Rainbows;

    address[] public entryList;
    address[] public winnerList;

    uint256 public raffleEntryCost = 20 ether;
    uint256 public raffleEntryCount = 0;

    // Entry time.
    uint256 public raffleStartTime = 0;
    uint256 public raffleEndTime = 0;

    // Extended access
    mapping(address => bool) public extendedAccess;

    modifier raffleEnabled() {
        require(raffleStartTime > 0 && block.timestamp > raffleStartTime, "Raffle not started.");
        require(raffleEndTime > 0 && block.timestamp <= raffleEndTime, "Raffle has ended.");
        _;
    }

    modifier onlyFromRestricted() {
        require(extendedAccess[msg.sender], "Your address does not have permission to use.");
        _;
    }

    constructor() {
        extendedAccess[msg.sender] = true;
    }

    // Set the address for the contract.
    function setAddressAccess(address _noundles, bool _value) public onlyOwner {
        extendedAccess[_noundles] = _value;
    }

    // Get the access status for a address.
    function getAddressAccess(address user) external view returns(bool) {
        return extendedAccess[user];
    }

    // Reset the raffle.
    function resetRaffle() public onlyFromRestricted {
        raffleEntryCount = 0;
        raffleStartTime = 0;
        raffleEndTime = 0;
        delete entryList;
        delete winnerList;
    }

    // Set the time.
    function setRaffleSettings(uint256 _raffleStartTime, uint256 _raffleEndTime, uint256 _raffleEntryCost) public onlyFromRestricted {
        raffleStartTime = _raffleStartTime;
        raffleEndTime   = _raffleEndTime;
        raffleEntryCost = _raffleEntryCost;
    }

    // Set the address.
    function setAddresses(address _rainbow) external onlyOwner {
        Rainbows = InterfaceRainbows(_rainbow);
    }

    // Enter the raffle.
    function enterRaffle(uint256 _entryCount) public raffleEnabled {

        // Consume the rewards.
        Rainbows.burn(msg.sender, raffleEntryCost * _entryCount);

        // Add the entries.
        for(uint256 i; i < _entryCount; i += 1){
            entryList.push(msg.sender);
            raffleEntryCount += 1;
        }
    }

    // Pick the winners.
    function pickWinners(uint256 winnerCount) public onlyFromRestricted {

        require(winnerCount <= entryList.length, "Can't have more winners then entries");

        // Clear the old winners.
        delete winnerList;

        // Prevent duplicate pulls.
        uint256 pickedOffset = 0;
        uint256 loopOffset = 0;
        uint256[] memory picked = new uint256[](winnerCount);

        // Loop.
        for(uint256 i; i < winnerCount; i += 1){
            uint256 pick = getRandomNumber(i + loopOffset) % entryList.length;

            bool duplicate = false;

            // Verify it's not already on the list.
            for(uint256 g; g < pickedOffset; g += 1){
                if(picked[g] == pick){
                    duplicate = true;
                    break;
                }
            }

            // Prevent duplicates.
            if(duplicate){
                i -= 1;
                loopOffset += 1;
                continue;
            }

            // If it's not a duplicate, add it to our winner list.
            winnerList.push(entryList[pick]);
            picked[pickedOffset] = pick;
            pickedOffset += 1;
        }
    }

    function getRandomNumber(uint256 _arg) public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _arg)));
    }

    function getEntryCount(address _arg) public view returns (uint256) {

        uint256 count = 0;

        for(uint256 i = 0; i < entryList.length; i += 1){
            if(_arg == entryList[i]){
                count++;
            }
        }

        return count;
    }

    function getEntryList() public view returns (address[] memory) {
        return entryList;
    }

    function getWinners() public view returns (address[] memory) {
        return winnerList;
    }
}