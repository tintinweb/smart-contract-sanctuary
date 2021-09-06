/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: BidLinkedList

contract BidLinkedList {
  struct Node {
    uint112 next; // next index in linked list
    uint112 price; // bid price
  }

  uint112 public constant HEAD = type(uint112).max - 1; // HEAD node index
  uint112 public constant LAST = type(uint112).max; // LAST node index
  address public immutable owner; // Owner address
  mapping(uint => Node) public nodes; // Mapping from index to Node

  /// @dev Initializes the linked list.
  /// @notice Should be called only once in constructor.
  constructor() {
    nodes[HEAD] = Node({next: LAST, price: type(uint112).max});
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, 'not owner');
    _;
  }

  /// @dev Returns the last index in the linked list that has price >= input price.
  /// @param _price Input price to compare.
  /// @return Index of the last node to return.
  function searchIndexByPrice(uint112 _price) public view returns (uint112) {
    uint112 curIndex = HEAD;
    uint112 nextIndex = nodes[curIndex].next;
    uint112 nextPrice = nodes[nextIndex].price;
    while (nextPrice >= _price) {
      curIndex = nextIndex;
      nextIndex = nodes[curIndex].next;
      nextPrice = nodes[nextIndex].price;
    }
    return curIndex;
  }

  /// @dev Inserts a new node to the linked list.
  /// @param _prevIndex Previous node index to insert after.
  /// @param _curIndex Current node index to insert.
  /// @param _price Bid price info.
  function insert(
    uint112 _prevIndex,
    uint112 _curIndex,
    uint112 _price
  ) external onlyOwner {
    require(_price > 0, 'price 0');
    require(nodes[_curIndex].next == 0, 'cur next not 0');
    require(nodes[_curIndex].price == 0, 'cur price not 0');

    Node storage prevNode = nodes[_prevIndex];
    uint112 nextIndex = prevNode.next;
    if (
      nextIndex == 0 ||
      prevNode.price < _price ||
      prevNode.price == 0 ||
      _price <= nodes[nextIndex].price
    ) {
      _prevIndex = searchIndexByPrice(_price);
      prevNode = nodes[_prevIndex];
      nextIndex = prevNode.next;
    }
    require(nextIndex != 0, 'zero next index');
    require(prevNode.price >= _price, 'prev price less than cur');
    require(prevNode.price != 0, 'prev price 0');
    require(_price > nodes[nextIndex].price, 'cur price not less than prev next');
    nodes[_curIndex] = Node({next: nextIndex, price: _price});
    prevNode.next = _curIndex;
  }

  /// @dev Removes a node at certain index from the linked list.
  /// @param _prevIndex Previous node index to remove the next node.
  /// @param _curIndex Current node index to remove.
  /// @notice Prev node's next must be cur.
  function _remove(uint112 _prevIndex, uint112 _curIndex) internal {
    nodes[_prevIndex].next = nodes[_curIndex].next;
    delete nodes[_curIndex];
  }

  /// @dev Returns the index before the target index in the linked list.
  /// @param _index The target index.
  /// @return The previous index whose next is the input index.
  function searchIndexByIndex(uint112 _index) public view returns (uint112) {
    uint112 curIndex = HEAD;
    uint112 nextIndex = nodes[curIndex].next;
    while (nextIndex != _index) {
      if (nextIndex == LAST) {
        revert('index not found in list');
      }
      curIndex = nextIndex;
      nextIndex = nodes[curIndex].next;
    }
    return curIndex;
  }

  /// @dev Removes a node from the linked list at current index.
  /// @param _prevIndex Previous node index to remove the next node.
  /// @param _curIndex Current node index to remove.
  function removeAt(uint112 _prevIndex, uint112 _curIndex) external onlyOwner {
    if (nodes[_prevIndex].next != _curIndex) {
      _prevIndex = searchIndexByIndex(_curIndex);
    }
    require(nodes[_prevIndex].next == _curIndex, 'prev next not cur');
    require(nodes[_curIndex].next != 0, 'cur next 0');
    require(nodes[_curIndex].price != 0, 'cur price 0');
    _remove(_prevIndex, _curIndex);
  }

  /// @dev Returns the frontmost node info.
  /// @return Frontmost node's index and price.
  /// @notice Reverts if no node in the linked list.
  function front() external view returns (uint112, uint112) {
    uint112 curIndex = nodes[HEAD].next;
    require(curIndex != LAST, 'no node');
    Node storage cur = nodes[curIndex];
    return (curIndex, cur.price);
  }

  /// @dev Removes the frontmost node.
  /// @notice Reverts if no node in the linked list.
  function removeFront() external onlyOwner {
    uint112 nextIndex = nodes[HEAD].next;
    require(nextIndex != LAST, 'empty linked list');
    _remove(HEAD, nextIndex);
  }

  /// @dev Returns the highest bid price.
  /// @return The highest bid price.
  function highestBidPrice() external view returns (uint112) {
    uint112 curIndex = nodes[HEAD].next;
    Node storage cur = nodes[curIndex];
    return cur.price;
  }
}

// Part: INFTOracle

interface INFTOracle {
  function init(address) external;

  function write(uint112) external;

  function OBS_SIZE() external view returns (uint);
}

// Part: OpenZeppelin/[email protected]/IERC165

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

// Part: OpenZeppelin/[email protected]/Initializable

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

// Part: Governable

contract Governable is Initializable {
  event SetGovernor(address governor);
  event SetPendingGovernor(address pendingGovernor);

  address public governor; // The current governor.
  address public pendingGovernor; // The address pending to become the governor once accepted.

  bytes32[64] _gap; // reserve space for upgrade

  modifier onlyGov() {
    require(msg.sender == governor, 'not the governor');
    _;
  }

  /// @dev Initialize using msg.sender as the first governor.
  function __Governable__init() internal initializer {
    governor = msg.sender;
    pendingGovernor = address(0);
    emit SetGovernor(msg.sender);
  }

  /// @dev Set the pending governor, which will be the governor once accepted.
  /// @param _pendingGovernor The address to become the pending governor.
  function setPendingGovernor(address _pendingGovernor) external onlyGov {
    pendingGovernor = _pendingGovernor;
    emit SetPendingGovernor(_pendingGovernor);
  }

  /// @dev Accept to become the new governor. Must be called by the pending governor.
  function acceptGovernor() external {
    require(msg.sender == pendingGovernor, 'not the pending governor');
    pendingGovernor = address(0);
    governor = msg.sender;
    emit SetGovernor(msg.sender);
  }
}

// Part: OpenZeppelin/[email protected]/IERC721

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// Part: AlphaBuyWallBase

abstract contract AlphaBuyWallBase is Governable {
  event Bid(address indexed bidder, uint112 index, uint112 price, uint96 amount);
  event Unbid(address indexed bidder, uint112 index, uint112 price, uint96 amount);
  event Sell(
    uint indexed tokenId,
    address indexed buyer,
    address indexed seller,
    uint112 index,
    uint payout,
    uint toReserve
  );
  event WithdrawReserve(address indexed governor, uint amount);
  event SetReserveBps(address indexed governor, uint reserveBps);
  event SetOracle(address oracle);

  struct BidInfo {
    address bidder; // bidder address
    uint96 amount; // remaining desired amount to buy
    uint112 price; // bid price
  }

  uint private lock; // Reentrancy lock
  address public nft; // NFT Token
  INFTOracle public oracle; // NFT price floor oracle address to update the floor prices
  BidLinkedList public bidLinkedList; // Linked list of bids for query best price
  BidInfo[] public bidInfos; // List of bidInfos
  uint public reserveBps; // Fee going to reserve in bps (1e4)
  uint public reservePool; // Protocol reserve pool

  modifier onlyEOA() {
    require(msg.sender == tx.origin, '!eoa');
    _;
  }

  modifier nonReentrant() {
    require(lock == 1, '!lock');
    lock = 2;
    _;
    lock = 1;
  }

  /// @dev Initializes ABW contract. Deploys bid linked list contract.
  /// @param _nft NFT token.
  /// @param _oracle Floor price oracle address.
  /// @param _reserveBps The fee portion to go to reserve (in 1e4).
  function initialize(
    address _nft,
    INFTOracle _oracle,
    uint _reserveBps
  ) external initializer {
    require(_nft != address(0), '!nft');
    require(_reserveBps < 1e4, '!reserveBps');
    __Governable__init();
    lock = 1;
    nft = _nft;
    oracle = _oracle;
    reserveBps = _reserveBps;
    bidLinkedList = new BidLinkedList();
    bidInfos.push(BidInfo({bidder: address(0), amount: 0, price: 0})); // start with index 1
    _oracle.init(_nft); // initializes the oracle in the slot

    emit SetReserveBps(msg.sender, _reserveBps);
  }

  /// @dev Sets and calls init to the oracle to a new oracle.
  /// @param _oracle The new NFT oracle.
  function setOracle(INFTOracle _oracle) external onlyGov {
    oracle = _oracle;
    _oracle.init(nft); // initializes the oracle
    emit SetOracle(address(_oracle));
  }

  /// @dev Updates new highest price to oracle. If no bids, price 0 is updated.
  function _updateOracle() internal {
    oracle.write(bidLinkedList.highestBidPrice());
  }

  /// @dev Withdraw available reserves. Only gov function.
  function withdrawReserve() external onlyGov {
    uint amount = reservePool;
    reservePool -= amount;
    payable(msg.sender).transfer(amount);
    emit WithdrawReserve(msg.sender, amount);
  }

  /// @dev Sets new fee bps. Can only be set by the governor.
  /// @param _reserveBps New fee in bps to set to.
  function setReserveBps(uint _reserveBps) external onlyGov {
    require(_reserveBps < 1e4, '!reserveBps');
    reserveBps = _reserveBps;
    emit SetReserveBps(msg.sender, _reserveBps);
  }

  /// @dev Checks if the input price is valid, i.e. has at most 2 significant digits.
  /// @param _price The input price to check validity.
  /// @return Whether the price is valid.
  function validPrice(uint112 _price) public pure returns (bool) {
    while (_price > 100) {
      if (_price % 10 != 0) return false;
      _price /= 10;
    }
    return true;
  }

  /// @dev Bids for any NFT.
  /// @param _prevIndex Previous index to add bid after. If 0, auto search.
  /// @param _price Price of NFT desired.
  /// @param _amount Number of NFT desired.
  function bid(
    uint112 _prevIndex,
    uint112 _price,
    uint96 _amount
  ) external payable onlyEOA nonReentrant {
    require(_amount > 0, '!bid/_amount');
    require(_price > 0, '!bid/_price');
    require(msg.value == _price * _amount, '!bid/value');
    require(validPrice(_price), '!bid/validPrice');
    uint112 curIndex = uint112(bidInfos.length);
    bidInfos.push(BidInfo({bidder: msg.sender, price: _price, amount: _amount}));
    // update linked list
    bidLinkedList.insert(_prevIndex, curIndex, _price);

    emit Bid(msg.sender, curIndex, _price, _amount);

    // update oracle
    _updateOracle();
  }

  /// @dev Unbids existing bid.
  /// @param _prevIndex Previous index of the bid to unbid. If 0, auto search.
  /// @param _curIndex Current index fof the bid to unbid.
  function unbid(uint112 _prevIndex, uint112 _curIndex) external onlyEOA nonReentrant {
    require(bidInfos[_curIndex].bidder == msg.sender, '!unbid/bidder');
    (uint112 price, uint96 amount) = (bidInfos[_curIndex].price, bidInfos[_curIndex].amount);
    require(amount > 0, '!unbid/amount');

    // clear info
    bidInfos[_curIndex].bidder = address(0);
    bidInfos[_curIndex].amount -= amount;
    bidInfos[_curIndex].price = 0;

    payable(msg.sender).transfer(price * amount);
    // update linked list
    bidLinkedList.removeAt(_prevIndex, _curIndex);

    emit Unbid(msg.sender, _curIndex, price, amount);

    // update oracle
    _updateOracle();
  }

  /// @dev Market sells ERC721.
  /// @param _tokenId NFT's id to sell.
  /// @param _minPrice Minimum price.
  function sell(uint _tokenId, uint112 _minPrice) external nonReentrant {
    (uint112 curIndex, uint112 price) = bidLinkedList.front();
    require(price == bidInfos[curIndex].price, '!sell/price');
    address bidder = bidInfos[curIndex].bidder;
    require(bidder != address(0), '!sell/bidder');

    bidInfos[curIndex].amount--;
    if (bidInfos[curIndex].amount == 0) {
      // remove from linked list
      bidLinkedList.removeFront();
      // clear info
      bidInfos[curIndex].bidder = address(0);
      bidInfos[curIndex].price = 0;
    }

    // calculate fees to reserve
    uint toReserve = (price * reserveBps) / 1e4;
    uint payout = price - toReserve;
    require(payout >= _minPrice, '!sell/_minPrice');
    reservePool += toReserve;

    doTransferFrom(msg.sender, bidder, _tokenId);
    payable(msg.sender).transfer(payout);
    emit Sell(_tokenId, bidder, msg.sender, curIndex, payout, toReserve);

    // update oracle
    _updateOracle();
  }

  /// @dev Transfers specific NFT from a target to another target.
  /// @param _from Address to transfer from.
  /// @param _to Address to transfer to.
  /// @param _tokenId NFT token id to transfer.
  function doTransferFrom(
    address _from,
    address _to,
    uint _tokenId
  ) internal virtual;
}

// File: AlphaBuyWallERC721.sol

contract AlphaBuyWallERC721 is AlphaBuyWallBase {
  function doTransferFrom(
    address _from,
    address _to,
    uint _tokenId
  ) internal override {
    IERC721(nft).safeTransferFrom(_from, _to, _tokenId);
  }
}