/**
 *Submitted for verification at polygonscan.com on 2022-01-05
*/

// Sources flattened with hardhat v2.6.5 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: UNLICENSED

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


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}


// File contracts/PhysicalSwap.sol

pragma solidity ^0.8.0;


contract PhysicalSwap {
    address scavenger;
    address feeTokenContract;
    enum ApprovedState {
        UNINITIALIZED,
        SUSPENSE,
        OK_TO_DELIVER,
        OK_TO_PAYOUT,
        OK_TO_REFUND,
        SCAVENGING
    }
    event FleatoCharge(
        bytes32 indexed chargeCode,
        bytes32 indexed productCode,
        address indexed receiver,
        uint256 paymentCode,
        address paymentTokenContract,
        uint256 paymentAmount,
        uint256 feeAmount
    );

    event PaymentWithdrawn(bytes32 indexed chargeCode, uint256 paymentCode);
    event FeeWithdrawn(bytes32 indexed chargeCode, uint256 paymentCode);
    event Refunded(bytes32 indexed chargeCode, uint256 paymentCode);
    event OkToDeliver(bytes32 indexed chargeCode);
    event OkToPayout(bytes32 indexed chargeCode);
    event OkToRefund(bytes32 indexed chargeCode);
    event PaymentScavenged(bytes32 indexed chargeCode, uint256 paymentCode);
    event FeeScavenged(bytes32 indexed chargeCode, uint256 paymentCode);

    struct ChargeContract {
        bytes32 productCode;
        address receiver;
        ApprovedState approvedState;
        address adjudicator;
        uint256 payments;
        uint256 created;
    }

    struct PaymentContract {
        address sender;
        address paymentTokenContract;
        uint256 paymentAmount;
        uint256 feeAmount;
        bool withdrawn;
        bool feeWithdrawn;
        bool refunded;
        bool paymentScavenged;
        bool feeScavenged;
        uint256 created;
    }

    modifier tokensTransferable(
        address _token,
        address _sender,
        uint256 _amount
    ) {
        if (_amount > 0) {
            require(
                IERC20(_token).allowance(_sender, address(this)) >= _amount,
                string(
                    abi.encodePacked(
                        "allowance ",
                        Strings.toString(
                            IERC20(_token).allowance(_sender, address(this))
                        ),
                        " must be >= ",
                        Strings.toString(_amount)
                    )
                )
            );
        }
        _;
    }

    modifier chargeExists(bytes32 _chargeCode) {
        require(
            hasCharge(_chargeCode),
            string(abi.encodePacked("chargeCode does not exist", _chargeCode))
        );
        _;
    }

    modifier depositableTo(PaymentInput memory _input) {
        if (charges[_input.chargeCode].approvedState == ApprovedState.UNINITIALIZED) {
            //New charge, just accept;
        } else {
            require(
                charges[_input.chargeCode].approvedState == ApprovedState.SUSPENSE,
                string(
                    abi.encodePacked(
                        "depositableTo: wrong charge approvedState ",
                        Strings.toString(uint256(charges[_input.chargeCode].approvedState))
                    )
                )
            );

            require(
                charges[_input.chargeCode].receiver == _input.receiver,
                "depositableTo: not same receiver"
            );

            require(
                charges[_input.chargeCode].adjudicator == _input.adjudicator,
                "depositableTo: not same adjudicator"
            );

        }
        _;
    }

    modifier withdrawable(bytes32 _chargeCode, uint256 _paymentCode) {
        require(
            charges[_chargeCode].approvedState == ApprovedState.OK_TO_PAYOUT,
            "withdrawable: payout not approved"
        );
        require(
            payments[_chargeCode][_paymentCode].withdrawn == false,
            "withdrawable: already withdrawn"
        );
        require(
            payments[_chargeCode][_paymentCode].refunded == false,
            "withdrawable: already refunded"
        );
        require(
            payments[_chargeCode][_paymentCode].paymentScavenged == false,
            "withdrawable: already scavenged"
        );
        _;
    }

    modifier feeWithdrawable(bytes32 _chargeCode, uint256 _paymentCode) {
        require(
            charges[_chargeCode].approvedState == ApprovedState.OK_TO_PAYOUT,
            "feeWithdraw: payout not approved"
        );
        require(
            payments[_chargeCode][_paymentCode].feeWithdrawn == false,
            "feeWithdraw: already withdrawn"
        );
        require(
            payments[_chargeCode][_paymentCode].refunded == false,
            "feeWithdraw: already refunded"
        );
        require(
            payments[_chargeCode][_paymentCode].feeScavenged == false,
            "feeWithdraw: already scavenged"
        );
        _;
    }

    modifier refundable(bytes32 _chargeCode, uint256 _paymentCode) {
        require(
            charges[_chargeCode].approvedState == ApprovedState.OK_TO_REFUND,
            "refundable: refund not approved"
        );
        require(
            payments[_chargeCode][_paymentCode].refunded == false,
            "refundable: already refunded"
        );
        require(
            payments[_chargeCode][_paymentCode].withdrawn == false,
            "refundable: already withdrawn"
        );
        require(
            payments[_chargeCode][_paymentCode].paymentScavenged == false,
            "refundable: already scavenged"
        );
        require(
            payments[_chargeCode][_paymentCode].feeScavenged == false,
            "refundable: already scavenged"
        );
        _;
    }

    modifier deliveryApprovable(bytes32 _chargeCode) {
        require(
            charges[_chargeCode].approvedState == ApprovedState.SUSPENSE,
            "deliveryApprovable: approvedState not in suspense"
        );
        require(
            charges[_chargeCode].adjudicator == msg.sender,
            "deliveryApprovable: not adjudicator"
        );
        _;
    }

    modifier payoutApprovable(bytes32 _chargeCode) {
        require(
            charges[_chargeCode].approvedState == ApprovedState.OK_TO_DELIVER,
            "payoutApprovable: approvedState not in ok to deliver"
        );
        require(
            charges[_chargeCode].adjudicator == msg.sender,
            "payoutApprovable: not adjudicator"
        );
        _;
    }

    modifier refundApprovable(bytes32 _chargeCode) {
        require(
            charges[_chargeCode].approvedState == ApprovedState.SUSPENSE ||
                charges[_chargeCode].approvedState == ApprovedState.OK_TO_DELIVER,
            "refundApprovable: approvedState not in suspense or ok to deliver"
        );
        require(
            (charges[_chargeCode].approvedState == ApprovedState.SUSPENSE &&
                charges[_chargeCode].adjudicator == msg.sender) ||
                (charges[_chargeCode].approvedState == ApprovedState.OK_TO_DELIVER &&
                    charges[_chargeCode].receiver == msg.sender) ||
                (charges[_chargeCode].approvedState == ApprovedState.OK_TO_DELIVER &&
                    charges[_chargeCode].adjudicator == msg.sender &&
                    charges[_chargeCode].created + 7 days < block.timestamp),
            "refundApprovable: not seller or adjudicator or wrong approvedState or cooling period not met"
        );
        _;
    }

    modifier paymentScavengable(bytes32 _chargeCode, uint256 _paymentCode) {
        require(
            payments[_chargeCode][_paymentCode].refunded == false,
            "scavengable: already refunded"
        );
        require(
            payments[_chargeCode][_paymentCode].withdrawn == false,
            "scavengable: already withdrawn"
        );
        require(
            payments[_chargeCode][_paymentCode].paymentScavenged == false,
            "scavengable: already scavenged"
        );
        require(
            payments[_chargeCode][_paymentCode].created + 180 days <
                block.timestamp,
            "scavengable: not 180 days yet"
        );
        _;
    }

    modifier feeScavengable(bytes32 _chargeCode, uint256 _paymentCode) {
        require(
            payments[_chargeCode][_paymentCode].refunded == false,
            "scavengable: already refunded"
        );
        require(
            payments[_chargeCode][_paymentCode].feeWithdrawn == false,
            "scavengable: already withdrawn"
        );
        require(
            payments[_chargeCode][_paymentCode].feeScavenged == false,
            "scavengable: already scavenged"
        );
        require(
            payments[_chargeCode][_paymentCode].created + 180 days <
                block.timestamp,
            "scavengable: not 180 days yet"
        );
        _;
    }

    mapping(bytes32 => ChargeContract) charges;
    mapping(bytes32 => mapping(uint256 => PaymentContract)) payments;

    struct PaymentInput {
        bytes32 chargeCode;
        bytes32 productCode;
        address receiver;
        address paymentTokenContract;
        uint256 paymentAmount;
        uint256 feeAmount;
        address adjudicator;
    }

    constructor(address _scavenger, address _feeTokenContract) {
        scavenger = _scavenger;
        feeTokenContract = _feeTokenContract;
    }

    function markOkToDeliver(bytes32 _chargeCode)
        external
        deliveryApprovable(_chargeCode)
    {
        ChargeContract storage c = charges[_chargeCode];
        c.approvedState = ApprovedState.OK_TO_DELIVER;
        emit OkToDeliver(_chargeCode);
    }

    function markOkToPayout(bytes32 _chargeCode)
        external
        payoutApprovable(_chargeCode)
    {
        ChargeContract storage c = charges[_chargeCode];
        c.approvedState = ApprovedState.OK_TO_PAYOUT;
        emit OkToPayout(_chargeCode);
    }

    function markOkToRefund(bytes32 _chargeCode)
        external
        refundApprovable(_chargeCode)
    {
        ChargeContract storage c = charges[_chargeCode];
        c.approvedState = ApprovedState.OK_TO_REFUND;
        emit OkToRefund(_chargeCode);
    }

    function pay(PaymentInput memory _input)
        external
        tokensTransferable(
            _input.paymentTokenContract,
            msg.sender,
            _input.paymentAmount
        )
        tokensTransferable(feeTokenContract, msg.sender, _input.feeAmount)
        depositableTo(_input)
    {
        // Debit the payment
        if (
            !IERC20(_input.paymentTokenContract).transferFrom(
                msg.sender,
                address(this),
                _input.paymentAmount
            )
        ) revert("payment transfer from sender to smartcontract failed");

        // Debit the fee
        if (
            !IERC20(feeTokenContract).transferFrom(
                msg.sender,
                address(this),
                _input.feeAmount
            )
        ) revert("fee transfer from sender to smartcontract failed");
        if (hasCharge(_input.chargeCode)) {
            charges[_input.chargeCode].payments =
                charges[_input.chargeCode].payments +
                1;
        } else {
            charges[_input.chargeCode] = ChargeContract(
                _input.productCode,
                _input.receiver,
                ApprovedState.SUSPENSE,
                _input.adjudicator,
                0,
                block.timestamp
            );
        }

        payments[_input.chargeCode][
            charges[_input.chargeCode].payments
        ] = PaymentContract(
            msg.sender,
            _input.paymentTokenContract,
            _input.paymentAmount,
            _input.feeAmount,
            false,
            false,
            false,
            false,
            false,
            block.timestamp
        );

        emit FleatoCharge(
            _input.chargeCode,
            _input.productCode,
            _input.receiver,
            charges[_input.chargeCode].payments,
            _input.paymentTokenContract,
            _input.paymentAmount,
            _input.feeAmount
        );
    }

    function withdrawPayment(bytes32 _chargeCode, uint256 _paymentCode)
        public
        chargeExists(_chargeCode)
        withdrawable(_chargeCode, _paymentCode)
        returns (bool)
    {
        ChargeContract storage c = charges[_chargeCode];
        PaymentContract storage p = payments[_chargeCode][_paymentCode];
        p.withdrawn = true;
        IERC20(p.paymentTokenContract).transfer(c.receiver, p.paymentAmount);
        emit PaymentWithdrawn(_chargeCode, _paymentCode);
        return true;
    }

    function withdrawFee(bytes32 _chargeCode, uint256 _paymentCode)
        public
        chargeExists(_chargeCode)
        feeWithdrawable(_chargeCode, _paymentCode)
        returns (bool)
    {
        ChargeContract storage c = charges[_chargeCode];
        PaymentContract storage p = payments[_chargeCode][_paymentCode];
        p.feeWithdrawn = true;
        IERC20(feeTokenContract).transfer(c.adjudicator, p.feeAmount);
        emit FeeWithdrawn(_chargeCode, _paymentCode);
        return true;
    }

    function withdrawPaymentsAndFees(bytes32 _chargeCode) external returns (bool) {
        ChargeContract storage c = charges[_chargeCode];
        for(uint i=0;i<c.payments;i++) {
            withdrawPayment(_chargeCode, i);
            withdrawFee(_chargeCode, i);
        }
        return true;
    }

    //For cases when buyer or seller has lost their key and their funds locked.
    function scavengePayment(bytes32 _chargeCode, uint256 _paymentCode)
        external
        paymentScavengable(_chargeCode, _paymentCode)
        returns (bool)
    {
        ChargeContract storage c = charges[_chargeCode];
        c.approvedState = ApprovedState.SCAVENGING;

        PaymentContract storage p = payments[_chargeCode][_paymentCode];
        IERC20(p.paymentTokenContract).transfer(
            scavenger,
            p.paymentAmount
        );
        p.paymentScavenged = true;
        emit PaymentScavenged(_chargeCode, _paymentCode);
        return true;
    }

    //For cases when adjudicator has lost their key and their funds locked.
    function scavengeFee(bytes32 _chargeCode, uint256 _paymentCode)
        external
        feeScavengable(_chargeCode, _paymentCode)
        returns (bool)
    {
        ChargeContract storage c = charges[_chargeCode];
        c.approvedState = ApprovedState.SCAVENGING;

        PaymentContract storage p = payments[_chargeCode][_paymentCode];
        IERC20(feeTokenContract).transfer(scavenger, p.feeAmount);
        p.feeScavenged = true;
        emit FeeScavenged(_chargeCode, _paymentCode);
        return true;
    }

    function refund(bytes32 _chargeCode, uint256 _paymentCode)
        external
        chargeExists(_chargeCode)
        refundable(_chargeCode, _paymentCode)
        returns (bool)
    {
        PaymentContract storage p = payments[_chargeCode][_paymentCode];
        p.refunded = true;
        IERC20(p.paymentTokenContract).transfer(p.sender, p.paymentAmount);
        IERC20(feeTokenContract).transfer(p.sender, p.feeAmount);
        emit Refunded(_chargeCode, _paymentCode);
        return true;
    }

    function getChargeStatus(bytes32 _chargeCode)
        public
        view
        returns (
            bytes32 productCode,
            address receiver,
            ApprovedState approvedState,
            address adjudicator,
            uint256 paymentsLength,
            uint256 created
        )
    {
        ChargeContract storage c = charges[_chargeCode];
        return (
            c.productCode,
            c.receiver,
            c.approvedState,
            c.adjudicator,
            c.payments + 1,
            c.created
        );
    }

    function getPaymentStatus(bytes32 _chargeCode, uint256 _paymentCode)
        public
        view
        returns (
            address sender,
            address paymentTokenContract,
            uint256 paymentAmount,
            uint256 feeAmount,
            bool withdrawn,
            bool feeWithdrawn,
            bool refunded,
            bool paymentScavenged,
            bool feeScavenged,
            uint256 created
        )
    {
        PaymentContract storage p = payments[_chargeCode][_paymentCode];
        return (
            p.sender,
            p.paymentTokenContract,
            p.paymentAmount,
            p.feeAmount,
            p.withdrawn,
            p.feeWithdrawn,
            p.refunded,
            p.paymentScavenged,
            p.feeScavenged,
            p.created
        );
    }

    function hasCharge(bytes32 _chargeCode)
        internal
        view
        returns (bool exists)
    {
        exists = (charges[_chargeCode].receiver != address(0));
    }
}