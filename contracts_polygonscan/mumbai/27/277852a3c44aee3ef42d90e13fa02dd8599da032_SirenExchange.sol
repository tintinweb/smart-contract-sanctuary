// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0 <=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./ISirenTradeAMM.sol";
import "../series/SeriesLibrary.sol";

/// This is an implementation of exchanging collateral tokens for different collateral tokens that represent the underlying asset for series in SirenMarkets
/// this then allows you to Buy and Sell bTokens as well as to Sell wTokens using MinterAmm.sol
///
/// For example, a sender could use WETH to trade on WBTC/USDC strikes of WBTC/USDC calls/puts using
/// WETH as the collateral instead of needing to have either WETH or USDC for call and puts.
/// This allows senders to trade multiple tokens for call or put options without needing to exchange these tokens outside of siren
///
/// This is accomplished using UniswapV2Router02 interface https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02
/// Since SirenMarkets is deployed on polygon so the routers used are supplied by:
///                                                                               QuickSwap: https://github.com/QuickSwap/quickswap-core
///                                                                               SusiSwap: https://dev.sushi.com/sushiswap/contracts
///
/// We take the router address in as a variable so we can choose which router has a better reserve at the time of the exchange.
contract SirenExchange is ERC1155Holder {
    IERC1155 public immutable erc1155Controller;

    constructor(IERC1155 erc1155Controller_) public {
        erc1155Controller = erc1155Controller_;
    }

    event BTokenBuy(
        uint256[] amounts,
        address[] path,
        address indexed sirenAmmAddress,
        uint256 bTokenAmount,
        uint64 indexed seriesId,
        address buyer
    );

    event BTokenSell(
        uint256[] amounts,
        address[] path,
        address indexed sirenAmmAddress,
        uint256 bTokenAmount,
        uint64 indexed seriesId,
        address seller
    );

    event WTokenSell(
        uint256[] amounts,
        address[] path,
        address indexed sirenAmmAddress,
        uint256 wTokenAmount,
        uint64 indexed seriesId,
        address seller
    );

    /// @dev Returns bytes to be used in safeTransferFrom ( prevents stack to deep error )
    function dataReturn() public returns (bytes memory data) {
        return data;
    }

    /// @notice Sell the wToken of a given series to the AMM in exchange for collateral token
    /// @param seriesId The ID of the Series to buy wToken on
    /// @param bTokenAmount The amount of bToken to buy (bToken has the same decimals as the underlying)
    /// @param path The path of the collateral token we supply to the collateral the series wishes to receive
    /// @param tokenAmountInMaximum The largest amount of collateral the caller is willing to pay for the bTokens
    /// @param sirenAmmAddress address of the amm that we wish to call
    /// @param deadline deadline the transaction must be completed by
    /// @param _router address of the router we wish to use ( QuickSwap or SushiSwap )
    /// @dev Exchange collateral for bToken for a given series.
    /// We supply a collateral that is not the underlying token of this series and then find the route
    /// Of the collateral provided to the underlying token using Uniswap router the addresses provided are currently from QuickSwap and SushiSwap.
    /// We then call bTokenBuy in MinterAMM to buy the bTokens and then send the bought bTokens to the user
    function bTokenBuy(
        uint64 seriesId,
        uint256 bTokenAmount,
        address[] calldata path,
        uint256 tokenAmountInMaximum,
        address sirenAmmAddress,
        uint256 deadline,
        address _router
    ) external returns (uint256[] memory amounts) {
        //Calculate the amount of underlying collateral we need to provide to get the desired bTokens
        uint256 collateralPremium = ISirenTradeAMM(sirenAmmAddress)
            .bTokenGetCollateralIn(seriesId, bTokenAmount);

        //Calculate the amount of token we need to provide to the router so we can get the needed underlying collateral
        uint256[] memory amountsIn = IUniswapV2Router02(_router).getAmountsIn(
            collateralPremium,
            path
        );

        require(amountsIn[0] <= tokenAmountInMaximum, "Not Enough tokens sent");

        //Transfer the tokens from user to the contract
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            amountsIn[0]
        );
        TransferHelper.safeApprove(
            path[0],
            address(IUniswapV2Router02(_router)),
            amountsIn[0]
        );

        // Executes the swap giving the needed collateral amount to the siren exchange
        amounts = IUniswapV2Router02(_router).swapTokensForExactTokens(
            collateralPremium,
            amountsIn[0],
            path,
            address(this),
            deadline
        );

        TransferHelper.safeApprove(
            path[path.length - 1],
            sirenAmmAddress,
            collateralPremium
        );

        //Call MinterAmm bTokenBuy contract
        ISirenTradeAMM(sirenAmmAddress).bTokenBuy(
            seriesId,
            bTokenAmount,
            collateralPremium
        );

        //Transfer the btokens to the correct address ( caller of this contract)
        erc1155Controller.safeTransferFrom(
            address(this),
            msg.sender,
            SeriesLibrary.bTokenIndex(seriesId),
            bTokenAmount,
            dataReturn()
        );

        emit BTokenBuy(
            amounts,
            path,
            sirenAmmAddress,
            bTokenAmount,
            seriesId,
            msg.sender
        );

        return amounts;
    }

    /// @notice Sell the wToken of a given series to the AMM in exchange for collateral token
    /// @param seriesId The ID of the Series to buy wToken on
    /// @param bTokenAmount The amount of bToken to sell (bToken has the same decimals as the underlying)
    /// @param path The path of the collateral token of the series to the collateral the caller wishes to receive
    /// @param tokenAmountOutMinimum The lowest amount of collateral the caller is willing to receive as payment
    /// @param sirenAmmAddress address of the amm that we wish to call
    /// @param deadline deadline the transaction must be completed by
    /// @param _router address of the router we wish to use ( QuickSwap or SushiSwap )
    /// We supply a bToken and then select which collateral we wish to receive as our payment ( if it isnt the underlying asset )
    function bTokenSell(
        uint64 seriesId,
        uint256 bTokenAmount,
        address[] calldata path,
        uint256 tokenAmountOutMinimum,
        address sirenAmmAddress,
        uint256 deadline,
        address _router
    ) external returns (uint256[] memory amounts) {
        //Calculate the amount of collateral we will receive from our provided bTokens on the amm
        //The naming is reversed because its from the routers perspective
        uint256 collateralAmountIn = ISirenTradeAMM(sirenAmmAddress)
            .bTokenGetCollateralOut(seriesId, bTokenAmount);

        //Calculate the amount of token we will receive for the collateral we are providing from the amm
        uint256[] memory amountsOut = IUniswapV2Router02(_router).getAmountsOut(
            collateralAmountIn,
            path
        );

        require(
            amountsOut[amountsOut.length - 1] >= tokenAmountOutMinimum,
            "Minimum token ammunt out not met"
        );

        //Transfer bToken from the user to the exchange contract
        erc1155Controller.safeTransferFrom(
            msg.sender,
            address(this),
            SeriesLibrary.bTokenIndex(seriesId),
            bTokenAmount,
            dataReturn()
        );

        erc1155Controller.setApprovalForAll(address(sirenAmmAddress), true);

        //Sell the bTokens back to the Amm
        ISirenTradeAMM(sirenAmmAddress).bTokenSell(
            seriesId,
            bTokenAmount,
            collateralAmountIn
        );

        TransferHelper.safeApprove(
            path[0],
            address(IUniswapV2Router02(_router)),
            amountsOut[0]
        );

        // Executes the swap returning the desired collateral directly back to the sender
        amounts = IUniswapV2Router02(_router).swapExactTokensForTokens(
            collateralAmountIn,
            amountsOut[amountsOut.length - 1],
            path,
            msg.sender,
            deadline
        );

        emit BTokenSell(
            amounts,
            path,
            sirenAmmAddress,
            bTokenAmount,
            seriesId,
            msg.sender
        );
        return amounts;
    }

    /// @notice Sell the wToken of a given series to the AMM in exchange for collateral token
    /// @param seriesId The ID of the Series to buy wToken on
    /// @param wTokenAmount The amount of wToken to sell (wToken has the same decimals as the underlying)
    /// @param path The path of the collateral token of the series to the collateral the caller wishes to receive
    /// @param tokenAmountOutMinimum The lowest amount of collateral the caller is willing to receive as payment
    /// @param sirenAmmAddress address of the amm that we wish to call
    /// @param deadline deadline the transaction must be completed by
    /// @param _router address of the router we wish to use ( QuickSwap or SushiSwap )
    /// We supply a wToken and then select which collateral we wish to receive as our payment ( if it isnt the underlying asset )
    function wTokenSell(
        uint64 seriesId,
        uint256 wTokenAmount,
        address[] calldata path,
        uint256 tokenAmountOutMinimum,
        address sirenAmmAddress,
        uint256 deadline,
        address _router
    ) external returns (uint256[] memory amounts) {
        //Calculate the amount of collateral we will receive from our provided wTokens on the amm
        //The naming is reversed because its from the routers perspective
        uint256 collateralAmountIn = ISirenTradeAMM(sirenAmmAddress)
            .wTokenGetCollateralOut(seriesId, wTokenAmount);

        //Calculate the amount of token we will receive for the collateral we are providing from the amm
        uint256[] memory amountsOut = IUniswapV2Router02(_router).getAmountsOut(
            collateralAmountIn,
            path
        );

        //Check to make sure our amountsOut is larger or equal to our min requested
        require(
            amountsOut[amountsOut.length - 1] >= tokenAmountOutMinimum,
            "Minimum token ammunt out not met"
        );

        //Transfer wTokens from the user to the exchange
        erc1155Controller.safeTransferFrom(
            msg.sender,
            address(this),
            SeriesLibrary.wTokenIndex(seriesId),
            wTokenAmount,
            dataReturn()
        );

        erc1155Controller.setApprovalForAll(address(sirenAmmAddress), true);

        //Sell the wTokens back to the Amm
        ISirenTradeAMM(sirenAmmAddress).wTokenSell(
            seriesId,
            wTokenAmount,
            collateralAmountIn
        );

        TransferHelper.safeApprove(
            path[0],
            address(IUniswapV2Router02(_router)),
            amountsOut[0]
        );

        // Executes the swap returning the desired collateral directly back to the sender
        amounts = IUniswapV2Router02(_router).swapExactTokensForTokens(
            collateralAmountIn,
            amountsOut[amountsOut.length - 1],
            path,
            msg.sender,
            deadline
        );

        emit WTokenSell(
            amounts,
            path,
            sirenAmmAddress,
            wTokenAmount,
            seriesId,
            msg.sender
        );

        return amounts;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.6.6 <=0.8.0;

/** Interface for any Siren contract which implements the functionality for trading
 * wTokens and bTokens
 */
interface ISirenTradeAMM {
    function bTokenBuy(
        uint64 seriesId,
        uint256 bTokenAmount,
        uint256 collateralMaximum
    ) external returns (uint256);

    function bTokenGetCollateralIn(uint64 seriesId, uint256 bTokenAmount)
        external
        returns (uint256);

    function bTokenGetCollateralOut(uint64 seriesId, uint256 bTokenAmount)
        external
        returns (uint256);

    function bTokenSell(
        uint64 seriesId,
        uint256 bTokenAmount,
        uint256 collateralMinimum
    ) external returns (uint256);

    function wTokenSell(
        uint64 seriesId,
        uint256 wTokenAmount,
        uint256 collateralMinimum
    ) external returns (uint256);

    function wTokenGetCollateralOut(uint64 seriesId, uint256 bTokenAmount)
        external
        returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

library SeriesLibrary {
    function wTokenIndex(uint64 _seriesId) internal pure returns (uint256) {
        return _seriesId * 2;
    }

    function bTokenIndex(uint64 _seriesId) internal pure returns (uint256) {
        return (_seriesId * 2) + 1;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1
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