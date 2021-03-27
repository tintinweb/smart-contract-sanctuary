/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File contracts/oracle/IPriceConsumerV3.sol

pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

abstract contract IPriceConsumerV3 {
    function getLatestPrice() public view virtual returns (int256);
}


// File contracts/mock/MockSettablePriceConsumerV3.sol

pragma solidity ^0.6.2;

contract MockSettablePriceConsumerV3 is IPriceConsumerV3 {
    int256 internal _price;

    function set(int256 price) external {
        _price = price;
    }

    function getLatestPrice() public view override returns (int256 price) {
        return _price;
    }
}