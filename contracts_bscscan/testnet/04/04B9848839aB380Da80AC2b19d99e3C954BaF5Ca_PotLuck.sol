/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

// SPDX-License-Identifier: Unlicensed

// Pot Luck smart contract

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
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
contract PotLuck is Context, Ownable {
    using SafeMath for uint256;
    struct TicketInfo {
        address player;
        uint256 amount;
    }
    address[] addresses;
    TicketInfo[] private tickets;
    mapping (address => uint256) private _balances;
    string private constant _name = "PotLuck";
    uint256 public totalAmountInPot;
    uint256 public maximumBetAmount = 0.15 ether; // 0.15 bnb
    uint256 public minimumBetAmount = 0.03 ether; // 0.03 bnb
    address public adminWallet = 0xcC0c86e51124aF147Bf08dF080A38b58d0A485Fe;
    address public devWallet = 0xC9A9f5157592deCAB20EC204cF8355Aa29dF66C5;
    uint256 public rewardPercent = 60;
    uint256 public lastRoundFinished;
    uint256 public nextRoundFinished;
    uint256 public roundInterval = 14400; // 4 hours
    uint256 public round = 1;
    uint256 public totalPaidToWinners;
    address public pickerAddress;
    bool private isAvailable = false;
    struct ResultInfo {
        address address1;
        address addaddress2;
        uint256 amount1;
        uint256 amount2;
    }
    ResultInfo lastResult;
    event PickedWinner(address winner1, address winnner2, uint256 amount);
    event EnteredInPot(address player, uint256 amount);
    event RewardPercentUpdated(uint256 amount);
    event RoundIntervalUpdated(uint256 amount);
    event MinimumBetAmountUpdated(uint256 amount);
    event MaximumBetAmountUpdated(uint256 amount);
    event Started();
    event Stopped();
    event LogRoundUpdated(string result);
    event NextRoundSetted(uint256 timestamp);
    event Claim(address recipient, uint256 amount);
    constructor() public {
        pickerAddress = _msgSender();
    }
    function name() public pure returns(string memory){
        return _name;
    }
    function myTickets() public view returns(TicketInfo[] memory) {
        uint256 resultCount;

        for (uint i = 0; i < tickets.length; i++) {
            if (tickets[i].player == _msgSender()) {
                resultCount++;
            }
        }
        TicketInfo[] memory result = new TicketInfo[](resultCount);
        uint256 j;
    
        for (uint i = 0; i < tickets.length; i++) {
            if (tickets[i].player == _msgSender()) {
                result[j] = tickets[i];
                j++;
            }
        }
    
        return result;
    }
    function buyTicket(uint256 ticketCount) public payable returns(uint256, uint256) {
        require(ticketCount > 0, "You need to buy at least 1 ticket");
        require(msg.value.div(ticketCount) <= maximumBetAmount, "Amount should be less than maximum amount");
        require(msg.value.div(ticketCount) >= minimumBetAmount, "Amount should be over than minimum amount");
        require(isAvailable == true, "Not available now. Try later");
        for(uint256 i = 0; i < ticketCount; i++){
            tickets.push(TicketInfo(msg.sender, msg.value.div(ticketCount)));
            addresses.push(msg.sender);
        }
        totalAmountInPot = totalAmountInPot.add(msg.value);
        emit EnteredInPot(msg.sender, msg.value);
        return (ticketCount, msg.value);
    }
    function random(uint256 number) internal view returns(uint256){
         return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, number, addresses)));
    }
    function getTicketCountInPot() public view returns(uint256)  {
        return tickets.length;
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
    function setPickerAddress(address picker) external onlyOwner {
        pickerAddress = picker;
    }
    function start() external onlyOwner {
        require(isAvailable == false, "Already started");
        isAvailable = true;
        nextRoundFinished = block.timestamp + roundInterval;
        emit Started();
        
    }
    function setNextFinishedTime(uint256 timestamp) external onlyOwner {
        nextRoundFinished = timestamp;
        emit NextRoundSetted(timestamp);
    }
    function stop() external onlyOwner {
        isAvailable = false;
        emit Stopped();
    }
    function generateRandomNumbers() internal view returns (uint256, uint256) {
        uint256 index = 99;
        uint256 winner1Index = random(index).mod(tickets.length);
        index = index.add(99);
        uint256 winner2Index = random(index.add(99)).mod(tickets.length);
        while(winner1Index == winner2Index) {
            index = index.add(99);
            winner2Index = random(index).mod(tickets.length);
        }
        return (winner1Index, winner2Index);
    }
    function calculateAmountForWinners(uint256 winner1Index, uint256 winner2Index) internal view returns(uint256, uint256) {
        uint256 winner1Amount = totalAmountInPot.mul(rewardPercent).div(100).mul(tickets[winner1Index].amount).div(tickets[winner1Index].amount.add(tickets[winner1Index].amount));
        uint256 winner2Amount = totalAmountInPot.mul(rewardPercent).div(100).mul(tickets[winner2Index].amount).div(tickets[winner2Index].amount.add(tickets[winner2Index].amount));
        return (winner1Amount, winner2Amount);
    }
    function pickWinner() public {
        require(_msgSender() == pickerAddress || _msgSender() == owner(), "You can not run this function");
        require(isAvailable == true, "Not available now. Try later");
        
        // require(tickets.length >= 2, "Should be two and more people in the pot");
        // require(block.timestamp >= nextRoundFinished, "Can not pick winner at this time");
        
        isAvailable = false;
        if(tickets.length >= 2) {
            (uint256 winner1Index, uint256 winner2Index) = generateRandomNumbers();
            (uint256 winner1Amount, uint256 winner2Amount) = calculateAmountForWinners(winner1Index, winner2Index);
            _balances[tickets[winner1Index].player] = _balances[tickets[winner1Index].player].add(winner1Amount);
            _balances[tickets[winner2Index].player] = _balances[tickets[winner2Index].player].add(winner2Amount);
            _balances[adminWallet] =  _balances[adminWallet].add(totalAmountInPot.mul(100 - rewardPercent).div(200));
            _balances[devWallet] =  _balances[devWallet].add(totalAmountInPot.mul(100 - rewardPercent).div(200));
            totalPaidToWinners = totalPaidToWinners.add(winner1Amount.add(winner2Amount));
            lastResult = ResultInfo(tickets[winner1Index].player, tickets[winner2Index].player, winner1Amount, winner2Amount);
            emit PickedWinner(tickets[winner1Index].player, tickets[winner2Index].player, totalAmountInPot);
            resetPlayers();
        }
        else if(tickets.length == 1) {
            _balances[tickets[0].player] = _balances[tickets[0].player] + totalAmountInPot;
        }
        nextRoundFinished = block.timestamp + roundInterval;
        round = round.add(1);
        isAvailable = true;
    }
    function balanceOf(address addr) public view returns(uint256){
        return _balances[addr];
    }
    function claim() public {
        require(_balances[_msgSender()] > 0, "Insufficiant balance" );
        uint256 balance = _balances[_msgSender()];
        (bool success, )  = payable(_msgSender()).call{value: balance}("");
        require(success == true);
        _balances[_msgSender()] = 0;
        emit Claim(_msgSender(), balance);
    }
    receive() external payable {
        
    }
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success == true);
    }
    function resetPlayers() internal {
        while(tickets.length > 0) {
            tickets.pop();
        }
        addresses = new address[](0);
        totalAmountInPot = 0;
    }
}