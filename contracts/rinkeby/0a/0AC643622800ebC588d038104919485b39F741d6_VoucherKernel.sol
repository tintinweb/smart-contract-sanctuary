// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.1;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IERC1155.sol";
import "./interfaces/IERC165.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC1155ERC721.sol";
import "./interfaces/IERC721TokenReceiver.sol";
import "./interfaces/IVoucherKernel.sol";
import "./UsingHelpers.sol";

//preparing for ERC-1066, ERC-1444, EIP-838

/**
 * @title VoucherKernel contract is controlling the core business logic
 * @dev Notes:
 *  - Since this is a reference app, it is not yet optimized.
 *      In the next phase, the bulk raw data will be packed into a single bytes32 field and/or pushed off-chain.
 *  - The usage of block.timestamp is honored since vouchers are defined currently with day-precision.
 *      See: https://ethereum.stackexchange.com/questions/5924/how-do-ethereum-mining-nodes-maintain-a-time-consistent-with-the-network/5931#5931
 */
// solhint-disable-next-line
contract VoucherKernel is IVoucherKernel, Ownable, Pausable, UsingHelpers {
    using Address for address;
    using SafeMath for uint256;

    //AssetRegistry assetRegistry;
    address public tokensContract;

    //promise for an asset could be reusable, but simplified here for brevity
    struct Promise {
        bytes32 promiseId;
        uint256 nonce; //the asset that is offered
        address seller; //the seller who created the promise
        //we simplify the value for the demoapp, otherwise voucher details would be packed in one bytes32 field value
        uint256 validFrom;
        uint256 validTo;
        uint256 price;
        uint256 depositSe;
        uint256 depositBu;
        uint256 idx;
    }

    struct VoucherPaymentMethod {
        uint8 paymentMethod;
        address addressTokenPrice;
        address addressTokenDeposits;
    }

    address public bosonRouterAddress; //address of the Boson Router contract
    address public cashierAddress; //address of the Cashier contract

    mapping(bytes32 => Promise) public promises; //promises to deliver goods or services
    mapping(address => uint256) public tokenNonces; //mapping between seller address and its own nonces. Every time seller creates supply ID it gets incremented. Used to avoid duplicate ID's
    mapping(uint256 => VoucherPaymentMethod) public paymentDetails; // tokenSupplyId to VoucherPaymentMethod

    bytes32[] public promiseKeys;

    mapping(uint256 => bytes32) public ordersPromise; //mapping between an order (supply a.k.a. VoucherSet token) and a promise

    mapping(uint256 => VoucherStatus) public vouchersStatus; //recording the vouchers evolution

    //standard reqs
    mapping(uint256 => mapping(address => uint256)) private balances; //balance of token ids of an account
    mapping(address => mapping(address => bool)) private operatorApprovals; //approval of accounts of an operator

    //ID reqs
    mapping(uint256 => uint256) public typeCounters; //counter for ID of a particular type of NFT
    uint256 public constant MASK_TYPE = uint256(uint128(~0)) << 128; //the type mask in the upper 128 bits
    //1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

    uint256 public constant MASK_NF_INDEX = uint128(~0); //the non-fungible index mask in the lower 128
    //0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

    uint256 public constant TYPE_NF_BIT = 1 << 255; //the first bit represents an NFT type
    //1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

    uint256 public typeId; //base token type ... 127-bits cover 1.701411835*10^38 types (not differentiating between FTs and NFTs)
    /* Token IDs:
    Fungibles: 0, followed by 127-bit FT type ID, in the upper 128 bits, followed by 0 in lower 128-bits
    <0><uint127: base token id><uint128: 0>
    
    Non-fungible VoucherSets (supply tokens): 1, followed by 127-bit NFT type ID, in the upper 128 bits, followed by 0 in lower 128-bits
    <1><uint127: base token id><uint128: 0    
    
    Non-fungible vouchers: 1, followed by 127-bit NFT type ID, in the upper 128 bits, followed by a 1-based index of an NFT token ID.
    <1><uint127: base token id><uint128: index of non-fungible>
    */

    uint256 public complainPeriod;
    uint256 public cancelFaultPeriod;

    event LogPromiseCreated(
        bytes32 indexed _promiseId,
        uint256 indexed _nonce,
        address indexed _seller,
        uint256 _validFrom,
        uint256 _validTo,
        uint256 _idx
    );

    event LogVoucherDelivered(
        uint256 indexed _tokenIdSupply,
        uint256 _tokenIdVoucher,
        address _issuer,
        address _holder,
        bytes32 _promiseId,
        uint256 _correlationId
    );

    event LogVoucherRedeemed(
        uint256 _tokenIdVoucher,
        address _holder,
        bytes32 _promiseId
    );

    event LogVoucherRefunded(uint256 _tokenIdVoucher);

    event LogVoucherComplain(uint256 _tokenIdVoucher);

    event LogVoucherFaultCancel(uint256 _tokenIdVoucher);

    event LogExpirationTriggered(uint256 _tokenIdVoucher, address _triggeredBy);

    event LogFinalizeVoucher(uint256 _tokenIdVoucher, address _triggeredBy);

    event LogBosonRouterSet(address _newBosonRouter, address _triggeredBy);

    event LogCashierSet(address _newCashier, address _triggeredBy);

    event LogComplainPeriodChanged(
        uint256 _newComplainPeriod,
        address _triggeredBy
    );

    event LogCancelFaultPeriodChanged(
        uint256 _newCancelFaultPeriod,
        address _triggeredBy
    );

    event LogVoucherSetFaultCancel(uint256 _tokenIdSupply, address _issuer);

    event LogFundsReleased(
        uint256 _tokenIdVoucher,
        uint8 _type //0 .. payment, 1 .. deposits
    );

    modifier onlyFromRouter() {
        require(bosonRouterAddress != address(0), "UNSPECIFIED_BR"); //hex"20" FISSION.code(FISSION.Category.Find, FISSION.Status.NotFound_Unequal_OutOfRange)
        require(msg.sender == bosonRouterAddress, "UNAUTHORIZED_BR"); //hex"10" FISSION.code(FISSION.Category.Permission, FISSION.Status.Disallowed_Stop)
        _;
    }

    modifier onlyFromCashier() {
        require(cashierAddress != address(0), "UNSPECIFIED_BR"); //hex"20" FISSION.code(FISSION.Category.Find, FISSION.Status.NotFound_Unequal_OutOfRange)
        require(msg.sender == cashierAddress, "UNAUTHORIZED_C"); //hex"10" FISSION.code(FISSION.Category.Permission, FISSION.Status.Disallowed_Stop)
        _;
    }

    modifier onlyVoucherOwner(uint256 _tokenIdVoucher, address _sender) {
        //check authorization
        require(
            IERC721(tokensContract).ownerOf(_tokenIdVoucher) == _sender,
            "UNAUTHORIZED_V"
        ); //hex"10" FISSION.code(FISSION.Category.Permission, FISSION.Status.Disallowed_Stop)
        _;
    }

    constructor(address _tokensContract) {
        tokensContract = _tokensContract;

        complainPeriod = 7 * 1 days;
        cancelFaultPeriod = 7 * 1 days;
    }

    /**
     * @notice Pause the process of interaction with voucherID's (ERC-721), in case of emergency.
     * Only BR contract is in control of this function.
     */
    function pause() external override onlyFromRouter {
        _pause();
    }

    /**
     * @notice Unpause the process of interaction with voucherID's (ERC-721).
     * Only BR contract is in control of this function.
     */
    function unpause() external override onlyFromRouter {
        _unpause();
    }

    /**
     * @notice Creating a new promise for goods or services.
     * Can be reused, e.g. for making different batches of these (in the future).
     * @param _seller      seller of the promise
     * @param _validFrom   Start of valid period
     * @param _validTo     End of valid period
     * @param _price       Price (payment amount)
     * @param _depositSe   Seller's deposit
     * @param _depositBu   Buyer's deposit
     */
    function createTokenSupplyID(
        address _seller,
        uint256 _validFrom,
        uint256 _validTo,
        uint256 _price,
        uint256 _depositSe,
        uint256 _depositBu,
        uint256 _quantity
    ) external override onlyFromRouter returns (uint256) {
        require(_validFrom <= _validTo, "INVALID_VALIDITY_FROM"); //hex"26" FISSION.code(FISSION.Category.Find, FISSION.Status.Above_Range_Overflow)
        // solhint-disable-next-line not-rely-on-time
        require(_validTo >= block.timestamp + 5 minutes, "INVALID_VALIDITY_TO"); //"Minimum order validity is set to prevent any potential attack from flash-loans or similar." //hex"24" FISSION.code(FISSION.Category.Find, FISSION.Status.BelowRange_Underflow)

        bytes32 key;
        key = keccak256(
            abi.encodePacked(_seller, tokenNonces[_seller]++, _validFrom, _validTo)
        );

        if (promiseKeys.length > 0) {
            require(
                promiseKeys[promises[key].idx] != key,
                "PROMISE_ALREADY_EXISTS"
            );
        }

        promises[key] = Promise({
            promiseId: key,
            nonce: tokenNonces[_seller],
            seller: _seller,
            validFrom: _validFrom,
            validTo: _validTo,
            price: _price,
            depositSe: _depositSe,
            depositBu: _depositBu,
            idx: promiseKeys.length
        });

        promiseKeys.push(key);

        emit LogPromiseCreated(
            key,
            tokenNonces[_seller],
            _seller,
            _validFrom,
            _validTo,
            promiseKeys.length - 1
        );

        return createOrder(_seller, key, _quantity);
    }

    /**
     * @notice Creates a Payment method struct recording the details on how the seller requires to receive Price and Deposits for a certain Voucher Set.
     * @param _tokenIdSupply     _tokenIdSupply of the voucher set this is related to
     * @param _paymentMethod  might be ETHETH, ETHTKN, TKNETH or TKNTKN
     * @param _tokenPrice   token address which will hold the funds for the price of the voucher
     * @param _tokenDeposits   token address which will hold the funds for the deposits of the voucher
     */
    function createPaymentMethod(
        uint256 _tokenIdSupply,
        uint8 _paymentMethod,
        address _tokenPrice,
        address _tokenDeposits
    ) external override onlyFromRouter {
        paymentDetails[_tokenIdSupply] = VoucherPaymentMethod({
            paymentMethod: _paymentMethod,
            addressTokenPrice: _tokenPrice,
            addressTokenDeposits: _tokenDeposits
        });
    }

    /**
     * @notice Create an order for offering a certain quantity of an asset
     * This creates a listing in a marketplace, technically as an ERC-1155 non-fungible token with supply.
     * @param _seller     seller of the promise
     * @param _promiseId  ID of a promise (simplified into asset for demo)
     * @param _quantity   Quantity of assets on offer
     */
    function createOrder(
        address _seller,
        bytes32 _promiseId,
        uint256 _quantity
    ) private returns (uint256) {
        require(_promiseId != bytes32(0), "UNSPECIFIED_PROMISE"); //hex"20" FISSION.code(FISSION.Category.Find, FISSION.Status.NotFound_Unequal_OutOfRange)
        require(promises[_promiseId].seller == _seller, "UNAUTHORIZED_CO"); //hex"10" FISSION.code(FISSION.Category.Permission, FISSION.Status.Disallowed_Stop)
        require(_quantity > 0, "INVALID_QUANTITY"); //hex"24" FISSION.code(FISSION.Category.Find, FISSION.Status.BelowRange_Underflow)

        uint256 tokenIdSupply = generateTokenType(true); //create & assign a new non-fungible type

        ordersPromise[tokenIdSupply] = _promiseId;

        IERC1155ERC721(tokensContract).mint(
            _seller,
            tokenIdSupply,
            _quantity,
            ""
        );

        return tokenIdSupply;
    }

    /**
     * @notice Fill Voucher Order, iff funds paid, then extract & mint NFT to the voucher holder
     * @param _tokenIdSupply   ID of the supply token (ERC-1155)
     * @param _issuer          Address of the token's issuer
     * @param _holder          Address of the recipient of the voucher (ERC-721)
     * @param _paymentMethod   method being used for that particular order that needs to be fulfilled
     * @param _correlationId           ID of the current interaction with the smart contract for a specific user
     */
    function fillOrder(
        uint256 _tokenIdSupply,
        address _issuer,
        address _holder,
        uint8 _paymentMethod,
        uint256 _correlationId
    ) external override onlyFromRouter {
        uint8 paymentMethod = getVoucherPaymentMethod(_tokenIdSupply);

        //checks
        require(paymentMethod == _paymentMethod, "Incorrect Payment Method");
        checkOrderFillable(_tokenIdSupply, _issuer, _holder);

        //close order
        uint256 voucherTokenId = extract721(_issuer, _holder, _tokenIdSupply);

        emit LogVoucherDelivered(
            _tokenIdSupply,
            voucherTokenId,
            _issuer,
            _holder,
            getPromiseIdFromVoucherId(voucherTokenId),
            _correlationId
        );
    }

    /**
     * @notice Check order is fillable
     * @dev Will throw if checks don't pass
     * @param _tokenIdSupply  ID of the supply token
     * @param _issuer  Address of the token's issuer
     * @param _holder  Address of the recipient of the voucher (ERC-721)
     */
    function checkOrderFillable(
        uint256 _tokenIdSupply,
        address _issuer,
        address _holder
    ) internal view {
        require(_tokenIdSupply != 0, "UNSPECIFIED_ID"); //hex"20" FISSION.code(FISSION.Category.Find, FISSION.Status.NotFound_Unequal_OutOfRange)

        if (_holder.isContract()) {
            require(
                IERC165(_holder).supportsInterface(0x150b7a02),
                "UNSUPPORTED_ERC721_RECEIVED"
            ); //hex"31"
            //bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
        }

        require(_holder != address(0), "UNSPECIFIED_ADDRESS"); //hex"20" FISSION.code(FISSION.Category.Find, FISSION.Status.NotFound_Unequal_OutOfRange)
        require(
            IERC1155(tokensContract).balanceOf(_issuer, _tokenIdSupply) > 0,
            "OFFER_EMPTY"
        ); //hex"40" FISSION.code(FISSION.Category.Availability, FISSION.Status.Unavailable)

        bytes32 promiseKey = ordersPromise[_tokenIdSupply];

        require(
            promises[promiseKey].validTo >= block.timestamp,
            "OFFER_EXPIRED"
        );
    }

    /**
     * @notice Extract a standard non-fungible token ERC-721 from a supply stored in ERC-1155
     * @dev Token ID is derived following the same principles for both ERC-1155 and ERC-721
     * @param _issuer          The address of the token issuer
     * @param _to              The address of the token holder
     * @param _tokenIdSupply   ID of the token type
     * @return                 ID of the voucher token
     */
    function extract721(
        address _issuer,
        address _to,
        uint256 _tokenIdSupply
    ) internal returns (uint256) {
        if (_to.isContract()) {
            require(
                ERC721TokenReceiver(_to).onERC721Received(
                    _issuer,
                    msg.sender,
                    _tokenIdSupply,
                    ""
                ) == ERC721TokenReceiver(_to).onERC721Received.selector,
                "UNSUPPORTED_ERC721_RECEIVED"
            ); //hex"10" FISSION.code(FISSION.Category.Permission, FISSION.Status.Disallowed_Stop)
            //bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
        }

        IERC1155ERC721(tokensContract).burn(_issuer, _tokenIdSupply, 1); // This is hardcoded as 1 on purpose

        //calculate tokenId
        uint256 voucherTokenId =
            _tokenIdSupply | ++typeCounters[_tokenIdSupply];

        //set status
        vouchersStatus[voucherTokenId].status = setChange(
            vouchersStatus[voucherTokenId].status,
            IDX_COMMIT
        );
        vouchersStatus[voucherTokenId].isPaymentReleased = false;
        vouchersStatus[voucherTokenId].isDepositsReleased = false;

        //mint voucher NFT as ERC-721
        IERC1155ERC721(tokensContract).mint(_to, voucherTokenId);

        return voucherTokenId;
    }

    /**
     * @notice Extract a standard non-fungible tokens ERC-721 from a supply stored in ERC-1155
     * @dev Token ID is derived following the same principles for both ERC-1155 and ERC-721
     * @param _issuer          The address of the token issuer
     * @param _tokenIdSupply   ID of the token type
     * @param _qty   qty that should be burned
     */
    function burnSupplyOnPause(
        address _issuer,
        uint256 _tokenIdSupply,
        uint256 _qty
    ) external override whenPaused onlyFromCashier {
        IERC1155ERC721(tokensContract).burn(_issuer, _tokenIdSupply, _qty);
    }

    /**
     * @notice Creating a new token type, serving as the base for tokenID generation for NFTs, and a de facto ID for FTs.
     * @param _isNonFungible   Flag for generating NFT or FT
     * @return _tokenType   Returns a newly generated token type
     */
    function generateTokenType(bool _isNonFungible)
        internal
        returns (uint256 _tokenType)
    {
        typeId++;

        if (_isNonFungible) {
            _tokenType = TYPE_NF_BIT | (typeId << 128); //upper bit is 1, followed by sequence, leaving lower 128-bits as 0
        } else {
            _tokenType = typeId << 128; //upper bit is not set, followed by sequence, leaving lower 128-bits as 0
        }

        return _tokenType;
    }

    /* solhint-disable */

    /**
     * @notice Redemption of the vouchers promise
     * @param _tokenIdVoucher   ID of the voucher
     * @param _msgSender   account called the fn from the BR contract
     */
    function redeem(uint256 _tokenIdVoucher, address _msgSender)
        external
        override
        whenNotPaused
        onlyFromRouter
        onlyVoucherOwner(_tokenIdVoucher, _msgSender)
    {
        //check status
        require(
            isStateCommitted(vouchersStatus[_tokenIdVoucher].status),
            "ALREADY_PROCESSED"
        ); //hex"48" FISSION.code(FISSION.Category.Availability, FISSION.Status.AlreadyDone)

        //check validity period
        isInValidityPeriod(_tokenIdVoucher);
        Promise memory tPromise =
            promises[getPromiseIdFromVoucherId(_tokenIdVoucher)];

        vouchersStatus[_tokenIdVoucher].complainPeriodStart = block.timestamp;
        vouchersStatus[_tokenIdVoucher].status = setChange(
            vouchersStatus[_tokenIdVoucher].status,
            IDX_REDEEM
        );

        emit LogVoucherRedeemed(
            _tokenIdVoucher,
            _msgSender,
            tPromise.promiseId
        );
    }

    // // // // // // // //
    // UNHAPPY PATH
    // // // // // // // //

    /**
     * @notice Refunding a voucher
     * @param _tokenIdVoucher   ID of the voucher
     * @param _msgSender   account called the fn from the BR contract
     */
    function refund(uint256 _tokenIdVoucher, address _msgSender)
        external
        override
        whenNotPaused
        onlyFromRouter
        onlyVoucherOwner(_tokenIdVoucher, _msgSender)
    {
        require(
            isStateCommitted(vouchersStatus[_tokenIdVoucher].status),
            "INAPPLICABLE_STATUS"
        ); //hex"18" FISSION.code(FISSION.Category.Permission, FISSION.Status.NotApplicableToCurrentState)

        //check validity period
        isInValidityPeriod(_tokenIdVoucher);

        vouchersStatus[_tokenIdVoucher].complainPeriodStart = block.timestamp;
        vouchersStatus[_tokenIdVoucher].status = setChange(
            vouchersStatus[_tokenIdVoucher].status,
            IDX_REFUND
        );

        emit LogVoucherRefunded(_tokenIdVoucher);
    }

    /**
     * @notice Issue a complain for a voucher
     * @param _tokenIdVoucher   ID of the voucher
     * @param _msgSender   account called the fn from the BR contract
     */
    function complain(uint256 _tokenIdVoucher, address _msgSender)
        external
        override
        whenNotPaused
        onlyFromRouter
        onlyVoucherOwner(_tokenIdVoucher, _msgSender)
    {
        require(
            !isStatus(vouchersStatus[_tokenIdVoucher].status, IDX_COMPLAIN),
            "ALREADY_COMPLAINED"
        ); //hex"48" FISSION.code(FISSION.Category.Availability, FISSION.Status.AlreadyDone)
        require(
            !isStatus(vouchersStatus[_tokenIdVoucher].status, IDX_FINAL),
            "ALREADY_FINALIZED"
        ); //hex"48" FISSION.code(FISSION.Category.Availability, FISSION.Status.AlreadyDone)

        //check if still in the complain period
        Promise memory tPromise =
            promises[getPromiseIdFromVoucherId(_tokenIdVoucher)];

        //if redeemed or refunded
        if (
            isStateRedemptionSigned(vouchersStatus[_tokenIdVoucher].status) ||
            isStateRefunded(vouchersStatus[_tokenIdVoucher].status)
        ) {
            if (
                !isStatus(
                    vouchersStatus[_tokenIdVoucher].status,
                    IDX_CANCEL_FAULT
                )
            ) {
                require(
                    block.timestamp <=
                        vouchersStatus[_tokenIdVoucher].complainPeriodStart +
                            complainPeriod +
                            cancelFaultPeriod,
                    "COMPLAINPERIOD_EXPIRED"
                ); //hex"46" FISSION.code(FISSION.Category.Availability, FISSION.Status.Expired)
            } else {
                require(
                    block.timestamp <=
                        vouchersStatus[_tokenIdVoucher].complainPeriodStart +
                            complainPeriod,
                    "COMPLAINPERIOD_EXPIRED"
                ); //hex"46" FISSION.code(FISSION.Category.Availability, FISSION.Status.Expired)
            }

            vouchersStatus[_tokenIdVoucher].cancelFaultPeriodStart = block
                .timestamp;
            vouchersStatus[_tokenIdVoucher].status = setChange(
                vouchersStatus[_tokenIdVoucher].status,
                IDX_COMPLAIN
            );

            emit LogVoucherComplain(_tokenIdVoucher);

            //if expired
        } else if (isStateExpired(vouchersStatus[_tokenIdVoucher].status)) {
            if (
                !isStatus(
                    vouchersStatus[_tokenIdVoucher].status,
                    IDX_CANCEL_FAULT
                )
            ) {
                require(
                    block.timestamp <=
                        tPromise.validTo + complainPeriod + cancelFaultPeriod,
                    "COMPLAINPERIOD_EXPIRED"
                ); //hex"46" FISSION.code(FISSION.Category.Availability, FISSION.Status.Expired)
            } else {
                require(
                    block.timestamp <= tPromise.validTo + complainPeriod,
                    "COMPLAINPERIOD_EXPIRED"
                ); //hex"46" FISSION.code(FISSION.Category.Availability, FISSION.Status.Expired)
            }

            vouchersStatus[_tokenIdVoucher].cancelFaultPeriodStart = block
                .timestamp;
            vouchersStatus[_tokenIdVoucher].status = setChange(
                vouchersStatus[_tokenIdVoucher].status,
                IDX_COMPLAIN
            );

            emit LogVoucherComplain(_tokenIdVoucher);

            //if cancelOrFault
        } else if (
            isStatus(vouchersStatus[_tokenIdVoucher].status, IDX_CANCEL_FAULT)
        ) {
            require(
                block.timestamp <=
                    vouchersStatus[_tokenIdVoucher].complainPeriodStart +
                        complainPeriod,
                "COMPLAINPERIOD_EXPIRED"
            ); //hex"46" FISSION.code(FISSION.Category.Availability, FISSION.Status.Expired));

            vouchersStatus[_tokenIdVoucher].status = setChange(
                vouchersStatus[_tokenIdVoucher].status,
                IDX_COMPLAIN
            );

            emit LogVoucherComplain(_tokenIdVoucher);
        } else {
            revert("INAPPLICABLE_STATUS"); //hex"18" FISSION.code(FISSION.Category.Permission, FISSION.Status.NotApplicableToCurrentState)
        }
    }

    /**
     * @notice Cancel/Fault transaction by the Seller, admitting to a fault or backing out of the deal
     * @param _tokenIdVoucher   ID of the voucher
     */
    function cancelOrFault(uint256 _tokenIdVoucher, address _msgSender)
        external
        override
        whenNotPaused
    {
        uint256 tokenIdSupply = getIdSupplyFromVoucher(_tokenIdVoucher);
        require(
            getSupplyHolder(tokenIdSupply) == _msgSender,
            "UNAUTHORIZED_COF"
        ); //hex"10" FISSION.code(FISSION.Category.Permission, FISSION.Status.Disallowed_Stop)

        uint8 tStatus = vouchersStatus[_tokenIdVoucher].status;

        require(!isStatus(tStatus, IDX_CANCEL_FAULT), "ALREADY_CANCELFAULT"); //hex"48" FISSION.code(FISSION.Category.Availability, FISSION.Status.AlreadyDone)
        require(!isStatus(tStatus, IDX_FINAL), "ALREADY_FINALIZED"); //hex"48" FISSION.code(FISSION.Category.Availability, FISSION.Status.AlreadyDone)

        Promise memory tPromise =
            promises[getPromiseIdFromVoucherId(_tokenIdVoucher)];

        if (isStatus(tStatus, IDX_REDEEM) || isStatus(tStatus, IDX_REFUND)) {
            //if redeemed or refunded
            if (!isStatus(tStatus, IDX_COMPLAIN)) {
                require(
                    block.timestamp <=
                        vouchersStatus[_tokenIdVoucher].complainPeriodStart +
                            complainPeriod +
                            cancelFaultPeriod,
                    "COFPERIOD_EXPIRED"
                ); //hex"46" FISSION.code(FISSION.Category.Availability, FISSION.Status.Expired)
                vouchersStatus[_tokenIdVoucher].complainPeriodStart = block
                    .timestamp; //resetting the complain period
            } else {
                require(
                    block.timestamp <=
                        vouchersStatus[_tokenIdVoucher].cancelFaultPeriodStart +
                            cancelFaultPeriod,
                    "COFPERIOD_EXPIRED"
                ); //hex"46" FISSION.code(FISSION.Category.Availability, FISSION.Status.Expired)
            }
        } else if (isStatus(tStatus, IDX_EXPIRE)) {
            //if expired
            if (!isStatus(tStatus, IDX_COMPLAIN)) {
                require(
                    block.timestamp <=
                        tPromise.validTo + complainPeriod + cancelFaultPeriod,
                    "COFPERIOD_EXPIRED"
                ); //hex"46" FISSION.code(FISSION.Category.Availability, FISSION.Status.Expired)
            } else {
                require(
                    block.timestamp <=
                        vouchersStatus[_tokenIdVoucher].cancelFaultPeriodStart +
                            cancelFaultPeriod,
                    "COFPERIOD_EXPIRED"
                ); //hex"46" FISSION.code(FISSION.Category.Availability, FISSION.Status.Expired)
            }
        } else if (isStateCommitted(tStatus)) {
            //if committed only
            require(
                block.timestamp <=
                    tPromise.validTo + complainPeriod + cancelFaultPeriod,
                "COFPERIOD_EXPIRED"
            ); //hex"46" FISSION.code(FISSION.Category.Availability, FISSION.Status.Expired)
            vouchersStatus[_tokenIdVoucher].complainPeriodStart = block.timestamp; //complain period starts
        } else {
            revert("INAPPLICABLE_STATUS"); //hex"18" FISSION.code(FISSION.Category.Permission, FISSION.Status.NotApplicableToCurrentState)
        }

        vouchersStatus[_tokenIdVoucher].status = setChange(
            tStatus,
            IDX_CANCEL_FAULT
        );

        emit LogVoucherFaultCancel(_tokenIdVoucher);
    }

    /**
     * @notice Cancel/Fault transaction by the Seller, cancelling the remaining uncommitted voucher set so that seller prevents buyers from committing to vouchers for items no longer in exchange.
     * @param _tokenIdSupply   ID of the voucher set
     * @param _issuer   owner of the voucher
     */
    function cancelOrFaultVoucherSet(uint256 _tokenIdSupply, address _issuer)
        external
        override
        onlyFromRouter
        whenNotPaused
        returns (uint256)
    {
        require(getSupplyHolder(_tokenIdSupply) == _issuer, "UNAUTHORIZED_COF");

        uint256 remQty = getRemQtyForSupply(_tokenIdSupply, _issuer);

        require(remQty > 0, "OFFER_EMPTY");

        IERC1155ERC721(tokensContract).burn(_issuer, _tokenIdSupply, remQty);

        emit LogVoucherSetFaultCancel(_tokenIdSupply, _issuer);

        return remQty;
    }

    // // // // // // // //
    // BACK-END PROCESS
    // // // // // // // //

    /**
     * @notice Mark voucher token that the payment was released
     * @param _tokenIdVoucher   ID of the voucher token
     */
    function setPaymentReleased(uint256 _tokenIdVoucher)
        external
        override
        onlyFromCashier
    {
        require(_tokenIdVoucher != 0, "UNSPECIFIED_ID"); //hex"20" FISSION.code(FISSION.Category.Find, FISSION.Status.NotFound_Unequal_OutOfRange)
        vouchersStatus[_tokenIdVoucher].isPaymentReleased = true;

        emit LogFundsReleased(_tokenIdVoucher, 0);
    }

    /**
     * @notice Mark voucher token that the deposits were released
     * @param _tokenIdVoucher   ID of the voucher token
     */
    function setDepositsReleased(uint256 _tokenIdVoucher)
        external
        override
        onlyFromCashier
    {
        require(_tokenIdVoucher != 0, "UNSPECIFIED_ID"); //hex"20" FISSION.code(FISSION.Category.Find, FISSION.Status.NotFound_Unequal_OutOfRange)
        vouchersStatus[_tokenIdVoucher].isDepositsReleased = true;

        emit LogFundsReleased(_tokenIdVoucher, 1);
    }

    /**
     * @notice Mark voucher token as expired
     * @param _tokenIdVoucher   ID of the voucher token
     */
    function triggerExpiration(uint256 _tokenIdVoucher) external override {
        require(_tokenIdVoucher != 0, "UNSPECIFIED_ID"); //hex"20" FISSION.code(FISSION.Category.Find, FISSION.Status.NotFound_Unequal_OutOfRange)

        Promise memory tPromise =
            promises[getPromiseIdFromVoucherId(_tokenIdVoucher)];

        if (
            tPromise.validTo < block.timestamp &&
            isStateCommitted(vouchersStatus[_tokenIdVoucher].status)
        ) {
            vouchersStatus[_tokenIdVoucher].status = setChange(
                vouchersStatus[_tokenIdVoucher].status,
                IDX_EXPIRE
            );

            emit LogExpirationTriggered(_tokenIdVoucher, msg.sender);
        }
    }

    /**
     * @notice Mark voucher token to the final status
     * @param _tokenIdVoucher   ID of the voucher token
     */
    function triggerFinalizeVoucher(uint256 _tokenIdVoucher) external override {
        require(_tokenIdVoucher != 0, "UNSPECIFIED_ID"); //hex"20" FISSION.code(FISSION.Category.Find, FISSION.Status.NotFound_Unequal_OutOfRange)

        uint8 tStatus = vouchersStatus[_tokenIdVoucher].status;

        require(!isStatus(tStatus, IDX_FINAL), "ALREADY_FINALIZED"); //hex"48" FISSION.code(FISSION.Category.Availability, FISSION.Status.AlreadyDone)

        bool mark;
        Promise memory tPromise =
            promises[getPromiseIdFromVoucherId(_tokenIdVoucher)];

        if (isStatus(tStatus, IDX_COMPLAIN)) {
            if (isStatus(tStatus, IDX_CANCEL_FAULT)) {
                //if COMPLAIN && COF: then final
                mark = true;
            } else if (
                block.timestamp >=
                vouchersStatus[_tokenIdVoucher].cancelFaultPeriodStart +
                    cancelFaultPeriod
            ) {
                //if COMPLAIN: then final after cof period
                mark = true;
            }
        } else if (
            isStatus(tStatus, IDX_CANCEL_FAULT) &&
            block.timestamp >=
            vouchersStatus[_tokenIdVoucher].complainPeriodStart + complainPeriod
        ) {
            //if COF: then final after complain period
            mark = true;
        } else if (
            isStateRedemptionSigned(tStatus) || isStateRefunded(tStatus)
        ) {
            //if RDM/RFND NON_COMPLAIN: then final after complainPeriodStart + complainPeriod
            if (
                block.timestamp >=
                vouchersStatus[_tokenIdVoucher].complainPeriodStart +
                    complainPeriod
            ) {
                mark = true;
            }
        } else if (isStateExpired(tStatus)) {
            //if EXP NON_COMPLAIN: then final after validTo + complainPeriod
            if (block.timestamp >= tPromise.validTo + complainPeriod) {
                mark = true;
            }
        }

        if (mark) {
            vouchersStatus[_tokenIdVoucher].status = setChange(
                tStatus,
                IDX_FINAL
            );
            emit LogFinalizeVoucher(_tokenIdVoucher, msg.sender);
        }
    }

    /* solhint-enable */

    // // // // // // // //
    // UTILS
    // // // // // // // //

    /**
     * @notice Set the address of the new holder of a _tokenIdSupply on transfer
     * @param _tokenIdSupply   _tokenIdSupply which will be transferred
     * @param _newSeller   new holder of the supply
     */
    function setSupplyHolderOnTransfer(
        uint256 _tokenIdSupply,
        address _newSeller
    ) external override onlyFromRouter {
        bytes32 promiseKey = ordersPromise[_tokenIdSupply];
        promises[promiseKey].seller = _newSeller;
    }

    /**
     * @notice Set the address of the Boson Router contract
     * @param _bosonRouterAddress   The address of the BR contract
     */
    function setBosonRouterAddress(address _bosonRouterAddress)
        external
        onlyOwner
    {
        require(_bosonRouterAddress != address(0), "UNSPECIFIED_ADDRESS"); //hex"20" FISSION.code(FISSION.Category.Find, FISSION.Status.NotFound_Unequal_OutOfRange)

        bosonRouterAddress = _bosonRouterAddress;

        emit LogBosonRouterSet(_bosonRouterAddress, msg.sender);
    }

    /**
     * @notice Set the address of the Cashier contract
     * @param _cashierAddress   The address of the BR contract
     */
    function setCashierAddress(address _cashierAddress)
        external
        override
        onlyOwner
    {
        require(_cashierAddress != address(0), "UNSPECIFIED_ADDRESS"); //hex"20" FISSION.code(FISSION.Category.Find, FISSION.Status.NotFound_Unequal_OutOfRange)

        cashierAddress = _cashierAddress;

        emit LogCashierSet(_cashierAddress, msg.sender);
    }

    /**
     * @notice Set the general complain period, should be used sparingly as it has significant consequences. Here done simply for demo purposes.
     * @param _complainPeriod   the new value for complain period (in number of seconds)
     */
    function setComplainPeriod(uint256 _complainPeriod)
        external
        override
        onlyOwner
    {
        complainPeriod = _complainPeriod;

        emit LogComplainPeriodChanged(_complainPeriod, msg.sender);
    }

    /**
     * @notice Set the general cancelOrFault period, should be used sparingly as it has significant consequences. Here done simply for demo purposes.
     * @param _cancelFaultPeriod   the new value for cancelOrFault period (in number of seconds)
     */
    function setCancelFaultPeriod(uint256 _cancelFaultPeriod)
        external
        override
        onlyOwner
    {
        cancelFaultPeriod = _cancelFaultPeriod;

        emit LogCancelFaultPeriodChanged(_cancelFaultPeriod, msg.sender);
    }

    // // // // // // // //
    // GETTERS
    // // // // // // // //

    /**
     * @notice Get the promise ID at specific index
     * @param _idx  Index in the array of promise keys
     * @return      Promise ID
     */
    function getPromiseKey(uint256 _idx)
        public
        view
        override
        returns (bytes32)
    {
        return promiseKeys[_idx];
    }

    /**
     * @notice Get the supply token ID from a voucher token
     * @param _tokenIdVoucher   ID of the voucher token
     * @return                  ID of the supply token
     */
    function getIdSupplyFromVoucher(uint256 _tokenIdVoucher)
        public
        pure
        override
        returns (uint256)
    {
        return _tokenIdVoucher & MASK_TYPE;
    }

    /**
     * @notice Get the promise ID from a voucher token
     * @param _tokenIdVoucher   ID of the voucher token
     * @return                  ID of the promise
     */
    function getPromiseIdFromVoucherId(uint256 _tokenIdVoucher)
        public
        view
        override
        returns (bytes32)
    {
        require(_tokenIdVoucher != 0, "UNSPECIFIED_ID"); //hex"20" FISSION.code(FISSION.Category.Find, FISSION.Status.NotFound_Unequal_OutOfRange)

        uint256 tokenIdSupply = getIdSupplyFromVoucher(_tokenIdVoucher);
        return promises[ordersPromise[tokenIdSupply]].promiseId;
    }

    /**
     * @notice Get the remaining quantity left in supply of tokens (e.g ERC-721 left in ERC-1155) of an account
     * @param _tokenSupplyId  Token supply ID
     * @param _owner    holder of the Token Supply
     * @return          remaining quantity
     */
    function getRemQtyForSupply(uint256 _tokenSupplyId, address _owner)
        public
        view
        override
        returns (uint256)
    {
        return IERC1155(tokensContract).balanceOf(_owner, _tokenSupplyId);
    }

    /**
     * @notice Get all necessary funds for a supply token
     * @param _tokenIdSupply   ID of the supply token
     * @return                  returns a tuple (Payment amount, Seller's deposit, Buyer's deposit)
     */
    function getOrderCosts(uint256 _tokenIdSupply)
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        bytes32 promiseKey = ordersPromise[_tokenIdSupply];
        return (
            promises[promiseKey].price,
            promises[promiseKey].depositSe,
            promises[promiseKey].depositBu
        );
    }

    /**
     * @notice Get Buyer costs required to make an order for a supply token
     * @param _tokenIdSupply   ID of the supply token
     * @return                  returns a tuple (Payment amount, Buyer's deposit)
     */
    function getBuyerOrderCosts(uint256 _tokenIdSupply)
        public
        view
        override
        returns (uint256, uint256)
    {
        bytes32 promiseKey = ordersPromise[_tokenIdSupply];
        return (promises[promiseKey].price, promises[promiseKey].depositBu);
    }

    /**
     * @notice Get Seller deposit
     * @param _tokenIdSupply   ID of the supply token
     * @return                  returns sellers deposit
     */
    function getSellerDeposit(uint256 _tokenIdSupply)
        public
        view
        override
        returns (uint256)
    {
        bytes32 promiseKey = ordersPromise[_tokenIdSupply];
        return promises[promiseKey].depositSe;
    }

    /**
     * @notice Get the current status of a voucher
     * @param _tokenIdVoucher   ID of the voucher token
     * @return                  Status of the voucher (via enum)
     */
    function getVoucherStatus(uint256 _tokenIdVoucher)
        public
        view
        override
        returns (
            uint8,
            bool,
            bool
        )
    {
        return (
            vouchersStatus[_tokenIdVoucher].status,
            vouchersStatus[_tokenIdVoucher].isPaymentReleased,
            vouchersStatus[_tokenIdVoucher].isDepositsReleased
        );
    }

    /**
     * @notice Get the holder of a voucher
     * @param _tokenIdVoucher   ID of the voucher token
     * @return                  Address of the holder
     */
    function getVoucherHolder(uint256 _tokenIdVoucher)
        public
        view
        override
        returns (address)
    {
        return IERC721(tokensContract).ownerOf(_tokenIdVoucher);
    }

    /**
     * @notice Get the holder of a supply
     * @param _tokenIdSupply        ID of a promise which is mapped to the corresponding Promise
     * @return                  Address of the holder
     */
    function getSupplyHolder(uint256 _tokenIdSupply)
        public
        view
        override
        returns (address)
    {
        bytes32 promiseKey = ordersPromise[_tokenIdSupply];
        return promises[promiseKey].seller;
    }

    /**
     * @notice Get the address of the token where the price for the supply is held
     * @param _tokenIdSupply   ID of the voucher supply token
     * @return                  Address of the token
     */
    function getVoucherPriceToken(uint256 _tokenIdSupply)
        public
        view
        override
        returns (address)
    {
        return paymentDetails[_tokenIdSupply].addressTokenPrice;
    }

    /**
     * @notice Get the address of the token where the deposits for the supply are held
     * @param _tokenIdSupply   ID of the voucher supply token
     * @return                  Address of the token
     */
    function getVoucherDepositToken(uint256 _tokenIdSupply)
        public
        view
        override
        returns (address)
    {
        return paymentDetails[_tokenIdSupply].addressTokenDeposits;
    }

    /**
     * @notice Get the payment method for a particular _tokenIdSupply
     * @param _tokenIdSupply   ID of the voucher supply token
     * @return                  payment method
     */
    function getVoucherPaymentMethod(uint256 _tokenIdSupply)
        public
        view
        override
        returns (uint8)
    {
        return paymentDetails[_tokenIdSupply].paymentMethod;
    }

    /**
     * @notice Checks whether a voucher is in valid period for redemption (between start date and end date)
     * @param _tokenIdVoucher ID of the voucher token
     */
    function isInValidityPeriod(uint256 _tokenIdVoucher)
        public
        view
        override
        returns (bool)
    {
        //check validity period
        Promise memory tPromise =
            promises[getPromiseIdFromVoucherId(_tokenIdVoucher)];
        require(tPromise.validFrom <= block.timestamp, "INVALID_VALIDITY_FROM"); //hex"26" FISSION.code(FISSION.Category.Find, FISSION.Status.Above_Range_Overflow)
        require(tPromise.validTo >= block.timestamp, "INVALID_VALIDITY_TO"); //hex"24" FISSION.code(FISSION.Category.Find, FISSION.Status.BelowRange_Underflow)

        return true;
    }

    /**
     * @notice Checks whether a voucher is in valid state to be transferred. If either payments or deposits are released, voucher could not be transferred
     * @param _tokenIdVoucher ID of the voucher token
     */
    function isVoucherTransferable(uint256 _tokenIdVoucher) public override view returns (bool) {
        return !(
            vouchersStatus[_tokenIdVoucher].isPaymentReleased || 
            vouchersStatus[_tokenIdVoucher].isDepositsReleased
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.1;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
/* is IERC165 */
interface IERC1155 {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).        
    */
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).                
    */
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.        
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.1;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others (`ERC165Checker`).
 *
 * For an implementation, see `ERC165`.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.1;

import "./IERC165.sol";

/// @title ERC-721 Non-Fungible Token Standard
/// @dev Deviated from standard: external | payable >> public
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
abstract contract IERC721 is IERC165 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) public view virtual returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) public view virtual returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public virtual;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) public virtual;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved)
        external
        virtual;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId)
        public
        view
        virtual
        returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.1;

interface IERC1155ERC721 {
    /**
     * @notice Mint an amount of a desired token
     * Currently no restrictions as to who is allowed to mint - so, it is external.
     * @dev ERC-1155
     * @param _to       owner of the minted token
     * @param _tokenId  ID of the token to be minted
     * @param _value    Amount of the token to be minted
     * @param _data     Additional data forwarded to onERC1155BatchReceived if _to is a contract
     */
    function mint(
        address _to,
        uint256 _tokenId,
        uint256 _value,
        bytes calldata _data
    ) external;

    /**
     * @notice Burn an amount of tokens with the given ID
     * @dev ERC-1155
     * @param _account  Account which owns the token
     * @param _tokenId  ID of the token
     * @param _value    Amount of the token
     */
    function burn(
        address _account,
        uint256 _tokenId,
        uint256 _value
    ) external;

    /**
     * @notice Function to mint tokens.
     * @dev ERC-721
     * @param to The address that will receive the minted tokens.
     * @param tokenId The token id to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 tokenId) external returns (bool);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
    */
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.1;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.1;

interface IVoucherKernel {
    /**
     * @notice Pause the process of interaction with voucherID's (ERC-721), in case of emergency.
     * Only Cashier contract is in control of this function.
     */
    function pause() external;

    /**
     * @notice Unpause the process of interaction with voucherID's (ERC-721).
     * Only Cashier contract is in control of this function.
     */
    function unpause() external;

    /**
     * @notice Creating a new promise for goods or services.
     * Can be reused, e.g. for making different batches of these (but not in prototype).
     * @param _seller      seller of the promise
     * @param _validFrom   Start of valid period
     * @param _validTo     End of valid period
     * @param _price       Price (payment amount)
     * @param _depositSe   Seller's deposit
     * @param _depositBu   Buyer's deposit
     */
    function createTokenSupplyID(
        address _seller,
        uint256 _validFrom,
        uint256 _validTo,
        uint256 _price,
        uint256 _depositSe,
        uint256 _depositBu,
        uint256 _quantity
    ) external returns (uint256);

    /**
     * @notice Creates a Payment method struct recording the details on how the seller requires to receive Price and Deposits for a certain Voucher Set.
     * @param _tokenIdSupply     _tokenIdSupply of the voucher set this is related to
     * @param _paymentMethod  might be ETHETH, ETHTKN, TKNETH or TKNTKN
     * @param _tokenPrice   token address which will hold the funds for the price of the voucher
     * @param _tokenDeposits   token address which will hold the funds for the deposits of the voucher
     */
    function createPaymentMethod(
        uint256 _tokenIdSupply,
        uint8 _paymentMethod,
        address _tokenPrice,
        address _tokenDeposits
    ) external;

    /**
     * @notice Mark voucher token that the payment was released
     * @param _tokenIdVoucher   ID of the voucher token
     */
    function setPaymentReleased(uint256 _tokenIdVoucher) external;

    /**
     * @notice Mark voucher token that the deposits were released
     * @param _tokenIdVoucher   ID of the voucher token
     */
    function setDepositsReleased(uint256 _tokenIdVoucher) external;

    /**
     * @notice Extract a standard non-fungible tokens ERC-721 from a supply stored in ERC-1155
     * @dev Token ID is derived following the same principles for both ERC-1155 and ERC-721
     * @param _issuer          The address of the token issuer
     * @param _tokenIdSupply   ID of the token type
     * @param _qty   qty that should be burned
     */
    function burnSupplyOnPause(
        address _issuer,
        uint256 _tokenIdSupply,
        uint256 _qty
    ) external;

    /**
     * @notice Redemption of the vouchers promise
     * @param _tokenIdVoucher   ID of the voucher
     * @param _msgSender owner of the voucher
     */
    function redeem(uint256 _tokenIdVoucher, address _msgSender) external;

    /**
     * @notice Refunding a voucher
     * @param _tokenIdVoucher   ID of the voucher
     * @param _msgSender owner of the voucher
     */
    function refund(uint256 _tokenIdVoucher, address _msgSender) external;

    /**
     * @notice Issue a complain for a voucher
     * @param _tokenIdVoucher   ID of the voucher
     * @param _msgSender owner of the voucher
     */
    function complain(uint256 _tokenIdVoucher, address _msgSender) external;

    /**
     * @notice Cancel/Fault transaction by the Seller, admitting to a fault or backing out of the deal
     * @param _tokenIdVoucher   ID of the voucher
     * @param _msgSender owner of the voucher set (seller)
     */
    function cancelOrFault(uint256 _tokenIdVoucher, address _msgSender)
        external;

    /**
     * @notice Cancel/Fault transaction by the Seller, cancelling the remaining uncommitted voucher set so that seller prevents buyers from committing to vouchers for items no longer in exchange.
     * @param _tokenIdSupply   ID of the voucher
     * @param _issuer   owner of the voucher
     */
    function cancelOrFaultVoucherSet(uint256 _tokenIdSupply, address _issuer)
        external
        returns (uint256);

    /**
     * @notice Fill Voucher Order, iff funds paid, then extract & mint NFT to the voucher holder
     * @param _tokenIdSupply   ID of the supply token (ERC-1155)
     * @param _issuer          Address of the token's issuer
     * @param _holder          Address of the recipient of the voucher (ERC-721)
     * @param _paymentMethod   method being used for that particular order that needs to be fulfilled
     * @param _correlationId           ID of the current interaction with the smart contract for a specific user
     */
    function fillOrder(
        uint256 _tokenIdSupply,
        address _issuer,
        address _holder,
        uint8 _paymentMethod,
        uint256 _correlationId
    ) external;

    /**
     * @notice Mark voucher token as expired
     * @param _tokenIdVoucher   ID of the voucher token
     */
    function triggerExpiration(uint256 _tokenIdVoucher) external;

    /**
     * @notice Mark voucher token to the final status
     * @param _tokenIdVoucher   ID of the voucher token
     */
    function triggerFinalizeVoucher(uint256 _tokenIdVoucher) external;

    /**
     * @notice Set the address of the new holder of a _tokenIdSupply on transfer
     * @param _tokenIdSupply   _tokenIdSupply which will be transferred
     * @param _newSeller   new holder of the supply
     */
    function setSupplyHolderOnTransfer(
        uint256 _tokenIdSupply,
        address _newSeller
    ) external;

    /**
     * @notice Set the general cancelOrFault period, should be used sparingly as it has significant consequences. Here done simply for demo purposes.
     * @param _cancelFaultPeriod   the new value for cancelOrFault period (in number of seconds)
     */
    function setCancelFaultPeriod(uint256 _cancelFaultPeriod) external;

    /**
     * @notice Set the address of the Cashier contract
     * @param _cashierAddress   The address of the Cashier contract
     */
    function setCashierAddress(address _cashierAddress) external;

    /**
     * @notice Set the general complain period, should be used sparingly as it has significant consequences. Here done simply for demo purposes.
     * @param _complainPeriod   the new value for complain period (in number of seconds)
     */
    function setComplainPeriod(uint256 _complainPeriod) external;

    /**
     * @notice Get the promise ID at specific index
     * @param _idx  Index in the array of promise keys
     * @return      Promise ID
     */
    function getPromiseKey(uint256 _idx) external view returns (bytes32);

    /**
     * @notice Get the address of the token where the price for the supply is held
     * @param _tokenIdSupply   ID of the voucher token
     * @return                  Address of the token
     */
    function getVoucherPriceToken(uint256 _tokenIdSupply)
        external
        view
        returns (address);

    /**
     * @notice Get the address of the token where the deposits for the supply are held
     * @param _tokenIdSupply   ID of the voucher token
     * @return                  Address of the token
     */
    function getVoucherDepositToken(uint256 _tokenIdSupply)
        external
        view
        returns (address);

    /**
     * @notice Get Buyer costs required to make an order for a supply token
     * @param _tokenIdSupply   ID of the supply token
     * @return                  returns a tuple (Payment amount, Buyer's deposit)
     */
    function getBuyerOrderCosts(uint256 _tokenIdSupply)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Get Seller deposit
     * @param _tokenIdSupply   ID of the supply token
     * @return                  returns sellers deposit
     */
    function getSellerDeposit(uint256 _tokenIdSupply)
        external
        view
        returns (uint256);

    /**
     * @notice Get the promise ID from a voucher token
     * @param _tokenIdVoucher   ID of the voucher token
     * @return                  ID of the promise
     */
    function getIdSupplyFromVoucher(uint256 _tokenIdVoucher)
        external
        pure
        returns (uint256);

    /**
     * @notice Get the promise ID from a voucher token
     * @param _tokenIdVoucher   ID of the voucher token
     * @return                  ID of the promise
     */
    function getPromiseIdFromVoucherId(uint256 _tokenIdVoucher)
        external
        view
        returns (bytes32);

    /**
     * @notice Get all necessary funds for a supply token
     * @param _tokenIdSupply   ID of the supply token
     * @return                  returns a tuple (Payment amount, Seller's deposit, Buyer's deposit)
     */
    function getOrderCosts(uint256 _tokenIdSupply)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     * @notice Get the remaining quantity left in supply of tokens (e.g ERC-721 left in ERC-1155) of an account
     * @param _tokenSupplyId  Token supply ID
     * @param _owner    holder of the Token Supply
     * @return          remaining quantity
     */
    function getRemQtyForSupply(uint256 _tokenSupplyId, address _owner)
        external
        view
        returns (uint256);

    /**
     * @notice Get the payment method for a particular _tokenIdSupply
     * @param _tokenIdSupply   ID of the voucher supply token
     * @return                  payment method
     */
    function getVoucherPaymentMethod(uint256 _tokenIdSupply)
        external
        view
        returns (uint8);

    /**
     * @notice Get the current status of a voucher
     * @param _tokenIdVoucher   ID of the voucher token
     * @return                  Status of the voucher (via enum)
     */
    function getVoucherStatus(uint256 _tokenIdVoucher)
        external
        view
        returns (
            uint8,
            bool,
            bool
        );

    /**
     * @notice Get the holder of a supply
     * @param _tokenIdSupply        ID of a promise which is mapped to the corresponding Promise
     * @return                  Address of the holder
     */
    function getSupplyHolder(uint256 _tokenIdSupply)
        external
        view
        returns (address);

    /**
     * @notice Get the holder of a voucher
     * @param _tokenIdVoucher   ID of the voucher token
     * @return                  Address of the holder
     */
    function getVoucherHolder(uint256 _tokenIdVoucher)
        external
        view
        returns (address);

    /**
     * @notice Checks whether a voucher is in valid period for redemption (between start date and end date)
     * @param _tokenIdVoucher ID of the voucher token
     */
    function isInValidityPeriod(uint256 _tokenIdVoucher)
        external
        view
        returns (bool);

    /**
     * @notice Checks whether a voucher is in valid state to be transferred. If either payments or deposits are released, voucher could not be transferred
     * @param _tokenIdVoucher ID of the voucher token
     */
    function isVoucherTransferable(uint256 _tokenIdVoucher)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.1;

/**
 * @title Utility contract to enable access to common structures
 */
contract UsingHelpers {
    uint8 internal constant ONE = 1;
    uint8 internal constant IDX_COMMIT = 7;
    uint8 internal constant IDX_REDEEM = 6;
    uint8 internal constant IDX_REFUND = 5;
    uint8 internal constant IDX_EXPIRE = 4;
    uint8 internal constant IDX_COMPLAIN = 3;
    uint8 internal constant IDX_CANCEL_FAULT = 2;
    uint8 internal constant IDX_FINAL = 1;

    /*  Status of the voucher in 8 bits:
        [7:COMMITTED] [6:REDEEMED] [5:REFUNDED] [4:EXPIRED] [3:COMPLAINED] [2:CANCELORFAULT] [1:FINAL] [1:/]
    */

    // Those are the payment methods we are using throughout the system.
    // Depending on how to user choose to interact with it's funds we store the method, so we could distribute its tokens afterwise
    uint8 internal constant ETHETH = 1;
    uint8 internal constant ETHTKN = 2;
    uint8 internal constant TKNETH = 3;
    uint8 internal constant TKNTKN = 4;

    struct VoucherDetails {
        uint256 tokenIdSupply;
        uint256 tokenIdVoucher;
        address issuer;
        address holder;
        uint256 price;
        uint256 depositSe;
        uint256 depositBu;
        uint256 price2pool;
        uint256 deposit2pool;
        uint256 price2issuer;
        uint256 deposit2issuer;
        uint256 price2holder;
        uint256 deposit2holder;
        uint8 paymentMethod;
        VoucherStatus currStatus;
    }

    struct VoucherStatus {
        uint8 status;
        bool isPaymentReleased;
        bool isDepositsReleased;
        uint256 complainPeriodStart;
        uint256 cancelFaultPeriodStart;
    }

    /**
     * @notice Based on its lifecycle, voucher can have many different statuses. Checks whether a voucher is in Committed state.
     * @param _status current status of a voucher.
     */
    function isStateCommitted(uint8 _status) internal pure returns (bool) {
        return _status == setChange(0, IDX_COMMIT);
    }

    /**
     * @notice Based on its lifecycle, voucher can have many different statuses. Checks whether a voucher is in RedemptionSigned state.
     * @param _status current status of a voucher.
     */
    function isStateRedemptionSigned(uint8 _status)
        internal
        pure
        returns (bool)
    {
        return _status == setChange(setChange(0, IDX_COMMIT), IDX_REDEEM);
    }

    /**
     * @notice Based on its lifecycle, voucher can have many different statuses. Checks whether a voucher is in Refunded state.
     * @param _status current status of a voucher.
     */
    function isStateRefunded(uint8 _status) internal pure returns (bool) {
        return _status == setChange(setChange(0, IDX_COMMIT), IDX_REFUND);
    }

    /**
     * @notice Based on its lifecycle, voucher can have many different statuses. Checks whether a voucher is in Expired state.
     * @param _status current status of a voucher.
     */
    function isStateExpired(uint8 _status) internal pure returns (bool) {
        return _status == setChange(setChange(0, IDX_COMMIT), IDX_EXPIRE);
    }

    /**
     * @notice Based on its lifecycle, voucher can have many different statuses. Checks the current status a voucher is at.
     * @param _status current status of a voucher.
     * @param _idx status to compare.
     */
    function isStatus(uint8 _status, uint8 _idx) internal pure returns (bool) {
        return (_status >> _idx) & ONE == 1;
    }

    /**
     * @notice Set voucher status.
     * @param _status previous status.
     * @param _changeIdx next status.
     */
    function setChange(uint8 _status, uint8 _changeIdx)
        internal
        pure
        returns (uint8)
    {
        return _status | (ONE << _changeIdx);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

{
  "optimizer": {
    "enabled": true,
    "runs": 10
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}