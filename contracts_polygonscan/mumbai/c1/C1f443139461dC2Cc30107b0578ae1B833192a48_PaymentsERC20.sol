// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./FeesCollectors.sol";
import "./EIP712Verifier.sol";

/**
 * @title Payments Contract in ERC20.
 * @author Freeverse.io, www.freeverse.io
 * @dev Upon transfer of ERC20 tokens to this contract, these remain
 * locked until an Operator confirms the success of failure of the
 * asset transfer required to fulfil this payment.
 *
 * If no confirmation is recevied from the operator during the PaymentWindow,
 * all of buyer's received tokens are made available to the buyer for refund.
 *
 * To start a payment, the signatures of both the buyer and the Operator are required.
 * - in the 'relayedPay' method, the Operator is the msg.sender, and the buyerSig is provided;
 * - in the 'pay' method, the buyer is the msg.sender, and the operatorSig is provided.
 *
 * This contract maintains the balances of all users, it does not transfer them automatically.
 * Users need to explicitly call the 'withdraw' method, which withdraws balanceOf[msg.sender]
 * If a buyer has non-zero local balance at the moment of starting a new payment, 
 * the contract reuses it, and only transfers the remainder required (if any) 
 * from the external ERC20 contract. 
 *
 * Each payment has the following States Machine:
 * - NOT_STARTED -> ASSET_TRANSFERRING, triggered by pay/relayedPay
 * - ASSET_TRANSFERRING -> PAID, triggered by assetTransferSuccess
 * - ASSET_TRANSFERRING -> FAILED, triggered implicitly by now > expirationTime
 * - ASSET_TRANSFERRING -> NOT_STARTED, triggered by assetTransferFailure
 * - FAILED -> NOT_STARTED, triggered by refund or refundAndWithdraw
 * - FAILED -> ASSET_TRANSFERRING, triggered by new pay/relayedPay
 *
 * NOTE: To ensure that the a payment process proceeds as expected when the payment starts,
 * upon acceptance of a pay/relatedPay, the following data: {operator, feesCollector, expirationTime}
 * is stored in the payment struct, and used throught the payment, regardless of
 * any possible modifications to the contract's storage.
 *
 */

import "./IPaymentsERC20.sol";

contract PaymentsERC20 is IPaymentsERC20, FeesCollectors, EIP712Verifier {

    address private _erc20;
    string private _acceptedCurrency;
    uint256 private _paymentWindow;
    bool private _isSellerRegistrationRequired;
    mapping(address => bool) private _isRegisteredSeller;
    mapping(bytes32 => Payment) private _payments;
    mapping(address => uint256) private _balanceOf;

    constructor(address erc20Address, string memory currencyDescriptor) {
        _erc20 = erc20Address;
        _acceptedCurrency = currencyDescriptor;
        _paymentWindow = 10 days;
        _isSellerRegistrationRequired = true;
    }

    /**
     * @notice Sets the amount of time available to the operator, after the payment starts,
     *  to confirm either the success or the failure of the asset transfer. 
     *  After this time, the payment moves to FAILED, allowing buyer to withdraw.
     * @param window The amount of time available, in seconds.
     */
    function setPaymentWindow(uint256 window) external onlyOwner {
        _paymentWindow = window;
        emit PaymentWindow(window);
    }

    /**
     * @notice Sets whether sellers are required to register in this contract before being
     *  able to accept payments. 
     * @param isRequired (bool) if true, registration is required.
     */
    function setIsSellerRegistrationRequired(bool isRequired)
        external
        onlyOwner
    {
        _isSellerRegistrationRequired = isRequired;
    }

    /// @inheritdoc IPaymentsERC20
    function registerAsSeller() external {
        _isRegisteredSeller[msg.sender] = true;
        emit NewSeller(msg.sender);
    }

    /// @inheritdoc IPaymentsERC20
    function relayedPay(
        PaymentInput calldata inp,
        bytes calldata buyerSignature
    ) external {
        require(
            universeOperator(inp.universeId) == msg.sender,
            "operator not authorized for this universeId"
        );
        if (paymentState(inp.paymentId) == States.Failed)
            _refund(inp.paymentId);
        checkPaymentInputs(inp);
        require(
            verify(inp, buyerSignature, inp.buyer),
            "incorrect buyer signature"
        );
        _payments[inp.paymentId] = Payment(
            States.AssetTransferring,
            inp.buyer,
            inp.seller,
            msg.sender,
            universeFeesCollector(inp.universeId),
            block.timestamp + _paymentWindow,
            inp.feeBPS,
            inp.amount
        );
        (uint256 newFunds, uint256 localFunds) = splitFundingSources(
            inp.buyer,
            inp.amount
        );
        if (newFunds > 0) {
            require(
                IERC20(_erc20).transferFrom(inp.buyer, address(this), newFunds),
                "ERC20 transfer failed"
            );
        }
        _balanceOf[inp.buyer] -= localFunds;
        emit Payin(inp.paymentId, inp.buyer, inp.seller);
    }

    /// @inheritdoc IPaymentsERC20
    function pay(PaymentInput calldata inp, bytes calldata operatorSignature)
        external
    {
        require(
            msg.sender == inp.buyer,
            "only buyer can execute this function"
        );
        if (paymentState(inp.paymentId) == States.Failed)
            _refund(inp.paymentId);
        checkPaymentInputs(inp);
        address operator = universeOperator(inp.universeId);
        require(
            verify(inp, operatorSignature, operator),
            "incorrect operator signature"
        );

        _payments[inp.paymentId] = Payment(
            States.AssetTransferring,
            inp.buyer,
            inp.seller,
            operator,
            universeFeesCollector(inp.universeId),
            block.timestamp + _paymentWindow,
            inp.feeBPS,
            inp.amount
        );
        (uint256 newFunds, uint256 localFunds) = splitFundingSources(
            inp.buyer,
            inp.amount
        );
        if (newFunds > 0) {
            require(
                IERC20(_erc20).transferFrom(inp.buyer, address(this), newFunds),
                "ERC20 transfer failed"
            );
        }
        _balanceOf[inp.buyer] -= localFunds;
        emit Payin(inp.paymentId, inp.buyer, inp.seller);
    }

    /// @inheritdoc IPaymentsERC20
    function assetTransferSuccess(bytes32 paymentId) external {
        Payment memory p = _payments[paymentId];
        require(
            msg.sender == p.operator,
            "only payment operator is authorized"
        );
        require(
            States.AssetTransferring == paymentState(paymentId),
            "payment not initially in asset transferring state"
        );
        _payments[paymentId].state = States.Paid;
        uint256 feeAmount = computeFeeAmount(p.amount, uint256(p.feeBPS));
        _balanceOf[p.seller] += (p.amount - feeAmount);
        _balanceOf[p.feesCollector] += feeAmount;
        emit Paid(paymentId);
    }

    /// @inheritdoc IPaymentsERC20
    function assetTransferFailed(bytes32 paymentId) external {
        require(
            msg.sender == _payments[paymentId].operator,
            "only payment operator is authorized"
        );
        require(
            States.AssetTransferring == paymentState(paymentId),
            "payment not initially in asset transferring state"
        );
        _refund(paymentId);
    }

    /// @inheritdoc IPaymentsERC20
    function refund(bytes32 paymentId) external {
        require(
            paymentState(paymentId) == States.Failed,
            "refund requires payment in failed state"
        );
        _refund(paymentId);
    }

    /// @inheritdoc IPaymentsERC20
    function refundAndWithdraw(bytes32 paymentId) external {
        require(
            paymentState(paymentId) == States.Failed,
            "refund requires payment in failed state"
        );
        _refund(paymentId);
        _withdraw();
    }

    /// @inheritdoc IPaymentsERC20
    function withdraw() external {
        _withdraw();
    }

    // PRIVATE FUNCTIONS

    /**
     * @dev (private) Executes refund, moves to NOT_STARTED state
     * @param paymentId The unique ID that identifies the payment.
     */
    function _refund(bytes32 paymentId) private {
        Payment memory p = _payments[paymentId];
        _balanceOf[p.buyer] += p.amount;
        delete _payments[paymentId];
        emit BuyerRefunded(paymentId, p.buyer);
    }

    /**
     * @dev (private) Transfers ERC20 avaliable in this
     *  contract's balanceOf[msg.sender] to msg.sender
     *  Follows standard Checks-Effects-Interactions pattern
     *  to protect against re-entrancy attacks.
     */
    function _withdraw() private {
        uint256 amount = _balanceOf[msg.sender];
        require(amount > 0, "cannot withdraw: balance is zero");
        _balanceOf[msg.sender] = 0;
        IERC20(_erc20).transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    // VIEW FUNCTIONS

    /// @inheritdoc IPaymentsERC20
    function isSellerRegistrationRequired() external view returns (bool) {
        return _isSellerRegistrationRequired;
    }

    /// @inheritdoc IPaymentsERC20
    function isRegisteredSeller(address addr) external view returns (bool) {
        return _isRegisteredSeller[addr];
    }

    /// @inheritdoc IPaymentsERC20
    function erc20() external view returns (address) {
        return _erc20;
    }

    /// @inheritdoc IPaymentsERC20
    function balanceOf(address addr) external view returns (uint256) {
        return _balanceOf[addr];
    }

    /// @inheritdoc IPaymentsERC20
    function erc20BalanceOf(address addr) external view returns (uint256) {
        return IERC20(_erc20).balanceOf(addr);
    }

    /// @inheritdoc IPaymentsERC20
    function allowance(address buyer) public view returns (uint256) {
        return IERC20(_erc20).allowance(buyer, address(this));
    }

    /// @inheritdoc IPaymentsERC20
    function paymentInfo(bytes32 paymentId)
        external
        view
        returns (Payment memory)
    {
        return _payments[paymentId];
    }

    /// @inheritdoc IPaymentsERC20
    function paymentState(bytes32 paymentId) public view returns (States) {
        States state = _payments[paymentId].state;
        if (
            state == States.AssetTransferring &&
            block.timestamp > _payments[paymentId].expirationTime
        ) return States.Failed;
        return state;
    }

    /// @inheritdoc IPaymentsERC20
    function paymentWindow() external view returns (uint256) {
        return _paymentWindow;
    }

    /// @inheritdoc IPaymentsERC20
    function acceptedCurrency() external view returns (string memory) {
        return _acceptedCurrency;
    }

    /// @inheritdoc IPaymentsERC20
    function enoughFundsAvailable(address buyer, uint256 amount)
        public
        view
        returns (bool)
    {
        return maxFundsAvailable(buyer) >= amount;
    }

    /// @inheritdoc IPaymentsERC20
    function maxFundsAvailable(address buyer) public view returns (uint256) {
        uint256 approved = allowance(buyer);
        uint256 erc20Balance = IERC20(_erc20).balanceOf(buyer);
        uint256 externalAvailable = (approved < erc20Balance)
            ? approved
            : erc20Balance;
        return _balanceOf[buyer] + externalAvailable;
    }

    /// @inheritdoc IPaymentsERC20
    function splitFundingSources(address buyer, uint256 amount)
        public
        view
        returns (uint256 externalFunds, uint256 localFunds)
    {
        uint256 localBalance = _balanceOf[buyer];
        localFunds = (amount > localBalance) ? localBalance : amount;
        externalFunds = (amount > localBalance) ? amount - localBalance : 0;
    }

    /// @inheritdoc IPaymentsERC20
    function checkPaymentInputs(PaymentInput calldata inp) public view {
        require(inp.feeBPS <= 10000, "fee cannot be larger than 100 percent");
        require(
            paymentState(inp.paymentId) == States.NotStarted,
            "payment in incorrect curent state"
        );
        require(block.timestamp <= inp.validUntil, "payment deadline expired");
        if (_isSellerRegistrationRequired)
            require(_isRegisteredSeller[inp.seller], "seller not registered");
        require(
            enoughFundsAvailable(inp.buyer, inp.amount),
            "not enough funds available for this buyer"
        );
    }

    // PURE FUNCTIONS

    /// @inheritdoc IPaymentsERC20
    function computeFeeAmount(uint256 amount, uint256 feeBPS)
        public
        pure
        returns (uint256)
    {
        uint256 feeAmount = (amount * feeBPS) / 10000;
        return (feeAmount <= amount) ? feeAmount : amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

/**
 * @title Management of Operators.
 * @author Freeverse.io, www.freeverse.io
 * @dev The Operator role is to execute the actions required when
 * payments arrive to this contract, and then either
 * confirm the success of those actions, or confirm the failure.
 *
 * The constructor sets a defaultOperator = deployer.
 * The owner of the contract can change the defaultOperator.
 *
 * The owner of the contract can assign explicit operators to each universe.
 * If a universe does not have an explicitly assigned operator,
 * the default operator is used.
 */

contract Operators is Ownable {
    event DefaultOperator(address operator);
    event UniverseOperator(uint256 universeId, address operator);

    address private _defaultOperator;
    mapping(uint256 => address) private _universeOperators;

    constructor() {
        _defaultOperator = msg.sender;
        emit DefaultOperator(msg.sender);
    }

    function setDefaultOperator(address operator) external onlyOwner {
        _defaultOperator = operator;
        emit DefaultOperator(operator);
    }

    function setUniverseOperator(uint256 universeId, address operator)
        external
        onlyOwner
    {
        _universeOperators[universeId] = operator;
        emit UniverseOperator(universeId, operator);
    }

    function removeUniverseOperator(uint256 universeId) external onlyOwner {
        delete _universeOperators[universeId];
        emit UniverseOperator(universeId, _defaultOperator);
    }

    function defaultOperator() external view returns (address) {
        return _defaultOperator;
    }

    function universeOperator(uint256 universeId)
        public
        view
        returns (address)
    {
        address storedOperator = _universeOperators[universeId];
        return storedOperator == address(0) ? _defaultOperator : storedOperator;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./FeesCollectors.sol";
import "./EIP712Verifier.sol";

/**
 * @title Interface to Payments Contract in ERC20.
 * @author Freeverse.io, www.freeverse.io
 * @dev Upon transfer of ERC20 tokens to this contract, these remain
 * locked until an Operator confirms the success of failure of the
 * asset transfer required to fulfil this payment.
 *
 * If no confirmation is recevied from the operator during the PaymentWindow,
 * all of buyer's received tokens are made available to the buyer for refund.
 *
 * To start a payment, the signatures of both the buyer and the Operator are required.
 * - in the 'relayedPay' method, the Operator is the msg.sender, and the buyerSig is provided;
 * - in the 'pay' method, the buyer is the msg.sender, and the operatorSig is provided.
 *
 * This contract maintains the balances of all users, it does not transfer them automatically.
 * Users need to explicitly call the 'withdraw' method, which withdraws balanceOf[msg.sender]
 * If a buyer has non-zero local balance at the moment of starting a new payment, 
 * the contract reuses it, and only transfers the remainder required (if any) 
 * from the external ERC20 contract. 
 *
 * Each payment has the following States Machine:
 * - NOT_STARTED -> ASSET_TRANSFERRING, triggered by pay/relayedPay
 * - ASSET_TRANSFERRING -> PAID, triggered by assetTransferSuccess
 * - ASSET_TRANSFERRING -> FAILED, triggered implicitly by now > expirationTime
 * - ASSET_TRANSFERRING -> NOT_STARTED, triggered by assetTransferFailure
 * - FAILED -> NOT_STARTED, triggered by refund or refundAndWithdraw
 * - FAILED -> ASSET_TRANSFERRING, triggered by new pay/relayedPay
 *
 * NOTE: To ensure that the a payment process proceeds as expected when the payment starts,
 * upon acceptance of a pay/relatedPay, the following data: {operator, feesCollector, expirationTime}
 * is stored in the payment struct, and used throught the payment, regardless of
 * any possible modifications to the contract's storage.
 *
 */

import './IEIP712Verifier.sol';

interface IPaymentsERC20 is IEIP712Verifier {
    event PaymentWindow(uint256 window);
    event NewSeller(address indexed seller);
    event BuyerRefunded(bytes32 indexed paymentId, address indexed buyer);
    event Payin(
        bytes32 indexed paymentId,
        address indexed buyer,
        address indexed seller
    );
    event Paid(bytes32 paymentId);
    event Withdraw(address indexed user, uint256 amount);

    enum States {
        NotStarted,
        AssetTransferring,
        Failed,
        Paid
    }

    /**
     * @notice Main struct stored with every payment.
     *  feeBPS is the percentage fee expressed in Basis Points (bps), typical in finance
     *  Examples:  2.5% = 250 bps, 10% = 1000 bps, 100% = 10000 bps
     */
    struct Payment {
        States state;
        address buyer;
        address seller;
        address operator;
        address feesCollector;
        uint256 expirationTime;
        uint16 feeBPS;
        uint256 amount;
    }

    /**
     * @notice Registers msg.sender as seller so that he/she can accept payments.
     */
    function registerAsSeller() external;

    /**
     * @notice Starts the Payment process via relay-by-operator.
     * @dev Executed by an operator, who relays the MetaTX with the buyer's signature.
     *  The buyer must have approved the amount to this contract before.
     *  If all requirements are fulfilled, it stores the data relevant
     *  for the next steps of the payment, and it locks the ERC20
     *  in this contract.
     *  Follows standard Checks-Effects-Interactions pattern
     *  to protect against re-entrancy attacks.
     *  Moves payment to ASSET_TRANSFERRING state.
     * @param inp The struct containing all required payment data
     * @param buyerSignature The signature of 'inp' by the buyer
     */
    function relayedPay(
        PaymentInput calldata inp,
        bytes calldata buyerSignature
    ) external;

    /**
     * @notice Starts Payment process directly by the buyer.
     * @dev Executed by the buyer, who relays the MetaTX with the operator's signature.
     *  The buyer must have approved the amount to this contract before.
     *  If all requirements are fulfilled, it stores the data relevant
     *  for the next steps of the payment, and it locks the ERC20
     *  in this contract.
     *  Follows standard Checks-Effects-Interactions pattern
     *  to protect against re-entrancy attacks.
     *  Moves payment to ASSET_TRANSFERRING state.
     * @param inp The struct containing all required payment data
     * @param operatorSignature The signature of 'inp' by the operator
     */
    function pay(PaymentInput calldata inp, bytes calldata operatorSignature) external;

    /**
     * @notice Confirms the asset transfer.
     * @dev Needs to be executed by the operator.
     *  Updates balances of seller and feesCollector.
     *  Moves payment to PAID state.
     * @param paymentId The unique ID that identifies the payment.
     */
    function assetTransferSuccess(bytes32 paymentId) external;

    /**
     * @notice Confirms the failure of asset transfer and refunds buyer.
     * @dev Needs to be executed by the operator.
     *  Buyer's balance is updated, allowing explicit withdrawal.
     *  It resets all data related to this payment.
     *  Moves payment to NOT_STARTED state.
     * @param paymentId The unique ID that identifies the payment.
     */
    function assetTransferFailed(bytes32 paymentId) external;

    /**
     * @notice Moves buyer's provided funds to buyer's balance.
     * @dev Anybody can call this function.
     *  Requires current state == FAILED to proceed.
     *  After updating buyer's balance, he/she can later withdraw.
     *  It resets all data related to this payment.
     *  Moves payment to NOT_STARTED state.
     * @param paymentId The unique ID that identifies the payment.
     */
    function refund(bytes32 paymentId) external;

    /**
     * @notice Executes refund and withdraw in one transaction.
     * @dev Needs to be called by buyer.
     *  All of buyer's balance in the contract is withdrawn,
     *  not only the part that was locked in this particular paymentId
     *  Moves payment to NOT_STARTED state.
     * @param paymentId The unique ID that identifies the payment.
     */
    function refundAndWithdraw(bytes32 paymentId) external;

    /**
     * @notice Transfers ERC20 avaliable in this
     *  contract's balanceOf[msg.sender] to msg.sender
     */
    function withdraw() external;

    // VIEW FUNCTIONS

    /**
     * @notice Returns whether sellers need to be registered to be able to accept payments
     * @return Returns true if sellers need to be registered to be able to accept payments
     */    
    function isSellerRegistrationRequired() external view returns (bool);

    /**
     * @notice Returns true if the address provided is a registered seller
     * @param addr the address that is queried
     * @return Returns whether the address is registered as seller
     */    
    function isRegisteredSeller(address addr) external view returns (bool);

    /**
     * @notice Returns the address of the ERC20 contract from which
     *  tokens are accepted for payments
     * @return the address of the ERC20 contract
     */
    function erc20() external view returns (address);

    /**
     * @notice Returns the local ERC20 balance of address that is stored in this
     *  contract, and hence, available for withdrawal.
     * @param addr the address that is queried
     * @return the local balance
     */
    function balanceOf(address addr) external view returns (uint256);

    /**
     * @notice Returns the ERC20 balance of address in the ERC20 contract
     * @param addr the address that is queried
     * @return the balance in the external ERC20 contract
     */
    function erc20BalanceOf(address addr) external view returns (uint256);

    /**
     * @notice Returns the allowance that the buyer has approved
     *  directly in the ERC20 contract in favour of this contract.
     * @param buyer the address of the buyer
     * @return the amount allowed by buyer
     */
    function allowance(address buyer) external view returns (uint256);

    /**
     * @notice Returns all data stored in a payment
     * @param paymentId The unique ID that identifies the payment.
     * @return the struct stored for the payment
     */
    function paymentInfo(bytes32 paymentId)
        external
        view
        returns (Payment memory);

    /**
     * @notice Returns the state of a payment.
     * @dev It maps 1-to-1 with the stored variable, with the exeption of
     *  an ASSET_TRANSFERRING that has gone beyond expirationTime.
     * @param paymentId The unique ID that identifies the payment.
     * @return the state of the payment.
     */
    function paymentState(bytes32 paymentId) external view returns (States);

    /**
     * @notice Returns the amount of seconds that a payment
     *  can remain in ASSET_TRANSFERRING state without positive
     *  or negative confirmation by the operator
     * @return the payment window in secs
     */
    function paymentWindow() external view returns (uint256);

    /**
     * @notice Returns a descriptor about the currency that this contract accepts
     * @return the string describing the currency
     */
    function acceptedCurrency() external view returns (string memory);

    /**
     * @notice Returns true if the 'amount' required for a payment is available to this contract.
     * @dev In more detail: returns true if the sum of the buyer's local balance in this contract,
     *  plus funds available and approved in the ERC20 contract, are larger or equal than 'amount'
     * @param buyer The address for which funds are queried
     * @param amount The amount that is queried
     * @return Returns true if enough funds are available
     */
    function enoughFundsAvailable(address buyer, uint256 amount)
        external
        view
        returns (bool);

    /**
     * @notice Returns the maximum amount of funds available to a buyer
     * @dev In more detail: returns the sum of the buyer's local balance in this contract,
     *  plus the funds available and approved in the ERC20 contract.
     * @param buyer The address for which funds are queried
     * @return the max funds available
     */
    function maxFundsAvailable(address buyer) external view returns (uint256);

    /**
     * @notice Splits the funds required to pay 'amount' into two source:
     *  - externalFunds: the amount of ERC20 required to be transferred from the external ERC20 contract
     *  - localFunds: the amount of ERC20 from the buyer's already available balance in this contract.
     * @param buyer The address for which the amount is to be split
     * @param amount The amount to be split
     * @return externalFunds The amount of ERC20 required from the external ERC20 contract.
     * @return localFunds The amount of ERC20 local funds required. 
     */
    function splitFundingSources(address buyer, uint256 amount)
        external
        view
        returns (uint256 externalFunds, uint256 localFunds);

    /**
     * @notice Reverts unless the requirements for a PaymentInput that
     *  are common to both pay and relayedPay are fulfilled.
     * @param inp The PaymentInput struct
     */
    function checkPaymentInputs(PaymentInput calldata inp) external view;

    // PURE FUNCTIONS

    /**
     * @notice Safe computation of fee amount for a provided amount, feeBPS pair
     * @dev Must return a value that is guaranteed to be less or equal to the provided amount
     * @param amount The amount
     * @param feeBPS The percentage fee expressed in Basis Points (bps).
     *  feeBPS examples:  2.5% = 250 bps, 10% = 1000 bps, 100% = 10000 bps
     * @return The fee amount
     */
    function computeFeeAmount(uint256 amount, uint256 feeBPS)
        external
        pure
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "openzeppelin-solidity/contracts/utils/cryptography/draft-EIP712.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Interface to Verification of MetaTXs for Payments using EIP712.
 * @author Freeverse.io, www.freeverse.io
 * @dev This contract just defines the structure of a Payment Input
 * and exposes a verify function, using the EIP712 code by OpenZeppelin
 */

interface IEIP712Verifier {
    struct PaymentInput {
        bytes32 paymentId;
        uint256 amount;
        uint16 feeBPS;
        uint256 universeId;
        uint256 validUntil;
        address buyer;
        address seller;
    }

    /** 
     * @notice Verifies that the provided input struct has been signed 
     * by the provided signer.
     * @param inp The provided PaymentInput struct 
     * @param signature The provided signature of the input struct
     * @param signer The signer's address that we want to verify
     * @return Returns true if the signature corresponds to the signer 
     * having signed the input struct 
     */
    function verify(
        PaymentInput calldata inp,
        bytes calldata signature,
        address signer
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "./Operators.sol";

/**
 * @title Management of Fees Collectors.
 * @author Freeverse.io, www.freeverse.io
 * @dev FeesCollectors are just the addresses to which fees
 * are paid when payments are successfully completed.
 *
 * The constructor sets a defaultFeesCollector = deployer.
 * The owner of the contract can change the defaultFeesCollector.
 *
 * The owner of the contract can assign explicit feesCollectors to each universe.
 * If a universe does not have an explicitly assigned feesCollector,
 * the default feesCollector is used.
 */

contract FeesCollectors is Operators {
    event DefaultFeesCollector(address feesCollector);
    event UniverseFeesCollector(uint256 universeId, address feesCollector);

    address private _defaultFeesCollector;
    mapping(uint256 => address) private _universeFeesCollectors;

    constructor() {
        _defaultFeesCollector = msg.sender;
        emit DefaultFeesCollector(msg.sender);
    }

    function setDefaultFeesCollector(address feesCollector) external onlyOwner {
        _defaultFeesCollector = feesCollector;
        emit DefaultFeesCollector(feesCollector);
    }

    function setUniverseFeesCollector(uint256 universeId, address feesCollector)
        external
        onlyOwner
    {
        _universeFeesCollectors[universeId] = feesCollector;
        emit UniverseFeesCollector(universeId, feesCollector);
    }

    function removeUniverseFeesCollector(uint256 universeId)
        external
        onlyOwner
    {
        delete _universeFeesCollectors[universeId];
        emit UniverseFeesCollector(universeId, _defaultFeesCollector);
    }

    function defaultFeesCollector() external view returns (address) {
        return _defaultFeesCollector;
    }

    function universeFeesCollector(uint256 universeId)
        public
        view
        returns (address)
    {
        address storedFeesCollector = _universeFeesCollectors[universeId];
        return
            storedFeesCollector == address(0)
                ? _defaultFeesCollector
                : storedFeesCollector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "openzeppelin-solidity/contracts/utils/cryptography/draft-EIP712.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Verification of MetaTXs for Payments using EIP712.
 * @author Freeverse.io, www.freeverse.io
 * @dev This contract defines the structure of a Payment Input
 * and exposes a verify function, using the EIP712 code by OpenZeppelin
 */

import './IEIP712Verifier.sol';

contract EIP712Verifier is IEIP712Verifier, EIP712 {
    using ECDSA for bytes32;
    bytes32 private constant _TYPEHASH =
        keccak256(
            "PaymentInput(bytes32 paymentId,uint256 amount,uint16 feeBPS,uint256 universeId,uint256 validUntil,address buyer,address seller)"
        );

    constructor() EIP712("EIP712-FV-Payments", "0.0.1") {}

    function verify(
        PaymentInput calldata inp,
        bytes calldata signature,
        address signer
    ) public view returns (bool) {
        address recoveredSigner = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _TYPEHASH,
                    inp.paymentId,
                    inp.amount,
                    inp.feeBPS,
                    inp.universeId,
                    inp.validUntil,
                    inp.buyer,
                    inp.seller
                )
            )
        ).recover(signature);
        return signer == recoveredSigner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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