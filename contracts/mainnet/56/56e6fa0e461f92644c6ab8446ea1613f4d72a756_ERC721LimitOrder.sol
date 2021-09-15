/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// See ArtBotter.io for a UI

interface IERC721 {
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
}

contract ERC721LimitOrder {
	struct Order {
		uint128 priceInWeiEach;
		uint128 quantity;
	}

	address public coordinator;
	address public profitReceiver;
	uint256 public botFeeBips; // fee paid by bots

	// user => token address => {priceInWeiEach, quantity}
	mapping(address => mapping(address => Order)) public orders;
	// bot => eth balance
	mapping(address => uint256) balances;

	event Action(address indexed user, address indexed tokenAddress, uint256 priceInWeiEach, uint256 quantity, string action, uint256 optionalTokenId);

	modifier onlyCoordinator() {
		require(msg.sender == coordinator, 'not Coordinator');
		_;
	}

	constructor(address _profitReceiver , uint256 _botFeeBips) {
		coordinator = msg.sender;
		profitReceiver = _profitReceiver;
		require(_botFeeBips <= 500, 'fee too high');
		botFeeBips = _botFeeBips;
	}

	// **************
	// USER FUNCTIONS
	// **************

    // users should place orders ONLY for token addresses that they trust
	function placeOrder(address _tokenAddress, uint128 _quantity) external payable {
		Order memory order = orders[msg.sender][_tokenAddress];
		require(order.quantity == 0, 'You already have an order for this token. Please cancel the existing order before making a new one.');
		uint128 priceInWeiEach = uint128(msg.value) / _quantity;
		require(priceInWeiEach > 0, 'Zero wei offers not accepted.');

		// EFFECTS
		orders[msg.sender][_tokenAddress].priceInWeiEach = priceInWeiEach;
		orders[msg.sender][_tokenAddress].quantity = _quantity;

		emit Action(msg.sender, _tokenAddress, priceInWeiEach, _quantity, 'order placed', 0);
	}

	function cancelOrder(address _tokenAddress) external {
		// CHECKS
		Order memory order = orders[msg.sender][_tokenAddress];
		uint256 amountToSendBack = order.priceInWeiEach * order.quantity;
		require(amountToSendBack != 0, 'You do not have an existing order for this token.');

		// EFFECTS
		delete orders[msg.sender][_tokenAddress];

		// INTERACTIONS
		sendValue(payable(msg.sender), amountToSendBack);

		emit Action(msg.sender, _tokenAddress, 0, 0, 'order cancelled', 0);
	}

	// *************
	// BOT FUNCTIONS
	// *************

	function fillOrder(address _user, address _tokenAddress, uint256 _tokenId, uint256 _expectedPriceInWeiEach, address _profitTo, bool _sendNow) public returns (uint256) {
		// CHECKS
		Order memory order = orders[_user][_tokenAddress];
		require(order.quantity > 0, 'user order DNE');
		require(order.priceInWeiEach >= _expectedPriceInWeiEach, 'user offer insufficient'); // protects bots from users frontrunning them

		// EFFECTS
		orders[_user][_tokenAddress].quantity = order.quantity - 1; // reverts on underflow
		uint256 botFee = order.priceInWeiEach * botFeeBips / 10_000;
		balances[profitReceiver] += botFee;

		// INTERACTIONS
		// transfer NFT to user (benign reentrancy possible here)
		IERC721(_tokenAddress).safeTransferFrom(msg.sender, _user, _tokenId); // ERC721-compliant contracts revert on failure here

		// pay the bot
		uint256 botPayment = order.priceInWeiEach - botFee;
		if (_sendNow) {
			sendValue(payable(_profitTo), botPayment);
		} else {
			balances[_profitTo] += botPayment;
		}

		emit Action(_user, _tokenAddress, order.priceInWeiEach, order.quantity - 1, 'order filled', _tokenId);

		return botPayment;
	}

	function fillMultipleOrders(address[] memory _users, address _tokenAddress, uint256[] memory _tokenIds, uint256[] memory _expectedPriceInWeiEach, address _profitTo, bool _sendNow) external returns (uint256[] memory) {
		require(_users.length == _tokenIds.length && _tokenIds.length == _expectedPriceInWeiEach.length, 'array length mismatch');
		uint256[] memory output = new uint256[](_users.length);
		for (uint256 i = 0; i < _users.length; i++) {
			output[i] = fillOrder(_users[i], _tokenAddress, _tokenIds[i], _expectedPriceInWeiEach[i], _profitTo, _sendNow);
		}
		return output;
	}
	
	function withdraw() external {
	    uint256 amountToSend = balances[msg.sender];
	    balances[msg.sender] = 0;
	    sendValue(payable(msg.sender), amountToSend);
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

	function changeBotFeeBips(uint256 _newBotFeeBips) external onlyCoordinator {
		require(_newBotFeeBips <= 500, 'fee cannot be greater than 5%');
		botFeeBips = _newBotFeeBips;
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

	function viewOrder(address _user, address _tokenAddress) external view returns (Order memory) {
		return orders[_user][_tokenAddress];
	}

	function viewOrders(address[] memory _users, address[] memory _tokenAddresses) external view returns (Order[] memory) {
		Order[] memory output = new Order[](_users.length);
		for (uint256 i = 0; i < _users.length; i++) output[i] = orders[_users[i]][_tokenAddresses[i]];
		return output;
	}

}