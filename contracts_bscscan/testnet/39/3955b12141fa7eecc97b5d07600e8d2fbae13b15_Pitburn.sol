/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: contracts/Lottery.sol


pragma solidity >=0.8.0 <0.9.0;




contract Pitburn is Ownable, ReentrancyGuard {
    struct Entry {
        uint[] entries;
        uint round;
    }
    
    struct LotteryResult {
        address winner;
        uint winningNumber;
        uint winningAmount;
        uint burnedAmount;
        uint communityAmount;
        uint announceAmount;
        uint timestamp;
    }
    
    struct FeeStructure {
        uint8 communityTaxPercentage;
        uint8 burnTaxPercentage;
        uint8 announcerFeePercentage;
        uint8 rolloverTaxPercentage;
        uint8 ownerTaxPercentage;
    }
    
    address public token;
    uint public decimal;
    
    // game state
    bool public paused;
    bool public inPlay;
    
    // addresses
    address[] private players;
    mapping (address => bool) private managers;
    address public communityWallet;

    // lottery info
    uint public lotteryInterval;
    uint public startDateTime;
    uint public endDateTime;
    uint public ticketPrice;
    uint public minimumPlayers;
    uint public round;
    uint public numberOfPlayers;

    // nonce for generating random number
    uint private nonce;
    
    FeeStructure public fees;
    
    // player entries array mapped by address
    mapping (address => Entry) private playerEntries;
    
    // lottery past results
    mapping (uint => LotteryResult) public pastRounds;
    
    
    event TicketBought(address indexed player, uint ticketAmount);
    event Winner(address indexed player, uint totalPot, uint winningNumber, uint round);
    event RoundStart(uint startDateTime, uint endDateTime, uint round);
    event Paused(uint pauseDateTime, uint round);

    constructor(uint _minimumPlayers, FeeStructure memory _fees, uint _decimal, uint _lotteryInterval, uint _ticketPrice, address _token, address _communityWallet, bool _paused, bool _inPlay) {
        minimumPlayers = _minimumPlayers;
        fees = _fees;
        lotteryInterval = _lotteryInterval;
        token = _token;
        decimal = _decimal;
        communityWallet = _communityWallet;
        paused = _paused;
        inPlay = _inPlay;
        ticketPrice = _ticketPrice * 10**_decimal;
    }

    modifier notActive {
        require(paused == true && inPlay == false, "Lottery is still ongoing");
        _;
    }
    
    modifier timer {
        require(lotteryInterval >= 1 minutes, "Atleast 1 minutes");
        _;
    }
    
    modifier active {
        require(inPlay == true, "Game is not active");
        _;
    }
    
    modifier onlyManager {
        require(managers[msg.sender] == true || msg.sender == owner(), "Not a manager");
        _;
    }
    
    // provacally random, alternative is to use chainlink vrf for fee
    function random() internal returns (uint) {
        nonce++;
        uint randomNumber = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce, players))) % players.length;
        return randomNumber;
    }
    
    function buyTickets(uint8 ticketAmount) external active nonReentrant  {
      require(ticketAmount > 0, "Purchase more than 1 ticket");
      require(ticketPrice > 0, "Ticket price must not be 0");
      require(msg.sender != owner(), "Owner can't play");
      require(IERC20(token).transferFrom(msg.sender, address(this), ticketAmount * ticketPrice));
      // delete previous round entry
      if (round > playerEntries[msg.sender].round) { 
          delete playerEntries[msg.sender];
          playerEntries[msg.sender].round = round;
      }
      // add player count
      if (playerEntries[msg.sender].entries.length == 0) { numberOfPlayers++; }
      for (uint i = 0; i < ticketAmount; i++) {
          players.push(msg.sender);
          // push ticket number to player entry
          playerEntries[msg.sender].entries.push(players.length-1);
      }
      emit TicketBought(msg.sender, ticketAmount);
    }
    
    function startGame() external onlyManager notActive {
        round++;
        paused = false;
        inPlay = true;
        startDateTime = block.timestamp;
        endDateTime = block.timestamp + lotteryInterval;
    }
    
    function announceResult() external nonReentrant active {
        require(block.timestamp > endDateTime, "Game is still going");
        require(IERC20(token).balanceOf(address(this)) > 0, "No Balance");
        require(numberOfPlayers >= minimumPlayers, "Not enough players"); 
        uint winningNumber = random();
        uint totalCommunity;
        uint totalAnnouncer;
        uint totalBurn;
        uint ownerTax;
        if (fees.communityTaxPercentage > 0) {
            totalCommunity = IERC20(token).balanceOf(address(this)) * fees.communityTaxPercentage / 10**2;
        }
        if (fees.burnTaxPercentage > 0) {
            totalBurn =  IERC20(token).balanceOf(address(this)) * fees.burnTaxPercentage / 10**2;
        }
        if (fees.announcerFeePercentage > 0) {
            totalAnnouncer = IERC20(token).balanceOf(address(this)) * fees.announcerFeePercentage / 10**2;
        }
        if (fees.ownerTaxPercentage > 0) {
            ownerTax = IERC20(token).balanceOf(address(this)) * fees.ownerTaxPercentage / 10**2;
        }
        uint winnings = IERC20(token).balanceOf(address(this)) * (100 - fees.communityTaxPercentage - fees.announcerFeePercentage - fees.burnTaxPercentage - fees.rolloverTaxPercentage - fees.ownerTaxPercentage) / 10**2;
        address winner = players[winningNumber];
        pastRounds[round] = LotteryResult(winner, winningNumber, winnings, totalBurn, totalCommunity, totalAnnouncer, block.timestamp);

                
        // send funds
        require(IERC20(token).transfer(winner, winnings));
        if (totalCommunity > 0) {
            require(IERC20(token).transfer(communityWallet, totalCommunity));
        }
        if (totalBurn > 0) {
            require(IERC20(token).transfer(address(0x000000000000000000000000000000000000dEaD), totalBurn));
        }
        if (totalAnnouncer > 0) {
            require(IERC20(token).transfer(msg.sender, totalAnnouncer));
        }
        if (ownerTax > 0) {
            require(IERC20(token).transfer(owner(), ownerTax));
        }

        emit Winner(winner, winnings, winningNumber, round);
        // reset game
        delete players;
        delete numberOfPlayers;
        if (paused) {
            inPlay = false;
            emit Paused(block.timestamp, round);
        } else {
            round++;
            startDateTime = block.timestamp;
            endDateTime = block.timestamp + lotteryInterval;
            emit RoundStart(block.timestamp, endDateTime, round);
        }
        
    }
    
    function setToken(address _token, uint _decimal) external onlyOwner {
        token = _token;
        decimal = _decimal;
    }

    function setLotteryInterval(uint _days, uint _hours, uint _minutes) external onlyManager {
        require(_days < 7, "must be less than 7 days");
        require(_hours < 24, "must be less than 24 hours");
        require(_minutes < 60, "must be less than 60 minutes");
        // https://docs.soliditylang.org/en/develop/units-and-global-variables.html#time-units
        lotteryInterval = _days * 1 days + _hours * 1 hours + _minutes * 1 minutes;
    }
    
    function setTicketPrice(uint _ticketPrice) external onlyManager notActive {
        // for token with decimals
        require(_ticketPrice > 0, "price must be over 0");
        ticketPrice = _ticketPrice * 10**decimal;
    }
    
    function setFeeStructure(uint8 _communityTaxPercentage, uint8 _announcerFeePercentage, uint8 _burnTaxPercentage, uint8 _rolloverTaxPercentage, uint8 _ownerTaxPercentage) external onlyManager notActive  {
        fees.communityTaxPercentage = _communityTaxPercentage;
        fees.announcerFeePercentage = _announcerFeePercentage;
        fees.burnTaxPercentage = _burnTaxPercentage;
        fees.rolloverTaxPercentage = _rolloverTaxPercentage;
        fees.ownerTaxPercentage = _ownerTaxPercentage;
    }
    
    function setCommunityTaxPercentage(uint8 _communityTaxPercentage) external onlyManager notActive  {
        fees.communityTaxPercentage = _communityTaxPercentage;
    }
    
    function setAnnouncerTaxPercentage(uint8 _announcerFeePercentage) external onlyManager notActive  {
        fees.announcerFeePercentage = _announcerFeePercentage;
    }
    function setBurnTaxPercentage(uint8 _burnTaxPercentage) external onlyManager notActive  {
        fees.burnTaxPercentage = _burnTaxPercentage;
    }
    function setRolloverTaxPercentage(uint8 _rolloverTaxPercentage) external onlyManager notActive  {
        fees.rolloverTaxPercentage = _rolloverTaxPercentage;
    }
    function setOwnerTaxPercentage(uint8 _ownerTaxPercentage) external onlyOwner notActive  {
        fees.ownerTaxPercentage = _ownerTaxPercentage;
    }
    
    function setManager(address _manager) external onlyOwner {
        managers[_manager] = true;
    }
    
    function togglePause() external onlyManager  {
        paused = !paused;
    }
    
    function emergencyPause() external onlyOwner  {
        paused = true;
        inPlay = false;
        emit Paused(block.timestamp, round);
    }
    
    function emergencyWithdraw() external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
    
    function destroy() external payable onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    
    function isManager(address _manager) external view returns(bool) {
        return managers[_manager];
    }
    
    function getPlayerEntry(address _player) external view returns(Entry memory) {
        return playerEntries[_player];
    }
    
    function getTotalEntries() external view returns(uint) {
        return players.length;
    }
    
    function currentPot() external view returns(uint) {
        uint balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            return IERC20(token).balanceOf(address(this)) * (100 - fees.communityTaxPercentage - fees.announcerFeePercentage - fees.burnTaxPercentage - fees.rolloverTaxPercentage - fees.ownerTaxPercentage) / 10**2;
        }
        return 0;
    }
    
    function currentCommunity() external view returns(uint) {
        uint balance = IERC20(token).balanceOf(address(this));
         if ( fees.communityTaxPercentage > 0 && balance > 0 ) {
            return balance * fees.communityTaxPercentage / 10**2;
         }
         return 0;
    }
    
    function currentBurn() external view returns(uint) {
        uint balance = IERC20(token).balanceOf(address(this));
        if ( fees.burnTaxPercentage > 0 && balance > 0 ) {
             return balance * fees.burnTaxPercentage / 10**2;
        }
        return 0;
       
    }
    
    function currentAnnouncerReward() external view returns(uint) {
        uint balance = IERC20(token).balanceOf(address(this));
        if ( fees.burnTaxPercentage > 0 && balance > 0) {
            return balance * fees.announcerFeePercentage / 10**2;
        }
        return 0;
    }
    
    function currentRollover() external view returns(uint) {
        uint balance = IERC20(token).balanceOf(address(this));
        if ( fees.rolloverTaxPercentage > 0 && balance > 0) {
            return balance * fees.rolloverTaxPercentage / 10**2;
        }
        return 0;
    }
    }