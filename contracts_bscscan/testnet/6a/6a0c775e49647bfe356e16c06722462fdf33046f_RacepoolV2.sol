// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./IRacepool.sol";

/**
 * Revert code and message pairs:
 * `Err01` Unathorized: caller is not the admin
 * `Err02` Unathorized: caller is not the creator
 * `Err03` Room not found
 * `Err04` Action not allowed
 * `Err05` Invalid entrance fee
 * `Err06` Invalid participant count
 * `Err07` Invalid winner count
 * `Err08` Participants is not empty
 * `Err09` Joined participants gte count
 * `Err10` Invalid address
 * `Err11(1)` Invalid main rewards length
 * `Err11(2)` Invalid secondary rewards length
 * `Err12` Invalid rewards amount
 * `Err13` Invalid rewards balance
 * `Err14` Invalid claimers length
 * `Err15` Duplicate entry
 * `Err16` Invalid claimers
 * `Err17` Unable to claim
 * `Err18` Already join
 */
contract RacepoolV2 is Initializable, OwnableUpgradeable, IRacepool {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  bytes public version;
  address public erc20Addr_1;
  address public erc20Addr_2;
  address public admin;
  string public name;
  string public symbol;
  uint256 public tax;
  uint256 private activeRoom;
  bool[] private index;

  mapping(uint256 => pool) private room;

  // balance[roomId][addressParticipant] = [erc20Addr_1 reward, erc20Addr_2 reward] ;
  mapping(uint256 => mapping(address => uint256[2])) private balances;

  modifier onlyAdmin() {
    require((owner() == msg.sender) || (admin == msg.sender), "Err01");
    _;
  }

  modifier onlyCreator(uint256 id) {
    require(
      (owner() == msg.sender) ||
        (admin == msg.sender) ||
        (room[id].creator == msg.sender),
      "Err02"
    );
    _;
  }

  modifier onlyExistRoom(uint256 id) {
    require(room[id].id != 0, "Err03");
    _;
  }

  modifier onlyStatus(state status, uint256 id) {
    require(room[id].status == status, "Err04");
    _;
  }

  function initialize(
    address erc20Address_1,
    address erc20Address_2,
    string memory contractName,
    string memory contractSymbol,
    address contractAdmin,
    uint256 contractTax
  ) public initializer {
    __Racepool_init(
      erc20Address_1,
      erc20Address_2,
      contractName,
      contractSymbol,
      contractAdmin,
      contractTax
    );
  }

  function __Racepool_init(
    address erc20Address_1,
    address erc20Address_2,
    string memory contractName,
    string memory contractSymbol,
    address contractAdmin,
    uint256 contractTax
  ) internal onlyInitializing {
    __Ownable_init();
    __Racepool_init_unchained(
      erc20Address_1,
      erc20Address_2,
      contractName,
      contractSymbol,
      contractAdmin,
      contractTax
    );
  }

  function __Racepool_init_unchained(
    address erc20Address_1,
    address erc20Address_2,
    string memory contractName,
    string memory contractSymbol,
    address contractAdmin,
    uint256 contractTax
  ) internal onlyInitializing {
    version = "1.1.2";
    name = contractName;
    symbol = contractSymbol;
    admin = contractAdmin;
    tax = contractTax;
    erc20Addr_1 = erc20Address_1;
    erc20Addr_2 = erc20Address_2;
  }

  function setVersion(string memory _version) external onlyOwner {
    version = bytes(_version);
  }

  function setContract(address erc20Addr, address newErc20Addr)
    external
    onlyOwner
  {
    if (erc20Addr_1 == erc20Addr) {
      erc20Addr_1 = newErc20Addr;
    } else if (erc20Addr_2 == erc20Addr) {
      erc20Addr_2 = newErc20Addr;
    }

    emit Contract(true);
  }

  function setAdmin(address walletAddress) external onlyOwner {
    admin = walletAddress;

    emit Admin(admin);
  }

  function setTax(uint256 contractTax) external onlyOwner {
    tax = contractTax;

    emit Tax(tax);
  }

  function createRoom(
    address creator,
    // note: pay with IERC20Upgradeable(erc20Addr_1) token
    // a.k.a a bail fee, this is alternative way to set a total reward instead of suming a joining fees
    uint256 lockingFee,
    uint256 startDate,
    uint8 participantCount,
    uint8 winnerCount,
    uint256 creatorTax
  ) external {
    require(lockingFee > 0, "Err05");
    require(participantCount > 0, "Err06");
    require(winnerCount > 0, "Err07");

    uint256 newId = index.length + 1;
    pool storage newRoom = room[newId];

    newRoom.id = newId;
    newRoom.creator = creator;
    newRoom.lockingFee = lockingFee;
    newRoom.startDate = startDate;
    newRoom.participantCount = participantCount;
    newRoom.winnerCount = winnerCount;
    newRoom.creatorTax = creatorTax;
    newRoom.contractTax = tax;
    newRoom.status = state.OPEN;

    index.push(true);
    activeRoom += 1;

    IERC20Upgradeable(erc20Addr_1).safeTransferFrom(
      newRoom.creator,
      address(this),
      newRoom.lockingFee
    );

    emit CreateRoom(newRoom.id);
  }

  function getRoom(uint256 id) external view returns (pool memory) {
    return room[id];
  }

  function getRooms(uint256 startedBefore)
    external
    view
    returns (uint256[] memory)
  {
    uint256[] memory roomIds = new uint256[](activeRoom);
    uint256 pointer = 0;

    for (uint256 i = 0; i < index.length; i++) {
      if (index[i] && (room[i].startDate >= startedBefore)) {
        roomIds[pointer] = room[i + 1].id;
        pointer += 1;
      }
    }
    return roomIds;
  }

  function destroyRoom(uint256 id)
    external
    onlyCreator(id)
    onlyExistRoom(id)
    onlyStatus(state.OPEN, id)
  {
    index[id - 1] = false;
    room[id].status = state.DESTROY;
    activeRoom -= 1;

    for (uint8 i = 0; i < room[id].participants.length; i++) {
      IERC20Upgradeable(erc20Addr_1).safeTransfer(
        room[id].participants[i],
        room[id].lockingFee / room[id].participantCount
      );
    }

    IERC20Upgradeable(erc20Addr_1).safeTransfer(
      room[id].creator,
      room[id].lockingFee
    );

    emit DestroyRoom(uint8(room[id].status));
  }

  function setLockingFee(uint256 id, uint256 balance)
    external
    onlyCreator(id)
    onlyExistRoom(id)
    onlyStatus(state.OPEN, id)
  {
    require(balance > 0, "Err05");
    require(room[id].participants.length == 0, "Err08");

    if (balance > room[id].lockingFee) {
      IERC20Upgradeable(erc20Addr_1).safeTransferFrom(
        room[id].creator,
        address(this),
        balance.sub(room[id].lockingFee)
      );
    } else if (balance < room[id].lockingFee) {
      IERC20Upgradeable(erc20Addr_1).safeTransfer(
        room[id].creator,
        room[id].lockingFee.sub(balance)
      );
    }

    room[id].lockingFee = balance;

    emit LockingFee(room[id].lockingFee);
  }

  function setStartDate(uint256 id, uint256 timestamp)
    external
    onlyCreator(id)
    onlyExistRoom(id)
    onlyStatus(state.OPEN, id)
  {
    // ! Make sure requester do validate:
    // ! new start date (unix timestamp) greater than or equal than current date (timestamp)
    room[id].startDate = timestamp;

    emit StartDate(room[id].startDate);
  }

  function setParticipantCount(uint256 id, uint8 count)
    external
    onlyCreator(id)
    onlyExistRoom(id)
    onlyStatus(state.OPEN, id)
  {
    require(count > 0, "Err06");
    require(room[id].participants.length == 0, "Err08");

    room[id].participantCount = count;

    emit ParticipantCount(room[id].participantCount);
  }

  function joinRoom(uint256 id)
    external
    onlyExistRoom(id)
    onlyStatus(state.OPEN, id)
  {
    for (uint8 i = 0; i < room[id].participants.length; i++) {
      if (room[id].participants[i] == msg.sender) {
        revert("Err18");
      }
    }

    room[id].participants.push(msg.sender);
    IERC20Upgradeable(erc20Addr_1).safeTransferFrom(
      msg.sender,
      address(this),
      room[id].lockingFee / room[id].participantCount
    );

    // auto lock room when last participants join
    if (room[id].participants.length == room[id].participantCount) {
      room[id].status = state.READY;
    }

    emit JoinRoom(room[id].participants);
  }

  function leaveRoom(uint256 id)
    external
    onlyExistRoom(id)
    onlyStatus(state.OPEN, id)
    returns (bool left)
  {
    bool success = false;
    for (uint8 i = 0; i < room[id].participants.length; i++) {
      if (room[id].participants[i] == msg.sender) {
        room[id].participants[i] = room[id].participants[
          room[id].participants.length - 1
        ];
        room[id].participants.pop();
        success = true;
        break;
      }
    }

    if (success) {
      IERC20Upgradeable(erc20Addr_1).safeTransfer(
        msg.sender,
        room[id].lockingFee / room[id].participantCount
      );
    }

    emit LeaveRoom(room[id].participants);
    return success;
  }

  function kickParticipant(uint256 id, address user)
    external
    onlyCreator(id)
    onlyExistRoom(id)
    onlyStatus(state.OPEN, id)
    returns (bool left)
  {
    require(user != address(0), "Err10");

    bool success = false;
    for (uint8 i = 0; i < room[id].participants.length; i++) {
      if (room[id].participants[i] == user) {
        room[id].participants[i] = room[id].participants[
          room[id].participants.length - 1
        ];
        room[id].participants.pop();
        success = true;
        break;
      }
    }

    if (success) {
      IERC20Upgradeable(erc20Addr_1).safeTransfer(
        user,
        room[id].lockingFee / room[id].participantCount
      );
    }

    emit KickParticipant(room[id].participants);
    return success;
  }

  function setWinnerCount(uint256 id, uint8 count)
    external
    onlyCreator(id)
    onlyExistRoom(id)
    onlyStatus(state.OPEN, id)
  {
    require(count > 0, "Err07");

    room[id].winnerCount = count;

    emit WinnerCount(room[id].winnerCount);
  }

  function finish(uint256 id)
    external
    onlyAdmin
    onlyExistRoom(id)
    onlyStatus(state.READY, id)
  {
    room[id].status = state.FULLFILL;
    emit Finish(uint8(room[id].status));
  }

  function setClaimers(
    uint256 id,
    address[] memory claimers,
    uint256[] memory rewards_1,
    uint256[] memory rewards_2
  ) external onlyAdmin onlyExistRoom(id) onlyStatus(state.FULLFILL, id) {
    require(claimers.length <= room[id].participantCount, "Err14");

    balances[id][admin][0] = 0;
    balances[id][room[id].creator][1] = 0;

    // address[] memory winners = new address[](claimers.length);

    for (uint8 i = 0; i < claimers.length; i++) {
      require(claimers[i] != address(0), "Err07");

      if (claimers[i] == room[id].creator) {
        balances[id][claimers[i]][0] += room[id].lockingFee;
      }

      balances[id][claimers[i]][0] += rewards_1[i];
      balances[id][claimers[i]][1] += rewards_2[i];
    }

    emit Claimers(true);
  }

  function getClaimers(uint256 id, address user) external view returns (uint256[2] memory rewards) {
    return balances[id][user];
  }

  function claimReward(uint256 id)
    external
    onlyExistRoom(id)
    onlyStatus(state.FULLFILL, id)
  {
    emit ClaimRewards(msg.sender, balances[id][msg.sender]);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

/**
 * Revert code and message pairs:
 * `Err01` Unathorized: caller is not the admin
 * `Err02` Unathorized: caller is not the creator
 * `Err03` Room not found
 * `Err04` Action not allowed
 * `Err05` Invalid entrance fee
 * `Err06` Invalid participant count
 * `Err07` Invalid winner count
 * `Err08` Participants is not empty
 * `Err09` Joined participants gte count
 * `Err10` Invalid address
 * `Err11` Invalid ratios length
 * `Err12` Invalid rewards ratio
 * `Err13` Invalid rewards balance
 * `Err14` Invalid claimers length
 * `Err15` Duplicate entry
 * `Err16` Invalid claimers
 * `Err17` Unable to claim
 * `Err18` Already join
 */
interface IRacepool {
  enum state {
    DESTROY,
    OPEN,
    READY,
    FULLFILL
  }

  struct pool {
    uint256 id;
    address creator;
    uint256 lockingFee;
    uint256 creatorTax;
    uint256 contractTax;
    uint256 startDate;
    uint8 participantCount;
    address[] participants;
    uint8 winnerCount;
    state status;
  }

  function setVersion(string memory _version) external;

  function setContract(address erc20Addr, address newErc20Addr) external;

  function setAdmin(address walletAddress) external;

  function setTax(uint256 contractTax) external;

  function createRoom(
    address creator,
    uint256 lockingFee,
    uint256 startDate,
    uint8 participantCount,
    uint8 winnerCount,
    uint256 creatorTax
  ) external;

  function getRoom(uint256 id) external view returns (pool memory);

  function getRooms(uint256 startedBefore)
    external
    view
    returns (uint256[] memory);

  function destroyRoom(uint256 id) external;

  function setLockingFee(uint256 id, uint256 balance) external;

  function setStartDate(uint256 id, uint256 timestamp) external;

  function setParticipantCount(uint256 id, uint8 count) external;

  function joinRoom(uint256 id) external;

  function leaveRoom(uint256 id) external returns (bool left);

  function kickParticipant(uint256 id, address user)
    external
    returns (bool left);

  function setWinnerCount(uint256 id, uint8 count) external;

  function finish(uint256 id) external;

  function setClaimers(
    uint256 id,
    address[] memory claimers,
    uint256[] memory rewards_1,
    uint256[] memory rewards_2
  ) external;

  function getClaimers(uint256 id, address user)
    external
    returns (uint256[2] memory rewards);

  function claimReward(uint256 id) external;

  event Contract(bool changed);

  event Admin(address admin);

  event Tax(uint256 tax);

  event CreateRoom(uint256 roomId);

  event DestroyRoom(uint8 status);

  event LockingFee(uint256 lockingFee);

  event StartDate(uint256 startDate);

  event ParticipantCount(uint256 participantCount);

  event JoinRoom(address[] participants);

  event LeaveRoom(address[] participants);

  event KickParticipant(address[] participants);

  event WinnerCount(uint256 winnerCount);

  event Finish(uint8 status);

  event Claimers(bool success);

  event ClaimRewards(address user, uint256[2] rewards);
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
library SafeMathUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}