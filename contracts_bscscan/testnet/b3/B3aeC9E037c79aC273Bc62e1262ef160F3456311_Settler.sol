pragma solidity ^0.7.0;

import "./lib/Address.sol";
import "./lib/Utils.sol";
import "./lib/SafeMath.sol";

contract Settler is Context, ReentrancyGuard {
  using SafeMath for uint;
  using SafeMath for uint256;

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