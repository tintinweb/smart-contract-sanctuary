/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library AlchemyERC20Mint {
    /**
     * @dev Mint ERC20 token as owner
     * @param token The token being minted
     * @param to User receiving minted tokens.
     * @param amount Amount of token to mint
     */
    function alchemy(
        address token,
        address to,
        uint256 amount
    ) public returns (bytes memory) {
        (bool success, bytes memory result) =
            token.call(
                abi.encodeWithSignature("mint(address,uint256)", to, amount)
            );

        // Require Success
        require(success == true, "ERC20 Minting Failed");

        return result;
    }
}