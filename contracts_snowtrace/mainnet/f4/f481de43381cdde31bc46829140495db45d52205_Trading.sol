// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./SafeERC20.sol";
import "./Address.sol";

import "./IRouter.sol";
import "./ITreasury.sol";
import "./IPool.sol";

contract Trading {

	// All amounts in 8 decimals unless otherwise indicated

	using SafeERC20 for IERC20;
    using Address for address payable;

	// Structs

	struct Product {
		uint64 maxLeverage; // set to 0 to deactivate product
		uint64 liquidationThreshold; // in bps. 8000 = 80%
		uint64 fee; // In sbps (10^6). 0.5% = 5000. 0.025% = 250
		uint64 interest; // For 360 days, in bps. 5.35% = 535
	}

	struct Position {
		uint64 size;
		uint64 margin;
		uint64 timestamp;
		uint64 price;
	}

	struct Order {
		bool isClose;
		uint64 size;
		uint64 margin;
	}

	// Contracts
	address public owner;
	address public router;
	address public treasury;
	address public oracle;

	uint256 public nextPositionId; // Incremental
	uint256 public nextCloseOrderId; // Incremental

	mapping(bytes32 => Product) private products;
	mapping(bytes32 => Position) private positions; // key = currency,user,product,direction
	mapping(bytes32 => Order) private orders; // position key => Order

	mapping(address => uint256) minMargin; // currency => amount

	mapping(address => uint256) pendingFees; // currency => amount

	uint256 public constant UNIT_DECIMALS = 8;
	uint256 public constant UNIT = 10**UNIT_DECIMALS;

	uint256 public constant PRICE_DECIMALS = 8;

	// Events
	event NewOrder(
		bytes32 indexed key,
		address indexed user,
		bytes32 indexed productId,
		address currency,
		bool isLong,
		uint256 margin,
		uint256 size,
		bool isClose
	);

	event PositionUpdated(
		bytes32 indexed key,
		address indexed user,
		bytes32 indexed productId,
		address currency,
		bool isLong,
		uint256 margin,
		uint256 size,
		uint256 price,
		uint256 fee
	);

	event ClosePosition(
		bytes32 indexed key,
		address indexed user,
		bytes32 indexed productId,
		address currency,
		bool isLong,
		uint256 price,
		uint256 margin,
		uint256 size,
		uint256 fee,
		int256 pnl,
		bool wasLiquidated
	);

	constructor() {
		owner = msg.sender;
	}

	// Governance methods

	function setOwner(address newOwner) external onlyOwner {
		owner = newOwner;
	}

	function setRouter(address _router) external onlyOwner {
		router = _router;
		treasury = IRouter(router).treasury();
		oracle = IRouter(router).oracle();
	}

	function setMinMargin(
		address currency,
		uint256 _minMargin
	) external onlyOwner {
		minMargin[currency] = _minMargin;
	}

	function addProduct(bytes32 productId, Product memory _product) external onlyOwner {
		
		Product memory product = products[productId];
		
		require(product.liquidationThreshold == 0, "!product-exists");
		require(_product.liquidationThreshold > 0, "!liqThreshold");

		products[productId] = Product({
			maxLeverage: _product.maxLeverage,
			fee: _product.fee,
			interest: _product.interest,
			liquidationThreshold: _product.liquidationThreshold
		});

	}

	function updateProduct(bytes32 productId, Product memory _product) external onlyOwner {

		Product storage product = products[productId];

		require(product.liquidationThreshold > 0, "!product-does-not-exist");

		product.maxLeverage = _product.maxLeverage;
		product.fee = _product.fee;
		product.interest = _product.interest;
		product.liquidationThreshold = _product.liquidationThreshold;

	}

	// Methods

	function distributeFees(address currency) external {
		uint256 pendingFee = pendingFees[currency];
		if (pendingFee > 0) {
			pendingFees[currency] = 0;
			_transferOut(currency, treasury, pendingFee);
			ITreasury(treasury).notifyFeeReceived(currency, pendingFee * 10**(18-UNIT_DECIMALS));
		}
	}

	function submitOrder(
		bytes32 productId,
		address currency,
		bool isLong,
		uint256 margin,
		uint256 size
	) external payable {

		if (currency == address(0)) { // User is sending AVAX
			margin = msg.value / 10**(18 - UNIT_DECIMALS);
		} else {
			require(IRouter(router).isSupportedCurrency(currency), "!currency");
		}

		// Check params
		require(margin > 0, "!margin");
		require(size > 0, "!size");

		bytes32 key = _getPositionKey(msg.sender, productId, currency, isLong);

		Order memory order = orders[key];
		require(order.size == 0, "!order"); // existing order

		Product memory product = products[productId];
		uint256 fee = size * product.fee / 10**6;

		if (currency == address(0)) {
			require(margin > fee, "!margin<fee");
			margin -= fee;
		} else {
			_transferIn(currency, margin + fee);
		}

		require(margin >= minMargin[currency], "!min-margin");

		uint256 leverage = UNIT * size / margin;
		require(leverage >= UNIT, "!leverage");
		require(leverage <= product.maxLeverage, "!max-leverage");

		// Update and check pool utlization
		_updateOpenInterest(currency, size, false);
		address pool = IRouter(router).getPool(currency);
		uint256 utilization = IPool(pool).getUtilization();
		require(utilization < 10**4, "!utilization");

		orders[key] = Order({
			isClose: false,
			size: uint64(size),
			margin: uint64(margin)
		});

		emit NewOrder(
			key,
			msg.sender,
			productId,
			currency,
			isLong,
			margin,
			size,
			false
		);

	}

	function submitCloseOrder(
		bytes32 productId,
		address currency,
		bool isLong,
		uint256 size
	) external payable {

		require(size > 0, "!size");

		bytes32 key = _getPositionKey(msg.sender, productId, currency, isLong);

		Order memory order = orders[key];
		require(order.size == 0, "!order"); // existing order

		// Check position
		Position storage position = positions[key];
		require(position.margin > 0, "!position");

		if (size > position.size) {
			size = position.size;
		}

		Product memory product = products[productId];
		uint256 fee = size * product.fee / 10**6;

		if (currency == address(0)) {
			uint256 fee_units = fee * 10**(18-UNIT_DECIMALS);
			require(msg.value >= fee_units && msg.value <= fee_units * (10**6 + 1)/10**6, "!fee");
		} else {
			_transferIn(currency, fee);
		}

		uint256 margin = size * uint256(position.margin) / uint256(position.size);

		orders[key] = Order({
			isClose: true,
			size: uint64(size),
			margin: uint64(margin)
		});

		emit NewOrder(
			key,
			msg.sender,
			productId,
			currency,
			isLong,
			margin,
			size,
			true
		);

	}

	function cancelOrder(
		bytes32 productId,
		address currency,
		bool isLong
	) external {

		bytes32 key = _getPositionKey(msg.sender, productId, currency, isLong);

		Order memory order = orders[key];
		require(order.size > 0, "!exists");

		Product memory product = products[productId];
		uint256 fee = order.size * product.fee / 10**6;

		_updateOpenInterest(currency, order.size, true);

		delete orders[key];

		// Refund margin + fee
		uint256 marginPlusFee = order.margin + fee;
		_transferOut(currency, msg.sender, marginPlusFee);

	}

	// Set price for newly submitted order (oracle)
	function settleOrder(
		address user,
		bytes32 productId,
		address currency,
		bool isLong,
		uint256 price
	) external onlyOracle {

		bytes32 key = _getPositionKey(user, productId, currency, isLong);

		Order storage order = orders[key];
		require(order.size > 0, "!exists");

		// fee
		Product memory product = products[productId];
		uint256 fee = order.size * product.fee / 10**6;
		pendingFees[currency] += fee;

		if (order.isClose) {
			
			{
				(uint256 margin, uint256 size, int256 pnl) = _settleCloseOrder(user, productId, currency, isLong, price);

				address pool = IRouter(router).getPool(currency);

				if (pnl < 0) {
					{
						uint256 positivePnl = uint256(-1 * pnl);
						_transferOut(currency, pool, positivePnl);
						if (positivePnl < margin) {
							_transferOut(currency, user, margin - positivePnl);
						}
					}
				} else {
					IPool(pool).creditUserProfit(user, uint256(pnl) * 10**(18-UNIT_DECIMALS));
					_transferOut(currency, user, margin);
				}

				_updateOpenInterest(currency, size, true);

				emit ClosePosition(
					key, 
					user,
					productId,
					currency,
					isLong,
					price,
					margin,
					size,
					fee,
					pnl,
					false
				);

			}

		} else {

			// Validate price, returns 8 decimals
			price = _validatePrice(price);

			Position storage position = positions[key];

			uint256 averagePrice = (uint256(position.size) * uint256(position.price) + uint256(order.size) * uint256(price)) / (uint256(position.size) + uint256(order.size));

			if (position.timestamp == 0) {
				position.timestamp = uint64(block.timestamp);
			}

			position.size += uint64(order.size);
			position.margin += uint64(order.margin);
			position.price = uint64(averagePrice);

			delete orders[key];

			emit PositionUpdated(
				key,
				user,
				productId,
				currency,
				isLong,
				position.margin,
				position.size,
				position.price,
				fee
			);

		}

	}

	function _settleCloseOrder(
		address user,
		bytes32 productId,
		address currency,
		bool isLong,
		uint256 price
	) internal returns(uint256, uint256, int256) {

		bytes32 key = _getPositionKey(user, productId, currency, isLong);

		// Check order and params
		Order memory order = orders[key];
		uint256 size = order.size;
		uint256 margin = order.margin;

		Position storage position = positions[key];
		require(position.margin > 0, "!position");

		Product memory product = products[productId];

		price = _validatePrice(price);

		int256 pnl = _getPnL(isLong, price, position.price, size, product.interest, position.timestamp);

		// Check if it's a liquidation
		if (pnl <= -1 * int256(uint256(position.margin) * uint256(product.liquidationThreshold) / 10**4)) {
			pnl = -1 * int256(uint256(position.margin));
			margin = position.margin;
			size = position.size;
			position.margin = 0;
		} else {
			position.margin -= uint64(margin);
			position.size -= uint64(size);
		}
		
		if (position.margin == 0) {
			delete positions[key];
		}

		delete orders[key];

		return (margin, size, pnl);

	}

	// Liquidate positionIds (oracle)
	function liquidatePosition(
		address user,
		bytes32 productId,
		address currency,
		bool isLong,
		uint256 price
	) external onlyOracle {

		bytes32 key = _getPositionKey(user, productId, currency, isLong);

		Position memory position = positions[key];

		if (position.margin == 0 || position.size == 0) {
			return;
		}

		Product storage product = products[productId];

		price = _validatePrice(price);

		int256 pnl = _getPnL(isLong, price, position.price, position.size, product.interest, position.timestamp);

		uint256 threshold = position.margin * product.liquidationThreshold / 10**4;

		if (pnl <= -1 * int256(threshold)) {

			uint256 fee = position.margin - threshold;
			address pool = IRouter(router).getPool(currency);

			_transferOut(currency, pool, threshold);
			_updateOpenInterest(currency, position.size, true);
			pendingFees[currency] += fee;

			emit ClosePosition(
				key, 
				user,
				productId,
				currency,
				isLong,
				price,
				position.margin,
				position.size,
				fee,
				-1 * int256(uint256(position.margin)),
				true
			);

			delete positions[key];

		}

	}

	function releaseMargin(
		address user,
		bytes32 productId,
		address currency,
		bool isLong, 
		bool includeFee
	) external onlyOwner {

		bytes32 key = _getPositionKey(user, productId, currency, isLong);

		Position storage position = positions[key];
		require(position.margin > 0, "!position");

		uint256 margin = position.margin;

		emit ClosePosition(
			key, 
			user,
			productId,
			currency,
			isLong,
			position.price,
			margin,
			position.size,
			0,
			0,
			false
		);

		delete orders[key];

		if (includeFee) {
			Product memory product = products[productId];
			uint256 fee = position.size * product.fee / 10**6;
			margin += fee;
		}

		_updateOpenInterest(currency, position.size, true);
		
		delete positions[key];

		_transferOut(currency, user, margin);

	}

	// To receive AVAX
	fallback() external payable {}
	receive() external payable {}

	// Internal methods

	function _getPositionKey(address user, bytes32 productId, address currency, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, productId, currency, isLong));
    }

	function _updateOpenInterest(address currency, uint256 amount, bool isDecrease) internal {
		address pool = IRouter(router).getPool(currency);
		IPool(pool).updateOpenInterest(amount * 10**(18 - UNIT_DECIMALS), isDecrease);
	}

	function _transferIn(address currency, uint256 amount) internal {
		if (amount == 0 || currency == address(0)) return;
		// adjust decimals
		uint256 decimals = IRouter(router).getDecimals(currency);
		amount = amount * (10**decimals) / (10**UNIT_DECIMALS);
		IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);
	}

	function _transferOut(address currency, address to, uint256 amount) internal {
		if (amount == 0 || to == address(0)) return;
		// adjust decimals
		uint256 decimals = IRouter(router).getDecimals(currency);
		amount = amount * (10**decimals) / (10**UNIT_DECIMALS);
		if (currency == address(0)) {
			payable(to).sendValue(amount);
		} else {
			IERC20(currency).safeTransfer(to, amount);
		}
	}

	function _validatePrice(
		uint256 price // 8 decimals
	) internal pure returns(uint256) {
		require(price > 0, "!price");
		return price * 10**(UNIT_DECIMALS - PRICE_DECIMALS);
	}
	
	function _getPnL(
		bool isLong,
		uint256 price,
		uint256 positionPrice,
		uint256 size,
		uint256 interest,
		uint256 timestamp
	) internal view returns(int256 _pnl) {

		bool pnlIsNegative;
		uint256 pnl;

		if (isLong) {
			if (price >= positionPrice) {
				pnl = size * (price - positionPrice) / positionPrice;
			} else {
				pnl = size * (positionPrice - price) / positionPrice;
				pnlIsNegative = true;
			}
		} else {
			if (price > positionPrice) {
				pnl = size * (price - positionPrice) / positionPrice;
				pnlIsNegative = true;
			} else {
				pnl = size * (positionPrice - price) / positionPrice;
			}
		}

		// Subtract interest from P/L
		if (block.timestamp >= timestamp + 15 minutes) {

			uint256 _interest = size * interest * (block.timestamp - timestamp) / (UNIT * 10**4 * 360 days);

			if (pnlIsNegative) {
				pnl += _interest;
			} else if (pnl < _interest) {
				pnl = _interest - pnl;
				pnlIsNegative = true;
			} else {
				pnl -= _interest;
			}

		}

		if (pnlIsNegative) {
			_pnl = -1 * int256(pnl);
		} else {
			_pnl = int256(pnl);
		}

		return _pnl;

	}

	// Getters

	function getProduct(bytes32 productId) external view returns(Product memory) {
		return products[productId];
	}

	function getPosition(
		address user,
		address currency,
		bytes32 productId,
		bool isLong
	) external view returns(Position memory position) {
		bytes32 key = _getPositionKey(user, productId, currency, isLong);
		return positions[key];
	}

	function getOrder(
		address user,
		address currency,
		bytes32 productId,
		bool isLong
	) external view returns(Order memory order) {
		bytes32 key = _getPositionKey(user, productId, currency, isLong);
		return orders[key];
	}

	function getOrders(bytes32[] calldata keys) external view returns(Order[] memory _orders) {
		uint256 length = keys.length;
		_orders = new Order[](length);
		for (uint256 i = 0; i < length; i++) {
			_orders[i] = orders[keys[i]];
		}
		return _orders;
	}

	function getPositions(bytes32[] calldata keys) external view returns(Position[] memory _positions) {
		uint256 length = keys.length;
		_positions = new Position[](length);
		for (uint256 i = 0; i < length; i++) {
			_positions[i] = positions[keys[i]];
		}
		return _positions;
	}

	function getPendingFee(address currency) external view returns(uint256) {
		return pendingFees[currency] * 10**(18-UNIT_DECIMALS);
	}

	// Modifiers

	modifier onlyOracle() {
		require(msg.sender == oracle, "!oracle");
		_;
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "!owner");
		_;
	}

}