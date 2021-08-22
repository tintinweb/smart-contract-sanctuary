// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {IAutoGamma} from "./interfaces/IAutoGamma.sol";
import {IGammaOperator} from "./interfaces/IGammaOperator.sol";
import {IResolver} from "./interfaces/IResolver.sol";
import {MarginVault} from "./external/OpynVault.sol";
import {IUniswapRouter} from "./interfaces/IUniswapRouter.sol";

/// @author Willy Shen
/// @title AutoGamma Resolver
/// @notice AutoGamma resolver for Gelato PokeMe checks
contract AutoGammaResolver is IResolver {
    address public redeemer;
    address public uniRouter;

    uint256 public maxSlippage = 50; // 0.5%
    address public owner;

    constructor(address _redeemer, address _uniRouter) {
        redeemer = _redeemer;
        uniRouter = _uniRouter;
        owner = msg.sender;
    }

    function setMaxSlippage(uint256 _maxSlippage) public {
        require(msg.sender == owner && _maxSlippage <= 500); // sanity check max slippage under 5%
        maxSlippage = _maxSlippage;
    }

    /**
     * @notice return if a specific order can be processed
     * @param _orderId id of order
     * @return true if order can be proceseed without a revert
     */
    function canProcessOrder(uint256 _orderId) public view returns (bool) {
        IAutoGamma.Order memory order = IAutoGamma(redeemer).getOrder(_orderId);

        if (order.isSeller) {
            if (
                !IGammaOperator(redeemer).isValidVaultId(
                    order.owner,
                    order.vaultId
                ) || !IGammaOperator(redeemer).isOperatorOf(order.owner)
            ) return false;

            (
                MarginVault.Vault memory vault,
                uint256 typeVault,

            ) = IGammaOperator(redeemer).getVaultWithDetails(
                order.owner,
                order.vaultId
            );

            try IGammaOperator(redeemer).getVaultOtokenByVault(vault) returns (
                address otoken
            ) {
                if (
                    !IGammaOperator(redeemer).hasExpiredAndSettlementAllowed(
                        otoken
                    )
                ) return false;

                (uint256 payout, bool isValidVault) = IGammaOperator(redeemer)
                    .getExcessCollateral(vault, typeVault);
                if (!isValidVault || payout == 0) return false;

                if (order.toToken != address(0)) {
                    address collateral = IGammaOperator(redeemer)
                        .getOtokenCollateral(otoken);
                    if (
                        !IAutoGamma(redeemer).isPairAllowed(
                            collateral,
                            order.toToken
                        )
                    ) return false;
                }
            } catch {
                return false;
            }
        } else {
            if (
                !IGammaOperator(redeemer).hasExpiredAndSettlementAllowed(
                    order.otoken
                )
            ) return false;

            if (order.toToken != address(0)) {
                address collateral = IGammaOperator(redeemer)
                    .getOtokenCollateral(order.otoken);
                if (
                    !IAutoGamma(redeemer).isPairAllowed(
                        collateral,
                        order.toToken
                    )
                ) return false;
            }
        }

        return true;
    }

    /**
     * @notice return payout of an order
     * @param _orderId id of order
     * @return payoutToken token address of payout
     * @return payoutAmount amount of payout
     */
    function getOrderPayout(uint256 _orderId)
        public
        view
        returns (address payoutToken, uint256 payoutAmount)
    {
        IAutoGamma.Order memory order = IAutoGamma(redeemer).getOrder(_orderId);

        if (order.isSeller) {
            (
                MarginVault.Vault memory vault,
                uint256 typeVault,

            ) = IGammaOperator(redeemer).getVaultWithDetails(
                order.owner,
                order.vaultId
            );

            address otoken = IGammaOperator(redeemer).getVaultOtokenByVault(
                vault
            );
            payoutToken = IGammaOperator(redeemer).getOtokenCollateral(otoken);

            (payoutAmount, ) = IGammaOperator(redeemer).getExcessCollateral(
                vault,
                typeVault
            );
        } else {
            payoutToken = IGammaOperator(redeemer).getOtokenCollateral(
                order.otoken
            );

            uint256 actualAmount = IGammaOperator(redeemer).getRedeemableAmount(
                order.owner,
                order.otoken,
                order.amount
            );
            payoutAmount = IGammaOperator(redeemer).getRedeemPayout(
                order.otoken,
                actualAmount
            );
        }
    }

    /**
     * @notice return list of processable orderIds
     * @return canExec if gelato should execute
     * @return execPayload the function and data to be executed by gelato
     * @dev order is processable if:
     * 1. it is profitable to process (shouldProcessOrder)
     * 2. it can be processed without reverting (canProcessOrder)
     * 3. it is not included yet (for same type of orders, process it one at a time)
     */
    function getProcessableOrders()
        public
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {
        IAutoGamma.Order[] memory orders = IAutoGamma(redeemer).getOrders();

        // Only proceess duplicate orders one at a time
        bytes32[] memory preCheckHashes = new bytes32[](orders.length);
        bytes32[] memory postCheckHashes = new bytes32[](orders.length);

        uint256 orderIdsLength;
        for (uint256 i = 0; i < orders.length; i++) {
            if (
                IAutoGamma(redeemer).shouldProcessOrder(i) &&
                canProcessOrder(i) &&
                !containDuplicateOrderType(orders[i], preCheckHashes)
            ) {
                preCheckHashes[i] = getOrderHash(orders[i]);
                orderIdsLength++;
            }
        }

        if (orderIdsLength > 0) {
            canExec = true;
        }

        uint256 counter;
        uint256[] memory orderIds = new uint256[](orderIdsLength);


            IAutoGamma.ProcessOrderArgs[] memory orderArgs
         = new IAutoGamma.ProcessOrderArgs[](orderIdsLength);
        for (uint256 i = 0; i < orders.length; i++) {
            if (
                IAutoGamma(redeemer).shouldProcessOrder(i) &&
                canProcessOrder(i) &&
                !containDuplicateOrderType(orders[i], postCheckHashes)
            ) {
                postCheckHashes[i] = getOrderHash(orders[i]);
                orderIds[counter] = i;

                if (orders[i].toToken != address(0)) {
                    // determine amountOutMin for swap
                    (
                        address payoutToken,
                        uint256 payoutAmount
                    ) = getOrderPayout(i);

                    payoutAmount =
                        payoutAmount -
                        ((orders[i].fee * payoutAmount) / 10_000);

                    address[] memory path = new address[](2);
                    path[0] = payoutToken;
                    path[1] = orders[i].toToken;

                    uint256[] memory amounts = IUniswapRouter(uniRouter)
                        .getAmountsOut(payoutAmount, path);
                    uint256 amountOutMin = amounts[1] -
                        ((amounts[1] * maxSlippage) / 10_000);

                    orderArgs[counter].swapAmountOutMin = amountOutMin;
                    orderArgs[counter].swapPath = path;
                }

                counter++;
            }
        }

        execPayload = abi.encodeWithSelector(
            IAutoGamma.processOrders.selector,
            orderIds,
            orderArgs
        );
    }

    /**
     * @notice return if order is already included
     * @param order struct to check
     * @param hashes list of hashed orders
     * @return containDuplicate if hashes already contain a same order type.
     */
    function containDuplicateOrderType(
        IAutoGamma.Order memory order,
        bytes32[] memory hashes
    ) public pure returns (bool containDuplicate) {
        bytes32 orderHash = getOrderHash(order);

        for (uint256 j = 0; j < hashes.length; j++) {
            if (hashes[j] == orderHash) {
                containDuplicate = true;
                break;
            }
        }
    }

    /**
     * @notice return hash of the order
     * @param order struct to hash
     * @return orderHash hash depending on the order's type
     */
    function getOrderHash(IAutoGamma.Order memory order)
        public
        pure
        returns (bytes32 orderHash)
    {
        if (order.isSeller) {
            orderHash = keccak256(abi.encode(order.owner, order.vaultId));
        } else {
            orderHash = keccak256(abi.encode(order.owner, order.otoken));
        }
    }
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {MarginVault} from "../external/OpynVault.sol";

interface IGammaOperator {
    function isValidVaultId(address _owner, uint256 _vaultId)
        external
        view
        returns (bool);

    function getExcessCollateral(
        MarginVault.Vault memory _vault,
        uint256 _typeVault
    ) external view returns (uint256, bool);

    function getVaultOtokenByVault(MarginVault.Vault memory _vault)
        external
        pure
        returns (address);

    function getVaultOtoken(address _owner, uint256 _vaultId)
        external
        view
        returns (address);

    function getVaultWithDetails(address _owner, uint256 _vaultId)
        external
        view
        returns (
            MarginVault.Vault memory,
            uint256,
            uint256
        );

    function getOtokenCollateral(address _otoken)
        external
        pure
        returns (address);

    function getRedeemPayout(address _otoken, uint256 _amount)
        external
        view
        returns (uint256);

    function getRedeemableAmount(
        address _owner,
        address _otoken,
        uint256 _amount
    ) external view returns (uint256);

    function isSettlementAllowed(address _otoken) external view returns (bool);

    function isOperatorOf(address _owner) external view returns (bool);

    function hasExpiredAndSettlementAllowed(address _otoken)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IResolver {
    function getProcessableOrders()
        external
        returns (bool canExec, bytes memory execPayload);
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