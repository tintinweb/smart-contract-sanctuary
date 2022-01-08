// SPDX-License-Identifier: MIT
// curion.eth, Jan 2022, for highly immersive metaverse purposes
// contact: [email protected]

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
//import "@openzeppelin/contracts/utils/Address.sol";
//import "@openzeppelin/contracts/security/PullPayment.sol"; //does this mean I have to include escrow? likely not as it imports it already...

contract ticTacToe is Ownable {

 //--------------------declaration of independence, i mean, variables--------------------
  address public admin;
  address public charityAddress;
  bool public charityClaimIsOpen = false;
  uint256 public entryFee = 0.1 * 10**18; //default amount required to play
  
  uint256 public totalContractWinnings = 0; //total amount of winnings awarded all-time
  uint256 public totalContractUnclaimedWinnings = 0; //total amount of winnings reserved in contract. Shouldnt withdraw beyond contractBalance-totalContractUnclaimedWinnings
  uint256 public winningPerc = 150; //percenage of individual entryFee awarded to winner.
  uint256 public percToCharity = 0; //percentage of total 'pot' sent to charity, the remainder being sent to owner or being kept in wallet
  uint256 public percToOwner = 50; //project dev fund. not just being greedy lol. trying not to over-grab anyway...only whole number percentages!
  uint256 public percSum = percToCharity+percToOwner; //for checking claim amounts
  
  uint256 public rewardUpdateInterval = 8 * 60 * 60; //8 hours
  uint256 public blocksBetweenUpdate = 2400; //approx 8 hours.
  uint256 public creationBlock;
  uint256 public lastUpdateBlock = 0; //initialization
  
  uint256 public prevTotalClaimableRewards = 0;
  uint256 public thisTotalClaimableRewards = 0;
  uint256 public donationClaimableRewards = 0;
  uint256 public ownerClaimableRewards = 0;

  mapping(address => uint256) winnings;

 //--------------------------------------constructor/modifiers/other-------------------------------------
  constructor(address _admin) {
    admin = payable(_admin); 
    creationBlock = block.number; //ik this isn't advisable, but I've included param to adjust num blocks bt updates
  }

  //recipient can't be zero address.
  modifier validAddress(address _addr) {
    require(_addr != address(0), "Not valid address");
    _;
  }

  //------------------------------functions that MOVE MONEY------------------------------

  //function updateClaimable() private nonReentrant whenNotPaused {
  function updateClaimable() private {
    //every N blocks, update reward balance by those accrued between blocks X and Y with N blocks between them
    if(lastUpdateBlock==0) {lastUpdateBlock = creationBlock; prevTotalClaimableRewards = 0;}
    if(block.number-lastUpdateBlock > blocksBetweenUpdate) {
      // divide up rewards accrued since last time this statement was entered. get total since last update, split, define new start to mark next range N blocks later.
      thisTotalClaimableRewards = address(this).balance - totalContractUnclaimedWinnings - prevTotalClaimableRewards; //isolate claimable rewards since last claim
      donationClaimableRewards += thisTotalClaimableRewards * percToCharity;
      ownerClaimableRewards += thisTotalClaimableRewards * percToOwner;
      prevTotalClaimableRewards = thisTotalClaimableRewards;
      lastUpdateBlock = block.number; //reset lastUpdateBlock to current block
    }
  }

  //function claimWinnings(address payable _winningsClaimer) external validAddress(_winningsClaimer) nonReentrant whenNotPaused {
  function claimWinnings(address payable _winningsClaimer) external {
    require(msg.sender == _winningsClaimer,"Claiming for wrong address");
    uint256 claimableWinnings = winnings[_winningsClaimer];
    if (claimableWinnings > 0) {      
      winnings[_winningsClaimer]=0;
      totalContractUnclaimedWinnings -= winnings[_winningsClaimer]; //decrease unclaimed reward total
      (bool success, ) = _winningsClaimer.call{ value: claimableWinnings }("");
      require(success, "winnings claim fail");
    }
  }

  //function claimDonation(address payable _charityAddress) external validAddress(_winningsClaimer) nonReentrant whenNotPaused {
  function claimDonation(address payable _charityAddress) external {
    require(charityClaimIsOpen,"Charity claim is not currently open");
    require(msg.sender == charityAddress && _charityAddress == charityAddress, "Not selected charity, can't claim charity rewards!");
    require(percSum<=100, "Check claim distribution percentages and correct such that they add to less than 100");
    uint256 donation = donationClaimableRewards;
    donationClaimableRewards = 0;
    (bool success, ) = _charityAddress.call{ value: donation }("");
    require(success, "donation claim fail");
  }

  //function ownerClaimRewards(uint256 _ownerClaimableRewards) external onlyOwner nonReentrant whenNotPaused {
  function ownerClaimRewards() external onlyOwner {
    require(percSum<=100, "Check claim distribution percentages and correct such that they add to less than 100");
    uint256 ownerClaimAmount = ownerClaimableRewards;
    ownerClaimableRewards = 0;
    (bool success, ) = msg.sender.call{ value: ownerClaimAmount }("");
    require(success, "owner claim fail");
  }

  //function withdraw(uint256 _withdrawAmount) external onlyOwner nonReentrant whenNotPaused {   
  function withdraw(uint256 _withdrawAmount) external onlyOwner {   
    require(_withdrawAmount < address(this).balance, "Invalid withdraw amount, not sure if this is redundant...");
    (bool success, ) = msg.sender.call{ value: _withdrawAmount }("");
    require(success, "withdraw fail");

  }

  //-------------------------READING and SET PARAMETER functions--------------------------
  // Function to receive Ether. msg.data must be empty
  receive() external payable {}
  // Fallback function is called when msg.data is not empty
  fallback() external payable {}
  
  // read/set functions
  function getBalance() public view returns (uint256) {
      return address(this).balance;
  }
  function readTotalContractWinnings() public view returns (uint256) {
    return totalContractWinnings;
  }
  function setEntryFee(uint256 _entryFee) public onlyOwner returns (uint256) {
    entryFee = _entryFee;
  }
  function setPercToCharity(uint256 _percToCharity) public onlyOwner returns (uint256) {
    percToCharity = _percToCharity;
  }
  function setPercToOwner(uint256 _percToOwner) public onlyOwner returns (uint256) {
    percToOwner = _percToOwner;
  }
  function setBlockBetweenRewardUpdates(uint256 _blocksBetweenUpdate) public onlyOwner returns(uint256) {
    blocksBetweenUpdate = _blocksBetweenUpdate;
  }

  // so the webapp can read the amount claimable
  function claimableGameWinnings(address _playerAddress) public view returns (uint256){
    return winnings[_playerAddress];
  }

  //function updateGameWinnings(address _winnerAddress) public onlyOwner nonReentrant whenNotPaused { //make payable?
  function updateGameWinnings(address _winnerAddress) public onlyOwner { //make payable?
    winnings[_winnerAddress] += entryFee * (winningPerc/100); //1.5x entryFee to winner
    totalContractWinnings += winnings[_winnerAddress]; //add to total amount of winnings awarded overall
    totalContractUnclaimedWinnings += winnings[_winnerAddress]; //add to current amount of unclaimed winnings
  }

  //function toggleCharityClaim() public onlyOwner whenNotPaused returns (bool){
  function toggleCharityClaim() public onlyOwner returns (bool){
    charityClaimIsOpen = !charityClaimIsOpen;
  }

  function setCharityAddress(address _charityAddress) public onlyOwner {
    charityAddress = _charityAddress;
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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