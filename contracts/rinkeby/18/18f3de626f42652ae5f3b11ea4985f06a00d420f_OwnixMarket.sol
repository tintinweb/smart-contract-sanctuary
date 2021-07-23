/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

// File: @openzeppelin/contracts/utils/Context.sol

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: contracts/market/OwnixMarketStorage.sol

// contracts/OwnixMarketStorage.sol


pragma solidity =0.8.6;

/**
 * @title Interface for contracts conforming to ERC-20
 */
interface ERC20Interface {
  function balanceOf(address from) external view returns (uint256);

  function transfer(address _to, uint256 _value)
    external
    returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 tokens
  ) external returns (bool success);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function mint(address account, uint256 amount) external;
}

/**
 * @title Interface for contracts conforming to ERC-1155
 */
interface ERC1155Interface {
  function balanceOf(address account, uint256 id)
    external
    view
    returns (uint256);

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;

  function supportsInterface(bytes4) external view returns (bool);
}

contract OwnixMarketStorage {
  uint256 public constant ONE_MILLION = 1000000;
  uint256 public constant FIFTEEN_MINUTES = 15 minutes;
  bytes4 public constant ERC1155_Interface = 0xd9b67a26;
  bytes4 public constant ERC1155_Received = 0xf23a6e61;

  struct Bid {
    // Bid Id
    bytes32 id;
    // Bidder address
    address bidder;
    // ERC1155 address
    address tokenAddress;
    // ERC1155 token id
    uint256 tokenId;
    // Amount
    uint256 amount;
    // Price for the bid in wei
    uint256 price;
    // Time when this bid create at
    uint256 bidCreatedAt;
  }

  struct List {
    // lister Id
    bytes32 id;
    // owner address
    address owner;
    // ERC1155 address
    address tokenAddress;
    // ERC1155 token id
    uint256 tokenId;
    // Amount
    uint256 amount;
    // Reserve price for the list in wei
    uint256 reservePrice;
    // List duration
    uint256 duration;
    // Time when this list expires at
    uint256 expiresAt;
  }

  // The ERC20 ownix token
  ERC20Interface  public ownixToken;

  // The ERC1155 ownix token
  ERC1155Interface public  ownixNFTToken;

  // The fee collector address
  address public feeCollector;
  
  // The inflation collector address
  address public inflationCollector;

  // Bid by token token id => bid
  mapping(uint256 => Bid) public bidsByToken;

  // List by token token id => address
  mapping(uint256 => List) public listsByToken;

  uint256 public inflationPerMillion;
  uint256 public bidFeePerMillion;
  uint256 public ownerSharePerMillion;
  uint256 public bidMinimumRaisePerMillion;
  uint256 public bidMinimumRaiseAmount;

  // EVENTS
  event BidCreated(
    bytes32 _id,
    address indexed _tokenAddress,
    uint256 indexed _tokenId,
    uint256 _amount,
    address indexed _bidder,
    uint256 _price,
    uint256 bidCreatedAt
  );

  event BidAccepted(
    bytes32 _id,
    address indexed _tokenAddress,
    uint256 indexed _tokenId,
    uint256 _amount,
    address _bidder,
    address indexed _seller,
    uint256 _price,
    uint256 _fee
  );

  event ChangedInflationPerMillion(uint256 _inflationFeePerMillion);
  event ChangedBidFeePerMillion(uint256 _bidFeePerMillion);
  event ChangedOwnerSharePerMillion(uint256 _ownerSharePerMillion);
  event ChangedBidMinimumRaisePerMillion(uint256 _bidMinimumRaisePerMillion);
  event ChangedBidMinimumRaiseAmount(uint256 _bidMinimumRaiseAmount);

  event NFTListed(
    address indexed _owner,
    address indexed _tokenAddress,
    uint256 indexed _tokenId,
    uint256 _amount,
    uint256 _reservePrice,
    uint256 _expiresAt
  );

  event NFTUnlisted(
    address indexed _owner,
    address indexed _tokenAddress,
    uint256 indexed _tokenId,
    uint256 _amount
  );

  event AuctionExtended(
    address indexed _owner,
    address indexed _tokenAddress,
    uint256 indexed _tokenId,
    uint256 _amount,
    uint256 _reservePrice,
    uint256 _expiresAt
  );

  event AuctionStarted(
    address _owner,
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _amount,
    uint256 _reservePrice,
    uint256 _expiresAt
  );

  event ReservePriceChanged(
    address indexed _owner,
    address indexed _tokenAddress,
    uint256 indexed _tokenId,
    uint256 _amount,
    uint256 _reservePrice
  );
}

// File: contracts/market/OwnixMarket.sol

// contracts/OwnixMarket.sol


pragma solidity =0.8.6;





contract OwnixMarket is Ownable, Pausable, OwnixMarketStorage {
  using Address for address;

  /**
   * @dev Constructor of the contract.
   * @param _ownixToken - address of the Ownix token
   * @param _ownixNFTToken - address of the Ownix NFT token
   * @param _owner - address of the owner for the contract
   * @param _feeCollector - address of the fee collector address
   * @param _inflationCollector - address of the inflation collector address
   */
  constructor(
    address _ownixToken,
    address _ownixNFTToken,
    address _owner,
    address _feeCollector,
    address _inflationCollector
  ) Ownable() Pausable() {
    require(_ownixToken != address(0), "Cant't be zero address");
    require(_ownixNFTToken != address(0), "Cant't be zero address");
    require(_owner != address(0), "Cant't be zero address");
    require(_feeCollector != address(0), "Cant't be zero address");
    require(_inflationCollector != address(0), "Cant't be zero address");

    ownixToken = ERC20Interface(_ownixToken);
    _requireERC1155(_ownixNFTToken);
    ownixNFTToken = ERC1155Interface(_ownixNFTToken);

    // Set owner
    transferOwnership(_owner);
    // Set fee collector address
    feeCollector = _feeCollector;
    // Set inflation fee collector address
    inflationCollector = _inflationCollector;
  }

  /**
   * @dev list NFT
   * @param _tokenId The NFT identifier which is being transferred
   * @param _amount The amount of tokens being transferred
   * @param _reservePrice The reserve price
   * @param _duration The auction duration in seconds
   */
  function listNFT(
    uint256 _tokenId,
    uint256 _amount,
    uint256 _reservePrice,
    uint256 _duration
  ) external whenNotPaused() {
    require(
     ownixNFTToken.balanceOf(msg.sender, _tokenId) == _amount,
      "Creator does not have the NFT amount"
    );

    require(
      listsByToken[_tokenId].id == bytes32(0),
      "List is already exists"
    );

    require(_duration > FIFTEEN_MINUTES, "Duration must be bigger the 15 min");

    bytes32 listId =
      keccak256(
        abi.encodePacked(
          block.timestamp,
          msg.sender,
          ownixNFTToken,
          _tokenId,
          _amount,
          _reservePrice
        )
      );

    listsByToken[_tokenId] = List({
      id: listId,
      owner: msg.sender,
      tokenAddress: address(ownixNFTToken),
      tokenId: _tokenId,
      amount: _amount,
      reservePrice: _reservePrice,
      duration: _duration,
      expiresAt: 0
    });

    ownixNFTToken.safeTransferFrom(
      msg.sender,
      address(this),
      _tokenId,
      _amount,
      _bytes32ToBytes(listId)
    );
  }

  /**
   * @dev Use to verify that we go the NFT
   * @notice  The ERC1155 smart contract calls this function on the recipient
   * after a `safetransfer`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * @param _tokenId The NFT identifier which is being transferred
   * @param _value The amount of tokens being transferred
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,bytes)"))`
   */
  function onERC1155Received(
    address, /*_from*/
    address, /*_to*/
    uint256 _tokenId,
    uint256 _value,
    bytes calldata _data
  ) external whenNotPaused() returns (bytes4) {
    bytes32 listId = _bytesToBytes32(_data);
    List memory listToken = listsByToken[_tokenId];

    // Check if the list is valid.
    require(
      // solium-disable-next-line operator-whitespace
      listToken.id == listId && listToken.amount == _value,
      "Invalid list"
    );

    emit NFTListed(
      listToken.owner,
      msg.sender,
      _tokenId,
      listToken.amount,
      listToken.reservePrice,
      listToken.expiresAt
    );

    return ERC1155_Received;
  }

  /**
   * @dev unlist NFT
   * @param _tokenId The NFT identifier which is being transferred
   * @param _amount The amount of tokens being transferred
   */
  function unlistNFT(
    uint256 _tokenId,
    uint256 _amount
  ) external whenNotPaused() {
    require(
      ownixNFTToken.balanceOf(address(this), _tokenId) ==
        _amount,
      "Market does not have the NFT amount"
    );

    require(
      listsByToken[_tokenId].expiresAt == 0,
      "Can not unlist NFT after auction started"
    );

    require(
      listsByToken[_tokenId].owner == msg.sender ||
        msg.sender == owner(),
      "Must be creator or owner to unlist NFT"
    );

   ownixNFTToken.safeTransferFrom(
      address(this),
      listsByToken[_tokenId].owner,
      _tokenId,
      _amount,
      ""
    );

    Bid memory highestBid = bidsByToken[_tokenId];

    if (highestBid.bidder != address(0)) {
      require(
        ownixToken.transfer(highestBid.bidder, highestBid.price),
        "Refund failed"
      );
    }

    delete listsByToken[_tokenId];
    delete bidsByToken[_tokenId];

    emit NFTUnlisted(
      listsByToken[_tokenId].owner,
     address(ownixNFTToken), 
     _tokenId, 
     _amount);
  }

  /**
   * @dev change reserve price
   * @param _tokenId The NFT identifier which is being transferred
   * @param _amount The amount of tokens being transferred
   * @param _reservePrice The new reserve price
   */
  function changeReservePrice(
    uint256 _tokenId,
    uint256 _amount,
    uint256 _reservePrice
  ) external whenNotPaused() {
    require(
      listsByToken[_tokenId].owner == msg.sender ||
        msg.sender == owner(),
      "Must be creator or owner to change reserve"
    );

    require(
      listsByToken[_tokenId].expiresAt == 0,
      "Can not change reserve price after auction started"
    );

    listsByToken[_tokenId].reservePrice = _reservePrice;

    emit ReservePriceChanged(
      msg.sender,
      address(ownixNFTToken),
      _tokenId,
      _amount,
      _reservePrice
    );
  }

  /**
   * @dev Place a bid for an ERC1155 token.
   * @notice Tokens can have multiple bids by different users.
   * Users can have only one bid per token.
   * If the user places a bid and has an active bid for that token,
   * the older one will be replaced with the new one.
   * @param _tokenId - uint256 of the token id
   * @param _amount - uint256 of the token amount
   * @param _price - uint256 of the price for the bid
   */
  function placeBid(
    uint256 _tokenId,
    uint256 _amount,
    uint256 _price
  ) external whenNotPaused() {
    List memory listToken = listsByToken[_tokenId];
    Bid memory highestBid = bidsByToken[_tokenId];

    require(_price > 0, "Price should be bigger than 0");
   
    require(
      listToken.expiresAt == 0 || listToken.expiresAt > block.timestamp,
      "List has been ended, can not place bid"
    );

    // Check minimum raise
    require(
      (_price > highestBid.price + bidMinimumRaiseAmount ||
        _price > highestBid.price + (highestBid.price * bidMinimumRaisePerMillion / ONE_MILLION)) &&
        _price > listToken.reservePrice,
      "Price should be bigger than highest bid and reserve price"
    );

    // Check if the first time bid
    // Yes - Start the auction
    // No  - Refund the token to the pervious bidder
    if (highestBid.bidder == address(0)) {
      listToken.expiresAt = block.timestamp + listToken.duration;
      listsByToken[_tokenId] = listToken;

      emit AuctionStarted(
        listToken.owner,
        address(ownixNFTToken),
        _tokenId,
        _amount,
        listToken.reservePrice,
        listToken.expiresAt);

    } else {
      require(
        ownixToken.transfer(highestBid.bidder, highestBid.price),
        "Refund failed"
      );
    }

    // check if place bid in the last FIFTEEN_MINUTES
    if (listToken.expiresAt - block.timestamp < FIFTEEN_MINUTES) {
      listToken.expiresAt = block.timestamp + FIFTEEN_MINUTES;
      listsByToken[_tokenId] = listToken;

      emit AuctionExtended(
        listToken.owner,
        address(ownixNFTToken),
        _tokenId,
        _amount,
        listToken.reservePrice,
        listToken.expiresAt
      );
    }

    _requireBidderBalance(msg.sender, _price);
    // Transfer tokens to the marekt
    require(
      ownixToken.transferFrom(msg.sender, address(this), _price),
      "Transferring the bid amount to the marketplace failed"
    );

    uint256 feeAmount = 0;
    // Check if there's a bid fee and transfer the amount to marketplace owner
    if (bidFeePerMillion > 0) {
      // Calculate sale share
      feeAmount = _price * bidFeePerMillion / ONE_MILLION;

      _requireBidderBalance(msg.sender, feeAmount);
      require(
        ownixToken.transferFrom(msg.sender, feeCollector, feeAmount),
        "Transferring the bid fee to the marketplace owner failed"
      );
    }

    bytes32 bidId =
      keccak256(
        abi.encodePacked(
          block.timestamp,
          msg.sender,
          ownixNFTToken,
          _tokenId,
          _amount,
          _price
        )
      );

    uint256 bidCreatedAt = block.timestamp;

    // Save Bid
    bidsByToken[_tokenId] = Bid({
      id: bidId,
      bidder: msg.sender,
      tokenAddress: address(ownixNFTToken),
      tokenId: _tokenId,
      amount: _amount,
      price: _price,
      bidCreatedAt: bidCreatedAt
    });

    emit BidCreated(
      bidId,
      address(ownixNFTToken),
      _tokenId,
      _amount,
      msg.sender,
      _price,
      bidCreatedAt
    );
  }

  /**
   * @dev settle bid
   * @param _tokenId The NFT identifier which is being transferred
   * @param _amount The amount of tokens being transferred
   * @param _bidId The bid id
   */
  function settleList(
    uint256 _tokenId,
    uint256 _amount,
    bytes32 _bidId
  ) external whenNotPaused() {
    Bid memory bid = bidsByToken[_tokenId];
    List memory listToken = listsByToken[_tokenId];
    address owner = listsByToken[_tokenId].owner;

    require(
      listToken.expiresAt < block.timestamp,
      "Can't settle list before been ended"
    );

    require(
      msg.sender == owner || msg.sender == bid.bidder,
      "Sender must be the NFT owner"
    );

    // Check if the bid is valid.
    require(
      // solium-disable-next-line operator-whitespace
      bid.id == _bidId && bid.amount == _amount,
      "Invalid bid"
    );

    require(
     ownixNFTToken.balanceOf(address(this), _tokenId) == _amount,
      "Market does not have the NFT amount"
    );

    address bidder = bid.bidder;
    uint256 price = bid.price;

    // Delete bid references from contract storage
    delete listsByToken[_tokenId];
    delete bidsByToken[_tokenId];

    // Transfer token to bidder
    ownixNFTToken.safeTransferFrom(
      address(this),
      bidder,
      _tokenId,
      bid.amount,
      ""
    );

    uint256 saleShareAmount = 0;
    if (ownerSharePerMillion > 0) {
      // Calculate sale share
      saleShareAmount = price * ownerSharePerMillion / ONE_MILLION;
      // Transfer share amount to the bid conctract Owner
      require(
        ownixToken.transfer(feeCollector, saleShareAmount),
        "Transfering the share to the bid contract owner failed"
      );
    }

    // Transfer ownixToken from bidder to seller
    require(
      ownixToken.transfer(listToken.owner, price - saleShareAmount),
      "Transfering ownixToken to nft owner failed"
    );

    if (inflationPerMillion > 0) {
      // Calculate mint tokens
      uint256 mintShareAmount = price * inflationPerMillion / ONE_MILLION;
      // mint the new ownix tokens to the inflationCollector
      ownixToken.mint(inflationCollector, mintShareAmount);
    }

    emit BidAccepted(
      _bidId,
      address(ownixNFTToken),
      _tokenId,
      bid.amount,
      bidder,
      owner,
      price,
      saleShareAmount
    );
  }

  /**
   * @dev Get an ERC1155 token bid by index
   * @param _tokenId - uint256 of the token id
   */
  function getBid(uint256 _tokenId)
    external
    view
    returns (
      bytes32,
      address,
      uint256
    )
  {
    Bid memory bid = bidsByToken[_tokenId];
    return (bid.id, bid.bidder, bid.price);
  }

  /**
   * @dev Sets the inflation that's we mint every transfer
   * @param _inflationPerMillion - inflation amount from 0 to 999,999
   */
  function setInflationPerMillion(uint256 _inflationPerMillion)
    external
    onlyOwner
  {
    require(
      _inflationPerMillion < ONE_MILLION,
      "The inflation should be between 0 and 999,999"
    );

    inflationPerMillion = _inflationPerMillion;
    emit ChangedInflationPerMillion(inflationPerMillion);
  }

  /**
   * @dev Sets the bid fee that's charged to users to bid
   * @param _bidFeePerMillion - Fee amount from 0 to 999,999
   */
  function setBidFeePerMillion(uint256 _bidFeePerMillion) external onlyOwner {
    require(
      _bidFeePerMillion < ONE_MILLION,
      "The bid fee should be between 0 and 999,999"
    );

    bidFeePerMillion = _bidFeePerMillion;
    emit ChangedBidFeePerMillion(bidFeePerMillion);
  }

  /**
   * @dev Sets the share Share for the owner of the contract that's
   * charged to the seller on a successful sale
   * @param _ownerSharePerMillion - Share amount, from 0 to 999,999
   */
  function setOwnerSharePerMillion(uint256 _ownerSharePerMillion)
    external
    onlyOwner
  {
    require(
      _ownerSharePerMillion < ONE_MILLION,
      "The owner share should be between 0 and 999,999"
    );

    ownerSharePerMillion = _ownerSharePerMillion;
    emit ChangedOwnerSharePerMillion(ownerSharePerMillion);
  }

  /**
   * @dev Sets bid minimum raise percentage value
   * @param _bidMinimumRaisePerMillion - Share amount, from 0 to 999,999
   */
  function setBidMinimumRaisePerMillion(uint256 _bidMinimumRaisePerMillion)
    external
    onlyOwner
  {
    require(
      _bidMinimumRaisePerMillion < ONE_MILLION,
      "bid minimum raise should be between 0 and 999,999"
    );

    bidMinimumRaisePerMillion = _bidMinimumRaisePerMillion;
    emit ChangedBidMinimumRaisePerMillion(bidMinimumRaisePerMillion);
  }

  /**
   * @dev Sets bid minimum raise token amount value
   * @param _bidMinimumRaiseAmount - raise token amount, bigger then 0
   */
  function setBidMinimumRaiseAmount(uint256 _bidMinimumRaiseAmount)
    external
    onlyOwner
  {
    require(
      _bidMinimumRaiseAmount > 0,
      "bid minimum raise should be bigger then 0 "
    );

    bidMinimumRaiseAmount = _bidMinimumRaiseAmount;
    emit ChangedBidMinimumRaiseAmount(_bidMinimumRaiseAmount);
  }

  /**
   * @dev Sets the fee collector address
   * @param _feeCollector - the fee collector address
   */
  function setFeeCollector(address _feeCollector) external onlyOwner {
    require(_feeCollector != address(0), "address can't be the zero address");

    feeCollector = _feeCollector;
  }

  /**
   * @dev Sets the inflation collector address
   * @param _inflationCollector - the fee collector address
   */
  function setInflationCollector(address _inflationCollector)
    external
    onlyOwner
  {
    require(
      _inflationCollector != address(0),
      "address can't be the zero address"
    );

    inflationCollector = _inflationCollector;
  }

  /**
   * @dev withdraw the erc20 tokens from the contract
   * @param _withdrawAddress - The withdraw address
   * @param _amount - The withdrawal amount
   */
  function withdraw(address _withdrawAddress, uint256 _amount)
    external
    onlyOwner
  {
    require(
      _withdrawAddress != address(0),
      "address can't be the zero address"
    );

    require(
      ownixToken.transfer(_withdrawAddress, _amount),
      "Withdraw failed"
    );
  }

  /**
   * @dev withdraw the erc1155 tokens from the contract
   * @param _tokenAddress - address of the ERC1155 token
   * @param _tokenId - uint256 of the token id
   * @param _withdrawAddress - The withdraw address
   * @param _amount - The withdrawal amount
   */
  function withdraw(
    address _tokenAddress,
    uint256 _tokenId,
    address _withdrawAddress,
    uint256 _amount
  ) external onlyOwner {
    require(
      _withdrawAddress != address(0),
      "address can't be the zero address"
    );

    ERC1155Interface(_tokenAddress).safeTransferFrom(
      address(this),
      _withdrawAddress,
      _tokenId,
      _amount,
      ""
    );
  }

  /**
   * @dev Convert bytes to bytes32
   * @param _data - bytes
   * @return bytes32
   */
  function _bytesToBytes32(bytes memory _data) internal pure returns (bytes32) {
    require(_data.length == 32, "The data should be 32 bytes length");

    bytes32 bidId;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      bidId := mload(add(_data, 0x20))
    }
    return bidId;
  }

  /**
   * @dev Convert bytes32 to bytes
   * @param _data - bytes32
   * @return bytes
   */
  function _bytes32ToBytes(bytes32 _data) internal pure returns (bytes memory) {
    return abi.encodePacked(_data);
  }

  /**
   * @dev Check if the token has a valid ERC1155 implementation
   * @param _tokenAddress - address of the token
   */
  function _requireERC1155(address _tokenAddress) internal view {
    require(_tokenAddress.isContract(), "Token should be a contract");

    ERC1155Interface token = ERC1155Interface(_tokenAddress);
    require(
      token.supportsInterface(ERC1155_Interface),
      "Token has an invalid ERC1155_Interface implementation"
    );
  }

  /**
   * @dev Check if the bidder has balance and the contract has enough allowance
   * to use bidder erc on his behalf
   * @param _bidder - address of bidder
   * @param _amount - uint256 of amount
   */
  function _requireBidderBalance(address _bidder, uint256 _amount)
    internal
    view
  {
    require(ownixToken.balanceOf(_bidder) >= _amount, "Insufficient funds");
    require(
      ownixToken.allowance(_bidder, address(this)) >= _amount,
      "The contract is not authorized to use ownix token on bidder behalf"
    );
  }
}