/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/YobotArtBlocksBroker.sol
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

////// src/external/IArtBlocksFactory.sol
/* pragma solidity ^0.8.6; */

interface IArtBlocksFactory {
    function tokenIdToProjectId(uint256 _tokenId) external view returns (uint256 projectId);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

////// src/YobotArtBlocksBroker.sol
/* pragma solidity ^0.8.6; */

/* solhint-disable max-line-length */

/* import {Coordinator} from "./Coordinator.sol"; */
/* import {IArtBlocksFactory} from "./external/IArtBlocksFactory.sol"; */

/// @title YobotArtBlocksBroker
/// @author Andreas Bigger <[email protected]> et al
/// @notice Broker enabling permissionless markets between flashbot
/// 				searchers and users attempting to mint ArtBlocks drops.
contract YobotArtBlocksBroker is Coordinator {
    IArtBlocksFactory public constant ARTBLOCKS_FACTORY = IArtBlocksFactory(0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270);

    /// @notice A user's order
    struct Order {
        /// @dev the price to pay for each erc721 token
        uint128 priceInWeiEach;
        /// @dev the quantity of tokens to pay
        uint128 quantity;
    }

    /// @dev user => projectID => Order
    mapping(address => mapping(uint256 => Order)) public orders;
    // bot => eth balance
    mapping(address => uint256) public balances;

    /// @notice Emitted whenever a respective individual executes a function
    /// @param _user the address of the sender executing the action - used primarily for indexing
    /// @param _artBlocksProjectId The Artblocks project Id
    /// @param _priceInWeiEach The bid price in wei for each ERC721 Token
    /// @param _quantity The number of tokens
    /// @param _action The action being emitted
    /// @param _optionalTokenId An optional specific token id
    event Action(address indexed _user, uint256 indexed _artBlocksProjectId, uint256 _priceInWeiEach, uint256 _quantity, string _action, uint256 _optionalTokenId);

    /// @notice Creates a new yobot erc721 limit order broker
    /// @param _profitReceiver The profit receiver for fees
    /// @param _botFeeBips The fee rake
    // solhint-disable-next-line no-empty-blocks
    constructor(address _profitReceiver, uint256 _botFeeBips) Coordinator(_profitReceiver, _botFeeBips) {}

    /*///////////////////////////////////////////////////////////////
                        USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice places an open order for a user
    /// @param _artBlocksProjectId the ArtBlocks Project Id
    /// @param _quantity the number of tokens
    function placeOrder(uint256 _artBlocksProjectId, uint128 _quantity) external payable {
        // CHECKS
        require(_artBlocksProjectId != 0, "INVALID_ARTBLOCKS_ID");

        // Removes user foot-guns and garuantees user can receive NFTs
        // We disable linting against tx-origin to purposefully allow EOA checks
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender == tx.origin, "NON_EOA_ORIGIN");

        Order memory order = orders[msg.sender][_artBlocksProjectId];
        require(order.priceInWeiEach * order.quantity == 0, "DUPLICATE_ORDER");
        uint128 priceInWeiEach = uint128(msg.value) / _quantity;
        require(priceInWeiEach > 0, "ZERO_WEI_BID");

        // EFFECTS
        orders[msg.sender][_artBlocksProjectId].priceInWeiEach = priceInWeiEach;
        orders[msg.sender][_artBlocksProjectId].quantity = _quantity;

        emit Action(msg.sender, _artBlocksProjectId, priceInWeiEach, _quantity, "ORDER_PLACED", 0);
    }

    /// @notice Cancels a user's order for the given ArtBlocks Project Id
    /// @param _artBlocksProjectId the ArtBlocks Project Id
    function cancelOrder(uint256 _artBlocksProjectId) external {
        // CHECKS
        require(_artBlocksProjectId != 0, "INVALID_ARTBLOCKS_ID");
        Order memory order = orders[msg.sender][_artBlocksProjectId];
        uint256 amountToSendBack = order.priceInWeiEach * order.quantity;
        require(amountToSendBack != 0, "NONEXISTANT_ORDER");

        // EFFECTS
        delete orders[msg.sender][_artBlocksProjectId];

        // INTERACTIONS
        sendValue(payable(msg.sender), amountToSendBack);

        emit Action(msg.sender, _artBlocksProjectId, 0, 0, "ORDER_CANCELLED", 0);
    }

    /*///////////////////////////////////////////////////////////////
                        BOT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice fill a single order
    /// @param _user the address of the user with the order
    /// @param _artBlocksProjectId the ArtBlocks Project Id
    /// @param _tokenId the token id to mint
    /// @param _expectedPriceInWeiEach the price to pay
    /// @param _profitTo the address to send the fee to
    /// @param _sendNow whether or not to send the fee now
    function fillOrder(
        address _user,
        uint256 _artBlocksProjectId,
        uint256 _tokenId,
        uint256 _expectedPriceInWeiEach,
        address _profitTo,
        bool _sendNow
    ) public returns (uint256) {
        // CHECKS
        Order memory order = orders[_user][_artBlocksProjectId];
        require(order.quantity > 0, "NO_OUTSTANDING_USER_ORDER");
        // Protects bots from users frontrunning them
        require(order.priceInWeiEach >= _expectedPriceInWeiEach, "INSUFFICIENT_EXPECTED_PRICE");
        require(ARTBLOCKS_FACTORY.tokenIdToProjectId(_tokenId) == _artBlocksProjectId, "UNREQUESTED_TOKEN_ID");

        // EFFECTS
        // TODO: remove newOrder entirely?
        Order memory newOrder;
        if (order.quantity > 1) {
            newOrder.priceInWeiEach = order.priceInWeiEach;
            newOrder.quantity = order.quantity - 1;
        }
        // else {
        // ?? ??
        // TODO: Delete orders from mapping once all are filled
        // }
        orders[_user][_artBlocksProjectId] = newOrder;

        uint256 artBlocksBrokerFee = (order.priceInWeiEach * botFeeBips) / 10_000;
        balances[profitReceiver] += artBlocksBrokerFee;

        // INTERACTIONS
        // Transfer NFT to user (benign reentrancy possible here)
        // ERC721-compliant contracts revert on failure here
        ARTBLOCKS_FACTORY.safeTransferFrom(msg.sender, _user, _tokenId);

        // Pay the bot with the remaining amount
        if (_sendNow) {
            sendValue(payable(_profitTo), order.priceInWeiEach - artBlocksBrokerFee);
        } else {
            balances[_profitTo] += order.priceInWeiEach - artBlocksBrokerFee;
        }

        // Emit the action later so we can log trace on a bot dashboard
        emit Action(_user, _artBlocksProjectId, newOrder.priceInWeiEach, newOrder.quantity, "ORDER_FILLED", _tokenId);

        // TODO: delete order ?

        // RETURN
        return order.priceInWeiEach - artBlocksBrokerFee; // proceeds to order fullfiller
    }

    /// @notice allows a bot to fill multiple outstanding orders
    /// @dev there should be one token id and token price specified for each users
    /// @dev So, _users.length == _tokenIds.length == _expectedPriceInWeiEach.length
    /// @param _users a list of users to fill orders for
    /// @param _artBlocksProjectId a list of ArtBlocks Project Ids
    /// @param _tokenIds a list of token ids
    /// @param _expectedPriceInWeiEach the price of each token
    /// @param _profitTo the addresses to send the bot's profit to
    /// @param _sendNow whether the profit should be sent immediately
    function fillMultipleOrders(
        address[] memory _users,
        uint256 _artBlocksProjectId,
        uint256[] memory _tokenIds,
        uint256[] memory _expectedPriceInWeiEach,
        address _profitTo,
        bool _sendNow
    ) external returns (uint256[] memory) {
        require(_users.length == _tokenIds.length && _tokenIds.length == _expectedPriceInWeiEach.length, "ARRAY_LENGTH_MISMATCH");
        uint256[] memory output = new uint256[](_users.length);
        for (uint256 i = 0; i < _users.length; i++) {
            output[i] = fillOrder(_users[i], _artBlocksProjectId, _tokenIds[i], _expectedPriceInWeiEach[i], _profitTo, _sendNow);
        }
        return output;
    }

    /// @notice allows a bot to fill multiple outstanding orders with
    /// @dev all argument array lengths should be equal
    /// @param _users a list of users to fill orders for
    /// @param _artBlocksProjectIds a list of ArtBlocks Project Ids
    /// @param _tokenIds a list of token ids
    /// @param _expectedPriceInWeiEach the price of each token
    /// @param _profitTo the addresses to send the bot's profit to
    /// @param _sendNow whether the profit should be sent immediately
    function fillMultipleOrdersUnOptimized(
        address[] memory _users,
        uint256[] memory _artBlocksProjectIds,
        uint256[] memory _tokenIds,
        uint256[] memory _expectedPriceInWeiEach,
        address[] memory _profitTo,
        bool[] memory _sendNow
    ) external returns (uint256[] memory) {
        // verify argument array lengths are equal
        require(_users.length == _artBlocksProjectIds.length && _artBlocksProjectIds.length == _tokenIds.length && _tokenIds.length == _expectedPriceInWeiEach.length && _expectedPriceInWeiEach.length == _profitTo.length && _profitTo.length == _sendNow.length, "ARRAY_LENGTH_MISMATCH");
        uint256[] memory output = new uint256[](_users.length);
        for (uint256 i = 0; i < _users.length; i++) {
            output[i] = fillOrder(_users[i], _artBlocksProjectIds[i], _tokenIds[i], _expectedPriceInWeiEach[i], _profitTo[i], _sendNow[i]);
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

    /// @notice returns an open order for a given user and ArtBlocks Project Id
    /// @param _user the users address
    /// @param _artBlocksProjectId the ArtBlocks Project Id
    function viewOrder(address _user, uint256 _artBlocksProjectId) external view returns (Order memory) {
        return orders[_user][_artBlocksProjectId];
    }

    /// @notice returns the open orders for a given user and list of ArtBlocks Project Ids
    /// @param _users the users address
    /// @param _artBlocksProjectIds a list of ArtBlocks Project Ids
    function viewOrders(address[] memory _users, uint256[] memory _artBlocksProjectIds) external view returns (Order[] memory) {
        Order[] memory output = new Order[](_users.length);
        for (uint256 i = 0; i < _users.length; i++) output[i] = orders[_users[i]][_artBlocksProjectIds[i]];
        return output;
    }
}