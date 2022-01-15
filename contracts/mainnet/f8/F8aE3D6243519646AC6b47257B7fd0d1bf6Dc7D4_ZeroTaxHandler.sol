// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ITaxHandler.sol";

/**
 * @title Zero tax handler contract
 * @dev This contract should only be used by protocols that collect taxes on certain transactions and want to set it to
 * zero.
 */
contract ZeroTaxHandler is ITaxHandler {
    /**
     * @notice Get taxed tokens for transfers. This method always returns zero.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     * @return Number of tokens to pay as tax. This is statically set to zero.
     */
    function getTax(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external pure override returns (uint256) {
        // Silence a few warnings. This will be optimized out by the compiler.
        benefactor;
        beneficiary;
        amount;

        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @title Tax handler interface
 * @dev Any class that implements this interface can be used for protocol-specific tax calculations.
 */
interface ITaxHandler {
    /**
     * @notice Get number of tokens to pay as tax.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     * @return Number of tokens to pay as tax.
     */
    function getTax(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external view returns (uint256);
}