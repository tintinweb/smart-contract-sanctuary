//SourceUnit: Address.sol

// SPDX-License-Identifier: MIT

/*
 * This file is part of the Autumn Cross-Chain Bridge Smart Contract
 *
 * The source is from OpenZeppelin
 * (https://github.com/autumn-finance/openzeppelin-contracts/blob/release-v2.5.0/contracts/utils/Address.sol)
 *
 * Applied Changes:
 *  - None
 */

pragma solidity ^0.5.8;

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
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

//SourceUnit: BridgeSource.sol

// SPDX-License-Identifier: MIT

/*
 * This file is part of the Autumn Cross-Chain Bridge Smart Contract
 */

pragma solidity ^0.5.8;

import { Witness } from "./Witness.sol";
import { IBridgeSource } from "./IBridgeSource.sol";
import { SafeERC20, IERC20, SafeMath } from "./SafeERC20.sol";

// This contract implements the source chain part of Cross-Chain Asset Bridge.
//
// Comprised by two parts:
// - Deposit / Withdraw
// - Witness / Approves
//
// Users can deposit without a restriction and the transaction will be actively
// found by the witness(es) who is keeping monitor on the contract.
//
// Then, the witness will submit witness on the target chain contract (not included
// within this file) and mint equivalent cross-chain asset (wBTC for example) to
// the address on the target chain specificed when deposit.
//
// Later, when the user can burn the cross-chain asset on the target chain,
// and it will be found by witness(es) and submit witness on this contract.
//
// When the witness count is enough (as specified by `minimumWitness`), the burning
// is identified as 'approved'. While an allowance of withdraw in the amount of
// the burnt equivalent cross-chain asset will be added to the source chain address
// (will be specificed by user when burning on the target chain) and user are
// able to withdraw his deposited asset.
//
// The witness program in both chains are in the similar way.
// `toSource` refers to the address on the source (current) chain
// `toX` refers to the address on the target (crossing) chain

contract BridgeSource is IBridgeSource, Witness {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Deposit Control

    /// @dev The minimum amount of asset to deposit
    uint256 public minimumDeposit;

    function setMinDeposit(uint256 minDeposit_) onlyOwner() external {
        minimumDeposit = minDeposit_;
    }

    // Asset
    
    IERC20 internal _asset;

    function asset() external view returns (address) {
        return address(_asset);
    }

    /**
     * @dev Whether the asset is the native currency on local chain
     */
    bool public native;

    // Fee Control

    /// @dev A fixed fee to be charged when deposit
    uint256 public feeFixed;

    /// @dev The allocated fee could be claimed
    uint256 public feeAllocated;

    /// @dev The recipient to receive the fee when claiming
    address payable public feeRecipient;

    function setFeeFixed(uint256 feeFixed_) onlyOwner() external {
        feeFixed = feeFixed_;
    }

    function setFeeRecipient(address payable recipient_) onlyOwner() external {
        feeRecipient = recipient_;
    }

    function claimAllocatedFee() external { // public
        require(feeRecipient != address(0), "No fee recipient");
        require(feeAllocated != 0, "No fee allocated yet");
        if (native) {
            feeRecipient.transfer(feeAllocated);
        } else {
            _asset.safeTransfer(feeRecipient, feeAllocated);
        }
        feeAllocated = 0;
    }

    constructor(address asset_, bool native_, uint256 minDeposit_) public {
        _asset = IERC20(asset_);
        native = native_;

        if (native) {
            // ensures asset is given correctly
            require(
                asset_ == address(0),
                "Asset should be zero address for native currency"
            );
        }
        
        minimumDeposit = minDeposit_;
    }

    bool public paused = false;

    function setPasued(bool paused_) onlyOwner() external {
        paused = paused_;
    }

    // IBridgeSource overrides

    function deposit(uint256 amount, string calldata toX) external payable {
        require(!paused, "Paused");
        uint256 amount_ = amount;
        if (native) {
            require(msg.value == amount_, "Inconsistent with amount and value");
        } else {
            require(msg.value == 0, "Non-native asset cannot have a value");

            uint256 before = _asset.balanceOf(address(this));
            _asset.safeTransferFrom(_msgSender(), address(this), amount_);
            amount_ = _asset.balanceOf(address(this)).sub(before);
        }

        require(amount_ >= minimumDeposit, "Amount smaller than minimum");
        amount_ = _chargeForFixedFee(amount_);

        emit Deposit(_msgSender(), toX, toX, amount_);
    }

    function _chargeForFixedFee(uint256 amount) private returns (uint256) {
        require(amount > feeFixed, "Amount less than fee");
        amount = amount.sub(feeFixed);
        feeAllocated = feeAllocated.add(feeFixed);
        return amount;
    }

    // Witness overrides

    function onWitnessApproved(string memory txHash, address payable to, uint256 amount) internal {
        txHash;
        _withdrawTo(to, amount);
    }

    /// @dev This need strict requirement checks
    function _withdrawTo(address payable to, uint256 amount) private {
        if (native) {
            to.transfer(amount);
        } else {
            IERC20(_asset).safeTransfer(to, amount);
        }
    }
}

//SourceUnit: Context.sol

// SPDX-License-Identifier: MIT

/*
 * This file is part of the Autumn Cross-Chain Bridge Smart Contract
 *
 * The source is from OpenZeppelin
 * (https://github.com/autumn-finance/openzeppelin-contracts/blob/release-v2.5.0/contracts/GSN/Context.sol)
 *
 * Applied Changes:
 *  - None
 */

pragma solidity ^0.5.8;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

//SourceUnit: IBridgeSource.sol

// SPDX-License-Identifier: MIT

/*
 * This file is part of the Autumn Cross-Chain Bridge Smart Contract
 */

pragma solidity ^0.5.8;

/**
 * @dev Source chain interface of the bridge
 */
interface IBridgeSource {
    /**
     * @dev The asset in the source chain for crossing
     */
    function asset() external view returns (address);

    // Entrances

    /**
     * @dev Deposit for minting cross-chain asset to the target cross-chain address
     */
    function deposit(uint256 amount, string calldata toX) external payable;

    // Events

    /// @dev Emits when a deposit is succeed (not sync to the target chain yet)
    event Deposit(address from, string indexed toX, string toXPlain, uint256 amount);
}

//SourceUnit: IERC20.sol

// SPDX-License-Identifier: MIT

/*
 * This file is part of the Autumn Cross-Chain Bridge Smart Contract
 *
 * The source is from OpenZeppelin
 * (https://github.com/autumn-finance/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/IERC20.sol)
 *
 * Applied Changes:
 *  - None
 */

pragma solidity ^0.5.8;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

//SourceUnit: Ownable.sol

// SPDX-License-Identifier: MIT

/*
 * This file is part of the Autumn Cross-Chain Bridge Smart Contract
 *
 * The source is from OpenZeppelin
 * (https://github.com/autumn-finance/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol)
 *
 * Applied Changes:
 *  - None
 */

pragma solidity ^0.5.8;

import "./Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//SourceUnit: SafeERC20.sol

// SPDX-License-Identifier: MIT

/*
 * This file is part of the Autumn Cross-Chain Bridge Smart Contract
 *
 * The source is from OpenZeppelin
 * (https://github.com/autumn-finance/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/SafeERC20.sol)
 *
 * Applied Changes:
 *  - None
 */

pragma solidity ^0.5.8;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

/*
 * This file is part of the Autumn Cross-Chain Bridge Smart Contract
 *
 * The source is from OpenZeppelin
 * (https://github.com/autumn-finance/openzeppelin-contracts/blob/release-v2.5.0/contracts/math/SafeMath.sol)
 *
 * Applied Changes:
 *  - None
 */

pragma solidity ^0.5.8;

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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//SourceUnit: Witness.sol

// SPDX-License-Identifier: MIT

/*
 * This file is part of the Autumn Cross-Chain Bridge Smart Contract
 */

pragma solidity ^0.5.8;

import { Ownable } from "./Ownable.sol";
import { SafeMath } from "./SafeMath.sol";

// A decentralized verification implementation for
// approving allowance for withdraw or mint of the Cross-Chain Bridge

contract Witness is Ownable {
    using SafeMath for uint256;

    bytes constant internal NO_ERROR = new bytes(0);

    /*
     * Storage
     */

    struct WitnessData {
        // Whether the burn is witnessed by enough witnesses
        bool approved;

        // The local chain address to receive the witness allowance
        address to;

        // The burnt amount of equivalent cross-chain assets
        uint256 amount;

        // the witness count of this burnt
        uint256 witness;
    }

    /// @dev Burn transaction hash to its data
    mapping (string => WitnessData) public witnessData;

    /// @dev All witnesses of burns
    mapping (string => address[]) public txWitnesses;

    function listWitnessesOf(string calldata hash) external view returns (address[] memory) {
        return txWitnesses[hash];
    }

    /*
     * Control
     */

    /// @dev the minimum amount of witness required to approve a burn
    uint256 minimumWitness;

    function setMinimumWitness(uint256 min) onlyOwner() external {
        minimumWitness = min;
    }

    /*
     * Permission
     */

    /// @dev The permission of witness accounts
    mapping (address => bool) public witnessPermission;

    /// @dev The array of all witnesses for quering
    address[] public witnessList;

    function listWitnesses() external view returns (address[] memory) {
        return witnessList;
    }

    function setWitnessPermission(address guy, bool permit) onlyOwner() external {
        require(witnessPermission[guy] != permit, "Permission already set");
        witnessPermission[guy] = permit;

        if (permit) {
            witnessList.push(guy);
        } else {
            uint256 atArray;
            for (uint256 i = 0; i < witnessList.length; i++) {
                if (witnessList[i] == guy) {
                    atArray = i;
                    break;
                }
            }
            witnessList[atArray] = witnessList[witnessList.length - 1];
            witnessList.pop();
        }

        emit WitnessPermissionUpdated(guy, permit);
    }

    event WitnessPermissionUpdated(address witness, bool permit);

    /*
     * Entrances
     */

     /**
     * @dev Checks the eligibility of the witness to verify the deposit transaction
     *
     *  It checks following requirements:
     *  - The witness account have correct permission
     *  - The deposit transaction have not been approved yet
     *  - The witness have not verified this deposit before
     */
    function canWitness(address guy, string memory hash)
        public
        view
        returns (bytes memory error)
    {
        if (!witnessPermission[guy]) {
            return "No permission";
        }

        if (witnessData[hash].approved) {
            return "Already approved";
        }

        address[] memory witnesses_ = txWitnesses[hash];
        for (uint256 i = 0; i < witnesses_.length; i++) {
            if (witnesses_[i] == guy) {
                return "Already witnessed";
            }
        }

        return NO_ERROR;
    }

    /**
     * @notice Witness a burn on the other chain with target account on the local chain
     *  Call `canWitness` to check the eligibility
     */
    function witness(string calldata hash, address payable to, uint256 amount)
        external
        returns (bool)
    {
        bytes memory error = canWitness(_msgSender(), hash);
        require(error.length == 0, string(error));

        WitnessData memory data = witnessData[hash];

        // setup the amount and to, all witness have to be the same for one tx
        if (data.amount == 0) {
            witnessData[hash].amount = amount;
            witnessData[hash].to = to;
        } else {
            // something was wrong, need a restart
            require(data.amount == amount, "Witness amount inconsistent");
            require(data.to == to, "Witness to inconsistent");
        }

        txWitnesses[hash].push(_msgSender());
        uint256 count = witnessData[hash].witness = data.witness.add(1);
        emit WitnessVisited(hash, hash, to, amount, _msgSender());

        // check for witness count
        if (count >= minimumWitness) {
            witnessData[hash].approved = true;
            onWitnessApproved(hash, to, amount);
            emit WitnessApproved(hash, hash, to, amount);
        }

        return true;
    }

    function onWitnessApproved(string memory txHash, address payable to, uint256 amount) internal;

    /// @dev Emits when a tx finally approved by enough witnesses
    event WitnessApproved(string indexed txHash, string txHashPlain, address indexed to, uint256 amount);

    /// @dev Emits everytime when a witness applied to the (unapprove yet) tx
    event WitnessVisited (string indexed txHash, string txHashPlain, address indexed to, uint256 amount, address witness);

    /**
     * @dev Forcily restart the witness program to a cross-chain tx
     *  in case it got stuck due to amount inconsistent, etc.
     */
    function restartWitness(string calldata hash)
        onlyOwner()
        external
    {
        require(!witnessData[hash].approved, "Transaction already approved");
        delete witnessData[hash];
        delete txWitnesses[hash];
    }
}