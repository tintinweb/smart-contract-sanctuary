/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity >=0.4.25 <0.6.0;

pragma experimental ABIEncoderV2;

/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */


/**
 * @title Modifiable
 * @notice A contract with basic modifiers
 */
contract Modifiable {
    //
    // Modifiers
    // -----------------------------------------------------------------------------------------------------------------
    modifier notNullAddress(address _address) {
        require(_address != address(0));
        _;
    }

    modifier notThisAddress(address _address) {
        require(_address != address(this));
        _;
    }

    modifier notNullOrThisAddress(address _address) {
        require(_address != address(0));
        require(_address != address(this));
        _;
    }

    modifier notSameAddresses(address _address1, address _address2) {
        if (_address1 != _address2)
            _;
    }
}

/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */



/**
 * @title SelfDestructible
 * @notice Contract that allows for self-destruction
 */
contract SelfDestructible {
    //
    // Variables
    // -----------------------------------------------------------------------------------------------------------------
    bool public selfDestructionDisabled;

    //
    // Events
    // -----------------------------------------------------------------------------------------------------------------
    event SelfDestructionDisabledEvent(address wallet);
    event TriggerSelfDestructionEvent(address wallet);

    //
    // Functions
    // -----------------------------------------------------------------------------------------------------------------
    /// @notice Get the address of the destructor role
    function destructor()
    public
    view
    returns (address);

    /// @notice Disable self-destruction of this contract
    /// @dev This operation can not be undone
    function disableSelfDestruction()
    public
    {
        // Require that sender is the assigned destructor
        require(destructor() == msg.sender);

        // Disable self-destruction
        selfDestructionDisabled = true;

        // Emit event
        emit SelfDestructionDisabledEvent(msg.sender);
    }

    /// @notice Destroy this contract
    function triggerSelfDestruction()
    public
    {
        // Require that sender is the assigned destructor
        require(destructor() == msg.sender);

        // Require that self-destruction has not been disabled
        require(!selfDestructionDisabled);

        // Emit event
        emit TriggerSelfDestructionEvent(msg.sender);

        // Self-destruct and reward destructor
        selfdestruct(msg.sender);
    }
}

/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */






/**
 * @title Ownable
 * @notice A modifiable that has ownership roles
 */
contract Ownable is Modifiable, SelfDestructible {
    //
    // Variables
    // -----------------------------------------------------------------------------------------------------------------
    address public deployer;
    address public operator;

    //
    // Events
    // -----------------------------------------------------------------------------------------------------------------
    event SetDeployerEvent(address oldDeployer, address newDeployer);
    event SetOperatorEvent(address oldOperator, address newOperator);

    //
    // Constructor
    // -----------------------------------------------------------------------------------------------------------------
    constructor(address _deployer) internal notNullOrThisAddress(_deployer) {
        deployer = _deployer;
        operator = _deployer;
    }

    //
    // Functions
    // -----------------------------------------------------------------------------------------------------------------
    /// @notice Return the address that is able to initiate self-destruction
    function destructor()
    public
    view
    returns (address)
    {
        return deployer;
    }

    /// @notice Set the deployer of this contract
    /// @param newDeployer The address of the new deployer
    function setDeployer(address newDeployer)
    public
    onlyDeployer
    notNullOrThisAddress(newDeployer)
    {
        if (newDeployer != deployer) {
            // Set new deployer
            address oldDeployer = deployer;
            deployer = newDeployer;

            // Emit event
            emit SetDeployerEvent(oldDeployer, newDeployer);
        }
    }

    /// @notice Set the operator of this contract
    /// @param newOperator The address of the new operator
    function setOperator(address newOperator)
    public
    onlyOperator
    notNullOrThisAddress(newOperator)
    {
        if (newOperator != operator) {
            // Set new operator
            address oldOperator = operator;
            operator = newOperator;

            // Emit event
            emit SetOperatorEvent(oldOperator, newOperator);
        }
    }

    /// @notice Gauge whether message sender is deployer or not
    /// @return true if msg.sender is deployer, else false
    function isDeployer()
    internal
    view
    returns (bool)
    {
        return msg.sender == deployer;
    }

    /// @notice Gauge whether message sender is operator or not
    /// @return true if msg.sender is operator, else false
    function isOperator()
    internal
    view
    returns (bool)
    {
        return msg.sender == operator;
    }

    /// @notice Gauge whether message sender is operator or deployer on the one hand, or none of these on these on
    /// on the other hand
    /// @return true if msg.sender is operator, else false
    function isDeployerOrOperator()
    internal
    view
    returns (bool)
    {
        return isDeployer() || isOperator();
    }

    // Modifiers
    // -----------------------------------------------------------------------------------------------------------------
    modifier onlyDeployer() {
        require(isDeployer());
        _;
    }

    modifier notDeployer() {
        require(!isDeployer());
        _;
    }

    modifier onlyOperator() {
        require(isOperator());
        _;
    }

    modifier notOperator() {
        require(!isOperator());
        _;
    }

    modifier onlyDeployerOrOperator() {
        require(isDeployerOrOperator());
        _;
    }

    modifier notDeployerOrOperator() {
        require(!isDeployerOrOperator());
        _;
    }
}

/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */




/**
 * @title     MonetaryTypesLib
 * @dev       Monetary data types
 */
library MonetaryTypesLib {
    //
    // Structures
    // -----------------------------------------------------------------------------------------------------------------
    struct Currency {
        address ct;
        uint256 id;
    }

    struct Figure {
        int256 amount;
        Currency currency;
    }

    struct NoncedAmount {
        uint256 nonce;
        int256 amount;
    }
}

/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */





/**
 * @title     NahmiiTypesLib
 * @dev       Data types of general nahmii character
 */
library NahmiiTypesLib {
    //
    // Enums
    // -----------------------------------------------------------------------------------------------------------------
    enum ChallengePhase {Dispute, Closed}

    //
    // Structures
    // -----------------------------------------------------------------------------------------------------------------
    struct OriginFigure {
        uint256 originId;
        MonetaryTypesLib.Figure figure;
    }

    struct IntendedConjugateCurrency {
        MonetaryTypesLib.Currency intended;
        MonetaryTypesLib.Currency conjugate;
    }

    struct SingleFigureTotalOriginFigures {
        MonetaryTypesLib.Figure single;
        OriginFigure[] total;
    }

    struct TotalOriginFigures {
        OriginFigure[] total;
    }

    struct CurrentPreviousInt256 {
        int256 current;
        int256 previous;
    }

    struct SingleTotalInt256 {
        int256 single;
        int256 total;
    }

    struct IntendedConjugateCurrentPreviousInt256 {
        CurrentPreviousInt256 intended;
        CurrentPreviousInt256 conjugate;
    }

    struct IntendedConjugateSingleTotalInt256 {
        SingleTotalInt256 intended;
        SingleTotalInt256 conjugate;
    }

    struct WalletOperatorHashes {
        bytes32 wallet;
        bytes32 operator;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct Seal {
        bytes32 hash;
        Signature signature;
    }

    struct WalletOperatorSeal {
        Seal wallet;
        Seal operator;
    }
}

/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */






/**
 * @title     PaymentTypesLib
 * @dev       Data types centered around payment
 */
library PaymentTypesLib {
    //
    // Enums
    // -----------------------------------------------------------------------------------------------------------------
    enum PaymentPartyRole {Sender, Recipient}

    //
    // Structures
    // -----------------------------------------------------------------------------------------------------------------
    struct PaymentSenderParty {
        uint256 nonce;
        address wallet;

        NahmiiTypesLib.CurrentPreviousInt256 balances;

        NahmiiTypesLib.SingleFigureTotalOriginFigures fees;

        string data;
    }

    struct PaymentRecipientParty {
        uint256 nonce;
        address wallet;

        NahmiiTypesLib.CurrentPreviousInt256 balances;

        NahmiiTypesLib.TotalOriginFigures fees;
    }

    struct Operator {
        uint256 id;
        string data;
    }

    struct Payment {
        int256 amount;
        MonetaryTypesLib.Currency currency;

        PaymentSenderParty sender;
        PaymentRecipientParty recipient;

        // Positive transfer is always in direction from sender to recipient
        NahmiiTypesLib.SingleTotalInt256 transfers;

        NahmiiTypesLib.WalletOperatorSeal seals;
        uint256 blockNumber;

        Operator operator;
    }

    //
    // Functions
    // -----------------------------------------------------------------------------------------------------------------
    function PAYMENT_KIND()
    public
    pure
    returns (string memory)
    {
        return "payment";
    }
}

/*
 * Hubii Nahmii
 *
 * Compliant with the Hubii Nahmii specification v0.12.
 *
 * Copyright (C) 2017-2018 Hubii AS
 */









/**
 * @title PaymentHasher
 * @notice Contract that hashes types related to payment
 */
contract PaymentHasher is Ownable {
    //
    // Constructor
    // -----------------------------------------------------------------------------------------------------------------
    constructor(address deployer) Ownable(deployer) public {
    }

    //
    // Functions
    // -----------------------------------------------------------------------------------------------------------------
    function hashPaymentAsWallet(PaymentTypesLib.Payment memory payment)
    public
    pure
    returns (bytes32)
    {
        bytes32 amountCurrencyHash = hashPaymentAmountCurrency(payment);
        bytes32 senderHash = hashPaymentSenderPartyAsWallet(payment.sender);
        bytes32 recipientHash = hashAddress(payment.recipient.wallet);

        return keccak256(abi.encodePacked(amountCurrencyHash, senderHash, recipientHash));
    }

    function hashPaymentAsOperator(PaymentTypesLib.Payment memory payment)
    public
    pure
    returns (bytes32)
    {
        bytes32 walletSignatureHash = hashSignature(payment.seals.wallet.signature);
        bytes32 senderHash = hashPaymentSenderPartyAsOperator(payment.sender);
        bytes32 recipientHash = hashPaymentRecipientPartyAsOperator(payment.recipient);
        bytes32 transfersHash = hashSingleTotalInt256(payment.transfers);
        bytes32 operatorHash = hashString(payment.operator.data);

        return keccak256(abi.encodePacked(
                walletSignatureHash, senderHash, recipientHash, transfersHash, operatorHash
            ));
    }

    function hashPaymentAmountCurrency(PaymentTypesLib.Payment memory payment)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(
                payment.amount,
                payment.currency.ct,
                payment.currency.id
            ));
    }

    function hashPaymentSenderPartyAsWallet(
        PaymentTypesLib.PaymentSenderParty memory paymentSenderParty)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(
                paymentSenderParty.wallet,
                paymentSenderParty.data
            ));
    }

    function hashPaymentSenderPartyAsOperator(
        PaymentTypesLib.PaymentSenderParty memory paymentSenderParty)
    public
    pure
    returns (bytes32)
    {
        bytes32 rootHash = hashUint256(paymentSenderParty.nonce);
        bytes32 balancesHash = hashCurrentPreviousInt256(paymentSenderParty.balances);
        bytes32 singleFeeHash = hashFigure(paymentSenderParty.fees.single);
        bytes32 totalFeesHash = hashOriginFigures(paymentSenderParty.fees.total);

        return keccak256(abi.encodePacked(
                rootHash, balancesHash, singleFeeHash, totalFeesHash
            ));
    }

    function hashPaymentRecipientPartyAsOperator(
        PaymentTypesLib.PaymentRecipientParty memory paymentRecipientParty)
    public
    pure
    returns (bytes32)
    {
        bytes32 rootHash = hashUint256(paymentRecipientParty.nonce);
        bytes32 balancesHash = hashCurrentPreviousInt256(paymentRecipientParty.balances);
        bytes32 totalFeesHash = hashOriginFigures(paymentRecipientParty.fees.total);

        return keccak256(abi.encodePacked(
                rootHash, balancesHash, totalFeesHash
            ));
    }

    function hashCurrentPreviousInt256(
        NahmiiTypesLib.CurrentPreviousInt256 memory currentPreviousInt256)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(
                currentPreviousInt256.current,
                currentPreviousInt256.previous
            ));
    }

    function hashSingleTotalInt256(
        NahmiiTypesLib.SingleTotalInt256 memory singleTotalInt256)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(
                singleTotalInt256.single,
                singleTotalInt256.total
            ));
    }

    function hashFigure(MonetaryTypesLib.Figure memory figure)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(
                figure.amount,
                figure.currency.ct,
                figure.currency.id
            ));
    }

    function hashOriginFigures(NahmiiTypesLib.OriginFigure[] memory originFigures)
    public
    pure
    returns (bytes32)
    {
        bytes32 hash;
        for (uint256 i = 0; i < originFigures.length; i++) {
            hash = keccak256(abi.encodePacked(
                    hash,
                    originFigures[i].originId,
                    originFigures[i].figure.amount,
                    originFigures[i].figure.currency.ct,
                    originFigures[i].figure.currency.id
                )
            );
        }
        return hash;
    }

    function hashUint256(uint256 _uint256)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(_uint256));
    }

    function hashString(string memory _string)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(_string));
    }

    function hashAddress(address _address)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(_address));
    }

    function hashSignature(NahmiiTypesLib.Signature memory signature)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(
                signature.v,
                signature.r,
                signature.s
            ));
    }
}