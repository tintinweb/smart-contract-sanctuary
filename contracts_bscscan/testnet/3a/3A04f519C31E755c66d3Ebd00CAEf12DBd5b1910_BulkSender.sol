// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IBulkSender {
  event LogCoinBulkSentSome(address[] addresses, uint256 value);
  event LogCoinBulkSentDifferent(address[] addresses, uint256[] values);
  event LogGetCoin(address receiver, uint256 balance);

  event LogTokenBulkSentSome(address token, address[] addresses, uint256 value);
  event LogTokenBulkSentDifferent(
    address token,
    address[] addresses,
    uint256[] values
  );
  event LogGetToken(address token, address receiver, uint256 balance);

  /*
   *  withdrawal balance by Owner
   */
  function withdrawalCoinFee() external;

  /*
   *  Register VIP
   */
  function registerVIP() external payable;

  /*
   * set vip fee by Owner
   */
  function setVIPFee(uint256 _fee) external;

  /*
   * set tx fee by Owner
   */
  function setTxFee(uint256 _fee) external;

  /*
   * add bulk address to VIP List by Owner
   */
  function addToVIPList(address[] memory _VIPList) external;

  /*
   * Remove address from VIP List by Owner
   */
  function removeFromVIPList(address[] memory _VIPList) external;

  /*
   * Check isVIP
   */
  function checkVIP(address _addr) external view returns (bool);

  /*
   * get receiver address
   */
  function getReceiverAddress() external view returns (address);

  /*
   * set receiver address
   */
  function setReceiverAddress(address _addr) external;

  /*
   * Send coin with the same value by a explicit call method
   */
  function coinSendSameValue(address[] memory _to, uint256 _value)
    external
    payable;

  /*
   * Send coin with the different value by a explicit call method
   */
  function coinSendDifferentValue(
    address[] memory _to,
    uint256[] memory _values
  ) external payable;

  /*
   * Send token with the same value by a explicit call method
   */
  function tokenSendSameValue(
    IERC20 _token,
    address[] memory _to,
    uint256 _value
  ) external payable;

  /*
   * Send token with the different value by a explicit call method
   */
  function tokenSendDifferentValue(
    IERC20 _token,
    address[] memory _to,
    uint256[] memory _values
  ) external payable;
}

contract BulkSender is IBulkSender, Ownable {
  using SafeMath for uint256;

  address private receiverAddress;
  uint256 public txFee = 0.5 ether;
  uint256 public VIPFee = 1 ether;

  /* VIP List */
  mapping(address => bool) private VIPList;

  constructor() Ownable() {
    receiverAddress = owner();
  }

  function balanceContract() public view onlyOwner returns (uint256) {
    return address(this).balance;
  }

  /*
   *  withdrawal balance by Owner
   */
  function withdrawalCoinFee() public virtual override onlyOwner {
    uint256 balance = address(this).balance;
    require(balance != 0, "Currently no balance");

    address receiver = getReceiverAddress();

    (bool success, ) = receiver.call{ value: balance }("");
    require(success, "Withdrawal coin failed");
    emit LogGetCoin(receiverAddress, balance);
  }

  /*
   * get fee
   */
  function _getFeeForTransfer() internal view returns (uint256) {
    bool isVip = checkVIP(msg.sender);
    if (isVip) {
      return 0;
    }

    return txFee;
  }

  /*
   *  Register VIP
   */
  function registerVIP() public payable virtual override {
    require(msg.value >= VIPFee, "VIPFee Invalid");
    VIPList[msg.sender] = true;
  }

  /*
   * set vip fee by Owner
   */
  function setVIPFee(uint256 _fee) public virtual override onlyOwner {
    require(VIPFee != _fee, "Input value same as current");
    VIPFee = _fee;
  }

  /*
   * set tx fee by Owner
   */
  function setTxFee(uint256 _fee) public virtual override onlyOwner {
    require(txFee != _fee, "Input value same as current");
    txFee = _fee;
  }

  /*
   * add bulk address to VIP List by Owner
   */
  function addToVIPList(address[] memory _VIPList)
    public
    virtual
    override
    onlyOwner
  {
    for (uint256 i = 0; i < _VIPList.length; i++) {
      VIPList[_VIPList[i]] = true;
    }
  }

  /*
   * Remove address from VIP List by Owner
   */
  function removeFromVIPList(address[] memory _VIPList)
    public
    virtual
    override
    onlyOwner
  {
    for (uint256 i = 0; i < _VIPList.length; i++) {
      VIPList[_VIPList[i]] = false;
    }
  }

  /*
   * Check isVIP
   */
  function checkVIP(address _addr) public view virtual override returns (bool) {
    return _addr == owner() || VIPList[_addr];
  }

  /*
   * get receiver address
   */
  function getReceiverAddress()
    public
    view
    virtual
    override
    onlyOwner
    returns (address)
  {
    return receiverAddress == address(0) ? owner() : receiverAddress;
  }

  /*
   * set receiver address
   */
  function setReceiverAddress(address _addr) public virtual override onlyOwner {
    require(_addr != address(0), "Input address is same as current");
    receiverAddress = _addr;
  }

  /*
   * Send coin with the same value by a explicit call method
   */
  function coinSendSameValue(address[] memory _to, uint256 _value)
    public
    payable
    virtual
    override
  {
    uint256 sendAmount = _to.length.mul(_value);
    uint256 feeAmount = _getFeeForTransfer();
    require(msg.value >= feeAmount, "TxFee Invalid");
    require(msg.value - feeAmount >= sendAmount, "Amount Invalid");

    for (uint256 i = 0; i < _to.length; i++) {
      (bool success, ) = _to[i].call{ value: _value }("");
      require(success, "Amount invalid or something wrong");
    }

    emit LogCoinBulkSentSome(_to, sendAmount);
  }

  /*
   * Send coin with the different value by a explicit call method
   */
  function coinSendDifferentValue(
    address[] memory _to,
    uint256[] memory _values
  ) public payable virtual override {
    uint256 remainingValue = msg.value;
    uint256 feeAmount = _getFeeForTransfer();

    require(_to.length == _values.length, "Wrong input");

    for (uint256 i = 0; i < _to.length; i++) {
      remainingValue = remainingValue.sub(_values[i]);
      (bool success, ) = _to[i].call{ value: _values[i] }("");
      require(success, "Amount invalid or something wrong");
    }

    require(remainingValue >= feeAmount, "TxFee Invalid");

    emit LogCoinBulkSentDifferent(_to, _values);
  }

  /*
   * Send token with the same value by a explicit call method
   */
  function tokenSendSameValue(
    IERC20 _token,
    address[] memory _to,
    uint256 _value
  ) public payable virtual override {
    uint256 sendAmount = _to.length.mul(_value);
    uint256 feeAmount = _getFeeForTransfer();

    require(msg.value >= feeAmount, "TxFee Invalid");
    require(
      _token.allowance(msg.sender, address(this)) >= sendAmount &&
        _token.balanceOf(msg.sender) >= sendAmount,
      "Token approval is not enough"
    );

    for (uint256 i = 0; i < _to.length; i++) {
      _token.transferFrom(msg.sender, _to[i], _value);
    }

    emit LogTokenBulkSentSome(address(_token), _to, sendAmount);
  }

  /*
   * Send token with the different value by a explicit call method
   */
  function tokenSendDifferentValue(
    IERC20 _token,
    address[] memory _to,
    uint256[] memory _values
  ) public payable virtual override {
    uint256 feeAmount = _getFeeForTransfer();

    require(_to.length == _values.length, "Wrong input");
    require(msg.value >= feeAmount, "TxFee Invalid");

    for (uint256 i = 0; i < _to.length; i++) {
      require(
        _token.allowance(msg.sender, address(this)) >= _values[i] &&
          _token.balanceOf(msg.sender) >= _values[i],
        "Token approval is not enough"
      );
      _token.transferFrom(msg.sender, _to[i], _values[i]);
    }

    emit LogTokenBulkSentDifferent(address(_token), _to, _values);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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