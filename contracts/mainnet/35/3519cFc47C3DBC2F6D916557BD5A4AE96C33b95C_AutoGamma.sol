// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {GammaOperator} from "./GammaOperator.sol";
import {IAutoGamma} from "./interfaces/IAutoGamma.sol";
import {IUniswapRouter} from "./interfaces/IUniswapRouter.sol";
import {IPokeMe} from "./interfaces/IPokeMe.sol";
import {ITaskTreasury} from "./interfaces/ITaskTreasury.sol";
import {IResolver} from "./interfaces/IResolver.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @author Willy Shen
/// @title Opyn Gamma Automatic Redeemer
/// @notice An automatic redeemer for Gamma otoken holders and writers
contract AutoGamma is IAutoGamma, GammaOperator {
    using SafeERC20 for IERC20;

    Order[] public orders;

    IUniswapRouter public uniRouter;
    IPokeMe public automator;
    ITaskTreasury public automatorTreasury;
    bool public isAutomatorEnabled;

    mapping(address => mapping(address => bool)) public uniPair;

    // fee in 1/10.000: 1% = 100, 0.01% = 1
    uint256 public redeemFee = 100;
    uint256 public settleFee = 15;

    /**
     * @notice only automator or owner
     */
    modifier onlyAuthorized() {
        require(
            msg.sender == address(automator) || msg.sender == owner(),
            "AutoGamma::onlyAuthorized: Only automator or owner"
        );
        _;
    }

    constructor(
        address _gammaAddressBook,
        address _uniRouter,
        address _automator,
        address _automatorTreasury
    ) GammaOperator(_gammaAddressBook) {
        uniRouter = IUniswapRouter(_uniRouter);
        automator = IPokeMe(_automator);
        automatorTreasury = ITaskTreasury(_automatorTreasury);
        isAutomatorEnabled = false;
    }

    /**
     * @notice tell automator to start executing orders
     * @param _resolver the address of automation resolver
     * @dev automator will start calling resolver to fetch and execute processable orders
     */
    function startAutomator(address _resolver) public onlyOwner {
        require(
            !isAutomatorEnabled,
            "AutoGamma::startAutomator: already started"
        );
        isAutomatorEnabled = true;
        automator.createTask(
            address(this),
            bytes4(0x895f7952), //processOrders selector
            _resolver,
            abi.encodeWithSelector(IResolver.getProcessableOrders.selector)
        );
    }

    /**
     * @notice tell automator to stop executing orders
     */
    function stopAutomator() public onlyOwner {
        require(
            isAutomatorEnabled,
            "AutoGamma::stopAutomator: already stopped"
        );
        isAutomatorEnabled = false;
        automator.cancelTask(
            automator.getTaskId(
                address(this),
                address(this),
                bytes4(0x895f7952) //processOrders selector
            )
        );
    }

    /**
     * @notice create automation order
     * @param _otoken the address of otoken (only holders)
     * @param _amount amount of otoken (only holders)
     * @param _vaultId the id of specific vault to settle (only writers)
     * @param _toToken token address for custom token settlement
     */
    function createOrder(
        address _otoken,
        uint256 _amount,
        uint256 _vaultId,
        address _toToken
    ) public override {
        uint256 fee;
        bool isSeller;
        if (_otoken == address(0)) {
            require(
                _amount == 0,
                "AutoGamma::createOrder: Amount must be 0 when creating settlement order"
            );
            fee = settleFee;
            isSeller = true;
        } else {
            require(
                isWhitelistedOtoken(_otoken),
                "AutoGamma::createOrder: Otoken not whitelisted"
            );
            fee = redeemFee;
        }

        if (_toToken != address(0)) {
            address payoutToken;
            if (isSeller) {
                address otoken = getVaultOtoken(msg.sender, _vaultId);
                payoutToken = getOtokenCollateral(otoken);
            } else {
                payoutToken = getOtokenCollateral(_otoken);
            }
            require(
                payoutToken != _toToken,
                "AutoGamma::createOrder: same settlement token and collateral"
            );
            require(
                uniPair[payoutToken][_toToken],
                "AutoGamma::createOrder: settlement token not allowed"
            );
        }

        uint256 orderId = orders.length;

        Order memory order;
        order.owner = msg.sender;
        order.otoken = _otoken;
        order.amount = _amount;
        order.vaultId = _vaultId;
        order.isSeller = isSeller;
        order.fee = fee;
        order.toToken = _toToken;
        orders.push(order);

        emit OrderCreated(orderId, msg.sender, _otoken);
    }

    /**
     * @notice cancel automation order
     * @param _orderId the id of specific order to be cancelled
     */
    function cancelOrder(uint256 _orderId) public override {
        Order storage order = orders[_orderId];
        require(
            order.owner == msg.sender,
            "AutoGamma::cancelOrder: Sender is not order owner"
        );
        require(
            !order.finished,
            "AutoGamma::cancelOrder: Order is already finished"
        );

        order.finished = true;
        emit OrderFinished(_orderId, true);
    }

    /**
     * @notice check if processing order is profitable
     * @param _orderId the id of specific order to be processed
     * @return true if settling vault / redeeming returns more than 0 amount
     */
    function shouldProcessOrder(uint256 _orderId)
        public
        view
        override
        returns (bool)
    {
        Order memory order = orders[_orderId];
        if (order.finished) return false;

        if (order.isSeller) {
            bool shouldSettle = shouldSettleVault(order.owner, order.vaultId);
            if (!shouldSettle) return false;
        } else {
            bool shouldRedeem = shouldRedeemOtoken(
                order.owner,
                order.otoken,
                order.amount
            );
            if (!shouldRedeem) return false;
        }

        return true;
    }

    /**
     * @notice process an order
     * @dev only automator allowed
     * @param _orderId the id of specific order to process
     */
    function processOrder(uint256 _orderId, ProcessOrderArgs calldata orderArgs)
        public
        override
        onlyAuthorized
    {
        Order storage order = orders[_orderId];
        require(
            shouldProcessOrder(_orderId),
            "AutoGamma::processOrder: Order should not be processed"
        );
        order.finished = true;

        address payoutToken;
        uint256 payoutAmount;
        if (order.isSeller) {
            (payoutToken, payoutAmount) = settleVault(
                order.owner,
                order.vaultId
            );
        } else {
            (payoutToken, payoutAmount) = redeemOtoken(
                order.owner,
                order.otoken,
                order.amount
            );
        }

        // minus fee
        payoutAmount = payoutAmount - ((order.fee * payoutAmount) / 10000);

        if (order.toToken == address(0)) {
            IERC20(payoutToken).safeTransfer(order.owner, payoutAmount);
        } else {
            require(
                payoutToken == orderArgs.swapPath[0] &&
                    order.toToken == orderArgs.swapPath[1],
                "AutoGamma::processOrder: Invalid swap path"
            );
            require(
                uniPair[payoutToken][order.toToken],
                "AutoGamma::processOrder: token pair not allowed"
            );

            IERC20(payoutToken).approve(address(uniRouter), payoutAmount);
            uint256[] memory amounts = swap(
                payoutAmount,
                orderArgs.swapAmountOutMin,
                orderArgs.swapPath
            );
            IERC20(order.toToken).safeTransfer(order.owner, amounts[1]);
        }

        emit OrderFinished(_orderId, false);
    }

    /**
     * @notice process multiple orders
     * @param _orderIds array of order ids to process
     */
    function processOrders(
        uint256[] calldata _orderIds,
        ProcessOrderArgs[] calldata _orderArgs
    ) public override {
        require(
            _orderIds.length == _orderArgs.length,
            "AutoGamma::processOrders: Params lengths must be same"
        );
        for (uint256 i = 0; i < _orderIds.length; i++) {
            processOrder(_orderIds[i], _orderArgs[i]);
        }
    }

    /**
     * @notice withdraw funds from automator
     * @param _token address of token to withdraw
     * @param _amount amount of token to withdraw
     */
    function withdrawFund(address _token, uint256 _amount) public onlyOwner {
        automatorTreasury.withdrawFunds(payable(this), _token, _amount);
    }

    /**
     * @notice uniswap token swap
     * @param _amountIn amount of token to swap
     * @param _amountOutMin minimal amount of token to receive
     * @param _path token pair to swap
     * @return amounts amount of each tokens being swapped
     */
    function swap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path
    ) internal returns (uint256[] memory amounts) {
        return
            IUniswapRouter(uniRouter).swapExactTokensForTokens(
                _amountIn,
                _amountOutMin,
                _path,
                address(this),
                block.timestamp
            );
    }

    /**
     * @notice allow token pair for swap
     * @param _token0 first token
     * @param _token1 second token
     */
    function allowPair(address _token0, address _token1) public onlyOwner {
        require(
            !uniPair[_token0][_token1],
            "AutoGamma::allowPair: already allowed"
        );
        uniPair[_token0][_token1] = true;
        uniPair[_token1][_token0] = true;
    }

    /**
     * @notice disallow token pair for swap
     * @param _token0 first token
     * @param _token1 second token
     */
    function disallowPair(address _token0, address _token1) public onlyOwner {
        require(
            uniPair[_token0][_token1],
            "AutoGamma::allowPair: already disallowed"
        );
        uniPair[_token0][_token1] = false;
        uniPair[_token1][_token0] = false;
    }

    function setUniRouter(address _uniRouter) public onlyOwner {
        uniRouter = IUniswapRouter(_uniRouter);
    }

    function setAutomator(address _automator) public onlyOwner {
        automator = IPokeMe(_automator);
    }

    function setAutomatorTreasury(address _automatorTreasury) public onlyOwner {
        automatorTreasury = ITaskTreasury(_automatorTreasury);
    }

    function setRedeemFee(uint256 _redeemFee) public onlyOwner {
        redeemFee = _redeemFee;
    }

    function setSettleFee(uint256 _settleFee) public onlyOwner {
        settleFee = _settleFee;
    }

    function getOrdersLength() public view override returns (uint256) {
        return orders.length;
    }

    function getOrders() public view override returns (Order[] memory) {
        return orders;
    }

    function getOrder(uint256 _orderId)
        public
        view
        override
        returns (Order memory)
    {
        return orders[_orderId];
    }

    function isPairAllowed(address _token0, address _token1)
        public
        view
        override
        returns (bool)
    {
        return uniPair[_token0][_token1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {IAddressBook} from "./interfaces/IAddressBook.sol";
import {IGammaController} from "./interfaces/IGammaController.sol";
import {IWhitelist} from "./interfaces/IWhitelist.sol";
import {IMarginCalculator} from "./interfaces/IMarginCalculator.sol";
import {Actions} from "./external/OpynActions.sol";
import {MarginVault} from "./external/OpynVault.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IOtoken} from "./interfaces/IOtoken.sol";

/// @author Willy Shen
/// @title Gamma Operator
/// @notice Opyn Gamma protocol adapter for redeeming otokens and settling vaults
contract GammaOperator is Ownable {
    using SafeERC20 for IERC20;

    // Gamma Protocol contracts
    IAddressBook public addressBook;
    IGammaController public controller;
    IWhitelist public whitelist;
    IMarginCalculator public calculator;

    /**
     * @dev fetch Gamma contracts from address book
     * @param _addressBook Gamma Address Book address
     */
    constructor(address _addressBook) {
        setAddressBook(_addressBook);
        refreshConfig();
    }

    /**
     * @notice redeem otoken on behalf of owner
     * @param _owner owner address
     * @param _otoken otoken address
     * @param _amount amount of otoken
     */
    function redeemOtoken(
        address _owner,
        address _otoken,
        uint256 _amount
    ) internal returns (address payoutToken, uint256 payoutAmount) {
        uint256 actualAmount = getRedeemableAmount(_owner, _otoken, _amount);

        IERC20(_otoken).safeTransferFrom(_owner, address(this), actualAmount);

        Actions.ActionArgs memory action;
        action.actionType = Actions.ActionType.Redeem;
        action.secondAddress = address(this);
        action.asset = _otoken;
        action.amount = _amount;

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);
        actions[0] = action;

        payoutToken = IOtoken(_otoken).collateralAsset();

        uint256 startAmount = IERC20(payoutToken).balanceOf(address(this));
        controller.operate(actions);
        uint256 endAmount = IERC20(payoutToken).balanceOf(address(this));

        payoutAmount = endAmount - startAmount;
    }

    /**
     * @notice settle vault on behalf of owner
     * @param _owner owner address
     * @param _vaultId vaultId to settle
     */
    function settleVault(address _owner, uint256 _vaultId)
        internal
        returns (address payoutToken, uint256 payoutAmount)
    {
        Actions.ActionArgs memory action;
        action.actionType = Actions.ActionType.SettleVault;
        action.owner = _owner;
        action.vaultId = _vaultId;
        action.secondAddress = address(this);

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);
        actions[0] = action;

        MarginVault.Vault memory vault = getVault(_owner, _vaultId);
        address otoken = getVaultOtokenByVault(vault);
        payoutToken = IOtoken(otoken).collateralAsset();

        uint256 startAmount = IERC20(payoutToken).balanceOf(address(this));
        controller.operate(actions);
        uint256 endAmount = IERC20(payoutToken).balanceOf(address(this));

        payoutAmount = endAmount - startAmount;
    }

    /**
     * @notice return if otoken should be redeemed
     * @param _owner owner address
     * @param _otoken otoken address
     * @param _amount amount of otoken
     * @return true if otoken has expired and payout is greater than zero
     */
    function shouldRedeemOtoken(
        address _owner,
        address _otoken,
        uint256 _amount
    ) public view returns (bool) {
        uint256 actualAmount = getRedeemableAmount(_owner, _otoken, _amount);
        try this.getRedeemPayout(_otoken, actualAmount) returns (
            uint256 payout
        ) {
            if (payout == 0) return false;
        } catch {
            return false;
        }

        return true;
    }

    /**
     * @notice return if vault should be settled
     * @param _owner owner address
     * @param _vaultId vaultId to settle
     * @return true if vault can be settled, contract is operator of owner,
     *          and excess collateral is greater than zero
     */
    function shouldSettleVault(address _owner, uint256 _vaultId)
        public
        view
        returns (bool)
    {
        (
            MarginVault.Vault memory vault,
            uint256 typeVault,

        ) = getVaultWithDetails(_owner, _vaultId);

        (uint256 payout, bool isValidVault) = getExcessCollateral(
            vault,
            typeVault
        );
        if (!isValidVault || payout == 0) return false;

        return true;
    }

    /**
     * @notice set Gamma Address Book
     * @param _address Address Book address
     */
    function setAddressBook(address _address) public onlyOwner {
        require(
            _address != address(0),
            "GammaOperator::setAddressBook: Address must not be zero"
        );
        addressBook = IAddressBook(_address);
    }

    /**
     * @notice transfer operator profit
     * @param _token address token to transfer
     * @param _amount amount of token to transfer
     * @param _to transfer destination
     */
    function harvest(
        address _token,
        uint256 _amount,
        address _to
    ) public onlyOwner {
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            (bool success, ) = _to.call{value: _amount}("");
            require(success, "GammaOperator::harvest: ETH transfer failed");
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    /**
     * @notice refresh Gamma contracts' addresses
     */
    function refreshConfig() public {
        address _controller = addressBook.getController();
        controller = IGammaController(_controller);

        address _whitelist = addressBook.getWhitelist();
        whitelist = IWhitelist(_whitelist);

        address _calculator = addressBook.getMarginCalculator();
        calculator = IMarginCalculator(_calculator);
    }

    /**
     * @notice get an oToken's payout in the collateral asset
     * @param _otoken otoken address
     * @param _amount amount of otoken to redeem
     */
    function getRedeemPayout(address _otoken, uint256 _amount)
        public
        view
        returns (uint256)
    {
        return controller.getPayout(_otoken, _amount);
    }

    /**
     * @notice get amount of otoken that can be redeemed
     * @param _owner owner address
     * @param _otoken otoken address
     * @param _amount amount of otoken
     * @return amount of otoken the contract can transferFrom owner
     */
    function getRedeemableAmount(
        address _owner,
        address _otoken,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 ownerBalance = IERC20(_otoken).balanceOf(_owner);
        uint256 allowance = IERC20(_otoken).allowance(_owner, address(this));
        uint256 spendable = min(ownerBalance, allowance);
        return min(_amount, spendable);
    }

    /**
     * @notice return details of a specific vault
     * @param _owner owner address
     * @param _vaultId vaultId
     * @return vault struct and vault type and the latest timestamp when the vault was updated
     */
    function getVaultWithDetails(address _owner, uint256 _vaultId)
        public
        view
        returns (
            MarginVault.Vault memory,
            uint256,
            uint256
        )
    {
        return controller.getVaultWithDetails(_owner, _vaultId);
    }

    /**
     * @notice return a specific vault
     * @param _owner owner address
     * @param _vaultId vaultId
     * @return vault struct
     */
    function getVault(address _owner, uint256 _vaultId)
        public
        view
        returns (MarginVault.Vault memory)
    {
        return controller.getVault(_owner, _vaultId);
    }

    /**
     * @notice return the otoken from specific vault
     * @param _vault id of specific vault
     * @return otoken address
     */
    function getVaultOtokenByVault(MarginVault.Vault memory _vault)
        public
        pure
        returns (address)
    {
        bool hasShort = isNotEmpty(_vault.shortOtokens);
        bool hasLong = isNotEmpty(_vault.longOtokens);

        assert(hasShort || hasLong);

        return hasShort ? _vault.shortOtokens[0] : _vault.longOtokens[0];
    }

    /**
     * @notice return the otoken from specific vault
     * @param _owner owner address
     * @param _vaultId id of specific vault
     * @return otoken address
     */
    function getVaultOtoken(address _owner, uint256 _vaultId)
        public
        view
        returns (address)
    {
        MarginVault.Vault memory vault = getVault(_owner, _vaultId);
        return getVaultOtokenByVault(vault);
    }

    /**
     * @notice return the collateral asset of a specific otoken
     * @param _otoken otoken address
     * @return collateral address
     */
    function getOtokenCollateral(address _otoken)
        public
        view
        returns (address)
    {
        return IOtoken(_otoken).collateralAsset();
    }

    /**
     * @notice return amount of collateral that can be removed from a vault
     * @param _vault vault struct
     * @param _typeVault vault type
     * @return excess amount and true if excess is greater than zero
     */
    function getExcessCollateral(
        MarginVault.Vault memory _vault,
        uint256 _typeVault
    ) public view returns (uint256, bool) {
        return calculator.getExcessCollateral(_vault, _typeVault);
    }

    /**
     * @notice return if otoken is ready to be settled
     * @param _otoken otoken address
     * @return true if settlement is allowed
     */
    function isSettlementAllowed(address _otoken) public view returns (bool) {
        return controller.isSettlementAllowed(_otoken);
    }

    /**
     * @notice return if this contract is Gamma operator of an address
     * @param _owner owner address
     * @return true if address(this) is operator of _owner
     */
    function isOperatorOf(address _owner) public view returns (bool) {
        return controller.isOperator(_owner, address(this));
    }

    /**
     * @notice return if otoken is whitelisted on Gamma
     * @param _otoken otoken address
     * @return true if isWhitelistedOtoken returns true for _otoken
     */
    function isWhitelistedOtoken(address _otoken) public view returns (bool) {
        return whitelist.isWhitelistedOtoken(_otoken);
    }

    /**
     * @param _otoken otoken address
     * @return true if otoken has expired and settlement is allowed
     */
    function hasExpiredAndSettlementAllowed(address _otoken)
        public
        view
        returns (bool)
    {
        bool hasExpired = block.timestamp >= IOtoken(_otoken).expiryTimestamp();
        if (!hasExpired) return false;

        bool isAllowed = isSettlementAllowed(_otoken);
        if (!isAllowed) return false;

        return true;
    }

    /**
     * @notice return if specific vault exist
     * @param _owner owner address
     * @param _vaultId vaultId to check
     * @return true if vault exist for owner
     */
    function isValidVaultId(address _owner, uint256 _vaultId)
        public
        view
        returns (bool)
    {
        uint256 vaultCounter = controller.getAccountVaultCounter(_owner);
        return ((_vaultId > 0) && (_vaultId <= vaultCounter));
    }

    /**
     * @notice return if array is not empty
     * @param _array array of address to check
     * @return true if array length is grreater than zero & first element isn't address zero
     */
    function isNotEmpty(address[] memory _array) private pure returns (bool) {
        return (_array.length > 0) && (_array[0] != address(0));
    }

    /**
     * @notice return the lowest number
     * @param a first number
     * @param b second number
     * @return the lowest uint256
     */
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? b : a;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IAutoGamma {
    struct Order {
        // address of user
        address owner;
        // address of otoken to redeem
        address otoken;
        // amount of otoken to redeem
        uint256 amount;
        // vaultId of vault to settle
        uint256 vaultId;
        // true if settle vault order, else redeem otoken
        bool isSeller;
        // convert proceed to token if not address(0)
        address toToken;
        // fee in 1/10.000
        uint256 fee;
        // true if order is already processed
        bool finished;
    }

    struct ProcessOrderArgs {
        // minimal swap output amount to prevent manipulation
        uint256 swapAmountOutMin;
        // swap path
        address[] swapPath;
    }

    event OrderCreated(
        uint256 indexed orderId,
        address indexed owner,
        address indexed otoken
    );
    event OrderFinished(uint256 indexed orderId, bool indexed cancelled);

    function createOrder(
        address _otoken,
        uint256 _amount,
        uint256 _vaultId,
        address _toToken
    ) external;

    function cancelOrder(uint256 _orderId) external;

    function shouldProcessOrder(uint256 _orderId) external view returns (bool);

    function processOrder(uint256 _orderId, ProcessOrderArgs calldata _orderArg)
        external;

    function processOrders(
        uint256[] calldata _orderIds,
        ProcessOrderArgs[] calldata _orderArgs
    ) external;

    function getOrdersLength() external view returns (uint256);

    function getOrders() external view returns (Order[] memory);

    function getOrder(uint256 _orderId) external view returns (Order memory);

    function isPairAllowed(address _token0, address _token1)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IPokeMe {
    function createTask(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external;

    function cancelTask(bytes32 _taskId) external;

    // function withdrawFunds(uint256 _amount) external;

    function getTaskId(
        address _taskCreator,
        address _execAddress,
        bytes4 _selector
    ) external pure returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ITaskTreasury {
    function withdrawFunds(
        address payable _receiver,
        address _token,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IResolver {
    function getProcessableOrders()
        external
        returns (bool canExec, bytes memory execPayload);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IAddressBook {
    function getOtokenImpl() external view returns (address);

    function getOtokenFactory() external view returns (address);

    function getWhitelist() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);

    function getMarginPool() external view returns (address);

    function getMarginCalculator() external view returns (address);

    function getLiquidationManager() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);

    /* Setters */

    function setOtokenImpl(address _otokenImpl) external;

    function setOtokenFactory(address _factory) external;

    function setOracleImpl(address _otokenImpl) external;

    function setWhitelist(address _whitelist) external;

    function setController(address _controller) external;

    function setMarginPool(address _marginPool) external;

    function setMarginCalculator(address _calculator) external;

    function setLiquidationManager(address _liquidationManager) external;

    function setAddress(bytes32 _id, address _newImpl) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {Actions} from "../external/OpynActions.sol";
import {MarginVault} from "../external/OpynVault.sol";

interface IGammaController {
    function operate(Actions.ActionArgs[] memory _actions) external;

    function isSettlementAllowed(address _otoken) external view returns (bool);

    function isOperator(address _owner, address _operator)
        external
        view
        returns (bool);

    function getPayout(address _otoken, uint256 _amount)
        external
        view
        returns (uint256);

    function getVaultWithDetails(address _owner, uint256 _vaultId)
        external
        view
        returns (
            MarginVault.Vault memory,
            uint256,
            uint256
        );

    function getVault(address _owner, uint256 _vaultId)
        external
        view
        returns (MarginVault.Vault memory);

    function getAccountVaultCounter(address _accountOwner)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IWhitelist {
    function isWhitelistedOtoken(address _otoken) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {MarginVault} from "../external/OpynVault.sol";

interface IMarginCalculator {
    function getExcessCollateral(
        MarginVault.Vault calldata _vault,
        uint256 _vaultType
    ) external view returns (uint256 netValue, bool isExcess);
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.8.0;

/**
 * @title Actions
 * @author Opyn Team
 * @notice A library that provides a ActionArgs struct, sub types of Action structs, and functions to parse ActionArgs into specific Actions.
 */
library Actions {
    // possible actions that can be performed
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call,
        Liquidate
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    struct MintArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the asset will be minted
        uint256 vaultId;
        // address to which we transfer the minted oTokens
        address to;
        // oToken that is to be minted
        address otoken;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of oTokens that is to be minted
        uint256 amount;
    }

    struct BurnArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the oToken will be burned
        uint256 vaultId;
        // address from which we transfer the oTokens
        address from;
        // oToken that is to be burned
        address otoken;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of oTokens that is to be burned
        uint256 amount;
    }

    struct OpenVaultArgs {
        // address of the account owner
        address owner;
        // vault id to create
        uint256 vaultId;
        // vault type, 0 for spread/max loss and 1 for naked margin vault
        uint256 vaultType;
    }

    struct DepositArgs {
        // address of the account owner
        address owner;
        // index of the vault to which the asset will be added
        uint256 vaultId;
        // address from which we transfer the asset
        address from;
        // asset that is to be deposited
        address asset;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of asset that is to be deposited
        uint256 amount;
    }

    struct RedeemArgs {
        // address to which we pay out the oToken proceeds
        address receiver;
        // oToken that is to be redeemed
        address otoken;
        // amount of oTokens that is to be redeemed
        uint256 amount;
    }

    struct WithdrawArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the asset will be withdrawn
        uint256 vaultId;
        // address to which we transfer the asset
        address to;
        // asset that is to be withdrawn
        address asset;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of asset that is to be withdrawn
        uint256 amount;
    }

    struct SettleVaultArgs {
        // address of the account owner
        address owner;
        // index of the vault to which is to be settled
        uint256 vaultId;
        // address to which we transfer the remaining collateral
        address to;
    }

    struct LiquidateArgs {
        // address of the vault owner to liquidate
        address owner;
        // address of the liquidated collateral receiver
        address receiver;
        // vault id to liquidate
        uint256 vaultId;
        // amount of debt(otoken) to repay
        uint256 amount;
        // chainlink round id
        uint256 roundId;
    }

    struct CallArgs {
        // address of the callee contract
        address callee;
        // data field for external calls
        bytes data;
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an open vault action
     * @param _args general action arguments structure
     * @return arguments for a open vault action
     */
    function _parseOpenVaultArgs(ActionArgs memory _args)
        internal
        pure
        returns (OpenVaultArgs memory)
    {
        require(
            _args.actionType == ActionType.OpenVault,
            "Actions: can only parse arguments for open vault actions"
        );
        require(
            _args.owner != address(0),
            "Actions: cannot open vault for an invalid account"
        );

        // if not _args.data included, vault type will be 0 by default
        uint256 vaultType;

        if (_args.data.length == 32) {
            // decode vault type from _args.data
            vaultType = abi.decode(_args.data, (uint256));
        }

        // for now we only have 2 vault types
        require(
            vaultType < 2,
            "Actions: cannot open vault with an invalid type"
        );

        return
            OpenVaultArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                vaultType: vaultType
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a mint action
     * @param _args general action arguments structure
     * @return arguments for a mint action
     */
    function _parseMintArgs(ActionArgs memory _args)
        internal
        pure
        returns (MintArgs memory)
    {
        require(
            _args.actionType == ActionType.MintShortOption,
            "Actions: can only parse arguments for mint actions"
        );
        require(
            _args.owner != address(0),
            "Actions: cannot mint from an invalid account"
        );

        return
            MintArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                to: _args.secondAddress,
                otoken: _args.asset,
                index: _args.index,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a burn action
     * @param _args general action arguments structure
     * @return arguments for a burn action
     */
    function _parseBurnArgs(ActionArgs memory _args)
        internal
        pure
        returns (BurnArgs memory)
    {
        require(
            _args.actionType == ActionType.BurnShortOption,
            "Actions: can only parse arguments for burn actions"
        );
        require(
            _args.owner != address(0),
            "Actions: cannot burn from an invalid account"
        );

        return
            BurnArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                from: _args.secondAddress,
                otoken: _args.asset,
                index: _args.index,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a deposit action
     * @param _args general action arguments structure
     * @return arguments for a deposit action
     */
    function _parseDepositArgs(ActionArgs memory _args)
        internal
        pure
        returns (DepositArgs memory)
    {
        require(
            (_args.actionType == ActionType.DepositLongOption) ||
                (_args.actionType == ActionType.DepositCollateral),
            "Actions: can only parse arguments for deposit actions"
        );
        require(
            _args.owner != address(0),
            "Actions: cannot deposit to an invalid account"
        );

        return
            DepositArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                from: _args.secondAddress,
                asset: _args.asset,
                index: _args.index,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a withdraw action
     * @param _args general action arguments structure
     * @return arguments for a withdraw action
     */
    function _parseWithdrawArgs(ActionArgs memory _args)
        internal
        pure
        returns (WithdrawArgs memory)
    {
        require(
            (_args.actionType == ActionType.WithdrawLongOption) ||
                (_args.actionType == ActionType.WithdrawCollateral),
            "Actions: can only parse arguments for withdraw actions"
        );
        require(
            _args.owner != address(0),
            "Actions: cannot withdraw from an invalid account"
        );
        require(
            _args.secondAddress != address(0),
            "Actions: cannot withdraw to an invalid account"
        );

        return
            WithdrawArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                to: _args.secondAddress,
                asset: _args.asset,
                index: _args.index,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an redeem action
     * @param _args general action arguments structure
     * @return arguments for a redeem action
     */
    function _parseRedeemArgs(ActionArgs memory _args)
        internal
        pure
        returns (RedeemArgs memory)
    {
        require(
            _args.actionType == ActionType.Redeem,
            "Actions: can only parse arguments for redeem actions"
        );
        require(
            _args.secondAddress != address(0),
            "Actions: cannot redeem to an invalid account"
        );

        return
            RedeemArgs({
                receiver: _args.secondAddress,
                otoken: _args.asset,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a settle vault action
     * @param _args general action arguments structure
     * @return arguments for a settle vault action
     */
    function _parseSettleVaultArgs(ActionArgs memory _args)
        internal
        pure
        returns (SettleVaultArgs memory)
    {
        require(
            _args.actionType == ActionType.SettleVault,
            "Actions: can only parse arguments for settle vault actions"
        );
        require(
            _args.owner != address(0),
            "Actions: cannot settle vault for an invalid account"
        );
        require(
            _args.secondAddress != address(0),
            "Actions: cannot withdraw payout to an invalid account"
        );

        return
            SettleVaultArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                to: _args.secondAddress
            });
    }

    function _parseLiquidateArgs(ActionArgs memory _args)
        internal
        pure
        returns (LiquidateArgs memory)
    {
        require(
            _args.actionType == ActionType.Liquidate,
            "Actions: can only parse arguments for liquidate action"
        );
        require(
            _args.owner != address(0),
            "Actions: cannot liquidate vault for an invalid account owner"
        );
        require(
            _args.secondAddress != address(0),
            "Actions: cannot send collateral to an invalid account"
        );
        require(
            _args.data.length == 32,
            "Actions: cannot parse liquidate action with no round id"
        );

        // decode chainlink round id from _args.data
        uint256 roundId = abi.decode(_args.data, (uint256));

        return
            LiquidateArgs({
                owner: _args.owner,
                receiver: _args.secondAddress,
                vaultId: _args.vaultId,
                amount: _args.amount,
                roundId: roundId
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a call action
     * @param _args general action arguments structure
     * @return arguments for a call action
     */
    function _parseCallArgs(ActionArgs memory _args)
        internal
        pure
        returns (CallArgs memory)
    {
        require(
            _args.actionType == ActionType.Call,
            "Actions: can only parse arguments for call actions"
        );
        require(
            _args.secondAddress != address(0),
            "Actions: target address cannot be address(0)"
        );

        return CallArgs({callee: _args.secondAddress, data: _args.data});
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.8.0;

/**
 * @title MarginVault
 * @author Opyn Team
 * @notice A library that provides the Controller with a Vault struct and the functions that manipulate vaults.
 * Vaults describe discrete position combinations of long options, short options, and collateral assets that a user can have.
 */
library MarginVault {
    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        // addresses of oTokens a user has shorted (i.e. written) against this vault
        address[] shortOtokens;
        // addresses of oTokens a user has bought and deposited in this vault
        // user can be long oTokens without opening a vault (e.g. by buying on a DEX)
        // generally, long oTokens will be 'deposited' in vaults to act as collateral in order to write oTokens against (i.e. in spreads)
        address[] longOtokens;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of oTokens minted/written for each oToken address in shortOtokens
        uint256[] shortAmounts;
        // quantity of oTokens owned and held in the vault for each oToken address in longOtokens
        uint256[] longAmounts;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IOtoken {
    function addressBook() external view returns (address);

    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external;

    function getOtokenDetails()
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            bool
        );

    function mintOtoken(address account, uint256 amount) external;

    function burnOtoken(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

