pragma solidity 0.6.9;

import "./roles/Migrator.sol";
import "./library/SafeERC20.sol";
import "./library/SafeMath.sol";
import "./interfaces/IBank.sol";
import "./interfaces/IInvitePool.sol";
import "./dependencies/Ownable.sol";
import "./dependencies/Pausable.sol";

/**
* SPDX-License-Identifier: UNLICENSED
*/
contract master is Ownable, Pausable, Migrator {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public bank;
    address public usdt;
    address public invitePool;

    address _firstDistributeAddress;
    address _secondDistributeAddress;

    uint256 _firstPercentage;
    uint256 _secondPercentage;
    uint256 public constant MAX_PERCENTAGE = 100;

    struct Appointment {//预约信息
        uint256 amount;
        uint256 withdrawType;//0：提取本金，1：提取利润
        uint256 effectBlock;//可提取的区块
    }

    bool public AppointmentOn;
    address public admin;
    uint64 public block4TenDays;

    mapping(address => Appointment) public appointInfo;

    event Deposit(address indexed user, uint256 indexed amount);
    event Withdraw(address indexed user, uint256 indexed amount, uint256 indexed withdrawType);//0 : capital ,1 : income
    event Appoint(address indexed user, uint256 indexed amount, uint256 indexed withdrawType);//0 : capital ,1 : income

    constructor (address _bank, address _usdt, address _admin, address _invitePool, address _firstAddress, address _secondAddress) public {
        bank = _bank;
        usdt = _usdt;
        admin = _admin;
        invitePool = _invitePool;
        _firstDistributeAddress = _firstAddress;
        _secondDistributeAddress = _secondAddress;
        _firstPercentage = 5;
        _secondPercentage = 15;
        block4TenDays = 57600;
        AppointmentOn = false;
    }

    //-------------settings period--------------
    function setAppointment(bool status) public onlyOwner {
        AppointmentOn = status;
    }

    function setBank(address _bank) public onlyOwner {
        bank = _bank;
    }

    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }

    function setBlock4TenDays(uint64 _block4TenDays) public onlyOwner {
        block4TenDays = _block4TenDays;
    }

    function distributeDepositAddresses(address _firstAddress, address _secondAddress) external onlyOwner {
        require(_firstAddress != address(0), "distribute address to zero address");
        require(_secondAddress != address(0), "distribute address to zero address");
        _firstDistributeAddress = _firstAddress;
        _secondDistributeAddress = _secondAddress;
    }

    function firstDistributeAddress() external view returns(address) {
        return _firstDistributeAddress;
    }

    function secondDistributeAddress() external view returns(address) {
        return _secondDistributeAddress;
    }

    function distributeDepositPercentages(uint256 _firstPercent, uint256 _secondPercent) external onlyOwner {
        require(_firstPercent.add(_secondPercent) <= MAX_PERCENTAGE, "total percent is over 100");
        _firstPercentage = _firstPercent;
        _secondPercentage = _secondPercent;
    }

    function firstPercentage() external view returns(uint256) {
        return _firstPercentage;
    }

    function secondPercentage() external view returns(uint256) {
        return _secondPercentage;
    }

    //-------------for first period--------------
    function deposit(uint256 amount) public whenNotPaused {
        (address superOne,) = IInvitePool(invitePool).getUserInfo(msg.sender);
        require(superOne != address(0), "do not bind");
        require(amount >= 1000000000, "at least 1000 usdt");

        //分3%给地址1
        uint256 first = 0;
        if (_firstPercentage != 0) {
            first = amount.mul(_firstPercentage).div(MAX_PERCENTAGE);
            IERC20(usdt).safeTransferFrom(msg.sender, _firstDistributeAddress, first);
        }

        //分17%给地址2
        uint256 second = 0;
        if (_firstPercentage != 0) {
            second = amount.mul(_secondPercentage).div(MAX_PERCENTAGE);
            IERC20(usdt).safeTransferFrom(msg.sender, _secondDistributeAddress, second);
        }

        //剩余的给到资金池
        uint256 left = amount.sub(first).sub(second);
        if (left != 0) {
            IERC20(usdt).safeTransferFrom(msg.sender, bank, left);
        }

        //用户真正的入金信息
        IBank(bank).addCapital(msg.sender, amount);
        emit Deposit(msg.sender, amount);
    }

    function getUserInvestInfo(address user) public view returns (uint256 capital, uint256 withdrawedCapital, uint256 withdrawedIncome){
        (capital, withdrawedCapital, withdrawedIncome) = IBank(bank).userInvestInfo(user);
    }

    //------------for next period----------------
    //预约提取
    function appoint(address user, uint256 capitalInServer, uint256 amount, uint8 withdrawType) public whenNotPaused {
        require(AppointmentOn == true, "appoint is offline");
        require(msg.sender == admin, "only admin can appoint for you");
        require(withdrawType == 0 || withdrawType == 1, "invalid withdraw type");
        require(appointInfo[user].amount == 0, "last appoint is not withdraw");

        appointInfo[user].amount = amount;
        appointInfo[user].effectBlock = block.number.add(block4TenDays);
        appointInfo[user].withdrawType = withdrawType;

        (uint256 capital,,) = getUserInvestInfo(user);
        if (capitalInServer > capital) {
            IBank(bank).addCapital(user, capitalInServer.sub(capital));
        }

        emit Appoint(user, amount, withdrawType);
    }

    //提取
    function withdraw() public whenNotPaused {
        require(appointInfo[msg.sender].amount > 0, "correct appoint is required");
        require(appointInfo[msg.sender].effectBlock <= block.number, "block height not reached");

        if (appointInfo[msg.sender].withdrawType == 0) {
            IBank(bank).withdrawCapital(msg.sender, appointInfo[msg.sender].amount);
        }
        if (appointInfo[msg.sender].withdrawType == 1) {
            IBank(bank).withdrawIncome(msg.sender, appointInfo[msg.sender].amount);
        }

        appointInfo[msg.sender].amount = 0;
        emit Withdraw(msg.sender, appointInfo[msg.sender].amount, appointInfo[msg.sender].withdrawType);
    }

    function migrateAppointmentLegacy(
        address[] calldata addresses,
        uint256[] calldata amounts,
        uint256[] calldata withdrawTypes,
        uint256[] calldata effectBlocks
    ) external onlyOwner whenNotMigrated {
        require(addresses.length == amounts.length, "Migrate: cannot compare two arrays");
        require(addresses.length == withdrawTypes.length, "Migrate: cannot compare two arrays");
        require(addresses.length == effectBlocks.length, "Migrate: cannot compare two arrays");

        for (uint256 i = 0; i < addresses.length; i++) {
            _migrateOneAppointment(addresses[i], amounts[i], withdrawTypes[i], effectBlocks[i]);
        }
    }

    function _migrateOneAppointment(address _address, uint256 _amount, uint256 _withdrawType, uint256 _effectBlock) internal {
        require(_address != address(0), "Migrate: cannot migrate zero address");
        require(_withdrawType == 0 || _withdrawType == 1, "Migrate: invalid withdraw type");
        appointInfo[_address] = Appointment(_amount, _withdrawType, _effectBlock);
    }

}

pragma solidity 0.6.9;

import "../dependencies/Ownable.sol";

/**
* SPDX-License-Identifier: UNLICENSED
*/

/**
 * @dev Contract module which allows children to implement an migration
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotMigrated` and `whenMigrated`, which can be applied to
 * the functions of your contract. Note that they will not be migration by
 * simply including this module, only once the modifiers are put in place.
 */
contract Migrator is Ownable {
    /**
     * @dev Emitted when the migration is triggered by a migrator (`account`).
     */
    event Migrated(address account);

    /**
     * @dev Emitted when the migration is lifted by a migrator (`account`).
     */
    event UnMigrated(address account);

    bool private _migrated;

    /**
     * @dev Initializes the contract in un-migrated state. Assigns the migrator role
     * to the deployer.
     */
    constructor() internal {
        _migrated = false;
    }

    /**
     * @dev Returns true if the contract is migrated, and false otherwise.
     */
    function migrated() public view returns (bool) {
        return _migrated;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not migrated.
     */
    modifier whenNotMigrated() {
        require(!_migrated, "Migrator: migrated");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is migrated.
     */
    modifier whenMigrated() {
        require(_migrated, "Migrator: not migrated");
        _;
    }

    /**
     * @dev Called by a migrator to migrate, triggers stopped state.
     */
    function migrate() public onlyOwner whenNotMigrated {
        _migrated = true;
        emit Migrated(msg.sender);
    }

    /**
     * @dev Called by a migrator to un-migrate, returns to normal state.
     */
    function unMigrate() public onlyOwner whenMigrated {
        _migrated = false;
        emit UnMigrated(msg.sender);
    }
}

pragma solidity 0.6.9;

import "./SafeMath.sol";
import "../interfaces/IERC20.sol";

/**
* SPDX-License-Identifier: UNLICENSED
*/

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.6.9;

/**
* SPDX-License-Identifier: UNLICENSED
*/

/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

pragma solidity 0.6.9;

/**
* SPDX-License-Identifier: UNLICENSED
*/
interface IBank {
    function addCapital(address user, uint256 amount) external;

    function withdrawCapital(address user, uint256 amount) external;

    function withdrawIncome(address user, uint256 amount) external;

    function userInvestInfo(address user) external view returns (uint256, uint256, uint256);
}

pragma solidity 0.6.9;

/**
* SPDX-License-Identifier: UNLICENSED
*/
interface IInvitePool {
    function getUserInfo(address userAddr) external view returns (address superOne, uint256 first);
}

pragma solidity 0.6.9;

/**
* SPDX-License-Identifier: UNLICENSED
*/
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
	address private _owner;

	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor() internal {
		_owner = msg.sender;
		emit OwnershipTransferred(address(0), _owner);
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
		return msg.sender == _owner;
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
		require(
			newOwner != address(0),
			"Ownable: new owner is the zero address"
		);
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

pragma solidity 0.6.9;
import "./Ownable.sol";

/**
* SPDX-License-Identifier: UNLICENSED
*/
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Ownable {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor() internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

pragma solidity 0.6.9;

/**
* SPDX-License-Identifier: UNLICENSED
*/
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

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
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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
  "libraries": {}
}