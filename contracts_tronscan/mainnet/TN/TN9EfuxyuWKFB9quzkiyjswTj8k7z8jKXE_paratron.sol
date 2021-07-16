//SourceUnit: paratron.sol

pragma solidity ^0.5.4;

interface ITRC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function balanceOf(address _target) external view returns (uint256);
    function allowance(address _target, address _spender) external view returns (uint256);
}

// File: contracts/Interface/IMint.sol

pragma solidity ^0.5.4;

interface IMint {
    function mint(uint256 _value) external returns (bool);
    function finishMint() external returns (bool);
}

// File: contracts/Interface/IBurn.sol

pragma solidity ^0.5.4;

interface IBurn {
    function burn(uint256 _value) external returns(bool);
}

// File: contracts/Library/Ownable.sol

pragma solidity ^0.5.4;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
    function owner() external view returns (address) {
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
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
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

// File: contracts/Library/SafeMath.sol

pragma solidity ^0.5.4;

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
    function sub(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
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
    function div(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
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
    function mod(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/Library/Freezer.sol

pragma solidity ^0.5.4;

contract Freezer is Ownable {
    event Freezed(address dsc);
    event Unfreezed(address dsc);

    mapping(address => bool) public freezing;

    modifier isFreezed(address src) {
        require(freezing[src] == false, "Freeze/Fronzen-Account");
        _;
    }

    /**
    * @notice The Freeze function sets the transfer limit
    * for a specific address.
    * @param dsc address The specify address want to limit the transfer.
    */
    function freeze(address dsc) external onlyOwner {
        require(dsc != address(0), "Freeze/Zero-Address");
        require(freezing[dsc] == false, "Freeze/Already-Freezed");

        freezing[dsc] = true;

        emit Freezed(dsc);
    }

    /**
    * @notice The Freeze function removes the transfer limit
    * for a specific address.
    * @param dsc address The specify address want to remove the transfer.
    */
    function unFreeze(address dsc) external onlyOwner {
        require(freezing[dsc] == true, "Freeze/Already-Unfreezed");

        delete freezing[dsc];

        emit Unfreezed(dsc);
    }
}

// File: contracts/Library/Pauser.sol

pragma solidity ^0.5.4;

contract Pauser is Ownable {
    event Pause(address pauser);
    event Resume(address resumer);

    bool public pausing;

    modifier isPause() {
        require(pausing == false, "Pause/Pause-Functionality");
        _;
    }

    function pause() external onlyOwner {
        require(pausing == false, "Pause/Already-Pausing");

        pausing = true;

        emit Pause(msg.sender);
    }

    function resume() external onlyOwner {
        require(pausing == true, "Pause/Already-Resuming");

        pausing = false;

        emit Resume(msg.sender);
    }
}

// File: contracts/Library/Locker.sol

pragma solidity ^0.5.4;




contract Locker is Ownable {
    event LockedUp(address target, uint256 value);

    using SafeMath for uint256;

    mapping(address => uint256) public lockup;

    modifier isLockup(address _target, uint256 _value) {
        uint256 balance = ITRC20(address(this)).balanceOf(_target);
        require(
            balance.sub(_value, "Locker/Underflow-Value") >= lockup[_target],
            "Locker/Impossible-Over-Lockup"
        );
        _;
    }

    function lock(address target, uint256 value) internal onlyOwner returns (bool) {
        lockup[target] = lockup[target].add(value);
        emit LockedUp(target, lockup[target]);
    }

    function decreaseLockup(address target, uint256 value) external onlyOwner returns (bool) {
        require(lockup[target] > 0, "Locker/Not-Lockedup");

        lockup[target] = lockup[target].sub(value, "Locker/Impossible-Underflow");

        emit LockedUp(target, lockup[target]);
    }

    function deleteLockup(address target) external onlyOwner returns (bool) {
        require(lockup[target] > 0, "Locker/Not-Lockedup");

        delete lockup[target];

        emit LockedUp(target, 0);
    }
}

// File: contracts/Library/Minter.sol

pragma solidity ^0.5.4;



contract Minter is Ownable {
    event Finished();

    bool public minting;

    modifier isMinting() {
        require(minting == true, "Minter/Finish-Minting");
        _;
    }

    constructor() public {
        minting = true;
    }

    function finishMint() external onlyOwner returns (bool) {
        require(minting == true, "Minter/Already-Finish");

        minting = false;

        emit Finished();

        return true;
    }
}

// File: contracts/paratron.sol

pragma solidity ^0.5.4;

/**
 * @title paratron
 * @notice The contract implements the TRC20 specification of DuckCoin. It implements "Mint"
 * and "Burn" functions incidentally. "Mint" can only be called by the Owner of the
 * corresponding Contract, and "Burn" can be called by any Token owner. Owner of the
 * contract can use "Pauser" to stop working, "Freezer" to freeze accounts and "Locker"
 * to maintain Token minimum balance for some owners.
 */
contract paratron is ITRC20, IMint, IBurn, Ownable, Freezer, Pauser, Locker, Minter {
    using SafeMath for uint256;

    string public constant name = "paratron";
    string public constant symbol = "PRON";
    uint8 public constant decimals = 6;
    uint256 public totalSupply = 1000000000;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private approved;

    constructor() public Minter() {
        totalSupply = totalSupply.mul(10**uint256(decimals));
        balances[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value)
        external
        isFreezed(msg.sender)
        isLockup(msg.sender, value)
        isPause
        returns (bool)
    {
        require(to != address(0), "paratron/Not-Allow-Zero-Address");

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferWithLockup(address to, uint256 value)
        external
        onlyOwner
        isLockup(msg.sender, value)
        isPause
        returns (bool)
    {
        require(to != address(0), "paratron/Not-Allow-Zero-Address");

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        lock(to, value);

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        external
        isFreezed(from)
        isLockup(from, value)
        isPause
        returns (bool)
    {
        require(from != address(0), "paratron/Not-Allow-Zero-Address");
        require(to != address(0), "paratron/Not-Allow-Zero-Address");

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        approved[from][msg.sender] = approved[from][msg.sender].sub(value);

        emit Transfer(from, to, value);

        return true;
    }

    function mint(uint256 value) external isMinting onlyOwner isPause returns (bool) {
        totalSupply = totalSupply.add(value);
        balances[msg.sender] = balances[msg.sender].add(value);

        emit Transfer(address(0), msg.sender, value);

        return true;
    }

    function burn(uint256 value) external isPause returns (bool) {
        require(value <= balances[msg.sender], "paratron/Not-Allow-Unvalued-Burn");

        balances[msg.sender] = balances[msg.sender].sub(value);
        totalSupply = totalSupply.sub(value);

        emit Transfer(msg.sender, address(0), value);

        return true;
    }

    function approve(address spender, uint256 value) external isPause returns (bool) {
        require(spender != address(0), "paratron/Not-Allow-Zero-Address");
        approved[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    function balanceOf(address target) external view returns (uint256) {
        return balances[target];
    }

    function allowance(address target, address spender) external view returns (uint256) {
        return approved[target][spender];
    }
}