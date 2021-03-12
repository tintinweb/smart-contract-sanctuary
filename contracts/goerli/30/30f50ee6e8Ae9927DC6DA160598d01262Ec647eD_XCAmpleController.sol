// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import {
    SafeMathUpgradeable
} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {
    SignedSafeMathUpgradeable
} from "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {UInt256Lib} from "./UInt256Lib.sol";
import {IXCAmple} from "../../_interfaces/IXCAmple.sol";
import {IXCAmpleSupplyPolicy} from "../../_interfaces/IXCAmpleSupplyPolicy.sol";
import {IBatchTxExecutor} from "../../_interfaces/IBatchTxExecutor.sol";

/**
 * @title XC(Cross-Chain)Ample Controller
 * @dev This component administers the XCAmple ERC20 token contract.
 *      It maintains a set of white-listed bridge gateway contracts which
 *      have the ability to `mint` and `burn` xcAmples. It also performs
 *      rebase on XCAmple, based on updated AMPL supply reported through
 *      the bridge gateway.
 */
contract XCAmpleController is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;
    using UInt256Lib for uint256;

    event GatewayMint(
        address indexed bridgeGateway,
        address indexed recipient,
        uint256 xcAmpleAmount
    );

    event GatewayBurn(
        address indexed bridgeGateway,
        address indexed depositor,
        uint256 xcAmpleAmount
    );

    event GatewayRebaseReported(
        address indexed bridgeGateway,
        uint256 indexed epoch,
        uint256 globalAMPLSupply,
        uint256 timestampSec
    );

    event LogRebase(uint256 indexed epoch, int256 requestedSupplyAdjustment, uint256 timestampSec);

    event GatewayWhitelistUpdated(address indexed bridgeGateway, bool active);

    // Reference to the cross-chain ample token contract.
    address public xcAmple;

    // This module executes downstream notifications and
    // returns if all the notifications were executed successfully.
    address public rebaseRelayer;

    // The number of rebase cycles since inception of AMPL.
    uint256 public globalAmpleforthEpoch;

    // The timestamp when xcAmple rebase was executed.
    uint256 public lastRebaseTimestampSec;

    // The information about the most recent AMPL rebase reported through the bridge gateway
    uint256 public nextGlobalAmpleforthEpoch;
    uint256 public nextGlobalAMPLSupply;

    // White-list of trusted bridge gateway contracts
    mapping(address => bool) public whitelistedBridgeGateways;

    modifier onlyBridgeGateway() {
        require(
            whitelistedBridgeGateways[msg.sender],
            "XCAmpleController: Bridge gateway not whitelisted"
        );
        _;
    }

    /**
     * @notice Adds bridge gateway contract address to whitelist.
     * @param bridgeGateway The address of the bridge gateway contract.
     */
    function addBridgeGateway(address bridgeGateway) external onlyOwner {
        whitelistedBridgeGateways[bridgeGateway] = true;
        emit GatewayWhitelistUpdated(bridgeGateway, true);
    }

    /**
     * @notice Removes bridge gateway contract address from whitelist.
     * @param bridgeGateway The address of the bridge gateway contract.
     */
    function removeBridgeGateway(address bridgeGateway) external onlyOwner {
        whitelistedBridgeGateways[bridgeGateway] = false;
        emit GatewayWhitelistUpdated(bridgeGateway, false);
    }

    /**
     * @notice Sets the reference to the rebaseRelayer.
     * @param rebaseRelayer_ The address of the rebaseRelayer contract.
     */
    function setRebaseRelayer(address rebaseRelayer_) external onlyOwner {
        rebaseRelayer = rebaseRelayer_;
    }

    /**
     * @notice Mint xcAmples to a recipient.
     * @dev Bridge mints xcAmples on this satellite chain.
     *
     * @param recipient The address of the recipient.
     * @param xcAmpleAmount The amount of xcAmples to be mint on this chain.
     */
    function mint(address recipient, uint256 xcAmpleAmount) external onlyBridgeGateway {
        IXCAmpleSupplyPolicy(xcAmple).mint(recipient, xcAmpleAmount);
        emit GatewayMint(msg.sender, recipient, xcAmpleAmount);
    }

    /**
     * @notice Burn xcAmples from depositor.
     * @dev Bridge burns xcAmples on this satellite chain.
     *
     * @param depositor The address of the depositor.
     * @param xcAmpleAmount The amount of xcAmples to be burnt on this chain.
     */
    function burn(address depositor, uint256 xcAmpleAmount) external onlyBridgeGateway {
        IXCAmpleSupplyPolicy(xcAmple).burn(depositor, xcAmpleAmount);
        emit GatewayBurn(msg.sender, depositor, xcAmpleAmount);
    }

    /**
     * @notice Upcoming rebase information reported by a bridge gateway and updated in storage.
     * @param nextGlobalAmpleforthEpoch_ The new epoch after rebase on the base chain.
     * @param nextGlobalAMPLSupply_ The new globalAMPLSupply after rebase on the base chain.
     */
    function reportRebase(uint256 nextGlobalAmpleforthEpoch_, uint256 nextGlobalAMPLSupply_)
        external
        onlyBridgeGateway
    {
        nextGlobalAmpleforthEpoch = nextGlobalAmpleforthEpoch_;
        nextGlobalAMPLSupply = nextGlobalAMPLSupply_;

        emit GatewayRebaseReported(
            msg.sender,
            nextGlobalAmpleforthEpoch,
            nextGlobalAMPLSupply,
            now
        );
    }

    /**
     * @notice A multi-chain AMPL interface method. The Ampleforth monetary policy contract
     *         on the base-chain and XCAmpleController contracts on the satellite-chains
     *         implement this method. It atomically returns two values:
     *         what the current contract believes to be,
     *         the globalAmpleforthEpoch and globalAMPLSupply.
     * @return globalAmpleforthEpoch The recorded global Ampleforth epoch.
     * @return globalAMPLSupply The recorded global AMPL supply.
     */
    function globalAmpleforthEpochAndAMPLSupply() external view returns (uint256, uint256) {
        return (globalAmpleforthEpoch, IXCAmple(xcAmple).globalAMPLSupply());
    }

    /**
     * @notice Initiate a new rebase operation.
     * @dev Once the Bridge gateway reports new epoch and total supply Rebase can be triggered on this satellite chain.
     *      The supply delta is calculated as the difference between the new reported globalAMPLSupply
     *      and the recordedGlobalAMPLSupply on this chain.
     *      After rebase, it notifies down-stream platforms by executing post-rebase callbacks
     *      on the rebase relayer.
     */
    function rebase() external {
        // recently reported epoch needs to be more than current globalEpoch in storage
        require(
            nextGlobalAmpleforthEpoch > globalAmpleforthEpoch,
            "XCAmpleController: Epoch not new"
        );

        // the globalAMPLSupply recorded on this chain
        int256 recordedGlobalAMPLSupply = IXCAmple(xcAmple).globalAMPLSupply().toInt256Safe();

        // execute rebase on this chain
        IXCAmpleSupplyPolicy(xcAmple).rebase(nextGlobalAmpleforthEpoch, nextGlobalAMPLSupply);

        // calculate supply delta
        int256 supplyDelta = nextGlobalAMPLSupply.toInt256Safe().sub(recordedGlobalAMPLSupply);

        // update state variables on this chain
        globalAmpleforthEpoch = nextGlobalAmpleforthEpoch;
        lastRebaseTimestampSec = now;

        // log rebase event
        emit LogRebase(globalAmpleforthEpoch, supplyDelta, lastRebaseTimestampSec);

        // executes callbacks only when the rebaseRelayer reference is set
        if (rebaseRelayer != address(0)) {
            require(IBatchTxExecutor(rebaseRelayer).executeAll());
        }
    }

    /**
     * @dev ZOS upgradable contract initialization method.
     *      It is called at the time of contract creation to invoke parent class initializers and
     *      initialize the contract's state variables.
     * @param xcAmple_ reference to the cross-chain ample token erc-20 contract
     * @param globalAmpleforthEpoch_ the epoch number from monetary policy on the base chain
     */
    function initialize(address xcAmple_, uint256 globalAmpleforthEpoch_) external initializer {
        __Ownable_init();

        xcAmple = xcAmple_;
        globalAmpleforthEpoch = globalAmpleforthEpoch_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMathUpgradeable {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

/**
 * @title Various utilities useful for uint256.
 * https://github.com/ampleforth/uFragments/blob/master/contracts/lib/UInt256Lib.sol
 */
library UInt256Lib {
    uint256 private constant MAX_INT256 = uint256(type(int256).max);

    /**
     * @dev Safely converts a uint256 to an int256.
     */
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        require(a <= MAX_INT256, "UInt256Lib: int256 overflow");
        return int256(a);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import "uFragments/contracts/interfaces/IAMPL.sol";

interface IXCAmple is IAMPL {
    function globalAMPLSupply() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

interface IXCAmpleSupplyPolicy {
    function rebase(uint256 globalAmpleforthEpoch_, uint256 globalAMPLSupply_)
        external
        returns (uint256);

    function mint(address who, uint256 value) external;

    function burn(address who, uint256 value) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

interface IBatchTxExecutor {
    function executeAll() external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// pragma solidity ^0.4.24;

// Public interface definition for the AMPL - ERC20 token on Ethereum (the base-chain)
interface IAMPL {
    // ERC20
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner_, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    // EIP-2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    // Elastic token interface
    function scaledBalanceOf(address who) external view returns (uint256);

    function scaledTotalSupply() external view returns (uint256);

    function transferAll(address to) external returns (bool);

    function transferAllFrom(address from, address to) external returns (bool);
}