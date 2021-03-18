// SPDX-License-Identifier: WTFPL
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

// Inheritance
import "@openzeppelin/contracts/access/Ownable.sol";
import "../helpers/ERC20Staking.sol";

// Interfaces
import "../interfaces/ERC1155/interfaces/IERC1155TokenReceiver.sol";
import "../interfaces/ILootCitadel.sol";

/**
 * @title Expansion ItemsCraft
 * @author TheLootMaster
 * @notice Stake LOOT to earn gold and craft items
 * @dev Manages staking of LOOT to earn rewards points for minting ERC1155 items
 */
contract ExpansionItemsCraft is ERC20Staking, Ownable {
    /***********************************|
    |   Libraries                       |
    |__________________________________*/
    using SafeMath for uint256;

    /***********************************|
    |   Constants                       |
    |__________________________________*/
    // Citadel
    ILootCitadel public citadel;

    // Points
    bool public priceLockup;
    uint256 public pointsPerDay;

    // Administation
    mapping(uint256 => bool) public exists;
    mapping(uint256 => uint256) public items;

    // User Rewards
    mapping(address => uint256) public points;
    mapping(address => uint256) public lastUpdateTime;

    /***********************************|
    |   Events                          |
    |__________________________________*/

    /**
     * @notice Staked
     * @dev Event fires when user stakes LOOT for earning points
     */
    event Staked(address user, uint256 amount);

    /**
     * @notice Withdrawl
     * @dev Event fires when user withdrew LOOT from staking
     */
    event Withdrawl(address user, uint256 amount);

    /**
     * @notice ItemAdded
     * @dev Event fires when a new item is added to crafing catalog
     */
    event ItemAdded(uint256 item, uint256 cost);

    /**
     * @notice ItemUpdated
     * @dev Event fires when the cost of item crafting is updated
     */
    event ItemUpdated(uint256 item, uint256 cost);

    /**
     * @notice ItemRemoved
     * @dev Event fires when the item can no longer be crafted
     */
    event ItemRemoved(uint256 item);

    /**
     * @notice ItemCrafted
     * @dev Event fires when a user burns points for item crafting
     */
    event ItemCrafted(uint256 item, address user);

    /***********************************|
    |   Modifiers                       |
    |__________________________________*/
    /**
     * @notice Update users reward balance
     * @dev Set the expansion confiration parameters
     * @param account Citadel target address
     */
    modifier updateReward(address account) {
        if (account != address(0)) {
            points[account] = earned(account);
            lastUpdateTime[account] = block.timestamp;
        }
        _;
    }

    /***********************************|
    |   Constructor                     |
    |__________________________________*/

    /**
     * @notice Smart Contract Constructor
     * @dev Set the expansion confiration parameters
     * @param _citadel Citadel target address
     * @param _loot loot address
     * @param _pointsPerDay loot address
     */
    constructor(
        address _citadel,
        address _loot,
        uint256 _pointsPerDay
    ) public ERC20Staking(_loot) {
        citadel = ILootCitadel(_citadel);
        pointsPerDay = _pointsPerDay;
    }

    /***********************************|
    |   Points and Staking              |
    |__________________________________*/

    /**
     * @notice Calculates earned points
     * @dev Streams points to users every second by dividing pointsPerDay by 86400
     * @param account Address of user
     * @return Points calculated at current block timestamp.
     */
    function earned(address account) public view returns (uint256) {
        uint256 blockTime = block.timestamp;

        return
            points[account].add(
                blockTime
                    .sub(lastUpdateTime[account])
                    .mul(pointsPerDay)
                    .div(86400)
                    .mul(balanceOf(account).div(1e18))
            );
    }

    /**
     * @notice Update pointsPerDay for each staked LOOT
     * @dev The points are streamed each second by dividing by 86400
     * @param _pointsPerDay Points per day with 18 decimals
     * @return True
     */
    function updatePointsPerDay(uint256 _pointsPerDay)
        external
        onlyOwner
        returns (bool)
    {
        // Set Points Allocation
        pointsPerDay = _pointsPerDay;

        return true;
    }

    /**
     * @notice Stake LOOT in Expansion ItemsCraft
     * @dev Stakes designated token using the ERC20Staking methods
     * @param amount Amount of LOOT to stake
     * @return Amount stake
     */
    function stake(uint256 amount)
        external
        updateReward(msg.sender)
        returns (uint256)
    {
        // Enforce 100,000 LOOT Staked
        require(
            amount.add(balanceOf(msg.sender)) <= 100000 ether,
            "Staking Limited to 100,000 LOOT"
        );

        // Stake LOOT
        _stake(amount);

        // Emit Staked
        emit Staked(msg.sender, amount);

        return amount;
    }

    /**
     * @notice Withdraw LOOT from ItemCraft.
     * @dev Withdraws designated token using the ERC20Staking methods
     * @param amount Amount of LOOT to withdraw
     * @return Amount withdrawn
     */
    function withdraw(uint256 amount)
        external
        updateReward(msg.sender)
        returns (uint256)
    {
        // Check User Staked Balance
        require(amount <= balanceOf(msg.sender));

        // Withdraw Staked LOOT
        _withdraw(amount);

        // Emit Withdrawl
        emit Withdrawl(msg.sender, amount);
    }

    /**
     * @notice Enables priceLockup
     * @dev Permanently prevents owner from updating the cost of item crafting.
     * @return Current priceLock boolean state
     */
    function enablePriceLock() external onlyOwner returns (bool) {
        require(priceLockup == false);
        priceLockup = true;
        return priceLockup;
    }

    /****************************************|
    |   Items                       |
    |_______________________________________*/

    /**
     * @notice Add Item and Crafting Cost
     * @dev Adds a items availabled in an existing ERC1155 smart contact.
     * @param id Item ID
     * @param cost Points to redeem Item
     * @return True
     */
    function addItem(uint256 id, uint256 cost) public onlyOwner returns (bool) {
        // Check if item exists or is being updated
        if (exists[id] == false) {
            // Set Item Cost
            items[id] = cost;

            // Set Creator
            exists[id] = true;

            // Emit ItemAdded
            emit ItemAdded(id, cost);
        } else {
            // Price Lockup is not activated
            require(!priceLockup, "Item Price Locked");

            // Set Item Cost
            items[id] = cost;

            // Emit ItemUpdated
            emit ItemUpdated(id, cost);
        }

        return true;
    }

    /**
     * @notice Batch ddd Items and Crafting Costs
     * @dev Adds a items availabled in an existing ERC1155 smart contact.
     * @param ids Item IDs
     * @param costs Points to craft items
     * @return True
     */
    function addItemBatch(uint256[] calldata ids, uint256[] calldata costs)
        external
        onlyOwner
        returns (bool)
    {
        // IDs and Cost Arrays length Match
        require(ids.length == costs.length);

        // Iterate Items and Crafting Cost
        for (uint256 index = 0; index < ids.length; index++) {
            addItem(ids[index], costs[index]);
        }

        return true;
    }

    /**
     * @notice Remove craftable item
     * @dev Prevents item from being crafted by setting crafting cost to zero
     * @param id Item ID
     * @return True
     */
    function removeItem(uint256 id) external onlyOwner returns (bool) {
        // Item Cost Set to Zero
        items[id] = 0;

        // Emit ItemRemoved
        emit ItemRemoved(id);

        return true;
    }

    /**
     * @notice Crafts item using earned points
     * @dev Mints a new ERC1155 item by calling the Citadel with the MINTER role.
     * Updates the users earned points before executing the crafting process.
     * @param id Item ID
     * @return True
     */
    function redeem(uint256 id)
        external
        updateReward(msg.sender)
        returns (bool)
    {
        // Check Item Is Available to Craft
        require(items[id] != 0, "Item Unavailable");

        // Sufficient User Points
        require(points[msg.sender] >= items[id], "Insufficient Points");

        // Update User Points
        points[msg.sender] = points[msg.sender].sub(items[id]);

        // Mint Item
        citadel.alchemy(msg.sender, id, 1);

        // Emit ItemCrafted
        emit ItemCrafted(id, msg.sender);

        return true;
    }
}

// SPDX-License-Identifier: MIT

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: WTFPL
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract ERC20Staking {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Target token for staking
    IERC20 public ERC20;

    constructor(address _ERC20) public {
        ERC20 = IERC20(_ERC20);
    }

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /**
     * @notice Total stake tokens
     * @dev The total of tokens staked for all accounts
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Account staked amount
     * @dev Amount of tokens currently staked
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Stake Token
     * @dev Stakes designated token
     * @param amount Amount of token to stake
     * @return true
     */
    function _stake(uint256 amount) internal virtual returns (bool) {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        ERC20.transferFrom(msg.sender, address(this), amount);

        return true;
    }

    /**
     * @notice Withdraw Token
     * @dev Withdraw designated token
     * @param amount Amount of token to withdraw
     * @return true
     */
    function _withdraw(uint256 amount) internal virtual returns (bool) {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        ERC20.transfer(msg.sender, amount);

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {
    /**
     * @notice Handle the receipt of a single ERC1155 token type
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value MUST result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _id        The id of the token being transferred
     * @param _amount    The amount of tokens being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) external returns (bytes4);

    /**
     * @notice Handle the receipt of multiple ERC1155 token types
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value WILL result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeBatchTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _ids       An array containing ids of each token being transferred
     * @param _amounts   An array containing amounts of each token being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: WTFPL
pragma solidity ^0.6.0;

abstract contract ILootCitadel {
    /**
     * @dev Call alchemy for ERC20 token.
     * @param to Receiver of rewards
     * @param amount Amount of rewards
     */
    function alchemy(address to, uint256 amount) external virtual;

    /**
     * @dev Call alchemy for ERC1155 token.
     * @param to Receiver of rewards
     * @param id Item ID
     * @param amount Amount of rewards
     */
    function alchemy(
        address to,
        uint256 id,
        uint256 amount
    ) external virtual;

    /**
     * @dev Call alchemy for ERC721 token.
     * @param to Receiver of rewards
     * @param tokenId Token Identification Number
     */
    function alchemy721(address to, uint256 tokenId) external virtual;

    /**
     * @dev Get current expansion balance
     * @param expansion Receiver of rewards
     */
    function expansionBalance(address expansion)
        external
        virtual
        returns (uint256);
}

// SPDX-License-Identifier: MIT

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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