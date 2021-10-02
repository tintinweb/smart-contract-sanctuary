/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

// SPDX-License-Identifier: BSD-3-Clause


pragma solidity ^0.8.0;


/// @author Limitr
/// @title factory contract interface for a Limitr factory
interface ILimitrDeployer {
    function createMarket(
        address factory,
        address baseToken,
        address counterToken
    ) external returns (address);
}





pragma solidity ^0.8.0;


struct DLL {
    mapping(uint256 => uint256) _next;
    mapping(uint256 => uint256) _prev;
}


library DoubleLinkedList {

    function first(DLL storage dll) internal view returns (uint256) {
        return dll._next[0];
    }

    function last(DLL storage dll) internal view returns (uint256) {
        return dll._prev[0];
    }

    function next(DLL storage dll, uint256 current) internal view returns (uint256) {
        return dll._next[current];
    }

    function previous(DLL storage dll, uint256 current) internal view returns (uint256) {
        return dll._prev[current];
    }

    function insertBeginning(DLL storage dll, uint256 value) internal {
        insertAfter(dll, value, 0);
    }

    function insertEnd(DLL storage dll, uint256 value) internal {
        insertBefore(dll, value, 0);
    }

    function insertAfter(DLL storage dll, uint256 value, uint256 _prev) internal {
        uint256 _next = dll._next[_prev];
        dll._next[_prev] = value;
        dll._prev[_next] = value;
        dll._next[value] = _next;
        dll._prev[value] = _prev;
    }

    function insertBefore(DLL storage dll, uint256 value, uint256 _next) internal {
        uint256 _prev = dll._prev[_next];
        dll._next[_prev] = value;
        dll._prev[_next] = value;
        dll._next[value] = _next;
        dll._prev[value] = _prev;
    }

    function remove(DLL storage dll, uint256 value) internal {
        uint256 p = dll._prev[value];
        uint256 n = dll._next[value];
        dll._prev[n] = p;
        dll._next[p] = n;
        dll._prev[value] = 0;
        dll._next[value] = 0;
    }
}






pragma solidity ^0.8.0;


struct SDLL {
    mapping(uint256 => uint256) _next;
    mapping(uint256 => uint256) _prev;
}


library SortedDoubleLinkedList {

    function first(SDLL storage s) internal view returns (uint256) {
        return s._next[0];
    }

    function last(SDLL storage s) internal view returns (uint256) {
        return s._prev[0];
    }

    function next(SDLL storage s, uint256 current) internal view returns (uint256) {
        return s._next[current];
    }

    function previous(SDLL storage s, uint256 current) internal view returns (uint256) {
        return s._prev[current];
    }

    function insertWithPointer(
        SDLL storage s,
        uint256 value,
        uint256 pointer
    )
        internal returns (bool)
    {
        uint256 n = pointer;
        while (true) {
            n = s._next[n];
            if (n == 0 || n > value) { break; }
        }
        uint256 p = s._prev[n];
        s._next[p] = value;
        s._prev[n] = value;
        s._next[value] = n;
        s._prev[value] = p;
        return true;
    }

    function insert(SDLL storage s, uint256 value) internal returns (bool) {
        return insertWithPointer(s, value, 0);
    }

    function remove(SDLL storage s, uint256 value) internal {
        uint256 p = s._prev[value];
        uint256 n = s._next[value];
        s._prev[n] = p;
        s._next[p] = n;
        s._prev[value] = 0;
        s._next[value] = 0;
    }
}






pragma solidity ^0.8.0;


struct Trade {
    uint256 base;
    uint256 counter;
    uint256 availableCounter;
}


library TradeLib {
    function update(Trade memory _trade, uint256 base, uint256 counter) internal pure {
        _trade.base += base;
        _trade.counter += counter;
        _trade.availableCounter -= counter;
    }
}




pragma solidity ^0.8.0;


/// @author Limitr
/// @title Trade market contract interface for Limitr
interface ILimitrMarketTokenToken {
    // events

    /// @notice NewFeePercentage is emitted when a new fee receiver is set
    /// @param oldFeePercentage The old fee percentage
    /// @param newFeePercentage The new fee percentage
    event NewFeePercentage(uint256 oldFeePercentage, uint256 newFeePercentage);

    /// @notice NewOrder is emitted when a new order is created
    /// @param id The id of the order
    /// @param trader The trader address
    /// @param price The price of the order
    /// @param amount The amount of baseToken deposited
    event NewOrder(
        uint256 indexed id,
        address indexed trader,
        uint256 indexed price,
        uint256 amount
    );

    /// @notice OrderCanceled is emitted when a trader cancels an order
    /// @param id The order id
    /// @param amount The amount canceled
    event OrderCanceled(uint256 indexed id, uint256 amount);

    /// @notice OrderTaken is emitted when an order is taken from the market
    /// @param id The order id
    /// @param amount The amount of the base token traded
    /// @param price The trade price
    /// @param receiver The receiver of the base token
    event OrderTaken(
        uint256 indexed id,
        uint256 amount,
        uint256 price,
        address receiver
    );

    /// @notice FeeReceived is emitted when the fee is collected
    /// @param from The address paying the fee
    /// @param amount The amount paid
    event FeeReceived(address indexed from, uint256 amount);


    // fee functions

    /// @notice Withdraw market profits (counter token)
    /// @param to The receiver address
    /// @param amount The amount to withdraw. Use 0 for all
    function withdrawFees(address to, uint256 amount) external;

    /// @return The fee percentage represented a value between 0 and 1
    ///         multiplied by 10^18
    function feePercentage() external view returns (uint256);

    /// @notice Set a new fee (must be smaller than the current,
    ///         for the feeCollectorSetter only)
    /// @param newFeePercentage The new fee in the format described
    ///        in feePercentage
    function setFeePercentage(uint256 newFeePercentage) external;


    // emergency withdraw

    /// @notice Emergency withdraw a token or ETH
    /// @param token The token address, 0 for ETH
    /// @param to The receiver address
    /// @param amount The amount to transfer
    function emergencyWithdraw(address token, address to, uint256 amount) external;

    // factory and token addresses

    /// @return The factory address
    function factory() external view returns (address);

    /// @return The address for the base token
    function baseToken() external view returns (address);

    /// @return The address for the counter token
    function counterToken() external view returns (address);


    // price listing functions

    /// @return The first price on the order book
    function firstPrice() external view returns (uint256);

    /// @return The last price on the order book
    function lastPrice() external view returns (uint256);

    /// @return The previous price to the pointer
    /// @param current The current price
    function previousPrice(uint256 current) external view returns (uint256);

    /// @return The next price to the current
    /// @param current The current price
    function nextPrice(uint256 current) external view returns (uint256);

    /// @return N prices after current
    /// @param current The current price
    /// @param n The number of prices to return
    function prices(uint256 current, uint256 n) external view returns (uint256[] memory);


    // orders functions

    /// @return The ID of the first order
    function firstOrder() external view returns (uint256);

    /// @return The ID of the last order
    function lastOrder() external view returns (uint256);

    /// @return The ID of the previous order
    /// @param pointer Pointer to the current order
    function previousOrder(uint256 pointer) external view returns (uint256);

    /// @return The ID of the next order
    /// @param pointer Pointer to the current order
    function nextOrder(uint256 pointer) external view returns (uint256);

    /// @notice Returns the order data
    /// @param orderID ID of the order
    /// @return price The price for the order
    /// @return amount The amount of the base token for sale
    /// @return trader The owner of the order
    function order(uint256 orderID) external view returns (
        uint256 price,
        uint256 amount,
        address trader
    );

    /// @notice Returns n order IDs from the current
    /// @param current The current ID
    /// @param n The number of IDs to return
    function orders(uint256 current, uint256 n) external view returns (uint256[] memory);

    /// @return The last assigned order ID
    function lastID() external view returns (uint256);


    // trader order functions

    /// @return The ID of the first order of the trader
    /// @param trader The trader
    function firstTraderOrder(address trader) external view returns (uint256);

    /// @return The ID of the last order of the trader
    /// @param trader The trader
    function lastTraderOrder(address trader) external view returns (uint256);

    /// @return The ID of the previous order of the trader
    /// @param trader The trader
    /// @param pointer Pointer to a trade
    function previousTraderOrder(address trader, uint256 pointer) external view returns (uint256);

    /// @return The ID of the next order of the trader
    /// @param trader The trader
    /// @param pointer Pointer to a trade
    function nextTraderOrder(address trader, uint256 pointer) external view returns (uint256);

    /// @notice Returns n trader order IDs from the current
    /// @param trader The trader
    /// @param current The current ID
    /// @param n The number of IDs to return
    function traderOrders(address trader, uint256 current, uint256 n) external view returns (uint256[] memory);


    // fee calculation functions

    /// @return The amount available after collecting the fee
    /// @param amount The total amount
    function afterFee(uint256 amount) external view returns (uint256);

    /// @return The amount corresponding to the fee from a given amount
    /// @param amount The traded amount
    function feeOf(uint256 amount) external view returns (uint256);

    /// @return The amount to collect as fee for the provided amount
    /// @param amount The amount traded
    function feeFor(uint256 amount) external view returns (uint256);


    // trade amounts calculation functions

    /// @return The cost of baseAmount of the base token at the provided price
    /// @param baseAmount The amount of the base token
    /// @param price The price in counter token
    function costOf(uint256 baseAmount, uint256 price) external view returns (uint256);

    /// @return The amount of base token than can be purchased with amount at price
    /// @param counterAmount The amount of the counter token
    /// @param price The price in counter token
    function returnOf(uint256 counterAmount, uint256 price) external view returns (uint256);

    /// @notice Return The input amount of counterToken and output amount of the
    ///         baseToken, up to maxBaseOut
    /// @param maxBaseOut The maximum output amount of baseToken
    function amountIn(uint256 maxBaseOut) external view returns (uint256, uint256);

    /// @notice Returns the input amount of counterToken and the output amount
    ///         of baseToken up to the provided maxCounterIn
    /// @param maxCounterIn The input amount of counterToken
    function amountOut(uint256 maxCounterIn) external view returns (uint256, uint256);


    // order creation functions

    /// @notice Creates a new order using 0 as a pointer
    /// @param price The order price in counterToken
    /// @param amount The baseToken amount to trade
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @return The order ID
    function newOrder(
        uint256 price,
        uint256 amount,
        address trader,
        uint256 deadline
    ) external returns (uint256);

    /// @notice Creates a new order using the provided pointer
    /// @param price The order price in counterToken
    /// @param amount The baseToken amount to trade
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @param pointer The start pointer
    /// @return The order ID
    function newOrderWithPointer(
        uint256 price,
        uint256 amount,
        address trader,
        uint256 deadline,
        uint256 pointer
    ) external returns (uint256);

    /// @notice Creates a new order using one of the provided pointers
    /// @param price The order price in counterToken
    /// @param amount The baseToken amount to trade
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @param pointers The potential pointers
    /// @return The order ID
    function newOrderWithPointers(
        uint256 price,
        uint256 amount,
        address trader,
        uint256 deadline,
        uint256[] memory pointers
    ) external returns (uint256);


    // order cancellation functions

    /// @notice Cancel an order
    /// @param orderID The order ID
    /// @param amount The amount to cancel. 0 cancels the total amount
    /// @param deadline Validity deadline
    function cancelOrder(uint256 orderID, uint256 amount, uint256 deadline) external;


    // trading functions

    /// @notice Executes a trade at a particular price or below, returns the amount spent
    ///         and the amount received
    /// @param maxPrice The price of the trade
    /// @param maxCounterIn The maximum amount of the counter token to spend
    /// @param receiver The receiver of the baseToken
    /// @param deadline Validity deadline
    /// @return cost The amount of counter token spent
    /// @return received The amount of base token received
    function tradeAtMaxPrice(
        uint256 maxPrice,
        uint256 maxCounterIn,
        address receiver,
        uint256 deadline
    ) external returns (uint256 cost, uint256 received);

    /// @notice Executes a trade at a maximum average price
    /// @param maxAveragePrice, The maximum average price
    /// @param maxCounterIn The maximum amount of the counter token to spend
    /// @param receiver The receiver of the baseToken
    /// @param deadline Validity deadline
    /// @return cost The amount of counter token spent
    /// @return received The amount of base token received
    function tradeAtAveragePrice(
        uint256 maxAveragePrice,
        uint256 maxCounterIn,
        address receiver,
        uint256 deadline
    ) external returns (uint256 cost, uint256 received);
}




pragma solidity ^0.8.0;


/// @author Limitr
/// @title factory contract interface for the Limitr main factory
interface ILimitrFactory {
    /// @notice NewFeeCollectorSetter is emitted when a new fee collector setter is set
    /// @param oldFeeCollectorSetter The old fee collector setter
    /// @param newFeeCollectorSetter The new fee collector setter
    event NewFeeCollectorSetter(address indexed oldFeeCollectorSetter, address indexed newFeeCollectorSetter);

    /// @notice NewFeeCollector is emitted when a new fee collector is set
    /// @param oldFeeCollector The old fee collector
    /// @param newFeeCollector The new fee collector
    event NewFeeCollector(address indexed oldFeeCollector, address indexed newFeeCollector);

    /// @notice MarketCreated is emitted when a new market is created
    /// @param baseToken The token to exchange
    /// @param counterToken The desired token
    event MarketCreated(address indexed baseToken, address indexed counterToken);


    /// @notice The address for WETH
    function weth() external view returns (address);

    /// @return The fee collector
    function feeCollector() external view returns (address);

    /// @return The fee collector setter
    function feeCollectorSetter() external view returns (address);

    /// @notice Set the fee collector (for the feeCollectorSetter only)
    /// @param newFeeCollector The new fee collector
    function setFeeCollector(address newFeeCollector) external;

    /// @notice Set the fee collector setter (for the feeCollectorSetter only)
    /// @param newFeeCollectorSetter The new fee collector setter
    function setFeeCollectorSetter(address newFeeCollectorSetter) external;

    /// @return The number of available markets
    function marketsCount() external view returns (uint256);

    /// @return The market at index idx
    /// @param idx The market index
    function market(uint256 idx) external view returns (address);

    /// @return The address for the market to trade baseToken for counterToken, may be 0
    /// @param baseToken The token owned by the trader
    /// @param counterToken The token desired by the trader
    function getMarket(address baseToken, address counterToken) external view returns (address);

    /// @return The address for the market with the provided hash
    /// @param hash The market hash
    function getMarketByHash(bytes32 hash) external view returns (address);

    /// @notice Create a new market
    /// @param baseToken The token owned by the trader
    /// @param counterToken The token desired by the trader
    /// @return The market address
    function createMarket(address baseToken, address counterToken) external returns (address);

    /// @notice Calculate the hash for a market
    /// @param baseToken The token owned by the trader
    /// @param counterToken The token desired by the trader
    /// @return The market hash
    function marketHash(address baseToken, address counterToken) external pure returns (bytes32);

    /// @notice Returns the addresses of the tokens with markets with baseToken as base
    /// @param baseToken The base token
    /// @return An array of counter token addresses
    function withBase(address baseToken) external view returns (address[] memory);

    /// @notice Returns the addresses of the tokens with markets with counterToken as counter
    /// @param counterToken The counter token
    /// @return An array of base token addresses
    function withCounter(address counterToken) external view returns (address[] memory);
}





pragma solidity ^0.8.0;


/// @author Limitr
/// @title ERC165 interface needed for the ERC721 implementation
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}





pragma solidity ^0.8.0;




/// @author Limitr
/// @title ERC721 interface for the Limit market
interface IERC721 is IERC165 {
    // events

    /// @notice Transfer is emitted when an order is transferred to a new owner
    /// @param from The order owner
    /// @param to The new order owner
    /// @param tokenId The token/order ID transferred
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// @notice Approval is emitted when the owner approves approved to transfer tokenId
    /// @param owner The token/order owner
    /// @param approved The address approved to transfer the token/order
    /// @param tokenId the token/order ID
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /// @notice ApprovalForAll is emitted when the owner approves operator sets a new approval flag (true/false) for all tokens/orders
    /// @param owner The tokens/orders owner
    /// @param operator The operator address
    /// @param approved The approval status for all tokens/orders
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @param owner The tokens/orders owner
    /// @return balance The number of tokens/orders owned by owner
    function balanceOf(address owner) external view returns (uint256 balance);

    /// @notice Returns the owner of a token/order. The ID must be valid
    /// @param tokenId The token/order ID
    /// @return owner The owner of a token/order. The ID must be valid
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /// @notice Approves an account to transfer the token/order with the given ID.
    ///         The token/order must exists
    /// @param to The address of the account to approve
    /// @param tokenId the token/order
    function approve(address to, uint256 tokenId) external;

    /// @notice Returns the address approved to transfer the token/order with the given ID
    ///         The token/order must exists
    /// @param tokenId the token/order
    /// @return operator The address approved to transfer the token/order with the given ID
    function getApproved(uint256 tokenId) external view returns (address operator);

    /// @notice Approves or removes the operator for the caller tokens/orders
    /// @param operator The operator to be approved/removed
    /// @param _approved Set true to approve, false to remove
    function setApprovalForAll(address operator, bool _approved) external;

    /// @notice Returns if the operator is allowed to manage all tokens/orders of owner
    /// @param owner The owner of the tokens/orders
    /// @param operator The operator
    /// @return If the operator is allowed to manage all tokens/orders of owner
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @notice Transfers the ownership of the token/order. Can be called by the owner
    ///         or approved operators
    /// @param from The token/order owner
    /// @param to The new owner
    /// @param tokenId The token/order ID to transfer
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /// @notice Safely transfers the token/order. It checks contract recipients are aware
    ///         of the ERC721 protocol to prevent tokens from being forever locked.
    /// @param from The token/order owner
    /// @param to the new owner
    /// @param tokenId The token/order ID to transfer
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /// @notice Safely transfers the token/order. It checks contract recipients are aware
    ///         of the ERC721 protocol to prevent tokens from being forever locked.
    /// @param from The token/order owner
    /// @param to the new owner
    /// @param tokenId The token/order ID to transfer
    /// @param data The data to be passed to the onERC721Received() call
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}





pragma solidity ^0.8.0;


/// @author Limitr
/// @title ERC20 token interface
interface IERC20 {

    /// @notice Approval is emitted when a token approval occurs
    /// @param owner The address that approved an allowance
    /// @param spender The address of the approved spender
    /// @param value The amount approved
    event Approval(address indexed owner, address indexed spender, uint value);

    /// @notice Transfer is emitted when a transfer occurs
    /// @param from The address that owned the tokens
    /// @param to The address of the new owner
    /// @param value The amount transferred
    event Transfer(address indexed from, address indexed to, uint value);

    /// @return Token name
    function name() external view returns (string memory);

    /// @return Token symbol
    function symbol() external view returns (string memory);

    /// @return Token decimals
    function decimals() external view returns (uint8);

    /// @return Total token supply
    function totalSupply() external view returns (uint);

    /// @param owner The address to query
    /// @return owner balance
    function balanceOf(address owner) external view returns (uint);

    /// @param owner The owner ot the tokens
    /// @param spender The approved spender of the tokens
    /// @return Allowed balance for spender
    function allowance(address owner, address spender) external view returns (uint);

    /// @notice Approves the provided amount to the provided spender address
    /// @param spender The spender address
    /// @param amount The amount to approve
    /// @return true on success
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers tokens to the provided address
    /// @param to The new owner address
    /// @param amount The amount to transfer
    /// @return true on success
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Transfers tokens from an approved address to the provided address
    /// @param from The tokens owner address
    /// @param to The new owner address
    /// @param amount The amount to transfer
    /// @return true on success
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}




pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}





pragma solidity ^0.8.0;




/// @author Limitr
/// @title Trade market contract for Limitr
contract LimitrMarketTokenToken is ILimitrMarketTokenToken, IERC721 {

    using DoubleLinkedList for DLL;

    using SortedDoubleLinkedList for SDLL;

    using TradeLib for Trade;


    /// @dev Contract constructor
    constructor(address _factory, address _baseToken, address _counterToken) {
        require(_baseToken != _counterToken, 'base and counter tokens are the same');
        require(_baseToken != address(0), 'zero address not allowed');
        require(_counterToken != address(0), 'zero address not allowed');
        require(_factory != address(0), 'zero address not allowed');
        baseToken = _baseToken;
        counterToken = _counterToken;
        factory = _factory;
        _oneBaseToken = 10**IERC20(_baseToken).decimals();
        feePercentage = 10**15;
    }


    /// @dev Order data
    struct Order {
        uint256 price;
        uint256 amount;
        address trader;
    }


    // emergency withdraw

    /// @notice Emergency withdraw a token or ETH
    /// @param token The token address, 0 for ETH
    /// @param to The receiver address
    /// @param amount The amount to transfer
    function emergencyWithdraw(address token, address to, uint256 amount)
        external override
        onlyFeeCollector
    {
        if (token == address(0)) {
            payable(to).transfer(amount);
            return;
        } else if (token == baseToken) {
            require(
                IERC20(token).balanceOf(address(this)) - amount >= _expectedBaseBalance,
                'can''t withdraw amount'
            );
        } else if (token == counterToken) {
            require(
                IERC20(token).balanceOf(address(this)) - amount >= _expectedCounterBalance,
                'can''t withdraw amount'
            );
        }
        _tokenTransfer(token, to, amount);
    }


    // fee functions

    /// @notice Withdraw market profits (counter token)
    /// @param to The receiver address, 0 for msg.sender
    /// @param amount The amount to withdraw. Use 0 for all
    function withdrawFees(address to, uint256 amount)
        public override
        onlyFeeCollector
    {
        uint256 bal = IERC20(counterToken).balanceOf(address(this));
        uint256 _amount = amount != 0 ? amount : bal;
        require(_amount <= bal, 'not enough available fees');
        address _to = to != address(0) ? to : msg.sender;
        _withdrawCounterToken(_to, _amount);
    }

    /// @return The fee percentage represented a value between 0 and 1
    ///         multiplied by 10^18. Initially set to 0.10 %
    uint256 public override feePercentage;

    /// @notice Set a new fee (must be smaller than the current,
    ///         for the feeCollectorSetter only). Emits a NewFeePercentage
    /// @param newFeePercentage The new fee in the format described
    ///        in feePercentage
    function setFeePercentage(uint256 newFeePercentage)
        external override
        onlyFeeCollectorSetter
    {
        require(newFeePercentage < feePercentage, 'Can only set a smaller fee');
        uint256 oldPercentage = feePercentage;
        feePercentage = newFeePercentage;
        emit NewFeePercentage(oldPercentage, newFeePercentage);
    }


    // factory and token addresses

    /// @return The factory address
    address public immutable override factory;

    /// @return The address for the base token
    address public immutable override baseToken;

    /// @return The address for the counter token
    address public immutable override counterToken;


    // price listing functions

    /// @return The first price on the order book
    function firstPrice() public view override returns (uint256) {
        return _prices.first();
    }

    /// @return The last price on the order book
    function lastPrice() public view override returns (uint256) {
        return _prices.last();
    }

    /// @return The previous price to the current
    function previousPrice(uint256 current) public view override returns (uint256) {
        return _prices.previous(current);
    }

    /// @return The next price to the current
    function nextPrice(uint256 current) public view override returns (uint256) {
        return _prices.next(current);
    }

    /// @return N prices after current
    /// @param current The current price
    /// @param n The number of prices to return
    function prices(uint256 current, uint256 n) external view override returns (uint256[] memory) {
        uint256 c = current;
        uint256[] memory r = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            c = nextPrice(c);
            if (c == 0) { break; }
            r[i] = c;
        }
        return r;
    }


    // orders listing functions


    /// @return The ID of the first order
    function firstOrder() public view override returns (uint256) {
        return _orders.first();
    }

    /// @return The ID of the last order
    function lastOrder() public view override returns (uint256) {
        return _orders.last();
    }

    /// @return The ID of the previous order
    function previousOrder(uint256 currentID) public view override returns (uint256) {
        return _orders.previous(currentID);
    }

    /// @return The ID of the next order
    function nextOrder(uint256 currentID) public view override returns (uint256) {
        return _orders.next(currentID);
    }

    /// @notice Returns n order IDs from the current
    /// @param current The current ID
    /// @param n The number of IDs to return
    function orders(uint256 current, uint256 n) external view override returns (uint256[] memory) {
        uint256 c = current;
        uint256[] memory r = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            c = nextOrder(c);
            if (c == 0) { break; }
            r[i] = c;
        }
        return r;
    }

    /// @notice Returns the order data
    mapping(uint256 => Order) public override order;

    /// @return The last assigned order ID
    uint256 public override lastID;


    // trader order listing functions

    /// @return The ID of the first order of the trader
    function firstTraderOrder(address trader) public view override returns (uint256) {
        return _tradersOrders[trader].first();
    }

    /// @return The ID of the last order of the trader
    function lastTraderOrder(address trader) public view override returns (uint256) {
        return _tradersOrders[trader].last();
    }

    /// @return The ID of the previous order of the trader
    function nextTraderOrder(address trader, uint256 currentID) public view override returns (uint256) {
        return _tradersOrders[trader].next(currentID);
    }

    /// @return The ID of the next order of the trader
    function previousTraderOrder(address trader, uint256 currentID) public view override returns (uint256) {
        return _tradersOrders[trader].previous(currentID);
    }

    /// @notice Returns n trader order IDs from the current
    /// @param trader The trader
    /// @param current The current ID
    /// @param n The number of IDs to return
    function traderOrders(
        address trader,
        uint256 current,
        uint256 n
    )
        external view override
        returns (uint256[] memory)
    {
        uint256 c = current;
        uint256[] memory r = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            c = nextTraderOrder(trader, c);
            if (c == 0) { break; }
            r[i] = c;
        }
        return r;
    }


    // fee calculation functions

    /// @return The amount corresponding to the fee for a given amount
    /// @param amount The traded amount
    function feeOf(uint256 amount) public view override returns (uint256) {
        if (feePercentage == 0 || amount == 0) { return 0; }
        return amount * feePercentage / 10**18;
    }

    /// @return The amount to collect as fee from the provided amount
    /// @param amount The amount traded
    function feeFor(uint256 amount) public view override returns (uint256) {
        if (feePercentage == 0 || amount == 0) { return 0; }
        return amount * feePercentage / (10**18 - feePercentage);
    }

    /// @return The amount available after collecting the fee
    /// @param amount The total amount
    function afterFee(uint256 amount) public view override returns (uint256) {
        return amount - feeOf(amount);
    }


    // trade amounts calculation functions

    /// @return The cost of baseAmount of the base token at the provided price
    /// @param baseAmount The amount of the base token
    /// @param price The price in counter token
    function costOf(uint256 baseAmount, uint256 price) public view override returns (uint256) {
        if (price == 0 || baseAmount == 0) { return 0; }
        return price * baseAmount / _oneBaseToken;
    }

    /// @return The amount of base token than can be purchased with amount at price
    /// @param amount The amount of the counter token
    /// @param price The price in counter token
    function returnOf(uint256 amount, uint256 price) public view override returns (uint256) {
        if (price == 0 || amount == 0) { return 0; }
        return _oneBaseToken * amount / price;
    }

    /// @notice Return The input amount of counterToken and output amount of the
    ///         baseToken, up to maxBaseOut
    /// @param maxBaseOut The maximum output amount of baseToken
    function amountIn(uint256 maxBaseOut) public view override returns (uint256, uint256) {
        uint256 remBase = maxBaseOut;
        uint256 counterIn;
        uint256 currentOrder;
        while (remBase > 0) {
            currentOrder = _orders.next(currentOrder);
            Order memory _order = order[currentOrder];
            if (_order.trader == address(0)) { break; }
            uint256 v = _order.amount <= remBase ? _order.amount : remBase;
            remBase -= v;
            counterIn += costOf(v, _order.price);
        }
        return (counterIn, maxBaseOut - remBase);
    }

    /// @notice Returns the input amount of counterToken and the output amount
    ///         of baseToken up to the provided maxCounterIn
    /// @param maxCounterIn The input amount of counterToken
    function amountOut(uint256 maxCounterIn) public view override returns (uint256, uint256) {
        uint256 currentOrder;
        uint256 remCounter = maxCounterIn;
        uint256 baseOut;
        while (remCounter > 0) {
            currentOrder = _orders.next(currentOrder);
            Order memory _order = order[currentOrder];
            if (_order.trader == address(0)) { break; }
            uint256 maxBase = returnOf(remCounter, _order.price);
            if (maxBase == 0) { break; }
            uint256 v = maxBase <= _order.amount ? maxBase : _order.amount;
            baseOut += v;
            remCounter -= costOf(v, _order.price);
        }
        return (maxCounterIn - remCounter, baseOut);
    }


    // order creation functions

    /// @notice Creates a new order using the provided pointer
    /// @param price The order price in counterToken
    /// @param amount The baseToken amount to trade
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @param pointer The start pointer
    /// @return The order ID
    function newOrderWithPointer(
        uint256 price,
        uint256 amount,
        address trader,
        uint256 deadline,
        uint256 pointer
    )
    public override
    returns (uint256)
    {
        (uint256 orderID, bool created) = _newOrderWithPointer(
            price,
            amount,
            trader,
            deadline,
            pointer
        );
        require(created, 'can''t create new order');
        return orderID;
    }

    /// @notice Creates a new order using 0 as a pointer
    /// @param price The order price in counterToken
    /// @param amount The baseToken amount to trade
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @return The order ID
    function newOrder(
        uint256 price,
        uint256 amount,
        address trader,
        uint256 deadline
    )
    public override
    returns (uint256)
    {
        (uint256 orderID, bool created) = _newOrderWithPointer(
            price,
            amount,
            trader,
            deadline,
            0
        );
        require(created, 'can''t create new order');
        return orderID;
    }

    /// @notice Creates a new order using one of the provided pointers
    /// @param price The order price in counterToken
    /// @param amount The baseToken amount to trade
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @param pointers The potential pointers
    /// @return The order ID
    function newOrderWithPointers(
        uint256 price,
        uint256 amount,
        address trader,
        uint256 deadline,
        uint256[] memory pointers
    )
    public override
    returns (uint256)
    {
        for (uint256 i = 0; i < pointers.length; i++) {
            (uint256 orderID, bool created) = _newOrderWithPointer(
                price,
                amount,
                trader,
                deadline,
                pointers[i]
            );
            if (created) { return orderID; }
        }
        revert('can''t create new order');
    }


    // order cancellation functions

    /// @notice Cancel an order and send the funds to the specified address. This method
    ///         can be called by the owner or an approved operator
    /// @param orderID The order ID
    /// @param amount The amount to cancel. 0 cancels the total amount
    /// @param deadline Validity deadline
    function cancelOrder(
        uint256 orderID,
        uint256 amount,
        uint256 deadline
    )
        public override
        withinDeadline(deadline)
        ownerOrApproved(orderID)
        lock
    {
        Order memory _order = order[orderID];
        uint256 _amount = amount != 0 ? amount : _order.amount;
        _cancelOrder(orderID, amount);
        _withdrawBaseToken(_order.trader, _amount);
    }

    function _cancelOrder(
        uint256 orderID,
        uint256 amount
    ) internal {
        Order memory _order = order[orderID];
        require(_order.amount >= amount, 'can''t cancel a bigger amount than the order size');
        uint256 _amount = amount != 0 ? amount : _order.amount;
        uint256 remAmount = _order.amount - _amount;
        if (remAmount == 0) { _removeOrder(orderID); }
        else { order[orderID].amount = remAmount; }
        emit OrderCanceled(orderID, _amount);
    }

    // trading functions

    /// @notice Executes a trade at a particular price or below, returns the amount spent
    ///         and the amount received
    /// @param maxPrice The price of the trade
    /// @param maxCounterIn The maximum amount of the counter token to spend
    /// @param receiver The receiver of the baseToken
    /// @param deadline Validity deadline
    /// @return The amount of counter token spent
    /// @return The amount of base token received
    function tradeAtMaxPrice(
        uint256 maxPrice,
        uint256 maxCounterIn,
        address receiver,
        uint256 deadline
    )
        public override
        lock
        withinDeadline(deadline)
        returns (uint256, uint256)
    {
        Trade memory trade = Trade(0, 0, afterFee(maxCounterIn));
        while (trade.availableCounter > 0) {
            if (!_tradeFirstOrderMaxPrice(maxPrice, trade, receiver)) {
                break;
            }
        }
        require(trade.counter > 0 && trade.base > 0, 'No trade');
        uint256 fee = _collectFees(trade);
        return (trade.counter + fee, trade.base);
    }

    /// @notice Executes a trade at a maximum average price
    /// @param maxAveragePrice, The maximum average price
    /// @param maxCounterIn The maximum amount of the counter token to spend
    /// @param receiver The receiver of the baseToken
    /// @param deadline Validity deadline
    /// @return The amount of counter token spent
    /// @return The amount of base token received
    function tradeAtAveragePrice(
        uint256 maxAveragePrice,
        uint256 maxCounterIn,
        address receiver,
        uint256 deadline
    )
        external override
        lock
        withinDeadline(deadline)
        returns (uint256, uint256)
    {
        Trade memory trade = Trade(0, 0, afterFee(maxCounterIn));
        while (trade.availableCounter > 0) {
            if (!_tradeFirstOrderAveragePrice(maxAveragePrice, trade, receiver)) {
                break;
            }
        }
        require(trade.counter > 0 && trade.base > 0, 'No trade');
        uint256 fee = _collectFees(trade);
        return (trade.counter + fee, trade.base);
    }


    // ERC165

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(ILimitrMarketTokenToken).interfaceId;
    }


    // ERC721


    /// @return The number of tokens/orders owned by owner
    mapping(address => uint256) public override balanceOf;

    /// @return If the operator is allowed to manage all tokens/orders of owner
    mapping(address => mapping(address => bool)) public override isApprovedForAll;

    /// @notice Returns the owner of a token/order. The ID must be valid
    /// @param tokenId The token/order ID
    /// @return owner The owner of a token/order. The ID must be valid
    function ownerOf(uint256 tokenId)
        public view override
        tokenMustExist(tokenId)
        returns (address)
    {
        return order[tokenId].trader;
    }

    /// @notice Approves an account to transfer the token/order with the given ID.
    ///         The token/order must exists
    /// @param to The address of the account to approve
    /// @param tokenId the token/order
    function approve(address to, uint256 tokenId)
        public override
        tokenMustExist(tokenId)
        ownerOrApproved(tokenId)
    {
        address owner = ownerOf(tokenId);
        require(to != owner, 'ERC721: approval to current owner');
        _approve(owner, to, tokenId);
    }

    /// @notice Returns the address approved to transfer the token/order with the given ID
    ///         The token/order must exists
    /// @param tokenId the token/order
    /// @return The address approved to transfer the token/order with the given ID
    function getApproved(uint256 tokenId)
        public view override
        tokenMustExist(tokenId)
        returns (address)
    {
        return _approvals[tokenId];
    }

    /// @notice Approves or removes the operator for the caller tokens/orders
    /// @param operator The operator to be approved/removed
    /// @param approved Set true to approve, false to remove
    function setApprovalForAll(address operator, bool approved) public override {
        require(msg.sender != operator, 'can''t approve yourself');
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Transfers the ownership of the token/order. Can be called by the owner
    ///         or approved operators
    /// @param from The token/order owner
    /// @param to The new owner
    /// @param tokenId The token/order ID to transfer
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _transfer(from, to, tokenId);
    }

    /// @notice Safely transfers the token/order. It checks contract recipients are aware
    ///         of the ERC721 protocol to prevent tokens from being forever locked.
    /// @param from The token/order owner
    /// @param to the new owner
    /// @param tokenId The token/order ID to transfer
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }


    // ERC721Operator

    /// @notice Safely transfers the token/order. It checks contract recipients are aware
    ///         of the ERC721 protocol to prevent tokens from being forever locked.
    /// @param from The token/order owner
    /// @param to the new owner
    /// @param tokenId The token/order ID to transfer
    /// @param _data The data to be passed to the onERC721Received() call
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        _safeTransfer(from, to, tokenId, _data);
    }

    // modifiers

    modifier onlyFeeCollectorSetter {
        require(
            msg.sender == ILimitrFactory(factory).feeCollectorSetter(),
            'Only for the fee collector setter'
        );
        _;
    }

    modifier onlyFeeCollector() {
        require(
            msg.sender == ILimitrFactory(factory).feeCollector(),
            'only for the fee collector'
        );
        _;
    }

    modifier withinDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, 'Past the deadline');
        _;
    }

    bool internal _locked;

    modifier lock() {
        require(!_locked, 'already locked');
        _locked = true;
        _;
        _locked = false;
    }

    modifier postBalanceCheck(address token, uint256 expBalance) {
        _;
        require(
            IERC20(token).balanceOf(address(this)) >= expBalance,
            'ERROR: Deflationary token'
        );
    }

    modifier ownerOrApproved(uint256 tokenId) {
        require(canTransfer(msg.sender, tokenId), 'not the owner or approved');
        _;
    }

    modifier tokenMustExist(uint256 tokenId) {
        require(order[tokenId].trader != address(0), 'ERC721: token does not exist');
        _;
    }


    // internal variables and methods

    uint256 internal immutable _oneBaseToken;

    uint256 internal _expectedBaseBalance;
    uint256 internal _expectedCounterBalance;

    mapping(uint256 => uint256) internal _lastOrder;

    SDLL internal _prices;

    DLL internal _orders;

    mapping(address => DLL) internal _tradersOrders;

    mapping(uint256 => address) private _approvals;

    /// @notice Returns if the operator can transfer the token/order
    /// @param operator The address to be checked
    /// @param tokenId The token/order ID
    /// @return True if the operator can transfer the token/order
    function canTransfer(address operator, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return
            operator == owner ||
            isApprovedForAll[owner][operator] ||
            getApproved(tokenId) == operator;
    }

    function _tokenTransfer(address token, address to, uint256 amount) internal {
        bool ok = IERC20(token).transfer(to, amount);
        require(ok, 'can''t transfer()');
    }

    function _tokenTransferFrom(address token, address from, address to, uint256 amount) internal {
        bool ok = IERC20(token).transferFrom(from, to, amount);
        require(ok, 'can''t transferFrom()');
    }

    /// @dev withdraw base token
    function _withdrawBaseToken(address to, uint256 amount)
        internal
        postBalanceCheck(baseToken, _expectedBaseBalance - amount)
    {
        _expectedBaseBalance -= amount;
        _tokenTransfer(baseToken, to, amount);
    }

    /// @dev withdraw counter token
    function _withdrawCounterToken(address to, uint256 amount)
        internal
        postBalanceCheck(counterToken, _expectedCounterBalance - amount)
    {
        _expectedCounterBalance -= amount;
        _tokenTransfer(counterToken, to, amount);
    }

    /// @dev take a base token deposit from a user
    function _depositBaseToken(address from, uint256 amount)
        internal
        postBalanceCheck(baseToken, _expectedBaseBalance + amount)
    {
        _expectedBaseBalance += amount;
        _tokenTransferFrom(baseToken, from, address(this), amount);
    }

    /// @dev take a counter token deposit from a user
    function _depositCounterToken(address from, uint256 amount)
        internal
        postBalanceCheck(counterToken, _expectedCounterBalance + amount)
    {
        _expectedCounterBalance += amount;
        _tokenTransferFrom(counterToken, from, address(this), amount);
    }

    /// @dev increment lastID and return it
    function _nextID() internal returns (uint256) {
        lastID++;
        return lastID;
    }

    /// @dev Creates a new order using the provided pointer
    /// @param price The order price in counterToken
    /// @param amount The baseToken amount to trade
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @return The order ID
    /// @return True on success
    function _newOrderWithPointer(
        uint256 price,
        uint256 amount,
        address trader,
        uint256 deadline,
        uint256 pointer
    )
        internal
        withinDeadline(deadline)
        lock
        returns (uint256, bool)
    {
        (uint256 orderID, bool created) = _createNewOrder(
            price,
            amount,
            trader,
            pointer
        );
        if (created) {
            _depositBaseToken(msg.sender, amount);
            emit NewOrder(orderID, trader, price, amount);
        }
        return (orderID, created);
    }

    function _createNewOrder(
        uint256 price,
        uint256 amount,
        address trader,
        uint256 pointer
    )
        internal returns (uint256, bool)
    {
        require(trader != address(0), 'zero address not allowed');
        require(amount > 0, 'zero amount not allowed');
        require(price > 0, 'zero price not allowed');
        // validate pointer
        if (pointer != 0 && _lastOrder[pointer] == 0) { return (0, false); }
        // save the order
        uint256 orderID = _nextID();
        order[orderID] = Order(price, amount, trader);
        // insert order
        if (!_insertOrder(orderID, price, pointer)) { return (0, false); }
        // insert order in the trader's orders
        _tradersOrders[trader].insertEnd(orderID);
        balanceOf[trader] += 1;
        return (orderID, true);
    }

    function _insertOrder(uint256 orderID, uint256 price, uint256 pointer) internal returns (bool) {
        uint256 _prevID = _lastOrder[price];
        if (_prevID == 0) {
            if (pointer != 0 && _lastOrder[pointer] == 0) { return false; }
            if (!_prices.insertWithPointer(price, pointer)) { return false; }
            _prevID = _lastOrder[_prices.previous(price)];
        }
        _orders.insertAfter(orderID, _prevID);
        _lastOrder[price] = orderID;
        return true;
    }

    /// @dev remove an order
    function _removeOrder(uint256 orderID) internal virtual {
        uint256 orderPrice = order[orderID].price;
        address orderTrader = order[orderID].trader;
        uint256 _prevID = _orders.previous(orderID);
        bool prevPriceNotEqual = orderPrice != order[_prevID].price;
        bool onlyOrderAtPrice = prevPriceNotEqual &&
            orderPrice != order[_orders.next(orderID)].price;
        delete order[orderID];
        _orders.remove(orderID);
        if (_lastOrder[orderPrice] == orderID) {
            if (prevPriceNotEqual) { delete _lastOrder[orderPrice]; }
            else { _lastOrder[orderPrice] = _prevID; }
        }
        if (onlyOrderAtPrice) { _prices.remove(orderPrice); }
        _tradersOrders[orderTrader].remove(orderID);
        balanceOf[orderTrader] -= 1;
    }

    /// @dev trade the first order at a max price
    function _tradeFirstOrderMaxPrice(
        uint256 maxPrice,
        Trade memory trade,
        address receiver
    ) internal returns (bool) {
        // get the order ID
        uint256 orderID = _orders.first();
        // get the order
        Order memory _order = order[orderID];
        // check price and trader
        if (_order.price > maxPrice) { return false; }
        if (_order.trader == address(0)) { return false; }
        // max amount of the base token that can be purchased with the
        uint256 maxAmount = returnOf(trade.availableCounter, _order.price);
        // remaining amount of counter token
        return _tradeOrder(orderID, _order, trade, maxAmount, receiver);
    }

    /// @dev trade the first order at an average price
    function _tradeFirstOrderAveragePrice(
        uint256 maxAveragePrice,
        Trade memory trade,
        address receiver
    ) internal returns (bool) {
        // get the order ID
        uint256 orderID = _orders.first();
        // get the order
        Order memory _order = order[orderID];
        // check trader
        if (_order.trader == address(0)) { return false; }
        // max amount of the base token that can be purchased with the
        // remaining amount of counter token
        uint256 maxAmount = _maxAmountAveragePrice(
            maxAveragePrice,
            trade,
            _order.price
        );
        if (maxAmount == 0) { return false; }
        return _tradeOrder(orderID, _order, trade, maxAmount, receiver);
    }

    function _maxAmountAveragePrice(
        uint256 maxAveragePrice,
        Trade memory trade,
        uint256 orderPrice
    ) internal view returns (uint256) {
        if (trade.base == 0 || trade.counter == 0) {
            if (orderPrice + feeFor(orderPrice) <= maxAveragePrice) {
                return returnOf(trade.availableCounter, orderPrice);
            }
            return 0;
        }
        uint256 a = (10**18 - feePercentage) * maxAveragePrice * orderPrice * trade.base;
        uint256 b = 10**18 * _oneBaseToken * orderPrice * trade.counter;
        a = a > b ? a - b : b - a;
        b = (10**18 - feePercentage) * maxAveragePrice * _oneBaseToken;
        uint256 c = 10**18 * _oneBaseToken * orderPrice;
        b = b > c ? b - c : c - b;
        return a / b;
    }

    function _tradeOrder(
        uint256 orderID,
        Order memory _order,
        Trade memory trade,
        uint256 maxAmount,
        address receiver
    ) internal returns (bool fullOrder) {
        // only the available amount in the order
        uint256 amt = maxAmount >= _order.amount ? _order.amount : maxAmount;
        // calculate cost
        uint256 cost = costOf(amt, _order.price);
        if (cost > trade.availableCounter) {
            cost = trade.availableCounter;
            amt = returnOf(cost, _order.price);
        }
        fullOrder = amt == _order.amount;
        // remaining amount of the order
        uint256 newAmount = _order.amount - amt;
        // transfer the base token to the receiver
        _withdrawBaseToken(receiver, amt);
        // transfer counter token to the order trader
        _tokenTransferFrom(counterToken, msg.sender, _order.trader, cost);
        // remove order or update amount
        if (newAmount == 0) { _removeOrder(orderID); }
        else { order[orderID].amount = newAmount; }
        trade.update(amt, cost);
        emit OrderTaken(orderID, amt, _order.price, receiver);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        lock
        tokenMustExist(tokenId)
        ownerOrApproved(tokenId)
    {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        _approvals[tokenId] = address(0);
        balanceOf[from] -= 1;
        balanceOf[to] += 1;
        order[tokenId].trader = to;
        _tradersOrders[from].remove(tokenId);
        _tradersOrders[to].insertEnd(tokenId);
        emit Transfer(from, to, tokenId);
    }

    function _approve(address owner, address to, uint256 tokenId) internal {
        _approvals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.code.length == 0) { return true; }
        try IERC721Receiver(to).onERC721Received(
            msg.sender,
            from,
            tokenId,
            _data
        ) returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch {
            return false;
        }
    }

    function _collectFees(Trade memory trade) internal returns (uint256 fee) {
        fee = feeFor(trade.counter);
        if (fee > 0) { _depositCounterToken(msg.sender, fee); }
        emit FeeReceived(msg.sender, fee);
    }
}






pragma solidity ^0.8.0;




/// @author Limitr
/// @title factory contract for Limitr
contract LimitrDeployerTokenToken is ILimitrDeployer {
    function createMarket(
        address factory,
        address baseToken,
        address counterToken
    )
        external override
        returns (address)
    {
        return address(new LimitrMarketTokenToken(factory, baseToken, counterToken));
    }
}