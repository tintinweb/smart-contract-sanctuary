/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;



// Part: AddressProviderInterface

interface AddressProviderInterface {
    function getAddress() external view returns (address);
}

// File: CryptoTraderTokenUriAddressProvider.sol

/**
 * This contract exposes a method to retrieve the current address for the
 * CryptoTokenUriProvider contract
 */
contract CryptoTraderTokenUriAddressProvider is AddressProviderInterface {
    address owner;
    address cryptoTraderTokenUriProviderAddress;

    constructor(address _cryptoTraderTokenUriProviderAddress) public {
        owner = msg.sender;
        cryptoTraderTokenUriProviderAddress = _cryptoTraderTokenUriProviderAddress;
    }

    /**
     * Returns the address for the CryptoTraderTokenUriProvider contract
     */
    function getAddress() external view override returns (address) {
        return cryptoTraderTokenUriProviderAddress;
    }

    /**
     * Set the address for the CryptoTraderTokenUriProvider contract
     */
    function setAddress(address _newAddress) public {
        require(
            msg.sender == owner,
            "ONLY contract owner may call this method."
        );

        cryptoTraderTokenUriProviderAddress = _newAddress;
    }
}