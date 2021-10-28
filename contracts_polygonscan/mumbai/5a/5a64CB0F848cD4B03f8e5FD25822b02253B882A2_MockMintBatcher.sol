// SPDX-License-Identifier:NO-LICENSE

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../lib/DepositBatcherLib.sol";
import {DepositBatch, BatchStatus} from "../type/Batch.sol";

/**
 * @title MockBatcher
 * @author SmartDeFi
 * @dev test contract for batching test.
 */

contract MockMintBatcher is Context, ReentrancyGuard {
    using DepositBatcherLib for DepositBatch;
    uint256 public currentBatch;
    IERC20 public usdc;

    mapping(uint256 => DepositBatch) private _batch;

    event Mint(
        address user,
        bytes[] protocols,
        uint256[] amounts,
        uint256 total,
        uint256 batchId
    );

    constructor(address _usdc) {
        usdc = IERC20(_usdc);
    }

    function mint(
        bytes[] memory protocols,
        uint256[] memory amounts,
        uint256 total
    ) public virtual nonReentrant returns (bool) {
        address user = _msgSender();

        require(usdc.balanceOf(user) >= total, "Error: Insufficient Balance");
        require(
            usdc.allowance(user, address(this)) >= total,
            "Error: Insufficient Allowance"
        );

        bool transfer = usdc.transferFrom(user, address(this), total);
        bool update = _batch[currentBatch].insert(
            user,
            total,
            protocols,
            amounts
        );

        emit Mint(user, protocols, amounts, total, currentBatch);
        return transfer && update;
    }

    function fetchUsersInBatch(uint256 batchId, bytes memory protocol)
        public
        view
        virtual
        returns (address[] memory)
    {
        DepositBatch storage b = _batch[batchId];
        return b.users[protocol];
    }

    function fetchProtocolsInBatch(uint256 batchId)
        public
        view
        virtual
        returns (bytes[] memory)
    {
        DepositBatch storage b = _batch[batchId];
        return b.protocols;
    }

    function fetchTotalDepositInBatch(uint256 batchId)
        public
        view
        virtual
        returns (uint256)
    {
        DepositBatch storage b = _batch[batchId];
        return b.total;
    }

    function fetch(uint256 batchId) public view virtual returns (uint256) {
        DepositBatch storage b = _batch[batchId];
        return b.total;
    }
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

    constructor() {
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

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.8;

// Type Imports
import {DepositBatch} from "../type/Batch.sol";
import {Errors} from "./helpers/Error.sol";

/**
 * @title Deposit Batcher Library
 * @author SmartDefi
 * @dev This is a library contract for handling user deposits in a specific protocol during
 * the minting process.
 *
 * [TIP]: It's main purpose is to make sure the contract processes are gas efficient.
 */

library DepositBatcherLib {
    /**
     * @dev validates if the sum of children is always equal to the
     * parent.
     *
     * [TIP]: For validating if the total USDC deposit is equal to the
     * sum of deposits of USDC in each individual protocol.
     */
    modifier validate(uint256 parent, uint256[] memory children) {
        uint256 looplen = children.length;
        uint256 total = 0;
        for (uint256 i = 0; i < looplen; i++) {
            total += children[i];
        }
        require(total == parent, "Lib Error: minting amount mismatch");
        _;
    }

    /**
     * @dev checks for hit-miss chances and maintains the batchInfo including
     * - total USDC deposits in batch
     * - protocols included in the batch
     * - mapping of protocols to USDC
     * - deposit of every user in individual protocols
     * - users deposited in each protocol in a batch
     *
     * @param self represents the Batch Struct.
     * @param user refers to the address of the gnosis-safe of user.
     * @param total refers to the total USDC deposit
     * @param amount refers the amount of USDC in each protocol.
     * @param protocols refers to the different protocols.
     *
     * @return bool representing the status of the process.
     *
     * [TIP]: the above information is most predominantly used
     * for sending information via data tunnels & distribution of minted tokens
     * back to user's safes without spending much gas & avoid LOOPS.
     */
    function insert(
        DepositBatch storage self,
        address user,
        uint256 total,
        bytes[] memory protocols,
        uint256[] memory amount
    ) internal validate(total, amount) returns (bool) {
        // validate protocols & amount length
        require(protocols.length != amount.length, Errors.VL_INVALID_DEPOSIT);

        for (uint256 i = 0; i < protocols.length; i++) {
            bytes memory protocol = protocols[i];

            if (!self.created[protocol]) {
                self.protocols.push(protocol);
                self.created[protocol] = true;
            }

            if (self.individualUser[protocol][user] == 0) {
                self.users[protocol].push(user);
            }

            self.tokens[protocol] += amount[i];
            self.individualUser[protocol][user] += amount[i];
            self.total += amount[i];
        }

        return true;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.8;

/**
 * @dev declares the required structures & enumerators.
 */
enum BatchStatus {
    LIVE,
    BATCHED,
    RECIEVED,
    DISTRIBUTED
}

struct DepositBatch {
    bytes[] protocols;
    uint256 total;
    BatchStatus status;
    mapping(bytes => bool) created;
    mapping(bytes => uint256) tokens;
    mapping(bytes => address[]) users;
    mapping(bytes => mapping(address => uint256)) individualUser;
}

struct WithdrawBatch {
    address[] tokens;
    BatchStatus status;
    mapping(address => bool) created;
    mapping(address => uint256) user;
    mapping(address => address[]) users;
    mapping(address => uint256) total;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Errors library
 * @author SmartDefi
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - AC = AccessContract
 */

library Errors {
    string public constant VL_INVALID_DEPOSIT = "1"; // 'The sum of deposits in each protocol should be equal to the total'
    string public constant VL_INSUFFICIENT_BALANCE = "2"; // 'The user doesn't have enough balance of tokens'

    string public constant VL_INSUFFICIENT_ALLOWANCE = "3"; // 'The spender doesn't have enough allowance of tokens'
    string public constant VL_BATCH_NOT_ELLIGIBLE = "4"; // The current batch Id doesn't have the ability for current operation
    string public constant VL_INVALID_PROTOCOL = "5"; // The protocol address is not found in factory.
    string public constant VL_ZERO_ADDRESS = "6"; // 'The sum of deposits in each protocol should be equal to the total'
    string public constant VL_INVALID_SUM = "7"; // 'The sum of deposits in each protocol should be equal to the total'

    string public constant AC_INVALID_GOVERNOR = "8"; // The caller is not governor of the whitelist contract.
    string public constant AC_INVALID_ROUTER = "9"; // The caller is not a valid router contract.
    string public constant AC_USER_NOT_WHITELISTED = "10"; // The caller is not a valid router contract.
}