pragma solidity ^0.5.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";

import "../interfaces/IPriceOracleGetter.sol";
import "../interfaces/IChainlinkAggregator.sol";
import "../libraries/EthAddressLib.sol";

/**
 * ChainlinkProxyPriceProvider
 * -
 *   Proxy smart contract to get the price of an asset from a price source, with Chainlink Aggregator
 *   smart contracts as primary option
 * - If the returned price by a Chainlink aggregator is <= 0, the call is forwarded to a fallbackOracle
 * - Owned by the Populous governance system, allowed to add sources for assets, replace them
 *   and change the fallbackOracle
 * -
 * This contract was cloned from Populous and modified to work with the Populous World eco-system.
 **/
contract ChainlinkProxyPriceProvider is IPriceOracleGetter, Ownable {
    event AssetSourceUpdated(address indexed asset, address indexed source);
    event FallbackOracleUpdated(address indexed fallbackOracle);

    mapping(address => IChainlinkAggregator) private assetsSources;
    IPriceOracleGetter private fallbackOracle;

    /// @notice Constructor
    /// @param _assets The addresses of the assets
    /// @param _sources The address of the source of each asset
    /// @param _fallbackOracle The address of the fallback oracle to use if the data of an
    ///        aggregator is not consistent
    constructor(
        address[] memory _assets,
        address[] memory _sources,
        address _fallbackOracle
    ) public {
        internalSetFallbackOracle(_fallbackOracle);
        internalSetAssetsSources(_assets, _sources);
    }

    /// @notice External function called by the Populous governance to set or replace sources of assets
    /// @param _assets The addresses of the assets
    /// @param _sources The address of the source of each asset
    function setAssetSources(
        address[] calldata _assets,
        address[] calldata _sources
    ) external onlyOwner {
        internalSetAssetsSources(_assets, _sources);
    }

    /// @notice Sets the fallbackOracle
    /// - Callable only by the Populous governance
    /// @param _fallbackOracle The address of the fallbackOracle
    function setFallbackOracle(address _fallbackOracle) external onlyOwner {
        internalSetFallbackOracle(_fallbackOracle);
    }

    /// @notice Internal function to set the sources for each asset
    /// @param _assets The addresses of the assets
    /// @param _sources The address of the source of each asset
    function internalSetAssetsSources(
        address[] memory _assets,
        address[] memory _sources
    ) internal {
        require(
            _assets.length == _sources.length,
            "INCONSISTENT_PARAMS_LENGTH"
        );
        for (uint256 i = 0; i < _assets.length; i++) {
            assetsSources[_assets[i]] = IChainlinkAggregator(_sources[i]);
            emit AssetSourceUpdated(_assets[i], _sources[i]);
        }
    }

    /// @notice Internal function to set the fallbackOracle
    /// @param _fallbackOracle The address of the fallbackOracle
    function internalSetFallbackOracle(address _fallbackOracle) internal {
        fallbackOracle = IPriceOracleGetter(_fallbackOracle);
        emit FallbackOracleUpdated(_fallbackOracle);
    }

    /// @notice Gets an asset price by address
    /// @param _asset The asset address
    function getAssetPrice(address _asset) public view returns (uint256) {
        IChainlinkAggregator source = assetsSources[_asset];
        if (_asset == EthAddressLib.ethAddress()) {
            return 1 ether;
        } else {
            // If there is no registered source for the asset, call the fallbackOracle
            if (address(source) == address(0)) {
                return IPriceOracleGetter(fallbackOracle).getAssetPrice(_asset);
            } else {
                int256 _price = IChainlinkAggregator(source).latestAnswer();
                if (_price > 0) {
                    return uint256(_price);
                } else {
                    return
                        IPriceOracleGetter(fallbackOracle).getAssetPrice(
                            _asset
                        );
                }
            }
        }
    }

    /// @notice Gets a list of prices from a list of assets addresses
    /// @param _assets The list of assets addresses
    function getAssetsPrices(address[] calldata _assets)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory prices = new uint256[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            prices[i] = getAssetPrice(_assets[i]);
        }
        return prices;
    }

    /// @notice Gets the address of the source for an asset address
    /// @param _asset The address of the asset
    /// @return address The address of the source
    function getSourceOfAsset(address _asset) external view returns (address) {
        return address(assetsSources[_asset]);
    }

    /// @notice Gets the address of the fallback oracle
    /// @return address The addres of the fallback oracle
    function getFallbackOracle() external view returns (address) {
        return address(fallbackOracle);
    }
}

pragma solidity ^0.5.0;

library EthAddressLib {

    /**
    * @dev returns the address used within the protocol to identify ETH
    * @return the address assigned to ETH
     */
    function ethAddress() internal pure returns(address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}

pragma solidity ^0.5.0;

/************
@title IPriceOracleGetter interface
@notice */
/**
* IPriceOracle interface
* -
* Interface for the Populous price oracle.
* -
* This contract was cloned from Populous and modified to work with the Populous World eco-system.
**/

interface IPriceOracleGetter {
    /***********
    @dev returns the asset price in ETH
     */
    function getAssetPrice(address _asset) external view returns (uint256);
}

pragma solidity ^0.5.0;

interface IChainlinkAggregator {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}