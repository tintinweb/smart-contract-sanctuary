/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/YobotERC721LimitOrder.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.6 <0.9.0;

////// src/Coordinator.sol
/* pragma solidity ^0.8.6; */

/* solhint-disable max-line-length */

contract Coordinator {
    /// @dev This contracts coordinator
    address public coordinator;

    /// @dev Address of the profit receiver
    address payable public profitReceiver;

    /// @dev Fee paid by bots
    uint256 public botFeeBips;

    /// @dev Modifier restricting msg.sender to solely be the coordinatoooor
    modifier onlyCoordinator() {
        require(msg.sender == coordinator, "not Coordinator");
        _;
    }

    /// @notice generic constructor to set coordinator to the msg.sender
    constructor(address _profitReceiver, uint256 _botFeeBips) {
        coordinator = msg.sender;
        profitReceiver = payable(_profitReceiver);
        require(_botFeeBips <= 500, "fee too high");
        botFeeBips = _botFeeBips;
    }

    /*///////////////////////////////////////////////////////////////
                      COORDINATOR FUNCTIONS
  //////////////////////////////////////////////////////////////*/

    function changeCoordinator(address _newCoordinator) external onlyCoordinator {
        coordinator = _newCoordinator;
    }

    function changeProfitReceiver(address _newProfitReceiver) external onlyCoordinator {
        profitReceiver = payable(_newProfitReceiver);
    }

    function changeBotFeeBips(uint256 _newBotFeeBips) external onlyCoordinator {
        require(_newBotFeeBips <= 500, "fee cannot be greater than 5%");
        botFeeBips = _newBotFeeBips;
    }
}

////// src/external/IERC721.sol
/* pragma solidity ^0.8.6; */

interface IERC721_2 {
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;
}

////// src/YobotERC721LimitOrder.sol
/* pragma solidity ^0.8.6; */

/* solhint-disable max-line-length */

/* import {IERC721} from "./external/IERC721.sol"; */
/* import {Coordinator} from "./Coordinator.sol"; */

/// @title YobotERC721LimitOrder
/// @author Andreas Bigger <[email protected]> et al
/// @notice Original contract implementation was open-sourced and verified on etherscan at:
///         https://etherscan.io/address/0x56E6FA0e461f92644c6aB8446EA1613F4D72a756#code
///         with the original UI at See ArtBotter.io
/// @notice Broker enabling permissionless markets between flashbot
/// 				searchers and users attempting to mint generic ERC721 drops.
contract YobotERC721LimitOrder is Coordinator {
    /// @notice A user's order
    struct Order {
        /// @dev the price to pay for each erc721 token
        uint128 priceInWeiEach;
        /// @dev the quantity of tokens to pay
        uint128 quantity;
    }

    // user => token address => {priceInWeiEach, quantity}
    mapping(address => mapping(address => Order)) public orders;
    // bot => eth balance
    mapping(address => uint256) public balances;

    /// @notice Emitted whenever a respective individual executes a function
    /// @param _user the address of the sender executing the action - used primarily for indexing
    /// @param _tokenAddress The token address to interact with
    /// @param _priceInWeiEach The bid price in wei for each ERC721 Token
    /// @param _quantity The number of tokens
    /// @param _action The action being emitted
    /// @param _optionalTokenId An optional specific token id
    event Action(address indexed _user, address indexed _tokenAddress, uint256 _priceInWeiEach, uint256 _quantity, string _action, uint256 _optionalTokenId);

    /// @notice Creates a new yobot erc721 limit order broker
    /// @param _profitReceiver The profit receiver for fees
    /// @param _botFeeBips The fee rake
    // solhint-disable-next-line no-empty-blocks
    constructor(address _profitReceiver, uint256 _botFeeBips) Coordinator(_profitReceiver, _botFeeBips) {}

    /*///////////////////////////////////////////////////////////////
                      USER FUNCTIONS
  //////////////////////////////////////////////////////////////*/

    /// @notice places an open order for a user
    /// @notice users should place orders ONLY for token addresses that they trust
    /// @param _tokenAddress the erc721 token address
    /// @param _quantity the number of tokens
    function placeOrder(address _tokenAddress, uint128 _quantity) external payable {
        // CHECKS
        // Removes user foot-guns and garuantees user can receive NFTs
        // We disable linting against tx-origin to purposefully allow EOA checks
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender == tx.origin, "NON_EOA_ORIGIN");

        Order memory order = orders[msg.sender][_tokenAddress];
        require(order.quantity == 0, "DUPLICATE_ORDER");
        uint128 priceInWeiEach = uint128(msg.value) / _quantity;
        require(priceInWeiEach > 0, "ZERO_WEI_BID");

        // EFFECTS
        orders[msg.sender][_tokenAddress].priceInWeiEach = priceInWeiEach;
        orders[msg.sender][_tokenAddress].quantity = _quantity;

        emit Action(msg.sender, _tokenAddress, priceInWeiEach, _quantity, "ORDER_PLACED", 0);
    }

    /// @notice Cancels a user's order for the given erc721 token
    /// @param _tokenAddress the erc721 token address
    function cancelOrder(address _tokenAddress) external {
        // CHECKS
        Order memory order = orders[msg.sender][_tokenAddress];
        uint256 amountToSendBack = order.priceInWeiEach * order.quantity;
        require(amountToSendBack != 0, "NONEXISTANT_ORDER");

        // EFFECTS
        delete orders[msg.sender][_tokenAddress];

        // INTERACTIONS
        sendValue(payable(msg.sender), amountToSendBack);

        emit Action(msg.sender, _tokenAddress, 0, 0, "ORDER_CANCELLED", 0);
    }

    /*///////////////////////////////////////////////////////////////
                      BOT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice fill a single order
    /// @param _user the address of the user with the order
    /// @param _tokenAddress the address of the erc721 token
    /// @param _tokenId the token id to mint
    /// @param _expectedPriceInWeiEach the price to pay
    /// @param _profitTo the address to send the fee to
    /// @param _sendNow whether or not to send the fee now
    function fillOrder(
        address _user,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _expectedPriceInWeiEach,
        address _profitTo,
        bool _sendNow
    ) public returns (uint256) {
        // CHECKS
        Order memory order = orders[_user][_tokenAddress];
        require(order.quantity > 0, "NO_OUTSTANDING_USER_ORDER");
        // Protects bots from users frontrunning them
        require(order.priceInWeiEach >= _expectedPriceInWeiEach, "INSUFFICIENT_EXPECTED_PRICE");

        // EFFECTS
        // This reverts on underflow
        orders[_user][_tokenAddress].quantity = order.quantity - 1;
        uint256 botFee = (order.priceInWeiEach * botFeeBips) / 10_000;
        balances[profitReceiver] += botFee;

        // INTERACTIONS
        // Transfer NFT to user (benign reentrancy possible here)
        // ERC721-compliant contracts revert on failure here
        IERC721_2(_tokenAddress).safeTransferFrom(msg.sender, _user, _tokenId);

        // Pay the bot with the remaining amount
        uint256 botPayment = order.priceInWeiEach - botFee;
        if (_sendNow) {
            sendValue(payable(_profitTo), botPayment);
        } else {
            balances[_profitTo] += botPayment;
        }

        // Emit the action later so we can log trace on a bot dashboard
        emit Action(_user, _tokenAddress, order.priceInWeiEach, order.quantity - 1, "ORDER_FILLED", _tokenId);

        // TODO: delete order ?

        // RETURN
        return botPayment;
    }

    /// @notice allows a bot to fill multiple outstanding orders
    /// @dev there should be one token id and token price specified for each users
    /// @dev So, _users.length == _tokenIds.length == _expectedPriceInWeiEach.length
    /// @param _users a list of users to fill orders for
    /// @param _tokenAddress the address of the erc721 token
    /// @param _tokenIds a list of token ids
    /// @param _expectedPriceInWeiEach the price of each token
    /// @param _profitTo the address to send the bot's profit to
    /// @param _sendNow whether the profit should be sent immediately
    function fillMultipleOrdersOptimized(
        address[] memory _users,
        address _tokenAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _expectedPriceInWeiEach,
        address _profitTo,
        bool _sendNow
    ) external returns (uint256[] memory) {
        require(_users.length == _tokenIds.length && _tokenIds.length == _expectedPriceInWeiEach.length, "ARRAY_LENGTH_MISMATCH");
        uint256[] memory output = new uint256[](_users.length);
        for (uint256 i = 0; i < _users.length; i++) {
            output[i] = fillOrder(_users[i], _tokenAddress, _tokenIds[i], _expectedPriceInWeiEach[i], _profitTo, _sendNow);
        }
        return output;
    }

    /// @notice allows a bot to fill multiple outstanding orders with
    /// @dev all argument array lengths should be equal
    /// @param _users a list of users to fill orders for
    /// @param _tokenAddresses a list of erc721 token addresses
    /// @param _tokenIds a list of token ids
    /// @param _expectedPriceInWeiEach the price of each token
    /// @param _profitTo the addresses to send the bot's profit to
    /// @param _sendNow whether the profit should be sent immediately
    function fillMultipleOrdersUnOptimized(
        address[] memory _users,
        address[] memory _tokenAddresses,
        uint256[] memory _tokenIds,
        uint256[] memory _expectedPriceInWeiEach,
        address[] memory _profitTo,
        bool[] memory _sendNow
    ) external returns (uint256[] memory) {
        // verify argument array lengths are equal
        require(_users.length == _tokenAddresses.length && _tokenAddresses.length == _tokenIds.length && _tokenIds.length == _expectedPriceInWeiEach.length && _expectedPriceInWeiEach.length == _profitTo.length && _profitTo.length == _sendNow.length, "ARRAY_LENGTH_MISMATCH");
        uint256[] memory output = new uint256[](_users.length);
        for (uint256 i = 0; i < _users.length; i++) {
            output[i] = fillOrder(_users[i], _tokenAddresses[i], _tokenIds[i], _expectedPriceInWeiEach[i], _profitTo[i], _sendNow[i]);
        }
        return output;
    }

    /*///////////////////////////////////////////////////////////////
                        WITHDRAW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows profitReceiver and bots to withdraw their fees
    /// @dev delete balances on withdrawal to free up storage
    function withdraw() external {
        // EFFECTS
        uint256 amount = balances[msg.sender];
        delete balances[msg.sender];
        // INTERACTIONS
        sendValue(payable(msg.sender), amount);
    }

    /*///////////////////////////////////////////////////////////////
                      HELPER FUNCTIONS
  //////////////////////////////////////////////////////////////*/

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

    /// @notice returns an open order for a given user and token address
    /// @param _user the users address
    /// @param _tokenAddress the address of the token
    function viewOrder(address _user, address _tokenAddress) external view returns (Order memory) {
        return orders[_user][_tokenAddress];
    }

    /// @notice returns the open orders for a given user and list of tokens
    /// @param _users the users address
    /// @param _tokenAddresses a list of token addresses
    function viewOrders(address[] memory _users, address[] memory _tokenAddresses) external view returns (Order[] memory) {
        Order[] memory output = new Order[](_users.length);
        for (uint256 i = 0; i < _users.length; i++) output[i] = orders[_users[i]][_tokenAddresses[i]];
        return output;
    }
}