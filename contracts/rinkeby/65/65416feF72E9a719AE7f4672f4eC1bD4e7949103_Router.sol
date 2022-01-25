// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/ITicketToken.sol";
import "./interfaces/IConverter.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract Router is Ownable, ReentrancyGuard, IERC1155Receiver {
  uint256 constant private bigNum = 1 ether * 100000000000;
  uint256 constant public impactDecimals = 1000000;
  uint256 public poolsCount;

  IFactory public factory;

  event Swapped(address indexed sender, uint256[] fromIds, uint256[] fromValues, uint256[] toIds, uint256[] toValues, int256 daiDelta);
  event TokenSwapped(address indexed sender, uint256 fromId, uint256 amountIn, uint256 toId, uint256 amountOut);
  event DaiWithdrawn(uint256 amount);

  constructor(address factory_, uint256 poolsCount_) {
    factory = IFactory(factory_);
    poolsCount = poolsCount_;

    for (uint256 i; i < poolsCount_; i++) {
      (,address tokenAddress, address poolAddress) = factory.tickets(i);
      ITicketToken(tokenAddress).approve(poolAddress, bigNum);
      ITicketToken(tokenAddress).approve(factory.converter(), bigNum);
      IERC20(factory.daiToken()).approve(poolAddress, bigNum);
    }

    IERC1155(factory.ticketToken()).setApprovalForAll(factory.converter(), true);
  }

  function abs(uint256 x, uint256 y) private pure returns(uint256) {
    int256 res = int256(x) - int256(y);
    return res >= 0 ? uint256(res) : uint256(-res);
  }

  function getPrice(uint256 tokenId_) public view returns(uint256) {
    (,,address poolAddress) = factory.tickets(tokenId_);
    return getPrice(poolAddress);
  }

  function getPrice(address pool) private view returns(uint256) {
    return IPool(pool).daiReserve() / IPool(pool).tokenReserve();
  }

  function estimateSwapAnyPriceImpact(
    uint256[] memory fromIds_,
    uint256[] memory fromValues_,
    uint256[] memory toIds_,
    uint256[] memory toValues_,
    bool useTickets
  ) public view returns(uint256) {
    uint256[] memory daiReserves = new uint256[](poolsCount);
    uint256[] memory tokenReserves = new uint256[](poolsCount);

    for (uint256 i; i < poolsCount; i++) {
      (,,address poolAddress) = factory.tickets(i);
      daiReserves[i] = IPool(poolAddress).daiReserve();
      tokenReserves[i] = IPool(poolAddress).tokenReserve();
    }

    for (uint256 i; i < fromIds_.length; i++) {
      (,,address poolAddress) = factory.tickets(fromIds_[i]);
      uint256 daiOut = IPool(poolAddress).estimateSwapToDaiByToken(useTickets ? fromValues_[i] * 1 ether : fromValues_[i]);
      daiReserves[fromIds_[i]] -= daiOut;
      tokenReserves[fromIds_[i]] += fromValues_[i];
    }

    for (uint256 i; i < toIds_.length; i++) {
      (,,address poolAddress) = factory.tickets(toIds_[i]);
      uint256 daiOut = IPool(poolAddress).estimateSwapFromDaiByToken(useTickets ? toValues_[i] * 1 ether : toValues_[i]);
      daiReserves[toIds_[i]] += daiOut;
      tokenReserves[toIds_[i]] -= toValues_[i];
    }

    uint256 sum;
    for (uint256 i; i < poolsCount; i++) {
      (,,address poolAddress) = factory.tickets(i);
      uint256 poolCurrPrice = getPrice(poolAddress);
      uint256 poolNextPrice = daiReserves[i] / tokenReserves[i];
      sum += abs(poolCurrPrice, poolNextPrice) * impactDecimals / poolCurrPrice;
    }

    return sum / poolsCount;
  }

  function estimateSwapAnyFee(
    uint256[] memory fromIds_,
    uint256[] memory fromValues_,
    uint256[] memory toIds_,
    uint256[] memory toValues_,
    bool useTickets
  ) public view returns(uint256) {
    uint256 fee;
    for (uint256 i; i < fromIds_.length; i++) {
      (,,address poolAddress) = factory.tickets(fromIds_[i]);
      fee += IPool(poolAddress).fee() * fromValues_[i];
    }

    for (uint256 i; i < toIds_.length; i++) {
      (,,address poolAddress) = factory.tickets(toIds_[i]);
      fee += IPool(poolAddress).fee() * toValues_[i];
    }

    return useTickets ? fee : fee / 1 ether;
  }

  function estimateSwapAnyDai(
    uint256[] memory fromIds_,
    uint256[] memory fromValues_,
    uint256[] memory toIds_,
    uint256[] memory toValues_,
    bool useTickets
  ) public view returns(int256) {
    int256 daiBalance;
    for (uint256 i; i < fromIds_.length; i++) {
      (,,address poolAddress) = factory.tickets(fromIds_[i]);
      daiBalance += int256(IPool(poolAddress).estimateSwapToDaiByToken(useTickets ? fromValues_[i] * 1 ether : fromValues_[i]));
    }

    for (uint256 i; i < toIds_.length; i++) {
      (,,address poolAddress) = factory.tickets(toIds_[i]);
      daiBalance -= int256(IPool(poolAddress).estimateSwapFromDaiByToken(useTickets ? toValues_[i] * 1 ether : toValues_[i]));
    }

    return daiBalance;
  }
  
  function estimateSwapTokenPriceImpact(uint256 tokenId0_, uint256 tokenId1_, uint256 amount_) public view returns(uint256) {
    (,,address poolAddress0) = factory.tickets(tokenId0_);
    (,,address poolAddress1) = factory.tickets(tokenId1_);
    
    uint256 daiAmountOut = IPool(poolAddress0).estimateSwapToDaiByToken(amount_);
    uint256 tokenAmountOut = IPool(poolAddress1).estimateSwapFromDaiByDai(daiAmountOut);

    uint256 pool0CurrPrice = getPrice(poolAddress0);
    uint256 pool1CurrPrice = getPrice(poolAddress1);

    uint256 pool0NextPrice = (IPool(poolAddress0).daiReserve() - daiAmountOut) / (IPool(poolAddress0).tokenReserve() + amount_);
    uint256 pool1NextPrice = (IPool(poolAddress1).daiReserve() + daiAmountOut) / (IPool(poolAddress1).tokenReserve() - tokenAmountOut);

    uint256 impact0 = abs(pool0CurrPrice, pool0NextPrice) * impactDecimals / pool0CurrPrice;
    uint256 impact1 = abs(pool1CurrPrice, pool1NextPrice) * impactDecimals / pool1CurrPrice;

    return (impact0 + impact1) / 2;
  }

  function estimateTokenSwapOut(uint256 tokenId0_, uint256 tokenId1_, uint256 amount_) public view returns(uint256) {
    (,,address poolAddress0) = factory.tickets(tokenId0_);
    (,,address poolAddress1) = factory.tickets(tokenId1_);
    return IPool(poolAddress1).estimateSwapFromDaiByDai(
      IPool(poolAddress0).estimateSwapToDaiByToken(amount_)
    );
  }

  function estimateTokenSwapFee(uint256 tokenId0_, uint256 tokenId1_, uint256 amount_) public view returns(uint256) {
    uint256 estimatedAmount1 = estimateTokenSwapOut(tokenId0_, tokenId1_, amount_);
    (,,address poolAddress0) = factory.tickets(tokenId0_);
    (,,address poolAddress1) = factory.tickets(tokenId1_);
    return (IPool(poolAddress0).fee() * amount_ + IPool(poolAddress1).fee() * estimatedAmount1) / 1 ether; 
  }

  function swapToken(uint256 tokenId0_, uint256 amount0_, uint256 tokenId1_, uint256 amount1Min_) external nonReentrant {
    require(tokenId0_ != tokenId1_, "Router: token ids is equal");

    (bool supported0, address tokenAddress0, address poolAddress0) = factory.tickets(tokenId0_);
    (bool supported1, address tokenAddress1, address poolAddress1) = factory.tickets(tokenId1_);

    require(supported0, "Router: token 0 is not supported");
    require(supported1, "Router: token 1 is not supported");

    uint256 token1Out = estimateTokenSwapOut(tokenId0_, tokenId1_, amount0_);
    require(token1Out >= amount1Min_, "Router: min swap amount reached");

    uint256 fee = estimateTokenSwapFee(tokenId0_, tokenId1_, amount0_);

    IERC20(factory.daiToken()).transferFrom(_msgSender(), address(this), fee);
    ITicketToken(tokenAddress0).transferFrom(_msgSender(), address(this), amount0_);

    uint256 out = IPool(poolAddress1).swapFromDaiByDai(IPool(poolAddress0).swapToDaiByToken(amount0_));

    ITicketToken(tokenAddress1).transfer(_msgSender(), out);

    emit TokenSwapped(_msgSender(), tokenId0_, amount0_, tokenId1_, out);
  }

  function swapAnyToken(
    uint256[] memory fromIds_,
    uint256[] memory fromValues_,
    uint256[] memory toIds_,
    uint256[] memory toValues_
  ) external nonReentrant {
    for (uint256 i; i < fromIds_.length; i++) {
      (,address tokenAddress,) = factory.tickets(fromIds_[i]);
      ITicketToken(tokenAddress).transferFrom(_msgSender(), address(this), fromValues_[i]);
    }

    _swapAny(fromIds_, fromValues_, toIds_, toValues_);

    for (uint256 i; i < toIds_.length; i++) {
      (,address tokenAddress,) = factory.tickets(toIds_[i]);
      ITicketToken(tokenAddress).transfer(_msgSender(), toValues_[i]);
    }
  }

  function _swapAny(
    uint256[] memory fromIds_,
    uint256[] memory fromValues_,
    uint256[] memory toIds_,
    uint256[] memory toValues_
  ) internal {
    require(fromIds_.length == fromValues_.length, "Router: Mismatch in fromIds and fromValues length");
    require(toIds_.length == toValues_.length, "Router: Mismatch in toIds and toValues length");

    IERC20(factory.daiToken()).transferFrom(
      _msgSender(),
      address(this),
      estimateSwapAnyFee(fromIds_, fromValues_, toIds_, toValues_, false)
    );

    int256 delta = estimateSwapAnyDai(fromIds_, fromValues_, toIds_, toValues_, false);

    for (uint256 i; i < fromIds_.length; i++) {
      (,,address poolAddress) = factory.tickets(fromIds_[i]);
      IPool(poolAddress).swapToDaiByToken(fromValues_[i]);
    }

    if (delta > 0) {
      IERC20(factory.daiToken()).transfer(_msgSender(), uint256(delta));
    } else {
      IERC20(factory.daiToken()).transferFrom(_msgSender(), address(this), uint256(delta * -1));
    }

    for (uint256 i; i < toIds_.length; i++) {
      (,,address poolAddress) = factory.tickets(toIds_[i]);
      IPool(poolAddress).swapFromDaiByToken(toValues_[i]);
    }

    emit Swapped(_msgSender(), fromIds_, fromValues_, toIds_, toValues_, delta);
  }

  function swapAnyTicket(
    uint256[] memory fromIds_,
    uint256[] memory fromValues_,
    uint256[] memory toIds_,
    uint256[] memory toValues_
  ) external nonReentrant {

    uint256[] memory from = new uint256[](fromIds_.length);
    uint256[] memory to = new uint256[](toIds_.length);

    for (uint256 i; i < fromIds_.length; i++) {
      IERC1155(factory.ticketToken()).safeTransferFrom(_msgSender(), address(this), fromIds_[i], fromValues_[i], "");
      IConverter(factory.converter()).convertNftToToken(fromIds_[i], fromValues_[i]);
      from[i] = fromValues_[i] * 1 ether;
    }

    for (uint256 i; i < toIds_.length; i++) {
      to[i] = toValues_[i] * 1 ether;
    }

    _swapAny(fromIds_, from, toIds_, to);

    for (uint256 i; i < toIds_.length; i++) {
      IConverter(factory.converter()).convertTokenToNft(toIds_[i], toValues_[i]);
      IERC1155(factory.ticketToken()).safeTransferFrom(address(this), _msgSender(), toIds_[i], toValues_[i], "");
    }
  } 

  function supportsInterface(bytes4 interfaceId) public virtual override view returns (bool) {
    return interfaceId == this.supportsInterface.selector;
  }

  function onERC1155Received(address, address, uint256, uint256, bytes calldata) 
    public virtual override returns (bytes4) {
      require(_msgSender() == address(factory.ticketToken()), "Router: Only ticket tokens allowed");
      return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
    public virtual override returns (bytes4) {
      require(_msgSender() == address(factory.ticketToken()), "Router: Only ticket tokens allowed");
      return this.onERC1155BatchReceived.selector;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITicketToken is IERC20 {
  function mint(address _to, uint256 _amount) external;

  function burn(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ITicketToken.sol";
import "./IFactory.sol";

abstract contract IPool {
  IFactory public factory;
  ITicketToken public token;
  uint256 public poolId;
  uint256 public fee;
  uint256 public tokenReserve;
  uint256 public daiReserve;
  bool public initialized;

  event Swapped(address indexed user, uint256 daiAmount, uint256 tokenAmount, uint256 feeAmount);
  event LiquidityAdded(address indexed user, uint256 daiAmount, uint256 tokenAmount, uint256 lpAmount);
  event LiquidityRemoved(address indexed user, uint256 lpAmount);
  event RewardClaimed(address indexed user, uint256 rewardAmount);

  function addLiquidity(uint256 _daiAmount, uint256 _tokenAmount) external virtual;

  function removeLiquidity(uint256 _lpAmount) external virtual;

  function estimateSwapToDaiByToken(uint256 _tokenAmount) external virtual view returns(uint256);

  function swapToDaiByToken(uint256 _tokenAmount) external virtual returns(uint256);

  function estimateSwapToDaiByDai(uint256 _daiAmount) external virtual view returns(uint256);

  function swapToDaiByDai(uint256 _daiAmount) external virtual returns(uint256);

  function estimateSwapFromDaiByToken(uint256 _tokenAmount) external virtual view returns(uint256);

  function swapFromDaiByToken(uint256 _tokenAmount) external virtual returns(uint256);

  function estimateSwapFromDaiByDai(uint256 _daiAmount) external virtual view returns(uint256);

  function swapFromDaiByDai(uint256 _daiAmount) external virtual returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract ILpToken is IERC1155 {
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  mapping(uint256 => bool) internal supportedIds;
  mapping(uint256 => uint256) public totalSupply;

  function setConfig(uint256[] calldata _ids, bool[] calldata _supported) virtual external;

  function mint(address _to, uint256 _id, uint256 _amount) virtual external;

  function burn(address _from, uint256 _id, uint256 _amount) virtual external;

  function grantRole(bytes32 role, address account) virtual external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ILpToken.sol";

abstract contract IFactory {
  struct Ticket {
    bool supported;
    address tokenAddress;
    address poolAddress;
  } 

  IERC1155 public ticketToken;
  IERC20 public daiToken;
  ILpToken public lpToken;
  address public treasury;
  address public converter;

  mapping(uint256 => Ticket) public tickets;

  event TicketSetup(uint256 indexed id, address pool, address token);
  
  event TreasurySet(address newAddress);
  event TicketTokenSet(address newAddress);
  event DaiTokenSet(address newAddress);
  event LpTokenSet(address newAddress);
  event ConverterSet(address newAddress);

  function setupTickets(uint256[] calldata ids_, uint256[] calldata fees_) external virtual;

  function setTreasury(address treasury_) external virtual;

  function setTicket(address ticket_) external virtual;

  function setDai(address dai_) external virtual;

  function setLp(address lp_) external virtual;

  function setConverter(address converter_) external virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IConverter {
  function convertNftToToken(uint256 id_, uint256 amount_) external;

  function convertTokenToNft(uint256 id_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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