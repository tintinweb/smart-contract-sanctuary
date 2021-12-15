// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Create2.sol';
import '../interfaces/IAuctionFactory.sol';
import '../interfaces/IAuction.sol';

pragma solidity 0.8.8;

/// @title Auction
/// @notice AuctionFactory creates and manages Auction contracts
contract Auction is IAuction {
  constructor() {
    _factory = IAuctionFactory(msg.sender);
    mvl = IERC20(_factory.getMvlAddress());
  }

  uint256 internal _startTimestamp;
  uint256 internal _endTimestamp;
  uint256 internal _mintAmount;
  uint256 internal _floorPrice;
  uint256 internal _auctionId;

  uint256 internal _criteria;

  mapping(bytes12 => Bid) internal _bids;
  mapping(bytes12 => bytes12) internal _nextBids;
  uint256 public totalBid;
  bytes12 constant BASE = '1';

  IERC20 public immutable mvl;

  IAuctionFactory internal _factory;

  modifier underway() {
    if (getAuctionState() != State.ACTIVE) revert AuctionNotInProgress();
    _;
  }

  modifier ended() {
    if (getAuctionState() == State.END) revert AuctionNotEnded();
    _;
  }

  modifier onlyFactory() {
    if (msg.sender != address(_factory)) revert NotAuthorized();
    _;
  }

  modifier owner(bytes12 bid) {
    if (msg.sender != _bids[bid].owner) revert NotBidOwner();
    _;
  }

  /// @notice Initialize function
  function initialize(
    uint256 startTimestamp,
    uint256 endTimestamp,
    uint256 mintAmount,
    uint256 floorPrice,
    uint256 auctionId
  ) external onlyFactory {
    _startTimestamp = startTimestamp;
    _endTimestamp = endTimestamp;
    _mintAmount = mintAmount;
    _floorPrice = floorPrice;
    _auctionId = auctionId;

    _nextBids[BASE] = BASE;
  }

  /// View Functions ///

  /// @notice This function returns current state of this auction.
  ///  If the criteria is 0, auction is always pending
  /// @return state The state of the auction
  function getAuctionState() public view returns (State state) {
    if (_criteria == 0) {
      return State.PENDING;
    }

    if (block.timestamp < _startTimestamp) {
      state = State.PENDING;
    } else if (block.timestamp > _endTimestamp) {
      state = State.END;
    } else {
      state = State.ACTIVE;
    }
  }

  /// @notice This function returns the information of the this auction
  /// @return startTimestamp Auction start timestamp
  /// @return endTimestamp Auction end timestamp
  /// @return mintAmount Amount to mint
  /// @return floorPrice Basis point of this auction
  /// @return auctionId Currend id of this auction
  /// @return criteria Currend id of this auction
  function getAuctionInformation()
    external
    view
    returns (
      uint256 startTimestamp,
      uint256 endTimestamp,
      uint256 mintAmount,
      uint256 floorPrice,
      uint256 auctionId,
      uint256 criteria
    )
  {
    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;
    mintAmount = _mintAmount;
    floorPrice = _floorPrice;
    auctionId = _auctionId;
    criteria = _criteria;
  }

  /// @notice This function returns the bid amount of the given bid id
  /// @param bid The address of the user
  /// @return bidAmount The price user bids
  function getBiddingPrice(bytes12 bid) external view returns (uint256 bidAmount) {
    bidAmount = _bids[bid].amount;
  }

  function getBidOwner(bytes12 bid) external view returns (address owner_) {
    owner_ = _bids[bid].owner;
  }

  /// @notice This function returns a list of addresses who bid in ascending order of the bid amount
  /// @param k The length of the result
  function getMultiBids(uint256 k) public view returns (Bid[] memory) {
    if (k > totalBid) revert SurpassTotalBidder();
    Bid[] memory bidList = new Bid[](k);
    bytes12 currentId = _nextBids[BASE];
    for (uint256 i = 0; i < k; ++i) {
      bidList[i] = _bids[currentId];
      currentId = _nextBids[currentId];
    }
    return bidList;
  }

  /// @notice This function returns a list of amounts which user bid in ascending order of the bid amount
  /// @param k The length of the list to check
  function getMultiBidAmount(uint256 k) public view returns (uint256[] memory) {
    if (k > totalBid) revert SurpassTotalBidder();
    uint256[] memory bidAmountList = new uint256[](k);
    bytes12 currentId = _nextBids[BASE];
    for (uint256 i = 0; i < k; ++i) {
      bidAmountList[i] = _bids[currentId].amount;
      currentId = _nextBids[currentId];
    }
    return bidAmountList;
  }

  /// @notice This function returns a list of the accounts who are the winner of this auction
  /// The number of the winner depends on the `_mintAmount`
  function getWinBids() external view returns (Bid[] memory) {
    if (totalBid <= _mintAmount) {
      return getMultiBids(totalBid);
    }
    return getMultiBids(_mintAmount);
  }

  /// @notice This function returns a list of the bid amounts of the accounts who are the winner of this auction
  /// The number of the winner depends on the `_mintAmount`
  function getWinBidAmounts() external view returns (uint256[] memory) {
    if (totalBid <= _mintAmount) {
      return getMultiBidAmount(totalBid);
    }
    return getMultiBidAmount(_mintAmount);
  }

  /// User Functions ///

  /// @notice User can bid by executing this function
  function placeBid(uint256 amount) external underway {
    bytes12 bid = _generateBidId(amount);

    if (_bids[bid].owner != address(0)) revert AlreadyExist();

    _placeBid(bid, amount);

    mvl.transferFrom(msg.sender, address(this), amount);
  }

  /// @notice users can place differenct bid. Asset transfers
  function updateBid(bytes12 bid, uint256 amount) external underway owner(bid) {
    Bid memory beforeBid = _bids[bid];

    if (beforeBid.amount == amount) revert NotSameAmount();

    if (beforeBid.amount < amount) {
      mvl.transferFrom(msg.sender, address(this), amount - beforeBid.amount);
    } else {
      mvl.transfer(msg.sender, beforeBid.amount - amount);
    }

    _updateBid(bid, amount);
  }

  /// @notice User can cancel their bid
  function cancelBid(bytes12 bid) external underway owner(bid) {
    Bid memory beforeBid = _bids[bid];

    _removeAccount(bid);

    mvl.transfer(msg.sender, beforeBid.amount);

    emit CancelBid(msg.sender, totalBid);
  }

  /// @notice After the auction ended, user who failed to win the bid can refund their bid amount
  function refundBid(bytes12 bid) external ended owner(bid) {}

  /// Admin Functions ///

  /// @notice admin can stop current auction by setting _endTimestamp to block.timestamp
  function emergencyStop() external onlyFactory {
    _endTimestamp = block.timestamp;
  }

  // function refund
  function transferAsset(address bid, uint256 amount) external onlyFactory {
    _transferAsset(bid, amount);
  }

  /// @notice Set criteria for the auction
  function setCriteria(uint256 currentMvlPrice) external onlyFactory {
    _criteria = (_floorPrice * currentMvlPrice) / 1e18;
  }

  /// Internal Functions ///

  function _generateBidId(uint256 salt) internal view returns (bytes12) {
    return bytes12(keccak256(abi.encodePacked(msg.sender, block.timestamp, salt)));
  }

  function _placeBid(bytes12 bid, uint256 amount) internal {
    require(_nextBids[bid] == bytes12(0), 'Already placed');
    bytes12 index = _findIndex(amount);

    Bid storage _bid = _bids[bid];

    _bid.amount = amount;
    _bid.owner = msg.sender;

    _nextBids[bid] = _nextBids[index];
    _nextBids[index] = bid;

    totalBid++;

    emit PlaceBid(msg.sender, bid, amount, totalBid);
  }

  function _updateBid(bytes12 bid, uint256 newBid) internal {
    require(_nextBids[bid] != bytes12(0), 'Not placed bid');
    bytes12 previousAccount = _findPreviousAccount(bid);
    bytes12 nextAccount = _nextBids[bid];
    if (_verifyIndex(previousAccount, newBid, nextAccount)) {
      _bids[bid].amount = newBid;
    } else {
      _removeAccount(bid);
      _placeBid(bid, newBid);
    }

    emit UpdateBid(msg.sender, bid, newBid, totalBid);
  }

  function _removeAccount(bytes12 bid) internal {
    require(_nextBids[bid] != bytes12(0));
    bytes12 previousAccount = _findPreviousAccount(bid);
    _nextBids[previousAccount] = _nextBids[bid];
    _nextBids[bid] = bytes12(0);
    _bids[bid].amount = 0;
    totalBid--;
  }

  function _verifyIndex(
    bytes12 previousAccount,
    uint256 newValue,
    bytes12 nextAccount
  ) internal view returns (bool) {
    return
      (previousAccount == BASE || _bids[previousAccount].amount >= newValue) &&
      (nextAccount == BASE || newValue > _bids[nextAccount].amount);
  }

  function _findIndex(uint256 newValue) internal view returns (bytes12) {
    bytes12 candidateAddress = BASE;
    while (true) {
      if (_verifyIndex(candidateAddress, newValue, _nextBids[candidateAddress]))
        return candidateAddress;
      candidateAddress = _nextBids[candidateAddress];
    }
  }

  function _isPreviousAccount(bytes12 bid, bytes12 previousBid) internal view returns (bool) {
    return _nextBids[previousBid] == bid;
  }

  function _findPreviousAccount(bytes12 bid) internal view returns (bytes12) {
    bytes12 currentId = BASE;
    while (_nextBids[currentId] != BASE) {
      if (_isPreviousAccount(bid, currentId)) return currentId;
      currentId = _nextBids[currentId];
    }
    return bytes12(0);
  }

  function _transferAsset(address account, uint256 amount) internal {
    mvl.transfer(account, amount);
  }
}

// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Create2.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './Auction.sol';
import '../interfaces/IAuctionFactory.sol';
import '../interfaces/IAuction.sol';
import '../interfaces/IMvlPriceOracle.sol';

pragma solidity 0.8.8;

/// @title AuctionFactory
/// @notice AuctionFactory creates and manages Auction contracts
contract AuctionFactory is IAuctionFactory, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter internal _auctionIds;

  mapping(uint256 => address) auctions;

  IERC20 internal _mvl;
  IMvlPriceOracle internal _mvlOracle;

  constructor(address mvl_) {
    _mvl = IERC20(mvl_);
  }

  function setMvlOracle(address mvlOracle) external onlyOwner {
    _mvlOracle = IMvlPriceOracle(mvlOracle);
  }

  function getMvlOracle() public view returns (address mvlOracle) {
    mvlOracle = address(_mvlOracle);
  }

  function getMvlAddress() public view returns (address mvlAddress) {
    mvlAddress = address(_mvl);
  }

  function getAuctionAddress(uint256 id) public view returns (address auction) {
    auction = auctions[id];
  }

  /// @notice Admin can create auction contract with Create2
  /// @param startTimestamp Auction start timestamp
  /// @param endTimestamp Auction end timestamp
  /// @param mintAmount The number of the winner
  /// @param floorPrice Floor price in USD. It will be used for setting mvl criteria
  function createAuction(
    uint256 startTimestamp,
    uint256 endTimestamp,
    uint256 mintAmount,
    uint256 floorPrice
  ) external onlyOwner {
    uint256 auctionId = _auctionIds.current();

    if (startTimestamp >= endTimestamp) revert InvalidTimestamps();
    if (block.timestamp >= endTimestamp) revert FinishedAuction();

    bytes32 salt = keccak256(
      abi.encodePacked(startTimestamp, endTimestamp, mintAmount, floorPrice, auctionId)
    );

    address auctionAddress = Create2.deploy(0, salt, type(Auction).creationCode);

    auctions[auctionId] = auctionAddress;

    IAuction(auctionAddress).initialize(
      startTimestamp,
      endTimestamp,
      mintAmount,
      floorPrice,
      auctionId
    );

    _auctionIds.increment();

    emit AuctionCreated(
      auctionAddress,
      auctionId,
      startTimestamp,
      endTimestamp,
      mintAmount,
      floorPrice
    );
  }

  function emergencyStop(uint256 auctionId) external onlyOwner {}

  function transferAuctionAsset(
    uint256 auctionId,
    address account,
    uint256 amount
  ) external onlyOwner {
    IAuction(auctions[auctionId]).transferAsset(account, amount);
  }

  function setCriteria(uint256 auctionId) external onlyOwner {
    IAuction(auctions[auctionId]).setCriteria(_mvlOracle.getCurrentPrice());
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

error AuctionNotInProgress();
error AuctionNotEnded();
error NotAuthorized();
error NotBidBefore();
error NotSameAmount();
error SurpassTotalBidder();
error NotBidOwner();
error AlreadyExist();

struct Bid {
  address owner;
  uint256 amount;
}

/// @title AuctionFactory
/// @notice AuctionFactory creates and manages Auction contracts
interface IAuction {
  event PlaceBid(address indexed account, bytes12 bid, uint256 amount, uint256 totalBid);

  event UpdateBid(address indexed account, bytes12 bid, uint256 newBid, uint256 totalBid);

  event CancelBid(address indexed account, uint256 totalBid);

  enum State {
    PENDING,
    ACTIVE,
    END
  }

  function initialize(
    uint256 startTimestamp,
    uint256 endTimestamp,
    uint256 mintAmount,
    uint256 floorPrice,
    uint256 auctionId
  ) external;

  /// View Functions ///

  function getAuctionState() external view returns (State state);

  function getAuctionInformation()
    external
    view
    returns (
      uint256 startTimestamp,
      uint256 endTimestamp,
      uint256 mintAmount,
      uint256 floorPrice,
      uint256 auctionId,
      uint256 criteria
    );

  function getBiddingPrice(bytes12 bid) external view returns (uint256 bidAmount);

  function getBidOwner(bytes12 bid) external view returns (address owner_);

  function getMultiBids(uint256 k) external view returns (Bid[] memory);

  function getMultiBidAmount(uint256 k) external view returns (uint256[] memory);

  function getWinBids() external view returns (Bid[] memory);

  function getWinBidAmounts() external view returns (uint256[] memory);

  /// User Functions ///

  /// @notice User can bid by executing this function
  function placeBid(uint256 amount) external;

  function updateBid(bytes12 bid, uint256 amount) external;

  function cancelBid(bytes12 bid) external;

  function refundBid(bytes12 bid) external;

  /// Admin Functions ///
  function emergencyStop() external;

  function transferAsset(address account, uint256 amount) external;

  /// @notice Set criteria for the auction
  function setCriteria(uint256 currentMvlPrice) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

error InvalidTimestamps();
error FinishedAuction();

interface IAuctionFactory {
  event AuctionCreated(
    address indexed auctionAddress,
    uint256 auctionId,
    uint256 startTimestamp,
    uint256 endTimestamp,
    uint256 mintAmount,
    uint256 floorPrice
  );

  /// @notice Returns mvl token contract address
  function getMvlAddress() external view returns (address mvlAddress);

  /// @notice Return the address of the auction corresponded to the given id
  function getAuctionAddress(uint256 id) external view returns (address auction);

  /// @notice Deploy new auction contract with `Create2`.
  function createAuction(
    uint256 startTimestamp,
    uint256 endTimestamp,
    uint256 mintAmount,
    uint256 floorPrice
  ) external;

  function emergencyStop(uint256 auctionId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

interface IMvlPriceOracle {
  function getCurrentPrice() external view returns (uint256 price);

  function setCurrentPrice(uint256 price) external;
}