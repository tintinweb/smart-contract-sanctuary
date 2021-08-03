/**
 *Submitted for verification at Etherscan.io on 2021-08-03
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

// File: contracts/market/IOwnixMarket.sol

// contracts/IOwnixMarket.sol


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

contract IOwnixMarket {
  uint256 public constant ONE_MILLION = 1000000;
  uint256 public constant FIFTEEN_MINUTES = 15 minutes;

  struct Bid {
    // ERC1155 address
    address tokenAddress;
    // ERC1155 token id
    uint256 tokenId;
    // Bidder address
    address bidder;
    // Amount
    uint256 amount;
    // Price for the bid in wei
    uint256 price;
    // Time when this bid create at
    uint256 bidCreatedAt;
  }

  struct Auction {
    // nft owner address
    address nftOwner;
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
    // Total bids
    uint64 totalBids;
    // Total bids Settled
    uint64 totalBidsSettled;
  }

  // The fee collector address
  address public feeCollector;
  
  // The inflation collector address
  address public inflationCollector;

  // List by token token id => address
  mapping(uint256 => Auction) public auctions;
  mapping(uint256 => Bid[]) public bids;

  uint256 public inflationPerMillion;
  uint256 public bidFeePerMillion;
  uint256 public ownerSharePerMillion;
  uint256 public bidMinimumRaisePerMillion;
  uint256 public bidMinimumRaiseAmount;

  // EVENTS
  event BidCreated(
    address indexed _tokenAddress,
    uint256 indexed _tokenId,
    uint256 _amount,
    address indexed _bidder,
    uint256 _price,
    uint256 bidCreatedAt
  );

  event BidAccepted(
    address indexed _tokenAddress,
    uint256 indexed _tokenId,
    uint256 _amount,
    address _bidder,
    address indexed _seller,
    uint256 _price
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





contract OwnixMarket is Ownable, Pausable, IOwnixMarket {
  using Address for address;

   // The ERC20 ownix token
  ERC20Interface immutable public ownixToken;

  // The ERC1155 ownix token
  ERC1155Interface immutable public  ownixNFTToken;

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
    require(_ownixToken != address(0), "Can not be zero address");
    require(_ownixNFTToken != address(0), "Ca not be zero address");
    require(_owner != address(0), "Can not be zero address");
    require(_feeCollector != address(0), "Can not be zero address");
    require(_inflationCollector != address(0), "Can not be zero address");

    ownixToken = ERC20Interface(_ownixToken);
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

    require(_tokenId != 0, "token id can't be zero");
    require(_amount != 0, "amount id can't be zero");
    require(_reservePrice != 0, "reservePrice id can't be zero");
    require(_duration >= FIFTEEN_MINUTES, "Duration must be bigger the 15 min");
    require(auctions[_tokenId].tokenId == 0, "auction with the same token id is already exists");

     auctions[_tokenId] = Auction(
       msg.sender,
       address(ownixNFTToken),
       _tokenId,
       _amount,
       _reservePrice,
       _duration,
       0,
       0,
       0
     );

    ownixNFTToken.safeTransferFrom(
      msg.sender,
      address(this),
      _tokenId,
      _amount,
      ""
    );

    emit NFTListed(
      msg.sender,
      address(ownixNFTToken),
      _tokenId,
      _amount,
      _reservePrice,
      0
    );
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
    require(auctions[_tokenId].expiresAt == 0, "Can not unlist NFT after auction started");
    require(auctions[_tokenId].nftOwner == msg.sender,  "Must be nft owner unlist NFT");

   ownixNFTToken.safeTransferFrom(
      address(this),
      auctions[_tokenId].nftOwner,
      _tokenId,
      _amount,
      ""
    );

    delete auctions[_tokenId];

    emit NFTUnlisted(
     msg.sender,
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
    require(auctions[_tokenId].expiresAt == 0, "Can not change reserve price after auction started");
    require(auctions[_tokenId].nftOwner == msg.sender, "Must be nft owner to change reserve");

    auctions[_tokenId].reservePrice = _reservePrice;

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
   * @param _price - uint256 of the price for the bid
   */
  function placeBid(
    uint256 _tokenId,
    uint256 _price
  ) external whenNotPaused() {
     Auction memory auction = auctions[_tokenId];
     (Bid memory bid, uint256 lowestBidIndex) = _getLowestBid(_tokenId, auction.amount);

    require(auctions[_tokenId].tokenId != 0, "auction must be listed first");
    require(auction.expiresAt == 0 || auction.expiresAt > block.timestamp,
      "List has been ended, can not place bid"
    );

    // Check minimum raise
    require(
      (_price > bid.price + bidMinimumRaiseAmount ||
        _price > bid.price + (bid.price * (bidMinimumRaisePerMillion / ONE_MILLION))) &&
        _price > auction.reservePrice,
      "Price should be bigger than highest bid and reserve price"
    );

    // Check if the first time bid
    // Yes - Start the auction
    // No  - Refund the token to the pervious bidder
    if (auction.totalBids == 0) {
      auction.expiresAt = block.timestamp + auction.duration;
      auctions[_tokenId] = auction;

      emit AuctionStarted(
        auction.nftOwner,
        address(ownixNFTToken),
        _tokenId,
        auction.amount,
        auction.reservePrice,
        auction.expiresAt);

    } else {
      require(ownixToken.transfer(bid.bidder, bid.price), "Refund failed");
    }

    // check if place bid in the last FIFTEEN_MINUTES
    if (auction.expiresAt - block.timestamp <= FIFTEEN_MINUTES) {
      auction.expiresAt = block.timestamp + FIFTEEN_MINUTES;

      emit AuctionExtended(
        auction.nftOwner,
        address(ownixNFTToken),
        _tokenId,
        auction.amount,
        auction.reservePrice,
        auction.expiresAt
      );
    }

    // Transfer tokens to the marekt
    require(
      ownixToken.transferFrom(msg.sender, address(this), _price),
      "Transferring the bid amount to the marketplace failed"
    );

    // Check if there's a bid fee and transfer the amount to marketplace owner
    if (bidFeePerMillion > 0) {
      // Calculate sale share
      uint256 feeAmount  = _price * bidFeePerMillion / ONE_MILLION;
      require(
        ownixToken.transferFrom(msg.sender, feeCollector, feeAmount),
        "Transferring the bid fee to the marketplace owner failed"
      );
    }

    uint256 bidCreatedAt = block.timestamp;

    // // Save Bid
    Bid storage tmpBid = bids[_tokenId][lowestBidIndex];
    tmpBid.bidder = msg.sender;
    tmpBid.amount = 1;
    tmpBid.price = _price;
    tmpBid.bidCreatedAt = bidCreatedAt;

    auction.totalBids = auction.totalBids++;

    emit BidCreated(
      address(ownixNFTToken),
      _tokenId,
      1,
      msg.sender,
      _price,
      bidCreatedAt
    );
  }

 /**
   * @dev finish auction
   * @param _tokenId The NFT identifier which is being transferred
   */
  function finishAuction(
    uint256 _tokenId
  ) internal whenNotPaused() {
   
    Auction memory auction = auctions[_tokenId];
    (Bid memory bid, uint256 bidIndex) = _findBidByBidder(_tokenId, auction.amount, msg.sender);
    
    if(msg.sender == auction.nftOwner) {
      finishAuctionByOwner(_tokenId);
    } else if(msg.sender == bid.bidder) {
      finishAuctionByBidder(_tokenId, bid, bidIndex);
    }
  }

  /**
   * @dev finish auction by bidder
   * @param _tokenId The NFT identifier which is being transferred
   * @param _tokenId The NFT identifier which is being transferred
   * @param _tokenId The NFT identifier which is being transferred
   */
  function finishAuctionByBidder(
    uint256 _tokenId,
    Bid memory _bid, 
    uint256 _bidIndex
  ) internal whenNotPaused() {
    
    Auction memory auction = auctions[_tokenId];
    
    require(auction.expiresAt < block.timestamp, "Can't settle list before been ended");
    require(msg.sender == _bid.bidder, "Sender must be the NFT bidder");

    // Transfer token to bidder
    ownixNFTToken.safeTransferFrom(
      address(this),
      _bid.bidder,
      _tokenId,
      _bid.amount,
      "");

    uint256 saleShareAmount;
    if (ownerSharePerMillion > 0) {
      // Calculate sale share
      saleShareAmount = _bid.price * ownerSharePerMillion / ONE_MILLION;
      // Transfer share amount to the bid conctract Owner
      require(
        ownixToken.transfer(feeCollector, saleShareAmount),
        "Transfering the share to the bid contract owner failed"
      );
    }

    // Transfer ownixToken from bidder to seller
    require(
      ownixToken.transfer(auction.nftOwner, _bid.price - saleShareAmount),
      "Transfering ownixToken to nft owner failed"
    );

    if (inflationPerMillion > 0) {
      // Calculate mint tokens
      uint256 mintShareAmount = _bid.price * inflationPerMillion / ONE_MILLION;
      // mint the new ownix tokens to the inflationCollector
      ownixToken.mint(inflationCollector, mintShareAmount);
    }

    delete bids[_tokenId][_bidIndex];
    auction.totalBidsSettled = auction.totalBidsSettled++;
    if(auction.totalBidsSettled == auction.amount) {
      delete auctions[_tokenId];
    }

    emit BidAccepted(
      address(ownixNFTToken),
      _tokenId,
      _bid.amount,
      _bid.bidder,
      auction.nftOwner,
      _bid.price
    );
  }


/**
   * @dev finish auction by owner
   * @param _tokenId The NFT identifier which is being transferred
   */
  function finishAuctionByOwner(
    uint256 _tokenId
  ) internal whenNotPaused() {
    
    Auction memory auction = auctions[_tokenId];
    Bid[] memory bids = bids[_tokenId];
  
    require(auction.expiresAt < block.timestamp, "Can't settle list before been ended");
    require(msg.sender == auction.nftOwner, "Sender must be the NFT owner");

    uint256 totalPrice;
    for (uint i=0; i<bids.length; i++) {
      // Transfer nft  to bidder
      ownixNFTToken.safeTransferFrom(
        address(this),
        bids[i].bidder,
        _tokenId,
        bids[i].amount,
        "");

        totalPrice = totalPrice + bids[i].price;

        emit BidAccepted(
          address(ownixNFTToken),
          _tokenId,
          bids[i].amount,
          bids[i].bidder,
          auction.nftOwner,
          bids[i].price
      );
    }

    uint256 saleShareAmount;
    if (ownerSharePerMillion > 0) {
      // Calculate sale share
      saleShareAmount = totalPrice * ownerSharePerMillion / ONE_MILLION;
      // Transfer share amount to the bid conctract Owner
      require(
        ownixToken.transfer(feeCollector, saleShareAmount),
        "Transfering the share to the bid contract owner failed"
      );
    }

    // Transfer ownixToken from bidder to seller
    require(
      ownixToken.transfer(auction.nftOwner, totalPrice - saleShareAmount),
      "Transfering ownixToken to nft owner failed"
    );

    if (inflationPerMillion > 0) {
      // Calculate mint tokens
      uint256 mintShareAmount = totalPrice * inflationPerMillion / ONE_MILLION;
      // mint the new ownix tokens to the inflationCollector
      ownixToken.mint(inflationCollector, mintShareAmount);
    }

    delete auctions[_tokenId];
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
  function setInflationCollector(address _inflationCollector) external onlyOwner {
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
  function withdrawERC20(address _withdrawAddress, uint256 _amount)
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
  function withdrawERC1155(
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

  function _getLowestBid(uint256 _tokenId, uint256 _arraySize) internal view returns (Bid memory, uint256)
  {
      Bid[] memory bids = bids[_tokenId];
      Bid memory lowestBid;
      uint256 lowestBidIndex;
      for (uint i=0; i < _arraySize; i++) {
        if(bids[i].price == 0) {
          return (bids[i], i);
        } else if(lowestBid.price > bids[i].price) {
          lowestBid = bids[i];
          lowestBidIndex = i;
        }
      }

      return (lowestBid, lowestBidIndex);
  }

   function _findBidByBidder(uint256 _tokenId, uint256 _arraySize, address bidder) internal view returns (Bid memory, uint256) {

    Bid[] memory bids = bids[_tokenId];
    Bid memory bid;
    uint256 bidIndex = _arraySize;
    for (uint i=0; i<_arraySize; i++) {
      if(bids[i].bidder == bidder) {
        return (bids[i] ,i);
      }
    }
    return (bid, bidIndex);
   }
}