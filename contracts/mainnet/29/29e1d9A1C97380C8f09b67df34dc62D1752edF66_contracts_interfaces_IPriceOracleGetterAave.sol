pragma solidity ^0.6.0;

/************
@title IPriceOracleGetterAave interface
@notice Interface for the Aave price oracle.*/
abstract contract IPriceOracleGetterAave {
    function getAssetPrice(address _asset) external virtual view returns (uint256);
    function getAssetsPrices(address[] calldata _assets) external virtual view returns(uint256[] memory);
    function getSourceOfAsset(address _asset) external virtual view returns(address);
    function getFallbackOracle() external virtual view returns(address);
}