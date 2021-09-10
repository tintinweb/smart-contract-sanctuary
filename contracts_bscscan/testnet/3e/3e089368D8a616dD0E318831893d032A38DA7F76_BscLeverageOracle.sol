/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

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




// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


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







pragma solidity ^0.6.7;

contract BscLeverageOracle is Ownable {

    mapping(uint256 => AggregatorV3Interface) internal assetsMap;
    mapping(uint256 => uint256) internal decimalsMap;
    mapping(uint256 => uint256) internal priceMap;
    uint256 internal decimals = 1;

    constructor() public {
//        assetsMap[1] = AggregatorV3Interface(0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf);  // BTC/USD
//        assetsMap[2] = AggregatorV3Interface(0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e);  // ETH/USD
//        assetsMap[6] = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);  //bnb  BNB/ USD
//        assetsMap[0] = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);  //bnb  BNB/ USD
//        //wbtc
//        assetsMap[uint256(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c)] = AggregatorV3Interface(0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf);  // BTC/USD
//        //weth
//        assetsMap[uint256(0x2170Ed0880ac9A755fd29B2688956BD959F933F8)] = AggregatorV3Interface(0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e);  // ETH/USD
//        // BUSD
//        assetsMap[uint256(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56)] = AggregatorV3Interface(0xcBb98864Ef56E9042e7d2efef76141f15731B82f);   //busd/USD
//        // USDT
//        assetsMap[uint256(0x55d398326f99059fF775485246999027B3197955)] = AggregatorV3Interface(0xB97Ad0E74fa7d920791E90258A6E2085088b4320);//usdt
//        // USDC
//        assetsMap[uint256(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d)] = AggregatorV3Interface(0x51597f405303C4377E36123cBc172b13269EA163);//usdc
//
//        priceMap[uint256(0xac86e5f9bA48d680516df50C72928c2ec50F3025)] = 1e7;
//
//        decimalsMap[0] = 18;
//        decimalsMap[1] = 18;
//        decimalsMap[2] = 18;
//        decimalsMap[6] = 18;
//        decimalsMap[uint256(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56)] = 18;
//        decimalsMap[uint256(0x55d398326f99059fF775485246999027B3197955)] = 18;
//        decimalsMap[uint256(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d)] = 18;
//        decimalsMap[uint256(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c)] = 18;
//        decimalsMap[uint256(0x2170Ed0880ac9A755fd29B2688956BD959F933F8)] = 18;
//        decimalsMap[uint256(0xac86e5f9bA48d680516df50C72928c2ec50F3025)] = 18;
        // bsc test
        assetsMap[1] = AggregatorV3Interface(0x5741306c21795FdCBb9b265Ea0255F499DFe515C);  // BTC/USD
        assetsMap[2] = AggregatorV3Interface(0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7);  // ETH/USD
        assetsMap[6] = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);  //bnb  BNB/ USD
        assetsMap[0] = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);  //bnb  BNB/ USD
        //wbtc TODO : 测试环境自己发行该币种
        assetsMap[uint256(0x063b90F189114d7fa9C3a0F87485370a3f5DdE6C)] = AggregatorV3Interface(0x5741306c21795FdCBb9b265Ea0255F499DFe515C);  // BTC/USD
        //weth
        assetsMap[uint256(0x8DEe35a222a10D1bCAe14E8cae00E87FAfFfD549)] = AggregatorV3Interface(0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7);  // ETH/USD
        // BUSD
        assetsMap[uint256(0x406553445021Ff992341E951CF98a1b66860a0e9)] = AggregatorV3Interface(0xcBb98864Ef56E9042e7d2efef76141f15731B82f);   //busd/USD
        // USDT
        assetsMap[uint256(0x7948C9E5B95a5C9d4C1bC3600a7cdf7af59B809c)] = AggregatorV3Interface(0xB97Ad0E74fa7d920791E90258A6E2085088b4320);//usdt/USD
        // USDC
        assetsMap[uint256(0xdD4Ce2056C5f8EFAC2aca646302d734e7CCD586A)] = AggregatorV3Interface(0x90c069C4538adAc136E051052E14c1cD799C41B7);//usdc/USD

//        priceMap[uint256(0xac86e5f9bA48d680516df50C72928c2ec50F3025)] = 1e7;

        decimalsMap[0] = 18;
        decimalsMap[1] = 18;
        decimalsMap[2] = 18;
        decimalsMap[6] = 18;
        decimalsMap[uint256(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56)] = 18;
        decimalsMap[uint256(0x55d398326f99059fF775485246999027B3197955)] = 18;
        decimalsMap[uint256(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d)] = 18;
        decimalsMap[uint256(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c)] = 18;
        decimalsMap[uint256(0x2170Ed0880ac9A755fd29B2688956BD959F933F8)] = 18;
        decimalsMap[uint256(0xac86e5f9bA48d680516df50C72928c2ec50F3025)] = 18;
    }


    function setDecimals(uint256 newDecimals) public onlyOwner{
        decimals = newDecimals;
    }

    function getAssetAndUnderlyingPrice(address asset,uint256 underlying) public view returns (uint256,uint256) {
        return (getUnderlyingPrice(uint256(asset)),getUnderlyingPrice(underlying));
    }

    function setPrices(uint256[]memory assets,uint256[]memory prices) public onlyOwner {
        require(assets.length == prices.length, "input arrays' length are not equal");
        uint256 len = assets.length;
        for (uint i=0;i<len;i++){
            priceMap[i] = prices[i];
        }
    }

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

    function getUnderlyingPrice(uint256 underlying) public view returns (uint256) {
        if (underlying == 3){
            return getMKRPrice();
        }
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

    function getMKRPrice() internal view returns (uint256) {
        AggregatorV3Interface assetsPrice = assetsMap[3];
        AggregatorV3Interface ethPriceAggregate = assetsMap[0];
        if (address(assetsPrice) != address(0) && address(ethPriceAggregate) != address(0)){
            (, int price,,,) = assetsPrice.latestRoundData();
            (, int ethPrice,,,) = ethPriceAggregate.latestRoundData();
            uint256 tokenDecimals = decimalsMap[3];
            uint256 mkrPrice = uint256(price*ethPrice)/decimals/1e18;
            if (tokenDecimals < 18){
                return mkrPrice/decimals*(10**(18-tokenDecimals));
            }else if (tokenDecimals > 18){
                return mkrPrice/decimals/(10**(18-tokenDecimals));
            }else{
                return mkrPrice/decimals;
            }
        }else {
            return priceMap[3];
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

    function getAssetsAggregator(address asset) public view returns (address,uint256) {
        return (address(assetsMap[uint256(asset)]),decimalsMap[uint256(asset)]);
    }

    function getUnderlyingAggregator(uint256 underlying) public view returns (address,uint256) {
        return (address(assetsMap[underlying]),decimalsMap[underlying]);
    }

}