// DELTA-BUG-BOUNTY
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../../../libs/Address.sol";
import "../../../libs/SafeMath.sol";

import "../../Common/OVLBase.sol";
import "../../../../common/OVLTokenTypes.sol";
import "../../Common/OVLVestingCalculator.sol";

import "../../../../interfaces/IOVLTransferHandler.sol";
import "../../../../interfaces/IDeltaDistributor.sol";
import "../../../../interfaces/IDeltaToken.sol";

contract OVLTransferHandler is OVLBase, OVLVestingCalculator, IOVLTransferHandler {
    using SafeMath for uint256;
    using Address for address;

    address public constant SUSHI_DELTA_WETH_PAIR = 0x1498bd576454159Bb81B5Ce532692a8752D163e8;
    address public constant DEEP_FARMING_VAULT = 0x9fE9Bb6B66958f2271C4B0aD23F6E8DDA8C221BE;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address, address) { // ignored props

    }

    function _removeBalanceFromSender(UserInformation storage senderInfo, address sender, bool immatureReceiverWhitelisted, uint256 amount) internal returns (uint256 totalRemoved) {
        uint256 mostMatureTxIndex = senderInfo.mostMatureTxIndex;
        uint256 lastInTxIndex = senderInfo.lastInTxIndex;

        // We check if recipent can get immature tokens, if so we go from the most imature first to be most fair to the user
        if (immatureReceiverWhitelisted) {

            //////
            ////
            // we go from the least mature balance to the msot mature meaning --
            ////
            /////
            uint256 accumulatedBalance;
            while (true) {

                uint256 leastMatureTxAmount = vestingTransactions[sender][lastInTxIndex].amount;
                // Can never underflow due to if conditional
                uint256 remainingBalanceNeeded = amount - accumulatedBalance;
                if (leastMatureTxAmount >= remainingBalanceNeeded) {
                    // We got enough in this bucket to cover the amount
                    // We remove it from total and dont adjust the fully vesting timestamp
                    // Because there might be tokens left still in it
                    totalRemoved += remainingBalanceNeeded;
                    vestingTransactions[sender][lastInTxIndex].amount = leastMatureTxAmount - remainingBalanceNeeded; // safe math already checked
                    // We got what we wanted we leave the loop
                    break;
                } else {
                    //we add the whole amount of this bucket to the accumulated balance
                    accumulatedBalance = accumulatedBalance.add(leastMatureTxAmount);
                    totalRemoved += leastMatureTxAmount;
                    delete vestingTransactions[sender][lastInTxIndex];
                    // And go to the more mature tx

                    // If we can't get enough in this tx and this is the last one, then we bail
                    if (lastInTxIndex == mostMatureTxIndex) {
                        // If we still have enough to cover in the mature balance we use that
                        uint256 maturedBalanceNeeded = amount - accumulatedBalance;
                        // Exhaustive underflow check
                    
                        senderInfo.maturedBalance = senderInfo.maturedBalance.sub(maturedBalanceNeeded, "OVLTransferHandler: Insufficient funds");
                        totalRemoved += maturedBalanceNeeded;
                        break;
                    }

                    // Loop over to the previous one
                    if (lastInTxIndex == 0) {
                        lastInTxIndex = QTY_EPOCHS;
                    }
                    lastInTxIndex--;
                }

            }
             // We write to storage the lastTx Index, which was in memory and we looped over it (or not)
            senderInfo.lastInTxIndex = lastInTxIndex;
            return totalRemoved; 
            // End of logic in case reciever is whitelisted ( return assures)
        }

        uint256 maturedBalance = senderInfo.maturedBalance;

        //////
        ////
        // we go from the most mature balance up
        ////
        /////

        if (maturedBalance >= amount) {
            senderInfo.maturedBalance = maturedBalance - amount; // safemath safe
            totalRemoved = amount;
        } else {
            // Possibly using a partially vested transaction
            uint256 accumulatedBalance = maturedBalance;
            totalRemoved = maturedBalance;

            // Use the entire balance to start
            senderInfo.maturedBalance = 0;

            while (amount > accumulatedBalance) {
                VestingTransaction memory mostMatureTx = vestingTransactions[sender][mostMatureTxIndex];
                // Guaranteed by `while` condition
                uint256 remainingBalanceNeeded = amount - accumulatedBalance;

                // Reduce this transaction as the final one
                VestingTransactionDetailed memory dtx = getTransactionDetails(mostMatureTx, block.timestamp);
                // credit is how much i got from this bucket
                // So if i didnt get enough from this bucket here we zero it and move to the next one
                if (remainingBalanceNeeded >= dtx.mature) {
                    totalRemoved += dtx.amount;
                    accumulatedBalance = accumulatedBalance.add(dtx.mature);
                    
                    delete vestingTransactions[sender][mostMatureTxIndex]; // refund gas
                } else {
                    // Remove the only needed amount
                    // Calculating debt based on the actual clamped credit eliminates
                    // the need for debit/credit ratio checks we initially had.
                    // Big gas savings using this one weird trick. Vitalik HATES it.
                    uint256 outputDebit = calculateTransactionDebit(dtx, remainingBalanceNeeded, block.timestamp);
                    remainingBalanceNeeded = outputDebit.add(remainingBalanceNeeded);
                    totalRemoved += remainingBalanceNeeded;

                    // We dont need to adjust timestamp
                    vestingTransactions[sender][mostMatureTxIndex].amount = mostMatureTx.amount.sub(remainingBalanceNeeded, "Removing too much from bucket");
                    break;
                }

                // If we just went throught he lasttx bucket, and we did not get enough then we bail
                // Note if its the lastTransaction it already had a break;
                if (mostMatureTxIndex == lastInTxIndex && accumulatedBalance < amount) { // accumulatedBalance < amount because of the case its exactly equal with first if
                    // Avoid ever looping around a second time because that would be bad
                    revert("OVLTransferHandler: Insufficient funds");
                }

                // We just emptied this so most mature one must be the next one
                mostMatureTxIndex++;

                if(mostMatureTxIndex == QTY_EPOCHS) {
                    mostMatureTxIndex = 0;
                }
            }
            // We remove the entire amount removed 
            // We already added amount
            senderInfo.mostMatureTxIndex = mostMatureTxIndex;
        }
    }


    // function _transferTokensToRecipient(address recipient, UserInformation memory senderInfo, UserInformation memory recipientInfo, uint256 amount) internal {
    function _transferTokensToRecipient(UserInformation storage recipientInfo, bool isSenderWhitelisted, address recipient, uint256 amount) internal {
        // If the sender can send fully or this recipent is whitelisted to not get vesting we just add it to matured balance
        (bool noVestingWhitelisted, uint256 maturedBalance, uint256 lastTransactionIndex) = (recipientInfo.noVestingWhitelisted, recipientInfo.maturedBalance, recipientInfo.lastInTxIndex);

        if(isSenderWhitelisted || noVestingWhitelisted) {
            recipientInfo.maturedBalance = maturedBalance.add(amount);
            return;
        }

        VestingTransaction storage lastTransaction = vestingTransactions[recipient][lastTransactionIndex];
  
        // Do i fit in this bucket?
        // conditions for fitting inside a bucket are
        // 1 ) Either its less than 2 days old
        // 2 ) Or its more than 14 days old
        // 3 ) Or we move to the next one - which is empty or already matured
        // Note that only the first bucket checked can logically be less than 2 days old, this is a important optimization
        // So lets take care of that case now, so its not checked in the loop.

        uint256 timestampNow = block.timestamp;
        uint256 fullVestingTimestamp = lastTransaction.fullVestingTimestamp;

        if (timestampNow >= fullVestingTimestamp) {// Its mature we move it to mature and override or we move to the next one, which is always either 0 or matured
            recipientInfo.maturedBalance = maturedBalance.add(lastTransaction.amount);

            lastTransaction.amount = amount;
            lastTransaction.fullVestingTimestamp = timestampNow + FULL_EPOCH_TIME;
        } else if (fullVestingTimestamp >= timestampNow + SECONDS_PER_EPOCH * (QTY_EPOCHS - 1)) {// we add 12 days
            // we avoid overflows from 0 fullyvestedtimestamp
            // if fullyVestingTimestamp is bigger than that we should increment
            // but not bigger than fullyVesting
            // This check is exhaustive
            // If this is the case we just put it in this bucket.
            lastTransaction.amount = lastTransaction.amount.add(amount);
            /// No need to adjust timestamp`
        } else { 

            // We move into the next one
            lastTransactionIndex++; 

            if (lastTransactionIndex == QTY_EPOCHS) { lastTransactionIndex = 0; } // Loop over

            recipientInfo.lastInTxIndex = lastTransactionIndex;

            // To figure out if this is a empty bucket or a stale one
            // Its either the most mature one 
            // Or its 0
            // There is no other logical options
            // If this is the most mature one then we go > with most mature
            uint256 mostMature = recipientInfo.mostMatureTxIndex;
            
            if (mostMature == lastTransactionIndex) {
                // It was the most mature one, so we have to increment the most mature index
                mostMature++;

                if (mostMature == QTY_EPOCHS) { mostMature = 0; }

                recipientInfo.mostMatureTxIndex = mostMature;
            }

            VestingTransaction storage evenLatestTransaction = vestingTransactions[recipient][lastTransactionIndex];

            // Its mature we move it to mature and override or we move to the next one, which is always either 0 or matured
            recipientInfo.maturedBalance = maturedBalance.add(evenLatestTransaction.amount);

            evenLatestTransaction.amount = amount;
            evenLatestTransaction.fullVestingTimestamp = timestampNow + FULL_EPOCH_TIME;
        }
    }

    function addAllowanceToDFV(address sender) internal {
        // If you transferFrom from anyone even 1 gwei unit
        // This will force dfv to have infinite allowance
        // But this is not abug because DFV has defacto infinite allowance becaose of this function
        // So there is no change
        _allowances[sender][DEEP_FARMING_VAULT] = uint(-1);
    }



    function handleUniswapAdjustmenets() internal{
        uint256 newLPSupply = IERC20(SUSHI_DELTA_WETH_PAIR).balanceOf(SUSHI_DELTA_WETH_PAIR);
        require(newLPSupply >= lpTokensInPair, "DELTAToken: Liquidity removals are forbidden");
        // We allow people to bump the number of LP tokens inside the pair, but we dont allow them to go lower
        // Making liquidity withdrawals impossible
        // Because uniswap queries banaceOf before doing a burn, that means we can detect a inflow of LP tokens
        // But someone could send them and then reset with this function
        // This is why we "lock" the bigger amount here and dont allow a lower amount than the last time
        // Making it impossible to anyone who sent the liquidity tokens to the pair (which is nessesary to burn) not be able to burn them
        lpTokensInPair = newLPSupply;
    }

    // This function does not need authentication, because this is EXCLUSIVELY
    // ever meant to be called using delegatecall() from the main token.
    // The memory it modifies in DELTAToken is what effects user balances.
    function handleTransfer(address sender, address recipient, uint256 amount) external override {
            require(sender != recipient, "DELTAToken: Can not send DELTA to yourself");
            require(sender != address(0), "ERC20: transfer from the zero address"); 
            require(recipient != address(0), "ERC20: transfer to the zero address");
            // If this is an interaction with Uniswap's old pair
            if(sender == 0x7D7E813082eF6c143277c71786e5bE626ec77b20 || recipient == 0x7D7E813082eF6c143277c71786e5bE626ec77b20) {
                // Whitelist exclusively for core deployer
                require(sender == 0x5A16552f59ea34E44ec81E58b3817833E9fD5436 || recipient == 0x5A16552f59ea34E44ec81E58b3817833E9fD5436, "DELTAToken: Uniswap is disabled. Please use SushiSwap.");
            }
            
            /// Liquidity removal protection
            if (!liquidityRebasingPermitted && (sender == SUSHI_DELTA_WETH_PAIR || recipient == SUSHI_DELTA_WETH_PAIR)) {
                handleUniswapAdjustmenets();
            }

            if(recipient == DEEP_FARMING_VAULT) {
                addAllowanceToDFV(sender);
            }

            UserInformation storage recipientInfo = _userInformation[recipient];
            UserInformation storage senderInfo = _userInformation[sender];
            uint256 totalRemoved = _removeBalanceFromSender(senderInfo, sender, recipientInfo.immatureReceiverWhitelisted, amount);
            uint256 toDistributor = totalRemoved.sub(amount, "OVLTransferHandler: Insufficient funds");

            // We remove from max balance totals
            senderInfo.maxBalance = senderInfo.maxBalance.sub(totalRemoved, "OVLTransferHandler: Insufficient funds");

            // Sanity check
            require(totalRemoved >= amount, "OVLTransferHandler: Insufficient funds");
            // Max is 90% of total removed
            require(amount.mul(9) >= toDistributor, "DELTAToken: Burned too many tokens"); 
            
            if(toDistributor > 0) {
                _creditDistributor(sender, toDistributor);
            }
            //////
            /// We add tokens to the recipient
            //////
            _transferTokensToRecipient(recipientInfo, senderInfo.fullSenderWhitelisted, recipient, amount);
            // We add to total balance for sanity checks and uniswap router
            recipientInfo.maxBalance = recipientInfo.maxBalance.add(amount);

            emit Transfer(sender, recipient, amount);
    }

    function _creditDistributor(address creditedBy, uint256 amount) internal {
        address _distributor = distributor; // gas savings for storage reads
        UserInformation storage distributorInfo = _userInformation[distributor];
        distributorInfo.maturedBalance = distributorInfo.maturedBalance.add(amount); // Should trigger an event here
        distributorInfo.maxBalance = distributorInfo.maxBalance.add(amount); 

        IDeltaDistributor(_distributor).creditUser(creditedBy, amount);
        emit Transfer(creditedBy, _distributor, amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// DELTA-BUG-BOUNTY
pragma abicoder v2;
pragma solidity ^0.7.6;

import "./../../../common/OVLTokenTypes.sol";

contract OVLBase {
    // Shared state begin v0
    mapping (address => VestingTransaction[QTY_EPOCHS]) public vestingTransactions;
    mapping (address => UserInformation) internal _userInformation;
    
    mapping (address => uint256) internal _maxPossibleBalances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    address public distributor;
    uint256 public lpTokensInPair;
    bool public liquidityRebasingPermitted;

    uint256 [72] private _gap;
    // Shared state end of v0
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

interface IOVLTransferHandler {
    function handleTransfer(address sender, address recipient, uint256 amount) external;
}

pragma solidity ^0.7.6;

interface IDeltaDistributor {
    function creditUser(address,uint256) external;
    function addDevested(address, uint256) external;
    function distribute() external;
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
    // Added with Sushi update
    function setTokenTransferHandler(address) external;
    function setBalanceCalculator(address) external;
    function setPendingGovernance(address) external;
    function acceptGovernance() external;
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

