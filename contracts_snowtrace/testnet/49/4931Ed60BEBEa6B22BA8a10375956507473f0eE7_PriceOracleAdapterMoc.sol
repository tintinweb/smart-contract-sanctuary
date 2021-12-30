pragma solidity ^0.5.16;

import "./PriceOracleAdapter.sol";

interface PriceProviderMoC {
    function peek() external view returns (bytes32, bool);
}

contract PriceOracleAdapterMoc is PriceOracleAdapter {
    /// @notice Address of the guardian
    address public guardian;
    /// @notice The MoC price oracle, which will continue to serve prices
    PriceProviderMoC public priceProviderMoC;

    /// @notice Guardian updated
    event NewGuardian(address oldGuardian,address newGuardian);

    /**
     * @notice Construct a PriceOracleAdapter for a MoC oracle
     * @param guardian_ address of guardian that is allowed to manage this contract
     * @param priceProvider address of asset's MoC price provider
     */
    constructor(address guardian_,address priceProvider) public {
        require(
            guardian_ != address(0),
            "PriceOracleAdapterMoc: guardian could not be 0"
        );
        require(
            priceProvider != address(0),
            "PriceOracleAdapterMoc: priceProvider could not be 0"
        );
        guardian = guardian_;
        priceProviderMoC = PriceProviderMoC(priceProvider);
    }

    /**
     * @notice Get the price from MoC and divide it by the rBTC price
     * @return The price
     */
    function assetPrices(address) public view returns (uint256) {
        (bytes32 price, bool has) = priceProviderMoC.peek();
        require(has, "PriceOracleAdapterMoc: Oracle have no Price");
        return uint256(price);
    }

    /**
     * @notice Set the address of price provider
     * @param priceProviderAddress address of price provider
     */
    function setPriceProvider(address priceProviderAddress) public {
        require(
            msg.sender == guardian,
            "PriceOracleAdapterMoc: only guardian may set the address"
        );
        require(
            priceProviderAddress != address(0),
            "PriceOracleAdapterMoc: address could not be 0"
        );
        //set old address
        address oldPriceProviderAddress = address(priceProviderMoC);
        //update interface address
        priceProviderMoC = PriceProviderMoC(priceProviderAddress);
        //emit event
        emit PriceOracleAdapterUpdated(
            oldPriceProviderAddress,
            priceProviderAddress
        );
    }

    /**
     * @notice Set the address of the guardian
     * @param newGuardian address of the guardian
     */
    function setGuardian(address newGuardian) public {
        require(
            msg.sender == guardian,
            "PriceOracleAdapterMoc: only guardian"
        );
        require(
            guardian != address(0),
            "PriceOracleAdapterMoc: guardin address can not be 0"
        );
        //set old address
        address oldGuardian = guardian;
        //update
        guardian = newGuardian;
        //emit event
        emit NewGuardian(
            oldGuardian,
            newGuardian
        );
    }
}

pragma solidity ^0.5.16;

contract PriceOracleAdapter {
    /// @notice Event adapter interface updated
    event PriceOracleAdapterUpdated(address oldAddress, address newAddress);

    /**
     * @notice Get the price
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function assetPrices(address cTokenAddress) external view returns (uint256);
}