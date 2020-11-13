// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: @openzeppelin\contracts\math\SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: node_modules\@openzeppelin\contracts\GSN\Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\ownership\Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\TTTdefiFundV2.sol

pragma solidity 0.5.16;




contract TTTdefiFundV2 is Ownable {
  using SafeMath for uint;

  /*** STORAGE VARIABLES ***/

  /**
    * @notice Date time in seconds when timelock expires.
  */
  uint public expiration;

  /**
    * @notice Address permitted to withdraw funds after unlock.
  */
  address public beneficiary;

  /**
    * @notice Token look up table for front-end access.
  */
  address[] public tokenLUT;

  /**
    * @notice Checks whether a token exists in the fund.
  */
  mapping(address => bool) public tokens;

  /*** EVENTS ***/

  /**
    * @notice Emits when a deposit is made.
  */
  event Deposit(address indexed _from, uint _value, address indexed _token);

  /**
    * @notice Emits when a withdrawal is made.
  */
  event Withdraw(address indexed _to, uint _value, address indexed _token);

  /**
    * @notice Emits when the expiration is increased.
  */
  event IncreaseTime(uint _newExpiration);

  /**
    * @notice Emits when the beneficiary is updated.
  */
  event UpdateBeneficiary(address indexed _newBeneficiary);

  /*** MODIFIERS ***/

  /**
    * @dev Throws if the contract has not yet reached its expiration.
  */
  modifier isExpired() {
    require(expiration < block.timestamp, 'contract is still locked');
    _;
  }

  /**
    * @dev Throws if msg.sender is not the beneficiary.
  */
  modifier onlyBeneficiary() {
    require(msg.sender == beneficiary, 'only the beneficiary can perform this function');
    _;
  }

  /**
    * @param _expiration Date time in seconds when timelock expires.
    * @param _beneficiary Address permitted to withdraw funds after unlock.
    * @param _owner The contract owner.
  */
  constructor(uint _expiration, address _beneficiary, address _owner) public {
    expiration = _expiration;
    beneficiary = _beneficiary;
    transferOwnership(_owner);
  }

  /*** VIEW/PURE FUNCTIONS ***/

  /**
    * @dev Returns the length of the tokenLUT array.
  */
  function getTokenSize() public view returns(uint) {
    return tokenLUT.length;
  }

  /*** OTHER FUNCTIONS ***/

  /**
    * @dev Allows a user to deposit ETH or an ERC20 into the contract.
           If _token is 0 address, deposit ETH.
    * @param _amount The amount to deposit.
    * @param _token The token to deposit.
  */
  function deposit(uint _amount, address _token) public payable {
    if(_token == address(0)) {
      require(msg.value == _amount, 'incorrect amount');
      if(!tokens[_token]) {
        tokenLUT.push(_token);
        tokens[_token] = true;
      }
      emit Deposit(msg.sender, _amount, _token);
    }
    else {
      IERC20 token = IERC20(_token);
      require(token.transferFrom(msg.sender, address(this), _amount), 'transfer failed');
      if(!tokens[_token]) {
        tokenLUT.push(_token);
        tokens[_token] = true;
      }
      emit Deposit(msg.sender, _amount, _token);
    }
  }

  /**
    * @dev Withdraw funds to msg.sender, but only if the timelock is expired
           and msg.sender is the beneficiary.
           If _token is 0 address, withdraw ETH.
    * @param _amount The amount to withdraw.
    * @param _token The token to withdraw.
  */
  function withdraw(uint _amount, address _token) public isExpired() onlyBeneficiary() {
    if(_token == address(0)) {
      (bool success, ) = msg.sender.call.value(_amount)("");
      require(success, "Transfer failed.");
      emit Withdraw(msg.sender, _amount, _token);
    } else {
      IERC20 token = IERC20(_token);
      require(token.transfer(msg.sender, _amount), 'transfer failed');
      emit Withdraw(msg.sender, _amount, _token);
    }
  }

  /**
    * @dev Increase the time until expiration. Only the owner can perform this.
    * @param _newExpiration New date time in seconds when timelock expires.
  */
  function increaseTime(uint _newExpiration) public onlyOwner() {
    require(_newExpiration > expiration, 'can only increase expiration');
    expiration = _newExpiration;
    emit IncreaseTime(_newExpiration);
  }

  /**
    * @dev Update the beneficiary address. Only the owner can perform this.
    * @param _newBeneficiary New beneficiary address.
  */
  function updateBeneficiary(address _newBeneficiary) public onlyOwner() {
    require(_newBeneficiary != beneficiary, 'same beneficiary');
    require(_newBeneficiary != address(0), 'cannot set as burn address');
    beneficiary = _newBeneficiary;
    emit UpdateBeneficiary(_newBeneficiary);
  }
}

// File: contracts\TTTdefiFundFactoryV2.sol

pragma solidity 0.5.16;


contract TTTdefiFundFactoryV2 {
  /*** STORAGE VARIABLES ***/

  /**
    * @notice Maps unique IDs to funds.
  */
  mapping(uint => address) funds;

  /**
    * @notice Maps user address to their corresponding funds.
  */
  mapping(address => uint[]) userFunds;

  /**
    * @notice Get the next fund ID.
  */
  uint public nextId;

  /*** EVENTS ***/

  /**
    * @notice Emits when a fund is created.
  */
  event CreateFund(
    uint expiration,
    address indexed beneficiary,
    address indexed owner
  );

  /*** PURE/VIEW FUNCTIONS ***/

  /**
    * @dev Given an id, return the corresponding fund address.
    * @param _id The id of the fund.
  */
  function getFund(uint _id) public view returns(address) {
    return funds[_id];
  }

  /**
    * @dev Given a user address, return all owned funds.
    * @param _user The address of the user.
  */
  function getUserFunds(address _user) public view returns(uint[] memory) {
    return userFunds[_user];
  }

  /*** OTHER FUNCTIONS ***/

  /**
    * @dev Deploy a TTTdefiFund contract.
    * @param _expiration Date time in seconds when timelock expires.
    * @param _beneficiary Address permitted to withdraw funds after unlock.
  */
  function createFund(uint _expiration, address _beneficiary) public {
    require(funds[nextId] == address(0), 'id already in use');
    require(_beneficiary != address(0), 'beneficiary is burn address');
    TTTdefiFundV2 fund = new TTTdefiFundV2(_expiration, _beneficiary, msg.sender);
    funds[nextId] = address(fund);
    userFunds[msg.sender].push(nextId);
    nextId++;
    emit CreateFund(_expiration, _beneficiary, msg.sender);
  }
}