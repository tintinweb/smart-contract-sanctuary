// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

import "./ownership/Operator.sol";
import "./lifecycle/Pausable.sol";
import "./token/ERC721Full.sol";
import "./libraries/SafeERC20.sol";

contract FastyToken is Operator, Pausable, ERC721Full {
    using SafeERC20 for IERC20;

    string public constant name = "Fasty";
    string public constant symbol = "FTY";
    uint256 public constant SYSTEM_FEE_COEFF = 1000; // 1x percent, 1000 = 100%

    struct Order {
        // Order ID - in uuid format
        uint128 id;
        // List of product IDs will be exchanged in this order
        uint128[] productIds;
        // The order maker (in this app it's always seller)
        address maker;
        // The order taker (in this app it's always buyer)
        address taker;
        // The seller's desired currencies. This is actually ERC20 contract address
        // For Ethereum as currency, will use special address 0x0
        address[] offeredCurrencies;
        // The seller's desired amount for each currency respestively
        uint256[] offeredAmounts;
        // The currency that buyer uses to fulfill the order
        address fulfilledCurrency;
        // The amount that buyer uses to fulfill the order
        uint256 fulfilledAmount;
        // The type of order
        OrderType otype;
        // The status of order
        OrderStatus status;
    }

    enum OrderStatus {OPEN, HOLDING, FULFILLED, CANCELLED}

    struct SystemFee {
        uint128 id;
        // % fasty fee per transaction
        uint256 fastyFee;
    }

    enum OrderType {OrderIndividual, OrderBundle}

    // storage product id
    mapping(uint128 => bytes32) private _nameOfProducts;
    // storage orders
    mapping(uint128 => Order) private _orders;
    // storage land id in order
    mapping(uint128 => uint128) private _goodIdOfOrders;
    // storage the order holder
    mapping(uint128 => address) private _orderHolders;
    // storage the processed txid
    mapping(string => bool) private _processedTxids;
    // storage the system fees
    mapping(uint128 => SystemFee) private _systemFees;
    // storage the order system fee
    mapping(uint128 => uint128) private _orderFees;

    // fire when receive token
    event Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes data,
        uint256 gas
    );
    // fire when a new order is created
    event OrderCreate(address operator, uint128 indexed orderId);
    // fire when seller want to update order price, selling method, fee
    event OrderUpdate(address operator, uint128 indexed orderId);
    // fire when seller cancel order
    event OrderCancelled(address operator, uint128 indexed orderId);
    // fire when buyer want to buy order by ether
    event OrderHolding(address holder, uint128 indexed orderId);
    // fire when the operator compelte order
    event OrderFulfilled(address operator, uint128 indexed orderId);
    // // fire when a new system fee is created
    event SystemFeeCreate(address operator, uint128 feeId);
    // // fire when the owner want to withdrawal ETH or ERC20
    // event Withdrawal(address operator, address recepient, address currency, uint256 amount);
    // fire when the operator want to refund ETH or ERC20 to buyer
    event Refund(
        address receiver,
        uint128 orderId,
        address currency,
        uint256 amount
    );

    constructor(string memory _name, string memory _symbol)
        public
        ERC721Full(_name, _symbol)
    {
        _addWhitelist(address(this));
    }

    /**
     * ========================================================================================
     * [GET] product
     */
    /**
     * @dev returns the product detail
     * @param id the product id
     * return product detail
     */
    function getProductDetail(uint128 id)
        external
        view
        returns (
            uint128 productId,
            bytes32 lname,
            address owner
        )
    {
        productId = id;
        lname = _nameOfProducts[productId];
        owner = ownerOf(productId);
    }

    /**
     * @dev check the token id has already exists
     * @param id the token id
     * @return bool whether the call correctly returned the expected magic value
     */
    function hasExistentToken(uint128 id) external view returns (bool) {
        return _exists(id);
    }

    /**
     * ========================================================================================
     * [SET] Product
     */
    /**
     * @dev the internal method to issue new product
     * @param _owner the owner of the product
     * @param _id the product id
     * @param _name the product name
     */
    function _issueNewProduct(
        address _owner,
        uint128 _id,
        bytes32 _name
    ) internal {
        require(_name.length != 0, "FTY: invalid productName");

        _nameOfProducts[_id] = _name;

        _mint(_owner, _id);
    }

    /**
     * @dev issue all lands of the specific bundle
     * @param _owner the owner of the land
     * @param _ids the array of land id
     * @param _names the array of land name
     */
    function issueNewProducts(
        address _owner,
        uint128[] calldata _ids,
        bytes32[] calldata _names
    ) external onlyOwner whenNotPaused {
        require(_ids.length == _names.length, "FTY: invalid array length");
        for (uint256 i = 0; i != _ids.length; i++) {
            _issueNewProduct(_owner, _ids[i], _names[i]);
        }
    }

    /**
     * ========================================================================================
     * [GET] Order
     */
    /**
     * @dev returns the order detail
     * @param _orderId the order id
     * return the product detail
     */
    function getOrderDetails(uint128 _orderId)
        external
        view
        returns (
            uint128 id,
            uint128[] memory productIds,
            address maker,
            address taker,
            address[] memory offeredCurrencies,
            uint256[] memory offeredAmounts,
            address fulfilledCurrency,
            uint256 fulfilledAmount,
            OrderType otype,
            OrderStatus status
        )
    {
        Order memory order = _orders[_orderId];
        id = order.id;
        productIds = order.productIds;
        maker = order.maker;
        taker = order.taker;
        offeredCurrencies = order.offeredCurrencies;
        offeredAmounts = order.offeredAmounts;
        fulfilledCurrency = order.fulfilledCurrency;
        fulfilledAmount = order.fulfilledAmount;
        otype = order.otype;
        status = order.status;
    }

    /**
     * @dev returns the system fee in the order
     * @param _orderId the order id
     * return the system fee id
     */
    function getOrderSystemFeeId(uint128 _orderId)
        external
        view
        returns (uint128 feeId)
    {
        return _orderFees[_orderId];
    }

    /**
     * @dev check order id has already exists
     * @param _orderId the order id
     * @return bool whether the call correctly returned the expected magic value
     */
    function hasExistentOrder(uint128 _orderId) external view returns (bool) {
        return _orders[_orderId].id != 0;
    }

    /**
     * ========================================================================================
     * [SET] Order
     */
    function _preValidateOrder(
        uint128 _orderId,
        uint128 _goodId,
        address[] memory _offeredCurrencies,
        uint256[] memory _offeredAmounts
    ) internal view {
        require(_orderId != 0, "FTY: invalid orderId");
        require(_orders[_orderId].id == 0, "FTY: order has already exists");
        require(_goodId != 0, "FTY: invalid goodId");
        require(
            _offeredCurrencies.length == _offeredAmounts.length,
            "FTY: invalid array length"
        );
    }

    /**
     * @dev the internal method to create new order
     * @param _orderId the order id
     * @param _productIds the array of the product id
     * @param _offeredCurrencies the array of the offered currency
     * @param _offeredAmounts the array of the offered amount
     */
    function _createOrder(
        uint128 _orderId,
        uint128[] memory _productIds,
        address[] memory _offeredCurrencies,
        uint256[] memory _offeredAmounts,
        OrderType _type
    ) internal {
        _orders[_orderId] = Order(
            _orderId,
            _productIds,
            msg.sender,
            address(0),
            _offeredCurrencies,
            _offeredAmounts,
            address(0),
            0,
            _type,
            OrderStatus.OPEN
        );
 
        emit OrderCreate(msg.sender, _orderId);
    }

    /**
     * @dev using for issue and create land bundle order
     * @param _orderId the order id
     * @param _productId the array of the product id
     * @param _productName the array of the product name
     * @param _offeredCurrencies the array of the offered currency
     * @param _offeredAmounts the array of the offered amount
     */
    function issueAndCreateSingleProductOrder(
        uint128 _orderId,
        uint128 _productId,
        bytes32 _productName,
        address[] calldata _offeredCurrencies,
        uint256[] calldata _offeredAmounts
    ) external onlyOwner whenNotPaused {
        uint128[] memory _productIds = new uint128[](1);
        _productIds[0] = _productId;
        _issueNewProduct(address(this), _productId, _productName);
        
        _preValidateOrder(
            _orderId,
            _productId,
            _offeredCurrencies,
            _offeredAmounts
        );

        _createOrder(
            _orderId,
            _productIds,
            _offeredCurrencies,
            _offeredAmounts,
            OrderType.OrderIndividual
        );
    }

    /**
     * @dev using for create a new order to sell single product
     * @param _orderId the order id
     * @param _productId the product id
     * @param _offeredCurrencies the array of the offered currency
     * @param _offeredAmounts the array of the offered amount
     */
    function createSingleProductOrder(
        uint128 _orderId,
        uint128 _productId,
        address[] calldata _offeredCurrencies,
        uint256[] calldata _offeredAmounts
    ) external whenNotPaused {
        uint128[] memory _productIds = new uint128[](1);
        _productIds[0] = _productId;

        _preValidateOrder(
            _orderId,
            _productId,
            _offeredCurrencies,
            _offeredAmounts
        );

        transferFrom(msg.sender, address(this), _productId);

        _createOrder(
            _orderId,
            _productIds,
            _offeredCurrencies,
            _offeredAmounts,
            OrderType.OrderIndividual
        );
    }

    /**
     * @dev using for update order price, selling method
     * @param _orderId the order id
     * @param _offeredCurrencies the array of the offered currency
     * @param _offeredAmounts the array of the offered amount
     */
    function updateOrder(
        uint128 _orderId,
        address[] calldata _offeredCurrencies,
        uint256[] calldata _offeredAmounts
    ) external whenNotPaused {
        Order storage order = _orders[_orderId];
        require(order.id != 0, "FTY: caller query nonexistent order");
        require(msg.sender == order.maker, "FTY: only maker can update order");
        require(
            order.status == OrderStatus.OPEN,
            "FTY: order not allow to update"
        );
        require(
            _offeredCurrencies.length == _offeredAmounts.length,
            "FTY: invalid array length"
        );

        order.offeredCurrencies = _offeredCurrencies;
        order.offeredAmounts = _offeredAmounts;

        emit OrderUpdate(msg.sender, order.id);
    }

    /**
     * @dev using for cancel order
     * @param _orderId the order id
     */
    function cancelOrder(uint128 _orderId) external whenNotPaused {
        Order storage order = _orders[_orderId];
        require(order.id != 0, "FTY: caller query nonexistent order");
        require(msg.sender == order.maker, "FTY: only maker can cancel order");
        require(
            order.status == OrderStatus.OPEN,
            "FTY: order not allow to cancel"
        );

        if (order.otype == OrderType.OrderIndividual) {
            IERC721(address(this)).safeTransferFrom(
                address(this),
                order.maker,
                order.productIds[0]
            );
        } else if (order.otype == OrderType.OrderBundle) {
            _batchSafeTransferFrom(
                address(this),
                address(this),
                order.maker,
                order.productIds
            );
        }
        order.status = OrderStatus.CANCELLED;

        emit OrderCancelled(msg.sender, order.id);
    }

    /**
     * @dev buyer can take order by staking ether
     * @param _orderId the order id
     */
    function takeOrderByEther(uint128 _orderId) external payable whenNotPaused {
        Order storage order = _orders[_orderId];
        require(order.id != 0, "FTY: caller query nonexistent order");
        require(order.maker != msg.sender, "FTY: you are owner");
        if (order.status == OrderStatus.OPEN) {
            uint256 _amount = 0;
            for (uint256 i = 0; i != order.offeredCurrencies.length; i++) {
                if (order.offeredCurrencies[i] == address(0)) {
                    _amount = order.offeredAmounts[i];
                    break;
                }
            }
            require(
                _amount != 0 && msg.value == _amount,
                "FTY: invalid amount"
            );

            order.status = OrderStatus.HOLDING;
            _orderHolders[_orderId] = msg.sender;

            emit OrderHolding(msg.sender, order.id);
        } else {
            // refund ether to buyer
            msg.sender.transfer(msg.value);
            emit Refund(msg.sender, _orderId, address(0), msg.value);
        }
    }

    /**
     * @dev using for complete the order by the system operator
     * @param _orderId the order id
     * @param _taker the buyer address
     * @param _currency the payable currency
     * @param _amount the payable amount
     * @param _txid the taken txid
     */
    function completeOrder(
        uint128 _orderId,
        address _taker,
        address _currency,
        uint256 _amount,
        string calldata _txid
    ) external whenNotPaused {
        require(isOperator(msg.sender), "FTY: caller is not operator");
        require(_taker != address(0), "FTY: invalid address");
        if (_orderHolders[_orderId] != address(0)) {
            require(_taker == _orderHolders[_orderId], "FTY: invalid taker");
        }
        Order storage order = _orders[_orderId];
        require(order.id != 0, "FTY: caller query nonexistent order");
        require(order.maker != _taker, "FTY: you are owner");
        require(
            order.status == OrderStatus.OPEN ||
                order.status == OrderStatus.HOLDING,
            "FTY: cannot complete this order"
        );
        require(!_processedTxids[_txid], "FTY: txid has processed");

        uint256 amount = 0;
        for (uint256 i = 0; i != order.offeredCurrencies.length; i++) {
            if (_currency == order.offeredCurrencies[i]) {
                amount = order.offeredAmounts[i];
                break;
            }
        }
        require(amount != 0 && amount == _amount, "FTY: invalid amount");


        // The transfer amount equals the offer amount
        if (_currency == address(0)) {
            // Transfer ether to the seller
            order.maker.toPayable().transfer(amount);
        } else {
            // Transfer erc20 token to the seller
            IERC20(_currency).safeTransfer(order.maker, amount);
        }

        // Transfer the land to buyer
        if (order.otype == OrderType.OrderIndividual) {
            IERC721(address(this)).safeTransferFrom(
                address(this),
                _taker,
                order.productIds[0]
            );
        } else if (order.otype == OrderType.OrderBundle) {
            _batchSafeTransferFrom(
                address(this),
                address(this),
                _taker,
                order.productIds
            );
        }

        order.taker = _taker;
        order.fulfilledCurrency = _currency;
        order.fulfilledAmount = amount;
        order.status = OrderStatus.FULFILLED;

        _orderHolders[_orderId] = _taker;
        _processedTxids[_txid] = true;
        emit OrderFulfilled(msg.sender, order.id);
    }

    /**
     * ========================================================================================
     * [GET] System Fee
     * @dev returns the system fee
     * @param _feeId the system fee id
     * return the system fee detail
     */
    function getSystemFee(uint128 _feeId)
        external
        view
        returns (uint128 feeId, uint256 fastyFee)
    {
        feeId = _systemFees[_feeId].id;
        fastyFee = _systemFees[_feeId].fastyFee;
    }

    /**
     * ========================================================================================
     * [SET] System Fee
     */
    /**
     * @dev using for set a new system fee
     * @param _feeId the system fee id
     * @param _fastyFee the fasty fee percentage
     */
    function setNewSystemFee(uint128 _feeId, uint256 _fastyFee)
        external
        onlyOwner
        whenNotPaused
    {
        require(_feeId != 0, "FTY: invalid feeId");
        require(_systemFees[_feeId].id == 0, "FTY: fee has already exists");

        _systemFees[_feeId] = SystemFee(_feeId, _fastyFee);
        emit SystemFeeCreate(msg.sender, _feeId);
    }

    /**
     * ========================================================================================
     * [SET] Withdrawal & Refund
     */
    /**
     * @dev the internal method used to withdrawal ETH or ERC20
     * @param _recepient the receiver address
     * @param _currency the withdrawal currency (can be ETH or ERC20)
     * @param _amount the withdrawl amount
     */
    function _withdrawal(
        address _recepient,
        address _currency,
        uint256 _amount
    ) internal {
        require(_recepient != address(0), "FTY: invalid address");
        require(_amount != 0, "FTY: invalid amount");
        if (_currency == address(0)) {
            require(
                address(this).balance >= _amount,
                "FTY: balance not enough"
            );
            _recepient.toPayable().transfer(_amount);
        } else {
            uint256 balance = IERC20(_currency).balanceOf(address(this));
            require(balance >= _amount, "FTY: balance not enough");
            IERC20(_currency).safeTransfer(_recepient, _amount);
        }
    }

    /**
     * @dev the operator can use to refund ETH or ERC20 to buyer
     * @param _orderId the refund order id
     * @param _recepient the receiver address
     * @param _currency the refund currency (can be ETH or ERC20)
     * @param _amount the refund amount
     */
    function refund(
        uint128 _orderId,
        address _recepient,
        address _currency,
        uint256 _amount
    ) external whenNotPaused {
        require(isOperator(msg.sender), "FTY: caller is not operator");
        require(
            _orders[_orderId].id != 0,
            "FTY: caller query nonexistent order"
        );
        _withdrawal(_recepient, _currency, _amount);
        emit Refund(_recepient, _orderId, _currency, _amount);
    }

    function _batchSafeTransferFrom(
        address _token,
        address _from,
        address _recepient,
        uint128[] memory _productIds
    ) internal {
        uint256 lengthOfProducts = _productIds.length;
        for (uint256 i = 0; i != lengthOfProducts; i++) {
            if (_token != address(0)) {
                IERC721(_token).safeTransferFrom(
                    _from,
                    _recepient,
                    _productIds[i]
                );
            } else {
                safeTransferFrom(_from, _recepient, _productIds[i]);
            }
        }
    }

    /**
     * ========================================================================================
     * [SET] Override ERC721Metadata
     */
    function setTokenURI(uint256 tokenId, string calldata _tokenURI)
        external
        onlyOwner
    {
        super._setTokenURI(tokenId, _tokenURI);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        super._setBaseURI(baseURI);
    }
}

pragma solidity 0.5.17;

import "./Ownable.sol";
import "../libraries/Roles.sol";

contract Operator is Ownable {
    using Roles for Roles.Role;

    Roles.Role private _operators;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    modifier onlyOperator() {
        require(isOperator(msg.sender), "caller does not have the Operator role");
        _;
    }

    constructor() public {
        _addOperator(msg.sender);
    }

    function isOperator(address _account) public view returns (bool) {
        return _operators.has(_account);
    }

    function addOperator(address _account) public onlyOwner {
        _addOperator(_account);
    }

    function removeOperator(address _account) public onlyOwner {
        _removeOperator(_account);
    }

    function renounceOperator() public {
        _removeOperator(msg.sender);
    }

    function _addOperator(address _account) internal {
        _operators.add(_account);
        emit OperatorAdded(_account);
    }

    function _removeOperator(address _account) internal {
        _operators.remove(_account);
        emit OperatorRemoved(_account);
    }
}

pragma solidity 0.5.17;

import "../ownership/Ownable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Ownable {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor() internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

pragma solidity 0.5.17;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Metadata.sol";
import "./ERC721Pausable.sol";
import "../validation/ERC721Whitelist.sol";

/**
 * @title Full ERC721 Token
 * @dev This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology.
 *
 * See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata, ERC721Pausable, ERC721Whitelist {
    constructor(string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
}

pragma solidity 0.5.17;

import "../interfaces/IERC20.sol";
import "./SafeMath.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        // TODO: implement later
        // require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.5.17;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = msg.sender;
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity 0.5.17;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage _role, address _account) internal {
        require(!has(_role, _account), "Roles: account already has role");
        _role.bearer[_account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage _role, address _account) internal {
        require(has(_role, _account), "Roles: account does not have role");
        _role.bearer[_account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage _role, address _account) internal view returns (bool) {
        require(_account != address(0), "Roles: account is the zero address");
        return _role.bearer[_account];
    }
}

pragma solidity 0.5.17;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Receiver.sol";
import "../libraries/SafeMath.sol";
import "../libraries/Address.sol";
import "../libraries/Counters.sol";
import "./ERC165.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping(uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping(address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor() public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use {_burn} instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This is an internal detail of the `ERC721` contract and its use is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(
            abi.encodeWithSelector(IERC721Receiver(to).onERC721Received.selector, msg.sender, from, tokenId, _data)
        );
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }

    /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

pragma solidity 0.5.17;

import "../interfaces/IERC721Enumerable.sol";
import "./ERC721.sol";
import "./ERC165.sol";

/**
 * @title ERC-721 Non-Fungible Token with optional enumeration extension logic
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Constructor function.
     */
    constructor() public {
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens.
     * @param index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to address the beneficiary that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use {ERC721-_burn} instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

pragma solidity 0.5.17;

import "./ERC165.sol";
import "./ERC721.sol";
import "../interfaces/IERC721Metadata.sol";

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Base URI
    string private _baseURI;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /**
     * @dev Constructor function
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the URI for a given token ID. May return an empty string.
     *
     * If the token's URI is non-empty and a base URI was set (via
     * {_setBaseURI}), it will be added to the token ID's URI as a prefix.
     *
     * Reverts if the token ID does not exist.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // Even if there is a base URI, it is only appended to non-empty token-specific URIs
        if (bytes(_tokenURI).length == 0) {
            return "";
        } else {
            // abi.encodePacked is being used to concatenate strings
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     *
     * Reverts if the token ID does not exist.
     *
     * TIP: if all token IDs share a prefix (e.g. if your URIs look like
     * `http://api.myproject.com/token/<id>`), use {_setBaseURI} to store
     * it and save gas.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI}.
     *
     * _Available since v2.5.0._
     */
    function _setBaseURI(string memory baseURI) internal {
        _baseURI = baseURI;
    }

    /**
     * @dev Returns the base URI set via {_setBaseURI}. This will be
     * automatically added as a preffix in {tokenURI} to each token's URI, when
     * they are non-empty.
     *
     * _Available since v2.5.0._
     */
    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

pragma solidity 0.5.17;

import "./ERC721.sol";
import "../lifecycle/Pausable.sol";

/**
 * @title ERC721 Non-Fungible Pausable token
 * @dev ERC721 modified with pausable transfers.
 */
contract ERC721Pausable is ERC721, Pausable {
    function approve(address to, uint256 tokenId) public whenNotPaused {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address to, bool approved) public whenNotPaused {
        super.setApprovalForAll(to, approved);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal whenNotPaused {
        super._transferFrom(from, to, tokenId);
    }
}

pragma solidity 0.5.17;

import "../ownership/Whitelist.sol";
import "../token/ERC721.sol";

contract ERC721Whitelist is ERC721, Whitelist {
    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(isWhitelist(from) || isWhitelist(to), "ERC721Whitelist: Sender or recipient does not belong to the whitelist role");
        super._transferFrom(from, to, tokenId);
    }
}

pragma solidity 0.5.17;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;

    function approve(address to, uint256 tokenId) public;

    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;

    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public;
}

pragma solidity 0.5.17;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4);
}

pragma solidity 0.5.17;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.5.17;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity 0.5.17;

import "./SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

pragma solidity 0.5.17;

import "../interfaces/IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

pragma solidity 0.5.17;

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

pragma solidity 0.5.17;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

pragma solidity 0.5.17;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity 0.5.17;

import "./Ownable.sol";
import "../libraries/Roles.sol";

contract Whitelist is Ownable {
    using Roles for Roles.Role;

    Roles.Role private _whitelists;

    event WhitelistAdded(address indexed account);
    event WhitelistRemoved(address indexed account);

    modifier onlyWhitelist() {
        require(isWhitelist(msg.sender), "caller does not have the Whitelisted");
        _;
    }

    function isWhitelist(address _account) public view returns (bool) {
        return _whitelists.has(_account);
    }

    function addWhitelist(address _account) public onlyOwner {
        _addWhitelist(_account);
    }

    function removeWhitelist(address _account) public onlyOwner {
        _removeWhitelist(_account);
    }

    function renounceWhitelist() public {
        _removeWhitelist(msg.sender);
    }

    function _addWhitelist(address _account) internal {
        _whitelists.add(_account);
        emit WhitelistAdded(_account);
    }

    function _removeWhitelist(address _account) internal {
        _whitelists.remove(_account);
        emit WhitelistRemoved(_account);
    }
}

pragma solidity 0.5.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

