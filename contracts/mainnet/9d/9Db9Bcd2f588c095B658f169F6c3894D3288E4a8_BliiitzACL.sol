// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./librairies/aave/ILendingPoolAddressesProvider.sol";

contract BliiitzACL is AccessControl {

    /**
     * Use for whitelist the access from market contract
     */
    bytes32 public WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");

    address public LENDING_POOL_ADDRESS_PROVIDER;
    address public LENDING_POOL;

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Only admin address can call this function");
        _;
    }

    constructor(
        address _admin,
        address _lendingPoolAddressesProvider
    ) public {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(WHITELISTED_ROLE, msg.sender);
        _setRoleAdmin(WHITELISTED_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function setAaveConfig(address _lendingPoolAddressesProvider) public onlyAdmin returns (bool) {
        LENDING_POOL_ADDRESS_PROVIDER = _lendingPoolAddressesProvider;
        LENDING_POOL = ILendingPoolAddressesProvider(LENDING_POOL_ADDRESS_PROVIDER).getLendingPool();
    }

    /** 
     * Check if funds receiver is known
     */
    function isWhitelisted(address addr) public view returns (bool) {
        return  hasRole(DEFAULT_ADMIN_ROLE, addr) || 
                hasRole(WHITELISTED_ROLE, addr);    
    }

    /** 
     * Check if funds receiver is known
     */
    function isAdmin(address addr) public view returns (bool) {
        return  hasRole(DEFAULT_ADMIN_ROLE, addr);    
    }

}