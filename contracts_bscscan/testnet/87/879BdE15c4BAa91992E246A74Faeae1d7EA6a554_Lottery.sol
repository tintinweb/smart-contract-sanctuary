// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

interface ISTAKING {
    function stakedBalance(address account) external view returns (uint256);
    function stakingStartTime(address account) external view returns(uint256);
}

interface IFARMING {
    function poolInfo(address lpToken) external view returns(address, address, uint256, uint256, uint256, uint256);
    function userInfo(address account, IBEP20 lpToken) external view returns (uint256, uint256, bool, bool, uint256);
}

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

contract Lottery is Ownable, Pausable {

    enum Levels {L1, L2, L3, L4, L5}

    /**
     * Info of each draw
     * 
     * Params - game number, levels, end time, winner address
     */
    struct Draw {
        uint256 gameNumber;
        Levels nftLevel;
        uint256 endTime;
        address winner;
    }

    /**
     * Info of each ticket
     * 
     * Params - ticket number, owner nft levels, game number, start date
     */
    struct Ticket {
        uint256 ticketNumber;
        address owner;
        Levels nftLevel;
        uint256 gameNumber;
        uint256 startDate;
    }

     /**
     * Info of each user points
     * 
     * Params - ticket number, owner nft levels, game number, start date
     */
    struct UserPoints {
        uint256 points;
        uint256 lastUpdate;
    }

    mapping (uint256 => Draw) public drawInfo;
    mapping (uint256 => Ticket) public ticketInfo;
    mapping (Levels => uint256) public ticketPoints;
    mapping (address => UserPoints) public userPoints;

    ISTAKING public stakingToken;
    IFARMING public farmingToken;
    uint256 public pointInterval = 86400;
    uint256 public pointRate = 1;
    uint256 private ticketCounter = 1;
    IBEP20[] public farmingLpPools;

    constructor(ISTAKING _stakingToken, IFARMING _farmingToken) {
        stakingToken = _stakingToken;
        farmingToken = _farmingToken;
    }

    function addDraw(uint256 _drawNumber, Levels _nftLevel) external onlyOwner returns(bool){
        require(drawInfo[_drawNumber].gameNumber != _drawNumber, "Draw already exists");
        drawInfo[_drawNumber].nftLevel = _nftLevel;
        drawInfo[_drawNumber].gameNumber = _drawNumber;
        return true;
    }

    function addTicketPoints(Levels _nftLevel, uint256 _points) external onlyOwner returns(bool){
        require(ticketPoints[_nftLevel] == 0, "Ticket point already exists");
        ticketPoints[_nftLevel] = _points;
        return true;
    }

    function buyTicket(uint256 draw_number) external returns(bool){
        require(drawInfo[draw_number].gameNumber == draw_number, "Draw dont exists");
        require(calculatePoints(msg.sender) >= ticketPoints[drawInfo[draw_number].nftLevel], "No sufficient points");

        ticketInfo[ticketCounter].ticketNumber = ticketCounter;
        ticketInfo[ticketCounter].owner = msg.sender;
        ticketInfo[ticketCounter].nftLevel = drawInfo[draw_number].nftLevel;
        ticketInfo[ticketCounter].gameNumber = draw_number;
        ticketInfo[ticketCounter].startDate = block.timestamp;

        userPoints[msg.sender].points -= ticketPoints[drawInfo[draw_number].nftLevel];

        ticketCounter += 1;
        return true;
    }

    function getPoints(address account) external {
        calculatePoints(account);
    }

    event StakingPoints(uint256 stakedBalance, uint256 stakingPoints);

    function calculatePoints(address account) internal returns(uint256){
        uint256 stakingPoints = calculateStakingPoints(account);
        uint256 farmingPoints;
        for (uint i = 0; i < farmingLpPools.length; i++) {
            farmingPoints += calculateFarmingPoints(account, farmingLpPools[i]);
        }
        return (stakingPoints + farmingPoints) * 10**18;
    }

    function calculateStakingPoints(address account) internal returns(uint256) {
        uint256 timeDifferences;
        if(userPoints[account].lastUpdate > 0) {
            timeDifferences = block.timestamp - userPoints[account].lastUpdate;
        } else {
            timeDifferences = block.timestamp - ISTAKING(stakingToken).stakingStartTime(account);
        }

        // staking points calculation
        // Staking Points  = Staked Amount * Point Rate (APY) *  TimeDiff / Point Interval
        uint256 timeFactor = timeDifferences / pointInterval;
        uint256 stakingPoints = ((ISTAKING(stakingToken).stakedBalance(account) * timeFactor * pointRate) / 100 ) / (10**18);

        emit StakingPoints(ISTAKING(stakingToken).stakedBalance(account), stakingPoints);
        return stakingPoints;
    }

    function calculateFarmingPoints(address account, IBEP20 lpToken) internal returns(uint256) {
        (uint256 farmedAmount, uint256 farmingStartTime,,,) = IFARMING(farmingToken).userInfo(account, lpToken);
        uint256 timeDifferences = block.timestamp - farmingStartTime;
        if(userPoints[account].lastUpdate > 0) {
            timeDifferences = block.timestamp - userPoints[account].lastUpdate;
        } else {
            timeDifferences = block.timestamp - farmingStartTime;
        }

        // farming points calculation
        // Farming Points  = Farmed Amount * Point Rate (APY) *  TimeDiff / Point Interval
        uint256 timeFactor = timeDifferences / pointInterval;
        uint256 farmingPoints = ((farmedAmount * timeFactor * pointRate) / 100 ) / (10**18);

        emit StakingPoints(farmedAmount, farmingPoints);

        return farmingPoints;
    }

    function setStakingToken(ISTAKING _stakingToken) external {
        stakingToken = _stakingToken;
    }

    function setFarmingToken(IFARMING _farmingToken) external {
        farmingToken = _farmingToken;
    }

    function setFarmingLpPools(IBEP20[] memory _farmingLpPools) external {
        require(_farmingLpPools.length > 0, "Farming Lp pools cant be empty");
        farmingLpPools = _farmingLpPools;
    }
}