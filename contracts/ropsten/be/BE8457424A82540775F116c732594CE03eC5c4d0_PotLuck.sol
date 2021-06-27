// SPDX-License-Identifier: Unlicensed

// Pot Luck smart contract

pragma solidity 0.6.12;

import "./OraclizeAPI.sol";
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
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
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _previousOwner = address(0);
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 0 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
contract PotLuck is Context, Ownable, usingProvable {
    using SafeMath for uint256;
    struct TicketInfo {
        address player;
        uint256 amount;
    }
    address[] addresses;
    TicketInfo[] private players;
    uint256 public totalAmountInPot;
    uint256 public maximumBetAmount = 50000000000000000; // 0.05 ether
    uint256 public minimumBetAmount = 5000000000000000; // 0.005 ether
    address public adminWallet = 0xcC0c86e51124aF147Bf08dF080A38b58d0A485Fe;
    address public devWallet = 0xC9A9f5157592deCAB20EC204cF8355Aa29dF66C5;
    uint256 public rewardPercent = 60;
    uint256 public lastRoundFinished;
    uint256 public nextRoundFinished;
    uint256 public roundInterval = 14400; // 4 hours
    uint256 public round;
    bool private isAvailable = false;
    event PickedWinner(address winner1, address winnner2, uint256 amount);
    event EnteredInPot(address player, uint256 amount);
    event RewardPercentUpdated(uint256 amount);
    event RoundIntervalUpdated(uint256 amount);
    event MinimumBetAmountUpdated(uint256 amount);
    event MaximumBetAmountUpdated(uint256 amount);
    event Started();
    event Stopped();
    constructor() public payable {
        
    }
    function play() public payable {
        require(msg.value < maximumBetAmount, "Amount should be less than maximum bet amount");
        require(msg.value.mod(minimumBetAmount) == 0, "Amount should be times of minimum bet amount");
        //require(isAvailable == true, "Not available now. Try later");
        players.push(TicketInfo(msg.sender, msg.value));
        addresses.push(msg.sender);
        totalAmountInPot += msg.value;
        emit EnteredInPot(msg.sender, msg.value);
    }
    function random(uint256 number) public view returns(uint256){
         return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, number, addresses)));
    }
    function getPlayersCountInPot() public view returns(uint256)  {
        return players.length;
    }
    function setRewardPercent(uint256 amount) external onlyOwner {
        rewardPercent = amount;
        emit RewardPercentUpdated(amount);
    }
    function setRoundInterval(uint256 amount) external onlyOwner {
        roundInterval = amount;
        emit RoundIntervalUpdated(amount);
    }
    function setMinimumBetAmount(uint256 amount) external onlyOwner {
        minimumBetAmount = amount;
        emit MinimumBetAmountUpdated(amount);
    }
    function setMaximumBetAmount(uint256 amount) external onlyOwner {
        maximumBetAmount = amount;
        emit MaximumBetAmountUpdated(amount);
    }
    function setAdminWallet(address wallet) external onlyOwner {
        adminWallet = wallet;
    }
    function setDevWallet(address wallet) external onlyOwner {
        devWallet = wallet;
    }
    function start() external onlyOwner {
        require(isAvailable == false, "Already started");
        isAvailable = true;
        nextRoundFinished = block.timestamp + roundInterval;
        provable_query(60, "URL", "json(https://www.therocktrading.com/api/ticker/BTCEUR).result.0.last");
        emit Started();
    }
    function stop() external onlyOwner {
        isAvailable = false;
        emit Stopped();
    }
    function __callback(bytes32 qid, string memory result) public  override{
        round = round.add(1);
    }
    function pickWinner() public onlyOwner returns(address, address, uint256, uint256) {
        require(isAvailable == true, "Not available now. Try later");
        require(players.length >= 2, "Should be two and more people in the pot");
        require(block.timestamp >= nextRoundFinished, "Can not pick winner at this time");
        isAvailable = false;
        uint index = 1;
        uint256 winner1Index = random(index).mod(players.length);
        index = index.add(1);
        uint256 winner2Index = random(index).mod(players.length);
        while(winner1Index == winner2Index) {
            index = index.add(1);
            winner2Index = random(index).mod(players.length);
        }
        address  winner1Addr = players[winner1Index].player;
        address winner2Addr = players[winner2Index].player;
        uint256 totalPotAmount = address(this).balance;
        uint256 winner1Amount = totalPotAmount.mul(rewardPercent).div(100).mul(players[winner1Index].amount).div(players[winner1Index].amount.add(players[winner1Index].amount));
        uint256 winner2Amount = totalPotAmount.mul(rewardPercent).div(100).mul(players[winner2Index].amount).div(players[winner2Index].amount.add(players[winner2Index].amount));
        (bool success, ) = payable(winner1Addr).call{value: winner1Amount}("");
        (success, ) = payable(winner2Addr).call{value: winner2Amount}("");
        uint256 ownerFee = address(this).balance.div(2);
        (success, ) = payable(adminWallet).call{value: ownerFee}("");
        (success, ) = payable(devWallet).call{value: address(this).balance.sub(ownerFee)}("");
        nextRoundFinished = block.timestamp + roundInterval;
        totalAmountInPot = 0;
        resetPlayers();
        isAvailable = true;
        emit PickedWinner(players[winner1Index].player, players[winner2Index].player, totalPotAmount);
        return (players[winner1Index].player, players[winner2Index].player, winner1Amount, winner2Amount);
    }
    function resetPlayers() internal {
        while(players.length > 0) {
            players.pop();
        }
        totalAmountInPot = 0;
        addresses = new address[](0);
    }
}