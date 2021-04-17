// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Adminable is Context {
    address private _admin;

    event AdminshipTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    constructor() {
        address msgSender = _msgSender();
        _admin = msgSender;
        emit AdminshipTransferred(address(0), msgSender);
    }

    function admin() public view virtual returns (address) {
        return _admin;
    }

    modifier onlyAdmin() {
        require(admin() == _msgSender(), "Adminable: caller is not the admin");
        _;
    }

    function _transferAdminship(address newAdmin) internal {
        require(
            newAdmin != address(0),
            "Adminable: new admin is the zero address"
        );
        emit AdminshipTransferred(_admin, newAdmin);
        _admin = newAdmin;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IERC20Short.sol";
import "./Adminable.sol";
import "./NetworksPreset.sol";
import "./TokensPreset.sol";

contract CosmoFundErc20CrossChainSwap is
    Ownable,
    Adminable,
    Pausable,
    NetworksPreset,
    TokensPreset
{
    using SafeMath for uint256;
    bool public mintAndBurn;

    // swaps
    struct SwapInfo {
        bool enabled;
        uint256 received;
        uint256 sent;
    }
    mapping(uint256 => mapping(address => SwapInfo)) public swapInfo;

    // events
    event Swap(
        uint256 indexed netId,
        address indexed token,
        address indexed to,
        uint256 amount
    );
    event Withdrawn(
        uint256 indexed netId,
        address indexed token,
        address indexed to,
        uint256 amount
    );

    constructor(uint256 _networkThis, bool _mintAndBurn) {
        setup();
        networkThis = _networkThis;
        mintAndBurn = _mintAndBurn;
    }

    function setup() private {
        _addNetwork("Ethereum Mainnet");
        _addNetwork("Binance Smart Chain Mainnet");

        _addToken(
            0x27cd7375478F189bdcF55616b088BE03d9c4339c, // Ethereum Mainnet
            //0x60E5FfdE4230985757E5Dd486e33E85AfEfC557b, // BSC Mainnet
            "Cosmo Token (COSMO)"
        );
        _addToken(
            0xB9FDc13F7f747bAEdCc356e9Da13Ab883fFa719B, // Ethereum Mainnet
            //0x7A43397662e82a9C15D590f211347D2871B12bb7, // BSC Mainnet
            "CosmoMasks Power (CMP)"
        );
    }

    function swap(
        uint256 netId,
        address token,
        uint256 amount
    ) public whenNotPaused {
        swapCheckStatus(netId, token);

        address to = _msgSender();
        IERC20Short(token).transferFrom(to, address(this), amount);

        tokenInfo[token].received = tokenInfo[token].received.add(amount);
        swapInfo[netId][token].received = swapInfo[netId][token].received.add(
            amount
        );

        if (mintAndBurn) {
            IERC20Short(token).burn(amount);
        }

        emit Swap(netId, token, to, amount);
    }

    function swapFrom(
        uint256 netId,
        address token,
        address from,
        uint256 amount
    ) public whenNotPaused {
        swapCheckStatus(netId, token);

        address to = from;
        IERC20Short(token).transferFrom(to, address(this), amount);

        tokenInfo[token].received = tokenInfo[token].received.add(amount);
        swapInfo[netId][token].received = swapInfo[netId][token].received.add(
            amount
        );

        if (mintAndBurn) {
            IERC20Short(token).burn(amount);
        }

        emit Swap(netId, token, to, amount);
    }

    function swapWithPermit(
        uint256 netId,
        address token,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        swapCheckStatus(netId, token);

        address to = _msgSender();
        IERC20Short(token).permit(to, address(this), amount, deadline, v, r, s);
        IERC20Short(token).transferFrom(to, address(this), amount);

        tokenInfo[token].received = tokenInfo[token].received.add(amount);
        swapInfo[netId][token].received = swapInfo[netId][token].received.add(
            amount
        );

        if (mintAndBurn) {
            IERC20Short(token).burn(amount);
        }

        emit Swap(netId, token, to, amount);
    }

    function withdraw(
        uint256 netId,
        address token,
        address to,
        uint256 amount
    ) public onlyAdmin {
        if (mintAndBurn) {
            IERC20Short(token).mint(address(this), amount);
        }
        IERC20Short(token).transfer(to, amount);

        tokenInfo[token].sent = tokenInfo[token].sent.add(amount);
        swapInfo[netId][token].sent = swapInfo[netId][token].sent.add(amount);

        emit Withdrawn(netId, token, to, amount);
    }

    // networks
    function addNetwork(string memory description) public onlyOwner {
        _addNetwork(description);
    }

    function setNetworkStatus(uint256 netId, bool status) public onlyOwner {
        _setNetworkStatus(netId, status);
    }

    //  Tokens
    function addToken(address token, string memory description)
        public
        onlyOwner
    {
        _addToken(token, description);
    }

    function setTokenStatus(address token, bool status) public onlyOwner {
        _setTokenStatus(token, status);
    }

    // swaps
    function setSwapStatus(
        uint256 netId,
        address token,
        bool status
    ) public onlyOwner returns (bool) {
        return swapInfo[netId][token].enabled = status;
    }

    // get token swap status
    function isSwapEnabled(uint256 netId, address token)
        public
        view
        returns (bool)
    {
        return swapInfo[netId][token].enabled;
    }

    // get token swap status
    function swapStatus(uint256 netId, address token)
        public
        view
        returns (bool)
    {
        if (paused()) return false;
        if (!isNetworkEnabled(netId)) return false;
        if (!isTokenEnabled(token)) return false;
        if (!isSwapEnabled(netId, token)) return false;
        return true;
    }

    function swapCheckStatus(uint256 netId, address token)
        public
        view
        returns (bool)
    {
        require(
            netId != networkThis,
            "Swap inside the same network is impossible"
        );
        require(
            isNetworkEnabled(netId),
            "Swap is not enabled for this network"
        );
        require(isTokenEnabled(token), "Swap is not enabled for this token");
        require(
            isSwapEnabled(netId, token),
            "Swap of this token for this network not enabled"
        );
        return true;
    }

    // pause all swaps
    function pause() public onlyOwner {
        _pause();
    }

    // unpause all swaps
    function unpause() public onlyOwner {
        _unpause();
    }

    function withdrawUnaccountedTokens(address token) public onlyOwner {
        uint256 unaccounted;
        if (mintAndBurn) unaccounted = tokenBalance(token);
        else unaccounted = tokensUnaccounted(token);
        IERC20Short(token).transfer(_msgSender(), unaccounted);
    }

    function transferAdminship(address newAdmin) public virtual onlyOwner {
        _transferAdminship(newAdmin);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Short {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract NetworksPreset {
    using SafeMath for uint256;

    uint256 public networkThis;
    uint256 public networksTotal;

    struct NetworkInfo {
        bool enabled;
        string description;
    }
    mapping(uint256 => NetworkInfo) public networkInfo;

    function isNetworkEnabled(uint256 netId) public view returns (bool) {
        return networkInfo[netId].enabled;
    }

    function _addNetwork(string memory description) internal {
        networkInfo[networksTotal].enabled = false;
        networkInfo[networksTotal].description = description;
        networksTotal = networksTotal.add(1);
    }

    function _setNetworkStatus(uint256 netId, bool status) internal {
        networkInfo[netId].enabled = status;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IERC20Short.sol";

abstract contract TokensPreset {
    using SafeMath for uint256;

    uint256 public tokensTotal;

    struct TokenInfo {
        bool enabled;
        address token;
        string description;
        uint256 received;
        uint256 sent;
    }
    mapping(address => TokenInfo) public tokenInfo;
    mapping(uint256 => address) public tokenById;

    function isTokenEnabled(address token) public view returns (bool) {
        return tokenInfo[token].enabled;
    }

    function tokensUnaccounted(address token) public view returns (uint256) {
        uint256 balance = IERC20Short(token).balanceOf(address(this));
        uint256 received = tokenInfo[token].received;
        uint256 sent = tokenInfo[token].sent;
        return balance.sub(received.sub(sent));
    }

    function tokenBalance(address token) public view returns (uint256) {
        return IERC20Short(token).balanceOf(address(this));
    }

    function _addToken(address token, string memory description) internal {
        tokenInfo[token].enabled = false;
        tokenInfo[token].token = token;
        tokenInfo[token].description = description;
        tokenById[tokensTotal] = token;
        tokensTotal = tokensTotal.add(1);
    }

    function _setTokenStatus(address token, bool status) internal {
        tokenInfo[token].enabled = status;
    }
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
    constructor () {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}