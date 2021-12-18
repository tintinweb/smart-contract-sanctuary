/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title ProceOracle
 * @dev Set & change price
 */
contract ProceOracle {

    mapping (address => uint256) private priceList;

    /**
     * @dev Store price in priceList
     */
    function setAssetPrice(address _asset, uint256 _price) external {
        priceList[_asset] = _price;
    }

    /**
     * @dev Return asset price 
     */
    function getAssetPrice(address _asset) public view returns(uint256) {
        return priceList[_asset];
    }

}