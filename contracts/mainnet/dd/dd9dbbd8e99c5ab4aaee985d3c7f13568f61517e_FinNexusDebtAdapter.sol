// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

/**
 * @title Protocol adapter interface.
 * @dev adapterType(), tokenType(), and getBalance() functions MUST be implemented.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
interface ProtocolAdapter {

    /**
     * @dev MUST return "Asset" or "Debt".
     * SHOULD be implemented by the public constant state variable.
     */
    function adapterType() external pure returns (string memory);

    /**
     * @dev MUST return token type (default is "ERC20").
     * SHOULD be implemented by the public constant state variable.
     */
    function tokenType() external pure returns (string memory);

    /**
     * @dev MUST return amount of the given token locked on the protocol by the given account.
     */
    function getBalance(address token, address account) external view returns (uint256);
}



/**
 * @dev FinNexusCollecteralPool contract interface.
 */
interface FinNexusCollecteralPool {
    function getUserInputCollateral(address user,address collateral) external view returns (uint256);
}


/**
 * @title Asset adapter for FinNexus option protocol.
 * @dev Implementation of ProtocolAdapter interface.
 * @author jeffqg123 <forestjqg@163.com>
 */
contract FinNexusDebtAdapter is ProtocolAdapter {

    string public constant override adapterType = "Debt";
    string public constant override tokenType = "ERC20";

    address public constant CollecteralPool = 0x20081862B301C1ef9357BC0a125Aa414db210f2c;
    address internal constant FNX = 0xeF9Cd7882c067686691B6fF49e650b43AFBBCC6B;
    address internal constant FNX_ETH = 0x0000000000000000000000000000000000000000;
    address internal constant USDC= 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @return Amount of FNX/USDC/FNX locked on the protocol by the given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        if (token==FNX || token==ETH || token==USDC) {
            return FinNexusCollecteralPool(CollecteralPool).getUserInputCollateral(account,token==ETH?FNX_ETH:token);
        } else {
            return 0;
        }
    }
}