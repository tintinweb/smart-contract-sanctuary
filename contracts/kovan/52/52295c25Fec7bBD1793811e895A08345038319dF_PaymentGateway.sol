/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

pragma solidity ^0.6.2;


interface PriceOracle {
    /**
     * @dev Returns the price to register or renew a PPN.
     * @param duration How long the PEN is being registered or extended for, in year.
     * @return The price of this renewal or registration, in wei.
     */
    function price(uint256 duration) external view returns (uint256);
}

/**
 * @title PPNTokenInterface
 */
interface PPNTokenInterface {
    enum PhoneNumberStatus {
        AVAILABLE_FOR_PURCHASE,
        ALREADY_PURCHASED,
        ALREADY_AUTHORIZED,
        AUTHORIZED_FOR_PURCHASE_BY_SOME_OTHER_WALLET,
        AUTHORIZATION_EXPIRED,
        PURCHASE_EXPIRED
    }

    /**
     * @notice Get the current status of `phoneNumber` whether authorized or not
     * @param owner The owner address
     * @param phoneNumber The phoneNumber of the owner to query
     * @return The number is available to authorized or not, current authorized status and code
     */
    function checkPPNAuthorizedStatus(address owner, uint256 phoneNumber)
        external
        view
        returns (
            bool,
            bool,
            PhoneNumberStatus,
            uint256
        );

    /**
     * @notice Create an authorization to PPN (PESA Phone Number) for a owner
     * @param phoneNumber The phoneNumber of the owner
     * @param duration The expiry time of the token
     */

    function authorizePPN(uint256 phoneNumber, uint256 duration)
        external
        payable;

    /**
     * @notice Create an authorization to PPN (PESA Phone Number) for a owner
     * @param owner The Owner wallet address
     * @param phoneNumber The phoneNumber of the owner
     * @param duration The expiry time of the token
     */

    function authorizePPNbyAdmin(
        address owner,
        uint256 phoneNumber,
        uint256 duration
    ) external;

    /**
     * @notice Create new PPN (PESA Phone Number) with Authorization for a owner
     * @param owner The Owner wallet address
     * @param phoneNumber The phoneNumber of the owner
     * @param duration The expiry time of the token
     * @return The PPN expiry time
     */
    function createPPNwithAuthoriztion(
        address owner,
        uint256 phoneNumber,
        uint256 duration
    ) external returns (uint256);

    /**
     * @notice Create new PPN (PESA Phone Number) for a owner
     * @param owner The Owner wallet address
     * @param itemId The itemId of the owner
     * @return The PPN expiry time
     */

    function createPPN(address owner, uint256 itemId)
        external
        returns (uint256);

    /**
     * @notice Create new PPN (PESA Phone Number) for a owner
     * @param owner The Owner wallet address
     * @param itemId The itemId of the owner
     * @param ensName The ENS name that user's own
     * @return The PPN expiry time
     */

    function createPPNwithENS(
        address owner,
        uint256 itemId,
        string calldata ensName
    ) external returns (uint256);

    /**
     * @notice Renews PPN (PESA Phone Number) for a owner
     * @param itemId The itemId of the owner
     * @param duration The expiry time of the token
     * @return The PPN expiry time
     */
    function renew(uint256 itemId, uint256 duration)
        external
        payable
        returns (uint256);

    /**
     * @notice Renews PPN (PESA Phone Number) for a owner by Admin
     * @param itemId The itemId of the owner
     * @param duration The expiry time of the token
     * @return The PPN expiry time
     */
    function renewByAdmin(uint256 itemId, uint256 duration)
        external
        returns (uint256);

    /**
     * @notice Get the tokenId of the `phoneNumber`
     * @param phoneNumber The phoneNumber of the owner to query
     * @return The tokenId owned by `owner`
     */
    function getTokenId(uint256 phoneNumber) external view returns (uint256);

    /**
     * @notice Get the owner of the `phoneNumber`
     * @param itemId The itemId of the owner to query
     * @return The wallet address owned by `owner`
     */
    function getOwnerOf(uint256 itemId) external view returns (address);

    /**
     * @notice Get the owner of the `phoneNumber`
     * @param ensName The ENS name that owner's own
     * @return The wallet address owned by `owner`
     */
    function getOwnerOfENS(string calldata ensName)
        external
        view
        returns (address);

    /**
     * @notice Check if ensName is already linked with user or not
     * @param ensName The ENS name that owner's own
     * @return Returns true if the specified ensName is not mapped with any tokenId
     */
    function available(string calldata ensName) external view returns (bool);

    /**
     * @notice The caller must own `tokenId` or be an approved operator.
     * @param tokenId The tokenId owned by the owner or an approved operator
     */
    function burnPPN(uint256 tokenId) external;

    /**
     * @notice Sets the price oracle address
     * @param _priceOracle The address of the price oracle to use.
     */
    function setOracle(PriceOracle _priceOracle) external;

    /**
     * @notice Check if `phoneNumber` is registered or not
     * @param itemId The itemId to check in the registry
     * @return The status whether it is exists or not
     */

    function isRegistered(uint256 itemId) external view returns (bool);
}

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

/**
  * @title Careful Math
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

// SPDX-License-Identifier: MIT
contract PaymentGateway is CarefulMath {
    PPNTokenInterface public ppnToken;

    uint256 internal PAYMENT_EXPIRY_PERIOD = 7 days;

    address payable public admin;
    address payable public pendingAdmin;

    event BnbTransfered(
        uint256 indexed senderId,
        uint256 indexed destinationId,
        uint256 amount
    );
    event BnbTransferedToWallet(
        uint256 indexed senderId,
        address indexed destinationAddress,
        uint256 amount
    );
    event ClaimBnbTransfered(
        uint256 indexed itemId,
        uint256 indexed senderId,
        uint256 indexed destinationId,
        uint256 amount
    );
    event RefundBnbTransfered(
        uint256 indexed itemId,
        uint256 indexed senderId,
        uint256 indexed destinationId,
        uint256 amount
    );
    event BnbAddedToEscrow(
        uint256 indexed itemId,
        uint256 indexed senderId,
        uint256 indexed destinationId,
        uint256 amount,
        uint256 expiresOn
    );

    event Bep20TokenTransfered(
        uint256 indexed senderId,
        uint256 indexed destinationId,
        address tokenAddress,
        uint256 amount
    );
    event Bep20TokenTransferedToWallet(
        uint256 indexed senderId,
        address indexed destinationAddress,
        address tokenAddress,
        uint256 amount
    );
    event ClaimBep20TokenTransfered(
        uint256 indexed itemId,
        uint256 indexed senderId,
        uint256 indexed destinationId,
        address tokenAddress,
        uint256 amount
    );
    event RefundBep20TokenTransfered(
        uint256 indexed itemId,
        uint256 indexed senderId,
        uint256 indexed destinationId,
        address tokenAddress,
        uint256 amount
    );
    event Bep20TokenAddedToEscrow(
        uint256 indexed itemId,
        uint256 indexed senderId,
        uint256 indexed destinationId,
        address tokenAddress,
        uint256 amount,
        uint256 expiresOn
    );

    struct EscrowPayment {
        uint256 senderId;
        uint256 destinationId;
        uint256 amount;
        uint256 expiryTime;
    }

    /**
     * @dev mapping escrow payments for BNB and BEP20 tokens
     */
    mapping(uint256 => EscrowPayment) public escrowBnbPayments;

    mapping(uint256 => mapping(address => EscrowPayment))
        public escrowBep20Payments;

    constructor(PPNTokenInterface ppnToken_) public {
        ppnToken = ppnToken_;
        admin = msg.sender;
    }

    /**
     * @notice Send binance from sender account to destination account if destination account has registered PPN, otherwise added it escorw
     * @param senderId The sender unique ID generated by PPN
     * @param destinationId The destination unique ID generated by PPN
     */

    function sendBnbAmount(uint256 senderId, uint256 destinationId)
        public
        payable
    {
        require(senderId != 0 && senderId != destinationId);
        require(
            ppnToken.isRegistered(senderId) &&
                ppnToken.getOwnerOf(senderId) == msg.sender
        );

        if (ppnToken.isRegistered(destinationId)) {
            address payable destinationAddress =
                payable(ppnToken.getOwnerOf(destinationId));
            destinationAddress.transfer(msg.value);
            emit BnbTransfered(senderId, destinationId, msg.value);
        } else {
            MathError error;
            uint256 expiryTime;
            (error, expiryTime) = addUInt(
                PAYMENT_EXPIRY_PERIOD,
                block.timestamp
            );

            uint256 mappingId = getUniqueId(senderId, destinationId);
            EscrowPayment storage payment = escrowBnbPayments[mappingId];

            if (payment.destinationId == destinationId) {
                (error, payment.amount) = addUInt(payment.amount, msg.value);
                payment.expiryTime = expiryTime;
            } else {
                escrowBnbPayments[mappingId] = EscrowPayment({
                    senderId: senderId,
                    destinationId: destinationId,
                    amount: msg.value,
                    expiryTime: expiryTime
                });
            }

            BnbAddedToEscrow(
                mappingId,
                senderId,
                destinationId,
                msg.value,
                expiryTime
            );
        }
    }

    /**
     * @notice Destination account claim the amount from the escorw
     * @param senderId The sender unique ID generated by PPN
     * @param destinationId The destination unique ID generated by PPN
     */

    function claimBnbAmount(uint256 senderId, uint256 destinationId) public {
        require(destinationId != 0 && senderId != destinationId);
        require(
            ppnToken.isRegistered(destinationId) &&
                ppnToken.getOwnerOf(destinationId) == msg.sender
        );
        uint256 mappingId = getUniqueId(senderId, destinationId);
        EscrowPayment storage payment = escrowBnbPayments[mappingId];
        require(
            payment.destinationId == destinationId &&
                payment.amount > 0 &&
                payment.expiryTime > block.timestamp
        );

        address payable destinationAddress =
            payable(ppnToken.getOwnerOf(destinationId));

        uint256 claimAmount = payment.amount;
        payment.amount = 0;

        destinationAddress.transfer(claimAmount);

        emit ClaimBnbTransfered(
            mappingId,
            senderId,
            destinationId,
            claimAmount
        );
    }

    /**
     * @notice Sender account claim the amount from the escorw when the payment expires
     * @param senderId The sender unique ID generated by PPN
     * @param destinationId The destination unique ID generated by PPN
     */

    function refundBnbAmount(uint256 senderId, uint256 destinationId) public {
        require(senderId != 0 && senderId != destinationId);
        require(
            ppnToken.isRegistered(senderId) &&
                ppnToken.getOwnerOf(senderId) == msg.sender
        );
        uint256 mappingId = getUniqueId(senderId, destinationId);
        EscrowPayment storage payment = escrowBnbPayments[mappingId];
        require(
            payment.senderId == senderId &&
                payment.amount > 0 &&
                payment.expiryTime < block.timestamp
        );

        address payable senderAddress = payable(ppnToken.getOwnerOf(senderId));

        uint256 refundAmount = payment.amount;
        payment.amount = 0;

        senderAddress.transfer(refundAmount);

        emit RefundBnbTransfered(
            mappingId,
            senderId,
            destinationId,
            refundAmount
        );
    }

    /**
     * @notice Send binance from sender account to destination account
     * @param senderId The sender unique ID generated by PPN
     * @param destinationAddress The destination account
     */

    function sendBnbAmountToWallet(
        uint256 senderId,
        address payable destinationAddress
    ) public payable {
        require(senderId != 0);
        require(
            ppnToken.isRegistered(senderId) &&
                ppnToken.getOwnerOf(senderId) == msg.sender
        );

        destinationAddress.transfer(msg.value);
        emit BnbTransferedToWallet(senderId, destinationAddress, msg.value);
    }

    /**
     * @notice Send BEP20 token from sender account to destination account if destination account has registered PPN, otherwise added it escorw
     * @param senderId The sender unique ID generated by PPN
     * @param destinationId The destination unique ID generated by PPN
     * @param token The BEP20 token address
     * @param amount The token value to be sent from the sender account
     */

    function sendBep20Token(
        uint256 senderId,
        uint256 destinationId,
        address token,
        uint256 amount
    ) public {
        require(
            senderId != 0 && senderId != destinationId && token != address(0x0)
        );
        require(
            ppnToken.isRegistered(senderId) &&
                ppnToken.getOwnerOf(senderId) == msg.sender
        );

        address senderAddress = ppnToken.getOwnerOf(senderId);
        if (ppnToken.isRegistered(destinationId)) {
            address payable destinationAddress =
                payable(ppnToken.getOwnerOf(destinationId));
            doTransferIn(token, senderAddress, destinationAddress, amount);
            emit Bep20TokenTransfered(senderId, destinationId, token, amount);
        } else {
            MathError error;
            uint256 expiryTime;
            (error, expiryTime) = addUInt(
                PAYMENT_EXPIRY_PERIOD,
                block.timestamp
            );

            uint256 mappingId = getUniqueId(senderId, destinationId);
            EscrowPayment storage payment =
                escrowBep20Payments[mappingId][address(token)];

            if (payment.destinationId == destinationId) {
                (error, payment.amount) = addUInt(payment.amount, amount);
                payment.expiryTime = expiryTime;
            } else {
                escrowBep20Payments[mappingId][address(token)] = EscrowPayment({
                    senderId: senderId,
                    destinationId: destinationId,
                    amount: amount,
                    expiryTime: expiryTime
                });
            }

            uint256 escrowAmount =
                doTransferIn(
                    token,
                    senderAddress,
                    payable(address(this)),
                    amount
                );

            Bep20TokenAddedToEscrow(
                mappingId,
                senderId,
                destinationId,
                token,
                escrowAmount,
                expiryTime
            );
        }
    }

    /**
     * @notice Destination account claim the amount from the escorw
     * @param senderId The sender unique ID generated by PPN
     * @param destinationId The destination unique ID generated by PPN
     * @param token The BEP20 token address
     */

    function claimBep20Token(
        uint256 senderId,
        uint256 destinationId,
        address token
    ) public {
        require(
            destinationId != 0 &&
                senderId != destinationId &&
                token != address(0x0)
        );
        require(
            ppnToken.isRegistered(destinationId) &&
                ppnToken.getOwnerOf(destinationId) == msg.sender
        );
        uint256 mappingId = getUniqueId(senderId, destinationId);
        EscrowPayment storage payment =
            escrowBep20Payments[mappingId][address(token)];
        require(
            payment.destinationId == destinationId &&
                payment.amount > 0 &&
                payment.expiryTime > block.timestamp
        );

        address payable destinationAddress =
            payable(ppnToken.getOwnerOf(destinationId));

        uint256 claimAmount = payment.amount;
        payment.amount = 0;

        doTransferOut(token, destinationAddress, claimAmount);

        emit ClaimBep20TokenTransfered(
            mappingId,
            senderId,
            destinationId,
            token,
            claimAmount
        );
    }

    /**
     * @notice Sender account claim the amount from the escorw when the payment expires
     * @param senderId The sender unique ID generated by PPN
     * @param destinationId The destination unique ID generated by PPN
     * @param token The BEP20 token address
     */

    function refundBep20Token(
        uint256 senderId,
        uint256 destinationId,
        address token
    ) public {
        require(
            senderId != 0 && senderId != destinationId && token != address(0x0)
        );
        require(
            ppnToken.isRegistered(senderId) &&
                ppnToken.getOwnerOf(senderId) == msg.sender
        );
        uint256 mappingId = getUniqueId(senderId, destinationId);
        EscrowPayment storage payment =
            escrowBep20Payments[mappingId][address(token)];
        require(
            payment.senderId == senderId &&
                payment.amount > 0 &&
                payment.expiryTime < block.timestamp
        );

        address payable senderAddress = payable(ppnToken.getOwnerOf(senderId));

        uint256 refundAmount = payment.amount;
        payment.amount = 0;

        doTransferOut(token, senderAddress, refundAmount);

        emit RefundBep20TokenTransfered(
            mappingId,
            senderId,
            destinationId,
            token,
            refundAmount
        );
    }

    /**
     * @notice Send BEP20 token from sender account to destination account
     * @param senderId The sender unique ID generated by PPN
     * @param destinationAddress The destination account
     * @param token The BEP20 token address
     * @param amount The token value to be sent from the sender account
     */

    function sendBep20TokenToWallet(
        uint256 senderId,
        address payable destinationAddress,
        address token,
        uint256 amount
    ) public {
        require(senderId != 0 && token != address(0x0));
        require(
            ppnToken.isRegistered(senderId) &&
                ppnToken.getOwnerOf(senderId) == msg.sender
        );

        address senderAddress = ppnToken.getOwnerOf(senderId);
        doTransferIn(token, senderAddress, destinationAddress, amount);
        emit Bep20TokenTransferedToWallet(
            senderId,
            destinationAddress,
            token,
            amount
        );
    }

    /**
     * @notice Sets new payment expiry period in days
     * @param paymentExpiryPeriod The expiry period in days
     */
    function setPaymentExpiryPeriod(uint256 paymentExpiryPeriod) public {
        // Check caller = admin
        require(msg.sender == admin);
        PAYMENT_EXPIRY_PERIOD = paymentExpiryPeriod;
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     */
    function _setPendingAdmin(address payable newPendingAdmin) public {
        // Check caller = admin
        require(msg.sender == admin);

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     */
    function _acceptAdmin() public {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin);
        require(msg.sender != address(0));

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferIn(
        address tokenAddress,
        address from,
        address payable to,
        uint256 amount
    ) internal returns (uint256) {
        EIP20NonStandardInterface token =
            EIP20NonStandardInterface(tokenAddress);
        uint256 balanceBefore =
            EIP20NonStandardInterface(token).balanceOf(address(this));
        token.transferFrom(from, to, amount);
        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := not(0) // set success to true
                }
                case 32 {
                    // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter =
            EIP20NonStandardInterface(token).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(
        address tokenAddress,
        address payable to,
        uint256 amount
    ) internal returns (uint256) {
        EIP20NonStandardInterface token =
            EIP20NonStandardInterface(address(tokenAddress));
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := not(0) // set success to true
                }
                case 32 {
                    // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");

        return 0;
    }

    /**
     * @notice Generate a unique Id from the sender and destination numbers
     * @param fromNumber The sender Id
     * @param toNumber The destination Id
     * @return The unique Id
     */

    function getUniqueId(uint256 fromNumber, uint256 toNumber)
        internal
        pure
        returns (uint256)
    {
        string memory label =
            append(uintToStr(fromNumber), "", uintToStr(toNumber));
        bytes32 hash = keccak256(bytes(label));
        return uint256(hash);
    }

    /**
     * @notice Convert from given uint to string
     * @param _i The integer value
     * @return _uintAsString The string value
     */

    function uintToStr(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        uint256 number = _i;
        if (number == 0) {
            return "0";
        }
        uint256 j = number;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (number != 0) {
            bstr[k--] = bytes1(uint8(48 + (number % 10)));
            number /= 10;
        }
        return string(bstr);
    }

    /**
     * @notice Concatenate the given string values
     * @param a The first string value
     * @param b The second string value
     * @param c The third string value
     * @return The string value
     */

    function append(
        string memory a,
        string memory b,
        string memory c
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }
}