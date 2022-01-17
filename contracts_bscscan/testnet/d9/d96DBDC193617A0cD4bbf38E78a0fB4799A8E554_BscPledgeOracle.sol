// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";



contract BscPledgeOracle is Ownable {

    mapping(uint256 => AggregatorV3Interface) internal assetsMap;
    mapping(uint256 => uint256) internal decimalsMap;
    mapping(uint256 => uint256) internal priceMap;
    uint256 internal decimals = 1;

    constructor() public {
//        //  bnb/USD
//        assetsMap[uint256(0x0000000000000000000000000000000000000000)] = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
//        // DAI/USD
//        assetsMap[uint256(0xf2bDB4ba16b7862A1bf0BE03CD5eE25147d7F096)] = AggregatorV3Interface(0xE4eE17114774713d2De0eC0f035d4F7665fc025D);
//        // BTC/USD
//        assetsMap[uint256(0xF592aa48875a5FDE73Ba64B527477849C73787ad)] = AggregatorV3Interface(0x5741306c21795FdCBb9b265Ea0255F499DFe515C);
//        // BUSD/USD
//        assetsMap[uint256(0xDc6dF65b2fA0322394a8af628Ad25Be7D7F413c2)] = AggregatorV3Interface(0x9331b55D9830EF609A2aBCfAc0FBCE050A52fdEa);
//
//
//        decimalsMap[uint256(0x0000000000000000000000000000000000000000)] = 18;
//        decimalsMap[uint256(0xf2bDB4ba16b7862A1bf0BE03CD5eE25147d7F096)] = 18;
//        decimalsMap[uint256(0xF592aa48875a5FDE73Ba64B527477849C73787ad)] = 18;
//        decimalsMap[uint256(0xDc6dF65b2fA0322394a8af628Ad25Be7D7F413c2)] = 18;

    }

    /**
      * @notice set the precision
      * @dev function to update precision for an asset
      * @param newDecimals replacement oldDecimal
      */
    function setDecimals(uint256 newDecimals) public onlyOwner{
        decimals = newDecimals;
    }


    /**
      * @notice Set prices in bulk
      * @dev function to update prices for an asset
      * @param prices replacement oldPrices
      */
    function setPrices(uint256[]memory assets,uint256[]memory prices) external onlyOwner {
        require(assets.length == prices.length, "input arrays' length are not equal");
        uint256 len = assets.length;
        for (uint i=0;i<len;i++){
            priceMap[i] = prices[i];
        }
    }

    /**
      * @notice retrieve prices of assets in bulk
      * @dev function to get price for an assets
      * @param  assets Asset for which to get the price
      * @return uint mantissa of asset price (scaled by 1e8) or zero if unset or contract paused
      */
    function getPrices(uint256[]memory assets) public view returns (uint256[]memory) {
        uint256 len = assets.length;
        uint256[] memory prices = new uint256[](len);
        for (uint i=0;i<len;i++){
            prices[i] = getUnderlyingPrice(assets[i]);
        }
        return prices;
    }

    /**
      * @notice retrieves price of an asset
      * @dev function to get price for an asset
      * @param asset Asset for which to get the price
      * @return uint mantissa of asset price (scaled by 1e8) or zero if unset or contract paused
      */
    function getPrice(address asset) public view returns (uint256) {
        return getUnderlyingPrice(uint256(asset));
    }

    /**
      * @notice get price based on index
      * @dev function to get price for index
      * @param underlying for which to get the price
      * @return uint mantissa of asset price (scaled by 1e8) or zero if unset or contract paused
      */
    function getUnderlyingPrice(uint256 underlying) public view returns (uint256) {
        AggregatorV3Interface assetsPrice = assetsMap[underlying];
        if (address(assetsPrice) != address(0)){
            (, int price,,,) = assetsPrice.latestRoundData();
            uint256 tokenDecimals = decimalsMap[underlying];
            if (tokenDecimals < 18){
                return uint256(price)/decimals*(10**(18-tokenDecimals));
            }else if (tokenDecimals > 18){
                return uint256(price)/decimals/(10**(18-tokenDecimals));
            }else{
                return uint256(price)/decimals;
            }
        }else {
            return priceMap[underlying];
        }
    }


    /**
      * @notice set price of an asset
      * @dev function to set price for an asset
      * @param asset Asset for which to set the price
      * @param price the Asset's price
      */
    function setPrice(address asset,uint256 price) public onlyOwner {
        priceMap[uint256(asset)] = price;
    }

    /**
      * @notice set price of an underlying
      * @dev function to set price for an underlying
      * @param underlying underlying for which to set the price
      * @param price the underlying's price
      */
    function setUnderlyingPrice(uint256 underlying,uint256 price) public onlyOwner {
        require(underlying>0 , "underlying cannot be zero");
        priceMap[underlying] = price;
    }

    /**
      * @notice set price of an asset
      * @dev function to set price for an asset
      * @param asset Asset for which to set the price
      * @param aggergator the Asset's aggergator
      */
    function setAssetsAggregator(address asset,address aggergator,uint256 _decimals) public onlyOwner {
        assetsMap[uint256(asset)] = AggregatorV3Interface(aggergator);
        decimalsMap[uint256(asset)] = _decimals;
    }

    /**
      * @notice set price of an underlying
      * @dev function to set price for an underlying
      * @param underlying underlying for which to set the price
      * @param aggergator the underlying's aggergator
      */
    function setUnderlyingAggregator(uint256 underlying,address aggergator,uint256 _decimals) public onlyOwner {
        require(underlying>0 , "underlying cannot be zero");
        assetsMap[underlying] = AggregatorV3Interface(aggergator);
        decimalsMap[underlying] = _decimals;
    }

    /** @notice get asset aggregator based on asset
      * @dev function to get aggregator for asset
      * @param asset for which to get the aggregator
      * @ return  an asset aggregator
      */
    function getAssetsAggregator(address asset) public view returns (address,uint256) {
        return (address(assetsMap[uint256(asset)]),decimalsMap[uint256(asset)]);
    }

     /**
       * @notice get asset aggregator based on index
       * @dev function to get aggregator for index
       * @param underlying for which to get the aggregator
       * @ return an asset aggregator
       */
    function getUnderlyingAggregator(uint256 underlying) public view returns (address,uint256) {
        return (address(assetsMap[underlying]),decimalsMap[underlying]);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

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