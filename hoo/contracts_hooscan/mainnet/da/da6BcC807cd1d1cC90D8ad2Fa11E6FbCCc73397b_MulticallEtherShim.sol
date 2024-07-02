// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @author sirbeefalot
 * @dev designed to manage ether whitin other BEP20 tokens while using a multicall contract.
 */
contract MulticallEtherShim {
    /**
     * @dev Returns an account's ether balance following a ERC20 call interface.
     */
    function balanceOf(address _address) external view returns (uint256) {
        return _address.balance;
    }

    /**
     * @dev Allowance is not required for ether transfers. It returns a large number to make the UI work.
     */
    function allowance(address, address) external pure returns (uint256) {
        return type(uint256).max;
    }
}