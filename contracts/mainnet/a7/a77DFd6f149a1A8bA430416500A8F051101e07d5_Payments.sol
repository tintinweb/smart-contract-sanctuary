// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20Permit.sol";
import "./lib/SafeERC20.sol";
import "./lib/ReentrancyGuard.sol";

/**
 * @title Payments
 * @dev Contract for streaming token payments for set periods of time 
 */
contract Payments is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Payment definition
    struct Payment {
        address token;
        address receiver;
        address payer;
        uint48 startTime;
        uint48 stopTime;
        uint16 cliffDurationInDays;
        uint256 paymentDurationInSecs;
        uint256 amount;
        uint256 amountClaimed;
    }

    /// @notice Payment balance definition
    struct PaymentBalance {
        uint256 id;
        uint256 claimableAmount;
        Payment payment;
    }

    /// @notice Token balance definition
    struct TokenBalance {
        uint256 totalAmount;
        uint256 claimableAmount;
        uint256 claimedAmount;
    }

    /// @dev Used to translate payment periods specified in days to seconds
    uint256 constant internal SECONDS_PER_DAY = 86400;
    
    /// @notice Mapping of payment id > token payments
    mapping (uint256 => Payment) public tokenPayments;

    /// @notice Mapping of address to payment id
    mapping (address => uint256[]) public paymentIds;

    /// @notice Number of payments
    uint256 public numPayments;

    /// @notice Event emitted when a new payment is created
    event PaymentCreated(address indexed token, address indexed payer, address indexed receiver, uint256 paymentId, uint256 amount, uint48 startTime, uint256 durationInSecs, uint16 cliffInDays);
    
    /// @notice Event emitted when tokens are claimed by a receiver from an available balance
    event TokensClaimed(address indexed receiver, address indexed token, uint256 indexed paymentId, uint256 amountClaimed);

    /// @notice Event emitted when payment stopped
    event PaymentStopped(uint256 indexed paymentId, uint256 indexed originalDuration, uint48 stopTime, uint48 startTime);

    /**
     * @notice Create payment, optionally providing voting power
     * @param payer The account that is paymenting tokens
     * @param receiver The account that will be able to retrieve available tokens
     * @param startTime The unix timestamp when the payment period will start
     * @param amount The amount of tokens being paid
     * @param paymentDurationInSecs The payment period in seconds
     * @param cliffDurationInDays The cliff duration in days
     */
    function createPayment(
        address token,
        address payer,
        address receiver,
        uint48 startTime,
        uint256 amount,
        uint256 paymentDurationInSecs,
        uint16 cliffDurationInDays
    )
        external
    {
        require(paymentDurationInSecs > 0, "Payments::createPayment: payment duration must be > 0");
        require(paymentDurationInSecs <= 25*365*SECONDS_PER_DAY, "Payments::createPayment: payment duration more than 25 years");
        require(paymentDurationInSecs >= SECONDS_PER_DAY*cliffDurationInDays, "Payments::createPayment: payment duration < cliff");
        require(amount > 0, "Payments::createPayment: amount not > 0");
        _createPayment(token, payer, receiver, startTime, amount, paymentDurationInSecs, cliffDurationInDays);
    }

    /**
     * @notice Create payment, using permit for approval
     * @dev It is up to the frontend developer to ensure the token implements permit - otherwise this will fail
     * @param token Address of token to payment
     * @param payer The account that is paymenting tokens
     * @param receiver The account that will be able to retrieve available tokens
     * @param startTime The unix timestamp when the payment period will start
     * @param amount The amount of tokens being paid
     * @param paymentDurationInSecs The payment period in seconds
     * @param cliffDurationInDays The payment cliff duration in days
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function createPaymentWithPermit(
        address token,
        address payer,
        address receiver,
        uint48 startTime,
        uint256 amount,
        uint256 paymentDurationInSecs,
        uint16 cliffDurationInDays,
        uint256 deadline,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) 
        external
    {
        require(paymentDurationInSecs > 0, "Payments::createPaymentWithPermit: payment duration must be > 0");
        require(paymentDurationInSecs <= 25*365*SECONDS_PER_DAY, "Payments::createPaymentWithPermit: payment duration more than 25 years");
        require(paymentDurationInSecs >= SECONDS_PER_DAY*cliffDurationInDays, "Payments::createPaymentWithPermit: duration < cliff");
        require(amount > 0, "Payments::createPaymentWithPermit: amount not > 0");

        // Set approval using permit signature
        IERC20Permit(token).permit(payer, address(this), amount, deadline, v, r, s);
        _createPayment(token, payer, receiver, startTime, amount, paymentDurationInSecs, cliffDurationInDays);
    }

    /**
     * @notice Get all active token payment ids
     * @return the payment ids
     */
    function allActivePaymentIds() external view returns(uint256[] memory){
        uint256 activeCount;

        // Get number of active payments
        for (uint256 i; i < numPayments; i++) {
            if(claimableBalance(i) > 0) {
                activeCount++;
            }
        }

        // Create result array of length `activeCount`
        uint256[] memory result = new uint256[](activeCount);
        uint256 j;

        // Populate result array
        for (uint256 i; i < numPayments; i++) {
            if(claimableBalance(i) > 0) {
                result[j] = i;
                j++;
            }
        }
        return result;
    }

    /**
     * @notice Get all active token payments
     * @return the payments
     */
    function allActivePayments() external view returns(Payment[] memory){
        uint256 activeCount;

        // Get number of active payments
        for (uint256 i; i < numPayments; i++) {
            if(claimableBalance(i) > 0) {
                activeCount++;
            }
        }

        // Create result array of length `activeCount`
        Payment[] memory result = new Payment[](activeCount);
        uint256 j;

        // Populate result array
        for (uint256 i; i < numPayments; i++) {
            if(claimableBalance(i) > 0) {
                result[j] = tokenPayments[i];
                j++;
            }
        }
        return result;
    }

    /**
     * @notice Get all active token payment balances
     * @return the active payment balances
     */
    function allActivePaymentBalances() external view returns(PaymentBalance[] memory){
        uint256 activeCount;

        // Get number of active payments
        for (uint256 i; i < numPayments; i++) {
            if(claimableBalance(i) > 0) {
                activeCount++;
            }
        }

        // Create result array of length `activeCount`
        PaymentBalance[] memory result = new PaymentBalance[](activeCount);
        uint256 j;

        // Populate result array
        for (uint256 i; i < numPayments; i++) {
            if(claimableBalance(i) > 0) {
                result[j] = paymentBalance(i);
                j++;
            }
        }
        return result;
    }

    /**
     * @notice Get all active token payment ids for receiver
     * @param receiver The address that has paid balances
     * @return the active payment ids
     */
    function activePaymentIds(address receiver) external view returns(uint256[] memory){
        uint256 activeCount;
        uint256[] memory receiverPaymentIds = paymentIds[receiver];

        // Get number of active payments
        for (uint256 i; i < receiverPaymentIds.length; i++) {
            if(claimableBalance(receiverPaymentIds[i]) > 0) {
                activeCount++;
            }
        }

        // Create result array of length `activeCount`
        uint256[] memory result = new uint256[](activeCount);
        uint256 j;

        // Populate result array
        for (uint256 i; i < receiverPaymentIds.length; i++) {
            if(claimableBalance(receiverPaymentIds[i]) > 0) {
                result[j] = receiverPaymentIds[i];
                j++;
            }
        }
        return result;
    }

    /**
     * @notice Get all token payments for receiver
     * @param receiver The address that has paid balances
     * @return the payments
     */
    function allPayments(address receiver) external view returns(Payment[] memory){
        uint256[] memory allPaymentIds = paymentIds[receiver];
        Payment[] memory result = new Payment[](allPaymentIds.length);
        for (uint256 i; i < allPaymentIds.length; i++) {
            result[i] = tokenPayments[allPaymentIds[i]];
        }
        return result;
    }

    /**
     * @notice Get all active token payments for receiver
     * @param receiver The address that has paid balances
     * @return the payments
     */
    function activePayments(address receiver) external view returns(Payment[] memory){
        uint256 activeCount;
        uint256[] memory receiverPaymentIds = paymentIds[receiver];

        // Get number of active payments
        for (uint256 i; i < receiverPaymentIds.length; i++) {
            if(claimableBalance(receiverPaymentIds[i]) > 0) {
                activeCount++;
            }
        }

        // Create result array of length `activeCount`
        Payment[] memory result = new Payment[](activeCount);
        uint256 j;

        // Populate result array
        for (uint256 i; i < receiverPaymentIds.length; i++) {
            if(claimableBalance(receiverPaymentIds[i]) > 0) {
                result[j] = tokenPayments[receiverPaymentIds[i]];
                j++;
            }
        }
        return result;
    }

    /**
     * @notice Get all active token payment balances for receiver
     * @param receiver The address that has paid balances
     * @return the active payment balances
     */
    function activePaymentBalances(address receiver) external view returns(PaymentBalance[] memory){
        uint256 activeCount;
        uint256[] memory receiverPaymentIds = paymentIds[receiver];

        // Get number of active payments
        for (uint256 i; i < receiverPaymentIds.length; i++) {
            if(claimableBalance(receiverPaymentIds[i]) > 0) {
                activeCount++;
            }
        }

        // Create result array of length `activeCount`
        PaymentBalance[] memory result = new PaymentBalance[](activeCount);
        uint256 j;

        // Populate result array
        for (uint256 i; i < receiverPaymentIds.length; i++) {
            if(claimableBalance(receiverPaymentIds[i]) > 0) {
                result[j] = paymentBalance(receiverPaymentIds[i]);
                j++;
            }
        }
        return result;
    }

    /**
     * @notice Get total token balance
     * @param token The token to check
     * @return balance the total active balance of `token`
     */
    function totalTokenBalance(address token) external view returns(TokenBalance memory balance){
        for (uint256 i; i < numPayments; i++) {
            Payment memory tokenPayment = tokenPayments[i];
            if(tokenPayment.token == token && tokenPayment.startTime != tokenPayment.stopTime){
                balance.totalAmount = balance.totalAmount + tokenPayment.amount;
                if(block.timestamp > tokenPayment.startTime) {
                    balance.claimedAmount = balance.claimedAmount + tokenPayment.amountClaimed;

                    uint256 elapsedTime = tokenPayment.stopTime > 0 && tokenPayment.stopTime < block.timestamp ? tokenPayment.stopTime - tokenPayment.startTime : block.timestamp - tokenPayment.startTime;
                    uint256 elapsedDays = elapsedTime / SECONDS_PER_DAY;

                    if (
                        elapsedDays >= tokenPayment.cliffDurationInDays
                    ) {
                        if (tokenPayment.stopTime == 0 && elapsedTime >= tokenPayment.paymentDurationInSecs) {
                            balance.claimableAmount = balance.claimableAmount + tokenPayment.amount - tokenPayment.amountClaimed;
                        } else {
                            uint256 paymentAmountPerSec = tokenPayment.amount / tokenPayment.paymentDurationInSecs;
                            uint256 amountAvailable = paymentAmountPerSec * elapsedTime;
                            balance.claimableAmount = balance.claimableAmount + amountAvailable - tokenPayment.amountClaimed;
                        }
                    }
                }
            }
        }
    }

    /**
     * @notice Get token balance of receiver
     * @param token The token to check
     * @param receiver The address that has available balances
     * @return balance the total active balance of `token` for `receiver`
     */
    function tokenBalance(address token, address receiver) external view returns(TokenBalance memory balance){
        uint256[] memory receiverPaymentIds = paymentIds[receiver];
        for (uint256 i; i < receiverPaymentIds.length; i++) {
            Payment memory receiverPayment = tokenPayments[receiverPaymentIds[i]];
            if(receiverPayment.token == token && receiverPayment.startTime != receiverPayment.stopTime){
                balance.totalAmount = balance.totalAmount + receiverPayment.amount;
                if(block.timestamp > receiverPayment.startTime) {
                    balance.claimedAmount = balance.claimedAmount + receiverPayment.amountClaimed;

                    uint256 elapsedTime = receiverPayment.stopTime > 0 && receiverPayment.stopTime < block.timestamp ? receiverPayment.stopTime - receiverPayment.startTime : block.timestamp - receiverPayment.startTime;
                    uint256 elapsedDays = elapsedTime / SECONDS_PER_DAY;

                    if (
                        elapsedDays >= receiverPayment.cliffDurationInDays
                    ) {
                        if (receiverPayment.stopTime == 0 && elapsedTime >= receiverPayment.paymentDurationInSecs) {
                            balance.claimableAmount = balance.claimableAmount + receiverPayment.amount - receiverPayment.amountClaimed;
                        } else {
                            uint256 paymentAmountPerSec = receiverPayment.amount / receiverPayment.paymentDurationInSecs;
                            uint256 amountAvailable = paymentAmountPerSec * elapsedTime;
                            balance.claimableAmount = balance.claimableAmount + amountAvailable - receiverPayment.amountClaimed;
                        }
                    }
                }
            }
        }
    }

    /**
     * @notice Get payment balance for a given payment id
     * @param paymentId The payment ID
     * @return balance the payment balance
     */
    function paymentBalance(uint256 paymentId) public view returns (PaymentBalance memory balance) {
        balance.id = paymentId;
        balance.claimableAmount = claimableBalance(paymentId);
        balance.payment = tokenPayments[paymentId];
    }

    /**
     * @notice Get claimable balance for a given payment id
     * @dev Returns 0 if cliff duration has not ended
     * @param paymentId The payment ID
     * @return The amount that can be claimed
     */
    function claimableBalance(uint256 paymentId) public view returns (uint256) {
        Payment storage payment = tokenPayments[paymentId];

        // For payments created with a future start date or payments stopped before starting, that hasn't been reached, return 0
        if (block.timestamp < payment.startTime || payment.startTime == payment.stopTime) {
            return 0;
        }

        
        uint256 elapsedTime = payment.stopTime > 0 && payment.stopTime < block.timestamp ? payment.stopTime - payment.startTime : block.timestamp - payment.startTime;
        uint256 elapsedDays = elapsedTime / SECONDS_PER_DAY;
        
        if (elapsedDays < payment.cliffDurationInDays) {
            return 0;
        }

        if (payment.stopTime == 0 && elapsedTime >= payment.paymentDurationInSecs) {
            return payment.amount - payment.amountClaimed;
        }
        
        uint256 paymentAmountPerSec = payment.amount / payment.paymentDurationInSecs;
        uint256 amountAvailable = paymentAmountPerSec * elapsedTime;
        return amountAvailable - payment.amountClaimed;
    }

    /**
     * @notice Allows receiver to claim all of their available tokens for a set of payments
     * @dev Errors if no tokens are claimable
     * @dev It is advised receivers check they are entitled to claim via `claimableBalance` before calling this
     * @param payments The payment ids for available token balances
     */
    function claimAllAvailableTokens(uint256[] memory payments) external nonReentrant {
        for (uint i = 0; i < payments.length; i++) {
            uint256 claimableAmount = claimableBalance(payments[i]);
            require(claimableAmount > 0, "Payments::claimAllAvailableTokens: claimableAmount is 0");
            _claimTokens(payments[i], claimableAmount);
        }
    }

    /**
     * @notice Allows receiver to claim a portion of their available tokens for a given payment
     * @dev Errors if token amounts provided are > claimable amounts
     * @dev It is advised receivers check they are entitled to claim via `claimableBalance` before calling this
     * @param payments The payment ids for available token balances
     * @param amounts The amount of each available token to claim
     */
    function claimAvailableTokenAmounts(uint256[] memory payments, uint256[] memory amounts) external nonReentrant {
        require(payments.length == amounts.length, "Payments::claimAvailableTokenAmounts: arrays must be same length");
        for (uint i = 0; i < payments.length; i++) {
            uint256 claimableAmount = claimableBalance(payments[i]);
            require(claimableAmount >= amounts[i], "Payments::claimAvailableTokenAmounts: claimableAmount < amount");
            _claimTokens(payments[i], amounts[i]);
        }
    }

    /**
     * @notice Allows payer or receiver to stop existing payments for a given paymentId
     * @param paymentId The payment id for a payment
     * @param stopTime Timestamp to stop payment, if 0 use current block.timestamp
     */
    function stopPayment(uint256 paymentId, uint48 stopTime) external nonReentrant {
        Payment storage payment = tokenPayments[paymentId];
        require(msg.sender == payment.payer || msg.sender == payment.receiver, "Payments::stopPayment: msg.sender must be payer or receiver");
        require(payment.stopTime == 0, "Payments::stopPayment: payment already stopped");
        stopTime = stopTime == 0 ? uint48(block.timestamp) : stopTime;
        require(stopTime < payment.startTime + payment.paymentDurationInSecs, "Payments::stopPayment: stop time > payment duration");
        if(stopTime > payment.startTime) {
            payment.stopTime = stopTime;
            uint256 newPaymentDuration = stopTime - payment.startTime;
            uint256 paymentAmountPerSec = payment.amount / payment.paymentDurationInSecs;
            uint256 newPaymentAmount = paymentAmountPerSec * newPaymentDuration;
            IERC20(payment.token).safeTransfer(payment.payer, payment.amount - newPaymentAmount);
            emit PaymentStopped(paymentId, payment.paymentDurationInSecs, stopTime, payment.startTime);
        } else {
            payment.stopTime = payment.startTime;
            IERC20(payment.token).safeTransfer(payment.payer, payment.amount);
            emit PaymentStopped(paymentId, payment.paymentDurationInSecs, payment.startTime, payment.startTime);
        }
    }

    /**
     * @notice Internal implementation of createPayment
     * @param payer The account that is paymenting tokens
     * @param receiver The account that will be able to retrieve available tokens
     * @param startTime The unix timestamp when the payment period will start
     * @param amount The amount of tokens being paid
     * @param paymentDurationInSecs The payment period in seconds
     * @param cliffDurationInDays The cliff duration in days
     */
    function _createPayment(
        address token,
        address payer,
        address receiver,
        uint48 startTime,
        uint256 amount,
        uint256 paymentDurationInSecs,
        uint16 cliffDurationInDays
    ) internal {

        // Transfer the tokens under the control of the payment contract
        IERC20(token).safeTransferFrom(payer, address(this), amount);

        uint48 paymentStartTime = startTime == 0 ? uint48(block.timestamp) : startTime;

        // Create payment
        Payment memory payment = Payment({
            token: token,
            receiver: receiver,
            payer: payer,
            startTime: paymentStartTime,
            stopTime: 0,
            paymentDurationInSecs: paymentDurationInSecs,
            cliffDurationInDays: cliffDurationInDays,
            amount: amount,
            amountClaimed: 0
        });

        tokenPayments[numPayments] = payment;
        paymentIds[receiver].push(numPayments);
        emit PaymentCreated(token, payer, receiver, numPayments, amount, paymentStartTime, paymentDurationInSecs, cliffDurationInDays);
        
        // Increment payment id
        numPayments++;
    }

    /**
     * @notice Internal implementation of token claims
     * @param paymentId The payment id for claim
     * @param claimAmount The amount to claim
     */
    function _claimTokens(uint256 paymentId, uint256 claimAmount) internal {
        Payment storage payment = tokenPayments[paymentId];

        // Update claimed amount
        payment.amountClaimed = payment.amountClaimed + claimAmount;

        // Release tokens
        IERC20(payment.token).safeTransfer(payment.receiver, claimAmount);
        emit TokensClaimed(payment.receiver, payment.token, paymentId, claimAmount);
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

import "./IERC20.sol";

interface IERC20Permit is IERC20 {
    function getDomainSeparator() external view returns (bytes32);
    function DOMAIN_TYPEHASH() external view returns (bytes32);
    function VERSION_HASH() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function nonces(address) external view returns (uint);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

