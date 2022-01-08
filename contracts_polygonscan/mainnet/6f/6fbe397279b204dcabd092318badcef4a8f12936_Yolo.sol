// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./libraries/PercentageMath.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IHandler.sol";
import "./interfaces/IYieldAdapter.sol";
import "./interfaces/IOrderStructs.sol";
import {IWETH as IWMATIC} from "./interfaces/IWETH.sol";

/**
 * @title Yolo contract
 * @author Symphony Finance
 **/
contract Yolo is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;
    using PercentageMath for uint256;

    // Protocol treasury address
    address public treasury;

    // Emergency admin address
    address public emergencyAdmin;

    /// Protocol fee: x% of input amount
    uint256 public protocolFeePercent; // 1 for 0.01%

    /// Cancellation fee: x% of total yield
    uint256 public cancellationFeePercent; // 1 for 0.01%

    /// Oracle
    IOracle public oracle;

    // Wrapped MATIC token address
    address internal constant WMATIC =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    mapping(address => address) public strategy;
    mapping(bytes32 => bytes32) public orderHash;
    mapping(address => uint256) public tokenBuffer;

    mapping(address => bool) public whitelistedTokens;
    mapping(address => uint256) public totalTokenShares;
    mapping(address => bool) public allowedHandlers;
    mapping(address => mapping(address => bool)) public allowedExecutors;

    // ************** //
    // *** EVENTS *** //
    // ************** //
    event OrderCreated(bytes32 orderId, bytes data);
    event OrderCancelled(bytes32 orderId, uint256 amountReceived);
    event OrderExecuted(
        bytes32 orderId,
        uint256 amountReceived,
        uint256 depositPlusYield
    );
    event OrderUpdated(bytes32 oldOrderId, bytes32 newOrderId, bytes data);
    event TokenStrategyUpdated(address token, address strategy);
    event HandlerAdded(address handler);
    event HandlerRemoved(address handler);
    event ProtocolFeeUpdated(uint256 feePercent);
    event CancellationFeeUpdated(uint256 feePercent);
    event TokenBufferUpdated(address token, uint256 bufferPercent);
    event AddedWhitelistToken(address token);
    event RemovedWhitelistToken(address token);
    event OracleAddressUpdated(address oracle);
    event EmergencyAdminUpdated(address admin);
    event TokensRebalanced(uint256 txCost);

    modifier onlyEmergencyAdminOrOwner() {
        require(
            _msgSender() == emergencyAdmin || _msgSender() == owner(),
            "Yolo: only emergency admin or owner can invoke this function"
        );
        _;
    }

    /**
     * @notice To initialize the global variables
     */
    function initialize(
        address _owner,
        address _emergencyAdmin,
        IOracle _oracle
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        super.transferOwnership(_owner);
        oracle = _oracle;
        emergencyAdmin = _emergencyAdmin;
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
        uint256 stoplossAmount,
        address executor,
        uint256 executionFee
    )
        external
        nonReentrant
        whenNotPaused
        returns (bytes32 orderId, bytes memory orderData)
    {
        require(
            whitelistedTokens[inputToken],
            "Yolo::createOrder: unsupported input token"
        );
        require(
            recipient != address(0),
            "Yolo::createOrder: zero recipient address"
        );
        require(inputAmount > 0, "Yolo::createOrder: zero input amount");
        require(minReturnAmount > 0, "Yolo::createOrder: zero return amount");
        require(
            stoplossAmount < minReturnAmount,
            "Yolo::createOrder: stoploss amount greater than return amount"
        );
        require(
            executionFee > 0 && executionFee < inputAmount,
            "Yolo::createOrder: invalid or zero execution fee"
        );

        orderId = getOrderId(
            msg.sender,
            recipient,
            inputToken,
            outputToken,
            inputAmount,
            minReturnAmount,
            stoplossAmount,
            executor,
            executionFee,
            block.timestamp
        );

        require(
            orderHash[orderId] == bytes32(0),
            "Yolo::createOrder: order already exists with the same id"
        );

        uint256 prevTotalShares = totalTokenShares[inputToken];

        uint256 shares = inputAmount;
        address tokenStrategy = strategy[inputToken];
        if (prevTotalShares > 0) {
            uint256 prevTotalTokens = IERC20(inputToken).balanceOf(
                address(this)
            );

            if (tokenStrategy != address(0)) {
                prevTotalTokens = getTotalTokens(
                    inputToken,
                    prevTotalTokens,
                    tokenStrategy
                );
            }

            shares = (inputAmount * prevTotalShares) / prevTotalTokens;
            require(shares > 0, "Yolo::createOrder: shares can't be zero");
        }

        // caution: trusting user input
        IERC20(inputToken).safeTransferFrom(
            msg.sender,
            address(this),
            inputAmount
        );

        totalTokenShares[inputToken] = prevTotalShares + shares;

        IOrderStructs.Order memory myOrder = IOrderStructs.Order({
            creator: msg.sender,
            recipient: recipient,
            inputToken: inputToken,
            outputToken: outputToken,
            inputAmount: inputAmount,
            minReturnAmount: minReturnAmount,
            stoplossAmount: stoplossAmount,
            shares: shares,
            executor: executor,
            executionFee: executionFee
        });
        orderData = getOrderData(myOrder);

        orderHash[orderId] = keccak256(orderData);

        emit OrderCreated(orderId, orderData);

        if (tokenStrategy != address(0)) {
            address[] memory tokens = new address[](1);
            tokens[0] = inputToken;
            rebalanceTokens(tokens);
        }
    }

    /**
     * @notice Create MATIC order
     */
    function createNativeOrder(
        address recipient,
        address outputToken,
        uint256 minReturnAmount,
        uint256 stoplossAmount,
        address executor,
        uint256 executionFee
    )
        external
        payable
        nonReentrant
        whenNotPaused
        returns (bytes32 orderId, bytes memory orderData)
    {
        uint256 inputAmount = msg.value;
        address inputToken = WMATIC;

        require(
            recipient != address(0),
            "Yolo::createNativeOrder: zero recipient address"
        );
        require(inputAmount > 0, "Yolo::createNativeOrder: zero input amount");
        require(
            minReturnAmount > 0,
            "Yolo::createNativeOrder: zero return amount"
        );
        require(
            stoplossAmount < minReturnAmount,
            "Yolo::createNativeOrder: stoploss amount greater than return amount"
        );
        require(
            executionFee > 0 && executionFee < inputAmount,
            "Yolo::createNativeOrder: invalid or zero execution fee"
        );

        orderId = getOrderId(
            msg.sender,
            recipient,
            inputToken,
            outputToken,
            inputAmount,
            minReturnAmount,
            stoplossAmount,
            executor,
            executionFee,
            block.timestamp
        );

        require(
            orderHash[orderId] == bytes32(0),
            "Yolo::createNativeOrder: order already exists with the same id"
        );

        uint256 prevTotalShares = totalTokenShares[inputToken];

        uint256 shares = inputAmount;
        address tokenStrategy = strategy[inputToken];
        if (prevTotalShares > 0) {
            uint256 prevTotalTokens = IERC20(inputToken).balanceOf(
                address(this)
            );

            if (tokenStrategy != address(0)) {
                prevTotalTokens = getTotalTokens(
                    inputToken,
                    prevTotalTokens,
                    tokenStrategy
                );
            }

            shares = (inputAmount * prevTotalShares) / prevTotalTokens;
            require(
                shares > 0,
                "Yolo::createNativeOrder: shares can't be zero"
            );
        }

        IWMATIC(inputToken).deposit{value: inputAmount}();

        totalTokenShares[inputToken] = prevTotalShares + shares;

        IOrderStructs.Order memory myOrder = IOrderStructs.Order({
            creator: msg.sender,
            recipient: recipient,
            inputToken: inputToken,
            outputToken: outputToken,
            inputAmount: inputAmount,
            minReturnAmount: minReturnAmount,
            stoplossAmount: stoplossAmount,
            shares: shares,
            executor: executor,
            executionFee: executionFee
        });
        orderData = getOrderData(myOrder);

        orderHash[orderId] = keccak256(orderData);

        emit OrderCreated(orderId, orderData);

        if (tokenStrategy != address(0)) {
            address[] memory tokens = new address[](1);
            tokens[0] = inputToken;
            rebalanceTokens(tokens);
        }
    }

    /**
     * @notice Update an existing order
     */
    function updateOrder(
        bytes32 orderId,
        bytes calldata orderData,
        address recipient,
        address outputToken,
        uint256 minReturnAmount,
        uint256 stoplossAmount,
        address executor,
        uint256 executionFee
    )
        external
        nonReentrant
        whenNotPaused
        returns (bytes32 newOrderId, bytes memory newOrderData)
    {
        require(
            recipient != address(0),
            "Yolo::updateOrder: zero recipient address"
        );
        require(
            orderHash[orderId] == keccak256(orderData),
            "Yolo::updateOrder: order doesn't match"
        );

        IOrderStructs.Order memory myOrder = decodeOrder(orderData);

        require(
            msg.sender == myOrder.creator,
            "Yolo::updateOrder: only creator can update the order"
        );
        require(minReturnAmount > 0, "Yolo::updateOrder: zero return amount");
        require(
            stoplossAmount < minReturnAmount,
            "Yolo::updateOrder: stoploss amount greater than return amount"
        );
        require(
            executionFee > 0 && executionFee < myOrder.inputAmount,
            "Yolo::updateOrder: invalid or zero execution fee"
        );

        delete orderHash[orderId];

        newOrderId = getOrderId(
            msg.sender,
            recipient,
            myOrder.inputToken,
            outputToken,
            myOrder.inputAmount,
            minReturnAmount,
            stoplossAmount,
            executor,
            executionFee,
            block.timestamp
        );

        require(
            orderHash[newOrderId] == bytes32(0),
            "Yolo::updateOrder: order already exists with the same id"
        );

        newOrderData = abi.encode(
            msg.sender,
            recipient,
            myOrder.inputToken,
            outputToken,
            myOrder.inputAmount,
            minReturnAmount,
            stoplossAmount,
            myOrder.shares,
            executor,
            executionFee
        );

        orderHash[newOrderId] = keccak256(newOrderData);

        emit OrderUpdated(orderId, newOrderId, newOrderData);
    }

    /**
     * @notice Cancel an existing order
     */
    function cancelOrder(bytes32 orderId, bytes calldata orderData)
        external
        nonReentrant
        returns (uint256 depositPlusYield)
    {
        require(
            orderHash[orderId] == keccak256(orderData),
            "Yolo::cancelOrder: order doesn't match"
        );

        IOrderStructs.Order memory myOrder = decodeOrder(orderData);

        require(
            msg.sender == myOrder.creator,
            "Yolo::cancelOrder: only creator can cancel the order"
        );

        depositPlusYield = _removeOrder(
            orderId,
            myOrder.inputToken,
            myOrder.shares
        );

        uint256 cancellationFee = 0;
        uint256 feePercent = cancellationFeePercent;
        if (depositPlusYield > myOrder.inputAmount && feePercent > 0) {
            uint256 yieldEarned = depositPlusYield - myOrder.inputAmount;
            cancellationFee = yieldEarned.percentMul(feePercent);
            if (cancellationFee > 0) {
                IERC20(myOrder.inputToken).safeTransfer(
                    treasury,
                    cancellationFee
                );
            }
        }

        uint256 transferAmount = depositPlusYield - cancellationFee;
        IERC20(myOrder.inputToken).safeTransfer(msg.sender, transferAmount);
        emit OrderCancelled(orderId, transferAmount);
    }

    /**
     * @notice Execute the order using external DEX
     */
    function executeOrder(
        bytes32 orderId,
        bytes calldata orderData,
        address payable handler,
        bytes calldata handlerData
    ) external nonReentrant whenNotPaused {
        require(
            orderHash[orderId] == keccak256(orderData),
            "Yolo::executeOrder: order doesn't match"
        );

        IOrderStructs.Order memory myOrder = decodeOrder(orderData);

        if (myOrder.executor != address(0) && myOrder.executor != msg.sender) {
            require(
                allowedExecutors[myOrder.executor][msg.sender],
                "Yolo::executeOrder: order executor mismatch"
            );
        }
        require(
            allowedHandlers[handler],
            "Yolo::executeOrder: unregistered handler"
        );

        uint256 depositPlusYield = _removeOrder(
            orderId,
            myOrder.inputToken,
            myOrder.shares
        );
        if (depositPlusYield < myOrder.inputAmount) {
            myOrder.inputAmount = depositPlusYield;
        }

        uint256 protocolFee = 0;
        uint256 _protocolFeePercent = protocolFeePercent;
        if (_protocolFeePercent > 0) {
            protocolFee = myOrder.inputAmount.percentMul(_protocolFeePercent);
        }

        _transferFee(
            myOrder.inputToken,
            myOrder.executionFee,
            protocolFee,
            msg.sender
        );
        uint256 totalFee = protocolFee + myOrder.executionFee;
        myOrder.inputAmount = myOrder.inputAmount - totalFee;

        (, uint256 oracleAmount) = oracle.get(
            myOrder.inputToken,
            myOrder.outputToken,
            myOrder.inputAmount
        );

        IERC20(myOrder.inputToken).safeTransfer(handler, myOrder.inputAmount);

        uint256 totalAmountOut = IHandler(handler).handle(
            myOrder,
            oracleAmount,
            handlerData
        );

        emit OrderExecuted(orderId, totalAmountOut, depositPlusYield);

        depositPlusYield = depositPlusYield - totalFee;
        if (depositPlusYield > myOrder.inputAmount) {
            uint256 yieldEarned = depositPlusYield - myOrder.inputAmount;
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
        bytes calldata orderData,
        uint256 quoteAmount
    ) external nonReentrant whenNotPaused {
        require(
            orderHash[orderId] == keccak256(orderData),
            "Yolo::fillOrder: order doesn't match"
        );

        IOrderStructs.Order memory myOrder = decodeOrder(orderData);

        if (myOrder.executor != address(0) && myOrder.executor != msg.sender) {
            require(
                allowedExecutors[myOrder.executor][msg.sender],
                "Yolo::fillOrder: order executor mismatch"
            );
        }

        uint256 depositPlusYield = _removeOrder(
            orderId,
            myOrder.inputToken,
            myOrder.shares
        );
        if (depositPlusYield < myOrder.inputAmount) {
            myOrder.inputAmount = depositPlusYield;
        }

        uint256 protocolFee = 0;
        uint256 _protocolFeePercent = protocolFeePercent;
        if (_protocolFeePercent > 0) {
            protocolFee = myOrder.inputAmount.percentMul(_protocolFeePercent);
        }
        uint256 totalFee = protocolFee + myOrder.executionFee;

        (uint256 oracleAmount, ) = oracle.get(
            myOrder.inputToken,
            myOrder.outputToken,
            myOrder.inputAmount - totalFee
        );

        bool success = ((quoteAmount >= myOrder.minReturnAmount ||
            quoteAmount <= myOrder.stoplossAmount) &&
            quoteAmount >= oracleAmount);

        require(success, "Yolo::fillOrder: fill condition doesn't satisfy");

        emit OrderExecuted(orderId, quoteAmount, depositPlusYield);

        _transferFee(
            myOrder.inputToken,
            myOrder.executionFee,
            protocolFee,
            address(0)
        );

        // caution: external calls to unknown address
        IERC20(myOrder.outputToken).safeTransferFrom(
            msg.sender,
            myOrder.recipient,
            quoteAmount
        );

        IERC20(myOrder.inputToken).safeTransfer(
            msg.sender,
            myOrder.inputAmount - protocolFee
        );

        if (depositPlusYield > myOrder.inputAmount) {
            uint256 yieldEarned = depositPlusYield - myOrder.inputAmount;
            IERC20(myOrder.inputToken).safeTransfer(
                myOrder.recipient,
                yieldEarned
            );
        }
    }

    /**
     * @notice rebalance token according to buffer
     */
    function rebalanceTokens(address[] memory tokens) public {
        uint256 totalGas = gasleft();
        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenStrategy = strategy[tokens[i]];
            require(
                tokenStrategy != address(0),
                "Yolo::rebalanceTokens: strategy doesn't exist"
            );

            uint256 balanceInContract = IERC20(tokens[i]).balanceOf(
                address(this)
            );

            uint256 balanceInStrategy = IYieldAdapter(tokenStrategy)
                .getTotalUnderlying(tokens[i]);

            uint256 totalBalance = balanceInContract + balanceInStrategy;

            uint256 bufferBalanceNeeded = totalBalance.percentMul(
                tokenBuffer[tokens[i]]
            );

            if (balanceInContract > bufferBalanceNeeded) {
                uint256 depositAmount = balanceInContract - bufferBalanceNeeded;
                IERC20(tokens[i]).safeTransfer(tokenStrategy, depositAmount);
                IYieldAdapter(tokenStrategy).deposit(tokens[i], depositAmount);
            } else if (balanceInContract < bufferBalanceNeeded) {
                IYieldAdapter(tokenStrategy).withdraw(
                    tokens[i],
                    bufferBalanceNeeded - balanceInContract
                );
            }
            if (i == tokens.length - 1) {
                emit TokensRebalanced((totalGas - gasleft()) * tx.gasprice);
            }
        }
    }

    // *************** //
    // *** GETTERS *** //
    // *************** //

    function getOrderId(
        address creator,
        address recipient,
        address inputToken,
        address outputToken,
        uint256 amount,
        uint256 minReturnAmount,
        uint256 stoplossAmount,
        address executor,
        uint256 executionFee,
        uint256 blockTimestamp
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    creator,
                    recipient,
                    inputToken,
                    outputToken,
                    amount,
                    minReturnAmount,
                    stoplossAmount,
                    executor,
                    executionFee,
                    blockTimestamp
                )
            );
    }

    function getTotalTokens(
        address token,
        uint256 contractBalance,
        address tokenStrategy
    ) public returns (uint256 totalTokens) {
        totalTokens = contractBalance;
        if (tokenStrategy != address(0)) {
            totalTokens =
                totalTokens +
                IYieldAdapter(tokenStrategy).getTotalUnderlying(token);
        }
    }

    function decodeOrder(bytes memory orderData)
        public
        view
        returns (IOrderStructs.Order memory order)
    {
        (
            address creator,
            address recipient,
            address inputToken,
            address outputToken,
            uint256 inputAmount,
            uint256 minReturnAmount,
            uint256 stoplossAmount,
            uint256 shares,
            address executor,
            uint256 executionFee
        ) = abi.decode(
                orderData,
                (
                    address,
                    address,
                    address,
                    address,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    address,
                    uint256
                )
            );

        order = IOrderStructs.Order(
            creator,
            recipient,
            inputToken,
            outputToken,
            inputAmount,
            minReturnAmount,
            stoplossAmount,
            shares,
            executor,
            executionFee
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
        allowedHandlers[_handler] = true;
        emit HandlerAdded(_handler);
    }

    /**
     * @notice Remove an order handler
     */
    function removeHandler(address _handler) external onlyOwner {
        allowedHandlers[_handler] = false;
        emit HandlerRemoved(_handler);
    }

    /**
     * @notice Update protocol fee percent
     */
    function updateProtocolFee(uint256 _feePercent) external onlyOwner {
        require(
            _feePercent <= 10000,
            "Yolo::updateProtocolFee: fee percent exceeds max threshold"
        );
        require(
            treasury != address(0),
            "Yolo::updateProtocolFee: treasury addresss not set"
        );
        protocolFeePercent = _feePercent;
        emit ProtocolFeeUpdated(_feePercent);
    }

    /**
     * @notice Update cancellation fee percent
     */
    function updateCancellationFee(uint256 _feePercent) external onlyOwner {
        require(
            _feePercent <= 10000,
            "Yolo::updateCancellationFee: fee percent exceeds max threshold"
        );
        require(
            treasury != address(0),
            "Yolo::updateCancellationFee: treasury addresss not set"
        );
        cancellationFeePercent = _feePercent;
        emit CancellationFeeUpdated(_feePercent);
    }

    /**
     * @notice Update the oracle
     */
    function updateOracle(IOracle _oracle) external onlyOwner {
        require(
            IOracle(_oracle).isOracle(),
            "Yolo::updateOracle: invalid oracle address"
        );
        oracle = _oracle;
        emit OracleAddressUpdated(address(_oracle));
    }

    /**
     * @notice Add an token into whitelist
     */
    function addWhitelistToken(address _token) external onlyOwner {
        whitelistedTokens[_token] = true;
        emit AddedWhitelistToken(_token);
    }

    /**
     * @notice Remove a whitelisted token
     */
    function removeWhitelistToken(address _token) external onlyOwner {
        whitelistedTokens[_token] = false;
        emit RemovedWhitelistToken(_token);
    }

    /**
     * @notice Set strategy of a token
     */
    function setStrategy(address _token, address _strategy) external onlyOwner {
        require(
            strategy[_token] == address(0),
            "Yolo::setStrategy: strategy already exists"
        );
        _updateTokenStrategy(_token, _strategy);
    }

    /**
     * @notice Migrate to new strategy
     */
    function migrateStrategy(address _token, address _newStrategy)
        external
        onlyOwner
    {
        address previousStrategy = strategy[_token];
        require(
            previousStrategy != address(0),
            "Yolo::migrateStrategy: no previous strategy exists"
        );
        require(
            previousStrategy != _newStrategy,
            "Yolo::migrateStrategy: new strategy same as previous"
        );

        IYieldAdapter(previousStrategy).withdrawAll(_token);

        require(
            IYieldAdapter(previousStrategy).getTotalUnderlying(_token) == 0,
            "Yolo::migrateStrategy: withdraw from strategy failed"
        );

        if (_newStrategy != address(0)) {
            _updateTokenStrategy(_token, _newStrategy);
        } else {
            strategy[_token] = _newStrategy;
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

    /*Yolo*
     * @notice Unpause the contract
     */
    function unpause() external onlyEmergencyAdminOrOwner {
        _unpause();
    }

    /**
     * @notice Withdraw all tokens from strategies including rewards
     * @dev Only in emergency case. Transfer rewards to Yolo contract
     */
    function emergencyWithdrawFromStrategy(address[] calldata _tokens)
        external
        onlyEmergencyAdminOrOwner
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            address tokenStrategy = strategy[token];

            IYieldAdapter(tokenStrategy).withdrawAll(token);
        }
    }

    /**
     * @notice Update token buffer percent
     */
    function updateTokenBuffer(address _token, uint256 _bufferPercent)
        external
        onlyEmergencyAdminOrOwner
    {
        require(
            _bufferPercent <= 10000,
            "Yolo::updateTokenBuffer: buffer percent exceeds max threshold"
        );
        tokenBuffer[_token] = _bufferPercent;
        emit TokenBufferUpdated(_token, _bufferPercent);
    }

    /**
     * @notice Update emergency admin address
     */
    function updateEmergencyAdmin(address _emergencyAdmin)
        external
        onlyEmergencyAdminOrOwner
    {
        emergencyAdmin = _emergencyAdmin;
        emit EmergencyAdminUpdated(_emergencyAdmin);
    }

    // ************************** //
    // *** EXECUTOR FUNCTIONS *** //
    // ************************** //
    function approveExecutor(address executor) external {
        allowedExecutors[msg.sender][executor] = true;
    }

    function revokeExecutor(address executor) external {
        allowedExecutors[msg.sender][executor] = false;
    }

    // ************************** //
    // *** INTERNAL FUNCTIONS *** //
    // ************************** //

    /**
     * @notice Update Strategy of an token
     */
    function _updateTokenStrategy(address _token, address _strategy) internal {
        if (_strategy != address(0)) {
            emit TokenStrategyUpdated(_token, _strategy);
            strategy[_token] = _strategy;
            address[] memory tokens = new address[](1);
            tokens[0] = _token;
            rebalanceTokens(tokens);
        }
    }

    function _transferFee(
        address _token,
        uint256 _executionFee,
        uint256 _protocolFee,
        address _executor
    ) internal returns (uint256 protocolFee) {
        address treasuryAddress = treasury;
        if (_protocolFee > 0) {
            IERC20(_token).safeTransfer(treasuryAddress, _protocolFee);
        }
        if (_executor != address(0) && _executionFee > 0) {
            IERC20(_token).safeTransfer(_executor, _executionFee - protocolFee);
        }
    }

    function _removeOrder(
        bytes32 _orderId,
        address _token,
        uint256 _shares
    ) internal returns (uint256 depositPlusYield) {
        delete orderHash[_orderId];
        address tokenStrategy = strategy[_token];
        uint256 contractBal = IERC20(_token).balanceOf(address(this));
        uint256 totalTokens = getTotalTokens(
            _token,
            contractBal,
            tokenStrategy
        );
        uint256 totalShares = totalTokenShares[_token];
        totalTokenShares[_token] = totalShares - _shares;
        depositPlusYield = (_shares * totalTokens) / (totalShares);

        if (contractBal < depositPlusYield && tokenStrategy != address(0)) {
            uint256 neededAmountInBuffer = (totalTokens - depositPlusYield)
                .percentMul(tokenBuffer[_token]);

            IYieldAdapter(tokenStrategy).withdraw(
                _token,
                depositPlusYield + neededAmountInBuffer - contractBal
            );
        }
    }

    function getOrderData(IOrderStructs.Order memory order)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encode(
                order.creator,
                order.recipient,
                order.inputToken,
                order.outputToken,
                order.inputAmount,
                order.minReturnAmount,
                order.stoplossAmount,
                order.shares,
                order.executor,
                order.executionFee
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
     * by making the `nonReentrant` function external, and making it call a
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
pragma solidity 0.8.10;

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
pragma solidity 0.8.10;

interface IOracle {
    function get(
        address inputToken,
        address outputToken,
        uint256 inputAmount
    ) external view returns (uint256 amountOut, uint256 amountOutWithSlippage);

    function isOracle() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOrderStructs.sol";

interface IHandler {
    /**
     * @notice Handle an order execution
     * @param _order - Order structure
     * @param _oracleAmount - Current out amount from oracle
     * @param _data - Bytes of arbitrary data
     */
    function handle(
        IOrderStructs.Order memory _order,
        uint256 _oracleAmount,
        bytes calldata _data
    ) external returns (uint256 returnAmount);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

interface IYieldAdapter {
    /**
     * @dev Used to deposit token
     * @param token the address of token to invest
     * @param amount the amount of token
     **/
    function deposit(address token, uint256 amount) external;

    /**
     * @dev Used to withdraw from available protocol
     * @param token the address of underlying token
     * @param amount the amount of liquidity shares to unlock
     **/
    function withdraw(address token, uint256 amount) external;

    /**
     * @dev Withdraw all tokens from the strategy
     * @param token the address of token
     **/
    function withdrawAll(address token) external;

    /**
     * @dev Used to get amount of underlying tokens
     * @param token the address of token
     * @return tokensAmount amount of underlying tokens
     **/
    function getTotalUnderlying(address token)
        external
        returns (uint256 tokensAmount);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

interface IOrderStructs {
    // This is not really an interface - it just defines common structs.

    struct Order {
        address creator;
        address recipient;
        address inputToken;
        address outputToken;
        uint256 inputAmount;
        uint256 minReturnAmount;
        uint256 stoplossAmount;
        uint256 shares;
        address executor;
        uint256 executionFee;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}