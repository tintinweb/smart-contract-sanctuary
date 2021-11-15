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

// SPDX-License-Identifier: MIT

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Lottery is Ownable {

    using SafeMath for uint256;

    enum STATE { IDLE, OPEN }

    address[] lastWinners;
    uint256[] lastPutIns;
    uint256[] lastTimestamps;
    uint256[] lastWinsAmounts;

    //factors to initialize
    uint256 public hardCapOfNextPool;
    uint256 public feePrizePool1;
    uint256 public feeNextPool1;
    uint256 public feePrizePool2;
    uint256 public numberOfWinners;

    //lottery infos
    uint256 public lotteryId;

    address[] chasers;
    uint256[] putIns;
    uint256[] timestamps;
    uint public lenChasers;

    uint256 public endingTimeStamp;
    uint256 public balanceOfPrizePool;
    uint256 public balanceOfNextPool;
    STATE public currentState;
    
    event NewEntry(uint256 endingTimeStamp);

    modifier inState(STATE state) {
        require(state == currentState, 'current state does not allow this');
        _;
    }
    //Lottery, 5, 60, 20, 70, 4
    constructor(uint256 _hardCapOfNextPool, uint256 _feePrizePool1, uint256 _feeNextPool1, uint256 _feePrizePool2, uint256 _numberOfWinners) {
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

        //? : block.timestamp => current time
        //To set the end-time of this round
        endingTimeStamp = (block.timestamp).add(10800);//3 hours

        emit NewEntry(endingTimeStamp);
    }

    function getLotteryStatus() external view returns(
        uint256 _lotteryId,
        uint256 _endingTimestamp, 
        STATE _currentState, 
        address[] memory _candsOfWin, 
        uint256[] memory _putIns, 
        uint256[] memory _timestamps,
        uint256[] memory _willWins,
        uint256 _balanceOfPrizePool) {
        _lotteryId = lotteryId;
        _endingTimestamp = endingTimeStamp;
        _balanceOfPrizePool = balanceOfPrizePool;
        _currentState = currentState;
        (_candsOfWin, _putIns, _timestamps, _willWins) = _calcCandsOfWin();
    }

    function enter() external payable inState(STATE.OPEN){
        require(msg.value >= 0.01 ether, 'Minimum entry is 0.01 BNB');
        require(endingTimeStamp.sub(block.timestamp).add(5) < 18000 ,'Prize Hard Cap time has reached out');
        uint256 entryPrize;
        uint256 entryNext;
        (entryPrize, entryNext) = _splitEntry(msg.value);
        balanceOfPrizePool = balanceOfPrizePool + entryPrize;
        balanceOfNextPool = balanceOfNextPool + entryNext;
        
        chasers.push(msg.sender);
        putIns.push(_getPutin(msg.value, msg.sender));
        timestamps.push(block.timestamp);
        lenChasers = lenChasers + 1;

        endingTimeStamp = endingTimeStamp.add(5);

        emit NewEntry(endingTimeStamp);
    }

    function _getPutin(uint256 val, address sender) internal view returns(uint256){
        uint256 _putin = val;
        for(uint i = 0; i < lenChasers; i++){
            if(chasers[lenChasers-i-1]==sender){
                _putin = _putin + putIns[lenChasers-i-1];
                break;
            }
        }
        return _putin;
    }

    function _splitEntry(uint256 entry) internal view returns(uint256 prizeEntry, uint256 nextEntry){
        if(balanceOfNextPool < hardCapOfNextPool){
            if((hardCapOfNextPool-balanceOfNextPool) < entry.mul(feeNextPool1).div(10**2)){
                uint256 _putNext = hardCapOfNextPool-balanceOfNextPool;
                uint256 _putPrize = _putNext.mul(feePrizePool1).div(feeNextPool1);
                nextEntry = _putNext;
                prizeEntry = _putPrize.add((entry.sub(_putNext).sub(_putPrize).sub(_putNext.mul(uint256(100).sub(feePrizePool1).sub(feeNextPool1)).div(feeNextPool1))).mul(feePrizePool2).div(10**2));
            }
            else{
                prizeEntry = entry.mul(feePrizePool1).div(10**2);
                nextEntry = entry.mul(feeNextPool1).div(10**2);
            }
        }
        else{
            prizeEntry = entry.mul(feePrizePool2).div(10**2);
            nextEntry = 0;
        }
    }


    function deliverPrize() external inState(STATE.OPEN) onlyOwner(){
        require(endingTimeStamp<=block.timestamp,'Lottery game has not been ended.');
        address[] memory _candsOfWin;
        uint256[] memory _putIns;
        uint256[] memory _timestamps;
        uint256[] memory _willWins;
        (_candsOfWin, _putIns, _timestamps, _willWins) = _calcCandsOfWin();
        for(uint i = 0; i < _candsOfWin.length; i++){
            if(_candsOfWin[i] != address(0)){
                (payable(_candsOfWin[i])).transfer(_willWins[i]);
            }     
        }
        balanceOfPrizePool = 0;
        currentState = STATE.IDLE;

        //save lottery info
        lastWinners = _candsOfWin;
        lastPutIns = _putIns;
        lastTimestamps = _timestamps;
        lastWinsAmounts = _willWins;

        chasers = new address[](0);
        putIns = new uint256[](0);
        timestamps = new uint256[](0);

        lenChasers = 0;
        emit NewEntry(endingTimeStamp);
    }

    function getLastLotteryInfo() external view returns( 
        address[] memory _winners, 
        uint256[] memory _putIns, 
        uint256[] memory _timestamps, 
        uint256[] memory _winsAmounts)
    {
        _winners = lastWinners;
        _putIns = lastPutIns; 
        _timestamps =  lastTimestamps;
        _winsAmounts = lastWinsAmounts;
    }

    function _calcCandsOfWin() internal view returns(
        address[] memory,
        uint256[] memory,
        uint256[] memory,
        uint256[] memory )
    {
        address[] memory _candsOfWin = new address[](numberOfWinners);
        uint256[] memory _putIns = new uint256[](numberOfWinners); 
        uint256[] memory _timestamps = new uint256[](numberOfWinners); 
        uint256[] memory _willWins = new uint256[](numberOfWinners);    

        uint256 _winersTPutIn = 0;
        uint found = 0;
        uint tried = 0;
        while(found<numberOfWinners && tried<lenChasers){
            uint _exist = 0;
            for(uint i = 0; i < numberOfWinners; i++){
                if(chasers[lenChasers-1-tried] == _candsOfWin[i]){
                    _exist = 1;
                }
            }
            if(_exist==0){
                _candsOfWin[found] = chasers[lenChasers-1-tried];
                _putIns[found] = putIns[lenChasers-1-tried];
                _timestamps[found] = timestamps[lenChasers-1-tried];
                _winersTPutIn = _winersTPutIn.add(_putIns[found]);
                found = found + 1;
            }
            tried = tried + 1;   
        }
        if(_winersTPutIn > 0){
            for(uint i = 0; i < numberOfWinners; i++){
                _willWins[i] = balanceOfPrizePool.mul(_putIns[i]).div(_winersTPutIn);  //////TODO
            }
        }
        
        return (_candsOfWin, _putIns, _timestamps, _willWins);
    }

    function setHardCapOfNextPool(uint256 _hardCap) external inState(STATE.IDLE) onlyOwner(){
        hardCapOfNextPool = _hardCap;
    }

    function setFeePrizeAndNextPool1(uint256 _feePrizePool1, uint256 _feeNextPool1) external onlyOwner(){
        require(_feePrizePool1 > 1 && _feePrizePool1 < 99, 'fee should be between 1 and 99');
        require(_feeNextPool1 > 1 && _feeNextPool1 < 99, 'fee should be between 1 and 99');
        require(_feePrizePool1 + _feeNextPool1 < 100, 'invalid marketing fee');
        feePrizePool1 = _feePrizePool1;
        feeNextPool1 = _feeNextPool1;
    }

    function setFeePrizePool2(uint256 _fee) external onlyOwner(){
        require(_fee > 1 && _fee < 99, 'fee should be between 1 and 99');
        feePrizePool2 = _fee;
    }

    function setNumberOfWinners(uint256 _num) external inState(STATE.IDLE) onlyOwner(){
        require(_num > 2, 'The number of Winners should be bigger than 2');
        numberOfWinners = _num;
    }

    function withdrawMarketing(uint256 amount) external onlyOwner(){
        require(amount <= (address(this).balance).sub(balanceOfPrizePool).sub(balanceOfNextPool), 'The amount is bigger than the balance of marketing pool.');
        (payable(msg.sender)).transfer(amount);
    }

    function getMarketingBalance() external view returns(uint256 _balance){
        _balance =  (address(this).balance).sub(balanceOfPrizePool).sub(balanceOfNextPool);
    }

    function sendToThisMarketing(address marketingAddress) external onlyOwner(){
        payable(marketingAddress).transfer((address(this).balance).sub(balanceOfPrizePool).sub(balanceOfNextPool));
    }

    function getPrizePoolBalance() external view returns(uint256 _balance){
        _balance =  balanceOfPrizePool;
    }

    function getNextPoolBalance() external view returns(uint256 _balance){
        _balance =  balanceOfNextPool;
    }
}

