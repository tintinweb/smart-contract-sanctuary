// SPDX-License-Identifier: MIT
import "./ProxyRegistry.sol";
import "./ERC20.sol";

pragma solidity ^0.8.0;

contract TokenTransferProxy {

    /* Authentication registry. */
    ProxyRegistry public registry;

    /**
     * Call ERC20 `transferFrom`
     *
     * @dev Authenticated contract only
     * @param token ERC20 token address
     * @param from From address
     * @param to To address
     * @param amount Transfer amount
     */
    function transferFrom(address token, address from, address to, uint amount)
    public
    returns (bool)
    {
        require(registry.contracts(msg.sender));
        return ERC20(token).transferFrom(from, to, amount);
    }

}