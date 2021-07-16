pragma solidity ^0.4.25;

import './TRC20.sol';
import './TRC20Detailed.sol';
import './TRC20Burnable.sol';
import './TRC20Mintable.sol';

/**
 * @title DOGE Token Contract
 * @dev Responsible for receiving the token's details at deployment
    and creating the token with the TRC20 token standard. DOGE token
    also has the burn feature
 * @author @wafflemakr
 */

contract DOGE is TRC20Burnable, TRC20Mintable{


    /**
     * @notice Token Deployment
     * @param name Name of the token (DOGE)
     * @param symbol Symbol of the token (DOGE)
     * @param decimals Amount of decimals of the token (18)
     * @param supply Max supply of the token (27 Billion)
     * @param initialOwner Address of the person that will receive
        the total supply when deploying the token
     */
    constructor
    (
        string name, string symbol,
        uint8 decimals, uint256 supply,
        address initialOwner
    )

        public TRC20Detailed(name, symbol, decimals)

    {
        mint(initialOwner, supply * (10 ** uint256(decimals)));
    }
}