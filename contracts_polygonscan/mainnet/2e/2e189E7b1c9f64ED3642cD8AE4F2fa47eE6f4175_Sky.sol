// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IApeRouter02.sol";
import "./interfaces/ILinkPeg.sol";
import "./interfaces/ISky.sol";

import "./Roller.sol";
import "./Cloud.sol";
import "./Charge.sol";


contract Sky is Ownable, ISky {
   using SafeMath for uint256;
   address public constant LINK_TOKEN = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
   address public constant VRF_COORDINATOR = 0x3d2341ADb2D31f1c5530cDC622016af293177AE0;
   bytes32 public keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
   address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
   uint256 public chainlinkFee = 100000000000000; // 0.0001 LINK
   Polyroll public polyroll = Polyroll(0x9Fad71370AE14Ef15dbd1A1767633C8e53d01A44);
   PolyrollMiner public polyrollMiner = PolyrollMiner(0xC96D9032770010f5f3D167cA4eeca84a0Bca0Fa2);
   IERC20 public constant ACTUAL_LINK_TOKEN = IERC20(0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39);
   IApeRouter02 public apeRouter = IApeRouter02(0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607);
   ILinkPeg public linkPeg = ILinkPeg(0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b);
   mapping(address=>uint256) public clouds;
   address[] public cloudsIndex;

   uint256 public totalStart = 0;
   uint256 public totalOver = 0;
   

   modifier onlyApprovedAddress(){
       require(msg.sender == owner()
               || clouds[msg.sender] > 0);
       _;
   }
   
   constructor(){
       
   }
   
   fallback() external payable {
       
   }
   receive() external payable {
       
   }
   function cloudsLength() external view returns(uint256){
       return cloudsIndex.length;
   }

   function makeLink() public onlyApprovedAddress {
       if(IERC20(LINK_TOKEN).balanceOf(address(this)) < uint256(10 ** 18).div(3)){
           if(IERC20(ACTUAL_LINK_TOKEN).balanceOf(address(this)) < uint256(10 ** 18)) {
               address[] memory path = new address[](2);
               path[0] = address(WMATIC);
               path[1] = address(ACTUAL_LINK_TOKEN);
               uint256[] memory expectedPayment = apeRouter.getAmountsIn(uint256(10 ** 18), path);
               if(address(this).balance > expectedPayment[0]){
                   apeRouter
                       .swapExactETHForTokens{ value: expectedPayment[0] }(
                                                                           expectedPayment[0],
                                                                           path,
                                                                           address(this),
                                                                           block.timestamp + 5000
                                                                           );
                  
               
               }
           }
           IERC20(ACTUAL_LINK_TOKEN).approve(address(linkPeg),
                                             IERC20(ACTUAL_LINK_TOKEN).balanceOf(address(this)));
           linkPeg.swap(IERC20(ACTUAL_LINK_TOKEN).balanceOf(address(this)),
                        address(ACTUAL_LINK_TOKEN),
                        address(LINK_TOKEN));
       }
       
   }
   
   function getLink() public override onlyApprovedAddress returns(uint256){
       makeLink();
       if(IERC20(LINK_TOKEN).balanceOf(address(this)) >= uint256(10 ** 18).div(3)){
           IERC20(LINK_TOKEN).transfer(msg.sender, uint256(10 ** 18).div(3).sub(1) );
           return uint256(10 ** 18).div(3).sub(1);
       }
       
       return 0;
   }
   
   function getMatic(uint256 amount) public override onlyApprovedAddress returns(uint256){
       if(address(this).balance >= amount){
           payable(msg.sender).transfer(amount);
           clouds[msg.sender] = clouds[msg.sender].add(amount);
           totalOver = totalOver.add(amount);
           Roller(payable(msg.sender)).incWaitRounds();
           return amount;
       }
       return 0;
   }
   
   function createCloud(uint256 maticAmount) external payable onlyOwner {
       Cloud cloud = new Cloud(
                               address(this), // taker
                               owner(), // ref
                               address(this), // sky
                               500
                               );
       cloudsIndex.push(address(cloud));
       makeLink();
       if(address(this).balance >= maticAmount){
           payable(address(cloud)).transfer(maticAmount);
           clouds[address(cloud)] = maticAmount;
           totalStart = totalStart.add(maticAmount);
       }

       if(IERC20(LINK_TOKEN).balanceOf(address(this)) >= uint256(10 ** 18).div(3)){
           IERC20(LINK_TOKEN).transfer(address(cloud), uint256(10 ** 18).div(3) );
       }
       cloud.start();
   }

   function createCharge(uint256 maticAmount) external payable onlyOwner {
       Charge cloud = new Charge(
                               address(this), // taker
                               owner(), // ref
                               address(this), // sky
                               1000
                               );
       cloudsIndex.push(address(cloud));
       makeLink();
       if(address(this).balance >= maticAmount){
           payable(address(cloud)).transfer(maticAmount);
           clouds[address(cloud)] = maticAmount;
           totalStart = totalStart.add(maticAmount);
       }

       if(IERC20(LINK_TOKEN).balanceOf(address(this)) >= uint256(10 ** 18).div(3)){
           IERC20(LINK_TOKEN).transfer(address(cloud), uint256(10 ** 18).div(3) );
       }
       cloud.start();
   }

   function stop() public onlyOwner {
       for(uint256 i = 0; i < cloudsIndex.length; i++){
           Roller(payable(cloudsIndex[i])).stop();
       }
   }

   function start() external onlyOwner {
       for(uint256 i = 0; i < cloudsIndex.length; i++){

           if(IERC20(LINK_TOKEN).balanceOf(address(cloudsIndex[i])) < chainlinkFee){
               makeLink();
               IERC20(LINK_TOKEN).transfer(address(cloudsIndex[i]), uint256(10**18).div(3));
           }
           
           if(address(cloudsIndex[i]).balance < clouds[address(cloudsIndex[i])]){
               payable(address(cloudsIndex[i])).transfer(clouds[address(cloudsIndex[i])]
                                                         .sub(address(cloudsIndex[i]).balance));
           }
           
           Roller(payable(cloudsIndex[i])).start();

           
           
       }
   }
   
   function withdraw() public onlyOwner {
       for(uint256 i = 0; i < cloudsIndex.length; i++){
           Roller(payable(cloudsIndex[i])).withdraw();
       }
   }

   function swipeMatic(uint256 amount) public onlyOwner {
       if(amount == 0){
           if(address(this).balance > 0){
               payable(msg.sender).transfer(address(this).balance);
           }
       }else{
           if(address(this).balance >= amount) {
               payable(msg.sender).transfer(amount);
           }
       }
   }

   function done() external onlyOwner {
       stop();
       withdraw();
       swipeMatic(0);
       swipeTokens(IERC20(0xC68e83a305b0FaD69E264A1769a0A070F190D2d6));
       swipeTokens(IERC20(LINK_TOKEN));
   }
   
   
   function swipeTokens(IERC20 token) public onlyOwner {
       if(token.balanceOf(address(this)) > 0){
           token.transfer(owner(), token.balanceOf(address(this)));
       }
   }

   function total() public view returns(uint256 totalMatic, uint256 totalRoll){
       totalMatic = address(this).balance;
       totalRoll = IERC20(0xC68e83a305b0FaD69E264A1769a0A070F190D2d6).balanceOf(address(this));
       for(uint256 i = 0; i < cloudsIndex.length; i++){
           totalMatic = totalMatic.add(address(cloudsIndex[i]).balance);
           totalRoll = totalRoll
               .add(polyrollMiner.userReward(address(cloudsIndex[i])))
               .add(IERC20(0xC68e83a305b0FaD69E264A1769a0A070F190D2d6).balanceOf(address(cloudsIndex[i])));
       }
       return (totalMatic, totalRoll);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IApeRouter01.sol";

interface IApeRouter02 is IApeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILinkPeg {
   function swap(
    uint256 amount,
    address source,
    address target
  )
    external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISky {
    function getLink() external returns(uint256);
    function getMatic(uint256) external returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/Polyroll.sol";
import "./interfaces/PolyrollMiner.sol";
import "./interfaces/ISky.sol";

import "./libraries/Utils.sol";

contract Roller is Ownable,  VRFConsumerBase {
    using SafeMath for uint256;
    bytes32 public keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
    uint256 public chainlinkFee = 100000000000000; // 0.0001 LINK
    address public constant VRF_COORDINATOR = 0x3d2341ADb2D31f1c5530cDC622016af293177AE0;
    IERC20 public constant LINK_TOKEN = IERC20(0xb0897686c545045aFc77CF20eC7A532E3120E0F1);
    
    IERC20 public constant ROLL_TOKEN = IERC20(0xC68e83a305b0FaD69E264A1769a0A070F190D2d6);
    Polyroll public polyroll = Polyroll(0x9Fad71370AE14Ef15dbd1A1767633C8e53d01A44);
    PolyrollMiner public polyrollMiner = PolyrollMiner(0xC96D9032770010f5f3D167cA4eeca84a0Bca0Fa2);
    ISky sky;
    
    uint256 waitForRounds = 0;
    uint256 public ROLLING = 0;
    uint256 public startBalance;
    address pTaker;
    address refer;
    uint256 wasPendingBet = 0;
    uint256 pendingBet = 0;
    uint256 balancePercentage = 500;
    uint256[] public rolls;
    uint256 lastRollCounted = 0;
    uint256 randomIndex = 0;
    uint256 public losses = 0;
    uint256 public wins = 0;
    constructor(address pTaker_, address refer_, address sky_, uint256 balancePercentage_) VRFConsumerBase(VRF_COORDINATOR, address(LINK_TOKEN)){
        pTaker = pTaker_;
        refer = refer_;
        sky = ISky(payable(sky_));
        balancePercentage = balancePercentage_;
    }

           
    fallback() external payable {
        
    }
    receive() external payable {
        
    }

    function getStartBalance() internal view returns(uint256){
        return startBalance;
    }
    
    function takeProfit() internal returns(uint256){
        if(address(this).balance > getStartBalance()){
            uint256 profit = address(this).balance.sub(getStartBalance());
            payable(pTaker).transfer(address(this).balance.sub(getStartBalance()));
            return profit;
        }
        return 0;
    }

    function getBetAmount() public virtual view returns(uint256){
        uint256 betAmount = Utils.calculatePercentageCents(address(this).balance,
                                                           balancePercentage);
        if(betAmount < polyroll.minBetAmount()) {
            betAmount = polyroll.minBetAmount();
        } else if( betAmount > polyroll.maxBetAmount() ) {
            betAmount = polyroll.maxBetAmount();
        }
        return betAmount;
    }

    function rollsLength() external view returns(uint256){
        return rolls.length;
    }
    

    function placeBet(uint256 randomValue) internal {

        uint256 betAmount = getBetAmount();
        if(address(this).balance < betAmount.mul(10)){
            sky.getMatic(betAmount.mul(10));
        }
        
        if(address(this).balance < betAmount){
                revert("NEB");
        }
        if(LINK_TOKEN.balanceOf(address(polyroll)) < chainlinkFee){
            LINK_TOKEN.transfer(address(polyroll), chainlinkFee);
        }
        rolls.push(polyroll.betsLength());
        (uint256 mask, uint256 modulo) = getBetInfo(randomValue);
        polyroll.placeBet{ value: betAmount }(mask, modulo, refer);
    }

    function onWin(uint256) internal virtual {}
    function onLoss(uint256) internal virtual{}
    
    function updateRollOutcome() internal {
        if(rolls.length == 1 || rolls.length > lastRollCounted){
            if(polyroll.bets(rolls[rolls.length-1]).winAmount > 0){
                wins = wins.add(1);
                onWin(polyroll.bets(rolls[rolls.length-1]).outcome);
            } else {
                losses = losses + 1;
                lastRollCounted = rolls.length;
                onLoss(polyroll.bets(rolls[rolls.length-1]).outcome);
            }

        }
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomValue) internal override {
        randomIndex = randomIndex.add(1);
        uint256 randomNumber = uint256(keccak256(
                                                 abi.encode(randomValue, requestId, randomIndex)
                                                 ));
        updateRollOutcome();
        roll(randomNumber);
    }


    function roll(uint256 randomValue) internal{
        
        takeProfit();
        
        if(pendingBet == 1){
            wasPendingBet = wasPendingBet + 1;
        }
        
        if(wasPendingBet > waitForRounds || pendingBet == 0){
            placeBet(randomValue);
        }

        if(ROLLING == 1){
            requestRoll();
        }

    }
    
    function stop() external onlyOwner {
        ROLLING = 0;
    }
    function getBetInfo(uint256) internal virtual returns(uint256, uint256){
        return (0,0);
    }

    function setBalancePercentage(uint256 n) external onlyOwner(){
        balancePercentage = n;
    }

    function setStartBalance(uint256 balance) external onlyOwner {
        startBalance = balance;
    }
    
    
    function start() external onlyOwner {
        if(ROLLING == 0){
            ROLLING = 1;
            if(startBalance == 0){
                startBalance = address(this).balance;
            }
            requestRoll();
        }
    }

    function requestRoll() internal {
        if(LINK_TOKEN.balanceOf(address(this)) < chainlinkFee){
            if(sky.getLink() == 0){
                revert();
            }
        }
        requestRandomness(keyHash, chainlinkFee);
    }
    
    function incWaitRounds() public onlyOwner {
        
        waitForRounds = waitForRounds.add(1);
        
    }
    function decWaitRounds() public onlyOwner {
        if(waitForRounds > 0){
            waitForRounds = waitForRounds.sub(1);
        }
    }

    function withdraw() external onlyOwner {
        if(address(this).balance > 0){
            ROLLING = 0;
            payable(msg.sender).transfer(address(this).balance);
        }
        harvest();
        swipeTokens(LINK_TOKEN);
        swipeTokens(ROLL_TOKEN);
    }

    function harvest() public onlyOwner {
        if(polyrollMiner.userReward(address(this)) > 0){
                                                   polyrollMiner.withdraw();
        }
    }
  
    function swipeTokens(IERC20 token) public onlyOwner {
        if(token.balanceOf(address(this)) > 0){
            token.transfer(msg.sender, token.balanceOf(address(this)));
        }
    }
  
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/Polyroll.sol";
import "./interfaces/PolyrollMiner.sol";
import "./interfaces/ISky.sol";

import "./Roller.sol";

import "./libraries/Utils.sol";

contract Cloud is Roller {
    using SafeMath for uint256;

    uint256 public maxPicks = 2;
    uint256[] public alwaysPicked;
    uint256 public lastAlwaysPickedReplaced;
    
    constructor(address pTaker_,
                address refer_,
                address sky_,
                uint256 balancePercentage_) Roller(pTaker_, refer_, sky_, balancePercentage_){
        alwaysPicked.push(27);
    }
    
    function pick(uint256 randomValue) public view returns(uint256){
        uint256 number = 1;
        uint256 max = (2 ** 37);
        uint256 numbers = 0;
        uint256 maxPicksModulo = maxPicks;
        uint256 addonPicks = 1;
        if(losses >= wins){
            maxPicksModulo = 23;
            addonPicks = (losses - wins) > 10 ? 10 : (losses - wins);
        }
        
        uint256 pickMax = (uint256(keccak256(abi.encode(randomValue, randomIndex * 2))) % maxPicksModulo) + addonPicks ;
        
        bool[] memory picks = new bool[](37);
        uint256 i = 0;
        while(i < pickMax){
            picks[36-(uint256(keccak256(abi.encode(randomValue, randomIndex + i + 1))) % 37)] = true;
            i = i + 1;
        }
        for(i = 0; i < alwaysPicked.length; i++){
            picks[36-(alwaysPicked[i] % 37) ] = true;
        }
        for(i = 0; i < 37; i++){
            number = number << 1;
            if(picks[i] && numbers < 30){
                number = number | 1;
                numbers = numbers + 1;
            }
        }
        return (number % max);
    }

    
    function getBetInfo(uint256 randomValue) internal view override returns(uint256, uint256){
        uint256 mask = pick(randomValue);
        return (mask, 37);
    }

    function onWin(uint256) internal override {
        
    }

    function onLoss(uint256 outcome) internal override {
        if(alwaysPicked.length < 2){
            alwaysPicked.push(outcome);
        }
    }

    function getBetAmount() public override pure returns(uint256){
        return 2 ether;
    }
    
   
      
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/Polyroll.sol";
import "./interfaces/PolyrollMiner.sol";
import "./interfaces/ISky.sol";

import "./Roller.sol";

import "./libraries/Utils.sol";

contract Charge is Roller {
    using SafeMath for uint256;

    uint256[] outcomes;
  
    constructor(
                address pTaker_,
                address refer_,
                address sky_,
                uint256 balancePercentage_
                ) Roller(pTaker_, refer_, sky_, balancePercentage_){

    }

    function betAverage(uint256 random) internal view returns(uint256){
       
        uint256 length = polyroll.betsLength();
        uint256 lastBet = length-1;

        if(rolls.length > 0){
            lastBet = rolls[rolls.length-1];
        }

        uint256 dl = random % 2 + length - lastBet + 1;
        uint256 adl = 0;
        uint256 average = 0;

        for(uint256 i = length - dl; i < length; i++){
            if(polyroll.bets(i).modulo > 0 ){
                average = average.add(polyroll.bets(i).outcome.mul(100).div(polyroll.bets(i).modulo));
                adl = adl.add(1);
            }
        }
        
        if(average.div(adl) < 25){
            return 1 + (random % 25);
        }
        
        if(average.div(adl) < 50){
            return 25 + (random % 25);
        }

        if(average.div(adl) < 75){
            return 50 + (random%25);
        }

        return 1 + (random % 99);

        
    }

    function getBetAmount() public override pure returns(uint256){
        return 2 ether;        
    }

    function getBetInfo(uint256 random) internal view override returns(uint256, uint256){
        return (betAverage(random), 100);
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

interface IApeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Polyroll {
     // Info of each bet.
    struct Bet {
        // Wager amount in wei.
        uint amount;
        // Modulo of a game.
        uint8 modulo;
        // Number of winning outcomes, used to compute winning payment (* modulo/rollUnder),
        // and used instead of mask for games with modulo > MAX_MASK_MODULO.
        uint8 rollUnder;
        // Bit mask representing winning bet outcomes (see MAX_MASK_MODULO comment).
        uint40 mask;
        // Block number of placeBet tx.
        uint placeBlockNumber;
        // Address of a gambler, used to pay out winning bets.
        address payable gambler;
        // Status of bet settlement.
        bool isSettled;
        // Outcome of bet.
        uint outcome;
        // Win amount.
        uint winAmount;
    }
    function minBetAmount() external view returns(uint256);
    function maxBetAmount() external view returns(uint256);
    function placeBet(uint256 betMask, uint256 modulo, address referrer) external payable;
    function refundBet(uint256 betId) external;
    function betsLength() external view returns (uint256);
    function bets(uint256) external view returns(Bet memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PolyrollMiner {
     function withdraw() external;
     function userReward(address) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Utils {
  using SafeMath for uint256;
  function hashString(string memory domainName)
    internal
    pure
    returns (bytes32) {
      return keccak256(abi.encode(domainName));
  }
  function calculatePercentage(uint256 amount,
                               uint256 percentagePoints,
                               uint256 maxPercentagePoints)
    internal
    pure
    returns (uint256){  
    return amount.mul(percentagePoints).div(maxPercentagePoints);
  }
  
  function percentageCentsMax()
    internal
    pure
    returns (uint256){
    return 10000;
  }
  
  function calculatePercentageCents(uint256 amount,
                                    uint256 percentagePoints)
    internal
    pure
    returns (uint256){
    return calculatePercentage(amount, percentagePoints, percentageCentsMax());
  }

  function sumArray(uint256[] memory numbers) internal pure returns (uint256){
    uint256 total = 0;
    for(uint256 i = 0; i < numbers.length; i++){
      total = total.add(numbers[i]);
    }
    return total;
  }
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}