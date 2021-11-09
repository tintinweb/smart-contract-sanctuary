/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

pragma solidity ^0.5.0;


/**
* IPriceOracle interface
* -
* Interface for the Populous price oracle.
* -
* This contract was cloned from Populous and modified to work with the Populous World eco-system.
**/
interface IPriceOracle {
    /***********
    @dev returns the asset price in ETH
     */
    function getAssetPrice(address _asset) external view returns (uint256);

    /***********
    @dev sets the asset price, in wei
     */
    function setAssetPrice(address _asset, uint256 _price) external;

}

contract PriceOracle is IPriceOracle {

    mapping(address => uint256) prices;
    uint256 ethPriceUsd;

    event AssetPriceUpdated(address _asset, uint256 _price, uint256 timestamp);
    event EthPriceUpdated(uint256 _price, uint256 timestamp);

    function getAssetPrice(address _asset) external view returns(uint256) {
        return prices[_asset];
    }

    function setAssetPrice(address _asset, uint256 _price) external {
        prices[_asset] = _price;
        emit AssetPriceUpdated(_asset, _price, block.timestamp);
    }

    function getEthUsdPrice() external view returns(uint256) {
        return ethPriceUsd;
    }

    function setEthUsdPrice(uint256 _price) external {
        ethPriceUsd = _price;
        emit EthPriceUpdated(_price, block.timestamp);
    }
}