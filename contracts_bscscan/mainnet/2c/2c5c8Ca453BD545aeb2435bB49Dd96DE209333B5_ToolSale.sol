/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

pragma solidity 0.8.2;

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
}

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

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

pragma solidity 0.8.2;

interface IMMTools {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function forge(address _addr, uint256 _rarity, string memory _tokenURI) external;
}

pragma solidity 0.8.2;

interface IMMStaking {
    function users(address _addr) external view returns (
        uint40 deposit_time,
        uint256 total_deposit,
        uint256 compound,
        uint256 unclaimed,
        uint256 unstaked,
        uint256 unstaked_time);
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ToolSale{
    
    using SafeMath for uint256;
    
    address public constant MYTH_TOKEN_ADDRESS = 0xA60ea04c796E8Fb17B690593fd9c61D31f9AA918;
    address public constant MMTOOLS_ADDRESS = 0x5C9296642A4B8eBEe0D4D8919438D74CeB6B157A;
    address public constant STAKING_ADDRESS = 0x71e7a4ED1E81cD81A6BAf3DfA06b2ceA1Fa25Be2;
    
    IERC20 public MythToken;
    IMMTools public MMTools;
    IMMStaking public MMStaking;
    
    
    address public owner;
    address public marketing;
    address public fee;
    
    uint256 public cur_pickaxe;
    uint256 public max_pickaxe;
    uint256 public cur_axe;
    uint256 public max_axe;
    uint256 public cur_fishing_rod;
    uint256 public max_fishing_rod;
    
    uint256 public fee_price = 500000000000000;
    
    /**
     * @dev Emitted when the buy is executed by an `account`.
     */
    event Buy(address indexed account, uint256 indexed token_id, uint256 indexed value);
    

    constructor(address _marketing, address _fee) {
        owner = msg.sender;
        marketing = _marketing;
        fee = _fee;
        
        cur_pickaxe = 0;
        max_pickaxe = 5000;
        cur_axe = 0;
        max_axe = 5000;
        cur_fishing_rod = 0;
        max_fishing_rod = 5000;
        
        MythToken = IERC20(MYTH_TOKEN_ADDRESS);
        MMTools = IMMTools(MMTOOLS_ADDRESS);
        MMStaking = IMMStaking(STAKING_ADDRESS);
        
        MythToken.approve(address(this), MythToken.totalSupply());
    }
    
    function getToolPrice() external pure returns (uint256){
        return 1000 * 10 ** 18; // TODO: price oracle
    }
    
    function checkDiscount(address _addr) external view returns (uint256 percentage, uint256 discount){
        ( , uint256 total_deposit, , , , ) = MMStaking.users(_addr);
        
        percentage = 0;
        discount = 0;
        
        if(total_deposit >= 2000 * 10 ** 18){
            percentage = total_deposit.div(2000 * 10 ** 18);
            discount = this.getToolPrice().mul(percentage).div(100);
        }
    }
    
    function _distributeFees(uint256 _amount) internal {
        MythToken.transferFrom(address(this), marketing, _amount.mul(70).div(100));
        MythToken.transferFrom(address(this), fee, _amount.mul(30).div(100));
    }
    
    function getDiscount() external view returns (uint256){
        ( , uint256 discount) = this.checkDiscount(msg.sender);
        return (this.getToolPrice() - discount);
    }
    
    function buy(string memory _tokenURI, uint256 _amount, uint256 _id) payable external {
        ( , uint256 discount) = this.checkDiscount(msg.sender);
        require(_amount == (this.getToolPrice() - discount) && fee_price == msg.value, "Error: Insufficient balance.");
        require((_id == 0 && cur_pickaxe < max_pickaxe) || 
                (_id == 1 && cur_axe < max_axe) || 
                (_id == 2 && cur_fishing_rod < max_fishing_rod), 
                "Error: Exceeds maximum sale.");
        
        if(_id == 0) cur_pickaxe++;
        if(_id == 1) cur_axe++;
        if(_id == 2) cur_fishing_rod++;
        
        MMTools.forge(msg.sender, 0, _tokenURI);
        MythToken.transferFrom(msg.sender, address(this), _amount);
        payable(fee).transfer(msg.value);
        _distributeFees(_amount);
        
        emit Buy(msg.sender, _id, _amount);
    }
    
    function clearBNB() external {
        require(owner == msg.sender, "Error: Insufficient permission.");
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function clearToken(IERC20 _token) external {
        require(owner == msg.sender, "Error: Insufficient permission.");
        require(_token.transfer(msg.sender, _token.balanceOf(address(this))), "Transfer failed");
    }
    
    function set(uint256 _tag, uint256 _value) external {
        require(owner == msg.sender, "Error: Insufficient permission.");
        if (_tag == 0) max_pickaxe += _value;
        if (_tag == 1) max_axe += _value;
        if (_tag == 2) max_fishing_rod += _value;
        if (_tag == 3) fee_price = _value;
    }
    
    function setAddress(uint256 _tag, address _addr) external {
        require(owner == msg.sender, "Error: Insufficient permission.");
        if (_tag == 0) marketing = _addr;
        if (_tag == 1) fee = _addr;
    }
    
    fallback() external {
    }

    receive() payable external {
    }
    
}