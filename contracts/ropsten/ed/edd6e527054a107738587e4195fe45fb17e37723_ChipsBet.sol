/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;


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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

//contract token { function transfer(address receiver, uint amount) public { receiver; amount; } }
interface Token {
  function balanceOf(address _owner) external view returns (uint256);
  function transfer(address _to, uint256 _value) external ;
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract ChipsBet is Context, Ownable {
    using SafeMath for uint256;
    using Address for address;
    Token public chipsToken ;

    uint256 public _withdrewFee = 20;
    uint256 public _burnFee = 10;
    uint256 public _recycleFee = 10;

    address public _burnAddress = 0x000000000000000000000000000000000000dEaD;

    // 总投注记录 
    struct BetInfo {
        address addressUser;
        uint    gameId;
        //...
    }

     //投注池子积累 
    struct GamePool {
        uint    gameId;
        uint256 betWinANum;
        uint256 betWinBNum;
        uint256 betDrewNum;
        uint256 recycleNum;
        uint256 ratioEarn;
        bool    isOver;
    }

    // 用户投注记录 单场比赛累计
    struct UserBetInfo {
        uint    gameId;
        address addressUser;
        uint256 betWinANum;
        uint256 betWinBNum;
        uint256 betDrewNum;
        bool    isExtract;
    }

    //投注场次信息
    //Game gameA(win/loser) gameB(win/loser) drew() 开赛时间 结束投注时间 是否开启投注
    struct GameInfo {
        uint    id;
        uint    results;//0:not-the-start 1:gameA-Win 2:gameB-Win 3:drew
        uint    startTime;
        uint    endTime;
        bool    isBet;
    }

   
    //投注记录Mapping
    mapping (string => mapping(uint => BetInfo)) betMapping;

    //投注场次积累
    mapping (uint => BetInfo)     betInfoapping;
    mapping (uint => GamePool)    gamePoolInfoMapping;
    mapping (uint => GameInfo)    gameInfoMapping;
    mapping (address => mapping(uint => UserBetInfo)) userInfoMapping;
    event PoolBet(address indexed user,uint indexed game,uint betPoolN,uint256 amount);
    event PoolExtract(address indexed user,uint indexed game,uint256 amount);
    event PoolWithdrew(address indexed user,uint indexed game,uint betPoolN,uint256 amount);



    constructor (Token tokenAddress) {
        chipsToken = tokenAddress;
    }


    function addGameInfo(uint id,uint startTime,uint endTime) external onlyOwner() {
        require(startTime > block.timestamp, "The start time needs to be greater than the current time");
        require(startTime < endTime, "The start times need to be smaller than end times");
        require(gameInfoMapping[id].id == 0,"The game already exists");
            
        gameInfoMapping[id] = GameInfo(id,0,startTime,endTime,true);
    }

 //betPool 1 gameA-win 2 gameB-win 3-drew
    function poolBet(address user,uint256 amount,uint game,uint betPoolN) external {
        require(user != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(betPoolN > 0 && betPoolN <= 3,"The game bet wrong");
        require(gameInfoMapping[game].isBet,"The game bet not opened");
        
        if (userInfoMapping[user][game].gameId == 0) {
            userInfoMapping[user][game] = UserBetInfo(game,user,0,0,0,false);
        }
        if (gamePoolInfoMapping[game].gameId == 0) {
            gamePoolInfoMapping[game] = GamePool(game,0,0,0,0,0,false);
        }

        UserBetInfo storage userBet     = userInfoMapping[user][game];
        GamePool   storage  gamePool    = gamePoolInfoMapping[game];
        if (betPoolN == 1) {
            userBet.betWinANum  = userBet.betWinANum.add(amount);
            gamePool.betWinANum = gamePool.betWinANum.add(amount);
        } else if (betPoolN == 2) {
            userBet.betWinBNum  = userBet.betWinBNum.add(amount);
            gamePool.betWinBNum = gamePool.betWinBNum.add(amount);
        }else if (betPoolN == 3) {
            userBet.betDrewNum  = userBet.betDrewNum.add(amount);
            gamePool.betDrewNum = gamePool.betDrewNum.add(amount);
        }

        //userInfoMapping[user][game] = userBet;
        //gamePoolInfoMapping[game]   = gamePool;

        chipsToken.transferFrom(user,address(this),amount);
        emit PoolBet(user,game,betPoolN,amount);
    }

    function releaseGame(uint game,uint results) external onlyOwner() {
        require(results > 0 && results <= 3,"The game results wrong");
        require(gameInfoMapping[game].id > 0,"The game doesn't exist");
        require(gameInfoMapping[game].isBet,"The game bet not opened");
        require(!gamePoolInfoMapping[game].isOver,"The game is over");

        GameInfo storage gameInfo  = gameInfoMapping[game];
        GamePool storage gamePool  = gamePoolInfoMapping[game];
        uint256 winPool;
        uint256 losePool;
        if (results == 1) {
            winPool  = gamePool.betWinANum;
            losePool = losePool.add(gamePool.betWinBNum);
            losePool = losePool.add(gamePool.betDrewNum);
        } else if (results == 2) {
            winPool  = gamePool.betWinBNum;
            losePool = losePool.add(gamePool.betWinANum);
            losePool = losePool.add(gamePool.betDrewNum);
        }else if (results == 3) {
            winPool  = gamePool.betDrewNum;
            losePool = losePool.add(gamePool.betWinANum);
            losePool = losePool.add(gamePool.betWinBNum);
        }
        losePool = losePool.add(gamePool.recycleNum);
        uint256 ratio = losePool.div(winPool);
        gamePool.ratioEarn = ratio;
        gamePool.isOver = true;

        gameInfo.results = results;
        gameInfo.isBet = false;
    }


    function queryPoolEarn(uint game,address user) public view  returns (uint256){
        GameInfo memory gameInfo  = gameInfoMapping[game];
        GamePool   memory  gamePool  = gamePoolInfoMapping[game];
        UserBetInfo memory userBet = userInfoMapping[user][game];
        if(gameInfo.results == 1){
           return userBet.betWinANum.mul(gamePool.ratioEarn);
        }else if(gameInfo.results == 2){
            return userBet.betWinBNum.mul(gamePool.ratioEarn);
        }else if(gameInfo.results == 3){
            return userBet.betDrewNum.mul(gamePool.ratioEarn);
        }
        return 0;
    }

    function extractPoolEarn(uint game,address user) external {
        require(gamePoolInfoMapping[game].isOver,"The game is not over");
        require(userInfoMapping[user][game].gameId > 0,"There will be no betting on the race");
        require(!userInfoMapping[user][game].isExtract,"Earnings have been withdrawn");

        GameInfo    memory      gameInfo     = gameInfoMapping[game];
        GamePool    memory      gamePool     = gamePoolInfoMapping[game];
        UserBetInfo storage     userBet      = userInfoMapping[user][game];
        uint256 earnAmount;
        uint256 betAmount;
        if(gameInfo.results == 1){
            betAmount = userBet.betWinANum;
            earnAmount = betAmount.mul(gamePool.ratioEarn);
        }else if(gameInfo.results == 2){
            betAmount = userBet.betWinBNum;
            earnAmount = betAmount.mul(gamePool.ratioEarn);
        }else if(gameInfo.results == 3){
            betAmount  = userBet.betDrewNum;
            earnAmount = betAmount.mul(gamePool.ratioEarn);
        }
        require(earnAmount > 0,"Not EarnPool extract");
        earnAmount = earnAmount.add(betAmount);
        transferChipsToken(user,earnAmount);
        emit PoolExtract(user,game,earnAmount);
        userBet.isExtract = true;
    }


    function withdrawBetPool(address user,uint game,uint betPoolN) external {
        require(gameInfoMapping[game].endTime > block.timestamp,"The betting time has ended");
        require(userInfoMapping[user][game].gameId > 0,"There will be no betting on the race");

        UserBetInfo storage userBet  = userInfoMapping[user][game];
        GamePool    storage gamePool = gamePoolInfoMapping[game];

        uint256 betAmount;
        if(betPoolN == 1){
            betAmount = userBet.betWinANum;
            userBet.betWinANum = 0;
            gamePool.betWinANum = gamePool.betWinANum.sub(betAmount);
        }else if(betPoolN == 2){
           betAmount = userBet.betWinBNum;
           userBet.betWinBNum = 0;
           gamePool.betWinBNum = gamePool.betWinBNum.sub(betAmount);
        }else if(betPoolN == 3){
            betAmount = userBet.betDrewNum;
            userBet.betDrewNum = 0;
            gamePool.betDrewNum = gamePool.betDrewNum.sub(betAmount);
        }
        require(betAmount > 0,"Not BetPool Game");

        uint256 burnAmount     = calculateBurnFee(betAmount);
        uint256 recycleAmount  = calculateRecycleFee(betAmount);
        uint256 withdrewAmount = betAmount.sub(burnAmount.add(recycleAmount));
        transferChipsToken(user,withdrewAmount);
        transferChipsToken(_burnAddress,burnAmount);
        gamePool.recycleNum = gamePool.recycleNum.add(recycleAmount);
        emit PoolWithdrew(user,game,betPoolN,withdrewAmount);
    }


    function transferChipsToken(address to, uint256 amount) internal {
        if (chipsToken.balanceOf(address(this)) > amount){
            chipsToken.transfer(to,amount);
        }else{
            chipsToken.transfer(to,chipsToken.balanceOf(address(this)));
        }   
    }

    function calculateWithdrewFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_withdrewFee).div(
            10**2
        );
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(
            10**2
        );
    }

    function calculateRecycleFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_recycleFee).div(
            10**2
        );
    }

    function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
        _burnFee = burnFee;
    }

    function setRecycleFeePercent(uint256 recycleFee) external onlyOwner() {
        _recycleFee = recycleFee;
    }


    function setGameBetOpen(uint game) external onlyOwner() {
        if(gameInfoMapping[game].id > 0){
            gameInfoMapping[game].isBet = true;
        }
    }

    function setGameBetClose(uint game) external onlyOwner() {
        if(gameInfoMapping[game].id > 0){
            gameInfoMapping[game].isBet = false;
        }
    }

}