// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';

import './RarePizzasBox.sol';

import '../interfaces/IChainlinkVRFRandomConsumer.sol';
import '../interfaces/IRarePizzasBoxV2Admin.sol';

/**
 * Public interface for interacting with rare pizzas box V2
 */
interface IChainlinkVRFCallback {
    /**
     * Callback function called by the VRF consumer with random response
     */
    function fulfillRandomness(bytes32 request, uint256 random) external;
}

contract RarePizzasBoxV2 is RarePizzasBox, IChainlinkVRFCallback, IRarePizzasBoxV2Admin {
    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    // V2 Variables (do not modify this section when upgrading)

    event VRFConsumerUpdated(address oldConsumer, address newConsumer);
    event InternalArtworkAssigned(uint256 tokenId, uint256 artworkURI);

    address internal _chainlinkVRFConsumer;
    mapping(bytes32 => address) internal _purchaseID;

    // END V2 Variables

    // IChainlinkVRFCallback

    function fulfillRandomness(bytes32 request, uint256 random) external override {
        require(msg.sender == _chainlinkVRFConsumer, 'caller not VRF');
        address to = _purchaseID[request];

        require(to != address(0), 'purchase must exist');

        uint256 id = _getNextPizzaTokenId();
        _safeMint(to, id);
        _assignBoxArtwork(id, random);
    }

    // IRarePizzasBox V1 Overrides

    function purchase() public payable virtual override {
        require(
            block.timestamp >= publicSaleStart_timestampInS ||
                (_presalePurchaseCount[msg.sender] < _presaleAllowed[msg.sender]),
            "sale hasn't started"
        );
        require(totalSupply().add(1) <= MAX_TOKEN_SUPPLY, 'exceeds supply.');

        uint256 price = getPrice();
        require(msg.value >= price, 'price too low');
        payable(msg.sender).transfer(msg.value - price);

        // Presale addresses can purchase up to X total
        _presalePurchaseCount[msg.sender] += 1;
        _purchased_pizza_count.increment();
        _externalMintWithArtwork(msg.sender); // V2: mint using external randomness

        // BUY ONE GET ONE FREE!
        if (_purchased_pizza_count.current().add(1) == MAX_PURCHASABLE_SUPPLY) {
            _presalePurchaseCount[msg.sender] += 1;
            _purchased_pizza_count.increment();
            _externalMintWithArtwork(msg.sender); // V2: mint using external randomness
        }
    }

    // IRarePizzasBoxV2Admin

    function setVRFConsumer(address consumer) public virtual override onlyOwner {
        address old = _chainlinkVRFConsumer;
        _chainlinkVRFConsumer = consumer;
        emit VRFConsumerUpdated(old, _chainlinkVRFConsumer);
    }

    // Internal Stuff

    function _assignBoxArtwork(uint256 tokenId, uint256 random) internal virtual {
        uint256 pseudoRandom = random % BOX_LENGTH;
        _tokenBoxArtworkURIs[tokenId] = pseudoRandom;
    }

    /**
     * override replaces the previous block hash with the difficulty
     */
    function _assignBoxArtwork(uint256 tokenId) internal override {
        uint256 pseudoRandom =
            uint256(keccak256(abi.encodePacked(blockhash(block.difficulty - 1), tokenId, msg.sender))) % BOX_LENGTH;
        _tokenBoxArtworkURIs[tokenId] = pseudoRandom;
        // this function should only be called from owner or as a fallback
        // so emit an event whenever it is called
        emit InternalArtworkAssigned(tokenId, pseudoRandom);
    }

    function _externalMintWithArtwork(address to) internal virtual {
        if (_chainlinkVRFConsumer != address(0)) {
            try IChainlinkVRFRandomConsumer(_chainlinkVRFConsumer).getRandomNumber() returns (bytes32 requestId) {
                _purchaseID[requestId] = to;
                // pizza box is out for delivery
                return;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // contract doesnt implement interface, use fallback
                } else {
                    //we got an error and dont care, use fallback
                }
            }
        }

        // fallback to the block-based implementation
        _internalMintWithArtwork(to);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';

import '@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol';

import '../math/BondingCurve.sol';
import '../interfaces/IOpenSeaCompatible.sol';
import '../interfaces/IRarePizzasBox.sol';
import '../interfaces/IRarePizzasBoxAdmin.sol';
import '../data/BoxArt.sol';

/**
 * @dev Rare Pizzas Box mints pizza box token for callers who call the purchase function.
 */
contract RarePizzasBox is
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    BoxArt,
    BondingCurve,
    IRarePizzasBox,
    IRarePizzasBoxAdmin,
    IOpenSeaCompatible
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    // V1 Variables (do not modify this section when upgrading)

    event BTCETHPriceUpdated(uint256 old, uint256 current);

    uint256 public constant MAX_TOKEN_SUPPLY = 10000;
    uint256 public constant MAX_MINTABLE_SUPPLY = 1250;
    uint256 public constant MAX_PURCHASABLE_SUPPLY = 8750;

    uint256 public publicSaleStart_timestampInS;
    uint256 public bitcoinPriceInWei;

    string public constant _uriBase = 'https://ipfs.io/ipfs/';

    address internal _chainlinkBTCETHFeed;

    CountersUpgradeable.Counter public _minted_pizza_count;
    CountersUpgradeable.Counter public _purchased_pizza_count;

    mapping(uint256 => uint256) internal _tokenBoxArtworkURIs;

    mapping(address => uint256) internal _presaleAllowed;
    mapping(address => uint256) internal _presalePurchaseCount;

    // END V1 Variables

    // V2 Events Added

    event PresaleAllowedUpdated();
    event SaleStartTimestampUpdated(uint256 old, uint256 current);

    // END V2 Events Added

    function initialize(address chainlinkBTCETHFeed) public initializer {
        __Ownable_init();
        __ERC721_init('Rare Pizza Box', 'ZABOX');

        // Date and time (GMT): Set to PI
        publicSaleStart_timestampInS = 3141592653;
        // starting value:  31.00 ETH
        bitcoinPriceInWei = 31000000000000000000;

        if (chainlinkBTCETHFeed != address(0)) {
            _chainlinkBTCETHFeed = chainlinkBTCETHFeed;
        }
    }

    // IOpenSeaCompatible
    function contractURI() public view virtual override returns (string memory) {
        // Metadata provided via github link so that it can be updated or modified
        return
            'https://raw.githubusercontent.com/PizzaDAO/pizza-smartcontract/master/data/opensea_metadata.mainnet.json';
    }

    // IRarePizzasBox
    function getBitcoinPriceInWei() public view virtual override returns (uint256) {
        return bitcoinPriceInWei;
    }

    function getPrice() public view virtual override returns (uint256) {
        return getPriceInWei();
    }

    function getPriceInWei() public view virtual override returns (uint256) {
        return ((super.curve(_purchased_pizza_count.current() + 1) * bitcoinPriceInWei) / oneEth);
    }

    function maxSupply() public view virtual override returns (uint256) {
        return MAX_TOKEN_SUPPLY;
    }

    function purchase() public payable virtual override {
        require(
            block.timestamp >= publicSaleStart_timestampInS ||
                (_presalePurchaseCount[msg.sender] < _presaleAllowed[msg.sender]),
            "sale hasn't started"
        );
        require(totalSupply().add(1) <= MAX_TOKEN_SUPPLY, 'exceeds supply.');

        uint256 price = getPrice();
        require(msg.value >= price, 'price too low');
        payable(msg.sender).transfer(msg.value - price);

        // Presale addresses can purchase up to X total
        _presalePurchaseCount[msg.sender] += 1;
        _purchased_pizza_count.increment();
        _internalMintWithArtwork(msg.sender);

        // BUY ONE GET ONE FREE!
        if (_purchased_pizza_count.current().add(1) == MAX_PURCHASABLE_SUPPLY) {
            _presalePurchaseCount[msg.sender] += 1;
            _purchased_pizza_count.increment();
            _internalMintWithArtwork(msg.sender);
        }
    }

    // IERC721 Overrides

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, IERC721MetadataUpgradeable)
        returns (string memory)
    {
        require(_exists(tokenId), 'does not exist, paisano');
        return string(abi.encodePacked(_uriBase, getUriString(_tokenBoxArtworkURIs[tokenId])));
    }

    // IRarePizzasBoxAdmin

    function mint(address toPizzaiolo, uint8 count) public virtual override onlyOwner {
        require(toPizzaiolo != address(0), 'dont be silly');
        require(count > 0, 'need a number');
        require(totalSupply().add(count) <= maxSupply(), 'would exceed supply.');
        require(_minted_pizza_count.current().add(count) <= MAX_MINTABLE_SUPPLY, 'would exceed mint');

        for (uint256 i = 0; i < count; i++) {
            _minted_pizza_count.increment();
            _internalMintWithArtwork(toPizzaiolo);
        }
    }

    function purchaseTo(address toPaisano) public payable virtual override onlyOwner {
        require(toPaisano != address(0), 'dont be silly');
        require(totalSupply().add(1) <= MAX_TOKEN_SUPPLY, 'would exceed supply.');
        require(toPaisano != msg.sender, 'thats how capos get whacked');

        uint256 price = getPrice();
        require(msg.value >= price, 'price too low');
        payable(msg.sender).transfer(msg.value - price);

        _purchased_pizza_count.increment();
        _internalMintWithArtwork(toPaisano);
    }

    function setPresaleAllowed(uint8 count, address[] memory toPaisanos) public virtual override onlyOwner {
        for (uint256 i = 0; i < toPaisanos.length; i++) {
            require(toPaisanos[i] != address(0), 'dont be silly');
            _presaleAllowed[toPaisanos[i]] = count;
        }

        emit PresaleAllowedUpdated();
    }

    function setSaleStartTimestamp(uint256 epochSeconds) public virtual override onlyOwner {
        uint256 old = publicSaleStart_timestampInS;
        publicSaleStart_timestampInS = epochSeconds;

        emit SaleStartTimestampUpdated(old, epochSeconds);
    }

    function updateBitcoinPriceInWei(uint256 fallbackValue) public virtual override onlyOwner {
        if (_chainlinkBTCETHFeed != address(0)) {
            try AggregatorV3Interface(_chainlinkBTCETHFeed).latestRoundData() returns (
                uint80, // roundId,
                int256 answer,
                uint256, // startedAt,
                uint256, // updatedAt,
                uint80 // answeredInRound
            ) {
                uint256 old = bitcoinPriceInWei;
                bitcoinPriceInWei = uint256(answer);
                emit BTCETHPriceUpdated(old, bitcoinPriceInWei);
                return;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // contract doesnt implement interface, use fallback
                } else {
                    //we got an error and dont care, use fallback
                }
            }
        }
        // obviously if the link integration fails,
        // the owner could set an arbitrary value here that is way out of range.
        if (fallbackValue > 0) {
            uint256 old = bitcoinPriceInWei;
            bitcoinPriceInWei = fallbackValue;
            emit BTCETHPriceUpdated(old, bitcoinPriceInWei);
        }
        // nothing got updated.  The miners thank you for your contribution.
    }

    function withdraw() public virtual override onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Internal Stuff

    function _assignBoxArtwork(uint256 tokenId) internal virtual {
        uint256 pseudoRandom =
            uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId, msg.sender))) % MAX_BOX_INDEX;
        _tokenBoxArtworkURIs[tokenId] = pseudoRandom;
    }

    function _getNextPizzaTokenId() internal view virtual returns (uint256) {
        return totalSupply();
    }

    function _internalMintWithArtwork(address to) internal virtual {
        uint256 id = _getNextPizzaTokenId();
        _safeMint(to, id);
        _assignBoxArtwork(id);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Public interface for interacting with the VRF Random Consumer Contract
 */
interface IChainlinkVRFRandomConsumer {
    /**
     * Get a random number from the VRF
     */
    function getRandomNumber() external returns (bytes32 requestId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IRarePizzasBoxAdmin.sol';

/**
 * Public interface for interacting with rare pizzas box V2 as an administrator
 * All methods should be implemented as onlyOwner
 */
interface IRarePizzasBoxV2Admin is IRarePizzasBoxAdmin {
    /**
     * Allows owner to set the VRF consumer address
     */
    function setVRFConsumer(address consumer) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "./extensions/IERC721EnumerableUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC721Upgradeable).interfaceId
            || interfaceId == type(IERC721MetadataUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721Upgradeable.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721Upgradeable.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BondingCurve {
    uint256 constant oneEth = 10**18;
    uint256 constant MAX_CURVE = 8750;
    uint256 constant TIER1 = ((501 * oneEth) / 10**4);
    uint256 constant TIER2 = TIER1 + ((100 * oneEth) / 10**3);
    uint256 constant TIER3 = TIER2 + ((250 * oneEth) / 10**3);
    uint256 constant TIER4 = TIER3 + ((250 * oneEth) / 10**3);
    uint256 constant TIER5 = TIER4 + ((500 * oneEth) / 10**3);

    // Approximate .001x^2+.000 000 000 000 000 000 000 000 0000999x^{8}

    function curve(uint256 n) public pure returns (uint256 price) {
        require(n > 0, 'position cannot be zero');
        require(n <= MAX_CURVE, 'cannot pass MAX_CURVE');

        uint256[25] memory approxvalues =
            [
                uint256(100),
                436,
                650,
                900,
                1000,
                1200,
                1400,
                1500,
                1600,
                1700,
                1800,
                1900,
                2000,
                2400,
                3000,
                4000,
                4400,
                6000,
                12000,
                24000,
                50000,
                100000,
                240000,
                333300,
                1000000
            ];

        if (n <= 2500) {
            return ((2 * n * oneEth) / 10**5) + oneEth / 10**4;
        }
        if (n > 2500 && n <= 5000) {
            return TIER1 + ((4 * (n - 2500) * oneEth) / 10**5);
        }
        if (n > 5000 && n <= 7500) {
            return TIER2 + (((n - 5000) * oneEth) / 10**4);
        }
        if (n > 7500 && n <= 8000) {
            return TIER3 + ((5 * (n - 7500) * oneEth) / 10**4);
        }
        if (n > 8000 && n <= 8500) {
            return TIER4 + (((n - 8000) * oneEth) / 10**3);
        }
        if (n > 8500 && n <= 8724) {
            return TIER5 + ((3 * (n - 8500) * oneEth) / 10**3);
        }
        if (n > 8724 && n < 8750) {
            return approxvalues[n - 8725] * 10**16;
        }
        if (n == 8750) {
            return 0;
        }

        // Keeping the compiler happy.
        // Should never get here.
        return approxvalues[approxvalues.length - 1] * 10**16;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

interface IOpenSeaCompatible is IERC721MetadataUpgradeable {
    /**
     * Get the contract metadata
     */
    function contractURI() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol';

/**
 * Public interface for interacting with rare pizzas
 */
interface IRarePizzasBox is IERC721EnumerableUpgradeable {
    /**
     * Get the btc eth exchange rate as set by the contract admin or
     * queried from an oracle
     */
    function getBitcoinPriceInWei() external view returns (uint256);

    /**
     * Get the current price on the bonding curve * the btc/eth exchange rate
     * may be an alias to getPriceInWei()
     */
    function getPrice() external view returns (uint256);

    /**
     * Get the current price on the bonding curve * the btc/eth exchange rate
     */
    function getPriceInWei() external view returns (uint256);

    /**
     * Get the maximum supply of tokens
     */
    function maxSupply() external view returns (uint256);

    /**
     * Try to purchase one token
     */
    function purchase() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Public interface for interacting with rare pizzas as an administrator
 * All methods should be implemented as onlyOwner
 */
interface IRarePizzasBoxAdmin {
    /**
     * Allows the contract owner to mint up to a specific number of boxes
     * owner can mit to themselves
     */
    function mint(address to, uint8 count) external;

    /**
     * Allows owner to purchase to a specific address
     * owner cannot purchase for themselves
     */
    function purchaseTo(address to) external payable;

    /**
     * Allows owner to add or remove addresses fro mthe presale list
     */
    function setPresaleAllowed(uint8 count, address[] memory toPaisanos) external;

    /**
     * Allows owner to set the sale start timestamp.
     * By modifying this value, the owner can pause the sale
     * by setting a timestamp arbitrarily in the future
     */
    function setSaleStartTimestamp(uint256 epochSeconds) external;

    /**
     * Allows the owner to update the cached bitcoin price
     */
    function updateBitcoinPriceInWei(uint256 fallbackValue) external;

    /**
     * Withdraw ether from this contract (Callable by owner)
     */
    function withdraw() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev a FakeRarePizzasBox is a wrapper exposing modifying contract variables for testing
 */
contract BoxArt {
    uint256 internal constant BOX_LENGTH = 100;
    uint256 internal constant MAX_BOX_INDEX = 99;

    /**
     * Get the uri for the artwork
     */
    function getUriString(uint256 index) internal pure returns (string memory) {
        string[BOX_LENGTH] memory assets =
            [
                'QmSnxgu8V9hw8wRUSMh3MoUDShgYeHatKnTwRiVFezgUnh',
                'QmZ4q72eVU3bX95GXwMXLrguybKLKavmStLWEWVJZ1jeyz',
                'QmXTSvbDSV16Vovhj9kuPYeEE8ewo5GRMDbRUTBP2yLP5P',
                'QmbkKfCoiUp82DcmmvcU8Uceztisp2MDZaMC79PjGfsjZf',
                'QmPvhL5SQTdxJweoqNxJeD1gMdx5tQJZYWZvXy4R3b2hmU',
                'QmNPfd5F7BNmtWeqbTEpqMfWFBg2fEKUfiX9UK2tGCbgZw',
                'QmaKLRMTRTyRDRftiR4Xpfx33ZEiXUBnRN2rPx3xfXvxZX',
                'Qmb4uWgGARSyPdcj31YiUDD8RCwPkk6AwadSR7LoKVPKP6',
                'QmTj5V7CLhKRg3sNBfk7hqqHCV26frQsGuHVDxdcFHwnVL',
                'QmTD17Sp6An4eYbE782DdpkquxiUUP3AfGz4XLs85we9mM',
                'QmTBwJ2D21UJMmjG9VDFWd4zwoWJkDrMYSg2iy9eC1ZVJP',
                'QmQhLaUW3XEBPcdp276eWBfF4ePLDXqiL6y3Xv9qz9DwAS',
                'QmZf4SHZzgBiXBFXEHF8PGvjafvdY8ZmD5YTiKPzSiteD5',
                'QmRVMxmR5MPUEQe1X84q72BX8wo1fbCMyvGG2mBcnTsSEa',
                'QmVc24hyYF5dniJCPrAy7PMWY7fLeU1hxGaSP8ZjUp1vrL',
                'QmQ7BsDb5aZVBCLcrK47JmrbJCPYak9oWXRk3zE6RCMH2y',
                'QmX2VkWXiY6spRH3sEk6khsBzbuPdBJJKXxzkxu42XWqM7',
                'QmUD8uqb24732HPorZ7kD5TXPaTEqcY26mT26nGwsq1VY5',
                'QmXp4TDoDfXmENr7m85kSLrpoD5UV4Vg9EbDqgj9Q3nNXn',
                'QmPCihu3KXqqPpCBXkjzk4aaJkCdbquRn629U8osSTtjhw',
                'QmdGUp241vCFGRK52xjsDS42oXiz4pP2cacqtAQbaxGDw1',
                'QmUSVp3Ur6jiFgCEEutDWQ32Z2uFinep5n7f8zoXpqC9iy',
                'Qmb8c1TC6sHwHmZvmpwUwaak776bTncHt1tyw5WTwXyukq',
                'QmQyi6vYaTqoafEFidhv8wz5skhEnXUwddv7ke6imJZTXa',
                'QmeLfCCxdKf5xgL94tnmny11xcG9C9CF5ZQmvVk8tbYEwT',
                'QmUw5jK3E3WSXTd5Ke4SQc99wbQR3KzfUJhWJoW2k5tp4b',
                'QmPtETphemJqCBgQLurAZjRnLL73XXPrRpsdoph79BPGUA',
                'QmYPms5a1QgUFjEcd7qxcxN7knByERe45GMXcjyDtJsjMi',
                'QmdepT5F1THKiszE654pS91muBrqjL4LLVVq2XTqEvwNip',
                'QmNmP3WTN8eKypabmevxMiWJeFesb4VWD8SzfkoygAYHKX',
                'QmRk52NGwg4X7nArYkwN8RFrWBSvKjJK19c5zSLEc6jFsa',
                'Qmd64sb7Dqw6mfd2x1BuE2eSJvzezsJopm3SUtJVJwoHm4',
                'QmchRWTi7YKoZJGEaiCaGe3fx7wzsrrMDpYCXrH9J59P6U',
                'QmQfeXrAKA5zKg6L55veicNJ2RT62wJCdFzjeY7TySUjT4',
                'QmczuzS5iXXjSxKQF9gQSMEGdMpafAT9NAEJgr7V2cteCp',
                'QmesAKGGuiaveC18orbyyUzBGjyNYM6ofGkdWzaPGBaqeg',
                'QmbmLP384LQ76KDE449Y4PohvpTqpv9B7qu83euMAQHdMC',
                'QmYCKW12HzqxSfxGhoFwAsfriqPKnSZsCfFj4QXhYoTjBy',
                'Qmenbx1VhYkhaa3gXLHL1s8MLxfMieYAMFgp9RZVUZvMFq',
                'QmRNx5GtHSNzqKtRnRJEX2LTHZ1A6JCXkDD2Rex46Q29oc',
                'Qmf5ueJdG94SZ5ZmZBypfE4cxrnmETGnsrAZkt33VMpn58',
                'QmZHxu7o8VvdQxS9smEEiNFNahGULBtQ8X6KjHaZkKBs1Z',
                'QmVnaacQsafwWH8VpkZQCrnAh63EFjCNtTHA7yjsaQkrUW',
                'QmQF7vMgjudvNicj93DKBdq8h6T6kGuszCsNWEBBb3gDwH',
                'QmVSemzoNsYgX7VxvmNKR8NLJBuLmBS9zZ4hsJ71d5n5PU',
                'QmXYR19yiM1CxMo3JKDQzHKLs7iog9dp7pci9Gh5Qym1sd',
                'QmP5KcWpWzBw1QsL6iek2E1gTXsnoJ66nn1VQQk4bG5RyY',
                'QmZC3mhXxyTBvfSGG458cg5QmmWJXYQrcu3bVTZ8q7Uavr',
                'QmVBmvnizUebTzVw4YjigUer1yfVwibJNa3ygvudWQ6oeV',
                'QmX5WYvzsuydDZKpQDMd2wMFzKet1x6axH7UxaPguecH3p',
                'QmVCAE5KVKAbYLWE3XYjpqMGEy8dt1AM9gRNfJSPYuXq9G',
                'QmcYoyQ7UnBEx6sC2fQH1MGhrB3bQyKa3qVNUCwBQVxkPa',
                'QmeYWsL4gSjFUZW392rSmSqP1eLvbMUtAznToBxTq7bT5Z',
                'QmWtHkzFGdLjB3Gt9d8Ma8ZUvykpR9ARtojqXr3nYU24Z5',
                'QmeC3ZUwtk2poJKcexcK5LdwhiA7jFcLUeHrHsEgMEXuy8',
                'QmQNXJj76fGFdL6isvAGqD8cFPqkGpxppymW2qttgfdFUX',
                'QmZLxaHtp2qCbGVhAervUipS6Xhoh8tB9ommF1kHaGaKPw',
                'QmRRuzzuETKibgaKapNvdTxiud9FxjC5HVEH8eayeNfnum',
                'QmcLqe1p6hKdk6eV27Sr5chRxJyMcGjYCUasFfhPnYaLGr',
                'Qmadg5qypy5Bir5WvCsrDGVVHFLsTSTCt2gsJWGmCNoqgj',
                'Qmd6rULs8XtUcnSyUZRzqf9MkpykeCKsDEgbbZdgjwXevf',
                'QmemtVU6n9RKQDGXLgvUXjRk46NBFtzZPgn2YFN3VGWcSi',
                'QmZUT1S6m9KWjAuGhNd78bf4k8ATbTuhvLdAQVzxtU1F7M',
                'QmUgFf5jQKNGvL8zYrW2uJE9ty2NGkXWzVkX3CmakEH5C8',
                'QmepSPKMnBxFD61qZBwJGeHrtQ4Eq9SYrJj8JMaAEcYQDr',
                'Qmb4yLr4K7gsmstiprN8im2Epb3JsivBafipJKrQxZSctS',
                'QmTQjnUqDjczuCxKEeGfSTnzV1sSntJiKaYY4at5CR9e32',
                'QmNqkTZUvroMDithxpU2iRXfffP414HdsMnciUMVCDwx69',
                'QmQAzMBnqL7ZFkLGx2EvMp26xABQ7WW4U5GXUaa7Jeo3f1',
                'QmWZ95dtJ6LFB72oahyjGhd3bEb6K8enMNGFhKMGYm1L2s',
                'QmTy92vfZUYVSKQkqNpKSviUmSmgxpppr7YU4V3xciXxoK',
                'QmSXC2pcp2YAG3wAapkBsJpjcJWQQ7Z5YXuQp2ahJb3ckZ',
                'QmUV4ThFSAFyoHhsA6HN93w9s9FD8AMFxgzQc4axQF9nkX',
                'QmewqxpnbdDmW81AZpsa8Hkjr2thpv3mdGSXHPvVBpgv4w',
                'QmWJhr3zZThDX6h1itgdwZiopWMqfq4PePngfHsfhCcgUx',
                'QmVNPJFUs3P2FKWbdJDpbTniDzSZLh8ZG7kEaZJsoLtsYE',
                'QmT22hfdTWdPyW1n66sFa1jZp2dvaKYNgpt4ZFJ4kD7mwk',
                'QmNurSTpZ4JBsMsKwe1EpJkFDDsMDETUsaeNnnc8e2nBaN',
                'QmdANFtvCpceR2ngAijyorJKhnvJeXhLkvuMerBNw6fN5A',
                'QmXB15gJDSaH8Jx2APMV7WCJ4TqRwesdkCpvHVxwgReEta',
                'QmYddkxHSDr7qB7i7LrFvE3m1CPP2G4Jy1pf1318DfEgaX',
                'QmZwsto5k4PfbVRiik6wcEFsmZmfcynRLbpYt5W7MqrLWf',
                'QmRtwBg8bUsNowVA3725PAuvTupfc3s2q1UEXU4ybzjQBD',
                'QmfGaT9eBU2HnYt9aXicFewm8x8EoLFuqQafqcppiCC2zx',
                'QmTgTV7EnREdt83h4DHLsLc5Q6f25eshJX5wbShfhxf3ct',
                'QmdoD8dk4CVhZpvdmhwqrJX8fq1BQnxuW4YNF6SBigYxj6',
                'QmSsyDi4YJUYUHq9dapCuMzBXdZbAc5kYr2kc27WyfXdb6',
                'QmXeGVgSn353vnSaPHeoY22u4h7wX8gwWd2hC1XE9qqVrP',
                'QmeE2s2Xm7jVHrXtW3zo7Srku4ViKQszYXczukPCVbfM6m',
                'QmbWpxXiSVeHUwxcqRS8khFkud6ZvLG5CwdqYPpGD9CEwM',
                'Qmb3FaytE4xpVZu2xTo4oRh1q6xYTZFMxRerNSoEYWKFc9',
                'Qmb3sQQUN3aTBq3tBBbTiWsGHHmjrmFHZGqoRb6z2fRtdh',
                'QmVYw6EevH7mSbMUSiwo1zgauZoB6RvNBbQpz7Qttgbg7W',
                'QmP6QV6kZHyvMy7aMxxwnNYAYU5tgb5yW6QmPv3WW2FXeF',
                'QmcyPJvujyhYexMLJMYCtKc1zP35y7bkggtpRWCGfznNn4',
                'QmXYCgwheKJJgkEJVxt5kXVhf6MRqdMoTbhMFccu6F4Sub',
                'QmYWy1LGjwBWfZ72kBRVq9inApkBARu2zeADKX55GPgGiG',
                'QmYpnnFQnZifwULDap94ZEwoawrbPjWKGPhJcCF8c4muyr',
                'QmQGRRcdsjEjRrmHPPV4UC3C8HXfm3LNYK93puBN5zvwVg',
                'QmeDKdALtP2R2fQ76CNUpL74xdyoaJYWkdFdBzVvGZs7Vc'
            ];

        require(index < assets.length, 'requested index is out of range');

        return assets[index];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Initializable.sol";

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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