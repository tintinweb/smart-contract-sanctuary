/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

pragma solidity 0.6.7;

abstract contract OracleForUniswapLike {
    function getResultsWithValidity()
    public
    virtual
    returns (
        uint256,
        uint256,
        bool
    );
}

contract OracleLikeMock is OracleForUniswapLike {
    // Virtual redemption price (not the most updated value)
    uint256 internal _redemptionPrice; // [ray]

    // Virtual redemption price (not the most updated value)
    uint256 internal _collateralPrice; // [ray]

    constructor() public {
        _collateralPrice = 300 ether;
        _redemptionPrice = 1200000000 ether;
    }

    /**
     * @notice Fetch systemCoin and Colleteral price
     * @return systemCoinPrice Price of the system coin
     * @return collateralPrice Price of the collateral
     * @return valid True only if both values are valid
     */
    function getResultsWithValidity()
        public
        override
        returns (
            uint256 systemCoinPrice,
            uint256 collateralPrice,
            bool valid
        )
    {
        return (_redemptionPrice, _collateralPrice, true);
    }

    function setSystemCoinPrice(uint256 newValue) public {
        _redemptionPrice = newValue;
    }

    function setCollateralPrice(uint256 newValue) public {
        _collateralPrice = newValue;
    }
}