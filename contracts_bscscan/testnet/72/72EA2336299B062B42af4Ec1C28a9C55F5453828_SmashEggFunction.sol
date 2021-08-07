/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/OwnableContract.sol

pragma solidity 0.6.6;

contract OwnableContract {
    address public owner;
    address public pendingOwner;
    address public admin;
    address public dev;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewDev(address oldDev, address newDev);
    event NewOwner(address oldOwner, address newOwner);
    event NewPendingOwner(address oldPendingOwner, address newPendingOwner);

    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
        dev   = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"onlyOwner");
        _;
    }

    modifier onlyPendingOwner {
        require(msg.sender == pendingOwner,"onlyPendingOwner");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner,"onlyAdmin");
        _;
    } 

    modifier onlyDev {
        require(msg.sender == dev  || msg.sender == owner,"onlyDev");
        _;
    } 
    
    function transferOwnership(address _pendingOwner) public onlyOwner {
        emit NewPendingOwner(pendingOwner, _pendingOwner);
        pendingOwner = _pendingOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit NewOwner(owner, address(0));
        emit NewAdmin(admin, address(0));
        emit NewPendingOwner(pendingOwner, address(0));

        owner = address(0);
        pendingOwner = address(0);
        admin = address(0);
    }
    
    function acceptOwner() public onlyPendingOwner {
        emit NewOwner(owner, pendingOwner);
        owner = pendingOwner;

        address newPendingOwner = address(0);
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }    
    
    function setAdmin(address newAdmin) public onlyOwner {
        emit NewAdmin(admin, newAdmin);
        admin = newAdmin;
    }

    function setDev(address newDev) public onlyOwner {
        emit NewDev(dev, newDev);
        dev = newDev;
    }

}

// File: contracts/RandomInterface.sol

pragma solidity 0.6.6;

interface RandomInterface{

    function getRandomNumber() external returns(uint256);
}

// File: contracts/SmashEggFunction.sol

pragma solidity 0.6.6;




interface LoserChickNftInterface{
     function createNFT(address owner) external returns(uint256);
     function totalSupply() external returns(uint256);
     function maxSupply() external returns(uint256);    
}

contract SmashEggFunction is OwnableContract{

    using SafeMath for uint256;

    uint public constant PRECISION = 1e17;

    uint256 public constant LUCKY_CHICK_INDEX = 0;
    uint256 public constant LABOR_CHICK_INDEX = 1;
    uint256 public constant BOSS_CHICK_INDEX = 2;
    uint256 public constant TRUMP_CHICK_INDEX = 3;
    uint256 public constant SHRIEKING_CHICK_INDEX = 4;


    address[] public loserChickAddrArray;

    RandomInterface public randomContract;

    uint256 public winningProbability; // Get NFT Probability

    uint256[] public chickProbability; // Per chick Rate, 0 is luckyChick, 1 is laborChick, 2 is bossChick, 3 is trumpChick.

    uint256 private seed;

    uint256 public activityNFTProbability;

    address public activityNFTAddr;

    uint256 public shriekingStartTimestamp = 0;
    uint256 public shriekingEndTimestamp = 0;
    bool public hasCreatedShriekingChick = false;
    bool public shriekingChickSwitch = false;
    uint256 public shriekingProbability = 99998000000000000; 

    event SmashEggsEvent(address userAddr, uint256 eggCount, uint256 chickCount, address[] chickAddrArray, uint256[] tokenIdArray);
    event ActivityEvent(address userAddr, uint256 NFTConut, address NFTAddr);

    constructor(address _shriekingChickAddr, address _luckyChickAddr, address _laborChickAddr, address _bossChickAddr, address _trumpChickAddr, address _randomAddr) public{
        loserChickAddrArray = new address[](5);
        loserChickAddrArray[LUCKY_CHICK_INDEX] = _luckyChickAddr;
        loserChickAddrArray[LABOR_CHICK_INDEX] = _laborChickAddr;
        loserChickAddrArray[BOSS_CHICK_INDEX] = _bossChickAddr;
        loserChickAddrArray[TRUMP_CHICK_INDEX] = _trumpChickAddr;
        loserChickAddrArray[SHRIEKING_CHICK_INDEX] = _shriekingChickAddr;

        randomContract = RandomInterface(_randomAddr);


        chickProbability = new uint256[](4);
        chickProbability[LUCKY_CHICK_INDEX] = 99926853587174232; // luckyChick  0.000428428571428571 * 1e17 = 42842857142857      0.0007314641282576833
        chickProbability[LABOR_CHICK_INDEX] = 99512243426578954; // laborChick  0.002428428571428570 * 1e17 = 242842857142857     0.004146101605952781
        chickProbability[BOSS_CHICK_INDEX] = 97561046401020877;  // bossChick   0.011428428571428600 * 1e17 = 1142842857142860    0.019511970255580775
        chickProbability[TRUMP_CHICK_INDEX] = 0;                 // trumpChick  0.571428428571429000 * 1e17 = 57142842857142900   0.9756104640102089

        winningProbability = 58571371428571464; // 0.571428428571429000 + 0.011428428571428600 + 0.002428428571428570 + 0.000428428571428571
    }

    function updateActivityNFT(address _activityNFTAddr, uint256 _activityNFTProbability) public onlyOwner{
        activityNFTAddr = _activityNFTAddr;
        activityNFTProbability = _activityNFTProbability;
    }

    function updateChickProbability(uint index, uint256 probability) public onlyOwner{
        require(index < 4, 'Index is wrong!');
        chickProbability[index] = probability;
    }

    function updateTotalProbability(uint256 probability) public onlyOwner{
        winningProbability = probability;
    }

    function smashEggs(uint256 amount)  external onlyDev  {
        require(amount <= 10, 'amount should be less than or equal to 10');
           
        address[] memory chickAddrArray = new address[](10);
        uint256[] memory tokenIds = new uint256[](10);
        uint256 count = 0;

        for(uint256 i=0; i<amount; i++){
            if(isWon()){
                (uint256 tokenId, address chickAddr) = getOneChickNFT();
                if(tokenId != 0){
                    chickAddrArray[count] = chickAddr;
                    tokenIds[count] = tokenId;

                    count++;
                }
            }
        }

        if(amount == 10 && count < 5){
            uint256 count2 = uint256(5).sub(count);
            for(uint256 i=0; i<count2; i++){
                (uint256 tokenId, address chickAddr) = getOneChickNFT();
                if(tokenId != 0){
                    chickAddrArray[count] = chickAddr;
                    tokenIds[count] = tokenId;

                    count++;
                }
            }
        }

        emit SmashEggsEvent(tx.origin, amount, count, chickAddrArray, tokenIds);
    }

    /**
     * @notice Won or not
     */
    function isWon() internal returns(bool){
        uint256 random = updateSeed() % PRECISION;
        if(random < winningProbability){
            return true;
        }
    }

    function getOneChickNFT() internal returns(uint256, address){
        uint256 random = updateSeed() % PRECISION;
        uint256 index = TRUMP_CHICK_INDEX;

        if(shouldGenerateShriekingChick()){
            index = SHRIEKING_CHICK_INDEX;
            hasCreatedShriekingChick = true;
        }else{
            for(uint256 i=0; i<chickProbability.length; i++){
                if(random > chickProbability[i]){
                    index = i;
                    break;
                }
            }
        }

        address chickAddr = loserChickAddrArray[index];
        LoserChickNftInterface loserChickNFT = LoserChickNftInterface(chickAddr);

        uint256 tokenId = 0;
        if(loserChickNFT.totalSupply() < loserChickNFT.maxSupply()){
            tokenId = loserChickNFT.createNFT(tx.origin);
        }
        return (tokenId, chickAddr);
    }

    function shouldGenerateShriekingChick() internal returns(bool){
        if(shriekingChickSwitch && shriekingStartTimestamp < block.timestamp 
          && block.timestamp <= shriekingEndTimestamp && !hasCreatedShriekingChick){
            uint256 random = updateSeed() % PRECISION;
            return random > shriekingProbability;
        }
        return false;
    }

    function updateShriekingProbability(uint256 _shriekingProbability) public onlyOwner {
        shriekingProbability = _shriekingProbability;
    }

    function updateShriekingTimestamp(uint256 _startTimestamp, uint256 _hours) public onlyAdmin {
        shriekingStartTimestamp = _startTimestamp;
        shriekingEndTimestamp = shriekingStartTimestamp.add(_hours.mul(3600));

        hasCreatedShriekingChick = false;
    }

    function updateShriekingChickSwitch(bool _shriekingChickSwitch) public onlyOwner{
        shriekingChickSwitch = _shriekingChickSwitch;
    }

    function updateRandomAddr(address _randomAddr) public onlyOwner{
        randomContract = RandomInterface(_randomAddr);
    }

    function updateSeed() internal returns(uint256 random){
        seed += randomContract.getRandomNumber();        
        random = uint256(keccak256(abi.encodePacked(seed)));
    }


    function updateLoserChickAddr(uint256 index, address loserChickAddr) public onlyOwner{
        loserChickAddrArray[index] = loserChickAddr;
    }
}