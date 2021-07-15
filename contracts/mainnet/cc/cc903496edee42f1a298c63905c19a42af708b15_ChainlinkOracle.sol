/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// SPDX-License-Identifier:  AGPL-3.0-or-later // hevm: flattened sources of contracts/oracles/ChainlinkOracle.sol
pragma solidity =0.6.11 >=0.6.0 <0.8.0;

////// contracts/interfaces/IMapleGlobals.sol
/* pragma solidity 0.6.11; */

interface IMapleGlobals {

    function pendingGovernor() external view returns (address);

    function governor() external view returns (address);

    function globalAdmin() external view returns (address);

    function mpl() external view returns (address);

    function mapleTreasury() external view returns (address);

    function isValidBalancerPool(address) external view returns (bool);

    function treasuryFee() external view returns (uint256);

    function investorFee() external view returns (uint256);

    function defaultGracePeriod() external view returns (uint256);

    function fundingPeriod() external view returns (uint256);

    function swapOutRequired() external view returns (uint256);

    function isValidLiquidityAsset(address) external view returns (bool);

    function isValidCollateralAsset(address) external view returns (bool);

    function isValidPoolDelegate(address) external view returns (bool);

    function validCalcs(address) external view returns (bool);

    function isValidCalc(address, uint8) external view returns (bool);

    function getLpCooldownParams() external view returns (uint256, uint256);

    function isValidLoanFactory(address) external view returns (bool);

    function isValidSubFactory(address, address, uint8) external view returns (bool);

    function isValidPoolFactory(address) external view returns (bool);
    
    function getLatestPrice(address) external view returns (uint256);
    
    function defaultUniswapPath(address, address) external view returns (address);

    function minLoanEquity() external view returns (uint256);
    
    function maxSwapSlippage() external view returns (uint256);

    function protocolPaused() external view returns (bool);

    function stakerCooldownPeriod() external view returns (uint256);

    function lpCooldownPeriod() external view returns (uint256);

    function stakerUnstakeWindow() external view returns (uint256);

    function lpWithdrawWindow() external view returns (uint256);

    function oracleFor(address) external view returns (address);

    function validSubFactories(address, address) external view returns (bool);

    function setStakerCooldownPeriod(uint256) external;

    function setLpCooldownPeriod(uint256) external;

    function setStakerUnstakeWindow(uint256) external;

    function setLpWithdrawWindow(uint256) external;

    function setMaxSwapSlippage(uint256) external;

    function setGlobalAdmin(address) external;

    function setValidBalancerPool(address, bool) external;

    function setProtocolPause(bool) external;

    function setValidPoolFactory(address, bool) external;

    function setValidLoanFactory(address, bool) external;

    function setValidSubFactory(address, address, bool) external;

    function setDefaultUniswapPath(address, address, address) external;

    function setPoolDelegateAllowlist(address, bool) external;

    function setCollateralAsset(address, bool) external;

    function setLiquidityAsset(address, bool) external;

    function setCalc(address, bool) external;

    function setInvestorFee(uint256) external;

    function setTreasuryFee(uint256) external;

    function setMapleTreasury(address) external;

    function setDefaultGracePeriod(uint256) external;

    function setMinLoanEquity(uint256) external;

    function setFundingPeriod(uint256) external;

    function setSwapOutRequired(uint256) external;

    function setPriceOracle(address, address) external;

    function setPendingGovernor(address) external;

    function acceptGovernor() external;

}

////// contracts/oracles/IChainlinkAggregatorV3.sol
/* pragma solidity 0.6.11; */

interface IChainlinkAggregatorV3 {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values,
  // which could be misinterpreted as actual reported values.
  
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80  roundId,
        int256  answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80  answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
        uint80  roundId,
        int256  answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80  answeredInRound
    );

}

////// lib/openzeppelin-contracts/contracts/GSN/Context.sol
/* pragma solidity >=0.6.0 <0.8.0; */

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol
/* pragma solidity >=0.6.0 <0.8.0; */

/* import "../GSN/Context.sol"; */
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

////// contracts/oracles/ChainlinkOracle.sol
/* pragma solidity 0.6.11; */

/* import "./IChainlinkAggregatorV3.sol"; */
/* import "../interfaces/IMapleGlobals.sol"; */
/* import "lib/openzeppelin-contracts/contracts/access/Ownable.sol"; */

/// @title ChainlinkOracle is a wrapper contract for Chainlink oracle price feeds that allows for manual price feed overrides.
contract ChainlinkOracle is Ownable {

    IChainlinkAggregatorV3 public priceFeed;
    IMapleGlobals public globals;

    address public immutable assetAddress;

    bool   public manualOverride;
    int256 public manualPrice;

    event ChangeAggregatorFeed(address _newMedianizer, address _oldMedianizer);
    event       SetManualPrice(int256 _oldPrice, int256 _newPrice);
    event    SetManualOverride(bool _override);

    /**
        @dev   Creates a new Chainlink based oracle.
        @param _aggregator   Address of Chainlink aggregator.
        @param _assetAddress Address of currency (0x0 for ETH).
        @param _owner        Address of the owner of the contract.
    */
    constructor(address _aggregator, address _assetAddress, address _owner) public {
        require(_aggregator != address(0), "CO:ZERO_AGGREGATOR_ADDR");
        priceFeed       = IChainlinkAggregatorV3(_aggregator);
        assetAddress    = _assetAddress;
        transferOwnership(_owner);
    }

    /**
        @dev    Returns the latest price.
        @return price The latest price.
    */
    function getLatestPrice() public view returns (int256) {
        if (manualOverride) return manualPrice;
        (uint80 roundID, int256 price,,uint256 timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();

        require(timeStamp != 0,             "CO:ROUND_NOT_COMPLETE");
        require(answeredInRound >= roundID,         "CO:STALE_DATA");
        require(price != int256(0),                 "CO:ZERO_PRICE");
        return price;
    }


    /**
        @dev   Updates aggregator address. Only the contract Owner can call this function.
        @dev   It emits a `ChangeAggregatorFeed` event.
        @param aggregator Address of Chainlink aggregator.
    */
    function changeAggregator(address aggregator) external onlyOwner {
        require(aggregator != address(0), "CO:ZERO_AGGREGATOR_ADDR");
        emit ChangeAggregatorFeed(aggregator, address(priceFeed));
        priceFeed = IChainlinkAggregatorV3(aggregator);
    }

    /**
        @dev Returns address of oracle currency (0x0 for ETH).
    */
    function getAssetAddress() external view returns (address) {
        return assetAddress;
    }

    /**
        @dev Returns denomination of price.
    */
    function getDenomination() external pure returns (bytes32) {
        // All Chainlink oracles are denominated in USD.
        return bytes32("USD");
    }

    /**
        @dev   Sets a manual price. Only the contract Owner can call this function.
               NOTE: this can only be used if manualOverride == true.
        @dev   It emits a `SetManualPrice` event.
        @param _price Price to set.
    */
    function setManualPrice(int256 _price) public onlyOwner {
        require(manualOverride, "CO:MANUAL_OVERRIDE_NOT_ACTIVE");
        emit SetManualPrice(manualPrice, _price);
        manualPrice = _price;
    }

    /**
        @dev   Sets manual override, allowing for manual price setting. Only the contract Owner can call this function.
        @dev   It emits a `SetManualOverride` event.
        @param _override Whether to use the manual override price or not.
    */
    function setManualOverride(bool _override) public onlyOwner {
        manualOverride = _override;
        emit SetManualOverride(_override);
    }

}