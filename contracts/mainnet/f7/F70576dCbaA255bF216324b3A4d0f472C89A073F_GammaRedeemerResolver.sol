// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {IGammaRedeemerV1} from "./interfaces/IGammaRedeemerV1.sol";
import {IGammaOperator} from "./interfaces/IGammaOperator.sol";
import {IResolver} from "./interfaces/IResolver.sol";
import {MarginVault} from "./external/OpynVault.sol";

/// @author Willy Shen
/// @title GammaRedeemer Resolver
/// @notice A GammaRedeemer resolver for Gelato PokeMe checks
contract GammaRedeemerResolver is IResolver {
    address public redeemer;

    constructor(address _redeemer) {
        redeemer = _redeemer;
    }

    /**
     * @notice return if a specific order can be processed
     * @param _orderId id of order
     * @return true if order can be proceseed without a revert
     */
    function canProcessOrder(uint256 _orderId) public view returns (bool) {
        IGammaRedeemerV1.Order memory order = IGammaRedeemerV1(redeemer)
            .getOrder(_orderId);

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

            try IGammaOperator(redeemer).getVaultOtoken(vault) returns (
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
            } catch {
                return false;
            }
        } else {
            if (
                !IGammaOperator(redeemer).hasExpiredAndSettlementAllowed(
                    order.otoken
                )
            ) return false;
        }

        return true;
    }

    /**
     * @notice return list of processable orderIds
     * @return an array of orderIds available to process
     * @dev order is processable if:
     * 1. it is profitable to process (shouldProcessOrder)
     * 2. it can be processed without reverting (canProcessOrder)
     * 3. it is not included yet (for same type of orders, process it one at a time)
     */
    function getProcessableOrders()
        public
        view
        override
        returns (uint256[] memory)
    {
        IGammaRedeemerV1.Order[] memory orders = IGammaRedeemerV1(redeemer)
            .getOrders();

        // Only proceess duplicate orders one at a time
        bytes32[] memory preCheckHashes = new bytes32[](orders.length);
        bytes32[] memory postCheckHashes = new bytes32[](orders.length);

        uint256 orderIdsLength;
        for (uint256 i = 0; i < orders.length; i++) {
            if (
                IGammaRedeemerV1(redeemer).shouldProcessOrder(i) &&
                canProcessOrder(i) &&
                !containDuplicateOrderType(orders[i], preCheckHashes)
            ) {
                preCheckHashes[i] = getOrderHash(orders[i]);
                orderIdsLength++;
            }
        }

        uint256 counter;
        uint256[] memory orderIds = new uint256[](orderIdsLength);
        for (uint256 i = 0; i < orders.length; i++) {
            if (
                IGammaRedeemerV1(redeemer).shouldProcessOrder(i) &&
                canProcessOrder(i) &&
                !containDuplicateOrderType(orders[i], postCheckHashes)
            ) {
                postCheckHashes[i] = getOrderHash(orders[i]);
                orderIds[counter] = i;
                counter++;
            }
        }
        return orderIds;
    }

    /**
     * @notice return if order is already included
     * @param order struct to check
     * @param hashes list of hashed orders
     * @return containDuplicate if hashes already contain a same order type.
     */
    function containDuplicateOrderType(
        IGammaRedeemerV1.Order memory order,
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
    function getOrderHash(IGammaRedeemerV1.Order memory order)
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

interface IGammaRedeemerV1 {
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
        // convert proceed to ETH, currently unused
        bool toETH;
        // fee in 1/10.000
        uint256 fee;
        // true if order is already processed
        bool finished;
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
        uint256 _vaultId
    ) external;

    function cancelOrder(uint256 _orderId) external;

    function shouldProcessOrder(uint256 _orderId) external view returns (bool);

    function processOrder(uint256 _orderId) external;

    function getOrdersLength() external view returns (uint256);

    function getOrders() external view returns (Order[] memory);

    function getOrder(uint256 _orderId) external view returns (Order memory);
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

    function getVaultOtoken(MarginVault.Vault memory _vault)
        external
        pure
        returns (address);

    function getVaultWithDetails(address _owner, uint256 _vaultId)
        external
        view
        returns (
            MarginVault.Vault memory,
            uint256,
            uint256
        );

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
    function getProcessableOrders() external returns (uint256[] memory);
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