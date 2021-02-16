// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

import "ERC20.sol";
import "Ownable.sol";
import "Initializable.sol";
import "IIdeaToken.sol";

/**
 * @title IdeaToken
 * @author Alexander Schlindwein
 *
 * IdeaTokens are implementations of the ERC20 interface
 * They can be burned and minted by the owner of the contract instance which is the IdeaTokenExchange
 *
 * New instances are created using a MinimalProxy
 */
contract IdeaToken is IIdeaToken, ERC20, Ownable, Initializable {

    /**
     * Constructs an IdeaToken with 18 decimals
     * The constructor is called by the IdeaTokenFactory when a new token is listed
     * The owner of the contract is set to msg.sender
     *
     * @param __name The name of the token. IdeaTokenFactory will prefix the market name
     * @param owner The owner of this contract, IdeaTokenExchange
     */
    function initialize(string calldata __name, address owner) external override initializer {
        setOwnerInternal(owner);
        _decimals = 18;
        _symbol = "IDT";
        _name = __name;
    }

    /**
     * Mints a given amount of tokens to an address
     * May only be called by the owner
     *
     * @param account The address to receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address account, uint256 amount) external override onlyOwner {
        _mint(account, amount);
    }

    /**
     * Burns a given amount of tokens from an address.
     * May only be called by the owner
     *
     * @param account The address for the tokens to be burned from
     * @param amount The amount of tokens to be burned
     */
    function burn(address account, uint256 amount) external override onlyOwner {
        _burn(account, amount);
    }
}