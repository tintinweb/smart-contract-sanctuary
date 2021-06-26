/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;

            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Bridge is OwnableUpgradeSafe {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => bool) public _isAdmin;
    mapping(address => bool) public _isOracle;

    mapping(address => SwapPair) public _registered;
    address[] public _registeredList;

    struct SwapPair {
        bool exists;
        bool paused;
        string destTokenAddr;
        uint256 fee;
        address feeAddr;
        uint256 dailyLimit;
        mapping(address => bool) tokenAdmin;
        mapping(address => bool) blacklist;
        mapping(address => uint256) swappedDayLast;
        mapping(address => uint256) swappedAmountLast;
    }

    mapping(string => bool) public _filledTx;

    bool public _paused;

    event SwapPairRegistered(
        address indexed srcTokenAddr,
        string name,
        string symbol,
        uint8 decimals,
        string destTokenAddr,
        uint256 fee,
        address feeAddr
    );

    event SwapPairModified(
        address indexed srcTokenAddr,
        string name,
        string symbol,
        uint8 decimals,
        string destTokenAddr,
        uint256 fee,
        address feeAddr
    );

    event SwapPairUnregistered(address indexed srcTokenAddr);

    event SwapPairPaused(address indexed srcTokenAddr);

    event SwapPairUn_paused(address indexed srcTokenAddr);

    event SwapStarted(
        address indexed srcTokenAddr,
        address indexed fromAddr,
        string toAddr, //tron address
        uint256 amount,
        uint256 feeAmount
    );

    event SwapFilled(
        address indexed srcTokenAddr,
        string destTxHash,
        address toAddress,
        uint256 amount
    );

    event Recovered(
        address srcTokenAddr,
        address to,
        uint256 amount,
        string txId
    );

    function initialize() public initializer {
        __Ownable_init();
        _isAdmin[_msgSender()] = true;
        _paused = true;
    }

    modifier onlyAdmin() {
        require(_isAdmin[_msgSender()], "onlyAdmin - Sender is not an Admin");
        _;
    }

    function setAdmin(address user, bool admin) public onlyOwner {
        _isAdmin[user] = admin;
    }

    modifier onlyOracle() {
        require(
            _isOracle[_msgSender()],
            "onlyOracle - Sender is not an Oracle"
        );
        _;
    }

    function setOracle(address user, bool oracle) public onlyAdmin {
        _isOracle[user] = oracle;
    }

    function isTokenAdmin(address srcTokenAddr, address user)
        public
        view
        returns (bool)
    {
        require(
            _registered[srcTokenAddr].exists,
            "isTokenAdmin - Token not registered"
        );
        return _registered[srcTokenAddr].tokenAdmin[user];
    }

    function setTokenAdmin(
        address srcTokenAddr,
        address user,
        bool admin
    ) public onlyAdmin {
        require(
            _registered[srcTokenAddr].exists,
            "setTokenAdmin - Token not registered"
        );
        _registered[srcTokenAddr].tokenAdmin[user] = admin;
    }

    function isBlacklisted(address srcTokenAddr, address user)
        public
        view
        returns (bool)
    {
        require(
            _registered[srcTokenAddr].exists,
            "isBlacklisted - Token not registered"
        );
        return _registered[srcTokenAddr].blacklist[user];
    }

    function setBlacklisted(
        address srcTokenAddr,
        address user,
        bool blacklisted
    ) public onlyAdmin {
        require(
            _registered[srcTokenAddr].exists,
            "setBlacklisted - Token not registered"
        );
        _registered[srcTokenAddr].blacklist[user] = blacklisted;
    }

    function pause() public onlyAdmin {
        _paused = true;
    }

    function unpause() public onlyAdmin {
        _paused = false;
    }

    function registerSwapPair(
        address srcTokenAddr,
        string calldata destTokenAddr,
        uint256 fee,
        address feeAddr,
        uint256 dailyLimit,
        bool paused
    ) external onlyAdmin returns (bool) {
        require(
            !_registered[srcTokenAddr].exists,
            "registerSwapPair - Already registered"
        );

        string memory name = IERC20(srcTokenAddr).name();
        string memory symbol = IERC20(srcTokenAddr).symbol();
        uint8 decimals = IERC20(srcTokenAddr).decimals();

        require(bytes(name).length > 0, "registerSwapPair - Empty name");
        require(bytes(symbol).length > 0, "registerSwapPair - Empty symbol");

        SwapPair storage sp = _registered[srcTokenAddr];

        sp.exists = true;
        sp.paused = paused;
        sp.destTokenAddr = destTokenAddr;
        sp.fee = fee;
        sp.feeAddr = feeAddr;
        sp.dailyLimit = dailyLimit;

        _registeredList.push(srcTokenAddr);

        emit SwapPairRegistered(
            srcTokenAddr,
            name,
            symbol,
            decimals,
            destTokenAddr,
            fee,
            feeAddr
        );
        return true;
    }

    function modifySwapPair(
        address srcTokenAddr,
        string calldata destTokenAddr,
        uint256 fee,
        address feeAddr,
        uint256 dailyLimit
    ) external onlyAdmin returns (bool) {
        require(
            _registered[srcTokenAddr].exists,
            "modifySwapPair - Token not registered"
        );

        string memory name = IERC20(srcTokenAddr).name();
        string memory symbol = IERC20(srcTokenAddr).symbol();
        uint8 decimals = IERC20(srcTokenAddr).decimals();

        require(bytes(name).length > 0, "registerSwapPair - Empty name");
        require(bytes(symbol).length > 0, "registerSwapPair - Empty symbol");

        SwapPair storage sp = _registered[srcTokenAddr];

        sp.destTokenAddr = destTokenAddr;
        sp.fee = fee;
        sp.feeAddr = feeAddr;
        sp.dailyLimit = dailyLimit;

        emit SwapPairModified(
            srcTokenAddr,
            name,
            symbol,
            decimals,
            destTokenAddr,
            fee,
            feeAddr
        );
        return true;
    }

    function unregisterSwapPair(address srcTokenAddr)
        external
        onlyAdmin
        returns (bool)
    {
        require(
            _registered[srcTokenAddr].exists,
            "unregisterSwapPair - Token not registered"
        );

        delete _registered[srcTokenAddr];

        for (uint256 i = 0; i < _registeredList.length; i++) {
            if (_registeredList[i] == srcTokenAddr) {
                _registeredList[i] = _registeredList[
                    _registeredList.length.sub(1)
                ];
                _registeredList.pop();
                break;
            }
        }

        emit SwapPairUnregistered(srcTokenAddr);
        return true;
    }

    function pauseSwapPair(address srcTokenAddr) external onlyAdmin {
        require(
            _registered[srcTokenAddr].exists,
            "pauseSwapPair - Token not registered"
        );
        _registered[srcTokenAddr].paused = true;
        emit SwapPairPaused(srcTokenAddr);
    }

    function unpauseSwapPair(address srcTokenAddr) external onlyAdmin {
        require(
            _registered[srcTokenAddr].exists,
            "unpauseSwapPair - Token not registered"
        );
        _registered[srcTokenAddr].paused = false;
        emit SwapPairUn_paused(srcTokenAddr);
    }

    function fill(
        string[] calldata destTxHash,
        address[] calldata tokenAddr,
        address[] calldata toAddress,
        uint256[] calldata amount
    ) external onlyOracle returns (bool) {
        require(destTxHash.length == tokenAddr.length, "Fill - invalid input");
        require(destTxHash.length == toAddress.length, "Fill - invalid input");
        require(destTxHash.length == amount.length, "Fill - invalid input");

        for (uint8 i = 0; i < destTxHash.length; i++) {
            require(
                _registered[tokenAddr[i]].exists,
                "Fill - Token not registered"
            );
            require(!_filledTx[destTxHash[i]], "Fill - TX filled already");

            _filledTx[destTxHash[i]] = true;
            IERC20(tokenAddr[i]).transfer(toAddress[i], amount[i]);

            emit SwapFilled(
                tokenAddr[i],
                destTxHash[i],
                toAddress[i],
                amount[i]
            );
        }

        return true;
    }

    function _calculateTimestampDay(uint256 ts)
        internal
        pure
        returns (uint256)
    {
        return ts.sub(ts.mod(86400));
    }

    function _calculateDaySwapped(address srcTokenAddr, address user)
        internal
        view
        returns (uint256)
    {
        require(
            _registered[srcTokenAddr].exists,
            "_calculateDaySwapped - Token not registered"
        );

        SwapPair storage sp = _registered[srcTokenAddr];

        uint256 tsDay = _calculateTimestampDay(block.timestamp);

        if (sp.swappedDayLast[user] != tsDay) return 0;

        return sp.swappedAmountLast[user];
    }

    function swap(
        address srcTokenAddr,
        uint256 amount,
        string calldata toAddress
    ) external payable returns (bool) {
        require(!_paused, "Swap - Bridge paused");
        require(
            _registered[srcTokenAddr].exists,
            "Swap - Token not registered"
        );

        SwapPair storage sp = _registered[srcTokenAddr];

        require(!sp.blacklist[_msgSender()], "Swap - Blacklisted");

        if (!sp.tokenAdmin[_msgSender()]) {
            require(!sp.paused, "Swap - Token paused");
            require(
                !Address.isContract(_msgSender()),
                "Swap - Contract disallowed"
            );
            require(
                _msgSender() == tx.origin,
                "Swap - Proxy contract disallowed"
            );
        }

        require(msg.value == sp.fee, "Swap - Invalid fee sent");

        if (sp.dailyLimit > 0 && !sp.tokenAdmin[_msgSender()])
            require(
                _calculateDaySwapped(srcTokenAddr, _msgSender()).add(amount) <
                    sp.dailyLimit,
                "Swap - Amount exceeds daily limit"
            );

        require(
            IERC20(srcTokenAddr).allowance(_msgSender(), address(this)) >=
                amount,
            "Swap - Contract has not been approved for this amount"
        );

        IERC20(srcTokenAddr).transferFrom(_msgSender(), address(this), amount);
        if (msg.value != 0) {
            Address.sendValue(payable(sp.feeAddr), msg.value);
        }

        sp.swappedAmountLast[_msgSender()] = _calculateDaySwapped(
            srcTokenAddr,
            _msgSender()
        ).add(amount);
        sp.swappedDayLast[_msgSender()] = _calculateTimestampDay(
            block.timestamp
        );

        emit SwapStarted(
            srcTokenAddr,
            _msgSender(),
            toAddress,
            amount,
            msg.value
        );
        return true;
    }

    /*
     *
     * info() - called by frontend
     *
     * Returns :
     *
     * - bridge paused (bool)
     * - token address list (address)
     * - symbol list (string)
     * - decimal list (int)
     * - paused list (bool)
     * - balance list (int)
     * - fee list (int)
     * - daily limit list (int)
     * - daily swapped list (int)
     *
     */

    function info()
        external
        view
        returns (
            bool,
            address[] memory,
            string[] memory,
            uint8[] memory,
            bool[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        string[] memory symbolList = new string[](_registeredList.length);
        uint8[] memory decimalList = new uint8[](_registeredList.length);
        bool[] memory pausedList = new bool[](_registeredList.length);
        uint256[] memory balanceList = new uint256[](_registeredList.length);
        uint256[] memory feeList = new uint256[](_registeredList.length);
        uint256[] memory dailyLimitList = new uint256[](_registeredList.length);
        uint256[] memory dailySwappedList = new uint256[](
            _registeredList.length
        );

        for (uint256 i = 0; i < _registeredList.length; i++) {
            address t = _registeredList[i];

            if (!_registered[t].exists) continue;

            SwapPair storage sp = _registered[t];

            symbolList[i] = IERC20(t).symbol();
            decimalList[i] = IERC20(t).decimals();

            pausedList[i] = sp.paused;
            if (sp.tokenAdmin[_msgSender()]) pausedList[i] = false;

            balanceList[i] = IERC20(t).balanceOf(address(this));
            feeList[i] = sp.fee;

            dailyLimitList[i] = 0;
            if (!sp.tokenAdmin[_msgSender()]) {
                dailyLimitList[i] = sp.dailyLimit;
            }

            dailySwappedList[i] = _calculateDaySwapped(t, _msgSender());
        }
        return (
            _paused,
            _registeredList,
            symbolList,
            decimalList,
            pausedList,
            balanceList,
            feeList,
            dailyLimitList,
            dailySwappedList
        );
    }

    function infoAdmin(address user)
        external
        view
        onlyAdmin
        returns (
            address[] memory,
            bool[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        bool[] memory pausedList = new bool[](_registeredList.length);
        uint256[] memory balanceList = new uint256[](_registeredList.length);
        uint256[] memory dailyLimitList = new uint256[](_registeredList.length);
        uint256[] memory dailySwappedList = new uint256[](
            _registeredList.length
        );

        for (uint256 i = 0; i < _registeredList.length; i++) {
            address t = _registeredList[i];

            if (!_registered[t].exists) continue;

            SwapPair storage sp = _registered[t];

            pausedList[i] = sp.paused;
            if (sp.tokenAdmin[user]) pausedList[i] = false;

            balanceList[i] = IERC20(t).balanceOf(address(this));

            dailyLimitList[i] = 0;
            if (!sp.tokenAdmin[user]) {
                dailyLimitList[i] = sp.dailyLimit;
            }

            dailySwappedList[i] = _calculateDaySwapped(t, user);
        }
        return (
            _registeredList,
            pausedList,
            balanceList,
            dailyLimitList,
            dailySwappedList
        );
    }

    function recoverToken(
        address srcTokenAddr,
        address to,
        uint256 amount,
        string calldata txId
    ) external onlyAdmin {
        require(to != address(0));
        require(
            _registered[srcTokenAddr].exists,
            "recoverToken - Token not registered"
        );
        require(
            IERC20(srcTokenAddr).balanceOf(address(this)) >= amount,
            "recoverToken - Insufficient amount"
        );
        require(
            IERC20(srcTokenAddr).transfer(to, amount),
            "recoverToken - Transfer failed"
        );

        emit Recovered(srcTokenAddr, to, amount, txId);
    }

    function transferToken(
        address token,
        uint256 amount,
        address to
    ) public onlyOwner() {
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "transferToken - Insufficent token balance to transfer amount."
        );
        IERC20(token).transfer(to, amount);
    }

    function transfer(uint256 amount, address payable to) public onlyOwner() {
        require(
            address(this).balance >= amount,
            "transfer - Insufficent native token balance to transfer amount."
        );
        Address.sendValue(to, amount);
    }
}