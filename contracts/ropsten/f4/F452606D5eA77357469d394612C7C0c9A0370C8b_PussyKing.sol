pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract PussyKing is Initializable, ContextUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _pussyIdTracker;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    struct Pussy {
        string Name;
        uint256 PussyId;
        address King;
    }

    struct Auction {
        bool IsStillInProgress;
        uint256 MinPrice;
        uint256 PussyId;
        uint256 AuctionEndTime;
        address OnlySellTo;
    }

    struct Offer {
        uint PussyId;
        uint Value;
        address Bidder;
    }
    
    bool private initialized;

    string private _baseTokenURI;
    string private _name;
    string private _symbol;
    address payable private _author;

    uint256 private _earnedEth;
    uint256 private _releasedEth;
    uint256 public _minBidStep;

    mapping(address => uint256) private _balances;

    mapping(uint256 => Pussy) private _pussies;
    mapping(uint256 => Auction) private _auctions;
    mapping(uint256 => Offer) private _offers;

    function initialize() public initializer {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        
        __Context_init();

        _minBidStep = 1 * (10 ** 18);

        _name = "PussyKing";
        _symbol = "PUSS";
        _baseTokenURI = "https://pussykingclub.com/";
        _author = payable(0x94BBbeD9d21EdE44753406A27B0aFd4825AC2ef2);
    }

    function ownerOf(uint256 pussyId) public view returns (address) {
        address king = _pussies[pussyId].King;
        require(king != address(0), "King query for nonexistent pussy");
        return king;
    }

    function balanceOf(address king) public view returns (uint256) {
        require(king != address(0), "Balance query for the zero king");
        return _balances[king];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 pussyId) public view returns (string memory) {
        require(_pussies[pussyId].PussyId != 0, "Invalid pussyId");

        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, pussyId.toString())) : "";
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 pussyId
    ) public {
        require(_msgSender() == from);
        require(ownerOf(pussyId) == from, "Transfer of pussy that is not own");
        require(to != address(0), "Transfer to the zero king");
        require(_auctions[pussyId].IsStillInProgress == false, "Auction is still in progress");

        _balances[from] -= 1;
        _balances[to] += 1;
        _pussies[pussyId].King = to;

        emit Transfer(from, to, pussyId);
    }

    function uploadPussy(string memory pussyName) public {
        require(_msgSender() == _author, "Method is available only to author");
        _pussyIdTracker.increment();
        uint256 pussyId = _pussyIdTracker.current();
        _pussies[pussyId] = Pussy(pussyName, pussyId, payable(address(0)));
    }
    
    function authorAuction(uint256 pussyId, uint256 startPrice, uint256 auctionTimeInDate) public {
        require(_pussies[pussyId].PussyId != 0, "Invalid pussyId");
        Pussy memory pussy = _pussies[pussyId];
        require(pussy.King == address(0) && _msgSender() == _author, "Sender not author");

        startAuction(pussyId, startPrice, auctionTimeInDate, address(0));
    }

    function auctionPussy(uint256 pussyId, uint256 startPrice, uint256 auctionTimeInDate) public {
        require(_pussies[pussyId].PussyId != 0, "Invalid pussyId");
        Pussy memory pussy = _pussies[pussyId];
        require(pussy.King == _msgSender(), "Sender not king of pussy");

        startAuction(pussyId, startPrice, auctionTimeInDate, address(0));
    }

    function offerPussyToAddress(uint256 pussyId, uint256 minPrice, uint256 offerEndTimeInDate, address sellTo) public {
        require(_pussies[pussyId].PussyId != 0, "Invalid pussyId");
        require(sellTo != address(0), "Sell to zero address");
        Pussy memory pussy = _pussies[pussyId];
        require(pussy.King == _msgSender(), "Sender not king of pussy");

        startAuction(pussyId, minPrice, offerEndTimeInDate, sellTo);
    }

    function startAuction(uint256 pussyId, uint256 startPrice, uint256 auctionTimeInDate, address onlySellTo) private {
        require(startPrice >= 1 * (10 ** 18), "Min price 1 eth"); // more then 1 eth
        require(_auctions[pussyId].IsStillInProgress == false, "Auction is still in progress");
        require(auctionTimeInDate >= 1);

        uint256 auctionEndTime = block.timestamp + auctionTimeInDate * 60;
        _auctions[pussyId] = Auction(true, startPrice, pussyId, auctionEndTime, onlySellTo);
    }

    function pussyOf(uint256 pussyId) public view returns (string memory, uint256, address) {
        require(_pussies[pussyId].PussyId != 0, "Invalid pussyId"); 
        Pussy memory pussy = _pussies[pussyId];
        return (pussy.Name, pussy.PussyId, pussy.King);
    }
    
    function auctionOf(uint256 pussyId) public view returns (bool, uint256, uint256, uint256, address ) {
        require(_pussies[pussyId].PussyId != 0, "Invalid pussyId");
        Auction memory auction = _auctions[pussyId];
        return (auction.IsStillInProgress, auction.MinPrice, auction.PussyId, auction.AuctionEndTime, auction.OnlySellTo);
    }
    
    function offerOf(uint256 pussyId) public view returns (uint256,  uint256, address) {
        require(_pussies[pussyId].PussyId != 0, "Invalid pussyId");
        Offer memory offer = _offers[pussyId];
        return (offer.PussyId, offer.Value, offer.Bidder);
    }

    function placeBid(uint256 pussyId) external payable {
        require(_pussies[pussyId].PussyId != 0, "Invalid pussyId");

        Auction memory auction = _auctions[pussyId];
        require(auction.AuctionEndTime > block.timestamp, "Auction is over");
        require(auction.OnlySellTo == address(0) || auction.OnlySellTo == _msgSender());
        
        Offer storage offer = _offers[pussyId];
        require(msg.value > offer.Value + _minBidStep, "Insufficient price");

        if (offer.Bidder != address(0)) {
            AddressUpgradeable.sendValue(payable(offer.Bidder), offer.Value);
        }

        _offers[pussyId] = Offer(pussyId, msg.value, _msgSender());
    }

    function becomePussyKing(uint256 pussyId) external {
        require(_pussies[pussyId].PussyId != 0, "Invalid pussyId");

        Auction memory auction = _auctions[pussyId];
        require(auction.IsStillInProgress, "Auction is not still in progress");
        require(auction.AuctionEndTime < block.timestamp, "The auction is still in progress");

        Offer memory offer = _offers[pussyId];
        require(offer.Bidder != address(0), "Bidder is zero");


        Pussy memory pussy = _pussies[pussyId];
        uint256 authorReward = 0;
        address from = pussy.King;
        address to = offer.Bidder;
        if(from == address(0)){
            authorReward = offer.Value;
        } else {
            uint256 authorCommision = offer.Value / 10;
            AddressUpgradeable.sendValue(payable(from), offer.Value - authorCommision);
            authorReward = authorCommision;
            _balances[from] -= 1;
        }

        _earnedEth += authorReward;
        _balances[to] += 1;
        _pussies[pussyId] = Pussy(pussy.Name, pussyId, to);
        _offers[pussyId] = Offer(pussyId, 0, address(0));
        _auctions[pussyId] = Auction(false, 0, pussyId, 0, address(0));

        emit Transfer(from, to, pussyId);
    }

    function abortAuction(uint256 pussyId) external {
        require(_offers[pussyId].Bidder == address(0), "Has bid");
        address king = _pussies[pussyId].King;
        require(_msgSender() == king || (king == address(0) && _msgSender() == _author));
        _auctions[pussyId] = Auction(false, 0, pussyId, 0, address(0));
    }

    function releaseEarn() external {
        require(_msgSender() == _author, "Method is available only to author");
        uint256 currentRelease = _earnedEth - _releasedEth;
        require(currentRelease > 0, "currentRelease = 0"); 
        AddressUpgradeable.sendValue(_author, currentRelease);
        _releasedEth += currentRelease;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}