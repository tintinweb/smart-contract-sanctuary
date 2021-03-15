// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {IBridgeGateway} from "../../_interfaces/IBridgeGateway.sol";
import {IXCAmpleController} from "../../_interfaces/IXCAmpleController.sol";
import {IXCAmpleControllerGateway} from "../../_interfaces/IXCAmpleControllerGateway.sol";
import {IXCAmple} from "../../_interfaces/IXCAmple.sol";

/**
 * @title ChainBridgeXCAmpleGateway
 * @dev This contract is deployed on the satellite EVM chains eg). tron, acala, near etc.
 *
 *      It's a pass-through contract between the ChainBridge handler contract and
 *      the xc-ample controller contract.
 *
 *      When rebase is transmitted across the bridge,
 *      It forwards the next rebase report to the xc-ample controller.
 *
 *      When a sender initiates a cross-chain AMPL transfer from a
 *      source chain to a recipient on the current chain (target chain)
 *      the xc-amples are mint into the recipient's wallet.
 *      The amount of tokens to be mint is calculated based on the globalAMPLSupply
 *      on a source chain at the time of transfer and the,
 *      globalAMPLSupply recorded on the current chain at the time of minting.
 *
 *      When a sender initiates a cross-chain AMPL transfer from the current chain (source chain)
 *      to a recipient on a target chain, chain-bridge executes the `validateAndBurn`.
 *      It validates if the total supply reported is consistent with the recorded on-chain value
 *      and burns xc-amples from the sender's wallet.
 *
 */
contract ChainBridgeXCAmpleGateway is IBridgeGateway, Ownable {
    using SafeMath for uint256;

    address public immutable xcAmple;
    address public immutable xcController;

    /**
     * @dev Forwards the most recent rebase information from the bridge handler to the xc-ample controller.
     * @param globalAmpleforthEpoch Ampleforth monetary policy epoch from the base chain.
     * @param globalAMPLSupply AMPL ERC-20 total supply from the base chain.
     */
    function reportRebase(uint256 globalAmpleforthEpoch, uint256 globalAMPLSupply)
        external
        onlyOwner
    {
        uint256 recordedGlobalAmpleforthEpoch = IXCAmpleController(xcController)
            .globalAmpleforthEpoch();

        uint256 recordedGlobalAMPLSupply = IXCAmple(xcAmple).globalAMPLSupply();

        emit XCRebaseReportIn(
            globalAmpleforthEpoch,
            globalAMPLSupply,
            recordedGlobalAmpleforthEpoch,
            recordedGlobalAMPLSupply
        );

        IXCAmpleControllerGateway(xcController).reportRebase(
            globalAmpleforthEpoch,
            globalAMPLSupply
        );
    }

    /**
     * @dev Calculates the amount of xc-amples to be mint based on the amount and the total supply
     *      on the base chain when the transaction was initiated
     *      and mints xc-amples to the recipient.
     * @param senderAddressInSourceChain Address of the sender wallet in the transaction originating chain.
     * @param recipient Address of the recipient wallet in the current chain (target chain).
     * @param amount Amount of tokens that were {locked/burnt} on the source chain.
     * @param globalAMPLSupply AMPL ERC-20 total supply at the time of transfer.
     */
    function mint(
        address senderAddressInSourceChain,
        address recipient,
        uint256 amount,
        uint256 globalAMPLSupply
    ) external onlyOwner {
        uint256 recordedGlobalAMPLSupply = IXCAmple(xcAmple).globalAMPLSupply();
        uint256 mintAmount = amount.mul(recordedGlobalAMPLSupply).div(globalAMPLSupply);

        emit XCTransferIn(recipient, globalAMPLSupply, mintAmount, recordedGlobalAMPLSupply);

        IXCAmpleControllerGateway(xcController).mint(recipient, mintAmount);
    }

    /**
     * @dev Validates the data from the handler and burns specified amount from the sender's wallet.
     * @param sender Address of the sender wallet on the source chain.
     * @param recipientAddressInTargetChain Address of the recipient wallet in the target chain.
     * @param amount Amount of tokens to be burnt on the current chain (source chain).
     * @param globalAMPLSupply AMPL ERC-20 total supply at the time of transfer burning.
     */
    function validateAndBurn(
        address sender,
        address recipientAddressInTargetChain,
        uint256 amount,
        uint256 globalAMPLSupply
    ) external onlyOwner {
        uint256 recordedGlobalAMPLSupply = IXCAmple(xcAmple).globalAMPLSupply();
        require(
            globalAMPLSupply == recordedGlobalAMPLSupply,
            "ChainBridgeXCAmpleGateway: total supply not consistent"
        );

        IXCAmpleControllerGateway(xcController).burn(sender, amount);

        emit XCTransferOut(sender, amount, recordedGlobalAMPLSupply);
    }

    constructor(
        address bridgeHandler,
        address xcAmple_,
        address xcController_
    ) public {
        xcAmple = xcAmple_;
        xcController = xcController_;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

interface IXCAmpleController {
    function rebase() external;

    function lastRebaseTimestampSec() external view returns (uint256);

    function globalAmpleforthEpoch() external view returns (uint256);

    function globalAmpleforthEpochAndAMPLSupply() external view returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

interface IXCAmpleControllerGateway {
    function nextGlobalAmpleforthEpoch() external view returns (uint256);

    function nextGlobalAMPLSupply() external view returns (uint256);

    function mint(address recipient, uint256 xcAmplAmount) external;

    function burn(address depositor, uint256 xcAmplAmount) external;

    function reportRebase(uint256 nextGlobalAmpleforthEpoch_, uint256 nextGlobalAMPLSupply_)
        external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import "uFragments/contracts/interfaces/IAMPL.sol";

interface IXCAmple is IAMPL {
    function globalAMPLSupply() external view returns (uint256);
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