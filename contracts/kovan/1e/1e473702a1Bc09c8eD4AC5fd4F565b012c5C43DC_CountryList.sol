// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ICountryList.sol";

contract CountryList is Ownable, ICountryList {

    // disable a country code with the COUNTRY_BAN_LIST, true = banned, false = allowed
    mapping (uint16 => bool) public COUNTRY_BAN_LIST;
    uint256 public MAX_UINT = 252;

    function setMaxUint (uint16 _maxUint) external onlyOwner {
        MAX_UINT = _maxUint;
    }
    
    function setCountryRule (uint16 _countryCode, bool _banned) external onlyOwner {
        require(_countryCode <= MAX_UINT, "INVALID CODE");
        COUNTRY_BAN_LIST[_countryCode] = _banned;
    }

    // call this function from external contracts to verify if a specified country code is allowed
    function countryIsValid (uint16 _countryCode) external view override returns (bool) {
        if (_countryCode > MAX_UINT) {
            return false;
        }
        if (COUNTRY_BAN_LIST[_countryCode]) {
            return false;
        }
        return true;
    }

}