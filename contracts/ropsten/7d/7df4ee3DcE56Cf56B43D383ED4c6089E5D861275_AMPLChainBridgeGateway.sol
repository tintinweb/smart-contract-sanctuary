// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAmpleforth} from "uFragments/contracts/interfaces/IAmpleforth.sol";
import {ITokenVault} from "../../_interfaces/ITokenVault.sol";
import {IBridgeGateway} from "../../_interfaces/IBridgeGateway.sol";

/**
 * @title AMPLChainBridgeGateway: AMPL-ChainBridge Gateway Contract
 * @dev This contract is deployed on the base chain (Ethereum).
 *
 *      It's a pass-through contract between the ChainBridge handler contract and
 *      the Ampleforth policy and the Token vault.
 *
 *      The contract is owned by the ChainBridge handler contract.
 *
 *      When rebase is transmitted across the bridge, It checks the consistency of rebase data
 *      from the ChainBridge handler contract with the recorded on-chain value.
 *
 *      When a sender initiates a cross-chain AMPL transfer from the
 *      current chain (source chain) to a target chain through chain-bridge,
 *      `validateAndLock` is executed.
 *      It validates if total supply reported is consistent with the
 *      recorded on-chain value and locks AMPLS in a token vault.
 *
 *      When a sender has initiated a cross-chain AMPL transfer from a source chain
 *      to a recipient on the current chain (target chain),
 *      chain-bridge executes the `unlock` function.
 *      The amount of tokens to be unlocked to the recipient is calculated based on
 *      the globalAMPLSupply on the source chain, at the time of transfer initiation
 *      and the total ERC-20 AMPL supply on the current chain, at the time of unlock.
 *
 */
contract AMPLChainBridgeGateway is IBridgeGateway, Ownable {
    using SafeMath for uint256;

    address public immutable ampl;
    address public immutable policy;
    address public immutable vault;

    /**
     * @dev Validates if the data from the handler is consistent with the
     *      recorded value on the current chain.
     * @param globalAmpleforthEpoch Ampleforth monetary policy epoch.
     * @param globalAMPLSupply AMPL ERC-20 total supply.
     */
    function validateRebaseReport(uint256 globalAmpleforthEpoch, uint256 globalAMPLSupply)
        external
        onlyOwner
    {
        uint256 recordedGlobalAmpleforthEpoch = IAmpleforth(policy).epoch();
        uint256 recordedGlobalAMPLSupply = IERC20(ampl).totalSupply();

        require(
            globalAmpleforthEpoch == recordedGlobalAmpleforthEpoch,
            "AMPLChainBridgeGateway: epoch not consistent"
        );
        require(
            globalAMPLSupply == recordedGlobalAMPLSupply,
            "AMPLChainBridgeGateway: total supply not consistent"
        );

        emit XCRebaseReportOut(globalAmpleforthEpoch, globalAMPLSupply);
    }

    /**
     * @dev Validates the data from the handler and transfers specified amount from
     *      the sender's wallet and locks it in the vault contract.
     * @param sender Address of the sender wallet on the base chain.
     * @param recipientAddressInTargetChain Address of the recipient wallet in the target chain.
     * @param amount Amount of tokens to be locked on the current chain (source chain).
     * @param globalAMPLSupply AMPL ERC-20 total supply at the time of transfer locking.
     */
    function validateAndLock(
        address sender,
        address recipientAddressInTargetChain,
        uint256 amount,
        uint256 globalAMPLSupply
    ) external onlyOwner {
        uint256 recordedGlobalAMPLSupply = IERC20(ampl).totalSupply();

        require(
            globalAMPLSupply == recordedGlobalAMPLSupply,
            "AMPLChainBridgeGateway: total supply not consistent"
        );

        ITokenVault(vault).lock(ampl, sender, amount);

        emit XCTransferOut(sender, amount, recordedGlobalAMPLSupply);
    }

    /**
     * @dev Calculates the amount of amples to be unlocked based on the share of total supply and
     *      transfers it to the recipient.
     * @param senderAddressInSourceChain Address of the sender wallet in the transaction originating chain.
     * @param recipient Address of the recipient wallet in the current chain (target chain).
     * @param amount Amount of tokens that were {locked/burnt} on the base chain.
     * @param globalAMPLSupply AMPL ERC-20 total supply at the time of transfer.
     */
    function unlock(
        address senderAddressInSourceChain,
        address recipient,
        uint256 amount,
        uint256 globalAMPLSupply
    ) external onlyOwner {
        uint256 recordedGlobalAMPLSupply = IERC20(ampl).totalSupply();
        uint256 unlockAmount = amount.mul(recordedGlobalAMPLSupply).div(globalAMPLSupply);

        emit XCTransferIn(recipient, globalAMPLSupply, unlockAmount, recordedGlobalAMPLSupply);

        ITokenVault(vault).unlock(ampl, recipient, unlockAmount);
    }

    constructor(
        address bridgeHandler,
        address ampl_,
        address policy_,
        address vault_
    ) public {
        ampl = ampl_;
        policy = policy_;
        vault = vault_;

        transferOwnership(bridgeHandler);
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

// pragma solidity ^0.4.24;

// Public interface definition for the Ampleforth supply policy on Ethereum (the base-chain)
interface IAmpleforth {
    function epoch() external view returns (uint256);

    function lastRebaseTimestampSec() external view returns (uint256);

    function inRebaseWindow() external view returns (bool);

    function globalAmpleforthEpochAndAMPLSupply() external view returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

interface ITokenVault {
    function lock(
        address token,
        address depositor,
        uint256 amount
    ) external;

    function unlock(
        address token,
        address recipient,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

/*
    INTERFACE NAMING CONVENTION:

    Base Chain: Ethereum; chain where actual AMPL tokens are locked/unlocked
    Satellite Chain: (tron, acala, ..); chain where xc-ample tokens are mint/burnt

    Source chain: Chain where a cross-chain transaction is initiated. (any chain ethereum, tron, acala ...)
    Target chain: Chain where a cross-chain transaction is finalized. (any chain ethereum, tron, acala ...)

    If a variable is prefixed with recorded: It refers to the existing value on the current-chain.
    eg) When rebase is reported to tron through a bridge, globalAMPLSupply is the new value
    reported through the bridge and recordedGlobalAMPLSupply refers to the current value on tron.

    On the Base chain:
    * ampl.totalSupply is the globalAMPLSupply.

    On Satellite chains:
    * xcAmple.totalSupply returns the current supply of xc-amples in circulation
    * xcAmple.globalAMPLSupply returns the chain's copy of the base chain's globalAMPLSupply.
*/

interface IBridgeGateway {
    // Logged on the base chain gateway (ethereum) when rebase report is propagated out
    event XCRebaseReportOut(
        uint256 globalAmpleforthEpoch, // epoch from the Ampleforth Monetary Policy on the base chain
        uint256 globalAMPLSupply // totalSupply of AMPL ERC-20 contract on the base chain
    );

    // Logged on the satellite chain gateway (tron, acala, near) when bridge reports most recent rebase
    event XCRebaseReportIn(
        uint256 globalAmpleforthEpoch, // new value coming in from the base chain
        uint256 globalAMPLSupply, // new value coming in from the base chain
        uint256 recordedGlobalAmpleforthEpoch, // existing value on the satellite chain
        uint256 recordedGlobalAMPLSupply // existing value on the satellite chain
    );

    // Logged on source chain when cross-chain transfer is initiated
    event XCTransferOut(
        address sender, // user sending funds
        uint256 amount, // amount to be locked/burnt
        uint256 recordedGlobalAMPLSupply // existing value on the current source chain
    );

    // Logged on target chain when cross-chain transfer is completed
    event XCTransferIn(
        address recipient, // user receiving funds
        uint256 globalAMPLSupply, // value on remote chain when transaction was initiated
        uint256 amount, // amount to be unlocked/mint
        uint256 recordedGlobalAMPLSupply // existing value on the current target chain
    );
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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