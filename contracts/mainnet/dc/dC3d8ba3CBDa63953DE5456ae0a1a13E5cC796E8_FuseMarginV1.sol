// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

import { Uniswap } from "./FuseMarginV1/Uniswap.sol";
import { FuseMarginBase } from "./FuseMarginV1/FuseMarginBase.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import { IFuseMarginController } from "./interfaces/IFuseMarginController.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

/// @author Ganesh Gautham Elango
/// @title FuseMargin contract that handles opening and closing of positions
contract FuseMarginV1 is Uniswap {
    using SafeERC20 for IERC20;

    /// @dev Position contract address
    address public immutable positionProxy;
    /// @dev FuseMarginController contract ERC721 interface
    IERC721 private immutable fuseMarginERC721;

    /// @param _connector ConnectorV1 address containing implementation logic
    /// @param _uniswapFactory Uniswap V2 Factory address
    /// @param _fuseMarginController FuseMarginController address
    /// @param _positionProxy Position address
    constructor(
        address _connector,
        address _uniswapFactory,
        address _fuseMarginController,
        address _positionProxy
    ) Uniswap(_connector, _uniswapFactory) FuseMarginBase(_fuseMarginController) {
        fuseMarginERC721 = IERC721(_fuseMarginController);
        positionProxy = _positionProxy;
    }

    /// @dev Opens a new position, provided an amount of base tokens, must approve base providedAmount before calling
    /// @param providedAmount Amount of base provided
    /// @param amount0Out Desired amount of token0 to borrow (0 if not being borrowed)
    /// @param amount1Out Desired amount of token1 to borrow (0 if not being borrowed)
    /// @param pair Uniswap V2 pair address to flash loan quote from
    /// @param addresses List of addresses to interact with
    ///                  [base, quote, pairToken, comptroller, cBase, cQuote, exchange]
    /// @param exchangeData Swap calldata
    /// @return tokenId of new position
    function openPosition(
        uint256 providedAmount,
        uint256 amount0Out,
        uint256 amount1Out,
        address pair,
        address[7] calldata addresses,
        bytes calldata exchangeData
    ) external override returns (uint256) {
        IERC20(
            addresses[0] /* base */
        )
            .safeTransferFrom(msg.sender, address(this), providedAmount);
        address newPosition = Clones.clone(positionProxy);
        bytes memory data = abi.encode(Action.Open, msg.sender, newPosition, addresses, exchangeData);
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
        return fuseMarginController.newPosition(msg.sender, newPosition);
    }

    /// @dev Closes an existing position, caller must own tokenId
    /// @param tokenId Position tokenId to close
    /// @param amount0Out Desired amount of token0 to borrow (0 if not being borrowed)
    /// @param amount1Out Desired amount of token1 to borrow (0 if not being borrowed)
    /// @param pair Uniswap V2 pair address to flash loan quote from
    /// @param addresses List of addresses to interact with
    ///                  [base, quote, pairToken, comptroller, cBase, cQuote, exchange]
    /// @param exchangeData Swap calldata
    function closePosition(
        uint256 tokenId,
        uint256 amount0Out,
        uint256 amount1Out,
        address pair,
        address[7] calldata addresses,
        bytes calldata exchangeData
    ) external override {
        require(msg.sender == fuseMarginERC721.ownerOf(tokenId), "FuseMarginV1: Not owner of position");
        address positionAddress = fuseMarginController.closePosition(tokenId);
        bytes memory data = abi.encode(Action.Close, msg.sender, positionAddress, addresses, exchangeData);
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

import { FuseMarginBase } from "./FuseMarginBase.sol";
import { IUniswapV2Callee } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IPositionProxy } from "../interfaces/IPositionProxy.sol";
import { CErc20Interface } from "../interfaces/CErc20Interface.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { UniswapV2Library } from "../libraries/UniswapV2Library.sol";

/// @author Ganesh Gautham Elango
/// @title Uniswap flash loan contract
abstract contract Uniswap is FuseMarginBase, IUniswapV2Callee {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Enum for differentiating open/close callbacks
    enum Action { Open, Close }

    /// @dev ConnectorV1 address containing implementation logic
    address public immutable override connector;
    /// @dev Uniswap V2 factory address
    address public immutable uniswapFactory;

    /// @param _connector ConnectorV1 address containing implementation logic
    /// @param _uniswapFactory Uniswap V2 factory address
    constructor(address _connector, address _uniswapFactory) {
        connector = _connector;
        uniswapFactory = _uniswapFactory;
    }

    /// @dev Uniswap flash loan/swap callback. Receives the token amount and gives it back + fees
    /// @param sender The msg.sender who called the Uniswap pair
    /// @param amount0 Amount of token0 received
    /// @param amount1 Amount of token1 received
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        require(sender == address(this), "FuseMarginV1: Only this contract may initiate");
        (
            Action action,
            address user,
            address position,
            address[7] memory addresses, /* [base, quote, pairToken, comptroller, cBase, cQuote, exchange] */
            bytes memory exchangeData
        ) = abi.decode(data, (Action, address, address, address[7], bytes));
        uint256 amount = amount0 > 0 ? amount0 : amount1;
        if (action == Action.Open) {
            require(
                msg.sender ==
                    UniswapV2Library.pairFor(
                        uniswapFactory,
                        addresses[1], /* quote */
                        addresses[2] /* pairToken */
                    ),
                "FuseMarginV1: only permissioned UniswapV2 pair can call"
            );
            _openPosition(amount, position, addresses, exchangeData);
        } else if (action == Action.Close) {
            require(
                msg.sender ==
                    UniswapV2Library.pairFor(
                        uniswapFactory,
                        addresses[0], /* base */
                        addresses[2] /* pairToken */
                    ),
                "FuseMarginV1: only permissioned UniswapV2 pair can call"
            );
            _closePosition(amount, user, position, addresses, exchangeData);
        }
    }

    function _openPosition(
        uint256 amount,
        address position,
        address[7] memory addresses, /* [base, quote, pairToken, comptroller, cBase, cQuote, exchange] */
        bytes memory exchangeData
    ) internal {
        // Swap flash loaned quote amount to base
        uint256 depositAmount =
            _swap(
                addresses[1], /* quote */
                addresses[0], /* base */
                addresses[6], /* exchange */
                amount,
                exchangeData
            );
        // Transfer total base to position
        IERC20(
            addresses[0] /* base */
        )
            .safeTransfer(position, depositAmount);
        // Mint base and borrow quote
        IPositionProxy(position).execute(
            connector,
            abi.encodeWithSignature(
                "mintAndBorrow(address,address,address,address,address,uint256,uint256)",
                addresses[3], /* comptroller */
                addresses[0], /* base */
                addresses[4], /* cBase */
                addresses[1], /* quote */
                addresses[5], /* cQuote */
                depositAmount,
                _uniswapLoanFees(amount)
            )
        );
        // Send the pair the owed amount + flashFee
        IERC20(
            addresses[1] /* quote */
        )
            .safeTransfer(msg.sender, _uniswapLoanFees(amount));
    }

    function _closePosition(
        uint256 amount,
        address user,
        address position,
        address[7] memory addresses, /* [base, quote, pairToken, comptroller, cBase, cQuote, exchange] */
        bytes memory exchangeData
    ) internal {
        // Swap flash loaned base amount to quote
        uint256 receivedAmount =
            _swap(
                addresses[0], /* base */
                addresses[1], /* quote */
                addresses[6], /* exchange */
                amount,
                exchangeData
            );
        // Get amount of quote to repay
        uint256 repayAmount =
            CErc20Interface(
                addresses[5] /* cQuote */
            )
                .borrowBalanceCurrent(position);
        // Transfer quote to be repaid to position
        IERC20(
            addresses[1] /* quote */
        )
            .safeTransfer(position, repayAmount);
        // Repay quote and redeem base
        IPositionProxy(position).execute(
            connector,
            abi.encodeWithSignature(
                "repayAndRedeem(address,address,address,address,uint256,uint256)",
                addresses[0], /* base */
                addresses[4], /* cBase */
                addresses[1], /* quote */
                addresses[5], /* cQuote */
                IERC20(
                    addresses[4] /* cBase */
                )
                    .balanceOf(position),
                repayAmount
            )
        );
        // Send the pair the owed amount + flashFee
        IERC20(
            addresses[0] /* base */
        )
            .safeTransfer(msg.sender, _uniswapLoanFees(amount));
        // Send the user the base profit
        IERC20(
            addresses[0] /* base */
        )
            .safeTransfer(
            user,
            IERC20(
                addresses[0] /* base */
            )
                .balanceOf(address(this))
        );
        // Send the user leftover quote dust
        IERC20(
            addresses[1] /* quote */
        )
            .safeTransfer(user, receivedAmount.sub(repayAmount));
    }

    function _swap(
        address from,
        address to,
        address exchange,
        uint256 amount,
        bytes memory data
    ) internal returns (uint256) {
        IERC20(from).safeApprove(exchange, amount);
        (bool success, ) = exchange.call(data);
        require(success, "FuseMarginV1: Swap failed");
        return IERC20(to).balanceOf(address(this));
    }

    function _uniswapLoanFees(uint256 amount) internal pure returns (uint256) {
        return amount.add(amount.mul(3).div(997).add(1));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

import { IFuseMarginV1 } from "../interfaces/IFuseMarginV1.sol";
import { IFuseMarginController } from "../interfaces/IFuseMarginController.sol";
import { IOwnable } from "../interfaces/IOwnable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @author Ganesh Gautham Elango
/// @title FuseMargin contract base
abstract contract FuseMarginBase is IFuseMarginV1 {
    /// @dev FuseMarginController contract
    IFuseMarginController public immutable override fuseMarginController;

    /// @param _fuseMarginController FuseMarginController address
    constructor(address _fuseMarginController) {
        fuseMarginController = IFuseMarginController(_fuseMarginController);
    }

    /// @dev Transfers token balance
    /// @param token Token address
    /// @param to Transfer to address
    /// @param amount Amount to transfer
    function transferToken(
        address token,
        address to,
        uint256 amount
    ) external {
        require(msg.sender == IOwnable(address(fuseMarginController)).owner(), "FuseMarginV1: Not owner of controller");
        IERC20(token).transfer(to, amount);
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

/// @author Ganesh Gautham Elango
/// @title FuseMarginController Interface
interface IFuseMarginController {
    /// @dev Emitted when support of FuseMargin contract is added
    /// @param contractAddress Address of FuseMargin contract added
    /// @param owner User who added the contract
    event AddMarginContract(address indexed contractAddress, address owner);

    /// @dev Emitted when support of FuseMargin contract is removed
    /// @param contractAddress Address of FuseMargin contract removed
    /// @param owner User who removed the contract
    event RemoveMarginContract(address indexed contractAddress, address owner);

    /// @dev Emitted when support of Connector contract is added
    /// @param contractAddress Address of Connector contract added
    /// @param owner User who added the contract
    event AddConnectorContract(address indexed contractAddress, address owner);

    /// @dev Emitted when support of Connector contract is removed
    /// @param contractAddress Address of Connector contract removed
    /// @param owner User who removed the contract
    event RemoveConnectorContract(address indexed contractAddress, address owner);

    /// @dev Emitted when a new Base URI is added
    /// @param _metadataBaseURI URL for position metadata
    event SetBaseURI(string indexed _metadataBaseURI);

    /// @dev Creates a position NFT, to be called only from FuseMargin
    /// @param user User to give the NFT to
    /// @param position The position address
    /// @return tokenId of the position
    function newPosition(address user, address position) external returns (uint256);

    /// @dev Burns the position at the index, to be called only from FuseMargin
    /// @param tokenId tokenId of position to close
    function closePosition(uint256 tokenId) external returns (address);

    /// @dev Adds support for a new FuseMargin contract, to be called only from owner
    /// @param contractAddress Address of FuseMargin contract
    function addMarginContract(address contractAddress) external;

    /// @dev Removes support for a new FuseMargin contract, to be called only from owner
    /// @param contractAddress Address of FuseMargin contract
    function removeMarginContract(address contractAddress) external;

    /// @dev Adds support for a new Connector contract, to be called only from owner
    /// @param contractAddress Address of Connector contract
    function addConnectorContract(address contractAddress) external;

    /// @dev Removes support for a Connector contract, to be called only from owner
    /// @param contractAddress Address of Connector contract
    function removeConnectorContract(address contractAddress) external;

    /// @dev Modify NFT URL, to be called only from owner
    /// @param _metadataBaseURI URL for position metadata
    function setBaseURI(string memory _metadataBaseURI) external;

    /// @dev Gets all approved margin contracts
    /// @return List of the addresses of the approved margin contracts
    function getMarginContracts() external view returns (address[] memory);

    /// @dev Gets all tokenIds and positions a user holds, dont call this on chain since it is expensive
    /// @param user Address of user
    /// @return List of tokenIds the user holds
    /// @return List of positions the user holds
    function tokensOfOwner(address user) external view returns (uint256[] memory, address[] memory);

    /// @dev Gets a position address given an index (index = tokenId)
    /// @param tokenId Index of position
    /// @return position address
    function positions(uint256 tokenId) external view returns (address);

    /// @dev List of supported FuseMargin contracts
    /// @param index Get FuseMargin contract at index
    /// @return FuseMargin contract address
    function marginContracts(uint256 index) external view returns (address);

    /// @dev Check if FuseMargin contract address is approved
    /// @param contractAddress Address of FuseMargin contract
    /// @return true if approved, false if not
    function approvedContracts(address contractAddress) external view returns (bool);

    /// @dev Check if Connector contract address is approved
    /// @param contractAddress Address of Connector contract
    /// @return true if approved, false if not
    function approvedConnectors(address contractAddress) external view returns (bool);

    /// @dev Returns number of positions created
    /// @return Length of positions array
    function positionsLength() external view returns (uint256);
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

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import { IFuseMarginController } from "./IFuseMarginController.sol";

/// @author Ganesh Gautham Elango
/// @title Position interface
interface IPositionProxy {
    /// @dev Points to immutable FuseMarginController instance
    function fuseMarginController() external view returns (IFuseMarginController);

    /// @dev Delegate call, to be called only from FuseMargin contracts
    /// @param _target Contract address to delegatecall
    /// @param _data ABI encoded function/params
    /// @return Return bytes
    function execute(address _target, bytes memory _data) external payable returns (bytes memory);

    /// @dev Delegate call, to be called only from position owner
    /// @param _target Contract address to delegatecall
    /// @param _data ABI encoded function/params
    /// @param tokenId tokenId of this position
    /// @return Return bytes
    function execute(
        address _target,
        bytes memory _data,
        uint256 tokenId
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.16;

interface CErc20Interface {
    function isCEther() external returns (bool);

    /*** User Interface ***/

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

    function balanceOfUnderlying(address account) external view returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import { IFuseMarginController } from "./IFuseMarginController.sol";

/// @author Ganesh Gautham Elango
/// @title FuseMarginV1 Interface
interface IFuseMarginV1 {
    /// @dev FuseMarginController contract
    function fuseMarginController() external view returns (IFuseMarginController);

    /// @dev ConnectorV1 address containing implementation logic
    function connector() external view returns (address);

    /// @dev Opens a new position, provided an amount of base tokens, must approve base providedAmount before calling
    /// @param providedAmount Amount of base provided
    /// @param amount0Out Desired amount of token0 to borrow (0 if not being borrowed)
    /// @param amount1Out Desired amount of token1 to borrow (0 if not being borrowed)
    /// @param pair Uniswap V2 pair address to flash loan quote from
    /// @param addresses List of addresses to interact with
    ///                  [base, quote, pairToken, comptroller, cBase, cQuote, exchange]
    /// @param exchangeData Swap calldata
    /// @return tokenId of new position
    function openPosition(
        uint256 providedAmount,
        uint256 amount0Out,
        uint256 amount1Out,
        address pair,
        address[7] calldata addresses,
        bytes calldata exchangeData
    ) external returns (uint256);

    /// @dev Closes an existing position, caller must own tokenId
    /// @param tokenId Position tokenId to close
    /// @param amount0Out Desired amount of token0 to borrow (0 if not being borrowed)
    /// @param amount1Out Desired amount of token1 to borrow (0 if not being borrowed)
    /// @param pair Uniswap V2 pair address to flash loan quote from
    /// @param addresses List of addresses to interact with
    ///                  [base, quote, pairToken, comptroller, cBase, cQuote, exchange]
    /// @param exchangeData Swap calldata
    function closePosition(
        uint256 tokenId,
        uint256 amount0Out,
        uint256 amount1Out,
        address pair,
        address[7] calldata addresses,
        bytes calldata exchangeData
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

interface IOwnable {
    function owner() external view returns (address);
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