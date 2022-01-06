//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/LibFeeData.sol";
import "./lib/LibVerifySignature.sol";
import "./lib/Order.sol";

/**
    @notice This contract wraps a request to Wyvern to do an atomic match
    and ensures the fees are paid out properly to the
    correct fee recipients. This is a workaround Wyvern V2, which only allows a single
    fee recipient, versus allowing multiple.

    Through this wrapper, fees will be paid out in real-time based on server-passed details
    describing the fee recipients and the amount owed. If a fee recipient is invalid,
    the fee recipient does not get paid out for the single transaction.

    OpenSea is intended to have control over this contract due to the need of rotating server signers
    and thus the contract is Ownable.

    Intended Usage:
        Moving forward, users can only submit Opensea atomic match orders through this wrapper
        versus directly making a request to Wyvern. If a request is made directly to Wyvern with
        Opensea orders, the request will fail.

        The Opensea SDK will automatically call this WyvernFeeWrapper, passing in
        the original Wyvern Order parameters, as well as additional params describing the correct
        fee recipients, in the form of FeeData. This information must be signed by the Opensea server
        to ensure no modifications were made.

        As a user, the only function you should be making is `wyvernFeeWrapper.atomicMatch_(...)`
*/
contract WyvernFeeWrapper is ReentrancyGuard, Ownable {
    address public exchange;
    // We use multiple server signer addresses so we can easily rotate between addresses
    address[] public serverSignerAddresses;

    // Variables for modifier `protectAgainstExternalWyvernCalls`
    uint64 private constant _NOT_ENTERED = 1;
    uint64 private constant _ENTERED = 2;
    uint64 private _transactionStatus;

    // Inverse basis point
    uint64 private constant INVERSE_BASIS_POINT = 10000;

    constructor(address _exchange, address[] memory _serverSignerAddresses)
        onlyNonZeroAddress(_exchange)
        onlyNonZeroAddresses(_serverSignerAddresses)
    {
        if (_serverSignerAddresses.length > 2) {
            revert MoreThanTwoServerSignerAddresses();
        }
        exchange = _exchange;
        serverSignerAddresses = _serverSignerAddresses;
        _transactionStatus = _NOT_ENTERED;
    }

    /**
        @notice Error that is thrown if the wrapper is currently not in the middle of
        executing function `atomicMatch_`
    */
    error NotInWrapperTransaction();

    /**
        @notice Error thrown if `atomicMatch_` received an invalid server
        signature for the given signed Order params.
    */
    error InvalidServerSignature();

    /**
        @notice Error only thrown by `atomicMatch_` when there's an issue with
        the fee recipient set on the buy or sell orders.
    */
    error InvalidFeeRecipient(address buyerFeeRecipient, address sellerFeeRecipient);

    /**
        @notice Error only thrown by `atomicMatch_` when there's a problem
        calling atomic match on Wyvern exchange
    */
    error WyvernAtomicMatchFailed();

    /**
        @notice Error only thrown by `atomicMatch_` if the amount received did not
        equal the amount sent out for fees
    */
    error ExactPaymentFeeAmountNotTransferred();

    /**
        @notice Error thrown when trying to send ether to an address
        Currently should only happen if the backup recipient for the fees (e.g. seller)
        cannot receive ETH.
    */
    error FailedToTransferFees(address to);

    /**
        @notice Error thrown when trying to set the exchange or server signer address to be the zero address.
     */
    error AddressIsZeroAddress();

    /**
        @notice Error thrown when trying to set more than two server signer addresses.
     */
    error MoreThanTwoServerSignerAddresses();

    /**
        @dev Ensures that Wyvern exchange can pay the fees out to this wrapper in ETH
    */
    receive() external payable {
        // This contract should only receive ETH while in the atomicMatch transaction
        expectInTransaction();
    }

    function setExchange(address _exchange) external onlyOwner onlyNonZeroAddress(_exchange) {
        exchange = _exchange;
    }

    /**
        @notice sets the server signer addresses. We enforce a max of 2 server signer addresses as we don't
                foresee needing more
        @param _serverSignerAddresses the list of server signer addresses to set
     */
    function setServerSignerAddresses(address[] memory _serverSignerAddresses)
        external
        onlyNonZeroAddresses(_serverSignerAddresses)
        onlyOwner
    {
        if (_serverSignerAddresses.length > 2) {
            revert MoreThanTwoServerSignerAddresses();
        }

        serverSignerAddresses = _serverSignerAddresses;
    }

    function getServerSignerAddresses() external view returns (address[] memory) {
        return serverSignerAddresses;
    }

    /**
        @notice This modifier, combined with `expectInTransaction()` ensures that only
        the FeeWrapper can submit atomic match calls directly to Wyvern with
        Opensea-created Wyvern orders. This is to ensure that users do not bypass
        fee wrapper, and cause fees to not be paid out to the proper parties.

        @dev How it works:
            1) We have `atomicMatch_()` use the modifier to set a state indicating whether
            we are currently executing this fee wrapper's atomicMatch_() function.
            2) We set a callback validator that is called by Wyvern atomic match
            (via Wyvern's `staticTarget`) that calls `this.expectInTransaction()`.
                NOTE: `staticTarget` is set on the order and signed by the buyer/seller,
                so this should not be spoofable as Wyvern validates Order + signatures.
            3) If the caller to Wyvern was this wrapper, expectInTransaction() will pass.
               If the caller to Wyvern was not this wrapper, expectInTransaction() will
               throw an error, failing the transaction.

        Wyvern static target:
            https://github.com/ProjectWyvern/wyvern-ethereum/blob/master/contracts/exchange/ExchangeCore.sol#L739
    */
    modifier protectAgainstExternalWyvernCalls() {
        // QUESTION[for auditors]: Can/should we consolidate nonReentrant and inTransaction
        // in a single modifier to save on gas, even though it'll be ugly?
        _transactionStatus = _ENTERED;
        _;
        _transactionStatus = _NOT_ENTERED;
    }

    modifier onlyNonZeroAddress(address addr) {
        revertIfZeroAddress(addr);
        _;
    }

    /**
        @notice This modifier ensures that the server signer address and exchange address can never be the zero address
        @param addresses The address to check if it's the zero address or not
     */
    modifier onlyNonZeroAddresses(address[] memory addresses) {
        for (uint256 i = 0; i < addresses.length; i++) {
            revertIfZeroAddress((addresses[i]));
        }
        _;
    }

    /**
        @notice Simply reverts with AddressIsZeroAddress if the address is the zero address
     */
    function revertIfZeroAddress(address addr) private pure {
        if (addr == address(0x0)) {
            revert AddressIsZeroAddress();
        }
    }

    /**
        @notice This function throws a `NotInTransaction` Error if
            we are currently not in the middle of executing `this.atomicMatch_()`
            and that the transaction came from the WyvernExchange
            This is currently used as a call-back function by Wyvern's atomic match.
    */
    function expectInTransaction() public view {
        if (_transactionStatus != _ENTERED || msg.sender != exchange) {
            revert NotInWrapperTransaction();
        }
    }

    /**
        @notice Inputs to Wyvern's `atomicMatch_`
            https://github.com/ProjectWyvern/wyvern-ethereum/blob/master/contracts/exchange/Exchange.sol#L317

            Wyvern takes in these params and uses it as input to interact with
            a "buy order" and "sell order" `Order` object in Wyvern:
            https://github.com/ProjectWyvern/wyvern-ethereum/blob/master/contracts/exchange/ExchangeCore.sol#L92
    */
    struct WyvernAtomicMatchParams {
        /** @dev Different addresses needed by Wyvern to specify the buy and sell order
        [
            buyOrder.exchange: The exchange processing this, e.g. Wyvern
            buyOrder.maker: Buy order's maker (e.g. buyer)
            buyOrder.taker: Usually the seller
            buyOrder.feeRecipient: A single fee recipient address. We set this to be this wrapper.
            buyOrder.target: The asset to transfer (e.g. the ERC721)
            buyOrder.staticTarget: Optional contract addr for callback function for Wyvern to execute
            buyOrder.paymentToken: Specifies what token this
                transaction is paid out in (e.g. ETH, ERC20, etc.)
            sellOrder.exchange: The exchange processing this, e.g. Wyvern
            sellOrder.maker: Sell order's maker (e.g. seller)
            sellOrder.taker: Sell order's taker (e.g. buyer if private listing, or null if public).
            sellOrder.feeRecipient: A single fee recipient address. We set this to be this wrapper.
            sellOrder.target: The asset to transfer (e.g. the ERC721)
            sellOrder.staticTarget: Optional contract addr callback function for Wyvern to execute
                In our case, this is set to be this wrapper's address.
            sellOrder.paymentToken: Specifies what token this
                transaction is paid out in (e.g. ETH, ERC20, etc.)
        ]
        */
        address[14] addrs;
        /** Different integers needed by Wyvern to specify the buy and sell order
        [
            buyOrder.makerRelayerFee: This is the sum of total fees charged to seller
            buyOrder.takerRelayerFee: We typically set these to 0,
                as we only charge fees once to seller
            buyOrder.makerProtocolFee: We typically set these to 0,
                as we only charge fees once to seller
            buyOrder.takerProtocolFee: We typically set these to 0,
                as we only charge fees once to seller
            buyOrder.basePrice: This is typically the cost of an ERC721
            buyOrder.extra
            buyOrder.listingTime
            buyOrder.expirationTime
            buyOrder.salt
            sellOrder.makerRelayerFee: This is the sum of total fees charged to
                seller, must match buyOrder.makerRelayerFee
            sellOrder.takerRelayerFee: We typically set these to 0,
                as we only charge fees once to seller
            sellOrder.makerProtocolFee: We typically set these to 0,
                as we only charge fees once to seller
            sellOrder.takerProtocolFee: We typically set these to 0,
                as we only charge fees once to seller
            sellOrder.basePrice: This is typically the cost of an ERC721
            sellOrder.extra
            sellOrder.listingTime
            sellOrder.expirationTime
            sellOrder.salt
        ]
        */
        uint256[18] uints;
        /**
        [
            buyOrder.feeMethod,
            buyOrder.side,
            buyOrder.saleKind,
            buyOrder.howToCall,
            sellOrder.feeMethod,
            sellOrder.side,
            sellOrder.saleKind,
            sellOrder.howToCall,
        ],
        */
        uint8[8] feeMethodsSidesKindsHowToCalls;
        // buyOrder.calldata - Encoded buy method to execute on `target`, including params
        bytes calldataBuy;
        // sellOrder.calldata - Encoded sell method to execute on `target`, including params
        bytes calldataSell;
        // buyOrder.replacementPattern calldata replacement mask
        // application-specific
        bytes replacementPatternBuy;
        // sellOrder.replacementPattern calldata replacement mask
        // application-specific
        bytes replacementPatternSell;
        // buyOrder.staticExtradata
        bytes staticExtradataBuy;
        // sellOrder.staticExtradata - our API/SDK sets this to be
        // a callback to `expectInTransaction()`
        bytes staticExtradataSell;
        /** Signature data (v)
        [
            buyOrder.v || 0,
            sellOrder.v || 0
        ]
        */
        uint8[2] vs;
        /** Signature data (r, s)
            [
                buyOrder.r || NULL_BLOCK_HASH,
                buyOrder.s || NULL_BLOCK_HASH,
                sellOrder.r || NULL_BLOCK_HASH,
                sellOrder.s || NULL_BLOCK_HASH,
                NULL_BLOCK_HASH,
            ]
        */
        bytes32[5] rssMetadata;
    }

    /**
    @param _params: Params specifying the details about the
        buy and sell Orders, e.g. who is seller/buyer, cost of asset, asset ID, etc.
        that will be forwarded to Wyvern's atomic match.
    @param _feeData: A list of FeeData objects, where each item specifies a payout to a single address.
        This should be constructed by Opensea server.
    @param _serverSignerSignature: A signature that the server produces by signing its private key on a set of
        params to ensure the parameters were constructed and modified only by the server.
    @param serverSignedOrderSide the side (buy/sell) of the order that was signed on the server. It needs to be passed
        in or else we have to check both orders, which is gas inefficient
    @notice Executes atomic match through Wyvern and sends out the fees appropriately. Asserts that balances in the contract remain
            constant before and after the atomic match. Thus, we do not support inflationary/deflationary payment tokens.
    @dev Executes atomic match through Wyvern and sends out the fees appropriately.
        The list of steps are as follows:
        1. Verify server signature to ensure feeData was not created or modified outside of the Opensea server
        2. Check if there are valid transfer fees and ensure fee recipient should be the Wyvern Fee Wrapper
        3. Submit an atomic match order to Wyvern
        4. If there are fees, send out the fees (ETH or ERC20)
    */
    function atomicMatch_(
        // Inputs to Wyvern atomicMatch
        WyvernAtomicMatchParams calldata _params,
        // Wrapper specific inputs
        bytes memory _serverSignerSignature,
        LibFeeData.FeeData[] memory _feeData,
        Order.Side serverSignedOrderSide
    ) external payable nonReentrant protectAgainstExternalWyvernCalls {
        // Step 1 - Verify server signature
        // Since we can transact in ETH or any ERC20 token, we need to use the buyer's payment
        // token address to make sure we're using the correct interface.
        // Buy and sell payment tokens must match, validated in WyvernExchange
        address paymentTokenAddress = _params.addrs[6];

        bool validSigner = false;

        if (serverSignedOrderSide == Order.Side.Sell) {
            validSigner = LibVerifySignature.verify(
                serverSignerAddresses,
                _serverSignerSignature,
                _params.vs[1],
                [_params.rssMetadata[2], _params.rssMetadata[3]],
                _feeData,
                paymentTokenAddress
            );
        } else {
            validSigner = LibVerifySignature.verify(
                serverSignerAddresses,
                _serverSignerSignature,
                _params.vs[0],
                [_params.rssMetadata[0], _params.rssMetadata[1]],
                _feeData,
                paymentTokenAddress
            );
        }

        if (!validSigner) {
            revert InvalidServerSignature();
        }

        // Step 2 - Verify and validate transfer fees
        bool transferFees = _feeData.length > 0;

        // We store current balance of wrapper to ensure the net fees paid to this wrapper
        // to this transaction is equal to 0. Think of it as a correctness check.
        uint256 balancePriorToMatch = _balanceOfPaymentToken(paymentTokenAddress);

        if (transferFees) {
            _validateFeeRecipients(_params.addrs[3], _params.addrs[10]);
        }

        // Step 3 - Submit an atomic match order to Wyvern
        // NOTE: If msg.value is greater than the base price, Wyvern will refund remaining to buyer
        (bool success, ) = exchange.call{value: msg.value}(_encodeAtomicMatchParams(_params));

        if (!success) {
            revert WyvernAtomicMatchFailed();
        }

        // Step 4 - For each fee item, send out the fee to the intended recipient
        if (transferFees) {
            if (_params.feeMethodsSidesKindsHowToCalls[6] == uint8(Order.SaleKind.DutchAuction)) {
                uint256 finalPrice = calculateDutchAuctionFinalPrice(
                    _params.uints[13],
                    _params.uints[14],
                    _params.uints[15],
                    _params.uints[16]
                );

                // In dutch auction cases, we calculate the payment token amount manually based off the basis points
                for (uint256 i = 0; i < _feeData.length; i++) {
                    _feeData[i].paymentTokenAmount = _getFeeAmountFromBasisPoints(
                        finalPrice,
                        _feeData[i].basisPoints
                    );
                }
            }
            // Set backup fee recipient to be sell order maker in case an invalid fee recipient
            // is passed in
            _distributeFees(_feeData, paymentTokenAddress, _params.addrs[8]);
        }

        // Do the correctness check to ensure all fees were paid out and our balance
        // does not change from before we started this transaction.
        uint256 balanceAfterMatch = _balanceOfPaymentToken(paymentTokenAddress);
        if (_isNativeEthAddr(paymentTokenAddress)) {
            // NOTE: In the case where ETH is sent as payment token, `balancePriorToMatch` would
            // include the msg.value.
            if (balancePriorToMatch - msg.value != balanceAfterMatch) {
                revert ExactPaymentFeeAmountNotTransferred();
            }
        } else {
            if (balancePriorToMatch != balanceAfterMatch) {
                revert ExactPaymentFeeAmountNotTransferred();
            }
        }
    }

    /**
    @notice Encodes the params for Wyvern's atomicMatch_ function with signature.
        This is needed in order to call the function on the Wyvern exchange.
    @param _params The WyvernAtomicMatchParams struct that contains info nececessary to call atomicMatch_
    @return the encoded call data
    */
    function _encodeAtomicMatchParams(WyvernAtomicMatchParams memory _params)
        private
        pure
        returns (bytes memory)
    {
        return
            abi.encodeWithSignature(
                "atomicMatch_(address[14],uint256[18],uint8[8],bytes,bytes,bytes,bytes,bytes,bytes,uint8[2],bytes32[5])",
                _params.addrs,
                _params.uints,
                _params.feeMethodsSidesKindsHowToCalls,
                _params.calldataBuy,
                _params.calldataSell,
                _params.replacementPatternBuy,
                _params.replacementPatternSell,
                _params.staticExtradataBuy,
                _params.staticExtradataSell,
                _params.vs,
                _params.rssMetadata
            );
    }

    /**
    @notice calculates the final price of a dutch auction order. Essentially copied from WyvernExchange
    @param _basePrice The base price of the order
    @param _extra extra is the start price - end price
    @param _listingTime the listing time of the order
    @param _expirationTime the expiration time of the order
    @return the final price of the dutch auction order
     */
    function calculateDutchAuctionFinalPrice(
        uint256 _basePrice,
        uint256 _extra,
        uint256 _listingTime,
        uint256 _expirationTime
    ) internal view returns (uint256) {
        uint256 diff = SafeMath.div(
            SafeMath.mul(_extra, SafeMath.sub(block.timestamp, _listingTime)),
            SafeMath.sub(_expirationTime, _listingTime)
        );
        return SafeMath.sub(_basePrice, diff);
    }

    /**
    @notice validates that one order's fee recipient is this wrapper's address and the other is the zero address
    @dev Throws InvalidFeeRecipient in the case of errors
    @param _buyFeeRecipient The fee recipient on the buy order
    @param _sellFeeRecipient The fee recipient on the sell order
    */
    function _validateFeeRecipients(address _buyFeeRecipient, address _sellFeeRecipient)
        private
        view
    {
        if (
            !((_buyFeeRecipient == address(this) && _sellFeeRecipient == address(0x0)) ||
                (_sellFeeRecipient == address(this) && _buyFeeRecipient == address(0x0)))
        ) {
            revert InvalidFeeRecipient(_buyFeeRecipient, _sellFeeRecipient);
        }
    }

    /**
    @notice Distributes the fees to the fee recipient addresses.
            If any fees were not able to be sent to a fee recipient, we act as if the fee
            recipient is invalid and does not exist by transferring it to `backupRecipient`.
    @dev throws with FailedToTransferFees if we were unable to send fees to backup recipient
    @param _feeData The list of fee data that represents the fee recipient and fee amount
    @param _paymentTokenAddress Address of the payment token that specifies what token it. 0x0 is Ether
    @param backupRecipient The recipient to send fees to incase the fee transfer fails. Defaults to the seller.
    */
    function _distributeFees(
        LibFeeData.FeeData[] memory _feeData,
        address _paymentTokenAddress,
        address backupRecipient
    ) private {
        uint256 unsendableBal = 0;

        for (uint256 index = 0; index < _feeData.length; ++index) {
            bool success = _transferTo(
                _feeData[index].recipient,
                _paymentTokenAddress,
                _feeData[index].paymentTokenAmount
            );

            if (!success) {
                unsendableBal += _feeData[index].paymentTokenAmount;
            }
        }

        // Send unsendable balance to `backupRecipient`
        if (unsendableBal > 0) {
            bool success = _transferTo(backupRecipient, _paymentTokenAddress, unsendableBal);
            if (!success) {
                revert FailedToTransferFees(backupRecipient);
            }
        }
    }

    /**
    @notice Gets the fee amount based on the total price and basis points
    @param _totalPrice the total price of the order
    @param _basisPoints the basis points for the fee. 100 basis points = 1%
    @return the fee amount
     */
    function _getFeeAmountFromBasisPoints(uint256 _totalPrice, uint256 _basisPoints)
        private
        pure
        returns (uint256)
    {
        return SafeMath.div(SafeMath.mul(_totalPrice, _basisPoints), INVERSE_BASIS_POINT);
    }

    /**
    @notice Returns a boolean specifying if the payment token address refers
    to Ether or not.
    @param _paymentTokenAddress Address of the payment token that specifies what token it. 0x0 is Ether
    @return whether the payment token address refers to Ether or not
     */
    function _isNativeEthAddr(address _paymentTokenAddress) private pure returns (bool) {
        return (_paymentTokenAddress == address(0x0));
    }

    /**
    @notice Transfers the specified amount to the address
    @param _to The address to transfer to
    @param _paymentTokenAddress Address of the payment token that specifies what token it. 0x0 is Ether
    @param _paymentTokenAmount The total amount of the payment token to transfer
    @return whether the payment token was sent
    */
    function _transferTo(
        address _to,
        address _paymentTokenAddress,
        uint256 _paymentTokenAmount
    ) private returns (bool) {
        bool sent = true;
        if (_isNativeEthAddr(_paymentTokenAddress)) {
            (sent, ) = _to.call{value: _paymentTokenAmount}("");
        } else {
            sent = IERC20(_paymentTokenAddress).transfer(_to, _paymentTokenAmount);
        }
        return sent;
    }

    /**
    @notice Fetches and returns the balance this contract has of the given payment token address
    @param _paymentTokenAddress Address of the payment token that specifies what token it. 0x0 is Ether
    @return the balance of the payment token
    */

    function _balanceOfPaymentToken(address _paymentTokenAddress) private view returns (uint256) {
        // Case 1: ETH
        if (_isNativeEthAddr(_paymentTokenAddress)) {
            return address(this).balance;
        }
        // Case 2: ERC20 token
        return IERC20(_paymentTokenAddress).balanceOf(address(this));
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

library LibFeeData {
    struct FeeData {
        address recipient;
        uint256 paymentTokenAmount;
        // These basis points are only used for dutch auction cases as paymentTokenAmount won't be able to pre-emptively calculated
        uint256 basisPoints;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./LibFeeData.sol";

/**
Helper Library for Wyvern Fee Wrapper to verify the calls are coming from
the proper server.
*/
library LibVerifySignature {
    /**
    @notice Returns a message hash based on the input params
    @param feeData The list of fee data that represents the fee recipient and fee amount
    @param paymentTokenAddress Address of the payment token that specifies what token it. 0x0 is Ether
    @param vs the `v` in the order
    @param rssMetadata the `r` and `s` in the order signature
    @return the encoded message hash when packing all of the arguments together
    */
    function getMessageHash(
        LibFeeData.FeeData[] memory feeData,
        address paymentTokenAddress,
        uint8 vs,
        bytes32[2] memory rssMetadata
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(abi.encode(feeData), paymentTokenAddress, vs, rssMetadata));
    }

    /**
    @notice Verifies the signature and ensures the message was signed by our Server
    @param serverSignerAddresses the address of our server signer
    @param serverSignature the signature generated from our server signer
    @param vs the `v` in the order
    @param rssMetadata the `r` and `s` in the order signature
    @param feeData The list of fee data that represents the fee recipient and fee amount
    @param paymentTokenAddress Address of the payment token that specifies what token it. 0x0 is Ether
    @return whether or not the recovered signer from the server signature is equal to our set server signer address
    */
    function verify(
        address[] memory serverSignerAddresses,
        bytes memory serverSignature,
        uint8 vs,
        bytes32[2] memory rssMetadata,
        LibFeeData.FeeData[] memory feeData,
        address paymentTokenAddress
    ) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(feeData, paymentTokenAddress, vs, rssMetadata);
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        address recoveredSigner = ECDSA.recover(ethSignedMessageHash, serverSignature);

        for (uint256 i = 0; i < serverSignerAddresses.length; i++) {
            if (recoveredSigner == serverSignerAddresses[i]) {
                return true;
            }
        }

        return false;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

library Order {
    // Identical to WyvernExchange's SaleKindInterface Side
    enum Side {
        Buy,
        Sell
    }

    // Identical to WyvernExchange's SaleKindInterface SaleKind
    enum SaleKind {
        FixedPrice,
        DutchAuction
    }
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
        return msg.data;
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
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
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