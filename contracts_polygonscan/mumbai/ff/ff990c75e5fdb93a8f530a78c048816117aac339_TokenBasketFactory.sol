// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "TokenBasket.sol";

/**
 * @dev Contract used to create TokenBasket instances.
 */
contract TokenBasketFactory is Context {
    /**
     * @dev Emitted when TokenBasket is created under specific `tokenBasketAddress`.
     */
    event TokenBasketCreated(address tokenBasketAddress);

    /**
     * @dev Creates TokenBasket instance using all constructor parameters, transfers TokenBasket ownership to message sender and emits TokenBasketCreated event.
     */
    function createTokenBasket(string memory name_, string memory symbol_, uint8 decimals_, IERC20 [] memory holdings_, uint256 [] memory weights_) public {
        TokenBasket tokenBasket = new TokenBasket(name_, symbol_, decimals_, holdings_, weights_);
        tokenBasket.transferOwnership(_msgSender());
        emit TokenBasketCreated(address(tokenBasket));
    }
}