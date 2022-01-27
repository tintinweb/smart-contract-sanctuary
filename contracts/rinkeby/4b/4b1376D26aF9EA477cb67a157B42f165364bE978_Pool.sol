/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;


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


interface ILpToken is IERC1155 {
  function totalSupplyOf(uint256 id) external view returns(uint256);

  function setConfig(uint256[] calldata _ids, bool[] calldata _supported) external;

  function mint(address _to, uint256 _id, uint256 _amount) external;

  function burn(address _from, uint256 _id, uint256 _amount) external;

  function grantRole(bytes32 role, address account) external;
}


interface ITicketToken is IERC20 {
  function mint(address _to, uint256 _amount) external;

  function burn(address _from, uint256 _amount) external;
}


interface IFactory {
  function ticketOf(uint256 id) external view returns(bool supported, address tokenAddress, address poolAddress);

  function getTreasury() external view returns(address);

  function getConverter() external view returns(address);

  function getLpToken() external view returns(address);

  function getCollateralToken() external view returns(address);

  function getTicketToken() external view returns(address);

  function setupTickets(uint256[] calldata ids_, uint256[] calldata fees_) external;

  function setTreasury(address treasury_) external;

  function setTicket(address ticket_) external;

  function setCollateral(address collateral_) external;

  function setLp(address lp_) external;

  function setConverter(address converter_) external;
}


interface IPool {
  function getReserves() external view returns(uint256,uint256);

  function estimateSwapAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns(uint256);

  function estimateSwapAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns(uint256);

  function estimateFee(uint256 _amountIn, uint256 _amountOut) external view returns(uint256);

  function addLiquidity(uint256 _collateralAmount, uint256 _tokenAmount) external;

  function removeLiquidity(uint256 _lpAmount) external;

  function swapToCollateralByToken(uint256 _tokenAmount) external returns(uint256);

  function swapToCollateralByCollateral(uint256 _collateralAmount) external returns(uint256);

  function swapFromCollateralByToken(uint256 _tokenAmount) external returns(uint256);

  function swapFromCollateralByCollateral(uint256 _collateralAmount) external returns(uint256);
}


library Math {
  // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

  function abs(uint256 x, uint256 y) internal pure returns(uint256) {
    int256 res = int256(x) - int256(y);
    return res >= 0 ? uint256(res) : uint256(-res);
  }
}


contract Pool is ReentrancyGuard, Context, IPool {
  IFactory public factory;
  ITicketToken public token;
  IERC20 public collateral;
  uint256 public poolId;
  uint256 private fee;
  uint256 private tokenReserve;
  uint256 private collateralReserve;
  bool public initialized;

  event Swapped(address indexed user, uint256 collateralAmount, uint256 tokenAmount, uint256 feeAmount);
  event LiquidityAdded(address indexed user, uint256 collateralAmount, uint256 tokenAmount, uint256 lpAmount);
  event LiquidityRemoved(address indexed user, uint256 lpAmount);

  constructor(uint256 _id, address _factory, address _token, uint256 _fee) {
    token = ITicketToken(_token);
    factory = IFactory(_factory);
    poolId = _id;
    fee = _fee;
    collateral = IERC20(factory.getCollateralToken());
  }
 
  function getReserves() public view override returns(uint256,uint256) {
    return (collateralReserve, tokenReserve);
  }

  function addLiquidity(uint256 _collateralAmount, uint256 _tokenAmount) external override nonReentrant {
    if (!initialized) {
      initialized = true;
    } else {
      require(_collateralAmount == _tokenAmount * collateralReserve / tokenReserve, "Pool: Invalid relation");
    }

    collateral.transferFrom(_msgSender(), address(this), _collateralAmount);
    token.transferFrom(_msgSender(), address(this), _tokenAmount);

    collateralReserve += _collateralAmount;
    tokenReserve += _tokenAmount;

    uint256 amount = Math.sqrt(_collateralAmount * _tokenAmount);
    ILpToken(factory.getLpToken()).mint(_msgSender(), poolId, amount);

    emit LiquidityAdded(_msgSender(), _collateralAmount, _tokenAmount, amount);
  }

  function removeLiquidity(uint256 _lpAmount) external override nonReentrant { 
    address lp = factory.getLpToken();

    ILpToken(lp).burn(_msgSender(), poolId, _lpAmount);

    uint256 collateralAmount = _lpAmount * collateralReserve / ILpToken(lp).totalSupplyOf(poolId);
    uint256 tokenAmount = _lpAmount * tokenReserve / ILpToken(lp).totalSupplyOf(poolId);

    collateral.transfer(_msgSender(), collateralAmount);
    token.transfer(_msgSender(), tokenAmount);

    collateralReserve -= collateralAmount;
    tokenReserve -= tokenAmount;

    emit LiquidityRemoved(_msgSender(), _lpAmount);
  }

  function estimateSwapAmountOut(uint256 _amountIn, uint256 _reserveIn, uint256 _reserveOut) public pure override returns(uint256) {
    return (_amountIn * _reserveOut) / (_reserveIn + _amountIn);
  }

  function estimateSwapAmountIn(uint256 _amountOut, uint256 _reserveIn, uint256 _reserveOut) public pure override returns(uint256) {
    return (_reserveIn * _amountOut) / (_reserveOut - _amountOut);
  }

  function estimateFee(uint256 _amountIn, uint256 _amountOut) public view override returns(uint256) {
    return Math.sqrt(_amountIn * _amountOut / 1 ether) * fee;
  }

  function swapToCollateralByToken(uint256 _tokenAmount) external override nonReentrant returns(uint256) {
    require(initialized, "Pool: Pool is not initialized");
    uint256 collateralAmount = estimateSwapAmountOut(_tokenAmount, tokenReserve, collateralReserve);

    token.transferFrom(_msgSender(), address(this), _tokenAmount);
    collateral.transfer(_msgSender(), collateralAmount);

    tokenReserve += _tokenAmount;
    collateralReserve -= collateralAmount;

    uint256 totalFee = estimateFee(_tokenAmount, collateralAmount);

    collateral.transferFrom(_msgSender(), factory.getTreasury(), uint256(totalFee));
    
    emit Swapped(_msgSender(), collateralAmount, _tokenAmount, uint256(totalFee));
    return collateralAmount;
  }

  function swapToCollateralByCollateral(uint256 _collateralAmount) external override nonReentrant returns(uint256) {
    require(initialized, "Pool: Pool is not initialized");
    uint256 tokenAmount = estimateSwapAmountIn(_collateralAmount, tokenReserve, collateralReserve);

    token.transferFrom(_msgSender(), address(this), tokenAmount);
    collateral.transfer(_msgSender(), _collateralAmount);

    tokenReserve += tokenAmount;
    collateralReserve -= _collateralAmount;

    uint256 totalFee = estimateFee(tokenAmount, _collateralAmount);

    collateral.transferFrom(_msgSender(), factory.getTreasury(), uint256(totalFee));
    
    emit Swapped(_msgSender(), _collateralAmount, tokenAmount, uint256(totalFee));
    return tokenAmount;
  }

  function swapFromCollateralByToken(uint256 _tokenAmount) external override nonReentrant returns(uint256) {
    require(initialized, "Pool: Pool is not initialized");
    uint256 collateralAmount = estimateSwapAmountIn(_tokenAmount, collateralReserve, tokenReserve);

    collateral.transferFrom(_msgSender(), address(this), collateralAmount);
    token.transfer(_msgSender(), _tokenAmount);

    tokenReserve -= _tokenAmount;
    collateralReserve += collateralAmount;

    uint256 totalFee = estimateFee(_tokenAmount, collateralAmount);

    collateral.transferFrom(_msgSender(), factory.getTreasury(), uint256(totalFee));

    emit Swapped(_msgSender(), collateralAmount, _tokenAmount, uint256(totalFee));
    return collateralAmount;
  }

  function swapFromCollateralByCollateral(uint256 _collateralAmount) external override nonReentrant returns(uint256) {
    require(initialized, "Pool: Pool is not initialized");
    uint256 tokenAmount = estimateSwapAmountOut(_collateralAmount, collateralReserve, tokenReserve);

    collateral.transferFrom(_msgSender(), address(this), _collateralAmount);
    token.transfer(_msgSender(), tokenAmount);

    tokenReserve -= tokenAmount;
    collateralReserve += _collateralAmount;

    uint256 totalFee = estimateFee(tokenAmount, _collateralAmount);

    collateral.transferFrom(_msgSender(), factory.getTreasury(), uint256(totalFee));

    emit Swapped(_msgSender(), _collateralAmount, tokenAmount, uint256(totalFee));
    return tokenAmount;
  }
}