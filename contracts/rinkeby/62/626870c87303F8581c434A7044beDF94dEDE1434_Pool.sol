/**
 *Submitted for verification at Etherscan.io on 2022-01-14
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


abstract contract ILpToken is IERC1155 {
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  mapping(uint256 => bool) internal supportedIds;
  mapping(uint256 => uint256) public totalSupply;

  function setConfig(uint256[] calldata _ids, bool[] calldata _supported) virtual external;

  function mint(address _to, uint256 _id, uint256 _amount) virtual external;

  function burn(address _from, uint256 _id, uint256 _amount) virtual external;

  function grantRole(bytes32 role, address account) virtual external;
}

interface ITicketToken is IERC20 {
  function mint(address _to, uint256 _amount) external;

  function burn(address _from, uint256 _amount) external;
}


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



contract Pool is ReentrancyGuard, Context, IPool {
  constructor(uint256 _id, address _factory, address _token, uint256 _fee) {
    token = ITicketToken(_token);
    factory = IFactory(_factory);
    poolId = _id;
    fee = _fee;
  }

  function addLiquidity(uint256 _daiAmount, uint256 _tokenAmount) external override nonReentrant {
    if (!initialized) {
      initialized = true;
    } else {
      require(_daiAmount == _tokenAmount * daiReserve / tokenReserve, "Pool: Invalid relation");
    }

    IERC20(factory.daiToken()).transferFrom(_msgSender(), address(this), _daiAmount);
    token.transferFrom(_msgSender(), address(this), _tokenAmount);

    daiReserve += _daiAmount;
    tokenReserve += _tokenAmount;
    
    uint256 amount = (_daiAmount + _tokenAmount * (daiReserve / tokenReserve)) / 1000;
    ILpToken(factory.lpToken()).mint(_msgSender(), poolId, amount);

    emit LiquidityAdded(_msgSender(), _daiAmount, _tokenAmount, amount);
  }

  function removeLiquidity(uint256 _lpAmount) external override nonReentrant {
    uint256 part = _lpAmount * 1e8 / ILpToken(factory.lpToken()).totalSupply(poolId);
    
    ILpToken(factory.lpToken()).burn(_msgSender(), poolId, _lpAmount);

    uint256 daiAmount = part * daiReserve / 1e8;
    uint256 tokenAmount = part * tokenReserve / 1e8;

    IERC20(factory.daiToken()).transfer(_msgSender(), daiAmount);
    token.transfer(_msgSender(), tokenAmount);

    daiReserve -= daiAmount;
    tokenReserve -= tokenAmount;

    emit LiquidityRemoved(_msgSender(), _lpAmount);
  }

  function estimateSwapToDaiByToken(uint256 _tokenAmount) public view override returns(uint256) {
    uint256 currRelation = daiReserve / tokenReserve;
    uint256 nextRelation = (daiReserve - (_tokenAmount * currRelation)) / (tokenReserve + _tokenAmount);
    return _tokenAmount * ((currRelation + nextRelation) / 2);
  }

  function swapToDaiByToken(uint256 _tokenAmount) external override nonReentrant returns(uint256) {
    require(initialized, "Pool: Pool is not initialized");
    uint256 daiAmount = estimateSwapToDaiByToken(_tokenAmount);

    token.transferFrom(_msgSender(), address(this), _tokenAmount);
    IERC20(factory.daiToken()).transfer(_msgSender(), daiAmount);

    tokenReserve += _tokenAmount;
    daiReserve -= daiAmount;

    uint256 totalFee = _tokenAmount * fee / 1 ether;

    IERC20(factory.daiToken()).transferFrom(_msgSender(), factory.treasury(), uint256(totalFee));
    
    emit Swapped(_msgSender(), daiAmount, _tokenAmount, uint256(totalFee));
    return daiAmount;
  }

  function estimateSwapToDaiByDai(uint256 _daiAmount) public view override returns(uint256) {
    uint256 currRelation = daiReserve / tokenReserve;
    uint256 nextRelation = (daiReserve - _daiAmount) / (tokenReserve + (_daiAmount / currRelation));
    return _daiAmount / ((currRelation + nextRelation) / 2);
  }

  function swapToDaiByDai(uint256 _daiAmount) external override nonReentrant returns(uint256) {
    require(initialized, "Pool: Pool is not initialized");
    uint256 tokenAmount = estimateSwapToDaiByDai(_daiAmount);

    token.transferFrom(_msgSender(), address(this), tokenAmount);
    IERC20(factory.daiToken()).transfer(_msgSender(), _daiAmount);

    tokenReserve += tokenAmount;
    daiReserve -= _daiAmount;

    uint256 totalFee = tokenAmount * fee / 1 ether;

    IERC20(factory.daiToken()).transferFrom(_msgSender(), factory.treasury(), uint256(totalFee));
    
    emit Swapped(_msgSender(), _daiAmount, tokenAmount, uint256(totalFee));
    return tokenAmount;
  }

  function estimateSwapFromDaiByToken(uint256 _tokenAmount) public view override returns(uint256) {
    uint256 currRelation = daiReserve / tokenReserve;
    uint256 nextRelation = (daiReserve + (_tokenAmount * currRelation)) / (tokenReserve - _tokenAmount);
    return _tokenAmount * ((currRelation + nextRelation) / 2);
  }

  function swapFromDaiByToken(uint256 _tokenAmount) external override nonReentrant returns(uint256) {
    require(initialized, "Pool: Pool is not initialized");
    uint256 daiAmount = estimateSwapFromDaiByToken(_tokenAmount);

    IERC20(factory.daiToken()).transferFrom(_msgSender(), address(this), daiAmount);
    token.transfer(_msgSender(), _tokenAmount);

    tokenReserve -= _tokenAmount;
    daiReserve += daiAmount;

    uint256 totalFee = _tokenAmount * fee / 1 ether;

    IERC20(factory.daiToken()).transferFrom(_msgSender(), factory.treasury(), uint256(totalFee));

    emit Swapped(_msgSender(), daiAmount, _tokenAmount, uint256(totalFee));
    return daiAmount;
  }

  function estimateSwapFromDaiByDai(uint256 _daiAmount) public view override returns(uint256) {
    uint256 currRelation = daiReserve / tokenReserve;
    uint256 nextRelation = (daiReserve + _daiAmount) / (tokenReserve - (_daiAmount / currRelation));
    return _daiAmount / ((currRelation + nextRelation) / 2);
  }

  function swapFromDaiByDai(uint256 _daiAmount) external override nonReentrant returns(uint256) {
    require(initialized, "Pool: Pool is not initialized");
    uint256 tokenAmount = estimateSwapFromDaiByDai(_daiAmount);

    IERC20(factory.daiToken()).transferFrom(_msgSender(), address(this), _daiAmount);
    token.transfer(_msgSender(), tokenAmount);

    tokenReserve -= tokenAmount;
    daiReserve += _daiAmount;

    uint256 totalFee = tokenAmount * fee / 1 ether;

    IERC20(factory.daiToken()).transferFrom(_msgSender(), factory.treasury(), uint256(totalFee));

    emit Swapped(_msgSender(), _daiAmount, tokenAmount, uint256(totalFee));
    return tokenAmount;
  }
}