/**
 *Submitted for verification at BscScan.com on 2021-08-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

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

interface IWAVE {

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

  function mint(uint256 amount, address account) external returns (bool);
  function burnFrom(uint256 amount, address account) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IV1 {
  function isRegistered(address user) external view returns (bool);

  function getUserID(address user) external view returns (uint);

  function getUserWallet(uint userID) external view returns (address);

  function getReferrerID(uint userID) external view returns (uint);

  function getReferrer(address user) external view returns (address);

  function getUserLevel(uint userID) external view returns (uint8);

  function getUserInvited(uint userID) external view returns (uint);

  function getUserEarned(uint userID) external view returns (uint);

  function getUserMissed(uint userID) external view returns (uint);

  function getTotalUsers() external view returns (uint);
}

contract Roles is Context {
  address private _owner;
  uint private _registrars;

  mapping (address => bool) private _isRegistrar;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event RegistrarAdded(address indexed newRegistrar);
  event RegistrarRemoved(address indexed removedRegistrar);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
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
   * @dev Return True if address is a registrar.
   */
  function isRegistrar(address who) public view returns (bool) {
      return _isRegistrar[who];
  }

  /**
   * @dev Return total number of registrars.
   */
  function registrars() public view returns (uint) {
      return _registrars;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Roles: caller is not the owner");
    _;
  }

  /**
   * @dev Throws if called by any account other than the registrar.
   */
  modifier onlyRegistrar() {
      require(_isRegistrar[_msgSender()], "Roles: caller is not a registrar");
      _;
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
   * @dev Add a new account (`newRegistrar`) as a registrar.
   * Can only be called by the current owner.
   */
  function addRegistrar(address newRegistrar) public onlyOwner {
      require(newRegistrar != address(0), "Roles: new registrar is the zero address");
      emit RegistrarAdded(newRegistrar);
      _isRegistrar[newRegistrar] = true;
      _registrars += 1;
  }

  /**
   * @dev Remove a registrar (`registrar`).
   * Can only be called by the current owner.
   */
  function removeRegistrar(address registrar) public onlyOwner {
      require(_isRegistrar[registrar], "Roles: this address is not registrar");
      emit RegistrarRemoved(registrar);
      _isRegistrar[registrar] = false;
      _registrars -= 1;
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
    require(newOwner != address(0), "Roles: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract Membership is Roles {
  using SafeMath for uint256;

  struct User {
    address wallet;
    uint referrerID;
    uint8 level;
    uint invited;
  }

  IWAVE private wave;
  IV1 private v1;

  string private _name;
  uint8 private _maxLevel;
  uint256 private _totalUsers;
  uint256[] private _upgradeFees;

  mapping(address => uint) public IDs;
  mapping(uint => User) public users;

  event Registration(uint indexed id, address indexed wallet);
  event Upgrade(uint indexed id, address indexed wallet, uint8 level);

  constructor(address waveContract, address v1Contract) {
    wave = IWAVE(waveContract);
    v1 = IV1(v1Contract);

    _name = "Kanagawa V2";
    _maxLevel = uint8(10);
    _totalUsers = v1.getTotalUsers();
    _upgradeFees = [
      50000,
      180000,
      640000,
      2240000,
      7680000,
      25600000,
      51200000,
      102400000,
      204800000,
      307200000
    ];

  }

  function name() external view returns (string memory) {
    return _name;
  }

  function getOwner() public view returns (address) {
    return owner();
  }

  function getWave() public view returns (IWAVE) {
    return wave;
  }

  function getOld() public view returns (IV1) {
    return v1;
  }

  function getMaxLevel() public view returns (uint8) {
    return _maxLevel;
  }

  function getTotalUsers() public view returns (uint) {
    return _totalUsers;
  }

  function isRegistered(address user) public view returns (bool) {
    return (IDs[user] != 0 || v1.getUserID(user) != 0);
  }

  function notUpgradeToV2(address user) public view returns (bool) {
    return (IDs[user] == 0 && v1.getUserID(user) != 0);
  }

  function getUserID(address user) public view returns (uint) {
    return IDs[user];
  }

  function getUserLevel(uint userID) public view returns (uint8) {
    return v1.getUserLevel(userID) > users[userID].level ? v1.getUserLevel(userID) : (users[userID].level);
  }

  function getUpgradeFee(uint8 level) public view returns (uint) {
    if (level < _maxLevel) {
      return _upgradeFees[level];
    } else {
      return uint(0)-1;
    }
  }

  function getUserDetails(address user) public view returns (User memory) {
    return users[IDs[user]];
  }

  function getUserDetailsById(uint userId) public view returns (User memory) {
    return users[userId];
  }

  function setUpgradeFee(uint8 level, uint fee) external onlyOwner returns (bool) {
    _upgradeFees[level] = fee;
    return true;
  }

  function register(address user, address referrer) external onlyRegistrar returns (bool) {
    require(!isRegistered(user), "User is already registered.");
    require(isRegistered(referrer), "Referrer is invalid.");
    if ( notUpgradeToV2(referrer) ) {
      _register(referrer, v1.getReferrerID(v1.getUserID(referrer)), v1.getUserInvited(v1.getUserID(referrer)), v1.getUserLevel(v1.getUserID(referrer)), 0);
    }

    _register(user, IDs[referrer], 0, 0, 1);
    return true;
  }

  function upgrade() external returns (bool) {
    if ( !isRegistered(_msgSender()) ) {
      _register(_msgSender(), 1, 0, 0, 1);
    }

    if ( notUpgradeToV2(_msgSender()) ) {
      _register(_msgSender(), v1.getReferrerID(v1.getUserID(_msgSender())), v1.getUserInvited(v1.getUserID(_msgSender())), v1.getUserLevel(v1.getUserID(_msgSender())), 0);
    }

    uint fee = getUpgradeFee(getUserLevel(getUserID(_msgSender())));
    require(fee <= wave.balanceOf(_msgSender()), "Insufficient WAVE funds.");
    _upgrade(fee, _msgSender());
    return true;
  }

  function _register(address userAddress, uint referrerID, uint invited, uint8 level, uint newUser) internal {
    uint32 size;
    assembly {
      size := extcodesize(userAddress)
    }
    require(size == 0, "Cannot be a contract");

    User memory user = User({
        wallet: userAddress,
        referrerID: referrerID,
        level: level,
        invited: invited
    });

    _totalUsers = _totalUsers.add(newUser);
    users[_totalUsers] = user;
    IDs[userAddress] = _totalUsers;

    users[referrerID].invited = users[referrerID].invited.add(newUser);

    emit Registration(_totalUsers, userAddress);
  }

  function _upgrade(uint fee, address account) internal {
    wave.burnFrom(fee, account);
    users[getUserID(account)].level += 1;
    emit Upgrade(getUserID(account), account, users[getUserID(account)].level);
  }

}