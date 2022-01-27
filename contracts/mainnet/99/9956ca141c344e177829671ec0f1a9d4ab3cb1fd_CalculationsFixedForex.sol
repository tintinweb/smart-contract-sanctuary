/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

interface IFixedForexRegistry {
    function cy(address) external view returns (address);

    function price(address) external view returns (uint256);
}

interface IYearnAddressesProvider {
    function addressById(string memory) external view returns (address);
}

contract Ownable {
    address public ownerAddress;

    constructor() {
        ownerAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Ownable: caller is not the owner");
        _;
    }

    function setOwnerAddress(address _ownerAddress) public onlyOwner {
        ownerAddress = _ownerAddress;
    }
}

contract AddressesProviderConsumer is Ownable {
    address public addressesProviderAddress;

    constructor(address _addressesProviderAddress) {
        addressesProviderAddress = _addressesProviderAddress;
    }

    function setAddressesProviderAddress(address _addressesProviderAddress)
        external
        onlyOwner
    {
        addressesProviderAddress = _addressesProviderAddress;
    }

    function addressById(string memory id) internal view returns (address) {
        return
            IYearnAddressesProvider(addressesProviderAddress).addressById(id);
    }
}

contract CalculationsFixedForex is AddressesProviderConsumer {
    constructor(address _addressesProviderAddress)
        AddressesProviderConsumer(_addressesProviderAddress)
    {}

    function isFixedForex(address tokenAddress) public view returns (bool) {
        try fixedForexRegistry().cy(tokenAddress) {
            return true;
        } catch {
            return false;
        }
    }

    function fixedForexRegistry() public view returns (IFixedForexRegistry) {
        return IFixedForexRegistry(addressById("FIXED_FOREX_REGISTRY"));
    }

    function getPriceUsdc(address tokenAddress) public view returns (uint256) {
        bool _isFixedForex = isFixedForex(tokenAddress);
        require(_isFixedForex);
        return fixedForexRegistry().price(tokenAddress) / 10**12;
    }
}