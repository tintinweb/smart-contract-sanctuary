// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./Initializable.sol";
import "./Ownable.sol";
import "./DuckExpressStorage.sol";
import "./DuckExpressConfig.sol";
import "./OrderModel.sol";
import "./OfferModel.sol";
import "./EnumerableMap.sol";

contract DuckExpress is OfferModel, OrderModel, DuckExpressStorage, Initializable, Ownable, DuckExpressConfig {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableMap for EnumerableMap.HashToOfferStatusMap;
    using EnumerableMap for EnumerableMap.AddressToSupportStateMap;

    // mapping (address => uint256) _nonces;
    // EnumerableMap.HashToOfferStatusMap _offerStatuses;
    // mapping (bytes32 => Offer) _offers;
    // mapping (bytes32 => Order) _orders;

    modifier onlyCustomer(bytes32 offerHash) {
        Offer storage offer = _offers[offerHash];
        require(msg.sender == offer.customerAddress, "DuckExpress: caller is not the offer creator");

        _;
    }

    modifier onlyAddressee(bytes32 offerHash) {
        Offer storage offer = _offers[offerHash];
        require(msg.sender == offer.addresseeAddress, "DuckExpress: caller is not the offer addressee");

        _;
    }

    modifier onlyCustomerOrAddressee(bytes32 offerHash) {
        Offer storage offer = _offers[offerHash];
        require(msg.sender == offer.customerAddress || msg.sender == offer.addresseeAddress, "DuckExpress: caller is neither the offer creator nor the offer addressee");

        _;
    }

    event DeliveryOfferCreated(address indexed customerAddress, address indexed addresseeAddress, bytes32 offerHash);
    event DeliveryOfferAccepted(address indexed customerAddress, address indexed addresseeAddress, address indexed courierAddress, bytes32 offerHash);
    event DeliveryOfferCanceled(address indexed customerAddress, address indexed addresseeAddress, bytes32 offerHash);
    event PackagePickedUp(address indexed customerAddress, address indexed addresseeAddress, address indexed courierAddress, bytes32 offerHash);
    event PackageDelivered(address indexed addresseeAddress, address indexed courierAddress, bytes32 indexed offerHash);
    event PackageReturned(address indexed customerAddress, address indexed courierAddress, bytes32 indexed offerHash);
    event DeliveryRefused(address indexed customerAddress, address indexed addresseeAddress, address indexed courierAddress, bytes32 offerHash);
    event DeliveryFailed(address indexed customerAddress, address indexed addresseeAddress, address indexed courierAddress, bytes32 offerHash);
    event CollateralClaimed(address indexed customerAddress, address indexed courierAddress, bytes32 offerHash);

    // INITIALIZERS

    constructor(address initialOwner) {
        __Ownable_init_unchained(initialOwner);
    }

    function initialize(address initialOwner, uint256 minDeliveryTime) public initializer {
        __Ownable_init_unchained(initialOwner);
        __DuckExpress_init_unchained(minDeliveryTime);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __DuckExpress_init_unchained(uint256 minDeliveryTime) internal {
        _setMinDeliveryTime(minDeliveryTime);
    }

    // MAIN METHODS

    function createDeliveryOffer(Offer calldata offer) external {
        require(isTokenSupported(offer.tokenAddress), "DuckExpress: the ERC20 loan token is not supported");
        require(_nonces[msg.sender] == offer.nonce, "DuckExpress: incorrect nonce");
        require(offer.customerAddress == msg.sender, "DuckExpress: customer address must be your address");
        require(offer.addresseeAddress != address(0), "DuckExpress: addressee address cannot be zero address");
        require(offer.pickupAddress != "", "DuckExpress: the pickup address must be set");
        require(offer.deliveryAddress != "", "DuckExpress: the delivery address must be set");
        require(offer.deliveryTime >= _minDeliveryTime, "DuckExpress: the delivery time cannot be lesser than the minimal delivery time");
        require(offer.reward > 0, "DuckExpress: the reward must be greater than 0");
        require(offer.collateral > 0, "DuckExpress: the collateral must be greater than 0");

        IERC20(offer.tokenAddress).safeTransferFrom(msg.sender, address(this), offer.reward);

        bytes32 offerHash = hashOffer(offer);

        _offerStatuses.set(offerHash, EnumerableMap.OfferStatus.AVAILABLE);
        _offers[offerHash] = offer;
        _nonces[msg.sender] += 1;

        emit DeliveryOfferCreated(msg.sender, offer.addresseeAddress, offerHash);
    }

    function acceptDeliveryOffer(bytes32 offerHash) external {
        require(offerStatus(offerHash) == EnumerableMap.OfferStatus.AVAILABLE, "DuckExpress: the offer is unavailable");

        Offer storage offer = _offers[offerHash];

        IERC20(offer.tokenAddress).safeTransferFrom(msg.sender, address(this), offer.collateral);

        _offerStatuses.set(offerHash, EnumerableMap.OfferStatus.ACCEPTED);

        _orders[offerHash] = Order({
            offer: offer,
            status: OrderStatus.AWAITING_PICK_UP,
            courierAddress: msg.sender,
            creationTimestamp: block.timestamp,
            lastUpdateTimestamp: block.timestamp
        });

        emit DeliveryOfferAccepted(offer.customerAddress, offer.addresseeAddress, msg.sender, offerHash);
    }

    function cancelDeliveryOffer(bytes32 offerHash) external onlyCustomer(offerHash) {
        require(offerStatus(offerHash) == EnumerableMap.OfferStatus.AVAILABLE, "DuckExpress: the offer is unavailable");

        _offerStatuses.set(offerHash, EnumerableMap.OfferStatus.CANCELED);

        emit DeliveryOfferCanceled(msg.sender, _offers[offerHash].addresseeAddress, offerHash);
    }

    function confirmPickUp(bytes32 offerHash) external onlyCustomer(offerHash) {
        require(offerStatus(offerHash) == EnumerableMap.OfferStatus.ACCEPTED, "DuckExpress: the offer is unavailable");
        Order storage order = _orders[offerHash];
        require(order.offer.customerAddress == msg.sender, "DuckExpress: you are not the creator of this offer");
        require(order.status == OrderStatus.AWAITING_PICK_UP, "DuckExpress: invalid order status");

        order.status = OrderStatus.PICKED_UP;
        order.lastUpdateTimestamp = block.timestamp;
        _orders[offerHash] = order;

        emit PackagePickedUp(msg.sender, order.offer.addresseeAddress, order.courierAddress, offerHash);
    }

    function confirmDelivery(bytes32 offerHash) external onlyCustomerOrAddressee(offerHash) {
        require(offerStatus(offerHash) == EnumerableMap.OfferStatus.ACCEPTED, "DuckExpress: the offer is unavailable");
        Order storage order = _orders[offerHash];
        require(order.status == OrderStatus.PICKED_UP || order.status == OrderStatus.REFUSED, "DuckExpress: invalid order status");
        order.lastUpdateTimestamp = block.timestamp;

        if (order.status == OrderStatus.PICKED_UP) {
            require(order.offer.addresseeAddress == msg.sender, "DuckExpress: caller is not the offer addressee");

            bool isDeliveryLate = block.timestamp >= deliveryDeadline(offerHash);

            if (isDeliveryLate) {
                order.status = OrderStatus.DELIVERED_LATE;
            } else {
                order.status = OrderStatus.DELIVERED;
            }

            _orders[offerHash] = order;
            IERC20 token = IERC20(order.offer.tokenAddress);

            if (isDeliveryLate) {
                uint256 customerReward = order.offer.reward.div(2);
                uint256 courierReward = order.offer.reward.sub(customerReward);

                token.safeTransfer(order.courierAddress, courierReward + order.offer.collateral);
                token.safeTransfer(order.offer.customerAddress, customerReward);
            } else {
                token.safeTransfer(order.courierAddress, order.offer.reward + order.offer.collateral);
            }

            emit PackageDelivered(order.offer.addresseeAddress, order.courierAddress, offerHash);
        } else {
            require(order.offer.customerAddress == msg.sender, "DuckExpress: caller is not the offer creator");

            order.status = OrderStatus.RETURNED;
            _orders[offerHash] = order;
            IERC20 token = IERC20(order.offer.tokenAddress);

            token.safeTransfer(order.courierAddress, order.offer.reward + order.offer.collateral);

            emit PackageReturned(order.offer.customerAddress, order.courierAddress, offerHash);
        }
    }

    function refuseDelivery(bytes32 offerHash) external onlyCustomerOrAddressee(offerHash) {
        require(offerStatus(offerHash) == EnumerableMap.OfferStatus.ACCEPTED, "DuckExpress: the offer is unavailable");
        Order storage order = _orders[offerHash];
        require(order.status == OrderStatus.PICKED_UP || order.status == OrderStatus.REFUSED, "DuckExpress: invalid order status");
        order.lastUpdateTimestamp = block.timestamp;

        if (order.status == OrderStatus.PICKED_UP) {
            require(order.offer.addresseeAddress == msg.sender, "DuckExpress: caller is not the offer addressee");

            order.status = OrderStatus.REFUSED;
            _orders[offerHash] = order;

            emit DeliveryRefused(order.offer.customerAddress, order.offer.addresseeAddress, order.courierAddress, offerHash);
        } else {
            require(order.offer.customerAddress == msg.sender, "DuckExpress: caller is not the offer creator");

            order.status = OrderStatus.FAILED;
            _orders[offerHash] = order;
            IERC20 token = IERC20(order.offer.tokenAddress);

            token.safeTransfer(order.offer.customerAddress, order.offer.reward + order.offer.collateral);

            emit DeliveryFailed(order.offer.customerAddress, order.offer.addresseeAddress, order.courierAddress, offerHash);
        }
    }

    function claimCollateral(bytes32 offerHash) external onlyCustomer(offerHash) {
        require(offerStatus(offerHash) == EnumerableMap.OfferStatus.ACCEPTED, "DuckExpress: the offer is unavailable");
        Order storage order = _orders[offerHash];
        require(order.offer.customerAddress == msg.sender, "DuckExpress: caller is not the offer creator");
        require(order.status == OrderStatus.PICKED_UP, "DuckExpress: invalid order status");
        require(block.timestamp >= deliveryDeadline(offerHash), "DuckExpress: the delivery time has not passed yet");

        order.status = OrderStatus.CLAIMED;
        order.lastUpdateTimestamp = block.timestamp;
        _orders[offerHash] = order;
        IERC20 token = IERC20(order.offer.tokenAddress);

        token.safeTransfer(order.offer.customerAddress, order.offer.reward + order.offer.collateral);

        emit CollateralClaimed(order.offer.customerAddress, order.courierAddress, offerHash);
    }

    // HELPERS

    function hashOffer(Offer calldata offer) public pure returns (bytes32) {
        return keccak256(abi.encode(
            offer.nonce,
            offer.customerAddress,
            offer.addresseeAddress,
            offer.pickupAddress,
            offer.deliveryAddress,
            offer.deliveryTime,
            offer.tokenAddress,
            offer.reward,
            offer.collateral
        ));
    }

    // GETTERS

    function customerNonce(address customer) external view returns (uint256) {
        return _nonces[customer];
    }

    function deliveryDeadline(bytes32 offerHash) public view returns (uint256) {
        require(offerStatus(offerHash) == EnumerableMap.OfferStatus.ACCEPTED, "DuckExpress: no order with provided hash");
        Order storage _order = _orders[offerHash];

        return _order.creationTimestamp.add(_order.offer.deliveryTime);
    }

    function offerStatus(bytes32 offerHash) public view returns (EnumerableMap.OfferStatus) {
        require(_offerStatuses.contains(offerHash), "DuckExpress: no offer with provided hash");
        return _offerStatuses.get(offerHash);
    }

    function offers() public view returns (EnumerableMap.HashWithOfferStatus[] memory) {
        uint256 offersTotal = EnumerableMap.length(_offerStatuses);

        EnumerableMap.HashWithOfferStatus[] memory allOffers = new EnumerableMap.HashWithOfferStatus[](offersTotal);

        for (uint256 i = 0; i < offersTotal; i++) {
            bytes32 currentHash;
            EnumerableMap.OfferStatus currentStatus;
            (currentHash, currentStatus) = EnumerableMap.at(_offerStatuses, i);
            EnumerableMap.HashWithOfferStatus memory newOffer = EnumerableMap.HashWithOfferStatus({
                offerHash: currentHash,
                offerStatus: currentStatus
            });
            allOffers[i] = newOffer;
        }

        return allOffers;
    }

    function offer(bytes32 offerHash) external view returns (Offer memory) {
        require(offerStatus(offerHash) != EnumerableMap.OfferStatus.ACCEPTED, "DuckExpress: no offer with provided hash");
        return _offers[offerHash];
    }

    function order(bytes32 offerHash) external view returns (Order memory) {
        require(offerStatus(offerHash) == EnumerableMap.OfferStatus.ACCEPTED, "DuckExpress: no order with provided hash");
        return _orders[offerHash];
    }
}