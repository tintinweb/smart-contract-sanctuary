// SPDX-License-Identifier: Apache License, Version 2.0
pragma solidity 0.8.5;

import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./Ownable.sol";

/**
 * @dev {ERC20} token implementing the {IERC20} interface, including:
 *
 *  - Preminted initial supply of 3.25 Billion tokens allocated to owner
 *  - Ability for holders to transfer their tokens
 *  - Ability for holders to burn (destroy) their tokens
 *  - Ability for owner to pause/stop all token transfers
 *
 * This contract uses {ERC20Pausable} for pausing token transfers which is useful
 * for scenarios such as preventing trades until the end of an evaluation period,
 * or having an emergency switch for freezing all token transfers in the event of
 * a large bug or an exchange hack.
 *
 * The account that deploys the contract will be granted the allocation of the
 * preminted initial supply along with the owner role which allows it to pause
 * token transfers.
 *
 * This contract uses {ERC20Burnable} to allow token holders to destroy (burn),
 * both their own tokens and those that they have an allowance for, in a way
 * that can be recognized off-chain (via event analysis).
 *
 * The inherited ERC20 contract includes the OpenZeppelin non-standard 
 * {decreaseAllowance} and {increaseAllowance} functions as alternatives to the 
 * standard {approve} function.
 *
 * The inherited contracts follows general OpenZeppelin guidelines: functions 
 * revert instead of returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20 applications.
 */
contract DrifeToken is ERC20Burnable, ERC20Pausable, Ownable {
    /**
     * @dev Mints an initial supply of 3.25 Billion DRF tokens with 18 decimals and
     * transfers them to deploying address which is also made the contract `owner`.
     *
     * See {ERC20-constructor}.
     */
    constructor() ERC20("Drife", "DRF") {
        _mint(_msgSender(), 3.25 * 10**9 * 10**18);
    }

    /**
     * @dev Toggles between paused <-> unpaused states to disallow <-> allow
     * token transfers.
     *
     * See {ERC20Pausable} - {Pausable-paused()}, {Pausable-_pause()} and 
     * {Pausable-_unpause()}.
     *
     * Requirements:
     *
     * - the caller must have `owner` priviledges.
     */
    function togglePause() public onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /**
     * @dev Overridden hook that is called before any transfer of tokens,
     * including minting and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}