// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ds/RedBlackTree.sol";
import "../ds/EnumerableSet.sol";
import "../security/SafeEntry.sol";
import "../utils/TransferWithCommission.sol";
import "../utils/ValueLimits.sol";
import "../utils/WhirlpoolConsumer.sol";

struct Round {
  Tree sortedBids;
  mapping(uint256 => AddressSet) bidToBidders;
  mapping(address => uint256) biddersToBids;
  AddressSet bidders;
  uint256 pendingReward;
  address winner;
  uint256 total;
  bool hasEnded;
}

contract Recipe is TransferWithCommission, ValueLimits, WhirlpoolConsumer, SafeEntry {
  using RedBlackTree for Tree;
  using EnumerableSet for AddressSet;

  Round[] internal rounds;
  uint256 public currentRound;

  uint16 public constant MAX_HIGHEST_BIDDER_WIN_ODDS = 10000;
  uint16 public highestBidderWinOdds = 2500;

  uint256 public minBidsPerRound = 5;
  uint256 public minAmountPerRound = 1 ether;

  // solhint-disable no-empty-blocks
  constructor(address _whirlpool) WhirlpoolConsumer(_whirlpool) ValueLimits(0.001 ether, 100 ether) {}

  function createBid(uint256 id, address referrer) external payable notContract nonReentrant isMinValue {
    require(currentRound == id, "Recipe: Not current round");
    require(rounds[id].winner == address(0), "Recipe: Round has ended");

    Round storage round = rounds[id];

    uint256 myBid = round.biddersToBids[msg.sender];

    round.bidToBidders[myBid].remove(msg.sender);
    if (round.bidToBidders[myBid].size() == 0) round.sortedBids.remove(myBid);

    if (myBid == 0) round.bidders.add(msg.sender);

    myBid += msg.value;

    round.sortedBids.insert(myBid);
    round.bidToBidders[myBid].add(msg.sender);
    round.biddersToBids[msg.sender] = myBid;

    round.total += msg.value;

    referrers[msg.sender] = referrer;
  }

  function claim(uint256 id) external notContract nonReentrant {
    Round storage round = rounds[id];

    if (msg.sender == round.winner) {
      require(round.pendingReward != 0, "Recipe: Nothing to claim");

      send(round.winner, round.pendingReward);
      round.pendingReward = 0;
      return;
    }

    uint256 myBid = round.biddersToBids[msg.sender];
    require(myBid != 0, "Recipe: Nothing to claim");

    uint256 myReward = (round.pendingReward * round.total) / myBid;
    round.pendingReward -= myReward;

    removeBid(id, round.bidders.indexes[msg.sender]);

    send(msg.sender, myBid + myReward);
  }

  function pickOrEliminate() external {
    Round storage round = rounds[currentRound];

    require(round.total >= minAmountPerRound, "Recipe: Min amount not reached");
    require(round.bidders.size() >= minBidsPerRound, "Recipe: Min bids not reached");

    _requestRandomness(currentRound);
  }

  function setHighestBidderWinOdds(uint16 val) external onlyOwner {
    require(val <= MAX_HIGHEST_BIDDER_WIN_ODDS, "Recipe: Value exceeds max amount");
    highestBidderWinOdds = val;
  }

  function setMinForElimination(uint256 minBids, uint256 minAmount) external onlyOwner {
    minBidsPerRound = minBids;
    minAmountPerRound = minAmount;
  }

  function highestBid(uint256 id) public view returns (address bidder, uint256 bid) {
    bid = rounds[id].sortedBids.last();
    bidder = rounds[id].bidToBidders[bid].get(0);
  }

  function eliminate(
    uint256 id,
    uint256 index,
    bool highestBidderWins
  ) internal {
    Round storage round = rounds[id];

    address bidder = round.bidders.get(index);
    uint256 bid = round.biddersToBids[bidder];

    (address highestBidder, uint256 _highestBid) = highestBid(id);
    if (highestBidder == bidder && _highestBid == bid && highestBidderWins) {
      round.pendingReward = round.total;
      round.winner = highestBidder;
      currentRound++;
      return;
    }

    round.pendingReward += bid;

    removeBid(id, index);
  }

  function removeBid(uint256 id, uint256 index) internal {
    Round storage round = rounds[id];
    address bidder = round.bidders.get(index);
    uint256 bid = round.biddersToBids[bidder];

    round.bidToBidders[bid].remove(bidder);
    if (round.bidToBidders[bid].size() == 0) round.sortedBids.remove(bid);
    round.bidders.removeAt(index);
    delete round.biddersToBids[bidder];
  }

  function _consumeRandomness(uint256 id, uint256 randomness) internal override {
    eliminate(
      id,
      (randomness % rounds[id].bidders.size()),
      randomness % MAX_HIGHEST_BIDDER_WIN_ODDS <= highestBidderWinOdds
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's Red-Black Tree Library v1.0-pre-release-a
//
// A Solidity Red-Black Tree binary search library to store and access a sorted
// list of unsigned integer data. The Red-Black algorithm rebalances the binary
// search tree, resulting in O(log n) insert, remove and search time (and ~gas)
//
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2020. The MIT Licence.
// ----------------------------------------------------------------------------
struct Node {
  uint256 parent;
  uint256 left;
  uint256 right;
  bool red;
}

struct Tree {
  uint256 root;
  mapping(uint256 => Node) nodes;
}

library RedBlackTree {
  uint256 private constant EMPTY = 0;

  function first(Tree storage self) internal view returns (uint256 _key) {
    _key = self.root;
    if (_key != EMPTY) {
      while (self.nodes[_key].left != EMPTY) {
        _key = self.nodes[_key].left;
      }
    }
  }

  function last(Tree storage self) internal view returns (uint256 _key) {
    _key = self.root;
    if (_key != EMPTY) {
      while (self.nodes[_key].right != EMPTY) {
        _key = self.nodes[_key].right;
      }
    }
  }

  function next(Tree storage self, uint256 target) internal view returns (uint256 cursor) {
    if (target == EMPTY) return EMPTY;
    if (self.nodes[target].right != EMPTY) {
      cursor = treeMinimum(self, self.nodes[target].right);
    } else {
      cursor = self.nodes[target].parent;
      while (cursor != EMPTY && target == self.nodes[cursor].right) {
        target = cursor;
        cursor = self.nodes[cursor].parent;
      }
    }
  }

  function prev(Tree storage self, uint256 target) internal view returns (uint256 cursor) {
    if (target == EMPTY) return EMPTY;
    if (self.nodes[target].left != EMPTY) {
      cursor = treeMaximum(self, self.nodes[target].left);
    } else {
      cursor = self.nodes[target].parent;
      while (cursor != EMPTY && target == self.nodes[cursor].left) {
        target = cursor;
        cursor = self.nodes[cursor].parent;
      }
    }
  }

  function exists(Tree storage self, uint256 key) internal view returns (bool) {
    return (key != EMPTY) && ((key == self.root) || (self.nodes[key].parent != EMPTY));
  }

  function insert(Tree storage self, uint256 key) internal {
    if (exists(self, key) || key == EMPTY) return;

    uint256 cursor = EMPTY;
    uint256 probe = self.root;
    while (probe != EMPTY) {
      cursor = probe;
      if (key < probe) {
        probe = self.nodes[probe].left;
      } else {
        probe = self.nodes[probe].right;
      }
    }
    self.nodes[key] = Node({ parent: cursor, left: EMPTY, right: EMPTY, red: true });
    if (cursor == EMPTY) {
      self.root = key;
    } else if (key < cursor) {
      self.nodes[cursor].left = key;
    } else {
      self.nodes[cursor].right = key;
    }
    insertFixup(self, key);
  }

  function remove(Tree storage self, uint256 key) internal {
    if (!exists(self, key) || key == EMPTY) return;

    uint256 probe;
    uint256 cursor;
    if (self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY) {
      cursor = key;
    } else {
      cursor = self.nodes[key].right;
      while (self.nodes[cursor].left != EMPTY) {
        cursor = self.nodes[cursor].left;
      }
    }
    if (self.nodes[cursor].left != EMPTY) {
      probe = self.nodes[cursor].left;
    } else {
      probe = self.nodes[cursor].right;
    }
    uint256 yParent = self.nodes[cursor].parent;
    self.nodes[probe].parent = yParent;
    if (yParent != EMPTY) {
      if (cursor == self.nodes[yParent].left) {
        self.nodes[yParent].left = probe;
      } else {
        self.nodes[yParent].right = probe;
      }
    } else {
      self.root = probe;
    }
    bool doFixup = !self.nodes[cursor].red;
    if (cursor != key) {
      replaceParent(self, cursor, key);
      self.nodes[cursor].left = self.nodes[key].left;
      self.nodes[self.nodes[cursor].left].parent = cursor;
      self.nodes[cursor].right = self.nodes[key].right;
      self.nodes[self.nodes[cursor].right].parent = cursor;
      self.nodes[cursor].red = self.nodes[key].red;
      (cursor, key) = (key, cursor);
    }
    if (doFixup) {
      removeFixup(self, probe);
    }
    delete self.nodes[cursor];
  }

  function treeMinimum(Tree storage self, uint256 key) private view returns (uint256) {
    while (self.nodes[key].left != EMPTY) {
      key = self.nodes[key].left;
    }
    return key;
  }

  function treeMaximum(Tree storage self, uint256 key) private view returns (uint256) {
    while (self.nodes[key].right != EMPTY) {
      key = self.nodes[key].right;
    }
    return key;
  }

  function rotateLeft(Tree storage self, uint256 key) private {
    uint256 cursor = self.nodes[key].right;
    uint256 keyParent = self.nodes[key].parent;
    uint256 cursorLeft = self.nodes[cursor].left;
    self.nodes[key].right = cursorLeft;
    if (cursorLeft != EMPTY) {
      self.nodes[cursorLeft].parent = key;
    }
    self.nodes[cursor].parent = keyParent;
    if (keyParent == EMPTY) {
      self.root = cursor;
    } else if (key == self.nodes[keyParent].left) {
      self.nodes[keyParent].left = cursor;
    } else {
      self.nodes[keyParent].right = cursor;
    }
    self.nodes[cursor].left = key;
    self.nodes[key].parent = cursor;
  }

  function rotateRight(Tree storage self, uint256 key) private {
    uint256 cursor = self.nodes[key].left;
    uint256 keyParent = self.nodes[key].parent;
    uint256 cursorRight = self.nodes[cursor].right;
    self.nodes[key].left = cursorRight;
    if (cursorRight != EMPTY) {
      self.nodes[cursorRight].parent = key;
    }
    self.nodes[cursor].parent = keyParent;
    if (keyParent == EMPTY) {
      self.root = cursor;
    } else if (key == self.nodes[keyParent].right) {
      self.nodes[keyParent].right = cursor;
    } else {
      self.nodes[keyParent].left = cursor;
    }
    self.nodes[cursor].right = key;
    self.nodes[key].parent = cursor;
  }

  function insertFixup(Tree storage self, uint256 key) private {
    uint256 cursor;
    while (key != self.root && self.nodes[self.nodes[key].parent].red) {
      uint256 keyParent = self.nodes[key].parent;
      if (keyParent == self.nodes[self.nodes[keyParent].parent].left) {
        cursor = self.nodes[self.nodes[keyParent].parent].right;
        if (self.nodes[cursor].red) {
          self.nodes[keyParent].red = false;
          self.nodes[cursor].red = false;
          self.nodes[self.nodes[keyParent].parent].red = true;
          key = self.nodes[keyParent].parent;
        } else {
          if (key == self.nodes[keyParent].right) {
            key = keyParent;
            rotateLeft(self, key);
          }
          keyParent = self.nodes[key].parent;
          self.nodes[keyParent].red = false;
          self.nodes[self.nodes[keyParent].parent].red = true;
          rotateRight(self, self.nodes[keyParent].parent);
        }
      } else {
        cursor = self.nodes[self.nodes[keyParent].parent].left;
        if (self.nodes[cursor].red) {
          self.nodes[keyParent].red = false;
          self.nodes[cursor].red = false;
          self.nodes[self.nodes[keyParent].parent].red = true;
          key = self.nodes[keyParent].parent;
        } else {
          if (key == self.nodes[keyParent].left) {
            key = keyParent;
            rotateRight(self, key);
          }
          keyParent = self.nodes[key].parent;
          self.nodes[keyParent].red = false;
          self.nodes[self.nodes[keyParent].parent].red = true;
          rotateLeft(self, self.nodes[keyParent].parent);
        }
      }
    }
    self.nodes[self.root].red = false;
  }

  function replaceParent(
    Tree storage self,
    uint256 a,
    uint256 b
  ) private {
    uint256 bParent = self.nodes[b].parent;
    self.nodes[a].parent = bParent;
    if (bParent == EMPTY) {
      self.root = a;
    } else {
      if (b == self.nodes[bParent].left) {
        self.nodes[bParent].left = a;
      } else {
        self.nodes[bParent].right = a;
      }
    }
  }

  function removeFixup(Tree storage self, uint256 key) private {
    uint256 cursor;
    while (key != self.root && !self.nodes[key].red) {
      uint256 keyParent = self.nodes[key].parent;
      if (key == self.nodes[keyParent].left) {
        cursor = self.nodes[keyParent].right;
        if (self.nodes[cursor].red) {
          self.nodes[cursor].red = false;
          self.nodes[keyParent].red = true;
          rotateLeft(self, keyParent);
          cursor = self.nodes[keyParent].right;
        }
        if (!self.nodes[self.nodes[cursor].left].red && !self.nodes[self.nodes[cursor].right].red) {
          self.nodes[cursor].red = true;
          key = keyParent;
        } else {
          if (!self.nodes[self.nodes[cursor].right].red) {
            self.nodes[self.nodes[cursor].left].red = false;
            self.nodes[cursor].red = true;
            rotateRight(self, cursor);
            cursor = self.nodes[keyParent].right;
          }
          self.nodes[cursor].red = self.nodes[keyParent].red;
          self.nodes[keyParent].red = false;
          self.nodes[self.nodes[cursor].right].red = false;
          rotateLeft(self, keyParent);
          key = self.root;
        }
      } else {
        cursor = self.nodes[keyParent].left;
        if (self.nodes[cursor].red) {
          self.nodes[cursor].red = false;
          self.nodes[keyParent].red = true;
          rotateRight(self, keyParent);
          cursor = self.nodes[keyParent].left;
        }
        if (!self.nodes[self.nodes[cursor].right].red && !self.nodes[self.nodes[cursor].left].red) {
          self.nodes[cursor].red = true;
          key = keyParent;
        } else {
          if (!self.nodes[self.nodes[cursor].left].red) {
            self.nodes[self.nodes[cursor].right].red = false;
            self.nodes[cursor].red = true;
            rotateLeft(self, cursor);
            cursor = self.nodes[keyParent].left;
          }
          self.nodes[cursor].red = self.nodes[keyParent].red;
          self.nodes[keyParent].red = false;
          self.nodes[self.nodes[cursor].left].red = false;
          rotateRight(self, keyParent);
          key = self.root;
        }
      }
    }
    self.nodes[key].red = false;
  }
}
// ----------------------------------------------------------------------------
// End - BokkyPooBah's Red-Black Tree Library
// ----------------------------------------------------------------------------

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct AddressSet {
  mapping(uint256 => address) addresses;
  mapping(address => uint256) indexes;
  uint256 startIndex;
  uint256 totalCount;
}

library EnumerableSet {
  function add(AddressSet storage self, address item) internal {
    if (has(self, item)) return;

    self.addresses[self.totalCount] = item;
    self.indexes[item] = self.totalCount;
    self.totalCount++;
  }

  function remove(AddressSet storage self, address item) internal {
    if (!has(self, item)) return;

    removeAt(self, self.indexes[item] - self.startIndex);
  }

  function removeAt(AddressSet storage self, uint256 index) internal {
    if (index >= size(self)) return;

    uint256 start = self.startIndex;
    address firstItem = self.addresses[start];

    index += start;

    self.addresses[index] = firstItem;
    self.indexes[firstItem] = index;
    delete self.addresses[start];

    self.startIndex++;
  }

  function size(AddressSet storage self) internal view returns (uint256) {
    return self.totalCount - self.startIndex;
  }

  function has(AddressSet storage self, address item) internal view returns (bool) {
    return self.addresses[self.indexes[item]] == item;
  }

  function get(AddressSet storage self, uint256 index) internal view returns (address) {
    return self.addresses[self.startIndex + index];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract SafeEntry is ReentrancyGuard {
  using Address for address;

  modifier notContract() {
    require(!Address.isContract(msg.sender), "Contract not allowed");

    // solhint-disable-next-line avoid-tx-origin
    require(msg.sender == tx.origin, "Proxy contract not allowed");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract TransferWithCommission is Ownable {
  using Address for address;

  uint16 public constant MAX_COMMISSION_RATE = 1000;

  uint16 public commissionRate = 500;
  uint16 public referralRate = 100;
  uint16 public cancellationFee = 100;

  mapping(address => address) public referrers;

  function setFees(
    uint16 _commissionRate,
    uint16 _referralRate,
    uint16 _cancellationFee
  ) external onlyOwner {
    require(
      _commissionRate <= MAX_COMMISSION_RATE && _referralRate <= _commissionRate && _cancellationFee <= _commissionRate,
      "Transfer: Value exceeds maximum"
    );

    commissionRate = _commissionRate;
    referralRate = _referralRate;
    cancellationFee = _cancellationFee;
  }

  function refund(address to, uint256 amount) internal {
    uint256 fee = (amount * cancellationFee) / 10000;

    Address.sendValue(payable(to), amount - fee);
    if (fee != 0) Address.sendValue(payable(owner()), fee);
  }

  function send(address to, uint256 amount) internal {
    uint256 fee = (amount * commissionRate) / 10000;
    Address.sendValue(payable(to), amount - fee);

    if (fee == 0) return;

    address referrer = referrers[to];
    if (referrer != address(0)) {
      uint256 refBonus = (amount * referralRate) / 10000;

      Address.sendValue(payable(referrer), refBonus);
      fee -= refBonus;
    }

    Address.sendValue(payable(owner()), fee);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ValueLimits is Ownable {
  uint256 public minValue;
  uint256 public maxValue;

  constructor(uint256 min, uint256 max) {
    minValue = min;
    maxValue = max;
  }

  modifier isMinValue() {
    require(msg.value >= minValue, "ValueLimits: Less than minimum");
    _;
  }

  modifier isMaxValue() {
    require(msg.value <= maxValue, "ValueLimits: More than maximum");
    _;
  }

  function setMinValue(uint256 val) external onlyOwner {
    minValue = val;
  }

  function setMaxValue(uint256 val) external onlyOwner {
    maxValue = val;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWhirlpoolConsumer.sol";
import "./interfaces/IWhirlpool.sol";

abstract contract WhirlpoolConsumer is Ownable, IWhirlpoolConsumer {
  IWhirlpool internal whirlpool;
  mapping(bytes32 => uint256) internal activeRequests;

  bool public whirlpoolEnabled = false;

  constructor(address _whirlpool) {
    whirlpool = IWhirlpool(_whirlpool);
  }

  function _requestRandomness(uint256 id) internal {
    if (whirlpoolEnabled) {
      bytes32 requestId = whirlpool.request();
      activeRequests[requestId] = id;
    } else {
      bytes32 random = keccak256(
        // solhint-disable-next-line not-rely-on-time
        abi.encodePacked(id, block.difficulty, block.timestamp, block.gaslimit, block.coinbase, block.number)
      );
      _consumeRandomness(id, uint256(random));
    }
  }

  function consumeRandomness(bytes32 requestId, uint256 randomness) external override onlyWhirlpoolOrOwner {
    _consumeRandomness(activeRequests[requestId], randomness);
    delete activeRequests[requestId];
  }

  function enableWhirlpool() external onlyOwner {
    whirlpool.addConsumer(address(this));
    whirlpoolEnabled = true;
  }

  function disableWhirlpool() external onlyOwner {
    whirlpoolEnabled = false;
  }

  function _consumeRandomness(uint256 id, uint256 randomness) internal virtual;

  modifier onlyWhirlpoolOrOwner() {
    require(msg.sender == address(whirlpool) || msg.sender == owner(), "WhirlpoolConsumer: Not whirlpool");
    _;
  }
}

// SPDX-License-Identifier: MIT

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

interface IWhirlpoolConsumer {
  function consumeRandomness(bytes32 requestId, uint256 randomness) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWhirlpool {
  function request() external returns (bytes32);

  function setKeyHash(bytes32 _keyHash) external;

  function setFee(uint256 _fee) external;

  function addConsumer(address consumerAddress) external;

  function deleteConsumer(address consumerAddress) external;

  function withdrawLink() external;
}

