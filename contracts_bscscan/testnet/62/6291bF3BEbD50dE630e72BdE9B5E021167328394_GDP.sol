/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// File: contracts/libs/goldpegas/Context.sol

pragma solidity 0.4.25;

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
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/libs/goldpegas/Auth.sol

pragma solidity 0.4.25;


contract Auth is Context {

  address internal mainAdmin;
  address internal backupAdmin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

  constructor(
    address _mainAdmin,
    address _backupAdmin
  ) internal {
    mainAdmin = _mainAdmin;
    backupAdmin = _backupAdmin;
  }

  modifier onlyMainAdmin() {
    require(isMainAdmin(), 'onlyMainAdmin');
    _;
  }

  modifier onlyBackupAdmin() {
    require(isBackupAdmin(), 'onlyBackupAdmin');
    _;
  }

  function transferOwnership(address _newOwner) onlyBackupAdmin internal {
    require(_newOwner != address(0x0));
    mainAdmin = _newOwner;
    emit OwnershipTransferred(_msgSender(), _newOwner);
  }

  function isMainAdmin() public view returns (bool) {
    return _msgSender() == mainAdmin;
  }

  function isBackupAdmin() public view returns (bool) {
    return _msgSender() == backupAdmin;
  }
}

// File: contracts/libs/goldpegas/StringUtil.sol

pragma solidity 0.4.25;

library StringUtil {
  struct slice {
    uint _length;
    uint _pointer;
  }

  function validateUserName(string memory _username)
  internal
  pure
  returns (bool)
  {
    uint8 len = uint8(bytes(_username).length);
    if ((len < 4) || (len > 18)) return false;

    // only contain A-Z 0-9
    for (uint8 i = 0; i < len; i++) {
      if (
        (uint8(bytes(_username)[i]) < 48) ||
        (uint8(bytes(_username)[i]) > 57 && uint8(bytes(_username)[i]) < 65) ||
        (uint8(bytes(_username)[i]) > 90)
      ) return false;
    }
    // First char != '0'
    return uint8(bytes(_username)[0]) != 48;
  }
}

// File: contracts/libs/zeppelin/math/SafeMath.sol

pragma solidity 0.4.25;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
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
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// File: contracts/libs/goldpegas/UnitConverter.sol

pragma solidity 0.4.25;


library UnitConverter {
  using SafeMath for uint256;

  function stringToBytes24(string memory source)
  internal
  pure
  returns (bytes24 result)
  {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly {
      result := mload(add(source, 24))
    }
  }
}

// File: contracts/libs/zeppelin/token/BEP20/IBEP20.sol

pragma solidity 0.4.25;

contract IBEP20 {
    function totalSupply() public view returns (uint256);
    function decimals() public view returns (uint8);
    function symbol() public view returns (string memory);
    function name() public view returns (string memory);
    function balanceOf(address account) public view returns (uint256);
    function transfer(address recipient, uint256 amount) public returns (bool);
    function allowance(address _owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 amount) public returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/libs/zeppelin/token/BEP20/IGDP.sol

pragma solidity 0.4.25;


contract IGDP is IBEP20 {
  function burn(uint _amount) external;
  function releaseFarmAllocation(address _farmerAddress, uint256 _amount) external;
}

// File: contracts/libs/zeppelin/token/BEP20/IUSDT.sol

pragma solidity 0.4.25;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
contract IUSDT {
    function transfer(address to, uint256 value) public;

    function approve(address spender, uint256 value) public;

    function transferFrom(address from, address to, uint256 value) public;

    function balanceOf(address who) public view returns (uint256);

    function allowance(address owner, address spender) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/GDP.sol

pragma solidity 0.4.25;






contract GDP is Auth {
  using StringUtil for string;
  using UnitConverter for string;

  mapping (bytes24 => address) private userNameAddresses;
  mapping (address => bool) userTracker;
  address[] private userAddresses;
  uint burnTokenRate = 100;
  IGDP gdpToken;
  IUSDT usdtToken = IUSDT(0xd5c05b3dBc0108f21EFD63e3D7656A3B726Ea8F7); //dev
  address withdrawContractAddress;
  address usdtAdmin;

  event Registered(address user, string userName, address inviter, uint timestamp);
  event USGTransferredToOther(address from, address to, string destination, uint value, uint timestamp);
  event USGTransferredToLive(address from, address to, string destination, uint value, uint timestamp);
  event USGWithdrew(address from, address to, string destination, uint value, uint timestamp);
  event Deposited(address from, address to, string destination, uint value, uint timestamp);
  event DepositedViaUSDT(address from, address to, uint value, uint timestamp);
  event UpRank(address from, address to, uint rank, uint timestamp);
  event Connect(address user, string userType, uint timestamp);

  constructor(
    address _mainAdmin,
    address _backupAdmin,
    address _withdrawContractAddress,
    address _admin,
    address _gdpToken
  )
  Auth(_mainAdmin, _backupAdmin)
  public
  {
    userTracker[msg.sender] = true;
    string memory rootUserName = 'GDP';
    bytes24 userNameAsKey = rootUserName.stringToBytes24();
    userNameAddresses[userNameAsKey] = msg.sender;
    emit Registered(msg.sender, rootUserName, address(0), now);

    withdrawContractAddress = _withdrawContractAddress;
    usdtAdmin = _admin;
    gdpToken = IGDP(_gdpToken);
  }

  function updateMainAdmin(address _admin) public {
    transferOwnership(_admin);
  }

  function updateBackupAdmin(address _backupAdmin) onlyBackupAdmin public {
    require(_backupAdmin != address(0x0), 'Invalid address');
    backupAdmin = _backupAdmin;
  }

  function updateWithdraw(address _withdrawContractAddress) onlyMainAdmin public {
    require(_withdrawContractAddress != address(0x0), 'Invalid address');
    withdrawContractAddress = _withdrawContractAddress;
  }

  function updateAdmin(address _admin) onlyMainAdmin public {
    require(_admin != address(0x0), 'Invalid address');
    usdtAdmin = _admin;
  }

  function updateBurnTokenRate(uint _rate) onlyMainAdmin public {
    require(_rate > 0 && _rate <= 100, 'Invalid rate');
    burnTokenRate = _rate;
  }

  function register(string _userName, address _inviter) public {
    require(_userName.validateUserName(), 'Invalid username');
    require(!userTracker[msg.sender], 'Registered already');
    require(msg.sender != _inviter, 'You can not refer your self');
    userTracker[msg.sender] = true;

    bytes24 userNameAsKey = _userName.stringToBytes24();
    require(userNameAddresses[userNameAsKey] == address(0x0), 'Username already exist');
    userNameAddresses[userNameAsKey] = msg.sender;

    emit Registered(msg.sender, _userName, _inviter, now);
  }

  function transferUSGToOther(address _receiver, string _destination, uint _amount) public {
    emit USGTransferredToOther(msg.sender, _receiver, _destination, _amount, now);
  }

  function transferUSGToLive(address _receiver, string _destination, uint _amount) public {
    emit USGTransferredToLive(msg.sender, _receiver, _destination, _amount, now);
  }

  function withdraw(address _from, string _destination, uint _amount) public {
    emit USGWithdrew(_from, msg.sender, _destination, _amount, now);
  }

  function upRank(address _to, uint _rank) public {
    require(_rank > 0 && _rank <= 19, 'Invalid rank');
    emit UpRank(msg.sender, _to, _rank, now);
  }

  function deposit(address _to, string _destination, uint _amount) public {
    require(gdpToken.allowance(msg.sender, address(this)) >= _amount, 'Please call approve() first');
    require(gdpToken.balanceOf(msg.sender) >= _amount, 'You have not enough token');
    require(gdpToken.transferFrom(msg.sender, address(this), _amount), 'Transfer token failed');
    gdpToken.burn(_amount / 100 * burnTokenRate);
    if (burnTokenRate < 100) {
      gdpToken.transfer(withdrawContractAddress, _amount / 100 * (100 - burnTokenRate));
    }

    emit Deposited(msg.sender, _to, _destination, _amount, now);
  }

  function depositViaUSDT(address _to, uint _amount) public {
    require(usdtToken.allowance(msg.sender, address(this)) >= _amount, 'Please call approve() first');
    require(usdtToken.balanceOf(msg.sender) >= _amount, 'You have not enough token');
    usdtToken.transferFrom(msg.sender, usdtAdmin, _amount);

    emit DepositedViaUSDT(msg.sender, _to, _amount, now);
  }

  function getUserAddressFromUserName(string _userName) public view returns (address) {
    require(_userName.validateUserName(), 'Invalid username');
    bytes24 _userNameAsKey = _userName.stringToBytes24();
    return userNameAddresses[_userNameAsKey];
  }

  function connect(string _type) public {
    emit Connect(msg.sender, _type, now);
  }
}