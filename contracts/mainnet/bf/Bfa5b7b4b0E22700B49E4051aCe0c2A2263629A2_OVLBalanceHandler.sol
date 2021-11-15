// DELTA-BUG-BOUNTY
pragma solidity ^0.7.6;
pragma abicoder v2;


import "../../../../common/OVLTokenTypes.sol";
import "../../Common/OVLVestingCalculator.sol";
import "../../../../interfaces/IOVLBalanceHandler.sol";
import "../../../../interfaces/IOVLTransferHandler.sol";
import "../../../../interfaces/IRebasingLiquidityToken.sol";
import "../../../../interfaces/IDeltaToken.sol";

contract OVLBalanceHandler is OVLVestingCalculator, IOVLBalanceHandler {
    using SafeMath for uint256;

    IDeltaToken private immutable DELTA_TOKEN;
    IERC20 private immutable DELTA_X_WETH_PAIR;
    IOVLTransferHandler private immutable TRANSFER_HANDLER;
    address private constant UNI_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;


    constructor(IOVLTransferHandler transactionHandler, IERC20 pair) {
        DELTA_TOKEN = IDeltaToken(0x9EA3b5b4EC044b70375236A281986106457b20EF);
        TRANSFER_HANDLER = transactionHandler;
        DELTA_X_WETH_PAIR = pair;
    }

    function handleBalanceCalculations(address account, address sender) external view override returns (uint256) {
        UserInformation memory ui = DELTA_TOKEN.userInformation(account);
        // LP Removal protection
        if(sender == address(DELTA_X_WETH_PAIR) && !DELTA_TOKEN.liquidityRebasingPermitted()) { // This guaranteed liquidity rebasing is not permitted and the sender whos calling is uniswap.
            // If the sender is uniswap and is querying balanceOf, this only happens first inside the burn function
            // This means if the balance of LP tokens here went up
            // We should revert
            // LP tokens supply can raise but it can never get lower with this method, if we detect a raise here we should revert
            // Rest of this code is inside the _transfer function
            require(DELTA_X_WETH_PAIR.balanceOf(address(DELTA_X_WETH_PAIR)) == DELTA_TOKEN.lpTokensInPair(), "DELTAToken: Liquidity removal is forbidden");
            return ui.maxBalance;
        }
        // We trick the uniswap router path revert by returning the whole balance
        // As well as saving gas in noVesting callers like uniswap
        if(ui.noVestingWhitelisted || sender == UNI_ROUTER) {
            return ui.maxBalance;
        } 
        // potentially do i + 1 % epochs
        while (true) {
            uint256 mature = getMatureBalance(DELTA_TOKEN.vestingTransactions(account, ui.mostMatureTxIndex), block.timestamp); 
            ui.maturedBalance = ui.maturedBalance.add(mature);
    
            // We go until we encounter a empty above most mature tx
            if(ui.mostMatureTxIndex == ui.lastInTxIndex) { 
                break;
            }
            ui.mostMatureTxIndex++;
            if(ui.mostMatureTxIndex == QTY_EPOCHS) { ui.mostMatureTxIndex = 0; }
        }

        return ui.maturedBalance;
    }
}

// SPDX-License-Identifier: UNLICENSED
// DELTA-BUG-BOUNTY

pragma solidity ^0.7.6;

struct VestingTransaction {
    uint256 amount;
    uint256 fullVestingTimestamp;
}

struct WalletTotals {
    uint256 mature;
    uint256 immature;
    uint256 total;
}

struct UserInformation {
    // This is going to be read from only [0]
    uint256 mostMatureTxIndex;
    uint256 lastInTxIndex;
    uint256 maturedBalance;
    uint256 maxBalance;
    bool fullSenderWhitelisted;
    // Note that recieving immature balances doesnt mean they recieve them fully vested just that senders can do it
    bool immatureReceiverWhitelisted;
    bool noVestingWhitelisted;
}

struct UserInformationLite {
    uint256 maturedBalance;
    uint256 maxBalance;
    uint256 mostMatureTxIndex;
    uint256 lastInTxIndex;
}

struct VestingTransactionDetailed {
    uint256 amount;
    uint256 fullVestingTimestamp;
    // uint256 percentVestedE4;
    uint256 mature;
    uint256 immature;
}


uint256 constant QTY_EPOCHS = 7;

uint256 constant SECONDS_PER_EPOCH = 172800; // About 2days

uint256 constant FULL_EPOCH_TIME = SECONDS_PER_EPOCH * QTY_EPOCHS;

// Precision Multiplier -- this many zeros (23) seems to get all the precision needed for all 18 decimals to be only off by a max of 1 unit
uint256 constant PM = 1e23;

// DELTA-BUG-BOUNTY
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./../../../common/OVLTokenTypes.sol";
import "../../../interfaces/IOVLVestingCalculator.sol";
import "../../libs/SafeMath.sol";

contract OVLVestingCalculator is IOVLVestingCalculator {
    using SafeMath for uint256;

    function getTransactionDetails(VestingTransaction memory _tx) public view override returns (VestingTransactionDetailed memory dtx) {
        return getTransactionDetails(_tx, block.timestamp);
    }

    function getTransactionDetails(VestingTransaction memory _tx, uint256 _blockTimestamp) public pure override returns (VestingTransactionDetailed memory dtx) {
        if(_tx.fullVestingTimestamp == 0) {
            return dtx;
        }

        dtx.amount = _tx.amount;
        dtx.fullVestingTimestamp = _tx.fullVestingTimestamp;

        // at precision E4, 1000 is 10%
        uint256 timeRemaining;
        if(_blockTimestamp >= dtx.fullVestingTimestamp) {
            // Fully vested
            dtx.mature = _tx.amount;
            return dtx;
        } else {
            timeRemaining = dtx.fullVestingTimestamp - _blockTimestamp;
        }

        uint256 percentWaitingToVestE4 = timeRemaining.mul(1e4) / FULL_EPOCH_TIME;
        uint256 percentWaitingToVestE4Scaled = percentWaitingToVestE4.mul(90) / 100;

        dtx.immature = _tx.amount.mul(percentWaitingToVestE4Scaled) / 1e4;
        dtx.mature = _tx.amount.sub(dtx.immature);
    }

    function getMatureBalance(VestingTransaction memory _tx, uint256 _blockTimestamp) public pure override returns (uint256 mature) {
        if(_tx.fullVestingTimestamp == 0) {
            return 0;
        }
        
        uint256 timeRemaining;
        if(_blockTimestamp >= _tx.fullVestingTimestamp) {
            // Fully vested
            return _tx.amount;
        } else {
            timeRemaining = _tx.fullVestingTimestamp - _blockTimestamp;
        }

        uint256 percentWaitingToVestE4 = timeRemaining.mul(1e4) / FULL_EPOCH_TIME;
        uint256 percentWaitingToVestE4Scaled = percentWaitingToVestE4.mul(90) / 100;

        mature = _tx.amount.mul(percentWaitingToVestE4Scaled) / 1e4;
        mature = _tx.amount.sub(mature); // the subtracted value represents the immature balance at this point
    }

    function calculateTransactionDebit(VestingTransactionDetailed memory dtx, uint256 matureAmountNeeded, uint256 currentTimestamp) public pure override returns (uint256 outputDebit) {
        if(dtx.fullVestingTimestamp > currentTimestamp) {
            // This will be between 0 and 100*pm representing how much of the mature pool is needed
            uint256 percentageOfMatureCoinsConsumed = matureAmountNeeded.mul(PM).div(dtx.mature);
            require(percentageOfMatureCoinsConsumed <= PM, "OVLTransferHandler: Insufficient funds");

            // Calculate the number of immature coins that need to be debited based on this ratio
            outputDebit = dtx.immature.mul(percentageOfMatureCoinsConsumed) / PM;
        }

        // shouldnt this use outputDebit
        require(dtx.amount <= dtx.mature.add(dtx.immature), "DELTAToken: Balance maximum problem"); // Just in case
    }
}

pragma experimental ABIEncoderV2;
pragma solidity ^0.7.6;

interface IOVLBalanceHandler {
    function handleBalanceCalculations(address, address) external view returns (uint256);
}

pragma experimental ABIEncoderV2;
pragma solidity ^0.7.6;

interface IOVLTransferHandler {
    function handleTransfer(address sender, address recipient, uint256 amount) external;
}

pragma experimental ABIEncoderV2;
pragma solidity ^0.7.6;
import "./IERC20Upgradeable.sol";
interface IRebasingLiquidityToken is IERC20Upgradeable {
    function tokenCaller() external;
    function reserveCaller(uint256,uint256) external;
    function wrapWithReturn() external returns (uint256);
    function wrap() external;
    function rlpPerLP() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

import "../common/OVLTokenTypes.sol";

interface IDeltaToken is IERC20 {
    function vestingTransactions(address, uint256) external view returns (VestingTransaction memory);
    function getUserInfo(address) external view returns (UserInformationLite memory);
    function getMatureBalance(address, uint256) external view returns (uint256);
    function liquidityRebasingPermitted() external view returns (bool);
    function lpTokensInPair() external view returns (uint256);
    function governance() external view returns (address);
    function performLiquidityRebasing() external;
    function distributor() external view returns (address);
    function totalsForWallet(address ) external view returns (WalletTotals memory totals);
    function adjustBalanceOfNoVestingAccount(address, uint256,bool) external;
    function userInformation(address user) external view returns (UserInformation memory);

}

pragma solidity ^0.7.6;
pragma abicoder v2;

import "../common/OVLTokenTypes.sol";

interface IOVLVestingCalculator {
    function getTransactionDetails(VestingTransaction memory _tx) external view returns (VestingTransactionDetailed memory dtx);

    function getTransactionDetails(VestingTransaction memory _tx, uint256 _blockTimestamp) external pure returns (VestingTransactionDetailed memory dtx);

    function getMatureBalance(VestingTransaction memory _tx, uint256 _blockTimestamp) external pure returns (uint256 mature);

    function calculateTransactionDebit(VestingTransactionDetailed memory dtx, uint256 matureAmountNeeded, uint256 currentTimestamp) external pure returns (uint256 outputDebit);
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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

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

