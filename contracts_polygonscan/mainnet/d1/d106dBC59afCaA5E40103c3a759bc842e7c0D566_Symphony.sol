// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./libraries/PercentageMath.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IHandler.sol";
import "./interfaces/IYieldAdapter.sol";
import "./interfaces/IOrderStructs.sol";
import "./interfaces/IAaveIncentivesController.sol";

contract Symphony is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using PercentageMath for uint256;

    // Protocol treasury address
    address public treasury;

    // Emergency admin address
    address public emergencyAdmin;

    /// Total fee (protocol_fee + relayer_fee)
    uint256 public BASE_FEE; // 1 for 0.01%

    /// Protocol fee: BASE_FEE - RELAYER_FEE
    uint256 public PROTOCOL_FEE_PERCENT;

    /// Oracle
    IOracle public oracle;

    mapping(address => address) public strategy;
    mapping(bytes32 => bytes32) public orderHash;
    mapping(address => uint256) public assetBuffer;

    mapping(address => bool) public isWhitelistAsset;
    mapping(address => bool) public isRegisteredHandler;
    mapping(address => uint256) public totalAssetShares;

    // ************** //
    // *** EVENTS *** //
    // ************** //
    event AssetRebalanced(address asset);
    event OrderCreated(bytes32 orderId, bytes data);
    event OrderCancelled(bytes32 orderId);
    event OrderExecuted(bytes32 orderId, address executor);
    event OrderUpdated(bytes32 oldOrderId, bytes32 newOrderId, bytes data);
    event AssetStrategyUpdated(address asset, address strategy);
    event HandlerAdded(address handler);
    event HandlerRemoved(address handler);
    event UpdatedBaseFee(uint256 fee);
    event UpdatedBufferPercentage(address asset, uint256 percent);
    event AddedWhitelistAsset(address asset);
    event RemovedWhitelistAsset(address asset);

    modifier onlyEmergencyAdminOrOwner() {
        require(
            _msgSender() == emergencyAdmin || _msgSender() == owner(),
            "Symphony: Only emergency admin or owner can invoke this function"
        );
        _;
    }

    /**
     * @notice To initalize the global variables
     */
    function initialize(
        address _owner,
        address _emergencyAdmin,
        uint256 _baseFee,
        IOracle _oracle
    ) external initializer {
        BASE_FEE = _baseFee;
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        super.transferOwnership(_owner);
        emergencyAdmin = _emergencyAdmin;
        oracle = _oracle;
    }

    /**
     * @notice Create an order
     */
    function createOrder(
        address recipient,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 minReturnAmount,
        uint256 stoplossAmount
    ) external nonReentrant whenNotPaused returns (bytes32 orderId) {
        require(
            inputAmount > 0,
            "Symphony::createOrder: Input amount can't be zero"
        );
        require(
            minReturnAmount > 0,
            "Symphony::createOrder: Amount out can't be zero"
        );
        require(
            isWhitelistAsset[inputToken],
            "Symphony::createOrder: Input asset not in whitelist"
        );
        require(
            stoplossAmount < minReturnAmount,
            "Symphony::createOrder: stoploss amount should be less than amount out"
        );

        orderId = getOrderId(
            recipient,
            inputToken,
            outputToken,
            inputAmount,
            minReturnAmount,
            stoplossAmount
        );

        require(
            orderHash[orderId] == bytes32(0),
            "Symphony::createOrder: There is already an existing order with same id"
        );

        uint256 shares = _calculateShares(inputToken, inputAmount);

        uint256 balanceBefore = IERC20(inputToken).balanceOf(address(this));
        IERC20(inputToken).safeTransferFrom(
            msg.sender,
            address(this),
            inputAmount
        );
        require(
            IERC20(inputToken).balanceOf(address(this)) ==
                inputAmount + balanceBefore,
            "Symphony::createOrder: tokens not transferred"
        );

        uint256 prevTotalAssetShares = totalAssetShares[inputToken];
        totalAssetShares[inputToken] = prevTotalAssetShares.add(shares);

        bytes memory encodedOrder = abi.encode(
            recipient,
            inputToken,
            outputToken,
            inputAmount,
            minReturnAmount,
            stoplossAmount,
            shares
        );

        orderHash[orderId] = keccak256(encodedOrder);

        emit OrderCreated(orderId, encodedOrder);

        address assetStrategy = strategy[inputToken];

        if (assetStrategy != address(0)) {
            rebalanceAsset(inputToken);

            IYieldAdapter(assetStrategy).setOrderRewardDebt(
                orderId,
                inputToken,
                shares,
                prevTotalAssetShares
            );
        }
    }

    /**
     * @notice Update an existing order
     */
    function updateOrder(
        bytes32 orderId,
        bytes calldata _orderData,
        address _receiver,
        address _outputToken,
        uint256 _minReturnAmount,
        uint256 _stoplossAmount
    ) external nonReentrant whenNotPaused {
        require(
            orderHash[orderId] == keccak256(_orderData),
            "Symphony::updateOrder: Order doesn't match"
        );

        IOrderStructs.Order memory myOrder = decodeOrder(_orderData);

        require(
            msg.sender == myOrder.recipient,
            "Symphony::updateOrder: Only recipient can update the order"
        );

        require(
            _minReturnAmount > 0,
            "Symphony::createOrder: Amount out can't be zero"
        );

        require(
            _stoplossAmount < _minReturnAmount,
            "Symphony::createOrder: stoploss amount should be less than amount out"
        );

        delete orderHash[orderId];

        bytes32 newOrderId = getOrderId(
            _receiver,
            myOrder.inputToken,
            _outputToken,
            myOrder.inputAmount,
            _minReturnAmount,
            _stoplossAmount
        );

        require(
            orderHash[newOrderId] == bytes32(0),
            "Symphony::updateOrder: There is already an existing order with same id"
        );

        bytes memory encodedOrder = abi.encode(
            _receiver,
            myOrder.inputToken,
            _outputToken,
            myOrder.inputAmount,
            _minReturnAmount,
            _stoplossAmount,
            myOrder.shares
        );

        orderHash[newOrderId] = keccak256(encodedOrder);

        emit OrderUpdated(orderId, newOrderId, encodedOrder);
    }

    /**
     * @notice Cancel an existing order
     */
    function cancelOrder(bytes32 orderId, bytes calldata _orderData)
        external
        payable
        nonReentrant
    {
        require(
            orderHash[orderId] == keccak256(_orderData),
            "Symphony::cancelOrder: Order doesn't match"
        );

        IOrderStructs.Order memory myOrder = decodeOrder(_orderData);

        require(
            msg.sender == myOrder.recipient,
            "Symphony::cancelOrder: Only recipient can cancel the order"
        );

        uint256 totalTokens = getTotalFunds(myOrder.inputToken);

        uint256 depositPlusYield = _calculateTokenFromShares(
            myOrder.inputToken,
            myOrder.shares,
            totalTokens
        );

        uint256 totalSharesInAsset = totalAssetShares[myOrder.inputToken];

        totalAssetShares[myOrder.inputToken] = totalSharesInAsset.sub(
            myOrder.shares
        );

        delete orderHash[orderId];
        emit OrderCancelled(orderId);

        if (strategy[myOrder.inputToken] != address(0)) {
            _calcAndwithdrawFromStrategy(
                myOrder,
                depositPlusYield,
                totalTokens,
                totalSharesInAsset,
                orderId
            );
        }

        IERC20(myOrder.inputToken).safeTransfer(msg.sender, depositPlusYield);
    }

    /**
     * @notice Execute the order using external DEX
     */
    function executeOrder(
        bytes32 orderId,
        bytes calldata _orderData,
        address payable _handler,
        bytes memory _handlerData
    ) external nonReentrant whenNotPaused {
        require(
            isRegisteredHandler[_handler],
            "Symphony::executeOrder: Handler doesn't exists"
        );
        require(
            orderHash[orderId] == keccak256(_orderData),
            "Symphony::executeOrder: Order doesn't match"
        );

        IOrderStructs.Order memory myOrder = decodeOrder(_orderData);

        uint256 totalTokens = getTotalFunds(myOrder.inputToken);

        uint256 depositPlusYield = _calculateTokenFromShares(
            myOrder.inputToken,
            myOrder.shares,
            totalTokens
        );

        uint256 totalSharesInAsset = totalAssetShares[myOrder.inputToken];

        totalAssetShares[myOrder.inputToken] = totalSharesInAsset.sub(
            myOrder.shares
        );

        delete orderHash[orderId];

        emit OrderExecuted(orderId, msg.sender);

        if (strategy[myOrder.inputToken] != address(0)) {
            _calcAndwithdrawFromStrategy(
                myOrder,
                depositPlusYield,
                totalTokens,
                totalSharesInAsset,
                orderId
            );
        }

        if (depositPlusYield < myOrder.inputAmount) {
            myOrder.inputAmount = depositPlusYield;
        }

        IERC20(myOrder.inputToken).safeTransfer(_handler, myOrder.inputAmount);

        (, uint256 oracleAmount) = oracle.get(
            myOrder.inputToken,
            myOrder.outputToken,
            myOrder.inputAmount
        );

        IHandler(_handler).handle(
            myOrder,
            oracleAmount,
            BASE_FEE,
            PROTOCOL_FEE_PERCENT,
            msg.sender,
            treasury,
            _handlerData
        );

        if (depositPlusYield > myOrder.inputAmount) {
            uint256 yieldEarned = depositPlusYield.sub(myOrder.inputAmount);
            IERC20(myOrder.inputToken).safeTransfer(
                myOrder.recipient,
                yieldEarned
            );
        }
    }

    /**
     * @notice Fill an order with own liquidity
     */
    function fillOrder(
        bytes32 orderId,
        bytes calldata _orderData,
        uint256 quoteAmount
    ) external nonReentrant whenNotPaused {
        require(
            orderHash[orderId] == keccak256(_orderData),
            "Symphony::fillOrder: Order doesn't match"
        );

        IOrderStructs.Order memory myOrder = decodeOrder(_orderData);

        uint256 totalTokens = getTotalFunds(myOrder.inputToken);

        uint256 depositPlusYield = _calculateTokenFromShares(
            myOrder.inputToken,
            myOrder.shares,
            totalTokens
        );

        uint256 totalSharesInAsset = totalAssetShares[myOrder.inputToken];

        totalAssetShares[myOrder.inputToken] = totalSharesInAsset.sub(
            myOrder.shares
        );

        (uint256 oracleAmount, ) = oracle.get(
            myOrder.inputToken,
            myOrder.outputToken,
            myOrder.inputAmount
        );

        bool success = ((quoteAmount >= myOrder.minReturnAmount ||
            quoteAmount <= myOrder.stoplossAmount) &&
            quoteAmount >= oracleAmount);

        require(success, "Symphony::fillOrder: Fill condition doesn't satisfy");

        delete orderHash[orderId];

        emit OrderExecuted(orderId, msg.sender);

        if (strategy[myOrder.inputToken] != address(0)) {
            _calcAndwithdrawFromStrategy(
                myOrder,
                depositPlusYield,
                totalTokens,
                totalSharesInAsset,
                orderId
            );
        }

        uint256 totalFee = quoteAmount.percentMul(BASE_FEE);

        // caution: external calls to unknown address
        IERC20(myOrder.outputToken).safeTransferFrom(
            msg.sender,
            myOrder.recipient,
            quoteAmount.sub(totalFee)
        );

        if (PROTOCOL_FEE_PERCENT > 0 && treasury != address(0)) {
            uint256 protocolFee = totalFee.percentMul(PROTOCOL_FEE_PERCENT);

            IERC20(myOrder.outputToken).safeTransferFrom(
                msg.sender,
                treasury,
                protocolFee
            );
        }

        IERC20(myOrder.inputToken).safeTransfer(
            msg.sender,
            myOrder.inputAmount
        );

        if (depositPlusYield > myOrder.inputAmount) {
            uint256 yieldEarned = depositPlusYield.sub(myOrder.inputAmount);
            IERC20(myOrder.inputToken).safeTransfer(
                myOrder.recipient,
                yieldEarned
            );
        }
    }

    /**
     * @notice rebalance asset according to buffer percent
     */
    function rebalanceAsset(address asset) public whenNotPaused {
        require(
            strategy[asset] != address(0),
            "Symphony::rebalanceAsset: Rebalance needs some strategy"
        );

        uint256 balanceInContract = IERC20(asset).balanceOf(address(this));

        uint256 balanceInStrategy = IYieldAdapter(strategy[asset])
            .getTotalUnderlying(asset);

        uint256 totalBalance = balanceInContract.add(balanceInStrategy);

        uint256 bufferBalanceNeeded = totalBalance.percentMul(
            assetBuffer[asset]
        );

        emit AssetRebalanced(asset);

        if (balanceInContract > bufferBalanceNeeded) {
            IYieldAdapter(strategy[asset]).deposit(
                asset,
                balanceInContract.sub(bufferBalanceNeeded)
            );
        } else if (balanceInContract < bufferBalanceNeeded) {
            IYieldAdapter(strategy[asset]).withdraw(
                asset,
                bufferBalanceNeeded.sub(balanceInContract),
                0,
                0,
                address(0),
                bytes32(0)
            );
        }
    }

    // *************** //
    // *** GETTERS *** //
    // *************** //

    function getOrderId(
        address _recipient,
        address _inputToken,
        address _outputToken,
        uint256 _amount,
        uint256 _minReturnAmount,
        uint256 _stoplossAmount
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _recipient,
                    _inputToken,
                    _outputToken,
                    _amount,
                    _minReturnAmount,
                    _stoplossAmount
                )
            );
    }

    function getTotalFunds(address asset)
        public
        view
        returns (uint256 totalBalance)
    {
        totalBalance = IERC20(asset).balanceOf(address(this));

        if (strategy[asset] != address(0)) {
            totalBalance = totalBalance.add(
                IYieldAdapter(strategy[asset]).getTotalUnderlying(asset)
            );
        }
    }

    function decodeOrder(bytes memory _data)
        public
        view
        returns (IOrderStructs.Order memory order)
    {
        (
            address recipient,
            address inputToken,
            address outputToken,
            uint256 inputAmount,
            uint256 minReturnAmount,
            uint256 stoplossAmount,
            uint256 shares
        ) = abi.decode(
                _data,
                (address, address, address, uint256, uint256, uint256, uint256)
            );

        order = IOrderStructs.Order(
            recipient,
            inputToken,
            outputToken,
            inputAmount,
            minReturnAmount,
            stoplossAmount,
            shares
        );
    }

    // ************************** //
    // *** GOVERNANCE METHODS *** //
    // ************************** //

    /**
     * @notice Update the treasury address
     */
    function updateTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    /**
     * @notice Add an order handler
     */
    function addHandler(address _handler) external onlyOwner {
        isRegisteredHandler[_handler] = true;
        emit HandlerAdded(_handler);
    }

    /**
     * @notice Remove an order handler
     */
    function removeHandler(address _handler) external onlyOwner {
        isRegisteredHandler[_handler] = false;
        emit HandlerRemoved(_handler);
    }

    /**
     * @notice Update base execution fee
     */
    function updateBaseFee(uint256 _fee) external onlyOwner {
        BASE_FEE = _fee;
        emit UpdatedBaseFee(_fee);
    }

    /**
     * @notice Update protocol fee
     */
    function updateProtocolFee(uint256 _feePercent) external onlyOwner {
        PROTOCOL_FEE_PERCENT = _feePercent;
    }

    /**
     * @notice Update the oracle
     */
    function updateOracle(IOracle _oracle) external onlyOwner {
        oracle = _oracle;
    }

    /**
     * @notice Add an asset into whitelist
     */
    function addWhitelistAsset(address _asset) external onlyOwner {
        isWhitelistAsset[_asset] = true;
        AddedWhitelistAsset(_asset);
    }

    /**
     * @notice Remove a whitelisted asset
     */
    function removeWhitelistAsset(address _asset) external onlyOwner {
        isWhitelistAsset[_asset] = false;
        RemovedWhitelistAsset(_asset);
    }

    /**
     * @notice Update strategy
     */
    function updateStrategy(address _asset, address _strategy)
        external
        onlyOwner
    {
        require(
            strategy[_asset] != _strategy,
            "Symphony::updateStrategy: Strategy shouldn't be same."
        );
        _updateAssetStrategy(_asset, _strategy);
    }

    /**
     * @notice Migrate to new strategy
     */
    function migrateStrategy(
        address asset,
        address newStrategy,
        bytes calldata data
    ) external onlyOwner {
        address previousStrategy = strategy[asset];
        require(
            previousStrategy != address(0),
            "Symphony::migrateStrategy: no strategy for asset exists!!"
        );
        require(
            previousStrategy != newStrategy,
            "Symphony::migrateStrategy: new startegy shouldn't be same!!"
        );

        IYieldAdapter(previousStrategy).withdrawAll(asset, data);

        if (newStrategy != address(0)) {
            _updateAssetStrategy(asset, newStrategy);
        } else {
            strategy[asset] = newStrategy;
        }
    }

    // *************************** //
    // **** EMERGENCY METHODS **** //
    // *************************** //

    /**
     * @notice Pause the contract
     */
    function pause() external onlyEmergencyAdminOrOwner {
        _pause();
    }

    /*symphony*
     * @notice Unpause the contract
     */
    function unpause() external onlyEmergencyAdminOrOwner {
        _unpause();
    }

    /**
     * @notice Withdraw all assets from strategies including rewards
     * @dev Only in emergency case. Transfer rewards to symphony contract
     */
    function emergencyWithdrawFromStrategy(
        address[] calldata assets,
        bytes calldata data
    ) external onlyEmergencyAdminOrOwner {
        for (uint256 i = 0; i < assets.length; i++) {
            address asset = assets[i];
            address assetStrategy = strategy[asset];

            IYieldAdapter(assetStrategy).withdrawAll(asset, data);
        }
    }

    /**
     * @notice Update asset buffer percentage
     */
    function updateBufferPercentage(address _asset, uint256 _value)
        external
        onlyEmergencyAdminOrOwner
    {
        require(
            _value <= 10000,
            "symphony::updateBufferPercentage: not correct buffer percent."
        );
        assetBuffer[_asset] = _value;
        emit UpdatedBufferPercentage(_asset, _value);
        rebalanceAsset(_asset);
    }

    /**
     * @notice Update emergency admin address
     */
    function updateEmergencyAdmin(address _emergencyAdmin) external {
        require(
            _msgSender() == emergencyAdmin,
            "Symphony: Only emergency admin can invoke this function"
        );
        emergencyAdmin = _emergencyAdmin;
    }

    // ************************** //
    // *** INTERNAL FUNCTIONS *** //
    // ************************** //

    function _calculateShares(address _token, uint256 _amount)
        internal
        view
        returns (uint256 shares)
    {
        if (totalAssetShares[_token] > 0) {
            shares = _amount.mul(totalAssetShares[_token]).div(
                getTotalFunds(_token)
            );
            require(
                shares > 0,
                "Symphony::_calculateShares: shares can't be 0"
            );
        } else {
            shares = _amount;
        }
    }

    function _calculateTokenFromShares(
        address _token,
        uint256 _shares,
        uint256 totalTokens
    ) internal view returns (uint256 amount) {
        amount = _shares.mul(totalTokens).div(totalAssetShares[_token]);
    }

    function _calcAndwithdrawFromStrategy(
        IOrderStructs.Order memory myOrder,
        uint256 orderAmount,
        uint256 totalTokens,
        uint256 totalSharesInAsset,
        bytes32 orderId
    ) internal {
        address asset = myOrder.inputToken;
        uint256 leftBalanceAfterOrder = totalTokens.sub(orderAmount);

        uint256 neededAmountInBuffer = leftBalanceAfterOrder.percentMul(
            assetBuffer[asset]
        );

        uint256 bufferAmount = IERC20(asset).balanceOf(address(this));

        uint256 amountToWithdraw = 0;
        if (bufferAmount < orderAmount.add(neededAmountInBuffer)) {
            amountToWithdraw = orderAmount.add(neededAmountInBuffer).sub(
                bufferAmount
            );
        }

        emit AssetRebalanced(asset);

        IYieldAdapter(strategy[asset]).withdraw(
            asset,
            amountToWithdraw,
            myOrder.shares,
            totalSharesInAsset,
            myOrder.recipient,
            orderId
        );
    }

    /**
     * @notice Update Strategy of an asset
     */
    function _updateAssetStrategy(address _asset, address _strategy) internal {
        // max approve token
        if (
            _strategy != address(0) &&
            IERC20(_asset).allowance(address(this), _strategy) == 0
        ) {
            emit AssetStrategyUpdated(_asset, _strategy);

            // caution: external call to unknown address
            IERC20(_asset).safeApprove(_strategy, uint256(-1));
            IYieldAdapter(_strategy).maxApprove(_asset);

            strategy[_asset] = _strategy;
            rebalanceAsset(_asset);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.4;

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
    uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
    uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

    /**
     * @dev Executes a percentage multiplication
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The percentage of value
     **/
    function percentMul(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        if (value == 0 || percentage == 0) {
            return 0;
        }

        require(
            value <= (type(uint256).max - HALF_PERCENT) / percentage,
            "PercentageMath: MATH_MULTIPLICATION_OVERFLOW"
        );

        return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
    }

    /**
     * @dev Executes a percentage division
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The value divided the percentage
     **/
    function percentDiv(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        require(percentage != 0, "PercentageMath: MATH_DIVISION_BY_ZERO");
        uint256 halfPercentage = percentage / 2;

        require(
            value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
            "PercentageMath: MATH_MULTIPLICATION_OVERFLOW"
        );

        return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IOracle {
    function get(
        address inputToken,
        address outputToken,
        uint256 inputAmount
    ) external view returns (uint256 amountOut, uint256 amountOutWithSlippage);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOrderStructs.sol";

interface IHandler {
    /// @notice receive ETH
    receive() external payable;

    /**
     * @notice Handle an order execution
     * @param _order - Order structure
     * @param _oracleAmount - Current out amount from oracle
     * @param _feePercent - uint256 total execution fee percent
     * @param _protocolFeePercent - uint256 protocol fee percent
     * @param _executor - Address of the order executor
     * @param _treasury - Address of the protocol treasury
     * @param _data - Bytes of arbitrary data
     */
    function handle(
        IOrderStructs.Order memory _order,
        uint256 _oracleAmount,
        uint256 _feePercent,
        uint256 _protocolFeePercent,
        address _executor,
        address _treasury,
        bytes calldata _data
    ) external;

    /**
     * @notice Simulate an order execution
     * @param _inputToken - Address of the input token
     * @param _outputToken - Address of the output token
     * @param _inputAmount - uint256 of the input token amount
     * @param _minReturnAmount - uint256 minimum return output token
     * @param _stoplossAmount - uint256 stoploss amount
     * @param _oracleAmount - Current out amount from oracle
     * @param _data - Bytes of arbitrary data
     * @return success - Whether the execution can be handled or not
     * @return amountOut - Amount of output token bought
     */
    function simulate(
        address _inputToken,
        address _outputToken,
        uint256 _inputAmount,
        uint256 _minReturnAmount,
        uint256 _stoplossAmount,
        uint256 _oracleAmount,
        bytes calldata _data
    ) external view returns (bool success, uint256 amountOut);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.4;

interface IYieldAdapter {
    /**
     * @dev emitted when tokens are deposited
     * @param investedTo the address of contract to invest in
     * @param sharesReceived the amount of shares received
     **/
    event Deposit(address investedTo, uint256 sharesReceived);

    /**
     * @dev emitted when tokens are withdrawn
     * @param investedTo the address of contract invested in
     * @param tokensReceived the amount of underlying asset received
     **/
    event Withdraw(address investedTo, uint256 tokensReceived);

    /**
     * @dev Used to deposit token
     * @param asset the address of token to invest
     * @param amount the amount of asset
     **/
    function deposit(address asset, uint256 amount) external;

    /**
     * @dev Used to withdraw from available protocol
     * @param asset the address of underlying token
     * @param amount the amount of liquidity shares to unlock
     * @param shares shares of the order (only for  external reward)
     * @param totalShares total share for particular asset
     * @param recipient address of reward receiever (if any)
     * @param orderId bytes32 format orderId
     **/
    function withdraw(
        address asset,
        uint256 amount,
        uint256 shares,
        uint256 totalShares,
        address recipient,
        bytes32 orderId
    ) external;

    /**
     * @dev Withdraw all tokens from the strategy
     * @param asset the address of token
     * @param data bytes of extra data
     **/
    function withdrawAll(address asset, bytes calldata data) external;

    /**
     * @dev Used to approve max token from yield provider contract
     * @param asset the address of token
     **/
    function maxApprove(address asset) external;

    /**
     * @dev Used to get amount of underlying tokens
     * @param asset the address of token
     * @return tokensAmount amount of underlying tokens
     **/
    function getTotalUnderlying(address asset)
        external
        view
        returns (uint256 tokensAmount);

    /**
     * @dev Used to get IOU token address
     * @param asset the address of token
     * @return iouToken address of IOU token
     **/
    function getYieldTokenAddress(address asset)
        external
        view
        returns (address iouToken);

    /**
     * @dev Used to set order current external reward debt
     * @param orderId the order Id
     * @param asset the address of token
     * @param shares shares of the order (only for  external reward)
     * @param totalShares total share for particular asset
     **/
    function setOrderRewardDebt(
        bytes32 orderId,
        address asset,
        uint256 shares,
        uint256 totalShares
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IOrderStructs {
    // This is not really an interface - it just defines common structs.

    struct Order {
        address recipient;
        address inputToken;
        address outputToken;
        uint256 inputAmount;
        uint256 minReturnAmount;
        uint256 stoplossAmount;
        uint256 shares;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.4;

interface IAaveIncentivesController {
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);

    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to
    ) external returns (uint256);

    function getRewardsBalance(address[] calldata assets, address user)
        external
        view
        returns (uint256);

    function getUserUnclaimedRewards(address user)
        external
        view
        returns (uint256);

    function REWARD_TOKEN() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}