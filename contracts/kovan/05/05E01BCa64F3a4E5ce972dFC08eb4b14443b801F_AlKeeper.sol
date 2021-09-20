pragma solidity 0.8.4;

import {IKeeperCompatibleInterface} from "./IKeeperCompatibleInterface.sol";
import {IAlchemist} from "./IAlchemist.sol";
import {ITransmuter} from "./ITransmuter.sol";
import {IVaultAdaptor} from "./IVaultAdaptor.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AlKeeper is IKeeperCompatibleInterface, Ownable {
    using SafeMath for uint256;
    
    enum TASK {
        HARVEST_TRANSMUTER,
        HARVEST_ALCHEMIST,
        FLUSH_ALCHEMIST
    }

    IAlchemist public alchemist;
    ITransmuter public transmuter;
    IERC20 public underlying;

    TASK public nextTask;
    mapping(TASK => uint256) public lastCallForTask;

    bool public paused;

    uint256 public keeperDelay;

    constructor(IAlchemist _alchemist, ITransmuter _transmuter, IERC20 _underlying) {
        alchemist = _alchemist;
        transmuter = _transmuter;
        underlying = _underlying;
        nextTask = TASK.HARVEST_TRANSMUTER;
        keeperDelay = 1 days;
    }

    function setAlchemist(IAlchemist newAlchemist) external onlyOwner() {
        alchemist = newAlchemist;
    }

    function setTransmuter(ITransmuter newTransmuter) external onlyOwner() {
        transmuter = newTransmuter;
    }

    function setPause(bool pauseState) external onlyOwner() {
        paused = pauseState;
    }

    function setKeeperDelay(uint256 newKeeperDelay) external onlyOwner() {
        keeperDelay = newKeeperDelay;
    }

    function recoverFunds(IERC20 token) external onlyOwner() {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /// @dev check if the nextTask needs to be performed
    ///
    /// Returns FALSE if 1 day has not passed since last call
    /// Returns FALSE if certain economic criteria are not met
    ///
    /// @param checkData input data to check (not used)
    ///
    /// @return upkeepNeeded if upkeep is needed
    /// @return performData the task to perform
    function checkUpkeep(bytes calldata checkData) external view override returns (
        bool upkeepNeeded,
        bytes memory performData
    ) {
        if (!paused && block.timestamp.sub(lastCallForTask[nextTask]) >= keeperDelay) {
            return (true, abi.encode(nextTask));
        } else {
            return (false, abi.encode(0x0));
        }
    }

    /// @dev perform a task that needs upkeep
    ///
    /// @param performData the task to be performed
    function performUpkeep(bytes calldata performData) external override {
        TASK task;
        (task) = abi.decode(performData, (TASK));
        if (!paused && block.timestamp.sub(lastCallForTask[task]) >= keeperDelay) {
            if (task == TASK.HARVEST_TRANSMUTER) {
                harvestTransmuter();
            } else if (task == TASK.HARVEST_ALCHEMIST) {
                harvestAlchemist();
            } else if (task == TASK.FLUSH_ALCHEMIST) {
                flushAlchemist();
            }
        }
    }

    function harvestTransmuter() internal {
        if (!transmuter.pause()) {
            uint256 vaultId = transmuter.vaultCount() - 1;
            address vaultAdaptor = transmuter.getVaultAdapter(vaultId);
            uint256 vaultTotalDep = transmuter.getVaultTotalDeposited(vaultId);
            uint256 totalValue = IVaultAdaptor(vaultAdaptor).totalValue();
            if (totalValue > vaultTotalDep) {
                transmuter.harvest(vaultId);
            }
        }
        nextTask = TASK.HARVEST_ALCHEMIST;
        lastCallForTask[TASK.HARVEST_TRANSMUTER] = block.timestamp;
    }

    function harvestAlchemist() internal {
        if (!alchemist.emergencyExit()) {
            uint256 vaultId = alchemist.vaultCount() - 1;
            address vaultAdaptor = alchemist.getVaultAdapter(vaultId);
            uint256 vaultTotalDep = alchemist.getVaultTotalDeposited(vaultId);
            uint256 totalValue = IVaultAdaptor(vaultAdaptor).totalValue();
            if (totalValue > vaultTotalDep) {
                alchemist.harvest(vaultId);
            }
        }
        nextTask = TASK.FLUSH_ALCHEMIST;
        lastCallForTask[TASK.HARVEST_ALCHEMIST] = block.timestamp;
    }

    function flushAlchemist() internal {
        if (!alchemist.emergencyExit() && underlying.balanceOf(address(alchemist)) > 0) {
            alchemist.flush();
        }
        nextTask = TASK.HARVEST_TRANSMUTER;
        lastCallForTask[TASK.FLUSH_ALCHEMIST] = block.timestamp;
    }
}

pragma solidity 0.8.4;

interface IKeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external
        returns (
            bool upkeepNeeded,
            bytes memory performData
        );

    function performUpkeep(
        bytes calldata performData
    ) external;
}

pragma solidity 0.8.4;

import {IVaultHolder} from "./IVaultHolder.sol";

interface IAlchemist is IVaultHolder {
    function flush() external;
    function emergencyExit() external view returns (bool);
}

pragma solidity 0.8.4;

import {IVaultHolder} from "./IVaultHolder.sol";

interface ITransmuter is IVaultHolder {
    function pause() external view returns (bool);
    function setKeepers(address[] calldata _keepers, bool[] calldata _states) external;
}

pragma solidity 0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVaultAdaptor {
    function underlying() external view returns (IERC20);
    function totalValue() external view returns (uint256);
    function totalDeposited() external view returns (uint256);
    function harvest(address rewards) external;
    function deposit(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

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

pragma solidity 0.8.4;

interface IVaultHolder {
    function harvest(uint256 vaultId) external;
    function vaultCount() external view returns (uint256);
    function getVaultAdapter(uint256 vaultId) external view returns (address);
    function getVaultTotalDeposited(uint256 vaultId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}