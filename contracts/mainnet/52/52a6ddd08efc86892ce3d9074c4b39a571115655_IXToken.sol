// SPDX-License-Identifier: MIT

import "./IERC20.sol";

pragma solidity 0.6.8;

interface IXToken is IERC20 {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function changeName(string calldata name) external;

    function changeSymbol(string calldata symbol) external;

    function setVaultAddress(address vaultAddress) external;
}
