/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

//"SPDX-License-Identifier: UNLICENSED"

pragma solidity ^0.6.6;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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

contract Multiplier{
    //instantiating SafeMath library
    using SafeMath for uint;
    
    //instance of utility token
    IERC20 private _token;
    
    //struct
    struct User {
        uint balance;
        uint release;
        address approved;
    }
    
    //address to User mapping
    mapping(address => User) private _users;
    
    //multiplier constance for multiplying rewards
    uint private constant _MULTIPLIER_CEILING = 2;
    
    //events
    event Deposited(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount, uint time);
    event NewLockup(address indexed poolstake, address indexed user, uint lockup);
    event ContractApproved(address indexed user, address contractAddress);
    
    /* 
     * @dev instantiate the multiplier.
     * --------------------------------
     * @param token--> the token that will be locked up.
     */    
    constructor(address token) public {
        require(token != address(0), "token must not be the zero address");
        _token = IERC20(token);
    }

    /* 
     * @dev top up the available balance.
     * --------------------------------
     * @param _amount --> the amount to lock up.
     * -------------------------------
     * returns whether successfully topped up or not.
     */  
    function deposit(uint _amount) external returns(bool) {
        
        require(_amount > 0, "amount must be larger than zero");
        
        require(_token.transferFrom(msg.sender, address(this), _amount), "amount must be approved");
        _users[msg.sender].balance = balance(msg.sender).add(_amount);
        
        emit Deposited(msg.sender, _amount);
        return true;
    }
    
    /* 
     * @dev approve a contract to use Multiplier
     * -------------------------------------------
     * @param _traditional --> the contract address to approve
     * -------------------------------------------------------
     * returns whether successfully approved or not
     */ 
    function approveContract(address _traditional) external returns(bool) {
        
        require(_users[msg.sender].approved != _traditional, "already approved");
        require(Address.isContract(_traditional), "can only approve a contract");
        
        _users[msg.sender].approved = _traditional;
        
        emit ContractApproved(msg.sender, _traditional);
        return true;
    } 
    
    /* 
     * @dev withdraw released multiplier balance.
     * ----------------------------------------
     * @param _amount --> the amount to be withdrawn.
     * -------------------------------------------
     * returns whether successfully withdrawn or not.
     */
    function withdraw(uint _amount) external returns(bool) {
        
        require(now >= _users[msg.sender].release, "must wait for release");
        require(_amount > 0, "amount must be larger than zero");
        require(balance(msg.sender) >= _amount, "must have a sufficient balance");
        
        _users[msg.sender].balance = balance(msg.sender).sub(_amount);
        require(_token.transfer(msg.sender, _amount), "token transfer failed");
        
        emit Withdrawn(msg.sender, _amount, now);
        return true;
    }
    
    /* 
     * @dev updates the lockup period (called by pool contract)
     * ----------------------------------------------------------
     * IMPORTANT - can only be used to increase lockup
     * -----------------------------------------------
     * @param _lockup --> the vesting period
     * -------------------------------------------
     * returns whether successfully withdrawn or not.
     */
    function updateLockupPeriod(address _user, uint _lockup) external returns(bool) {
        
        require(Address.isContract(msg.sender), "only a smart contract can call");
        require(_users[_user].approved == msg.sender, "contract is not approved");
        require(now.add(_lockup) > _users[_user].release, "cannot reduce current lockup");
        
        _users[_user].release = now.add(_lockup);
        
        emit NewLockup(msg.sender, _user, _lockup);
        return true;
    }
    
    /* 
     * @dev get the multiplier ceiling for percentage calculations.
     * ----------------------------------------------------------
     * returns the multiplication factor.
     */     
    function getMultiplierCeiling() external pure returns(uint) {
        
        return _MULTIPLIER_CEILING;
    }

    /* 
     * @dev get the multiplier user balance.
     * -----------------------------------
     * @param _user --> the address of the user.
     * ---------------------------------------
     * returns the multiplier balance.
     */ 
    function balance(address _user) public view returns(uint) {
        
        return _users[_user].balance;
    }
    
    /* 
     * @dev get the approved Traditional contract address
     * --------------------------------------------------
     * @param _user --> the address of the user
     * ----------------------------------------
     * returns the approved contract address
     */ 
    function approvedContract(address _user) external view returns(address) {
        
        return _users[_user].approved;
    }
    
    /* 
     * @dev get the release of the multiplier balance.
     * ---------------------------------------------
     * @param user --> the address of the user.
     * ---------------------------------------
     * returns the release timestamp.
     */     
    function lockupPeriod(address _user) external view returns(uint) {
        
        uint release = _users[_user].release;
        if (release > now) return (release.sub(now));
        else return 0;
    }
}