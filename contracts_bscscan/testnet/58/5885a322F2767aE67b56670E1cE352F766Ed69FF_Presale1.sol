pragma solidity ^0.8.0;

import "./Auth.sol";
import "./IBEP20.sol";
import "./SafeMath.sol";

contract Presale1 is Auth{
    using SafeMath for uint256;
    IBEP20 public moonGame;
    address public rewardWallet;
    uint256 public releaseTime = 1635260700;
    uint256 public holdTime = 30 days;
    uint256 public apr = 100; //100% per year
    uint256 public totalHold;

    struct Wallet{
        uint amount;
        uint withdrawAmount;
    }

    mapping(address => Wallet) private wallets;
    mapping(address => uint) private lastRewardReceive;
    event ClaimToken(address indexed beneficiary, uint256 amount);
    event WithdrawMoonGame(address indexed to, uint256 amount);

    constructor(
        IBEP20 _moonGame
    ) Auth(msg.sender){
        moonGame = _moonGame;
    }

    receive() external payable {
        
    }

    function setMoonGame(address _moonGame) external onlyOwner{
        require(_moonGame != address(0));
        moonGame = IBEP20(_moonGame);
    }

    function setRewardWallet(address _rewardWallet) external onlyOwner{
        require(_rewardWallet != address(0));
        rewardWallet = _rewardWallet;
    }

    function setAPR(uint _apr) external onlyOwner{
        apr = _apr;
    }

    function withdrawMoonGame(address _to, uint256 _amount) external onlyOwner{
        require(moonGame.balanceOf(address(this)) >= _amount, "Not enough MGT");
        require(_to != address(0), "Destination is 0");
        moonGame.transfer(_to, _amount);
        emit WithdrawMoonGame(_to, _amount);
    }

    function setBalances(bytes[] calldata amounts) external authorized{
        address buyer;
        uint amount;
        for(uint i=0; i< amounts.length; i++){
            (buyer, amount) = abi.decode(amounts[i], (address, uint));
            wallets[buyer] = Wallet(amount, 0);
            totalHold = totalHold.add(amount);
        }
    }

    function balanceOf(address _holder) public view returns (uint256) {
        return wallets[_holder].amount - wallets[_holder].withdrawAmount;
    }

    function setReleaseTime(uint256 _time) external onlyOwner {
        releaseTime = _time;
    }

    function setHoldTime(uint256 _time) external onlyOwner{
        holdTime = _time;
    }

    function amountCanClaim(address holder) public view returns(uint){
        if(wallets[holder].amount == 0){
            return 0;
        }
        if(block.timestamp < releaseTime.add(holdTime)){
            //release 50% at list
            return wallets[holder].amount.div(2).sub(wallets[holder].withdrawAmount);
        }else{
            // release all after 30 days
            return wallets[holder].amount.sub(wallets[holder].withdrawAmount);
        }
    }

    function rewardAmount(address holder) public view returns(uint){
        uint256 amount = wallets[holder].amount.sub(wallets[holder].withdrawAmount);
        if(amount == 0){
            return 0;
        }
        uint timeElapsed;
        if(lastRewardReceive[holder]!=0){
            timeElapsed = block.timestamp - lastRewardReceive[holder];
        }else{
            timeElapsed = block.timestamp - releaseTime;
        }
        uint reward = amount.mul(timeElapsed).div(365 days).mul(apr).div(100);
        return reward;
    }

    function claim() external{
        require(block.timestamp >= releaseTime, "Wait for release time");
        require(wallets[msg.sender].amount > 0, "Your balance is 0");
        uint256 amount = amountCanClaim(msg.sender);
        if(amount > 0){
            require(moonGame.balanceOf(address(this)) >= amount, "Not enough MGT");
            // reward stake
            uint reward = rewardAmount(msg.sender);
            if(reward > 0){
                try moonGame.transferFrom(rewardWallet, msg.sender, reward) {} catch {}
                lastRewardReceive[msg.sender] = block.timestamp;
            }
            // release
            moonGame.transfer(msg.sender, amount);
            totalHold = totalHold.sub(amount);
            wallets[msg.sender].withdrawAmount = wallets[msg.sender].withdrawAmount.add(amount);
            emit ClaimToken(msg.sender, amount);
        }
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

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}