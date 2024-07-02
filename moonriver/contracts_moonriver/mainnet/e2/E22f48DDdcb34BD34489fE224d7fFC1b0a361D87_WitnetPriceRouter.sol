/**
 *Submitted for verification at moonriver.moonscan.io on 2022-04-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;

// File: ado-contracts\contracts\interfaces\IERC2362.sol
/**
* @dev EIP2362 Interface for pull oracles
* https://github.com/adoracles/EIPs/blob/erc-2362/EIPS/eip-2362.md
*/
interface IERC2362
{
	/**
	 * @dev Exposed function pertaining to EIP standards
	 * @param _id bytes32 ID of the query
	 * @return int,uint,uint returns the value, timestamp, and status code of query
	 */
	function valueFor(bytes32 _id) external view returns(int256,uint256,uint256);
}
// File: contracts\interfaces\IERC165.sol
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
// File: contracts\interfaces\IWitnetPriceRouter.sol
/// @title The Witnet Price Router basic interface.
/// @dev Guides implementation of price feeds aggregation contracts.
/// @author The Witnet Foundation.
abstract contract IWitnetPriceRouter
    is
        IERC2362 
{
    /// Emitted everytime a currency pair is attached to a new price feed contract
    /// @dev See https://github.com/adoracles/ADOIPs/blob/main/adoip-0010.md 
    /// @dev to learn how these ids are created.
    event CurrencyPairSet(bytes32 indexed erc2362ID, IERC165 pricefeed);

    /// Helper pure function: returns hash of the provided ERC2362-compliant currency pair caption (aka ID).
    function currencyPairId(string memory) external pure virtual returns (bytes32);

    /// Returns the ERC-165-compliant price feed contract currently serving 
    /// updates on the given currency pair.
    function getPriceFeed(bytes32 _erc2362id) external view virtual returns (IERC165);

    /// Returns human-readable ERC2362-based caption of the currency pair being
    /// served by the given price feed contract address. 
    /// @dev Should fail if the given price feed contract address is not currently
    /// @dev registered in the router.
    function getPriceFeedCaption(IERC165) external view virtual returns (string memory);

    /// Returns human-readable caption of the ERC2362-based currency pair identifier, if known.
    function lookupERC2362ID(bytes32 _erc2362id) external view virtual returns (string memory);

    /// Register a price feed contract that will serve updates for the given currency pair.
    /// @dev Setting zero address to a currency pair implies that it will not be served any longer.
    /// @dev Otherwise, should fail if the price feed contract does not support the `IWitnetPriceFeed` interface,
    /// @dev or if given price feed is already serving another currency pair (within this WitnetPriceRouter instance).
    function setPriceFeed(
            IERC165 _pricefeed,
            uint256 _decimals,
            string calldata _base,
            string calldata _quote
        )
        external virtual;

    /// Returns list of known currency pairs IDs.
    function supportedCurrencyPairs() external view virtual returns (bytes32[] memory);

    /// Returns `true` if given pair is currently being served by a compliant price feed contract.
    function supportsCurrencyPair(bytes32 _erc2362id) external view virtual returns (bool);

    /// Returns `true` if given price feed contract is currently serving updates to any known currency pair. 
    function supportsPriceFeed(IERC165 _priceFeed) external view virtual returns (bool);
}
// File: node_modules\@openzeppelin\contracts\utils\Context.sol
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)


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
// File: @openzeppelin\contracts\access\Ownable.sol
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)



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
// File: contracts\interfaces\IWitnetPriceFeed.sol
/// @title The Witnet Price Feed basic interface.
/// @dev Guides implementation of active price feed polling contracts.
/// @author The Witnet Foundation.

interface IWitnetPriceFeed {

    /// Signals that a new price update request is being posted to the Witnet Request Board
    event PriceFeeding(address indexed from, uint256 queryId, uint256 extraFee);

    /// Estimates minimum fee amount in native currency to be paid when 
    /// requesting a new price update.
    /// @dev Actual fee depends on the gas price of the `requestUpdate()` transaction.
    /// @param _gasPrice Gas price expected to be paid when calling `requestUpdate()`
    function estimateUpdateFee(uint256 _gasPrice) external view returns (uint256);

    /// Returns result of the last valid price update request successfully solved by the Witnet oracle.
    function lastPrice() external view returns (int256);

    /// Returns the EVM-timestamp when last valid price was reported back from the Witnet oracle.
    function lastTimestamp() external view returns (uint256);    

    /// Returns tuple containing last valid price and timestamp, as well as status code of latest update
    /// request that got posted to the Witnet Request Board.
    /// @return _lastPrice Last valid price reported back from the Witnet oracle.
    /// @return _lastTimestamp EVM-timestamp of the last valid price.
    /// @return _lastDrTxHash Hash of the Witnet Data Request that solved the last valid price.
    /// @return _latestUpdateStatus Status code of the latest update request.
    function lastValue() external view returns (
        int _lastPrice,
        uint _lastTimestamp,
        bytes32 _lastDrTxHash,
        uint _latestUpdateStatus
    );

    /// Returns identifier of the latest update request posted to the Witnet Request Board.
    function latestQueryId() external view returns (uint256);

    /// Returns hash of the Witnet Data Request that solved the latest update request.
    /// @dev Returning 0 while the latest update request remains unsolved.
    function latestUpdateDrTxHash() external view returns (bytes32);

    /// Returns error message of latest update request posted to the Witnet Request Board.
    /// @dev Returning empty string if the latest update request remains unsolved, or
    /// @dev if it was succesfully solved with no errors.
    function latestUpdateErrorMessage() external view returns (string memory);

    /// Returns status code of latest update request posted to the Witnet Request Board:
    /// @dev Status codes:
    /// @dev   - 200: update request was succesfully solved with no errors
    /// @dev   - 400: update request was solved with errors
    /// @dev   - 404: update request was not solved yet 
    function latestUpdateStatus() external view returns (uint256);

    /// Returns `true` if latest update request posted to the Witnet Request Board 
    /// has not been solved yet by the Witnet oracle.
    function pendingUpdate() external view returns (bool);

    /// Posts a new price update request to the Witnet Request Board. Requires payment of a fee
    /// that depends on the value of `tx.gasprice`. See `estimateUpdateFee(uint256)`.
    /// @dev If previous update request was not solved yet, calling this method again allows
    /// @dev upgrading the update fee if called with a higher `tx.gasprice` value.
    function requestUpdate() external payable;

    /// Tells whether this contract implements the interface defined by `interfaceId`. 
    /// @dev See the corresponding https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    /// @dev to learn more about how these ids are created.
    function supportsInterface(bytes4) external view returns (bool);
}
// File: @openzeppelin\contracts\utils\Strings.sol
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)


/**
 * @dev String operations.
 */
library Strings {
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
// File: contracts\apps\WitnetPriceRouter.sol
contract WitnetPriceRouter
    is
        IWitnetPriceRouter,
        Ownable
{
    using Strings for uint256;
    
    struct Pair {
        IERC165 pricefeed;
        uint256 decimals;
        string  base;
        string  quote;
    }    

    mapping (bytes4 => Pair) internal __pairs;
    mapping (address => bytes32) internal __pricefeedId_;

    bytes32[] internal __supportedCurrencyPairs;

    // ========================================================================
    // --- Implementation of 'IERC2362' ---------------------------------------

    /// Returns last valid price value and timestamp, as well as status of
    /// the latest update request that got posted to the Witnet Request Board. 
    /// @dev Fails if the given currency pair is not currently supported.
    /// @param _erc2362id Price pair identifier as specified in https://github.com/adoracles/ADOIPs/blob/main/adoip-0010.md
    /// @return _lastPrice Last valid price reported back from the Witnet oracle.
    /// @return _lastTimestamp EVM-timestamp of the last valid price.
    /// @return _latestUpdateStatus Status code of latest update request that got posted to the Witnet Request Board:
    ///          - 200: latest update request was succesfully solved with no errors
    ///          - 400: latest update request was solved with errors
    ///          - 404: latest update request is still pending to be solved    
	function valueFor(bytes32 _erc2362id)
        external view
        virtual override
        returns (
            int256 _lastPrice,
            uint256 _lastTimestamp,
            uint256 _latestUpdateStatus
        )
    {
        IWitnetPriceFeed _pricefeed = IWitnetPriceFeed(address(getPriceFeed(_erc2362id)));
        require(address(_pricefeed) != address(0), "WitnetPriceRouter: unsupported currency pair");
        (_lastPrice, _lastTimestamp,, _latestUpdateStatus) = _pricefeed.lastValue();
    }


    // ========================================================================
    // --- Implementation of 'IWitnetPriceRouter' ---------------------------    

    /// Helper pure function: returns hash of the provided ERC2362-compliant currency pair caption (aka ID).
    function currencyPairId(string memory _caption)
        public pure
        virtual override
        returns (bytes32)
    {
        return keccak256(bytes(_caption));
    }

    /// Returns the ERC-165-compliant price feed contract currently serving 
    /// updates on the given currency pair.
    function getPriceFeed(bytes32 _erc2362id)
        public view
        virtual override
        returns (IERC165)
    {
        return __pairs[bytes4(_erc2362id)].pricefeed;
    }

    /// Returns human-readable ERC2362-based caption of the currency pair being
    /// served by the given price feed contract address. 
    /// @dev Fails if the given price feed contract address is not currently
    /// @dev registered in the router.
    function getPriceFeedCaption(IERC165 _pricefeed) 
        public view
        virtual override
        returns (string memory)
    {
        require(supportsPriceFeed(_pricefeed), "WitnetPriceRouter: unknown");
        return lookupERC2362ID(__pricefeedId_[address(_pricefeed)]);
    }

    /// Returns human-readable caption of the ERC2362-based currency pair identifier, if known.
    function lookupERC2362ID(bytes32 _erc2362id)
        public view
        virtual override
        returns (string memory _caption)
    {
        Pair storage _pair = __pairs[bytes4(_erc2362id)];
        if (
            bytes(_pair.base).length > 0 
                && bytes(_pair.quote).length > 0
        ) {
            _caption = string(abi.encodePacked(
                "Price-",
                _pair.base,
                "/",
                _pair.quote,
                "-",
                _pair.decimals.toString()
            ));
        }
    }

    /// Register a price feed contract that will serve updates for the given currency pair.
    /// @dev Setting zero address to a currency pair implies that it will not be served any longer.
    /// @dev Otherwise, fails if the price feed contract does not support the `IWitnetPriceFeed` interface,
    /// @dev or if given price feed is already serving another currency pair (within this WitnetPriceRouter instance).
    function setPriceFeed(
            IERC165 _pricefeed,
            uint256 _decimals,
            string calldata _base,
            string calldata _quote
        )
        public 
        virtual override
        onlyOwner
    {
        if (address(_pricefeed) != address(0)) {
            require(
                _pricefeed.supportsInterface(type(IWitnetPriceFeed).interfaceId),
                "WitnetPriceRouter: feed contract is not compliant with IWitnetPriceFeed"
            );
            require(
                __pricefeedId_[address(_pricefeed)] == bytes32(0),
                "WitnetPriceRouter: already serving a currency pair"
            );
        }
        bytes memory _caption = abi.encodePacked(
            "Price-",
            bytes(_base),
            "/",
            bytes(_quote),
            "-",
            _decimals.toString()
        );
        bytes32 _erc2362id = keccak256(_caption);
        
        Pair storage _record = __pairs[bytes4(_erc2362id)];
        address _currentPriceFeed = address(_record.pricefeed);
        if (bytes(_record.base).length == 0) {
            _record.base = _base;
            _record.quote = _quote;
            _record.decimals = _decimals;
            __supportedCurrencyPairs.push(_erc2362id);
        }
        else if (_currentPriceFeed != address(0)) {
            __pricefeedId_[_currentPriceFeed] = bytes32(0);
        }
        if (address(_pricefeed) != _currentPriceFeed) {
            __pricefeedId_[address(_pricefeed)] = _erc2362id;
        }
        _record.pricefeed = _pricefeed;
        emit CurrencyPairSet(_erc2362id, _pricefeed);
    }

    /// Returns list of known currency pairs IDs.
    function supportedCurrencyPairs()
        external view
        virtual override
        returns (bytes32[] memory)
    {
        return __supportedCurrencyPairs;
    }

    /// Returns `true` if given pair is currently being served by a compliant price feed contract.
    function supportsCurrencyPair(bytes32 _erc2362id)
        public view
        virtual override
        returns (bool)
    {
        return address(__pairs[bytes4(_erc2362id)].pricefeed) != address(0);
    }

    /// Returns `true` if given price feed contract is currently serving updates to any known currency pair. 
    function supportsPriceFeed(IERC165 _pricefeed)
        public view
        virtual override
        returns (bool)
    {
        return __pairs[bytes4(__pricefeedId_[address(_pricefeed)])].pricefeed == _pricefeed;
    }
}