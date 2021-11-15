pragma solidity ^0.7.0;

import "./lib/Address.sol";
import "./lib/Utils.sol";
import "./lib/SafeMath.sol";
import "./Types.sol";
import "./Settler.sol";
import "./Land.sol";

contract World is Context, ReentrancyGuard, Ownable {
  struct InSettler {
    address settler;
    uint ptr;
  }
  struct InLand {
    address land;
    uint ptr;
  }
  address[] public lands;
  mapping (address => InLand) public addrToLands;

  address[] public users;
  // user => settler
  mapping (address => InSettler) public settlers;

  enum State { INIT, PLAYABLE, END }
  State public state;

  modifier onlyInit() {
    require(state == State.INIT, "state is non-initable");
    _;
  }
  modifier onlyPlayable() {
    require(state == State.PLAYABLE, "state is non-playable");
    _;
  }

  function init() external onlyOwner {
    require(state == State.INIT, "state: already init");
    // init lands
    // TODO: implement me

    // king land
    //    initLand("King Land", 1, 0, 0,36e6, 36e6, 24e6, 24e6, 1e8);
    // duke land
    // initLand("Duke I", 2, 0, 0,36e6, 24e6, 30e6, 18e6, 1e7);
    // initLand("Duke II", 2, 0, 0,36e6, 24e6, 18e6, 30e6, 1e7);
    // earl land
    // initLand("Earl I", 3, 0, 0,24e6, 24e6, 12e6, 30e6, 1e7);
    // initLand("Earl II", 3, 0, 0,24e6, 24e6, 30e6, 12e6, 1e7);
    // initLand("Earl III", 3, 0, 0,24e6, 30e6, 18e6, 18e6, 1e7);
    // initLand("Earl IV", 3, 0, 0,36e6, 24e6, 12e6, 12e6, 1e7);
    // baron land group 1
    // initLand("Baron A-I", 4, 0, 0,30e6, 18e6, 12e6, 12e6, 1e6);
    // initLand("Baron A-II", 4, 0, 0,30e6, 18e6, 12e6, 12e6, 1e6);
    // initLand("Baron A-III", 4, 0, 0,30e6, 18e6, 12e6, 12e6, 1e6);
    // initLand("Baron A-IV", 4, 0, 0,30e6, 18e6, 12e6, 12e6, 1e6);
    // initLand("Baron A-V", 4, 0, 0,30e6, 18e6, 12e6, 12e6, 1e6);
    // initLand("Baron A-VI", 4, 0, 0,30e6, 18e6, 12e6, 12e6, 1e6);
    // baron land group 2
    // initLand("Baron B-I", 4, 0, 0,18e6, 30e6, 12e6, 12e6, 1e6);
    // initLand("Baron B-II", 4, 0, 0,18e6, 30e6, 12e6, 12e6, 1e6);
    // initLand("Baron B-III", 4, 0, 0,18e6, 30e6, 12e6, 12e6, 1e6);
    // initLand("Baron B-IV", 4, 0, 0,18e6, 30e6, 12e6, 12e6, 1e6);
    // initLand("Baron B-V", 4, 0, 0,18e6, 30e6, 12e6, 12e6, 1e6);
    // initLand("Baron B-VI", 4, 0, 0,18e6, 30e6, 12e6, 12e6, 1e6);
    // baron land group 3
    // initLand("Baron C-I", 4, 0, 0,24e6, 24e6, 12e6, 12e6, 1e6);
    // initLand("Baron C-II", 4, 0, 0,24e6, 24e6, 12e6, 12e6, 1e6);
    // initLand("Baron C-III", 4, 0, 0,24e6, 24e6, 12e6, 12e6, 1e6);
    // initLand("Baron C-IV", 4, 0, 0,24e6, 24e6, 12e6, 12e6, 1e6);
    // initLand("Baron C-V", 4, 0, 0,24e6, 24e6, 12e6, 12e6, 1e6);
    // initLand("Baron C-VI", 4, 0, 0,24e6, 24e6, 12e6, 12e6, 1e6);

    state = State.PLAYABLE;
  }

  function addLand(address addr) external onlyOwner onlyInit {
    lands.push(addr);
    addrToLands[addr].ptr = lands.length-1;
    addrToLands[addr].land = addr;
  }

//  function initLand(
//    string memory _name, uint256 _tier,
//    uint256 _x, uint256 _y,
//    uint256 _foodRate, uint256 _woodRate, uint256 _stoneRate, uint256 _ironRate,uint256 _barbarian
//  ) external onlyInit returns (Land _land) {
//    Land l = new Land(address(this));
//    l.init(_name, _tier, _x, _y, _foodRate, _woodRate, _stoneRate, _ironRate, _barbarian);
//    lands.push(address(l));
//    addrToLands[address(l)].ptr = lands.length-1;
//    addrToLands[address(l)].land = address(l);
//    return l;
//  }

  function initSettler() virtual external onlyPlayable returns (bool success) {
    address user = _msgSender();
    require(!isSettlerExist(user), "already exist");

    users.push(user);
    Settler s = new Settler(address(this), user, lands);
    settlers[user].ptr = users.length-1;
    settlers[user].settler = address(s);
    return true;
  }

  function isSettlerExist(address user) public view returns (bool exist) {
    if(users.length == 0) return false;
    return (users[settlers[user].ptr] == user);
  }

  // get settler from mapping
  function settler(address user) public virtual view returns (address _settler) {
    if (users.length == 0) return address(0);
    return settlers[user].settler;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call(data);
        return _verifyCallResult(success, returndata, errorMessage);
        // solhint-disable-next-line avoid-low-level-calls
        // return functionCallWithValue(target, data, 0, errorMessage);
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
    // function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
    //     return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    // }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    // function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    //     require(address(this).balance >= value, "Address: insufficient balance for call");
    //     require(isContract(target), "Address: call to non-contract");

    //     // solhint-disable-next-line avoid-low-level-calls
    //     (bool success, bytes memory returndata) = target.call{ value: value }(data);
    //     return _verifyCallResult(success, returndata, errorMessage);
    // }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    // function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    //     return functionStaticCall(target, data, "Address: low-level static call failed");
    // }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    // function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
    //     require(isContract(target), "Address: static call to non-contract");

    //     // solhint-disable-next-line avoid-low-level-calls
    //     (bool success, bytes memory returndata) = target.staticcall(data);
    //     return _verifyCallResult(success, returndata, errorMessage);
    // }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    // function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    //     return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    // }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    // function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    //     require(isContract(target), "Address: delegate call to non-contract");

    //     // solhint-disable-next-line avoid-low-level-calls
    //     (bool success, bytes memory returndata) = target.delegatecall(data);
    //     return _verifyCallResult(success, returndata, errorMessage);
    // }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.2 <0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    // function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    //     uint256 c = a + b;
    //     if (c < a) return (false, 0);
    //     return (true, c);
    // }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    // function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    //     if (b > a) return (false, 0);
    //     return (true, a - b);
    // }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    // function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    //     // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    //     // benefit is lost if 'b' is also tested.
    //     // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    //     if (a == 0) return (true, 0);
    //     uint256 c = a * b;
    //     if (c / a != b) return (false, 0);
    //     return (true, c);
    // }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    // function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    //     if (b == 0) return (false, 0);
    //     return (true, a / b);
    // }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    // function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    //     if (b == 0) return (false, 0);
    //     return (true, a % b);
    // }

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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.7.0;

interface IWorld {
  function initSettler() external returns (bool);

  function settler(address) external view returns (address);
}

interface ILand {
  function getCityOwner() external view returns (address _address);

  function sendWorker(uint) external;
  function retrieveWorker(uint) external;

  // defense city
  function reinForceCity(uint, uint, uint) external;
  function retreatFromCity(uint, uint, uint) external; // remove troops from attack or defend
  function getReinforceTroops() external view returns (uint, uint, uint, uint, uint, uint, uint);
  function getAllRainforceTroops() external view returns(uint _inf, uint _arc, uint _chv);
  // attack city
  function declareWar(uint _infantry, uint _archer, uint _chevalier) external;
  function joinWarRally(uint _infantry, uint _archer, uint _chevalier) external;
  function retreatFromRally(uint _infantry, uint _archer, uint _chevalier) external;
  function getRallyTroops() external view returns (uint _infantry, uint _archer, uint _charvelier, uint _atk, uint _defToInf, uint _defToArc, uint _defToChv);
  function getAllWarRallyTroops() external view returns (uint _infantry, uint _archer, uint _charvelier);
  function getRallyAttackTime() external view returns (uint _timestamp);
  function getWarCooldownTime() external view returns (uint _timestamp);
  // ====
  function getTopRallyPlayer() external view returns (address _address);
  // war result
//  function calculateWarResult() external;
//  function getClaimable() external view returns (uint _inf, uint _arc, uint _chv, uint _token);
//  function claim() external;
  
}

interface ISettler {
  // land adds resources to settler
  function addResources(uint, uint, uint, uint) external;

  function getWorker() external view returns (uint);
  // request workers from settler and send to land
  function requestWorker(uint) external;

  // return workers to settler
  function returnWorker(uint) external;

  // request troops from settler to land
  function requestTroops(uint, uint, uint) external;

  // return troops from land to settler
  function returnTroops(uint, uint, uint) external;

  function getHonorToken() external returns (uint _token);
  function receiveHonorToken(uint) external;

  function trainWorker(uint) external;
  function trainInfantry(uint) external;
  function trainArcher(uint) external;
  function trainChevalier(uint) external;
  function collect() external;
}

pragma solidity ^0.7.0;

import "./lib/Address.sol";
import "./lib/Utils.sol";
import "./lib/SafeMath.sol";

contract Settler is Context, ReentrancyGuard {
  using SafeMath for uint;

  event Upgrade(uint indexed level);

  address private _world;
  address private _owner;
  mapping (address => bool) lands;

  // settler
  uint private _level;

  // unit
  struct Unit {
    // current no of unit (include lands)
    // only used for worker to keep tracking with population limit
    uint current;
    uint settler;     // no of unit on settler

    uint training;    // no of currently training units
    uint startAt;
    uint unitPerMinute;

    uint walking;
    uint arrival;
  }
  uint public population;
  Unit public worker;
  Unit public infantry;
  Unit public archer;
  Unit public chevalier;

  // hero token
  uint public honorToken;

  // resources
  uint public food;
  uint public stone;
  uint public wood;
  uint public ore;

  uint private nextRequiredResource;

  constructor(address w, address u, address[] memory _lands) public {
    _world = w;
    _owner = u;
    init();
    uint n = _lands.length;
    for (uint256 i = 0; i < n; ++i) {
      lands[_lands[i]]=true;
    }
  }

  function init() internal virtual {
    _level = 1;
    population = 1000;
    honorToken = 0;
    worker.settler = 1;
    worker.current = 1;
    worker.unitPerMinute = 100; // support 2 decimal points
    infantry.unitPerMinute = 100;
    archer.unitPerMinute = 100;
    chevalier.unitPerMinute = 100;
    nextRequiredResource = 5000;
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }
  function world() public view virtual returns (address) {
    return _world;
  }
  function level() public view virtual returns (uint) {
    return _level;
  }

  modifier onlyOwner() {
    require(owner() == _msgSender(), "caller is not the owner");
    _;
  }
  modifier onlySystem() {
    require(world() == _msgSender(), "caller is not the system");
    _;
  }
  modifier onlyLand() {
    require(lands[_msgSender()], "caller is not the land");
    _;
  }

  function trainWorker(uint v) external onlyOwner {
    require(v > 0, "should be more than zero");
    require(worker.current.add(v) <= population, "population limit exceed");
    food = food.sub(v, "food not enough");
    wood = wood.sub(v, "wood not enough");

    _train(worker, v);
    worker.current = worker.current.add(v);
  }

  function _collect(Unit storage u) internal {
    if (u.training == 0) return;
    uint mins = uint(block.timestamp - u.startAt).div(60);
    uint v = uint(mins.mul(u.unitPerMinute)).div(100);
    if (v > u.training) {
      v = u.training;
    }
    u.training = u.training.sub(v);
    u.settler = u.settler.add(v);
    u.startAt = u.training == 0 ? block.timestamp : u.startAt.add(mins*60);
    // collect walking
    if (u.walking > 0 && block.timestamp >= u.arrival) {
      u.settler = u.settler.add(u.walking);
      u.walking = 0;
    }
  }

  function trainInfantry(uint v) external onlyOwner {
    require(v > 0, "should be more than zero");
    wood = wood.sub(v, "wood not enough");
    food = food.sub(v, "food not enough");
    ore = ore.sub(v, "ore not enough");
    _train(infantry, v);
  }

  function trainArcher(uint v) external onlyOwner {
    require(v > 0, "should be more than zero");
    wood = wood.sub(v.mul(2), "wood not enough");
    food = food.sub(v, "food not enough");
    _train(archer, v);
  }

  function trainChevalier(uint v) external onlyOwner {
    require(v > 0, "should be more than zero");
    wood = wood.sub(v, "train: wood not enough");
    food = food.sub(v.mul(2), "train: food not enough");
    ore = ore.sub(v, "train: ore not enough");
    _train(chevalier, v);
  }

  function _train(Unit storage u, uint amount) internal {
    _collect(u);
    u.training = u.training.add(amount);
    u.startAt = block.timestamp;
  }

  function collect() external {
    _collect(worker);
    _collect(infantry);
    _collect(archer);
    _collect(chevalier);
  }

  function upgradeSettler() external nonReentrant onlyOwner returns (bool success) {
    wood = wood.sub(nextRequiredResource, "upgrade: wood not enough");
    stone = stone.sub(nextRequiredResource.mul(3), "upgrade: stone not enough");
    ore = ore.sub(nextRequiredResource.div(2), "upgrade: ore not enough");

    _level = _level.add(1);
    population = population.mul(115).div(100);  // 15% increase
    nextRequiredResource = nextRequiredResource.mul(130).div(100); // 30% increase

    emit Upgrade(_level);
    return true;
  }

  function nextRequiredResources() public view returns (uint, uint, uint) {
    return (nextRequiredResource, nextRequiredResource.mul(3), nextRequiredResource.div(2));
  }

  function addResources(uint _food, uint _wood, uint _stone, uint _ore) external virtual nonReentrant onlyLand {
    food = food.add(_food);
    wood = wood.add(_wood);
    stone = stone.add(_stone);
    ore = ore.add(_ore);
  }

  function getWorker() public view virtual returns (uint) {
    return worker.settler;
  }

  function requestWorker(uint v) external virtual onlyLand {
    worker.settler = worker.settler.sub(v, "worker not enough");
  }
  
  function returnWorker(uint v) external virtual onlyLand {
    require(worker.settler.add(v) <= worker.current, "worker exceed limit");
    worker.settler = worker.settler.add(v);
  }

  function requestTroops(uint _infantry, uint _archer, uint _chevalier) external virtual onlyLand {
    infantry.settler = infantry.settler.sub(_infantry, "infantry not enough");
    archer.settler = archer.settler.sub(_archer, "archer not enough");
    chevalier.settler = chevalier.settler.sub(_chevalier, "chevalier not enough");
  }

  function returnTroops(uint _infantry, uint _archer, uint _chevalier) external virtual onlyLand {
    uint arrival = block.timestamp + 60; // default 1 minute
    if (_infantry > 0 || _archer > 0 || infantry.walking > 0 || archer.walking > 0) {
      arrival = block.timestamp + 300; // 5 minutes
    }
    _returnUnit(infantry, _infantry, arrival);
    _returnUnit(archer, _archer, arrival);
    _returnUnit(chevalier, _chevalier, arrival);
  }

  function getHonorToken() public view virtual returns (uint _token) {
    return honorToken;
  }

  function receiveHonorToken(uint _amount) external virtual onlyLand {
    honorToken = honorToken.add(_amount);
  }

  function _returnUnit(Unit storage u, uint amount, uint arrival) internal {
    if (amount == 0) return;
    u.walking = amount;
    u.arrival = arrival;
  }
}

pragma solidity ^0.7.0;

import "./Types.sol";

import "./lib/Address.sol";
import "./lib/Utils.sol";
import "./lib/SafeMath.sol";

contract Land is Context, ReentrancyGuard, Ownable {
  using Address for address;
  using SafeMath for uint256;
  using SafeMath for uint;

  IWorld world;

//  address public manager;
//  string public announceText = '';
//  string public name = '';
  uint8 public id;
  uint8 public taxRate = 50;
  uint8 public tier; // 1 = king land, 2 = duke, 3 = earl, 4 = baron
  uint32 public x;
  uint32 public y;
  uint32 public barbarian;

  address public cityOwner;

  // Troops Section
  struct TroopStat {
    uint256 Atk;
    uint256 DefToInf;
    uint256 DefToArc;
    uint256 DefToChv;
  }
  // Troop Infantry
  TroopStat INFANTRY_STAT = TroopStat(50, 50, 35, 60);
  TroopStat CHEVALIER_STAT = TroopStat(65, 50, 50, 50);
  TroopStat ARCHER_STAT = TroopStat(40, 60, 50, 50);

  struct Troop {
    // index
    address prev;
    address next;
    // data
    uint256 infantry;
    uint256 archer;
    uint256 chevalier;
    // sum of stat
    uint256 atk;
    uint256 defToInf;
    uint256 defToArc;
    uint256 defToChv;
  }
  // city defense
  address endTroopAddrPointer;
  address startTroopAddrPointer;
  mapping(address => Troop) public defTroops;
  // rally attacker
  address startRallyAddrPointer;
  address endRallyAddrPointer;
  mapping(address => Troop) public rallyTroops;
  // top rally atttacker is player who will the next city's owner
  // time to attack
  uint rallyAttackTime; // time to rally will attact the city
  uint warCooldownTime; // cooldown to disable declare war feature
  // sum of all troop
  Troop allDefTroops;
  Troop allRallyTroops;
  // after war result
//  struct WarResult {
//    uint timestamp;
//    Troop defender;
//    Troop attacker;
//    uint result; // 0 = draw / 1 = attacker win / 2 = defender win
//    uint diffPower;
//    uint deathTroops;
//  }
//  WarResult[] warResults;
  // keep after war troop in variable
//  struct AfterWarTroop {
//    uint warNo;
//    uint remainTroopPercent;
//    Troop troop;
//    uint rewardToken;
//  }
//  mapping(address => AfterWarTroop[]) afterWarTroops;

  // worker
  struct Worker {
    // index
//    address prev;
//    address next;
    // data
    uint worker;
    uint rssDebt;
  }
//  address endWorkerAddrPointer;
//  address startWorkerAddrPointer;
  mapping(address => Worker) public workers;
  uint256 WORKER_GATHER_PER_SECOND = 2e10;
  uint256 totalWorkerPower;

  // resources
  struct ResourcePerShare {
    uint256 lastBlockNo;
    uint256 lastBlockTime;
    uint256 perShare;
    uint256 totalRate;
    uint256 foodRate; // food generate in rss/second
    uint256 woodRate;
    uint256 stoneRate;
    uint256 ironRate;
  }

  ResourcePerShare resources;
  /*
    1 worker gather power = 1.2 rss/min => 0.015 rss/sec
    all number multiply by 1e10
  */
  uint256 minWorkerNeedRssShare; // minimum share that

  function init(
    uint8 _id,
    uint8 _tier,
    uint32 _barbarian,
    uint32 _x,
    uint32 _y,
    uint256 _foodRate,
    uint256 _woodRate,
    uint256 _stoneRate,
    uint256 _ironRate,
    address _world
  ) external onlyOwner {
    world = IWorld(_world);
    tier = _tier;
    barbarian = _barbarian;
    x = _x;
    y = _y;
    id = _id;
    // init def troop
    // defTroops[manager] = Troop(endTroopAddrPointer, address(0), _barbarian, 0, 0);

//    uint atk;
//    uint defToInf;
//    uint defToArc;
//    uint defToChv;
//    (atk, defToInf, defToArc, defToChv) = _getSumTroopsStat(_barbarian, 0, 0);
//    defTroops[manager] = Troop(endTroopAddrPointer, address(0), _barbarian, 0, 0, atk, defToInf, defToArc, defToChv);
//    // sum of defense troops
//    allDefTroops = Troop(address(0), address(0), _barbarian, 0, 0, atk, defToInf, defToArc, defToChv);

    // set latest player send to def is manager addr
    startTroopAddrPointer = owner();
    endTroopAddrPointer = owner();

    // init rss per share
    uint256 wFood = _foodRate.mul(1e12).div(60); // convert rss/min -> rss/sec and multiply by 10^12
    uint256 wWood = _woodRate.mul(1e12).div(60);
    uint256 wStone = _stoneRate.mul(1e12).div(60);
    uint256 wIron = _ironRate.mul(1e12).div(60);
    uint256 totalResourceRate = wFood.add(wWood).add(wStone).add(wIron);
    minWorkerNeedRssShare = totalResourceRate.div(WORKER_GATHER_PER_SECOND); // 1 worker can gather up to 1.2 rss/min => 0.02 rss/sec keep in 1e12
    resources = ResourcePerShare(
      block.number,
      block.timestamp,
      0,
      totalResourceRate,
      wFood,
      wWood,
      wStone,
      wIron
    );
  }

//  function getCityOwner() external view returns (address) {
//    return cityOwner;
//  }

//  function getLatestGatherBlock() external view returns(uint) {
//    return rssPerShare.latestGatherBlock;
//  }

  function getLandInfo() external view returns(uint, uint, uint, uint) {
    return (id, x, y, tier);
  }

  function getResourceProductivity() public view returns(uint256, uint256, uint256, uint256, uint256) {
    return (resources.totalRate, resources.foodRate, resources.woodRate, resources.stoneRate, resources.ironRate);
  }

//  function getTaxRate() public view returns(uint) {
//    return taxRate;
//  }

  // deploy worker
  function sendWorker(uint256 _workers) external virtual {
    // TODO: check deployer worker balance
    require(_workers >= 1, "worker must more than 1");
    // TODO: call safeRequestWorker here
    address sender = _msgSender();
    ISettler s = ISettler(world.settler(sender));
    // console.log("current worker", s.getWorker());
    require(s.getWorker() >= _workers, "worker not enough");
    // Update Pool
    updateLandRss();
    // request worker from settler
    // s.requestWorker(_workers);
    _safeRequestWorker(s, _workers);

    uint resourcePerShare = resources.perShare;

    if (workers[sender].worker == 0) {
      // create new
      workers[sender] = Worker(
        _workers,
        _workers.mul(resourcePerShare)
      );
    } else {
      // Claim pending resources
      uint256 food;
      uint256 wood;
      uint256 stone;
      uint256 iron;
      (food, wood, stone, iron) = getPendingResource();

      // Transfer Rss
      _safeAddResources(s, food, wood, stone, iron);

      { // update worker and debt
        uint w = workers[sender].worker.add(_workers);
        workers[sender].worker = w;
        workers[sender].rssDebt = w.mul(resourcePerShare);
      }
    }
    { // update total worker power
      uint t = totalWorkerPower;
      totalWorkerPower = t.add(_workers);
    }
  }
  

//  function getMyWorkerDeployed() public view returns (uint _workers) {
//    return workers[msg.sender].worker;
//  }

  function getWorker(address addr) public view returns (uint) {
    return workers[addr].worker;
  }

  function getTotalWorkerPower() public view returns (uint) {
    return totalWorkerPower;
  }
  function getMinimumWorker() public view returns (uint) {
    return minWorkerNeedRssShare;
  }

//  function getTotalWorkerPower() public view returns (uint _power, uint _minWorkerToShare) {
//    return (workersPower, minWorkerNeedRssShare);
//  }

//  function getFristDeployed() public view returns (address _first) {
//    return startWorkerAddrPointer;
//  }

  // callback worker
  function retrieveWorker(uint256 _workers) external virtual {
    uint worker = workers[msg.sender].worker.sub(_workers);
    address sender = _msgSender();
    ISettler s = ISettler(world.settler(sender));

    // update pool
    updateLandRss();

    // claim pending resources
    uint256 food;
    uint256 wood;
    uint256 stone;
    uint256 iron;
    (food, wood, stone, iron) = getPendingResource();
    _safeAddResources(s, food, wood, stone, iron);

    if (worker > 0) {
      workers[sender].worker = worker;
      // Calculate Debt
      workers[sender].rssDebt = worker.mul(resources.perShare);
    } else {
      workers[sender].worker = 0;
      workers[sender].rssDebt = 0;
    }
    // transfer worker to settler
    _safeReturnWorker(s, _workers);

    { // remove total worker power
      uint totalWorker = totalWorkerPower;
      totalWorkerPower = totalWorker.sub(_workers);
    }
  }

  // claim resource
  function updateLandRss() internal {
    if (block.number < resources.lastBlockNo) {
      return;
    }
    if (totalWorkerPower == 0) {
      // no worker, only update block info
      resources.lastBlockNo = block.number;
      resources.lastBlockTime = block.timestamp;
      return;
    }
    uint totalWorker = totalWorkerPower;
    uint totalRate = resources.totalRate;
    uint fromTime = resources.lastBlockTime;
    uint toTime = block.timestamp;
    uint perShare = resources.perShare;

    // get rss per minute
    if (totalWorkerPower < minWorkerNeedRssShare) {
      // resource per second is lower when total workers is less than total generate rate
      totalRate = totalWorker.mul(WORKER_GATHER_PER_SECOND);
    }
    uint generatedReward = toTime.sub(fromTime).mul(totalRate);
    // save reward per share
    resources.perShare = perShare.add(generatedReward.div(totalWorker));
    // update rss block and timestamp
    resources.lastBlockNo = block.number;
    resources.lastBlockTime = block.timestamp;
  }

  function getPendingResource() public view returns (uint food, uint wood, uint stone, uint iron) {
    // pending rss to claim
    // = rssPerShare * (gatherPower / totalGatherPower) - rssRewardDebt
    if (totalWorkerPower == 0) {
      // no worker update lastest block => return
      return (0, 0, 0, 0);
    }
    uint totalRate = resources.totalRate;
    uint resourcePerSec = totalRate;
    uint minWorker = minWorkerNeedRssShare;
    uint lastBlockTime = resources.lastBlockTime;
    uint perShare = resources.perShare;

    if (totalWorkerPower < minWorker) {
      // resource per second is lower when total workers is less than total generate rate
      resourcePerSec = totalWorkerPower.mul(WORKER_GATHER_PER_SECOND);
    }
    uint totalReward = block.timestamp.sub(lastBlockTime).mul(resourcePerSec);
    uint pendingPerShare = perShare.add(totalReward.div(totalWorkerPower));
    uint pendingReward = workers[_msgSender()].worker.mul(pendingPerShare).sub(workers[_msgSender()].rssDebt);

    // pending resource is multiply by the ratio of each
    food = pendingReward.mul(resources.foodRate).div(totalRate);
    wood = pendingReward.mul(resources.woodRate).div(totalRate);
    stone = pendingReward.mul(resources.stoneRate).div(totalRate);
    iron = pendingReward.mul(resources.ironRate).div(totalRate);
  }

  function claimResource() external {
    address s = world.settler(_msgSender());
    require(s != address(0), "");

    // update land
    updateLandRss();

    // get pending resource
    uint food;
    uint wood;
    uint stone;
    uint iron;
    (food, wood, stone, iron) = getPendingResource();
    // transfer rss
    _safeAddResources(ISettler(s), food, wood, stone, iron);

    // update debt
    workers[_msgSender()].rssDebt = workers[_msgSender()].worker.mul(resources.perShare);
  }

//  function transferResource(uint _food, uint _wood, uint _stone, uint _iron) private {
//    // TODO: Connect with Settler to transfer rss
//    address s = world.settler(msg.sender);
//    _safeAddResources(ISettler(s), _food, _wood, _stone, _iron);
//  }

  // connect with Settler

  function _safeAddResources(ISettler s, uint food, uint wood, uint stone, uint ore) internal virtual {
    (bool success, bytes memory data) = address(s).call(abi.encodeWithSelector(s.addResources.selector, food, wood, stone, ore));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'land: add resource failed');
  }

  function _safeRequestWorker(ISettler s, uint _worker) internal virtual {
    (bool success, bytes memory data) = address(s).call(abi.encodeWithSelector(s.requestWorker.selector, _worker));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'land: request worker failed');
  }

  function _safeReturnWorker(ISettler s, uint _worker) internal virtual {
    (bool success, bytes memory data) = address(s).call(abi.encodeWithSelector(s.returnWorker.selector, _worker));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'land: return worker failed');
  }

  function _safeRequestTroop(ISettler _s, uint _inf, uint _arc, uint _chv) internal {
    (bool success, bytes memory data) = address(_s).call(abi.encodeWithSelector(_s.requestTroops.selector, _inf, _arc, _chv));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'land: request troop failed');
  }

  function _safeReturnTroop(ISettler _s, uint _inf, uint _arc, uint _chv) internal {
    (bool success, bytes memory data) = address(_s).call(abi.encodeWithSelector(_s.returnTroops.selector, _inf, _arc, _chv));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'land: return troop failed');
  }

  // defense city section
  function _getSumTroopsStat(uint _infantry, uint _archer, uint _charvely) internal view returns (uint _atk, uint _defToInf, uint _defToArc, uint _defToChv) {
    uint atk = (INFANTRY_STAT.Atk.mul(_infantry)).add(CHEVALIER_STAT.Atk.mul(_charvely)).add(ARCHER_STAT.Atk.mul(_archer));
    uint defToInf = (INFANTRY_STAT.DefToInf.mul(_infantry)).add(CHEVALIER_STAT.DefToInf.mul(_charvely)).add(ARCHER_STAT.DefToInf.mul(_archer));
    uint defToChv = (INFANTRY_STAT.DefToChv.mul(_infantry)).add(CHEVALIER_STAT.DefToChv.mul(_charvely)).add(ARCHER_STAT.DefToChv.mul(_archer));
    uint defToArc = (INFANTRY_STAT.DefToArc.mul(_infantry)).add(CHEVALIER_STAT.DefToArc.mul(_charvely)).add(ARCHER_STAT.DefToArc.mul(_archer));
    return (atk, defToInf, defToArc, defToChv);
  }

  function reinForceCity(uint _infantry, uint _archer, uint _charvely) external virtual {
    // calc total atk and def
    uint atk;
    uint defToInf;
    uint defToArc;
    uint defToChv;
    (atk, defToInf, defToArc, defToChv) = _getSumTroopsStat(_infantry, _archer, _charvely);
    // transfer troops
    address s = world.settler(_msgSender());
    _safeRequestTroop(ISettler(s), _infantry, _archer, _charvely);
    if (defTroops[_msgSender()].atk == 0) {
      defTroops[endTroopAddrPointer].next = _msgSender();
      defTroops[_msgSender()] = Troop(endTroopAddrPointer, address(0), _infantry, _archer, _charvely, atk, defToInf, defToArc, defToChv);
      endTroopAddrPointer = _msgSender();
    } else {
      defTroops[_msgSender()].atk = defTroops[_msgSender()].atk.add(atk);
      defTroops[_msgSender()].defToInf = defTroops[_msgSender()].defToInf.add(defToInf);
      defTroops[_msgSender()].defToChv = defTroops[_msgSender()].defToChv.add(defToChv);
      defTroops[_msgSender()].defToArc = defTroops[_msgSender()].defToArc.add(defToArc);
    }
    // Update total def troops
    allDefTroops.atk = allDefTroops.atk.add(atk);
    allDefTroops.defToInf = allDefTroops.defToInf.add(defToInf);
    allDefTroops.defToArc = allDefTroops.defToArc.add(defToArc);
    allDefTroops.defToChv = allDefTroops.defToChv.add(defToChv);
    allDefTroops.infantry = allDefTroops.infantry.add(_infantry);
    allDefTroops.archer = allDefTroops.archer.add(_archer);
    allDefTroops.chevalier = allDefTroops.chevalier.add(_charvely);
  }

  function retreatFromCity(uint _infantry, uint _archer, uint _charvely) external virtual {
    // check troop in city
    Troop memory _troop = defTroops[_msgSender()];
    require(_troop.infantry >= _infantry && _troop.archer >= _archer && _troop.chevalier >= _charvely, "land: troops not enough to return");
    // get sum of troops stat to reduce
    uint atk;
    uint defToInf;
    uint defToArc;
    uint defToChv;
    (atk, defToInf, defToArc, defToChv) = _getSumTroopsStat(_infantry, _archer, _charvely);
    // Delete pointer if not remain troops
    if (_troop.infantry <= _infantry && _troop.archer <= _archer && _troop.chevalier <= _charvely) {
      // delete from struct
      defTroops[_troop.prev].next = _troop.next;
      defTroops[_troop.next].prev = _troop.prev;
      delete defTroops[_msgSender()];
    } else {
      // just reduce some troop
      defTroops[_msgSender()].infantry = defTroops[_msgSender()].infantry.sub(_infantry);
      defTroops[_msgSender()].archer = defTroops[_msgSender()].archer.sub(_archer);
      defTroops[_msgSender()].chevalier = defTroops[_msgSender()].chevalier.sub(_charvely);
      defTroops[_msgSender()].atk = defTroops[_msgSender()].atk.sub(atk);
      defTroops[_msgSender()].defToInf = defTroops[_msgSender()].defToInf.sub(defToInf);
      defTroops[_msgSender()].defToArc = defTroops[_msgSender()].defToArc.sub(defToArc);
      defTroops[_msgSender()].defToChv = defTroops[_msgSender()].defToChv.sub(defToChv);
    }
    // transferTroop to settler
    address _s = world.settler(_msgSender());
    _safeReturnTroop(ISettler(_s), _infantry, _archer, _charvely);
    // TODO: Update total def troops
    allDefTroops.atk = allDefTroops.atk.sub(atk);
    allDefTroops.defToInf = allDefTroops.defToInf.sub(defToInf);
    allDefTroops.defToArc = allDefTroops.defToArc.sub(defToArc);
    allDefTroops.defToChv = allDefTroops.defToChv.sub(defToChv);
    allDefTroops.infantry = allDefTroops.infantry.sub(_infantry);
    allDefTroops.archer = allDefTroops.archer.sub(_archer);
    allDefTroops.chevalier = allDefTroops.chevalier.sub(_charvely);
  }

  function getReinforceTroops() public view returns (uint _infantry, uint _archer, uint _charvely, uint _atk, uint _defToInf, uint _defToArc, uint _defToChv) {
    Troop memory _troop = defTroops[_msgSender()];
    return (_troop.infantry, _troop.archer, _troop.chevalier, _troop.atk, _troop.defToInf, _troop.defToArc, _troop.defToChv);
  }

  function getAllRainforceTroops() public view returns (uint _infantry, uint _archer, uint _charvely) {
    return (allDefTroops.infantry, allDefTroops.archer, allDefTroops.chevalier);
  }
  
  // war section
  function declareWar(uint _infantry, uint _archer, uint _charvely) external virtual {
    // keep troops in rally
    // require(block.timestamp < warCooldownTime, "Land: land is on peaceful time");
    require(block.timestamp > rallyAttackTime, "War already declared.");
    uint atk;
    uint defToInf;
    uint defToArc;
    uint defToChv;
    (atk, defToInf, defToArc, defToChv) = _getSumTroopsStat(_infantry, _archer, _charvely);
    // request settler troops
    // transfer troops
    address s = world.settler(_msgSender());
    _safeRequestTroop(ISettler(s), _infantry, _archer, _charvely);
    rallyTroops[_msgSender()] = Troop(endRallyAddrPointer, address(0), _infantry, _archer, _charvely, atk, defToInf, defToArc, defToChv);
    endRallyAddrPointer = _msgSender();
    startRallyAddrPointer = _msgSender();
    allRallyTroops.atk = atk;
    allRallyTroops.defToInf = defToInf;
    allRallyTroops.defToArc = defToArc;
    allRallyTroops.defToChv = defToChv;
    allRallyTroops.infantry = _infantry;
    allRallyTroops.archer = _archer;
    allRallyTroops.chevalier = _charvely;
    // start countdown to attack
    rallyAttackTime = block.timestamp.add(10800); // add 3 hrs
    // TODO: request eth for gas fee
  }

  function joinWarRally(uint _infantry, uint _archer, uint _charvely) external virtual {

    require(rallyAttackTime > block.timestamp, "war not declare");
    uint atk;
    uint defToInf;
    uint defToArc;
    uint defToChv;
    (atk, defToInf, defToArc, defToChv) = _getSumTroopsStat(_infantry, _archer, _charvely);
    // transfer troop from settler
    address s = world.settler(_msgSender());
    _safeRequestTroop(ISettler(s), _infantry, _archer, _charvely);
    if (rallyTroops[_msgSender()].atk == 0) {
      rallyTroops[_msgSender()] = Troop(endRallyAddrPointer, address(0), _infantry, _archer, _charvely, atk, defToInf, defToArc, defToChv);
      rallyTroops[endRallyAddrPointer].next = _msgSender(); // update rally troop pointer
      endRallyAddrPointer = _msgSender();
    } else {
      // add troop amount 
      rallyTroops[_msgSender()].infantry = rallyTroops[_msgSender()].infantry.add(_infantry);
      rallyTroops[_msgSender()].archer = rallyTroops[_msgSender()].archer.add(_archer);
      rallyTroops[_msgSender()].chevalier = rallyTroops[_msgSender()].chevalier.add(_charvely);
      rallyTroops[_msgSender()].atk = rallyTroops[_msgSender()].atk.add(atk);
      rallyTroops[_msgSender()].defToInf = rallyTroops[_msgSender()].defToInf.add(defToInf);
      rallyTroops[_msgSender()].defToChv = rallyTroops[_msgSender()].defToChv.add(defToChv);
      rallyTroops[_msgSender()].defToArc = rallyTroops[_msgSender()].defToArc.add(defToArc);
    }
    allRallyTroops.atk = allRallyTroops.atk.add(atk);
    allRallyTroops.defToInf = allRallyTroops.defToInf.add(defToInf);
    allRallyTroops.defToArc = allRallyTroops.defToArc.add(defToArc);
    allRallyTroops.defToChv = allRallyTroops.defToChv.add(defToChv);
    allRallyTroops.infantry = allRallyTroops.infantry.add(_infantry);
    allRallyTroops.archer = allRallyTroops.archer.add(_archer);
    allRallyTroops.chevalier = allRallyTroops.chevalier.add(_charvely);
    
  }

  function retreatFromRally(uint _infantry, uint _archer, uint _charvely) external virtual {
    // check troop in city
    Troop memory _troop = rallyTroops[_msgSender()];
    require(_troop.infantry >= _infantry && _troop.archer >= _archer && _troop.chevalier >= _charvely, "land: troops not enough to return");
    // get sum of troops stat to reduce
    uint atk;
    uint defToInf;
    uint defToArc;
    uint defToChv;
    (atk, defToInf, defToArc, defToChv) = _getSumTroopsStat(_infantry, _archer, _charvely);
    // Delete pointer if not remain troops
    if (_troop.infantry <= _infantry && _troop.archer <= _archer && _troop.chevalier <= _charvely) {
      // delete from struct
      rallyTroops[_troop.prev].next = _troop.next;
      rallyTroops[_troop.next].prev = _troop.prev;
      delete defTroops[_msgSender()];
    } else {
      // just reduce some troop
      rallyTroops[_msgSender()].infantry = rallyTroops[_msgSender()].infantry.sub(_infantry);
      rallyTroops[_msgSender()].archer = rallyTroops[_msgSender()].archer.sub(_archer);
      rallyTroops[_msgSender()].chevalier = rallyTroops[_msgSender()].chevalier.sub(_charvely);
      rallyTroops[_msgSender()].atk = rallyTroops[_msgSender()].atk.sub(atk);
      rallyTroops[_msgSender()].defToInf = rallyTroops[_msgSender()].defToInf.sub(defToInf);
      rallyTroops[_msgSender()].defToArc = rallyTroops[_msgSender()].defToArc.sub(defToArc);
      rallyTroops[_msgSender()].defToChv = rallyTroops[_msgSender()].defToChv.sub(defToChv);
    }
    // transferTroop to settler
    address _s = world.settler(_msgSender());
    _safeReturnTroop(ISettler(_s), _infantry, _archer, _charvely);
    // Update total def troops
    allRallyTroops.atk = allRallyTroops.atk.sub(atk);
    allRallyTroops.defToInf = allRallyTroops.defToInf.sub(defToInf);
    allRallyTroops.defToArc = allRallyTroops.defToArc.sub(defToArc);
    allRallyTroops.defToChv = allRallyTroops.defToChv.sub(defToChv);
    allRallyTroops.infantry = allRallyTroops.infantry.sub(_infantry);
    allRallyTroops.archer = allRallyTroops.archer.sub(_archer);
    allRallyTroops.chevalier = allRallyTroops.chevalier.sub(_charvely);
  }

  function getRallyTroops() public view returns (uint _infantry, uint _archer, uint _charvelier, uint _atk, uint _defToInf, uint _defToArc, uint _defToChv) {
    Troop memory _troop = rallyTroops[_msgSender()];
    return (_troop.infantry, _troop.archer, _troop.chevalier, _troop.atk, _troop.defToInf, _troop.defToArc, _troop.defToChv);
  }

  function getAllWarRallyTroops() public view returns (uint _infantry, uint _archer, uint _charvelier) {
    return (allRallyTroops.infantry, allRallyTroops.archer, allRallyTroops.chevalier);
  }

  function getTopRallyPlayer() external view returns (address _address) {
     // loop to push all player in attack rally to afterWarTroops
    address _currentAddr = startRallyAddrPointer;
    uint topAtkPlayerPower = 0;
    address topAtkPlayerAddr2 = address(0);
    // console.log("here ----------> ", _currentAddr);
    while(_currentAddr != address(0)) {
      // console.log("current addr: ", _currentAddr);
      // console.log("current atk: ", rallyTroops[_currentAddr].atk);
      // console.log("top player addr: ", topAtkPlayerAddr2);
      // console.log("top player addr: ", topAtkPlayerPower);
      if (rallyTroops[_currentAddr].atk > topAtkPlayerPower) {
        topAtkPlayerPower = rallyTroops[_currentAddr].atk;
        topAtkPlayerAddr2 = _currentAddr;
      }
      _currentAddr = rallyTroops[_currentAddr].next;
    }
    return topAtkPlayerAddr2;
  }

  function getRallyAttackTime() public view returns(uint _timstamps) {
    return rallyAttackTime;
  }

  function getWarCooldownTime() public view returns(uint _timesamps) {
    return warCooldownTime;
  }

  function calculateWarResult() external virtual onlyOwner {
    require(block.timestamp >= rallyAttackTime, "please waiting for rally countdown");
    /*
      War Result
      algo:
      TotalAtkPower = nInfInRally * InfAtk + nArcInRally * ArcAtk + nChvInRally * ChvAtk
      ===
      nTroopInRally = nInfInRally + nArcInRally + nChvInRally
      TotalDefPower = sumInfDef * (nInfInRally / nTroopInRally) + 
                      sumArcDef * (nArcInRally / nTroopInRally) +
                      sumChvDef * (nChvInRally / nTroopInRally)
      ===
      warResult     = TotalAtkPower - TotalDefPower
      ===
      Positive      = Attacker win
      Zero|Negative = Defender win
    */
    uint totalAtkPower = allRallyTroops.atk;
    uint totalAtkTroop = allRallyTroops.infantry.add(allRallyTroops.archer).add(allRallyTroops.chevalier);
    uint totalDefPower = (allDefTroops.defToInf.mul(allRallyTroops.infantry.div(totalAtkTroop))).add(allDefTroops.defToArc.mul(allRallyTroops.archer.div(totalAtkTroop))).add(allDefTroops.defToChv.mul(allRallyTroops.chevalier.div(totalAtkTroop)));
//    WarResult memory _warResult; // 0 = draw | 1 = attacker win | 2 defender win
    uint _diffPower;
    uint _troopRemain;
//    uint _warNo = warResults.length;
    uint _warNo = 1;
    uint winnerTokenReward = 1000;
    uint loserTokenReward = 1000;
    uint _reward = 0;
    if (totalAtkPower > totalDefPower) {
      // rally attacker win
      
      // TODO: calculate troop loss
      _diffPower = totalAtkPower.sub(totalDefPower);
      _troopRemain = _diffPower.mul(1e12).div(totalAtkPower); // markup keep decimal in 1e12
      // console.log("troop remain", _troopRemain);
      // save war result
//      _warResult = WarResult(block.timestamp, allDefTroops, allRallyTroops, 1, _diffPower, _troopRemain);
//      warResults.push(_warResult);

      // spread reward
      // loop to push all player in attack rally to afterWarTroops
      address _currentAddr = startRallyAddrPointer;
      address _tempAddr = address(0);
      uint topAtkPlayerPower = 0;
      address topAtkPlayerAddr = address(0);
      while(_currentAddr != address(0)) {
        // TODO: calculate now
        _reward = winnerTokenReward.mul(1e8).mul(rallyTroops[_currentAddr].atk).div(totalAtkPower);
//        AfterWarTroop memory _afterWarTroop = AfterWarTroop(_warNo, _troopRemain, rallyTroops[_currentAddr], _reward);
        // _remain_archer = rallyTroops[_currentAddr].archer.sub(rallyTroops[_currentAddr].archer.mul(_troopLoss).div(1e14));
        // _remain_archer = rallyTroops[_currentAddr].archer.sub(rallyTroops[_currentAddr].archer.mul(_troopLoss).div(1e14));
        // _remain_archer = rallyTroops[_currentAddr].archer.sub(rallyTroops[_currentAddr].archer.mul(_troopLoss).div(1e14));
        // console.log("atk reward:", _reward);
        // console.log("atk inf:", rallyTroops[_currentAddr].infantry);
        if (rallyTroops[_currentAddr].atk > topAtkPlayerPower) {
          topAtkPlayerPower = rallyTroops[_currentAddr].atk;
          topAtkPlayerAddr = _currentAddr;
        }
//        afterWarTroops[_currentAddr].push(_afterWarTroop);
        _tempAddr = _currentAddr;
        _currentAddr = rallyTroops[_currentAddr].next;
        delete rallyTroops[_tempAddr];
      }
      // loop to push all player in defense city to afterWarTroops
      _currentAddr = startTroopAddrPointer;
      while(_currentAddr != address(0)) {
        _reward = loserTokenReward.mul(1e8)
          .mul(
            defTroops[_currentAddr].infantry
            .add(defTroops[_currentAddr].archer)
            .add(defTroops[_currentAddr].chevalier)
          ).div(totalAtkTroop);
        // console.log("def reward:", _re1ward);
        // console.log("def inf:", defTroops[_currentAddr].infantry);
//        AfterWarTroop memory _afterWarTroop = AfterWarTroop(_warNo, 0, defTroops[_currentAddr], _reward);
//        afterWarTroops[_currentAddr].push(_afterWarTroop);
        _tempAddr = _currentAddr;
        _currentAddr = defTroops[_currentAddr].next;
        delete defTroops[_tempAddr];
      }
      // clear data
      // change city owner
      cityOwner = topAtkPlayerAddr;
    } else if (totalAtkPower < totalDefPower) {
      // city defender win
      // calculate troops loss
      _diffPower = totalDefPower.sub(totalAtkPower);
      _troopRemain = _diffPower.mul(1e12).div(totalDefPower);
      // save war result
//      _warResult = WarResult(block.timestamp, allDefTroops, allRallyTroops, 2, _diffPower, _troopRemain);
//      warResults.push(_warResult);

      // spread reward
      // loop to push all player in defense city to afterWarTroops
      address _tempAddr = address(0);
      address _currentAddr = startTroopAddrPointer;
      while(_currentAddr != address(0)) {
        _reward = loserTokenReward.mul(1e8)
          .mul(
            defTroops[_currentAddr].infantry
            .add(defTroops[_currentAddr].archer)
            .add(defTroops[_currentAddr].chevalier)
          ).mul(50).div(totalDefPower);
//        AfterWarTroop memory _afterWarTroop = AfterWarTroop(_warNo, _troopRemain, defTroops[_currentAddr], _reward);
//        afterWarTroops[_currentAddr].push(_afterWarTroop);
        _tempAddr = _currentAddr;
        _currentAddr = defTroops[_currentAddr].next;
        delete defTroops[_tempAddr];
      }
      // loop to push all player in attack rally to afterWarTroops
      _currentAddr = startRallyAddrPointer;
      while(_currentAddr != address(0)) {
        _reward = winnerTokenReward.mul(1e8).mul(rallyTroops[_currentAddr].atk).div(totalDefPower);
//        AfterWarTroop memory _afterWarTroop = AfterWarTroop(_warNo, 0, rallyTroops[_currentAddr], _reward);
//        afterWarTroops[_currentAddr].push(_afterWarTroop);
        _tempAddr = _currentAddr;
        _currentAddr = rallyTroops[_currentAddr].next;
        delete rallyTroops[_tempAddr];
      }
    } else {
      // draw any troop die
//      _warResult = WarResult(block.timestamp, allDefTroops, allRallyTroops, 0, 0, 1e12);
//      warResults.push(_warResult);
      // spread reward
      address _currentAddr = startTroopAddrPointer;
      address _tempAddr = address(0);
      while(_currentAddr != address(0)) {
        _reward = winnerTokenReward.mul(1e8).mul(rallyTroops[_currentAddr].atk).div(totalAtkPower);
//        AfterWarTroop memory _afterWarTroop = AfterWarTroop(_warNo, 0, defTroops[_currentAddr], _reward);
//        afterWarTroops[_currentAddr].push(_afterWarTroop);
        _tempAddr = _currentAddr;
        _currentAddr = defTroops[_currentAddr].next;
        delete rallyTroops[_tempAddr];
      }
      // loop to push all player in attack rally to afterWarTroops
      _currentAddr = startRallyAddrPointer;
      while(_currentAddr != address(0)) {
        _reward = loserTokenReward.mul(1e8)
          .mul(
            defTroops[_currentAddr].infantry
            .add(defTroops[_currentAddr].archer)
            .add(defTroops[_currentAddr].chevalier)
          ).div(totalAtkTroop);
//        AfterWarTroop memory _afterWarTroop = AfterWarTroop(_warNo, 0, rallyTroops[_currentAddr], _reward);
//        afterWarTroops[_currentAddr].push(_afterWarTroop);
        _tempAddr = _currentAddr;
        _currentAddr = rallyTroops[_currentAddr].next;
        delete rallyTroops[_tempAddr];
      }
    }
    resetWarData();
    /*
      Troop Death
      algo:
      defeat = die all
      win = have less troop
      ======
      diffPower = TotalAtkPower - TotalDefPower
      %RemainTroop = diffPower/WinnerAtkOrDefPower
    */
  }

//  function getClaimable() public view returns(uint _inf, uint _arc, uint _chv, uint _token) {
////    uint _len = afterWarTroops[_msgSender()].length;
//    uint totalInf = 0;
//    uint totalArc = 0;
//    uint totalChv = 0;
//    uint totalToken = 0;
////    address _me = _msgSender();
////    for (uint i = 0; i < _len; i++) {
////      totalInf = totalInf.add(afterWarTroops[_me][i].troop.infantry.mul(afterWarTroops[_me][i].remainTroopPercent).div(1e12));
////      totalArc = totalArc.add(afterWarTroops[_me][i].troop.archer.mul(afterWarTroops[_me][i].remainTroopPercent).div(1e12));
////      totalChv = totalArc.add(afterWarTroops[_me][i].troop.charvely.mul(afterWarTroops[_me][i].remainTroopPercent).div(1e12));
////      totalToken = totalToken.add(afterWarTroops[_me][i].rewardToken);
////    }
//
//    return (totalInf, totalArc, totalChv, totalToken);
//
//  }

//  function claim() external virtual {
//    uint256 _inf;
//    uint256 _arc;
//    uint256 _chv;
//    uint256 _token;
//    address _user = _msgSender();
//    (_inf, _arc, _chv, _token) = getClaimable();
//    // TODO: transfer token
//    address _s = world.settler(_user);
//    _safeTransferHonorToken(ISettler(_s), _token);
//    // TODO: transfer troop
//    _safeReturnTroop(ISettler(_s), _inf, _arc, _chv);
//    // TODO: delete claimable data
//    delete afterWarTroops[_user];
//  }

//  function _safeTransferHonorToken(ISettler _s, uint256 _amount) internal {
//    (bool success, bytes memory data) = address(_s).call(abi.encodeWithSelector(_s.receiveHonorToken.selector, _amount));
//    require(success && (data.length == 0 || abi.decode(data, (bool))), 'land: transfer honor token failed');
//  }

  function resetWarData() internal {
    // rally attacker
    allRallyTroops.infantry = 0;
    allRallyTroops.archer = 0;
    allRallyTroops.chevalier = 0;
    allRallyTroops.atk = 0;
    allRallyTroops.defToInf = 0;
    allRallyTroops.defToArc = 0;
    allRallyTroops.defToChv = 0;
    // city defender
    allDefTroops.infantry = 0;
    allDefTroops.archer = 0;
    allDefTroops.chevalier = 0;
    allDefTroops.atk = 0;
    allDefTroops.defToInf = 0;
    allDefTroops.defToArc = 0;
    allDefTroops.defToChv = 0;
    // set war cooldown
    warCooldownTime = block.timestamp.add(82800);
  }

  // Return reward multiplier over the given _from to _to block.
//  function getMultiplier(uint256 _from, uint256 _to, uint _rssPerSecond) public view returns (uint256) {
//      return _to.sub(_from).mul(_rssPerSecond);
//  }
}

