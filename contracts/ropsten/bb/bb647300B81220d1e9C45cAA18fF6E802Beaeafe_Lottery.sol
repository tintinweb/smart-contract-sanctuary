// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Lottery is Ownable {

    using SafeMath for uint256;

    enum STATE { IDLE, OPEN, CLOSED }

    struct PlayerInfo{
        address payable playerAddress;
        uint putIn;
        uint lastEnterTimestamp;
    }

    //factors to initialize
    uint hardCapOfNextPool;
    uint feePrizePool1;
    uint feeNextPool1;
    uint feePrizePool2;
    uint numberOfWinners;

    //lottery infos
    uint public lotteryId;
    address[] public chasingList;
    mapping(address=>PlayerInfo) players;
    uint endingTimeStamp;
    uint public balanceOfPrizePool;
    uint public balanceOfNextPool;
    // uint public balanceOfMarketing;
    STATE public currentState;
    
    event NewEntry(uint lotteryId, uint endingTimeStamp, PlayerInfo[] candsOfWin, uint[] willWins);

    modifier inState(STATE state) {
        require(state == currentState, 'current state does not allow this');
        _;
    }

    constructor(uint _hardCapOfNextPool, uint _feePrizePool1, uint _feeNextPool1, uint _feePrizePool2, uint _numberOfWinners) {
        require(_feePrizePool1 > 1 && _feePrizePool1 < 99, 'fee should be between 1 and 99');
        require(_feeNextPool1 > 1 && _feeNextPool1 < 99, 'fee should be between 1 and 99');
        require(_feePrizePool2 > 1 && _feePrizePool2 < 99, 'fee should be between 1 and 99');

        hardCapOfNextPool = _hardCapOfNextPool.mul(10**18);
        feePrizePool1 = _feePrizePool1;
        feeNextPool1 = _feeNextPool1;
        feePrizePool2 = _feePrizePool2;
        numberOfWinners = _numberOfWinners;

        lotteryId = 0;
        balanceOfPrizePool=0;
        balanceOfNextPool=0;
        currentState=STATE.IDLE;
    }

    function start() external inState(STATE.IDLE) onlyOwner() {
        lotteryId = lotteryId.add(1);
        balanceOfPrizePool = balanceOfNextPool;
        balanceOfNextPool = 0;
        currentState = STATE.OPEN;

        endingTimeStamp = (block.timestamp).add(18000);
        chasingList = new address[](0);
        PlayerInfo[] memory candsOfWin = new PlayerInfo[](0);
        uint[] memory willWins = new uint[](0);

        emit NewEntry(lotteryId, endingTimeStamp, candsOfWin, willWins);
    }

    function getLotteryStatus() external view returns(STATE, uint, uint, PlayerInfo[] memory, uint[] memory) {
        PlayerInfo[] memory candsOfWin;
        uint[] memory willWins;
        (candsOfWin, willWins) = _calcCandsOfWin();
        return (currentState, lotteryId, endingTimeStamp, candsOfWin, willWins);
    }

    function enter() external payable inState(STATE.OPEN){
        require(msg.value >= 0.01 ether, 'Minimum entry is 0.01 BNB');
        require(endingTimeStamp.sub(block.timestamp).add(5) < 18000 ,'Prize Hard Cap time has reached out');
        require(chasingList[chasingList.length.sub(1)] != msg.sender, 'You have just entered');


        if(players[msg.sender].playerAddress != msg.sender){  // first put in
            PlayerInfo memory info = PlayerInfo(payable(msg.sender),  msg.value, block.timestamp);
            players[msg.sender] = info;
        }
        else{
            players[msg.sender].putIn = players[msg.sender].putIn.add(msg.value);
            players[msg.sender].lastEnterTimestamp = block.timestamp;
        }

        chasingList.push(msg.sender);
        endingTimeStamp = endingTimeStamp.sub(5);

        if(balanceOfNextPool < hardCapOfNextPool){
            balanceOfPrizePool = balanceOfPrizePool.add((msg.value).mul(feePrizePool1).div(10**2));
            balanceOfNextPool = balanceOfNextPool.add((msg.value).mul(feeNextPool1).div(10**2));
        }
        else{
            balanceOfPrizePool = balanceOfPrizePool.add((msg.value).mul(feePrizePool2).div(10**2));
        }

        PlayerInfo[] memory candsOfWin;
        uint[] memory willWins;
        (candsOfWin, willWins) = _calcCandsOfWin();
        emit NewEntry(lotteryId, endingTimeStamp, candsOfWin, willWins);
    }

    function closeLottery() external inState(STATE.OPEN) onlyOwner(){
        currentState = STATE.CLOSED;
    }

    function deliverPrize() external inState(STATE.CLOSED) onlyOwner(){
        PlayerInfo[] memory candsOfWin;
        uint[] memory willWins;
        (candsOfWin, willWins) = _calcCandsOfWin();
        for(uint i = 0; i < candsOfWin.length; i++){
            candsOfWin[i].playerAddress.transfer(willWins[i]);
        }
        for(uint i = 0; i < chasingList.length; i++){
            delete players[chasingList[i]];
        }
        
        currentState = STATE.IDLE;
    }

    function _calcCandsOfWin() internal view returns(PlayerInfo[] memory, uint[] memory){

        PlayerInfo[] memory _cands = new PlayerInfo[](numberOfWinners);

        uint _chasingLength = chasingList.length;
        uint _winersTPutIn = 0;

        for(uint i = 0; i < numberOfWinners; i++){
            if(_chasingLength < i.add(1)) { break; }
            _cands[i] = players[chasingList[_chasingLength.sub(1).sub(i)]];
            _winersTPutIn = _winersTPutIn.add(_cands[i].putIn);
        }

        uint[] memory _willWins = new uint[](numberOfWinners);
        for(uint i = 0; i < _cands.length; i++){
            _willWins[i] = balanceOfPrizePool.mul(_cands[i].putIn).div(_winersTPutIn);  //////TODO
        }
        
        return (_cands, _willWins);
    }

    function setHardCapOfNextPool(uint _hardCap) external inState(STATE.IDLE) onlyOwner(){
        hardCapOfNextPool = _hardCap.mul(10**18);
    }

    function setFeePrizePool1(uint _fee) external inState(STATE.IDLE) onlyOwner(){
        require(_fee > 1 && _fee < 99, 'fee should be between 1 and 99');
        feePrizePool1 = _fee;
    }

    function setFeeNextPool1(uint _fee) external inState(STATE.IDLE) onlyOwner(){
        require(_fee > 1 && _fee < 99, 'fee should be between 1 and 99');
        feeNextPool1 = _fee;
    }

    function setFeePrizePool2(uint _fee) external inState(STATE.IDLE) onlyOwner(){
        require(_fee > 1 && _fee < 99, 'fee should be between 1 and 99');
        feePrizePool2 = _fee;
    }

    function setNumberOfWinners(uint _num) external inState(STATE.IDLE) onlyOwner(){
        require(_num > 2, 'The number of Winners should be bigger than 2');
        numberOfWinners = _num;
    }

    function withDrawMarketing(uint amount) external inState(STATE.IDLE) onlyOwner(){
        require(amount < (address(this).balance).sub(balanceOfPrizePool).sub(balanceOfNextPool), 'The amount is bigger than the balance of marketing pool.');
        (payable(msg.sender)).transfer(amount);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

