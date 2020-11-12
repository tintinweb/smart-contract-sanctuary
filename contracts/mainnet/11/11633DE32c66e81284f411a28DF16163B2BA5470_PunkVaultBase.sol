// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Pausable.sol";
import "./IPunkToken.sol";
import "./ICryptoPunksMarket.sol";

contract PunkVaultBase is Pausable {
    address private erc20Address;
    address private cpmAddress;

    IPunkToken private erc20;
    ICryptoPunksMarket private cpm;

    function getERC20Address() public view returns (address) {
        return erc20Address;
    }

    function getCpmAddress() public view returns (address) {
        return cpmAddress;
    }

    function getERC20() internal view returns (IPunkToken) {
        return erc20;
    }

    function getCPM() internal view returns (ICryptoPunksMarket) {
        return cpm;
    }

    function setERC20Address(address newAddress) internal {
        require(erc20Address == address(0), "Already initialized ERC20");
        erc20Address = newAddress;
        erc20 = IPunkToken(erc20Address);
    }

    function setCpmAddress(address newAddress) internal {
        require(cpmAddress == address(0), "Already initialized CPM");
        cpmAddress = newAddress;
        cpm = ICryptoPunksMarket(cpmAddress);
    }
}
