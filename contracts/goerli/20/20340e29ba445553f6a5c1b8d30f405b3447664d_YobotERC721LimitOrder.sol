/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/YobotERC721LimitOrder.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.11;

////// src/Coordinator.sol
/* pragma solidity 0.8.11; */

/// Fee Overflow
/// @param sender address that caused the revert
/// @param fee uint256 proposed fee percent
error FeeOverflow(address sender, uint256 fee);

/// Non Coordinator
/// @param sender The coordinator impersonator address
/// @param coordinator The expected coordinator address
error NonCoordinator(address sender, address coordinator);

/// @title Coordinator
/// @notice Coordinates fees and receivers
/// @author Andreas Bigger <[email protected]>
contract Coordinator {
    /// @dev This contracts coordinator
    address public coordinator;

    /// @dev Address of the profit receiver
    address payable public profitReceiver;

    /// @dev Pack the below variables using uint32 values
    /// @dev Fee paid by bots
    uint32 public botFeeBips;

    /// @dev The absolute maximum fee in bips (10,000 bips or 100%)
    uint32 public constant MAXIMUM_FEE = 10_000;

    /// @dev Modifier restricting msg.sender to solely be the coordinatoooor
    modifier onlyCoordinator() {
        if (msg.sender != coordinator) revert NonCoordinator(msg.sender, coordinator);
        _;
    }

    /// @notice Constructor sets coordinator, profit receiver, and fee in bips
    /// @param _profitReceiver the address of the profit receiver
    /// @param _botFeeBips the fee in bips
    /// @dev The fee cannot be greater than 100%
    constructor(address _profitReceiver, uint32 _botFeeBips) {
        if (botFeeBips > MAXIMUM_FEE) revert FeeOverflow(msg.sender, _botFeeBips);
        coordinator = msg.sender;
        profitReceiver = payable(_profitReceiver);
        botFeeBips = _botFeeBips;
    }

    /// @notice Coordinator can change the stored Coordinator address
    /// @param newCoordinator The address of the new coordinator
    function changeCoordinator(address newCoordinator) external onlyCoordinator {
        coordinator = newCoordinator;
    }

    /// @notice The Coordinator can change the address that receives the fee profits
    /// @param newProfitReceiver The address of the new profit receiver
    function changeProfitReceiver(address newProfitReceiver) external onlyCoordinator {
        profitReceiver = payable(newProfitReceiver);
    }

    /// @notice The Coordinator can change the fee amount in bips
    /// @param newBotFeeBips The unsigned integer representing the new fee amount in bips
    /// @dev The fee cannot be greater than 100%
    function changeBotFeeBips(uint32 newBotFeeBips) external onlyCoordinator {
        if (newBotFeeBips > MAXIMUM_FEE) revert FeeOverflow(msg.sender, newBotFeeBips);
        botFeeBips = newBotFeeBips;
    }
}

////// src/interfaces/IERC165.sol
/* pragma solidity 0.8.11; */

/// @title ERC165 Interface
/// @dev https://eips.ethereum.org/EIPS/eip-165
/// @author Andreas Bigger <[email protected]>
interface IERC165 {
    /// @dev Returns if the contract implements the defined interface
    /// @param interfaceId the 4 byte interface signature
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

////// src/interfaces/IERC721.sol
/* pragma solidity 0.8.11; */

/* import {IERC165} from "./IERC165.sol"; */

/// @title ERC721 Interface
/// @dev https://eips.ethereum.org/EIPS/eip-721
/// @author Andreas Bigger <[email protected]>
interface IERC721 is IERC165 {
    /// @dev Emitted when a token is transferred
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /// @dev Emitted when a token owner approves `approved`
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /// @dev Emitted when `owner` enables or disables `operator` for all tokens
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /// @dev Returns the number of tokens owned by `owner`
    function balanceOf(address owner) external view returns (uint256 balance);

    /// @dev Returns the owner of token with id `tokenId`
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /// @dev Safely transfers the token with id `tokenId`
    /// @dev Requires the sender to be approved through an `approve` or `setApprovalForAll`
    /// @dev Emits a Transfer Event
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /// @dev Transfers the token with id `tokenId`
    /// @dev Requires the sender to be approved through an `approve` or `setApprovalForAll`
    /// @dev Emits a Transfer Event
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /// @dev Approves `to` to transfer the given token
    /// @dev Approval is reset on transfer
    /// @dev Caller must be the owner or approved
    /// @dev Only one address can be approved at a time
    /// @dev Emits an Approval Event
    function approve(address to, uint256 tokenId) external;

    /// @dev Returns the address approved for the given token
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /// @dev Sets an operator as approved or disallowed for all tokens owned by the caller
    /// @dev Emits an ApprovalForAll Event
    function setApprovalForAll(address operator, bool _approved) external;

    /// @dev Returns if the operator is allowed approved for owner's tokens
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /// @dev Safely transfers a token with id `tokenId`
    /// @dev Emits a Transfer Event
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

////// src/YobotERC721LimitOrder.sol
/* pragma solidity 0.8.11; */

/* import {IERC721} from "./interfaces/IERC721.sol"; */
/* import {Coordinator} from "./Coordinator.sol"; */

/// Require EOA
error NonEOA();

/// Order Out of Bounds
/// @param sender The address of the msg sender
/// @param orderNumber The requested order number for the user (maps to an order id)
/// @param maxOrderCount The maximum number of orders a user has placed
error OrderOOB(address sender, uint256 orderNumber, uint256 maxOrderCount);

/// Order Nonexistent
/// @param user The address of the user who owns the order
/// @param orderNumber The requested order number for the user (maps to an order id)
/// @param orderId The order's Id
error OrderNonexistent(address user, uint256 orderNumber, uint256 orderId);

/// Invalid Amount
/// @param sender The address of the msg sender
/// @param priceInWeiEach The order's priceInWeiEach
/// @param quantity The order's quantity
/// @param tokenAddress The order's token address
error InvalidAmount(address sender, uint256 priceInWeiEach, uint256 quantity, address tokenAddress);

/// Insufficient price in wei
/// @param sender The address of the msg sender
/// @param orderId The order's Id
/// @param tokenId The ERC721 Token ID
/// @param expectedPriceInWeiEach The expected priceInWeiEach
/// @param priceInWeiEach The order's actual priceInWeiEach from internal store
error InsufficientPrice(address sender, uint256 orderId, uint256 tokenId, uint256 expectedPriceInWeiEach, uint256 priceInWeiEach);

/// Inconsistent Arguments
/// @param sender The address of the msg sender
error InconsistentArguments(address sender);

/// @title YobotERC721LimitOrder
/// @author Andreas Bigger <[email protected]>
/// @notice Original contract implementation was open-sourced and verified on etherscan at:
///         https://etherscan.io/address/0x56E6FA0e461f92644c6aB8446EA1613F4D72a756#code
///         with the original UI at See ArtBotter.io
/// @notice Permissionless Broker for Generalized ERC721 Minting using Flashbot Searchers
contract YobotERC721LimitOrder is Coordinator {
    /// @notice A user's order
    struct Order {
        /// @dev The Order owner
        address owner;
        /// @dev The Order's Token Address
        address tokenAddress;
        /// @dev the price to pay for each erc721 token
        uint256 priceInWeiEach;
        /// @dev the quantity of tokens to pay
        uint256 quantity;
        /// @dev the order number for the user, used for reverse mapping
        uint256 num;
    }

    /// @dev Current Order Id
    /// @dev Starts at 1, 0 is a deleted order
    uint256 public orderId = 1;

    /// @dev Mapping from order id to an Order
    mapping(uint256 => Order) public orderStore;

    /// @dev user => order number => order id
    mapping(address => mapping(uint256 => uint256)) public userOrders;

    /// @dev The number of user orders
    mapping(address => uint256) public userOrderCount;

    /// @dev bot => eth balance
    mapping(address => uint256) public balances;

    /// @notice Emitted whenever a respective individual executes a function
    /// @param _user the address of the sender executing the action - used primarily for indexing
    /// @param _tokenAddress The token address to interact with
    /// @param _priceInWeiEach The bid price in wei for each ERC721 Token
    /// @param _quantity The number of tokens
    /// @param _action The action being emitted
    /// @param _orderId The order's id
    /// @param _orderNum The user<>num order
    /// @param _tokenId The optional token id (used primarily on bot fills)
    event Action(
        address indexed _user,
        address indexed _tokenAddress,
        uint256 indexed _priceInWeiEach,
        uint256 _quantity,
        string _action,
        uint256 _orderId,
        uint256 _orderNum,
        uint256 _tokenId
    );

    /// @notice Creates a new yobot erc721 limit order broker
    /// @param _profitReceiver The profit receiver for fees
    /// @param _botFeeBips The fee rake
    // solhint-disable-next-line no-empty-blocks
    constructor(address _profitReceiver, uint32 _botFeeBips) Coordinator(_profitReceiver, _botFeeBips) {}

    ////////////////////////////////////////////////////
    ///                     ORDERS                   ///
    ////////////////////////////////////////////////////

    /// @notice places an open order for a user
    /// @notice users should place orders ONLY for token addresses that they trust
    /// @param _tokenAddress the erc721 token address
    /// @param _quantity the number of tokens
    function placeOrder(address _tokenAddress, uint256 _quantity) external payable {
        // Removes user foot-guns and garuantees user can receive NFTs
        // We disable linting against tx-origin to purposefully allow EOA checks
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender != tx.origin) revert NonEOA();

        // Check to make sure the bids are gt zero
        uint256 priceInWeiEach = msg.value / _quantity;
        if (priceInWeiEach == 0 || _quantity == 0) revert InvalidAmount(msg.sender, priceInWeiEach, _quantity, _tokenAddress);

        // Update the Order Id
        uint256 currOrderId = orderId;
        orderId += 1;

        // Get the current order number for the user
        uint256 currUserOrderCount = userOrderCount[msg.sender];

        // Create a new Order
        orderStore[currOrderId].owner = msg.sender;
        orderStore[currOrderId].tokenAddress = _tokenAddress;
        orderStore[currOrderId].priceInWeiEach = priceInWeiEach;
        orderStore[currOrderId].quantity = _quantity;
        orderStore[currOrderId].num = currUserOrderCount;

        // Update the user's orders
        userOrders[msg.sender][currUserOrderCount] = currOrderId;
        userOrderCount[msg.sender] += 1;

        emit Action(msg.sender, _tokenAddress, priceInWeiEach, _quantity, "ORDER_PLACED", currOrderId, currUserOrderCount, 0);
    }

    /// @notice Cancels a user's order for the given erc721 token
    /// @param _orderNum The user's order number
    function cancelOrder(uint256 _orderNum) external {
        // Check to make sure the user's order is in bounds
        uint256 currUserOrderCount = userOrderCount[msg.sender];
        if (_orderNum >= currUserOrderCount) revert OrderOOB(msg.sender, _orderNum, currUserOrderCount);

        // Get the id for the given user order num
        uint256 currOrderId = userOrders[msg.sender][_orderNum];
        
        // Revert if the order id is 0, already deleted or filled
        if (currOrderId == 0) revert OrderNonexistent(msg.sender, _orderNum, currOrderId);

        // Get the order
        Order memory order = orderStore[currOrderId];
        uint256 amountToSendBack = order.priceInWeiEach * order.quantity;
        if (amountToSendBack == 0) revert InvalidAmount(msg.sender, order.priceInWeiEach, order.quantity, order.tokenAddress);

        // Delete the order
        delete orderStore[currOrderId];

        // Delete the order id from the userOrders mapping
        delete userOrders[msg.sender][_orderNum];

        // Send the value back to the user
        sendValue(payable(msg.sender), amountToSendBack);

        emit Action(msg.sender, order.tokenAddress, order.priceInWeiEach, order.quantity, "ORDER_CANCELLED", currOrderId, _orderNum, 0);
    }

    ////////////////////////////////////////////////////
    ///                  BOT LOGIC                   ///
    ////////////////////////////////////////////////////

    /// @notice Fill a single order
    /// @param _orderId The id of the order
    /// @param _tokenId the token id to mint
    /// @param _expectedPriceInWeiEach the price to pay
    /// @param _profitTo the address to send the fee to
    /// @param _sendNow whether or not to send the fee now
    function fillOrder(
        uint256 _orderId,
        uint256 _tokenId,
        uint256 _expectedPriceInWeiEach,
        address _profitTo,
        bool _sendNow
    ) public returns (uint256) {
        Order storage order = orderStore[_orderId];

        // Make sure the order isn't deleted
        uint256 orderIdFromMap = userOrders[order.owner][order.num];
        if (order.quantity == 0 || order.priceInWeiEach == 0 || orderIdFromMap == 0) revert InvalidAmount(order.owner, order.priceInWeiEach, order.quantity, order.tokenAddress);

        // Protects bots from users frontrunning them
        if (order.priceInWeiEach < _expectedPriceInWeiEach) revert InsufficientPrice(msg.sender, _orderId, _tokenId, _expectedPriceInWeiEach, order.priceInWeiEach);

        // Transfer NFT to user (benign reentrancy possible here)
        // ERC721-compliant contracts revert on failure here
        IERC721(order.tokenAddress).safeTransferFrom(msg.sender, order.owner, _tokenId);
        
        // This reverts on underflow
        order.quantity -= 1;
        uint256 botFee = (order.priceInWeiEach * botFeeBips) / 10_000;
        balances[profitReceiver] += botFee;

        // Pay the bot with the remaining amount
        uint256 botPayment = order.priceInWeiEach - botFee;
        if (_sendNow) {
            sendValue(payable(_profitTo), botPayment);
        } else {
            balances[_profitTo] += botPayment;
        }

        // Emit the action later so we can log trace on a bot dashboard
        emit Action(order.owner, order.tokenAddress, order.priceInWeiEach, order.quantity, "ORDER_FILLED", _orderId, order.num, _tokenId);

        // Clear up if the quantity is now 0
        if (order.quantity == 0) {
            delete orderStore[_orderId];
            userOrders[order.owner][order.num] = 0;
        }

        // RETURN
        return botPayment;
    }

    /// @notice allows a bot to fill multiple outstanding orders
    /// @dev there should be one token id and token price specified for each users
    /// @dev So, _users.length == _tokenIds.length == _expectedPriceInWeiEach.length
    /// @param _orderIds a list of order ids
    /// @param _tokenIds a list of token ids
    /// @param _expectedPriceInWeiEach the price of each token
    /// @param _profitTo the address to send the bot's profit to
    /// @param _sendNow whether the profit should be sent immediately
    function fillMultipleOrdersOptimized(
        uint256[] memory _orderIds,
        uint256[] memory _tokenIds,
        uint256[] memory _expectedPriceInWeiEach,
        address _profitTo,
        bool _sendNow
    ) external returns (uint256[] memory) {
        if (_orderIds.length != _tokenIds.length || _tokenIds.length != _expectedPriceInWeiEach.length) revert InconsistentArguments(msg.sender);
        uint256[] memory output = new uint256[](_orderIds.length);
        for (uint256 i = 0; i < _orderIds.length; i++) {
            output[i] = fillOrder(_orderIds[i], _tokenIds[i], _expectedPriceInWeiEach[i], _profitTo, _sendNow);
        }
        return output;
    }

    /// @notice allows a bot to fill multiple outstanding orders with
    /// @dev all argument array lengths should be equal
    /// @param _orderIds a list of order ids
    /// @param _tokenIds a list of token ids
    /// @param _expectedPriceInWeiEach the price of each token
    /// @param _profitTo the addresses to send the bot's profit to
    /// @param _sendNow whether the profit should be sent immediately
    function fillMultipleOrdersUnOptimized(
        uint256[] memory _orderIds,
        uint256[] memory _tokenIds,
        uint256[] memory _expectedPriceInWeiEach,
        address[] memory _profitTo,
        bool[] memory _sendNow
    ) external returns (uint256[] memory) {
        if (
            _orderIds.length != _tokenIds.length
            || _tokenIds.length != _expectedPriceInWeiEach.length
            || _expectedPriceInWeiEach.length != _profitTo.length
            || _profitTo.length != _sendNow.length
        ) revert InconsistentArguments(msg.sender);

        // Fill the orders iteratively
        uint256[] memory output = new uint256[](_orderIds.length);
        for (uint256 i = 0; i < _orderIds.length; i++) {
            output[i] = fillOrder(_orderIds[i], _tokenIds[i], _expectedPriceInWeiEach[i], _profitTo[i], _sendNow[i]);
        }
        return output;
    }

    ////////////////////////////////////////////////////
    ///                 WITHDRAWALS                  ///
    ////////////////////////////////////////////////////

    /// @notice Allows profitReceiver and bots to withdraw their fees
    /// @dev delete balances on withdrawal to free up storage
    function withdraw() external {
        // EFFECTS
        uint256 amount = balances[msg.sender];
        delete balances[msg.sender];
        // INTERACTIONS
        sendValue(payable(msg.sender), amount);
    }

    ////////////////////////////////////////////////////
    ///                   HELPERS                    ///
    ////////////////////////////////////////////////////

    /// @notice sends ETH out of this contract to the recipient
    /// @dev OpenZeppelin's sendValue function
    /// @param recipient the recipient to send the ETH to | payable
    /// @param amount the amount of ETH to send
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /// @notice Returns an open order for a user and order number pair
    /// @param _user The user
    /// @param _orderNum The order number (NOT ID)
    function viewUserOrder(address _user, uint256 _orderNum) public view returns (Order memory) {
        // Revert if the order id is 0
        uint256 _orderId = userOrders[_user][_orderNum];
        if (_orderId == 0) revert OrderNonexistent(_user, _orderNum, _orderId);
        return orderStore[_orderId];
    }

    /// @notice Returns all open orders for a given user
    /// @param _user The user
    function viewUserOrders(address _user) public view returns (Order[] memory output) {
        uint256 _userOrderCount = userOrderCount[_user];
        output = new Order[](_userOrderCount);
        for (uint256 i = 0; i < _userOrderCount; i += 1) {
            uint256 _orderId = userOrders[_user][i];
            output[i] = orderStore[_orderId]; 
        }
    }

    /// @notice Returns the open orders for a list of users
    /// @param _users the users address
    function viewMultipleOrders(address[] memory _users) public view returns (Order[][] memory output) {
        Order[][] memory output = new Order[][](_users.length);
        for (uint256 i = 0; i < _users.length; i++) {
            output[i] = viewUserOrders(_users[i]);
        }
    }
}