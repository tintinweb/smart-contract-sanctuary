// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRToken.sol";

contract ChainlinkPriceFeed is Ownable {
    struct TokenConfig {
        address rToken;
        address underlying;
        bytes32 symbolHash;
        uint256 baseUnit;
        address chainlinkPriceFeed;
    }

    uint256 public constant PRECISION = 1e18;

    mapping(address => TokenConfig) public getTokenConfigFromRToken;
    mapping(bytes32 => address) public getRTokenFromSymbolHash;
    mapping(address => address) public getRTokenFromUnderlying;

    function getUnderlyingPrice(IRToken _rToken) external view returns (uint256) {
        TokenConfig storage config = getTokenConfigFromRToken[address(_rToken)];
         // IronController needs prices in the format: ${raw price} * 1e(36 - baseUnit)
         // Since the prices in this view have 6 decimals, we must scale them by 1e(36 - 6 - baseUnit)
        return 1e18 * getFromChainlink(config.chainlinkPriceFeed) / config.baseUnit;
    }

    function setTokenConfig(
        address _rToken,
        address _underlying,
        string memory _symbol,
        uint256 _decimals,
        address _chainlinkPriceFeed
    ) external onlyOwner {
        require(getRTokenFromUnderlying[_underlying] == address(0), "RToken & underlying existed");
        require(_chainlinkPriceFeed != address(0), "!chainlink");
        bytes32 symbolHash = keccak256(abi.encodePacked(_symbol));

        TokenConfig storage _newToken = getTokenConfigFromRToken[_rToken];
        _newToken.rToken = _rToken;
        _newToken.underlying = _underlying;
        _newToken.baseUnit = 10**_decimals;
        _newToken.symbolHash = symbolHash;
        _newToken.chainlinkPriceFeed = _chainlinkPriceFeed;

        getRTokenFromUnderlying[_newToken.underlying] = _rToken;
        getRTokenFromSymbolHash[_newToken.symbolHash] = _rToken;
    }

    function price(string calldata _symbol) external view returns (uint256) {
        TokenConfig memory config = getTokenConfigBySymbol(_symbol);
        return getFromChainlink(config.chainlinkPriceFeed);
    }

    /**
     * @return price in USD with 6 decimals
     */
    function getFromChainlink(address _chainlinkPriceFeed) internal view returns (uint256) {
        assert(_chainlinkPriceFeed != address(0));
        AggregatorV3Interface _priceFeed = AggregatorV3Interface(_chainlinkPriceFeed);
        (, int256 _price, , , ) = _priceFeed.latestRoundData();
        uint8 _decimals = _priceFeed.decimals();
        return (uint256(_price) * PRECISION) / (10**_decimals);
    }

    function getTokenConfigBySymbolHash(bytes32 _symbolHash) internal view returns (TokenConfig memory) {
        address rToken = getRTokenFromSymbolHash[_symbolHash];
        require(rToken != address(0), "token config not found");
        return getTokenConfigFromRToken[rToken];
    }

    function getTokenConfigBySymbol(string memory symbol) public view returns (TokenConfig memory) {
        bytes32 symbolHash = keccak256(abi.encodePacked(symbol));
        return getTokenConfigBySymbolHash(symbolHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IRToken {
    function underlying() external returns (address);
}