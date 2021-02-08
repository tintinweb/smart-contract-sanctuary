// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

import "./interface/IERC20Extended.sol";
import "./interface/IPremiaOption.sol";
import "./interface/IFeeCalculator.sol";
import "./interface/IPremiaReferral.sol";
import "./interface/IPremiaUncutErc20.sol";

/// @author Premia
/// @title An option market contract
contract PremiaMarket is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // The uPremia token
    IPremiaUncutErc20 public uPremia;
    // FeeCalculator contract
    IFeeCalculator public feeCalculator;
    // PremiaReferral contract
    IPremiaReferral public premiaReferral;

    // List of whitelisted option contracts for which users can create orders
    EnumerableSet.AddressSet private _whitelistedOptionContracts;
    // List of whitelisted payment tokens that users can use to buy / sell options
    EnumerableSet.AddressSet private _whitelistedPaymentTokens;

    mapping(address => uint8) public paymentTokenDecimals;

    // Recipient of protocol fees
    address public feeRecipient;

    enum SaleSide {Buy, Sell}

    uint256 private constant _inverseBasisPoint = 1e4;

    // Salt to prevent duplicate hash
    uint256 salt = 0;

    // An order on the exchange
    struct Order {
        address maker;              // Order maker address
        SaleSide side;              // Side (buy/sell)
        bool isDelayedWriting;      // If true, option has not been written yet
        address optionContract;     // Address of optionContract from which option is from
        uint256 optionId;           // OptionId
        address paymentToken;       // Address of token used for payment
        uint256 pricePerUnit;       // Price per unit (in paymentToken) with 18 decimals
        uint256 expirationTime;     // Expiration timestamp of option (Which is also expiration of order)
        uint256 salt;               // To ensure unique hash
        uint8 decimals;             // Option token decimals
    }

    struct Option {
        address token;              // Token address
        uint256 expiration;         // Expiration timestamp of the option (Must follow expirationIncrement)
        uint256 strikePrice;        // Strike price (Must follow strikePriceIncrement of token)
        bool isCall;                // If true : Call option | If false : Put option
    }

    // OrderId -> Amount of options left to purchase/sell
    mapping(bytes32 => uint256) public amounts;

    // Mapping of balances of uPremia to claim for each address
    mapping(address => uint256) public uPremiaBalance;

    // Whether delayed option writing is enabled or not
    // This allow users to create a sell order for an option, without writing it, and delay the writing at the moment the order is filled
    bool public isDelayedWritingEnabled = true;

    ////////////
    // Events //
    ////////////

    event OrderCreated(
        bytes32 indexed hash,
        address indexed maker,
        address indexed optionContract,
        SaleSide side,
        bool isDelayedWriting,
        uint256 optionId,
        address paymentToken,
        uint256 pricePerUnit,
        uint256 expirationTime,
        uint256 salt,
        uint256 amount,
        uint8 decimals
    );

    event OrderFilled(
        bytes32 indexed hash,
        address indexed taker,
        address indexed optionContract,
        address maker,
        address paymentToken,
        uint256 amount,
        uint256 pricePerUnit
    );

    event OrderCancelled(
        bytes32 indexed hash,
        address indexed maker,
        address indexed optionContract,
        address paymentToken,
        uint256 amount,
        uint256 pricePerUnit
    );

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    /// @param _uPremia The uPremia token
    /// @param _feeCalculator FeeCalculator contract
    /// @param _feeRecipient Address receiving protocol fees (PremiaMaker)
    constructor(IPremiaUncutErc20 _uPremia, IFeeCalculator _feeCalculator, address _feeRecipient, IPremiaReferral _premiaReferral) {
        require(_feeRecipient != address(0), "FeeRecipient cannot be 0x0 address");
        feeRecipient = _feeRecipient;
        uPremia = _uPremia;
        feeCalculator = _feeCalculator;
        premiaReferral = _premiaReferral;
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    ///////////
    // Admin //
    ///////////

    /// @notice Change the protocol fee recipient
    /// @param _feeRecipient New protocol fee recipient address
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "FeeRecipient cannot be 0x0 address");
        feeRecipient = _feeRecipient;
    }

    /// @notice Set new PremiaUncut token address
    /// @param _uPremia New uPremia contract
    function setPremiaUncutErc20(IPremiaUncutErc20 _uPremia) external onlyOwner {
        uPremia = _uPremia;
    }

    /// @notice Set new FeeCalculator contract
    /// @param _feeCalculator New FeeCalculator contract
    function setFeeCalculator(IFeeCalculator _feeCalculator) external onlyOwner {
        feeCalculator = _feeCalculator;
    }


    /// @notice Add contract addresses to the list of whitelisted option contracts
    /// @param _addr The list of addresses to add
    function addWhitelistedOptionContracts(address[] memory _addr) external onlyOwner {
        for (uint256 i=0; i < _addr.length; i++) {
            _whitelistedOptionContracts.add(_addr[i]);
        }
    }

    /// @notice Remove contract addresses from the list of whitelisted option contracts
    /// @param _addr The list of addresses to remove
    function removeWhitelistedOptionContracts(address[] memory _addr) external onlyOwner {
        for (uint256 i=0; i < _addr.length; i++) {
            _whitelistedOptionContracts.remove(_addr[i]);
        }
    }

    /// @notice Add token addresses to the list of whitelisted payment tokens
    /// @param _addr The list of addresses to add
    function addWhitelistedPaymentTokens(address[] memory _addr) external onlyOwner {
        for (uint256 i=0; i < _addr.length; i++) {
            uint8 decimals = IERC20Extended(_addr[i]).decimals();
            require(decimals <= 18, "Too many decimals");
            _whitelistedPaymentTokens.add(_addr[i]);
            paymentTokenDecimals[_addr[i]] = decimals;
        }
    }
    /// @notice Remove contract addresses from the list of whitelisted payment tokens
    /// @param _addr The list of addresses to remove
    function removeWhitelistedPaymentTokens(address[] memory _addr) external onlyOwner {
        for (uint256 i=0; i < _addr.length; i++) {
            _whitelistedPaymentTokens.remove(_addr[i]);
        }
    }

    /// @notice Enable or disable delayed option writing which allow users to create option sell order without writing the option before the order is filled
    /// @param _state New state (true = enabled / false = disabled)
    function setDelayedWritingEnabled(bool _state) external onlyOwner {
        isDelayedWritingEnabled = _state;
    }

    //////////////////////////////////////////////////

    //////////
    // View //
    //////////

    /// @notice Get the amounts left to buy/sell for an order
    /// @param _orderIds A list of order hashes
    /// @return List of amounts left for each order
    function getAmountsBatch(bytes32[] memory _orderIds) external view returns(uint256[] memory) {
        uint256[] memory result = new uint256[](_orderIds.length);

        for (uint256 i=0; i < _orderIds.length; i++) {
            result[i] = amounts[_orderIds[i]];
        }

        return result;
    }

    /// @notice Get order hashes for a list of orders
    /// @param _orders A list of orders
    /// @return List of orders hashes
    function getOrderHashBatch(Order[] memory _orders) external pure returns(bytes32[] memory) {
        bytes32[] memory result = new bytes32[](_orders.length);

        for (uint256 i=0; i < _orders.length; i++) {
            result[i] = getOrderHash(_orders[i]);
        }

        return result;
    }

    /// @notice Get the hash of an order
    /// @param _order The order from which to calculate the hash
    /// @return The order hash
    function getOrderHash(Order memory _order) public pure returns(bytes32) {
        return keccak256(abi.encode(_order));
    }

    /// @notice Get the list of whitelisted option contracts
    /// @return The list of whitelisted option contracts
    function getWhitelistedOptionContracts() external view returns(address[] memory) {
        uint256 length = _whitelistedOptionContracts.length();
        address[] memory result = new address[](length);

        for (uint256 i=0; i < length; i++) {
            result[i] = _whitelistedOptionContracts.at(i);
        }

        return result;
    }

    /// @notice Get the list of whitelisted payment tokens
    /// @return The list of whitelisted payment tokens
    function getWhitelistedPaymentTokens() external view returns(address[] memory) {
        uint256 length = _whitelistedPaymentTokens.length();
        address[] memory result = new address[](length);

        for (uint256 i=0; i < length; i++) {
            result[i] = _whitelistedPaymentTokens.at(i);
        }

        return result;
    }

    /// @notice Check the validity of an order (Make sure order make has sufficient balance + allowance for required tokens)
    /// @param _order The order from which to check the validity
    /// @return Whether the order is valid or not
    function isOrderValid(Order memory _order) public view returns(bool) {
        bytes32 hash = getOrderHash(_order);
        uint256 amountLeft = amounts[hash];

        if (amountLeft == 0) return false;

        // Expired
        if (_order.expirationTime == 0 || block.timestamp > _order.expirationTime) return false;

        IERC20 token = IERC20(_order.paymentToken);

        if (_order.side == SaleSide.Buy) {
            uint8 decimals = _order.decimals;
            uint256 basePrice = _order.pricePerUnit.mul(amountLeft).div(10**decimals);
            uint256 makerFee = feeCalculator.getFee(_order.maker, false, IFeeCalculator.FeeType.Maker);
            uint256 orderMakerFee = basePrice.mul(makerFee).div(_inverseBasisPoint);
            uint256 totalPrice = basePrice.add(orderMakerFee);

            uint256 userBalance = token.balanceOf(_order.maker);
            uint256 allowance = token.allowance(_order.maker, address(this));

            return userBalance >= totalPrice && allowance >= totalPrice;
        } else if (_order.side == SaleSide.Sell) {
            IPremiaOption premiaOption = IPremiaOption(_order.optionContract);
            bool isApproved = premiaOption.isApprovedForAll(_order.maker, address(this));

            if (_order.isDelayedWriting) {
                IPremiaOption.OptionData memory data = premiaOption.optionData(_order.optionId);
                IPremiaOption.OptionWriteArgs memory writeArgs = IPremiaOption.OptionWriteArgs({
                    token: data.token,
                    amount: amountLeft,
                    strikePrice: data.strikePrice,
                    expiration: data.expiration,
                    isCall: data.isCall
                });

                IPremiaOption.QuoteWrite memory quote = premiaOption.getWriteQuote(_order.maker, writeArgs, address(0), _order.decimals);

                uint256 userBalance = IERC20(quote.collateralToken).balanceOf(_order.maker);
                uint256 allowance = IERC20(quote.collateralToken).allowance(_order.maker, _order.optionContract);
                uint256 totalPrice = quote.collateral.add(quote.fee).add(quote.feeReferrer);

                return isApproved && userBalance >= totalPrice && allowance >= totalPrice;

            } else {
                uint256 optionBalance = premiaOption.balanceOf(_order.maker, _order.optionId);
                return isApproved && optionBalance >= amountLeft;
            }
        }

        return false;
    }

    /// @notice Check the validity of a list of orders (Make sure order make has sufficient balance + allowance for required tokens)
    /// @param _orders The orders from which to check the validity
    /// @return Whether the orders are valid or not
    function areOrdersValid(Order[] memory _orders) external view returns(bool[] memory) {
        bool[] memory result = new bool[](_orders.length);

        for (uint256 i=0; i < _orders.length; i++) {
            result[i] = isOrderValid(_orders[i]);
        }

        return result;
    }

    //////////////////////////////////////////////////

    //////////
    // Main //
    //////////

    /// @notice Claim pending uPremia rewards
    function claimUPremia() external {
        uint256 amount = uPremiaBalance[msg.sender];
        uPremiaBalance[msg.sender] = 0;
        IERC20(address(uPremia)).safeTransfer(msg.sender, amount);
    }

    /// @notice Create a new order
    /// @dev Maker, salt and expirationTime will be overridden by this function
    /// @param _order Order to create
    /// @param _amount Amount of options to buy / sell
    /// @return The hash of the order
    function createOrder(Order memory _order, uint256 _amount) public returns(bytes32) {
        require(_whitelistedOptionContracts.contains(_order.optionContract), "Option contract not whitelisted");
        require(_whitelistedPaymentTokens.contains(_order.paymentToken), "Payment token not whitelisted");

        IPremiaOption.OptionData memory data = IPremiaOption(_order.optionContract).optionData(_order.optionId);
        require(data.strikePrice > 0, "Option not found");
        require(block.timestamp < data.expiration, "Option expired");

        _order.maker = msg.sender;
        _order.expirationTime = data.expiration;
        _order.decimals = data.decimals;
        _order.salt = salt;

        require(_order.decimals <= 18, "Too many decimals");

        if (_order.isDelayedWriting) {
            require(isDelayedWritingEnabled, "Delayed writing disabled");
        }

        // If this is a buy order, isDelayedWriting is always false
        if (_order.side == SaleSide.Buy) {
            _order.isDelayedWriting = false;
        }

        salt = salt.add(1);

        bytes32 hash = getOrderHash(_order);
        amounts[hash] = _amount;
        uint8 decimals = _order.decimals;

        emit OrderCreated(
            hash,
            _order.maker,
            _order.optionContract,
            _order.side,
            _order.isDelayedWriting,
            _order.optionId,
            _order.paymentToken,
            _order.pricePerUnit,
            _order.expirationTime,
            _order.salt,
            _amount,
            decimals
        );

        return hash;
    }

    /// @notice Create an order for an option which has never been minted before (Will create a new optionId for this option)
    /// @param _order Order to create
    /// @param _amount Amount of options to buy / sell
    /// @param _option Option to create
    /// @return The hash of the order
    /// @param _referrer Referrer
    function createOrderForNewOption(Order memory _order, uint256 _amount, Option memory _option, address _referrer) external returns(bytes32) {
        // If this is a delayed writing on a sell order, we need to set referrer now, so that it is used when writing is done
        if (address(premiaReferral) != address(0) && _order.isDelayedWriting && _order.side == SaleSide.Sell) {
            _referrer = premiaReferral.trySetReferrer(msg.sender, _referrer);
        }

        _order.optionId = IPremiaOption(_order.optionContract).getOptionIdOrCreate(_option.token, _option.expiration, _option.strikePrice, _option.isCall);
        return createOrder(_order, _amount);
    }

    /// @notice Create a list of orders
    /// @param _orders Orders to create
    /// @param _amounts Amounts of options to buy / sell for each order
    /// @return The hashes of the orders
    function createOrders(Order[] memory _orders, uint256[] memory _amounts) external returns(bytes32[] memory) {
        require(_orders.length == _amounts.length, "Arrays must have same length");

        bytes32[] memory result = new bytes32[](_orders.length);

        for (uint256 i=0; i < _orders.length; i++) {
            result[i] = createOrder(_orders[i], _amounts[i]);
        }

        return result;
    }

    /// @notice Try to fill orders passed as candidates, and create order for remaining unfilled amount
    /// @param _order Order to create
    /// @param _amount Amount of options to buy / sell
    /// @param _orderCandidates Accepted orders to be filled
    /// @param _writeOnBuyFill Write option prior to filling order when a buy order is passed
    /// @param _referrer Referrer
    function createOrderAndTryToFill(Order memory _order, uint256 _amount, Order[] memory _orderCandidates, bool _writeOnBuyFill, address _referrer) external {
        require(_amount > 0, "Amount must be > 0");

        // Ensure candidate orders are valid
        for (uint256 i=0; i < _orderCandidates.length; i++) {
            require(_orderCandidates[i].side != _order.side, "Candidate order : Same order side");
            require(_orderCandidates[i].optionContract == _order.optionContract, "Candidate order : Diff option contract");
            require(_orderCandidates[i].optionId == _order.optionId, "Candidate order : Diff optionId");
        }

        uint256 totalFilled;
        if (_orderCandidates.length == 1) {
            totalFilled = fillOrder(_orderCandidates[0], _amount, _writeOnBuyFill, _referrer);
        } else if (_orderCandidates.length > 1) {
            totalFilled = fillOrders(_orderCandidates, _amount, _writeOnBuyFill, _referrer);
        }

        if (totalFilled < _amount) {
            createOrder(_order, _amount.sub(totalFilled));
        }
    }

    /// @notice Write an option and create a sell order
    /// @dev OptionId will be filled automatically on the order object. Amount is defined in the option object.
    ///      Approval on option contract is required
    /// @param _order Order to create
    /// @param _referrer Referrer
    /// @return The hash of the order
    function writeAndCreateOrder(IPremiaOption.OptionWriteArgs memory _option, Order memory _order, address _referrer) public returns(bytes32) {
        require(_order.side == SaleSide.Sell, "Not a sell order");

        // This cannot be a delayed writing as we are writing the option now
        _order.isDelayedWriting = false;

        IPremiaOption optionContract = IPremiaOption(_order.optionContract);
        _order.optionId = optionContract.writeOptionFrom(msg.sender, _option, _referrer);

        return createOrder(_order, _option.amount);
    }

    /// @notice Fill an existing order
    /// @param _order The order to fill
    /// @param _amount Max amount of options to buy or sell
    /// @param _writeOnBuyFill Write option prior to filling order when a buy order is passed
    /// @param _referrer Referrer
    /// @return Amount of options bought or sold
    function fillOrder(Order memory _order, uint256 _amount, bool _writeOnBuyFill, address _referrer) public nonReentrant returns(uint256) {
        bytes32 hash = getOrderHash(_order);

        require(_order.expirationTime != 0 && block.timestamp < _order.expirationTime, "Order expired");
        require(amounts[hash] > 0, "Order not found");
        require(_amount > 0, "Amount must be > 0");

        if (amounts[hash] < _amount) {
            _amount = amounts[hash];
        }

        amounts[hash] = amounts[hash].sub(_amount);

        // If option has delayed minting on fill, we first need to mint it on behalf of order maker
        if (_order.side == SaleSide.Sell && _order.isDelayedWriting) {
            // We do not pass a referrer, cause referrer used is the one of the order maker
            IPremiaOption(_order.optionContract).writeOptionWithIdFrom(_order.maker, _order.optionId, _amount, address(0));
        } else if (_order.side == SaleSide.Buy && _writeOnBuyFill) {
            IPremiaOption(_order.optionContract).writeOptionWithIdFrom(msg.sender, _order.optionId, _amount, _referrer);
        }

        uint256 basePrice = _order.pricePerUnit.mul(_amount).div(10**_order.decimals);

        (uint256 orderMakerFee,) = feeCalculator.getFeeAmounts(_order.maker, false, basePrice, IFeeCalculator.FeeType.Maker);
        (uint256 orderTakerFee,) = feeCalculator.getFeeAmounts(msg.sender, false, basePrice, IFeeCalculator.FeeType.Taker);

        if (_order.side == SaleSide.Buy) {
            IPremiaOption(_order.optionContract).safeTransferFrom(msg.sender, _order.maker, _order.optionId, _amount, "");

            IERC20(_order.paymentToken).safeTransferFrom(_order.maker, feeRecipient, orderMakerFee.add(orderTakerFee));
            IERC20(_order.paymentToken).safeTransferFrom(_order.maker, msg.sender, basePrice.sub(orderTakerFee));

        } else {
            IERC20(_order.paymentToken).safeTransferFrom(msg.sender, feeRecipient, orderMakerFee.add(orderTakerFee));
            IERC20(_order.paymentToken).safeTransferFrom(msg.sender, _order.maker, basePrice.sub(orderMakerFee));

            IPremiaOption(_order.optionContract).safeTransferFrom(_order.maker, msg.sender, _order.optionId, _amount, "");
        }

        // Mint uPremia
        if (address(uPremia) != address(0)) {
            uint256 paymentTokenPrice = uPremia.getTokenPrice(_order.paymentToken);

            uPremiaBalance[_order.maker] = uPremiaBalance[_order.maker].add(orderMakerFee.mul(paymentTokenPrice).div(10**paymentTokenDecimals[_order.paymentToken]));
            uPremiaBalance[msg.sender] = uPremiaBalance[msg.sender].add(orderTakerFee.mul(paymentTokenPrice).div(10**paymentTokenDecimals[_order.paymentToken]));

            uPremia.mint(address(this), orderMakerFee.add(orderTakerFee).mul(paymentTokenPrice).div(10**paymentTokenDecimals[_order.paymentToken]));
        }

        emit OrderFilled(
            hash,
            msg.sender,
            _order.optionContract,
            _order.maker,
            _order.paymentToken,
            _amount,
            _order.pricePerUnit
        );

        return _amount;
    }


    /// @notice Fill a list of existing orders
    /// @dev All orders passed must :
    ///         - Use same payment token
    ///         - Be on the same order side
    ///         - Be for the same option contract and optionId
    /// @param _orders The list of orders to fill
    /// @param _maxAmount Max amount of options to buy or sell
    /// @param _writeOnBuyFill Write option prior to filling order when a buy order is passed
    /// @param _referrer Referrer
    /// @return Amount of options bought or sold
    function fillOrders(Order[] memory _orders, uint256 _maxAmount, bool _writeOnBuyFill, address _referrer) public nonReentrant returns(uint256) {
        if (_maxAmount == 0) return 0;

        uint256 takerFee = feeCalculator.getFee(msg.sender, false, IFeeCalculator.FeeType.Taker);

        // We make sure all orders are same side / payment token / option contract / option id
        if (_orders.length > 1) {
            for (uint256 i=0; i < _orders.length; i++) {
                require(i == 0 || _orders[0].paymentToken == _orders[i].paymentToken, "Different payment tokens");
                require(i == 0 || _orders[0].side == _orders[i].side, "Different order side");
                require(i == 0 || _orders[0].optionContract == _orders[i].optionContract, "Different option contract");
                require(i == 0 || _orders[0].optionId == _orders[i].optionId, "Different option id");
            }
        }

        uint256 paymentTokenPrice;
        if (address(uPremia) != address(0)) {
            uPremia.getTokenPrice(_orders[0].paymentToken);
        }

        uint256 totalFee;
        uint256 totalAmount;
        uint256 amountFilled;

        for (uint256 i=0; i < _orders.length; i++) {
            if (amountFilled >= _maxAmount) break;

            Order memory _order = _orders[i];
            bytes32 hash = getOrderHash(_order);

            // If nothing left to fill, continue
            if (amounts[hash] == 0) continue;
            // If expired, continue
            if (block.timestamp >= _order.expirationTime) continue;

            uint256 amount = amounts[hash];
            if (amountFilled.add(amount) > _maxAmount) {
                amount = _maxAmount.sub(amountFilled);
            }

            amounts[hash] = amounts[hash].sub(amount);
            amountFilled = amountFilled.add(amount);

            // If option has delayed minting on fill, we first need to mint it on behalf of order maker
            if (_order.side == SaleSide.Sell && _order.isDelayedWriting) {
                // We do not pass a referrer, cause referrer used is the one of the order maker
                IPremiaOption(_order.optionContract).writeOptionWithIdFrom(_order.maker, _order.optionId, amount, address(0));
            } else if (_order.side == SaleSide.Buy && _writeOnBuyFill) {
                IPremiaOption(_order.optionContract).writeOptionWithIdFrom(msg.sender, _order.optionId, amount, _referrer);
            }

            uint256 basePrice = _order.pricePerUnit.mul(amount).div(10**_order.decimals);

            (uint256 orderMakerFee,) = feeCalculator.getFeeAmounts(_order.maker, false, basePrice, IFeeCalculator.FeeType.Maker);
            uint256 orderTakerFee = basePrice.mul(takerFee).div(_inverseBasisPoint);

            totalFee = totalFee.add(orderMakerFee).add(orderTakerFee);

            if (_order.side == SaleSide.Buy) {
                IPremiaOption(_order.optionContract).safeTransferFrom(msg.sender, _order.maker, _order.optionId, amount, "");

                // We transfer all to the contract, contract will pays fees, and send remainder to msg.sender
                IERC20(_order.paymentToken).safeTransferFrom(_order.maker, address(this), basePrice.add(orderMakerFee));
                totalAmount = totalAmount.add(basePrice.add(orderMakerFee));

            } else {
                // We pay order maker, fees will be all paid at once later
                IERC20(_order.paymentToken).safeTransferFrom(msg.sender, _order.maker, basePrice.sub(orderMakerFee));
                IPremiaOption(_order.optionContract).safeTransferFrom(_order.maker, msg.sender, _order.optionId, amount, "");
            }

            // Add uPremia reward to users balance
            if (address(uPremia) != address(0)) {
                uPremiaBalance[_order.maker] = uPremiaBalance[_order.maker].add(orderMakerFee.mul(paymentTokenPrice).div(10**paymentTokenDecimals[_order.paymentToken]));
                uPremiaBalance[msg.sender] = uPremiaBalance[msg.sender].add(orderTakerFee.mul(paymentTokenPrice).div(10**paymentTokenDecimals[_order.paymentToken]));
            }

            emit OrderFilled(
                hash,
                msg.sender,
                _order.optionContract,
                _order.maker,
                _order.paymentToken,
                amount,
                _order.pricePerUnit
            );
        }

        if (_orders[0].side == SaleSide.Buy) {
            // Batch payment of fees
            IERC20(_orders[0].paymentToken).safeTransfer(feeRecipient, totalFee);
            // Send remainder of tokens after fee payment, to msg.sender
            IERC20(_orders[0].paymentToken).safeTransfer(msg.sender, totalAmount.sub(totalFee));
        } else {
            // Batch payment of fees
            IERC20(_orders[0].paymentToken).safeTransferFrom(msg.sender, feeRecipient, totalFee);
        }

        // Mint uPremia
        if (address(uPremia) != address(0)) {
            uPremia.mint(address(this), totalFee.mul(paymentTokenPrice).div(10**paymentTokenDecimals[_orders[0].paymentToken]));
        }

        return amountFilled;
    }

    /// @notice Cancel an existing order
    /// @param _order The order to cancel
    function cancelOrder(Order memory _order) public {
        bytes32 hash = getOrderHash(_order);
        uint256 amountLeft = amounts[hash];

        require(amountLeft > 0, "Order not found");
        require(_order.maker == msg.sender, "Not order maker");
        delete amounts[hash];

        emit OrderCancelled(
            hash,
            _order.maker,
            _order.optionContract,
            _order.paymentToken,
            amountLeft,
            _order.pricePerUnit
        );
    }

    /// @notice Cancel a list of existing orders
    /// @param _orders The list of orders to cancel
    function cancelOrders(Order[] memory _orders) external {
        for (uint256 i=0; i < _orders.length; i++) {
            cancelOrder(_orders[i]);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Ownable is Context {
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

pragma solidity ^0.7.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import "../interface/IFlashLoanReceiver.sol";
import "../uniswapV2/interfaces/IUniswapV2Router02.sol";

interface IPremiaOption is IERC1155 {
    struct OptionWriteArgs {
        address token;                  // Token address
        uint256 amount;                 // Amount of tokens to write option for
        uint256 strikePrice;            // Strike price (Must follow strikePriceIncrement of token)
        uint256 expiration;             // Expiration timestamp of the option (Must follow expirationIncrement)
        bool isCall;                    // If true : Call option | If false : Put option
    }

    struct OptionData {
        address token;                  // Token address
        uint256 strikePrice;            // Strike price (Must follow strikePriceIncrement of token)
        uint256 expiration;             // Expiration timestamp of the option (Must follow expirationIncrement)
        bool isCall;                    // If true : Call option | If false : Put option
        uint256 claimsPreExp;           // Amount of options from which the funds have been withdrawn pre expiration
        uint256 claimsPostExp;          // Amount of options from which the funds have been withdrawn post expiration
        uint256 exercised;              // Amount of options which have been exercised
        uint256 supply;                 // Total circulating supply
        uint8 decimals;                 // Token decimals
    }

    // Total write cost = collateral + fee + feeReferrer
    struct QuoteWrite {
        address collateralToken;        // The token to deposit as collateral
        uint256 collateral;             // The amount of collateral to deposit
        uint8 collateralDecimals;       // Decimals of collateral token
        uint256 fee;                    // The amount of collateralToken needed to be paid as protocol fee
        uint256 feeReferrer;            // The amount of collateralToken which will be paid the referrer
    }

    // Total exercise cost = input + fee + feeReferrer
    struct QuoteExercise {
        address inputToken;             // Input token for exercise
        uint256 input;                  // Amount of input token to pay to exercise
        uint8 inputDecimals;            // Decimals of input token
        address outputToken;            // Output token from the exercise
        uint256 output;                 // Amount of output tokens which will be received on exercise
        uint8 outputDecimals;           // Decimals of output token
        uint256 fee;                    // The amount of inputToken needed to be paid as protocol fee
        uint256 feeReferrer;            // The amount of inputToken which will be paid to the referrer
    }

    struct Pool {
        uint256 tokenAmount;
        uint256 denominatorAmount;
    }

    function denominatorDecimals() external view returns(uint8);

    function maxExpiration() external view returns(uint256);
    function optionData(uint256 _optionId) external view returns (OptionData memory);
    function tokenStrikeIncrement(address _token) external view returns (uint256);
    function nbWritten(address _writer, uint256 _optionId) external view returns (uint256);

    function getOptionId(address _token, uint256 _expiration, uint256 _strikePrice, bool _isCall) external view returns(uint256);
    function getOptionIdOrCreate(address _token, uint256 _expiration, uint256 _strikePrice, bool _isCall) external returns(uint256);

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    function getWriteQuote(address _from, OptionWriteArgs memory _option, address _referrer, uint8 _decimals) external view returns(QuoteWrite memory);
    function getExerciseQuote(address _from, OptionData memory _option, uint256 _amount, address _referrer, uint8 _decimals) external view returns(QuoteExercise memory);

    function writeOptionWithIdFrom(address _from, uint256 _optionId, uint256 _amount, address _referrer) external returns(uint256);
    function writeOption(address _token, OptionWriteArgs memory _option, address _referrer) external returns(uint256);
    function writeOptionFrom(address _from, OptionWriteArgs memory _option, address _referrer) external returns(uint256);
    function cancelOption(uint256 _optionId, uint256 _amount) external;
    function cancelOptionFrom(address _from, uint256 _optionId, uint256 _amount) external;
    function exerciseOption(uint256 _optionId, uint256 _amount) external;
    function exerciseOptionFrom(address _from, uint256 _optionId, uint256 _amount, address _referrer) external;
    function withdraw(uint256 _optionId) external;
    function withdrawFrom(address _from, uint256 _optionId) external;
    function withdrawPreExpiration(uint256 _optionId, uint256 _amount) external;
    function withdrawPreExpirationFrom(address _from, uint256 _optionId, uint256 _amount) external;
    function flashExerciseOption(uint256 _optionId, uint256 _amount, address _referrer, IUniswapV2Router02 _router, uint256 _amountInMax) external;
    function flashExerciseOptionFrom(address _from, uint256 _optionId, uint256 _amount, address _referrer, IUniswapV2Router02 _router, uint256 _amountInMax) external;
    function flashLoan(address _tokenAddress, uint256 _amount, IFlashLoanReceiver _receiver) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface IFeeCalculator {
    enum FeeType {Write, Exercise, Maker, Taker, FlashLoan}

    function writeFee() external view returns(uint256);
    function exerciseFee() external view returns(uint256);
    function flashLoanFee() external view returns(uint256);

    function referrerFee() external view returns(uint256);
    function referredDiscount() external view returns(uint256);

    function makerFee() external view returns(uint256);
    function takerFee() external view returns(uint256);

    function getFee(address _user, bool _hasReferrer, FeeType _feeType) external view returns(uint256);
    function getFeeAmounts(address _user, bool _hasReferrer, uint256 _amount, FeeType _feeType) external view returns(uint256 _fee, uint256 _feeReferrer);
    function getFeeAmountsWithDiscount(address _user, bool _hasReferrer, uint256 _baseFee) external view returns(uint256 _fee, uint256 _feeReferrer);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface IPremiaReferral {
    function referrals(address _referred) external view returns(address _referrer);
    function trySetReferrer(address _referred, address _potentialReferrer) external returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IPremiaUncutErc20 is IERC20 {
    function getTokenPrice(address _token) external view returns(uint256);
    function mint(address _account, uint256 _amount) external;
    function mintReward(address _account, address _token, uint256 _feePaid, uint8 _decimals) external;
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

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface IFlashLoanReceiver {
    function execute(address _tokenAddress, uint256 _amount, uint256 _amountWithFee) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}