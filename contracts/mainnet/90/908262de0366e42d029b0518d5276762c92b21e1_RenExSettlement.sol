pragma solidity 0.4.24;

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    * @notice Renouncing to ownership will leave the contract without an owner.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/// @notice The Orderbook contract stores the state and priority of orders and
/// allows the Darknodes to easily reach consensus. Eventually, this contract
/// will only store a subset of order states, such as cancellation, to improve
/// the throughput of orders.
contract Orderbook  {
    /// @notice OrderState enumerates the possible states of an order. All
    /// orders default to the Undefined state.
    enum OrderState {Undefined, Open, Confirmed, Canceled}

    /// @notice returns a list of matched orders to the given orderID.
    function orderMatch(bytes32 _orderID) external view returns (bytes32);

    /// @notice returns the trader of the given orderID.
    /// Trader is the one who signs the message and does the actual trading.
    function orderTrader(bytes32 _orderID) external view returns (address);

    /// @notice returns status of the given orderID.
    function orderState(bytes32 _orderID) external view returns (OrderState);

    /// @notice returns the darknode address which confirms the given orderID.
    function orderConfirmer(bytes32 _orderID) external view returns (address);
}


/// @notice RenExTokens is a registry of tokens that can be traded on RenEx.
contract RenExTokens is Ownable {
    struct TokenDetails {
        address addr;
        uint8 decimals;
        bool registered;
    }

    mapping(uint32 => TokenDetails) public tokens;

    /// @notice Allows the owner to register and the details for a token.
    /// Once details have been submitted, they cannot be overwritten.
    /// To re-register the same token with different details (e.g. if the address
    /// has changed), a different token identifier should be used and the
    /// previous token identifier should be deregistered.
    /// If a token is not Ethereum-based, the address will be set to 0x0.
    ///
    /// @param _tokenCode A unique 32-bit token identifier.
    /// @param _tokenAddress The address of the token.
    /// @param _tokenDecimals The decimals to use for the token.
    function registerToken(uint32 _tokenCode, address _tokenAddress, uint8 _tokenDecimals) public onlyOwner;

    /// @notice Sets a token as being deregistered. The details are still stored
    /// to prevent the token from being re-registered with different details.
    ///
    /// @param _tokenCode The unique 32-bit token identifier.
    function deregisterToken(uint32 _tokenCode) external onlyOwner;
}


/// @notice RenExBalances is responsible for holding RenEx trader funds.
contract RenExBalances {
    address public settlementContract;

    /// @notice Restricts a function to only being called by the RenExSettlement
    /// contract.
    modifier onlyRenExSettlementContract() {
        require(msg.sender == address(settlementContract), "not authorized");
        _;
    }

    /// @notice Transfer a token value from one trader to another, transferring
    /// a fee to the RewardVault. Can only be called by the RenExSettlement
    /// contract.
    ///
    /// @param _traderFrom The address of the trader to decrement the balance of.
    /// @param _traderTo The address of the trader to increment the balance of.
    /// @param _token The token&#39;s address.
    /// @param _value The number of tokens to decrement the balance by (in the
    ///        token&#39;s smallest unit).
    /// @param _fee The fee amount to forward on to the RewardVault.
    /// @param _feePayee The recipient of the fee.
    function transferBalanceWithFee(address _traderFrom, address _traderTo, address _token, uint256 _value, uint256 _fee, address _feePayee)
    external onlyRenExSettlementContract;
}


/// @notice A library for calculating and verifying order match details
library SettlementUtils {

    struct OrderDetails {
        uint64 settlementID;
        uint64 tokens;
        uint256 price;
        uint256 volume;
        uint256 minimumVolume;
    }

    /// @notice Calculates the ID of the order.
    /// @param details Order details that are not required for settlement
    ///        execution. They are combined as a single byte array.
    /// @param order The order details required for settlement execution.
    function hashOrder(bytes details, OrderDetails memory order) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                details,
                order.settlementID,
                order.tokens,
                order.price,
                order.volume,
                order.minimumVolume
            )
        );
    }

    /// @notice Verifies that two orders match when considering the tokens,
    /// price, volumes / minimum volumes and settlement IDs. verifyMatchDetails is used
    /// my the DarknodeSlasher to verify challenges. Settlement layers may also
    /// use this function.
    /// @dev When verifying two orders for settlement, you should also:
    ///   1) verify the orders have been confirmed together
    ///   2) verify the orders&#39; traders are distinct
    /// @param _buy The buy order details.
    /// @param _sell The sell order details.
    function verifyMatchDetails(OrderDetails memory _buy, OrderDetails memory _sell) internal pure returns (bool) {

        // Buy and sell tokens should match
        if (!verifyTokens(_buy.tokens, _sell.tokens)) {
            return false;
        }

        // Buy price should be greater than sell price
        if (_buy.price < _sell.price) {
            return false;
        }

        // // Buy volume should be greater than sell minimum volume
        if (_buy.volume < _sell.minimumVolume) {
            return false;
        }

        // Sell volume should be greater than buy minimum volume
        if (_sell.volume < _buy.minimumVolume) {
            return false;
        }

        // Require that the orders were submitted to the same settlement layer
        if (_buy.settlementID != _sell.settlementID) {
            return false;
        }

        return true;
    }

    /// @notice Verifies that two token requirements can be matched and that the
    /// tokens are formatted correctly.
    /// @param _buyTokens The buy token details.
    /// @param _sellToken The sell token details.
    function verifyTokens(uint64 _buyTokens, uint64 _sellToken) internal pure returns (bool) {
        return ((
                uint32(_buyTokens) == uint32(_sellToken >> 32)) && (
                uint32(_sellToken) == uint32(_buyTokens >> 32)) && (
                uint32(_buyTokens >> 32) <= uint32(_buyTokens))
        );
    }
}

/// @notice RenExSettlement implements the Settlement interface. It implements
/// the on-chain settlement for the RenEx settlement layer, and the fee payment
/// for the RenExAtomic settlement layer.
contract RenExSettlement is Ownable {
    using SafeMath for uint256;

    string public VERSION; // Passed in as a constructor parameter.

    // This contract handles the settlements with ID 1 and 2.
    uint32 constant public RENEX_SETTLEMENT_ID = 1;
    uint32 constant public RENEX_ATOMIC_SETTLEMENT_ID = 2;

    // Fees in RenEx are 0.2%. To represent this as integers, it is broken into
    // a numerator and denominator.
    uint256 constant public DARKNODE_FEES_NUMERATOR = 2;
    uint256 constant public DARKNODE_FEES_DENOMINATOR = 1000;

    // Constants used in the price / volume inputs.
    int16 constant private PRICE_OFFSET = 12;
    int16 constant private VOLUME_OFFSET = 12;

    // Constructor parameters, updatable by the owner
    Orderbook public orderbookContract;
    RenExTokens public renExTokensContract;
    RenExBalances public renExBalancesContract;
    address public slasherAddress;
    uint256 public submissionGasPriceLimit;

    enum OrderStatus {None, Submitted, Settled, Slashed}

    struct TokenPair {
        RenExTokens.TokenDetails priorityToken;
        RenExTokens.TokenDetails secondaryToken;
    }

    // A uint256 tuple representing a value and an associated fee
    struct ValueWithFees {
        uint256 value;
        uint256 fees;
    }

    // A uint256 tuple representing a fraction
    struct Fraction {
        uint256 numerator;
        uint256 denominator;
    }

    // We use left and right because the tokens do not always represent the
    // priority and secondary tokens.
    struct SettlementDetails {
        uint256 leftVolume;
        uint256 rightVolume;
        uint256 leftTokenFee;
        uint256 rightTokenFee;
        address leftTokenAddress;
        address rightTokenAddress;
    }

    // Events
    event LogOrderbookUpdated(Orderbook previousOrderbook, Orderbook nextOrderbook);
    event LogRenExTokensUpdated(RenExTokens previousRenExTokens, RenExTokens nextRenExTokens);
    event LogRenExBalancesUpdated(RenExBalances previousRenExBalances, RenExBalances nextRenExBalances);
    event LogSubmissionGasPriceLimitUpdated(uint256 previousSubmissionGasPriceLimit, uint256 nextSubmissionGasPriceLimit);
    event LogSlasherUpdated(address previousSlasher, address nextSlasher);

    // Order Storage
    mapping(bytes32 => SettlementUtils.OrderDetails) public orderDetails;
    mapping(bytes32 => address) public orderSubmitter;
    mapping(bytes32 => OrderStatus) public orderStatus;

    // Match storage (match details are indexed by [buyID][sellID])
    mapping(bytes32 => mapping(bytes32 => uint256)) public matchTimestamp;

    /// @notice Prevents a function from being called with a gas price higher
    /// than the specified limit.
    ///
    /// @param _gasPriceLimit The gas price upper-limit in Wei.
    modifier withGasPriceLimit(uint256 _gasPriceLimit) {
        require(tx.gasprice <= _gasPriceLimit, "gas price too high");
        _;
    }

    /// @notice Restricts a function to only being called by the slasher
    /// address.
    modifier onlySlasher() {
        require(msg.sender == slasherAddress, "unauthorized");
        _;
    }

    /// @notice The contract constructor.
    ///
    /// @param _VERSION A string defining the contract version.
    /// @param _orderbookContract The address of the Orderbook contract.
    /// @param _renExBalancesContract The address of the RenExBalances
    ///        contract.
    /// @param _renExTokensContract The address of the RenExTokens contract.
    constructor(
        string _VERSION,
        Orderbook _orderbookContract,
        RenExTokens _renExTokensContract,
        RenExBalances _renExBalancesContract,
        address _slasherAddress,
        uint256 _submissionGasPriceLimit
    ) public {
        VERSION = _VERSION;
        orderbookContract = _orderbookContract;
        renExTokensContract = _renExTokensContract;
        renExBalancesContract = _renExBalancesContract;
        slasherAddress = _slasherAddress;
        submissionGasPriceLimit = _submissionGasPriceLimit;
    }

    /// @notice The owner of the contract can update the Orderbook address.
    /// @param _newOrderbookContract The address of the new Orderbook contract.
    function updateOrderbook(Orderbook _newOrderbookContract) external onlyOwner {
        emit LogOrderbookUpdated(orderbookContract, _newOrderbookContract);
        orderbookContract = _newOrderbookContract;
    }

    /// @notice The owner of the contract can update the RenExTokens address.
    /// @param _newRenExTokensContract The address of the new RenExTokens
    ///       contract.
    function updateRenExTokens(RenExTokens _newRenExTokensContract) external onlyOwner {
        emit LogRenExTokensUpdated(renExTokensContract, _newRenExTokensContract);
        renExTokensContract = _newRenExTokensContract;
    }
    
    /// @notice The owner of the contract can update the RenExBalances address.
    /// @param _newRenExBalancesContract The address of the new RenExBalances
    ///       contract.
    function updateRenExBalances(RenExBalances _newRenExBalancesContract) external onlyOwner {
        emit LogRenExBalancesUpdated(renExBalancesContract, _newRenExBalancesContract);
        renExBalancesContract = _newRenExBalancesContract;
    }

    /// @notice The owner of the contract can update the order submission gas
    /// price limit.
    /// @param _newSubmissionGasPriceLimit The new gas price limit.
    function updateSubmissionGasPriceLimit(uint256 _newSubmissionGasPriceLimit) external onlyOwner {
        emit LogSubmissionGasPriceLimitUpdated(submissionGasPriceLimit, _newSubmissionGasPriceLimit);
        submissionGasPriceLimit = _newSubmissionGasPriceLimit;
    }

    /// @notice The owner of the contract can update the slasher address.
    /// @param _newSlasherAddress The new slasher address.
    function updateSlasher(address _newSlasherAddress) external onlyOwner {
        emit LogSlasherUpdated(slasherAddress, _newSlasherAddress);
        slasherAddress = _newSlasherAddress;
    }

    /// @notice Stores the details of an order.
    ///
    /// @param _prefix The miscellaneous details of the order required for
    ///        calculating the order id.
    /// @param _settlementID The settlement identifier.
    /// @param _tokens The encoding of the token pair (buy token is encoded as
    ///        the first 32 bytes and sell token is encoded as the last 32
    ///        bytes).
    /// @param _price The price of the order. Interpreted as the cost for 1
    ///        standard unit of the non-priority token, in 1e12 (i.e.
    ///        PRICE_OFFSET) units of the priority token).
    /// @param _volume The volume of the order. Interpreted as the maximum
    ///        number of 1e-12 (i.e. VOLUME_OFFSET) units of the non-priority
    ///        token that can be traded by this order.
    /// @param _minimumVolume The minimum volume the trader is willing to
    ///        accept. Encoded the same as the volume.
    function submitOrder(
        bytes _prefix,
        uint64 _settlementID,
        uint64 _tokens,
        uint256 _price,
        uint256 _volume,
        uint256 _minimumVolume
    ) external withGasPriceLimit(submissionGasPriceLimit) {

        SettlementUtils.OrderDetails memory order = SettlementUtils.OrderDetails({
            settlementID: _settlementID,
            tokens: _tokens,
            price: _price,
            volume: _volume,
            minimumVolume: _minimumVolume
        });
        bytes32 orderID = SettlementUtils.hashOrder(_prefix, order);

        require(orderStatus[orderID] == OrderStatus.None, "order already submitted");
        require(orderbookContract.orderState(orderID) == Orderbook.OrderState.Confirmed, "unconfirmed order");

        orderSubmitter[orderID] = msg.sender;
        orderStatus[orderID] = OrderStatus.Submitted;
        orderDetails[orderID] = order;
    }

    /// @notice Settles two orders that are matched. `submitOrder` must have been
    /// called for each order before this function is called.
    ///
    /// @param _buyID The 32 byte ID of the buy order.
    /// @param _sellID The 32 byte ID of the sell order.
    function settle(bytes32 _buyID, bytes32 _sellID) external {
        require(orderStatus[_buyID] == OrderStatus.Submitted, "invalid buy status");
        require(orderStatus[_sellID] == OrderStatus.Submitted, "invalid sell status");

        // Check the settlement ID (only have to check for one, since
        // `verifyMatchDetails` checks that they are the same)
        require(
            orderDetails[_buyID].settlementID == RENEX_ATOMIC_SETTLEMENT_ID ||
            orderDetails[_buyID].settlementID == RENEX_SETTLEMENT_ID,
            "invalid settlement id"
        );

        // Verify that the two order details are compatible.
        require(SettlementUtils.verifyMatchDetails(orderDetails[_buyID], orderDetails[_sellID]), "incompatible orders");

        // Verify that the two orders have been confirmed to one another.
        require(orderbookContract.orderMatch(_buyID) == _sellID, "unconfirmed orders");

        // Retrieve token details.
        TokenPair memory tokens = getTokenDetails(orderDetails[_buyID].tokens);

        // Require that the tokens have been registered.
        require(tokens.priorityToken.registered, "unregistered priority token");
        require(tokens.secondaryToken.registered, "unregistered secondary token");

        address buyer = orderbookContract.orderTrader(_buyID);
        address seller = orderbookContract.orderTrader(_sellID);

        require(buyer != seller, "orders from same trader");

        execute(_buyID, _sellID, buyer, seller, tokens);

        /* solium-disable-next-line security/no-block-members */
        matchTimestamp[_buyID][_sellID] = now;

        // Store that the orders have been settled.
        orderStatus[_buyID] = OrderStatus.Settled;
        orderStatus[_sellID] = OrderStatus.Settled;
    }

    /// @notice Slashes the bond of a guilty trader. This is called when an
    /// atomic swap is not executed successfully.
    /// To open an atomic order, a trader must have a balance equivalent to
    /// 0.6% of the trade in the Ethereum-based token. 0.2% is always paid in
    /// darknode fees when the order is matched. If the remaining amount is
    /// is slashed, it is distributed as follows:
    ///   1) 0.2% goes to the other trader, covering their fee
    ///   2) 0.2% goes to the slasher address
    /// Only one order in a match can be slashed.
    ///
    /// @param _guiltyOrderID The 32 byte ID of the order of the guilty trader.
    function slash(bytes32 _guiltyOrderID) external onlySlasher {
        require(orderDetails[_guiltyOrderID].settlementID == RENEX_ATOMIC_SETTLEMENT_ID, "slashing non-atomic trade");

        bytes32 innocentOrderID = orderbookContract.orderMatch(_guiltyOrderID);

        require(orderStatus[_guiltyOrderID] == OrderStatus.Settled, "invalid order status");
        require(orderStatus[innocentOrderID] == OrderStatus.Settled, "invalid order status");
        orderStatus[_guiltyOrderID] = OrderStatus.Slashed;

        (bytes32 buyID, bytes32 sellID) = isBuyOrder(_guiltyOrderID) ?
            (_guiltyOrderID, innocentOrderID) : (innocentOrderID, _guiltyOrderID);

        TokenPair memory tokens = getTokenDetails(orderDetails[buyID].tokens);

        SettlementDetails memory settlementDetails = calculateAtomicFees(buyID, sellID, tokens);

        // Transfer the fee amount to the other trader
        renExBalancesContract.transferBalanceWithFee(
            orderbookContract.orderTrader(_guiltyOrderID),
            orderbookContract.orderTrader(innocentOrderID),
            settlementDetails.leftTokenAddress,
            settlementDetails.leftTokenFee,
            0,
            0x0
        );

        // Transfer the fee amount to the slasher
        renExBalancesContract.transferBalanceWithFee(
            orderbookContract.orderTrader(_guiltyOrderID),
            slasherAddress,
            settlementDetails.leftTokenAddress,
            settlementDetails.leftTokenFee,
            0,
            0x0
        );
    }

    /// @notice Retrieves the settlement details of an order.
    /// For atomic swaps, it returns the full volumes, not the settled fees.
    ///
    /// @param _orderID The order to lookup the details of. Can be the ID of a
    ///        buy or a sell order.
    /// @return [
    ///     a boolean representing whether or not the order has been settled,
    ///     a boolean representing whether or not the order is a buy
    ///     the 32-byte order ID of the matched order
    ///     the volume of the priority token,
    ///     the volume of the secondary token,
    ///     the fee paid in the priority token,
    ///     the fee paid in the secondary token,
    ///     the token code of the priority token,
    ///     the token code of the secondary token
    /// ]
    function getMatchDetails(bytes32 _orderID)
    external view returns (
        bool settled,
        bool orderIsBuy,
        bytes32 matchedID,
        uint256 priorityVolume,
        uint256 secondaryVolume,
        uint256 priorityFee,
        uint256 secondaryFee,
        uint32 priorityToken,
        uint32 secondaryToken
    ) {
        matchedID = orderbookContract.orderMatch(_orderID);

        orderIsBuy = isBuyOrder(_orderID);

        (bytes32 buyID, bytes32 sellID) = orderIsBuy ?
            (_orderID, matchedID) : (matchedID, _orderID);

        SettlementDetails memory settlementDetails = calculateSettlementDetails(
            buyID,
            sellID,
            getTokenDetails(orderDetails[buyID].tokens)
        );

        return (
            orderStatus[_orderID] == OrderStatus.Settled || orderStatus[_orderID] == OrderStatus.Slashed,
            orderIsBuy,
            matchedID,
            settlementDetails.leftVolume,
            settlementDetails.rightVolume,
            settlementDetails.leftTokenFee,
            settlementDetails.rightTokenFee,
            uint32(orderDetails[buyID].tokens >> 32),
            uint32(orderDetails[buyID].tokens)
        );
    }

    /// @notice Exposes the hashOrder function for computing a hash of an
    /// order&#39;s details. An order hash is used as its ID. See `submitOrder`
    /// for the parameter descriptions.
    ///
    /// @return The 32-byte hash of the order.
    function hashOrder(
        bytes _prefix,
        uint64 _settlementID,
        uint64 _tokens,
        uint256 _price,
        uint256 _volume,
        uint256 _minimumVolume
    ) external pure returns (bytes32) {
        return SettlementUtils.hashOrder(_prefix, SettlementUtils.OrderDetails({
            settlementID: _settlementID,
            tokens: _tokens,
            price: _price,
            volume: _volume,
            minimumVolume: _minimumVolume
        }));
    }

    /// @notice Called by `settle`, executes the settlement for a RenEx order
    /// or distributes the fees for a RenExAtomic swap.
    ///
    /// @param _buyID The 32 byte ID of the buy order.
    /// @param _sellID The 32 byte ID of the sell order.
    /// @param _buyer The address of the buy trader.
    /// @param _seller The address of the sell trader.
    /// @param _tokens The details of the priority and secondary tokens.
    function execute(
        bytes32 _buyID,
        bytes32 _sellID,
        address _buyer,
        address _seller,
        TokenPair memory _tokens
    ) private {
        // Calculate the fees for atomic swaps, and the settlement details
        // otherwise.
        SettlementDetails memory settlementDetails = (orderDetails[_buyID].settlementID == RENEX_ATOMIC_SETTLEMENT_ID) ?
            settlementDetails = calculateAtomicFees(_buyID, _sellID, _tokens) :
            settlementDetails = calculateSettlementDetails(_buyID, _sellID, _tokens);

        // Transfer priority token value
        renExBalancesContract.transferBalanceWithFee(
            _buyer,
            _seller,
            settlementDetails.leftTokenAddress,
            settlementDetails.leftVolume,
            settlementDetails.leftTokenFee,
            orderSubmitter[_buyID]
        );

        // Transfer secondary token value
        renExBalancesContract.transferBalanceWithFee(
            _seller,
            _buyer,
            settlementDetails.rightTokenAddress,
            settlementDetails.rightVolume,
            settlementDetails.rightTokenFee,
            orderSubmitter[_sellID]
        );
    }

    /// @notice Calculates the details required to execute two matched orders.
    ///
    /// @param _buyID The 32 byte ID of the buy order.
    /// @param _sellID The 32 byte ID of the sell order.
    /// @param _tokens The details of the priority and secondary tokens.
    /// @return A struct containing the settlement details.
    function calculateSettlementDetails(
        bytes32 _buyID,
        bytes32 _sellID,
        TokenPair memory _tokens
    ) private view returns (SettlementDetails memory) {

        // Calculate the mid-price (using numerator and denominator to not loose
        // precision).
        Fraction memory midPrice = Fraction(orderDetails[_buyID].price + orderDetails[_sellID].price, 2);

        // Calculate the lower of the two max volumes of each trader
        uint256 commonVolume = Math.min256(orderDetails[_buyID].volume, orderDetails[_sellID].volume);

        uint256 priorityTokenVolume = joinFraction(
            commonVolume.mul(midPrice.numerator),
            midPrice.denominator,
            int16(_tokens.priorityToken.decimals) - PRICE_OFFSET - VOLUME_OFFSET
        );
        uint256 secondaryTokenVolume = joinFraction(
            commonVolume,
            1,
            int16(_tokens.secondaryToken.decimals) - VOLUME_OFFSET
        );

        // Calculate darknode fees
        ValueWithFees memory priorityVwF = subtractDarknodeFee(priorityTokenVolume);
        ValueWithFees memory secondaryVwF = subtractDarknodeFee(secondaryTokenVolume);

        return SettlementDetails({
            leftVolume: priorityVwF.value,
            rightVolume: secondaryVwF.value,
            leftTokenFee: priorityVwF.fees,
            rightTokenFee: secondaryVwF.fees,
            leftTokenAddress: _tokens.priorityToken.addr,
            rightTokenAddress: _tokens.secondaryToken.addr
        });
    }

    /// @notice Calculates the fees to be transferred for an atomic swap.
    ///
    /// @param _buyID The 32 byte ID of the buy order.
    /// @param _sellID The 32 byte ID of the sell order.
    /// @param _tokens The details of the priority and secondary tokens.
    /// @return A struct containing the fee details.
    function calculateAtomicFees(
        bytes32 _buyID,
        bytes32 _sellID,
        TokenPair memory _tokens
    ) private view returns (SettlementDetails memory) {

        // Calculate the mid-price (using numerator and denominator to not loose
        // precision).
        Fraction memory midPrice = Fraction(orderDetails[_buyID].price + orderDetails[_sellID].price, 2);

        // Calculate the lower of the two max volumes of each trader
        uint256 commonVolume = Math.min256(orderDetails[_buyID].volume, orderDetails[_sellID].volume);

        if (isEthereumBased(_tokens.secondaryToken.addr)) {
            uint256 secondaryTokenVolume = joinFraction(
                commonVolume,
                1,
                int16(_tokens.secondaryToken.decimals) - VOLUME_OFFSET
            );

            // Calculate darknode fees
            ValueWithFees memory secondaryVwF = subtractDarknodeFee(secondaryTokenVolume);

            return SettlementDetails({
                leftVolume: 0,
                rightVolume: 0,
                leftTokenFee: secondaryVwF.fees,
                rightTokenFee: secondaryVwF.fees,
                leftTokenAddress: _tokens.secondaryToken.addr,
                rightTokenAddress: _tokens.secondaryToken.addr
            });
        } else if (isEthereumBased(_tokens.priorityToken.addr)) {
            uint256 priorityTokenVolume = joinFraction(
                commonVolume.mul(midPrice.numerator),
                midPrice.denominator,
                int16(_tokens.priorityToken.decimals) - PRICE_OFFSET - VOLUME_OFFSET
            );

            // Calculate darknode fees
            ValueWithFees memory priorityVwF = subtractDarknodeFee(priorityTokenVolume);

            return SettlementDetails({
                leftVolume: 0,
                rightVolume: 0,
                leftTokenFee: priorityVwF.fees,
                rightTokenFee: priorityVwF.fees,
                leftTokenAddress: _tokens.priorityToken.addr,
                rightTokenAddress: _tokens.priorityToken.addr
            });
        } else {
            // Currently, at least one token must be Ethereum-based.
            // This will be implemented in the future.
            revert("non-eth atomic swaps are not supported");
        }
    }

    /// @notice Order parity is set by the order tokens are listed. This returns
    /// whether an order is a buy or a sell.
    /// @return true if _orderID is a buy order.
    function isBuyOrder(bytes32 _orderID) private view returns (bool) {
        uint64 tokens = orderDetails[_orderID].tokens;
        uint32 firstToken = uint32(tokens >> 32);
        uint32 secondaryToken = uint32(tokens);
        return (firstToken < secondaryToken);
    }

    /// @return (value - fee, fee) where fee is 0.2% of value
    function subtractDarknodeFee(uint256 _value) private pure returns (ValueWithFees memory) {
        uint256 newValue = (_value * (DARKNODE_FEES_DENOMINATOR - DARKNODE_FEES_NUMERATOR)) / DARKNODE_FEES_DENOMINATOR;
        return ValueWithFees(newValue, _value - newValue);
    }

    /// @notice Gets the order details of the priority and secondary token from
    /// the RenExTokens contract and returns them as a single struct.
    ///
    /// @param _tokens The 64-bit combined token identifiers.
    /// @return A TokenPair struct containing two TokenDetails structs.
    function getTokenDetails(uint64 _tokens) private view returns (TokenPair memory) {
        (
            address priorityAddress,
            uint8 priorityDecimals,
            bool priorityRegistered
        ) = renExTokensContract.tokens(uint32(_tokens >> 32));

        (
            address secondaryAddress,
            uint8 secondaryDecimals,
            bool secondaryRegistered
        ) = renExTokensContract.tokens(uint32(_tokens));

        return TokenPair({
            priorityToken: RenExTokens.TokenDetails(priorityAddress, priorityDecimals, priorityRegistered),
            secondaryToken: RenExTokens.TokenDetails(secondaryAddress, secondaryDecimals, secondaryRegistered)
        });
    }

    /// @return true if _tokenAddress is 0x0, representing a token that is not
    /// on Ethereum
    function isEthereumBased(address _tokenAddress) private pure returns (bool) {
        return (_tokenAddress != address(0x0));
    }

    /// @notice Computes (_numerator / _denominator) * 10 ** _scale
    function joinFraction(uint256 _numerator, uint256 _denominator, int16 _scale) private pure returns (uint256) {
        if (_scale >= 0) {
            // Check that (10**_scale) doesn&#39;t overflow
            assert(_scale <= 77); // log10(2**256) = 77.06
            return _numerator.mul(10 ** uint256(_scale)) / _denominator;
        } else {
            /// @dev If _scale is less than -77, 10**-_scale would overflow.
            // For now, -_scale > -24 (when a token has 0 decimals and
            // VOLUME_OFFSET and PRICE_OFFSET are each 12). It is unlikely these
            // will be increased to add to more than 77.
            // assert((-_scale) <= 77); // log10(2**256) = 77.06
            return (_numerator / _denominator) / 10 ** uint256(-_scale);
        }
    }
}