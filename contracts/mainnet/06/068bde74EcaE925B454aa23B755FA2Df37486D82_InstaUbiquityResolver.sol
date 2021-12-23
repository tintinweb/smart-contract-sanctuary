// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces.sol";

contract Helpers {
    address internal constant dsaConnectorAddress = 0x8EC066D75d665616A94F2EccDBE49b54eAeefc78;

    IUbiquityAlgorithmicDollarManager internal constant ubiquityManager =
        IUbiquityAlgorithmicDollarManager(0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98);

    struct UbiquityAddresses {
        address ubiquityManagerAddress;
        address masterChefAddress;
        address twapOracleAddress;
        address uadAddress;
        address uarAddress;
        address udebtAddress;
        address ubqAddress;
        address cr3Address;
        address uadcrv3Address;
        address bondingShareAddress;
        address dsaResolverAddress;
        address dsaConnectorAddress;
    }

    struct UbiquityDatas {
        uint256 twapPrice;
        uint256 uadTotalSupply;
        uint256 uarTotalSupply;
        uint256 udebtTotalSupply;
        uint256 ubqTotalSupply;
        uint256 uadcrv3TotalSupply;
        uint256 bondingSharesTotalSupply;
        uint256 lpTotalSupply;
    }

    struct UbiquityInventory {
        uint256 uadBalance;
        uint256 uarBalance;
        uint256 udebtBalance;
        uint256 ubqBalance;
        uint256 crv3Balance;
        uint256 uad3crvBalance;
        uint256 ubqRewards;
        uint256 bondingSharesBalance;
        uint256 lpBalance;
        uint256 bondBalance;
        uint256 ubqPendingBalance;
    }

    function getMasterChef() internal view returns (IMasterChefV2) {
        return IMasterChefV2(ubiquityManager.masterChefAddress());
    }

    function getTWAPOracle() internal view returns (ITWAPOracle) {
        return ITWAPOracle(ubiquityManager.twapOracleAddress());
    }

    function getUAD() internal view returns (IERC20) {
        return IERC20(ubiquityManager.dollarTokenAddress());
    }

    function getUAR() internal view returns (IERC20) {
        return IERC20(ubiquityManager.autoRedeemTokenAddress());
    }

    function getUBQ() internal view returns (IERC20) {
        return IERC20(ubiquityManager.governanceTokenAddress());
    }

    function getCRV3() internal view returns (IERC20) {
        return IERC20(ubiquityManager.curve3PoolTokenAddress());
    }

    function getUADCRV3() internal view returns (IERC20) {
        return IERC20(ubiquityManager.stableSwapMetaPoolAddress());
    }

    function getUDEBT() internal view returns (IERC1155) {
        return IERC1155(ubiquityManager.debtCouponAddress());
    }

    function getBondingShare() internal view returns (IBondingShareV2) {
        return IBondingShareV2(ubiquityManager.bondingShareAddress());
    }

    function getBondingShareIds(address user) internal view returns (uint256[] memory bondIds) {
        return getBondingShare().holderTokens(user);
    }

    function getBondingShareBalanceOf(address user) internal view returns (uint256 balance) {
        uint256[] memory bondIds = getBondingShareIds(user);
        for (uint256 i = 0; i < bondIds.length; i += 1) {
            balance += getBondingShare().getBond(bondIds[i]).lpAmount;
        }
    }

    function getPendingUBQ(address user) internal view returns (uint256 amount) {
        uint256[] memory bondIds = getBondingShareIds(user);
        for (uint256 i = 0; i < bondIds.length; i += 1) {
            amount += getMasterChef().pendingUGOV(bondIds[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC1155.sol";

interface ITWAPOracle {
    function update() external;

    function token0() external view returns (address);

    function consult(address token) external view returns (uint256 amountOut);
}

interface IUbiquityAlgorithmicDollarManager {
    function twapOracleAddress() external view returns (address);

    function dollarTokenAddress() external view returns (address);

    function autoRedeemTokenAddress() external view returns (address);

    function governanceTokenAddress() external view returns (address);

    function curve3PoolTokenAddress() external view returns (address);

    function stableSwapMetaPoolAddress() external view returns (address);

    function debtCouponAddress() external view returns (address);

    function bondingShareAddress() external view returns (address);

    function masterChefAddress() external view returns (address);
}

interface IBondingShareV2 {
    struct Bond {
        address minter;
        uint256 lpFirstDeposited;
        uint256 creationBlock;
        uint256 lpRewardDebt;
        uint256 endBlock;
        uint256 lpAmount;
    }

    function holderTokens(address) external view returns (uint256[] memory);

    function totalLP() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getBond(uint256 id) external view returns (Bond memory);
}

interface IMasterChefV2 {
    function lastPrice() external view returns (uint256);

    function pendingUGOV(uint256) external view returns (uint256);

    function minPriceDiffToUpdateMultiplier() external view returns (uint256);

    function pool() external view returns (uint256 lastRewardBlock, uint256 accuGOVPerShare);

    function totalShares() external view returns (uint256);

    function uGOVDivider() external view returns (uint256);

    function uGOVPerBlock() external view returns (uint256);

    function uGOVmultiplier() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
pragma solidity ^0.8.4;

import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
    function getUbiquityAddresses() public view returns (UbiquityAddresses memory addresses) {
        addresses.ubiquityManagerAddress = address(ubiquityManager);
        addresses.masterChefAddress = address(getMasterChef());
        addresses.twapOracleAddress = address(getTWAPOracle());
        addresses.uadAddress = address(getUAD());
        addresses.uarAddress = address(getUAR());
        addresses.udebtAddress = address(getUDEBT());
        addresses.ubqAddress = address(getUBQ());
        addresses.cr3Address = address(getCRV3());
        addresses.uadcrv3Address = address(getUADCRV3());
        addresses.bondingShareAddress = address(getBondingShare());
        addresses.dsaResolverAddress = address(this);
        addresses.dsaConnectorAddress = address(dsaConnectorAddress);
    }

    function getUbiquityDatas() public view returns (UbiquityDatas memory datas) {
        datas.twapPrice = getTWAPOracle().consult(getTWAPOracle().token0());
        datas.uadTotalSupply = getUAD().totalSupply();
        datas.uarTotalSupply = getUAR().totalSupply();
        datas.ubqTotalSupply = getUBQ().totalSupply();
        datas.uadcrv3TotalSupply = getUADCRV3().totalSupply();
        datas.bondingSharesTotalSupply = getBondingShare().totalSupply();
        datas.lpTotalSupply = getBondingShare().totalLP();
    }

    function getUbiquityInventory(address user) public view returns (UbiquityInventory memory inventory) {
        inventory.uadBalance = getUAD().balanceOf(user);
        inventory.uarBalance = getUAR().balanceOf(user);
        inventory.ubqBalance = getUBQ().balanceOf(user);
        inventory.crv3Balance = getCRV3().balanceOf(user);
        inventory.uad3crvBalance = getUADCRV3().balanceOf(user);
        inventory.bondingSharesBalance = getBondingShareBalanceOf(user);
        inventory.lpBalance = getBondingShareBalanceOf(user);
        inventory.bondBalance = getBondingShareIds(user).length;
        inventory.ubqPendingBalance = getPendingUBQ(user);
    }
}

contract InstaUbiquityResolver is Resolver {
    string public constant name = "Ubiquity-Resolver-v0.1";
}