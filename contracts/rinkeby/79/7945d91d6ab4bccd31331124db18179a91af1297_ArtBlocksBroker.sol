/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.2;

interface IArtBlocksFactory {
	function tokenIdToProjectId(uint256 _tokenId) external view returns (uint256 projectId);
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract ArtBlocksBroker {
	IArtBlocksFactory public constant ARTBLOCKS_FACTORY = IArtBlocksFactory(0x30436e30035a848b0d018342747502357de9837D);

	struct Order {
		uint128 priceInWeiEach;
		uint128 quantity;
	}

	// user => projectID => Order
	mapping(address => mapping(uint256 => Order)) public orders;
	mapping(address => uint256) public balances; // for bots

	address public coordinator;
	address public profitReceiver;
	uint256 public artBlocksBrokerFeeBips; // paid by bots, not users

	modifier onlyCoordinator() {
		require(msg.sender == coordinator, 'not Coordinator');
		_;
	}

	event Action(address indexed _user, uint256 indexed _artBlocksProjectId, uint256 _priceInWeiEach, uint256 _quantity, string _action, uint256 _optionalTokenId);

	constructor(address _profitReceiver , uint256 _artBlocksBrokerFeeBips) {
		coordinator = msg.sender;
		profitReceiver = _profitReceiver;
		require(_artBlocksBrokerFeeBips < 10_000, 'fee too high');
		artBlocksBrokerFeeBips = _artBlocksBrokerFeeBips;
	}

	// **************
	// USER FUNCTIONS
	// **************

	function placeOrder(uint256 _artBlocksProjectId, uint128 _quantity) external payable {
		// CHECKS
		require(_artBlocksProjectId != 0, 'invalid AB id');
		require(msg.sender == tx.origin, 'we only mint to EOAs'); // removes user foot-guns and garuantees user can receive NFTs
		Order memory order = orders[msg.sender][_artBlocksProjectId];
		require(order.priceInWeiEach * order.quantity == 0, 'You already have an order for this ArtBlocks project. Please cancel the existing order before making a new one.');
		uint128 priceInWeiEach = uint128(msg.value) / _quantity;
		require(priceInWeiEach > 0, 'Zero wei offers not accepted.');

		// EFFECTS
		orders[msg.sender][_artBlocksProjectId].priceInWeiEach = priceInWeiEach;
		orders[msg.sender][_artBlocksProjectId].quantity = _quantity;

		emit Action(msg.sender, _artBlocksProjectId, priceInWeiEach, _quantity, 'order placed', 0);
	}

	function cancelOrder(uint256 _artBlocksProjectId) external {
		// CHECKS
		Order memory order = orders[msg.sender][_artBlocksProjectId];
		uint256 amountToSendBack = order.priceInWeiEach * order.quantity;
		require(amountToSendBack != 0, 'You do not have an existing order for this ArtBlocks project.');

		// EFFECTS
		delete orders[msg.sender][_artBlocksProjectId];

		// INTERACTIONS
		sendValue(payable(msg.sender), amountToSendBack);

		emit Action(msg.sender, _artBlocksProjectId, 0, 0, 'order cancelled', 0);
	}

	// *************
	// BOT FUNCTIONS
	// *************

	function fulfillOrder(address _user, uint256 _artBlocksProjectId, uint256 _tokenId, uint256 _expectedPriceInWeiEach, address _profitTo, bool _sendNow) public returns (uint256) {
		// CHECKS
		Order memory order = orders[_user][_artBlocksProjectId];
		require(order.quantity > 0, 'user order DNE');
		require(order.priceInWeiEach >= _expectedPriceInWeiEach, 'user offer insufficient'); // protects bots from users frontrunning them
		require(ARTBLOCKS_FACTORY.tokenIdToProjectId(_tokenId) == _artBlocksProjectId, 'user did not request this NFT');

		// EFFECTS
		Order memory newOrder;
		if (order.quantity > 1) {
			newOrder.priceInWeiEach = order.priceInWeiEach;
			newOrder.quantity = order.quantity - 1;
		}
		orders[_user][_artBlocksProjectId] = newOrder;

		uint256 artBlocksBrokerFee = order.priceInWeiEach * artBlocksBrokerFeeBips / 10_000;
		balances[profitReceiver] += artBlocksBrokerFee;

		// INTERACTIONS
		// transfer NFT to user
		ARTBLOCKS_FACTORY.safeTransferFrom(msg.sender, _user, _tokenId); // reverts on failure

		// pay the fullfiller
		if (_sendNow) {
			sendValue(payable(_profitTo), order.priceInWeiEach - artBlocksBrokerFee);
		} else {
			balances[_profitTo] += order.priceInWeiEach - artBlocksBrokerFee;
		}

		emit Action(_user, _artBlocksProjectId, newOrder.priceInWeiEach, newOrder.quantity, 'order fulfilled', _tokenId);

		return order.priceInWeiEach - artBlocksBrokerFee; // proceeds to order fullfiller
	}

	function fulfillMultipleOrders(address[] memory _user, uint256[] memory _artBlocksProjectId, uint256[] memory _tokenId, uint256[] memory _expectedPriceInWeiEach, address[] memory _profitTo, bool[] memory _sendNow) external returns (uint256[] memory) {
		uint256[] memory output = new uint256[](_user.length);
		for (uint256 i = 0; i < _user.length; i++) {
			output[i] = fulfillOrder(_user[i], _artBlocksProjectId[i], _tokenId[i], _expectedPriceInWeiEach[i], _profitTo[i], _sendNow[i]);
		}
		return output;
	}

	// *********************
	// COORDINATOR FUNCTIONS
	// *********************

	function changeCoordinator(address _newCoordinator) external onlyCoordinator {
		coordinator = _newCoordinator;
	}

	function changeProfitReceiver(address _newProfitReceiver) external onlyCoordinator {
		profitReceiver = _newProfitReceiver;
	}

	function changeArtBlocksBrokerFeeBips(uint256 _newArtBlocksBrokerFeeBips) external onlyCoordinator {
		require(_newArtBlocksBrokerFeeBips < artBlocksBrokerFeeBips, 'fee can only ever be reduced');
		artBlocksBrokerFeeBips = _newArtBlocksBrokerFeeBips;
	}

	// ******************
	// WITHDRAW FUNCTIONS
	// ******************

	// for profitReceiver and bots
	function withdraw() external {
		uint256 amount = balances[msg.sender];
		delete balances[msg.sender];
		sendValue(payable(msg.sender), amount);
	}

	// ****************
	// HELPER FUNCTIONS
	// ****************

	// OpenZeppelin's sendValue function, used for transfering ETH out of this contract
	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");
		// solhint-disable-next-line avoid-low-level-calls, avoid-call-value
		(bool success, ) = recipient.call{ value: amount }("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}

	function viewOrder(address _user, uint256 _artBlocksProjectId) external view returns (Order memory) {
		return orders[_user][_artBlocksProjectId];
	}

	function viewOrders(address[] memory _users, uint256[] memory _artBlocksProjectIds) external view returns (Order[] memory) {
		Order[] memory output = new Order[](_users.length);
		for (uint256 i = 0; i < _users.length; i++) output[i] = orders[_users[i]][_artBlocksProjectIds[i]];
		return output;
	}
}