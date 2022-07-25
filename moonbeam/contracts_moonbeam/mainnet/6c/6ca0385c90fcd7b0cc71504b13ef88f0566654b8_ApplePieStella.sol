/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-05-01
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

// SPDX-License-Identifier: MIT


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

pragma solidity 0.8.9;

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

contract Ownable is Context {
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
    function owner() public view returns (address) {
      return _owner;
    }


    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function renounceOwnership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}

contract ApplePieStella is Context, Ownable {
    using SafeMath for uint256;

    uint256 private Pies_TO_Oven_1MINERS = 86400;//for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 4;
    bool private initialized = false;
    address private recAdd;
    mapping (address => uint256) private ovenryMiners;
    mapping (address => uint256) private claimedPies;
    mapping (address => uint256) private lastOven;
    mapping (address => address) private referrals;
    uint256 private marketPie;
    IERC20 public acceptingToken;

    constructor(IERC20 _acceptingToken) {
        recAdd = msg.sender;
        acceptingToken = _acceptingToken;
    }

    function setAcceptingToken(IERC20 _acceptingToken) external onlyOwner { 
      acceptingToken = _acceptingToken;
    }

    function heatPie(address ref) public {
        require(initialized, "not initialized");

        if(ref == msg.sender) {
            ref = address(0);
        }

        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }

        uint256 pieUsed = getMyPie(msg.sender);
        uint256 newMiners = SafeMath.div(pieUsed,Pies_TO_Oven_1MINERS);
        ovenryMiners[msg.sender] = SafeMath.add(ovenryMiners[msg.sender],newMiners);
        claimedPies[msg.sender] = 0;
        lastOven[msg.sender] = block.timestamp;

        //send referral Pies
        claimedPies[referrals[msg.sender]] = SafeMath.add(claimedPies[referrals[msg.sender]],SafeMath.div(pieUsed, 5));

        //boost market to nerf miners hoarding
        marketPie=SafeMath.add(marketPie,SafeMath.div(pieUsed,5));
    }

    function sellPies() public {
        require(initialized, "not initialized");
        uint256 hasPies = getMyPie(msg.sender);
        uint256 pieValue = calculatePieSell(hasPies);
        uint256 fee = devFee(pieValue);
        claimedPies[msg.sender] = 0;
        lastOven[msg.sender] = block.timestamp;
        marketPie = SafeMath.add(marketPie,hasPies);
        // recAdd.transfer(fee);
        acceptingToken.transfer(recAdd, fee);
        acceptingToken.transfer(msg.sender, SafeMath.sub(pieValue,fee));
        // payable (msg.sender).transfer(SafeMath.sub(pieValue,fee));
    }

    function beanRewards(address adr) public view returns(uint256) {
        uint256 hasPies = getMyPie(adr);
        uint256 pieValue = calculatePieSell(hasPies);
        return pieValue;
    }

    function ovenPie(address ref, uint256 amount) public{
        require(initialized, "not initialized");
        uint256 piesBought = calculatePieBuy(amount,SafeMath.sub(acceptingToken.balanceOf(address(this)),amount));
        piesBought = SafeMath.sub(piesBought,devFee(piesBought));
        uint256 fee = devFee(amount);
        acceptingToken.transferFrom(msg.sender, address(this), amount- fee);
        acceptingToken.transferFrom(msg.sender, recAdd, fee);
        // recAdd.transfer(fee);
        claimedPies[msg.sender] = SafeMath.add(claimedPies[msg.sender],piesBought);
        heatPie(ref);
    }

    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
        // ((PSN*bs)/(PSNH+(PSN+rs)/()))

        // (PSN*bs)/(PSNH + ((PSN*rs) + (PSNH *rt)/rt))
    }

    function calculatePieSell(uint256 pies) public view returns(uint256) {
        // return calculateTrade(pies,marketPie,address(this).balance);
        return calculateTrade(pies,marketPie,acceptingToken.balanceOf(address(this)));
    }

    function calculatePieBuy(uint256 amount,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(amount,contractBalance,marketPie);
    }

    function calculatePieBuySimple(uint256 amount) public view returns(uint256) {
        // return calculatePieBuy(eth,address(this).balance);
        return calculatePieBuy(amount, acceptingToken.balanceOf(address(this)));
    }

    function devFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,devFeeVal),100);
    }

    function seedMarket(uint256 amount) public payable onlyOwner {
        require(marketPie == 0, "pies");
        initialized = true;
        marketPie = 86400000000;
        acceptingToken.transferFrom(msg.sender, address(this), amount);
    }

    function getBalance() public view returns(uint256) {
        // return address(this).balance;
        return acceptingToken.balanceOf(address(this));
    }

    function getMyMiners(address adr) public view returns(uint256) {
        return ovenryMiners[adr];
    }

    function getMyPie(address adr) public view returns(uint256) {
        return SafeMath.add(claimedPies[adr],getPieSinceLastOven(adr));
    }

    function getPieSinceLastOven(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(Pies_TO_Oven_1MINERS,SafeMath.sub(block.timestamp,lastOven[adr]));
        return SafeMath.mul(secondsPassed,ovenryMiners[adr]);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}