/**
 *Submitted for verification at polygonscan.com on 2021-11-05
*/

pragma solidity 0.5.17;

contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

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

interface Energy8Token {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IEnergy8Router {
  event Deposit(uint32 serverId, string username, address indexed sender, uint256 value);
  event Withdraw(uint32 serverId, string username, address indexed recipient, uint256 value);
}

contract Energy8Router is IEnergy8Router, Ownable {
  using SafeMath for uint256;

  struct Server {
    string name;
    string link;
    address adminAddress;
    uint8 depositFeeAdmin;
    uint8 depositBurn;
    uint8 depositFee;
    uint8 withdrawFeeAdmin;
    uint8 withdrawBurn;
    uint8 withdrawFee;
    mapping (string => address) players;
    bool isActive;
  }
  
  mapping (uint32 => Server) public _servers;
  
  uint32 public serversNumber = 0;

  Energy8Token private token = Energy8Token(0x185CB6fA1F2B03Ef38ADC61dab86a20282035592);
  
  address public deadAddress = 0x000000000000000000000000000000000000dEaD;
  
  function depositToServer(uint32 serverId, string calldata nickname, uint256 amount) external returns (bool) {
    _depositToServer(serverId, nickname, amount);
    return true;
  }
  
  function withdrawFromServer(uint32 serverId, address recipient, string calldata nickname, uint256 amount) external onlyOwner returns (bool) {
    _withdrawFromServer(serverId, recipient, nickname, amount);
    return true;
  }
  
  function addServer(string calldata name, string calldata link, address adminAddress) external onlyOwner returns (bool) {
    _servers[serversNumber] = Server(name, link, adminAddress, 0, 0, 0, 0, 0, 0, true);

    serversNumber += 1;
    
    return true;
  }
  
  function updateServerDepositFees(uint32 serverId, uint8 depositFeeAdmin, uint8 depositBurn, uint8 depositFee) external onlyOwner returns (bool) {
    require(depositFeeAdmin >= 0 && depositFeeAdmin <= 1000);
    require(depositBurn >= 0 && depositBurn <= 1000);
    require(depositFee >= 0 && depositFee <= 1000);

    Server storage server = _getServer(serverId);
    
    server.depositFeeAdmin = depositFeeAdmin;
    server.depositBurn = depositBurn;
    server.depositFee = depositFee;
    
    return true;
  }
  
  function updateServerWithdrawFees(uint32 serverId, uint8 withdrawFeeAdmin, uint8 withdrawBurn, uint8 withdrawFee) external onlyOwner returns (bool) {
    require(withdrawFeeAdmin >= 0 && withdrawFeeAdmin <= 1000);
    require(withdrawBurn >= 0 && withdrawBurn <= 1000);
    require(withdrawFee >= 0 && withdrawFee <= 1000);

    Server storage server = _getServer(serverId);
    
    server.withdrawFeeAdmin = withdrawFeeAdmin;
    server.withdrawBurn = withdrawBurn;
    server.withdrawFee = withdrawFee;
    
    return true;
  }
  
  function updateServerAdmin(uint32 serverId, address adminAddress) external onlyOwner returns (bool) {
    Server storage server = _getServer(serverId);
    
    server.adminAddress = adminAddress;
    
    return true;
  }
  
  function updateServerInfo(uint32 serverId, string calldata name, string calldata link) external onlyOwner returns (bool) {
    Server storage server = _getServer(serverId);
    
    server.name = name;
    server.link = link;
    
    return true;
  }
  
  function activateServer(uint32 serverId) external onlyOwner returns (bool) {
    _setActiveStatus(serverId, true);
    
    return true;
  }
  
  function deactivateServer(uint32 serverId) external onlyOwner returns (bool) {
    _setActiveStatus(serverId, false);
    
    return true;
  }
  
  function updateServerPlayerAddress(uint32 serverId, string calldata nickname, address nicknameOwner) external onlyOwner returns (bool) {
      Server storage server = _getServer(serverId);
      
      server.players[nickname] = nicknameOwner;

      return true;
  }
  
  function removeNicknameFromServer(uint32 serverId, string calldata nickname) external onlyOwner returns (bool) {
      Server storage server = _getServer(serverId);
      
      server.players[nickname] = address(0);

      return true;
  }
  
  function withdrawTokensFromRouter(address wallet, uint256 amount) external onlyOwner {
    token.transfer(wallet, amount);
  }
  
  function _setActiveStatus(uint32 serverId, bool isActive) internal {
    Server storage server = _servers[serverId];
    
    server.isActive = isActive;
  }
  
  function _depositToServer(uint32 serverId, string memory nickname, uint256 amount) internal {
    require(amount > 0);

    Server storage server = _getServer(serverId);
    
    uint256 adminFeeAmount = _getPercentage(amount, server.depositFeeAdmin);
    uint256 burnAmount = _getPercentage(amount, server.depositBurn);
    uint256 feeAmount = _getPercentage(amount, server.depositFee);
    
    uint256 depositAmount = amount.sub(adminFeeAmount).sub(burnAmount).sub(feeAmount);
    
    require(token.transferFrom(msg.sender, address(this), depositAmount));

    if (burnAmount != uint256(0)) {
        require(token.transfer(deadAddress, burnAmount));
    }
    
    if (adminFeeAmount != uint256(0)) {
        require(token.transfer(server.adminAddress, adminFeeAmount));
    }
    
    address nicknameOwner = server.players[nickname];
    
    if (nicknameOwner == address(0)) {
        // associating the address with the nickname
        server.players[nickname] = msg.sender;
    } else {
        require(server.players[nickname] == msg.sender, "You are not authorized to deposit this account");
    }
      
    emit Deposit(serverId, nickname, msg.sender, depositAmount);
  }
  
  function _withdrawFromServer(uint32 serverId, address recipient, string memory nickname, uint256 amount) internal {
    require(amount > 0);

    Server storage server = _getServer(serverId);

    require(server.players[nickname] == recipient, "You are not authorized to withdraw from this account");
    
    uint256 adminFeeAmount = _getPercentage(amount, server.withdrawFeeAdmin);
    uint256 burnAmount = _getPercentage(amount, server.withdrawBurn);
    uint256 feeAmount = _getPercentage(amount, server.withdrawFee);
    
    uint256 withdrawAmount = amount.sub(adminFeeAmount).sub(burnAmount).sub(feeAmount);
    
    require(token.transfer(recipient, withdrawAmount));
    
    if (burnAmount != uint256(0)) {
        require(token.transfer(deadAddress, burnAmount));
    }
    
    if (adminFeeAmount != uint256(0)) {
        require(token.transfer(server.adminAddress, adminFeeAmount));
    }
      
    emit Withdraw(serverId, nickname, recipient, withdrawAmount);
  }

  function _getServer(uint32 serverId) internal view returns (Server storage) {
    Server storage server = _servers[serverId];
      
    require(server.isActive == true, "Server not found or inactive");
      
    return server;
  }
  
  function _getPercentage(uint256 number, uint8 percent) internal pure returns (uint256) {
    return number.mul(percent).div(1000);
  }
}