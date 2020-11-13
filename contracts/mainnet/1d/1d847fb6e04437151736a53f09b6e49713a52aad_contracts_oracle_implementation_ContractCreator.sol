pragma solidity ^0.6.0;

import "../interfaces/FinderInterface.sol";
import "../../common/implementation/AddressWhitelist.sol";
import "./Registry.sol";
import "./Constants.sol";


/**
 * @title Base contract for all financial contract creators
 */
abstract contract ContractCreator {
    address internal finderAddress;

    constructor(address _finderAddress) public {
        finderAddress = _finderAddress;
    }

    function _requireWhitelistedCollateral(address collateralAddress) internal view {
        FinderInterface finder = FinderInterface(finderAddress);
        AddressWhitelist collateralWhitelist = AddressWhitelist(
            finder.getImplementationAddress(OracleInterfaces.CollateralWhitelist)
        );
        require(collateralWhitelist.isOnWhitelist(collateralAddress), "Collateral not whitelisted");
    }

    function _registerContract(address[] memory parties, address contractToRegister) internal {
        FinderInterface finder = FinderInterface(finderAddress);
        Registry registry = Registry(finder.getImplementationAddress(OracleInterfaces.Registry));
        registry.registerContract(parties, contractToRegister);
    }
}
