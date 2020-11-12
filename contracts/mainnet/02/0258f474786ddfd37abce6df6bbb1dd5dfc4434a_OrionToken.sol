pragma solidity 0.5.10;

import "./ERC20Detailed.sol";
import "./ERC20Capped.sol";

/**
 * @title ORN Token Contract
 *
 * @author Orion Protocol
 *
 *  Address:
 *  Name:           Orion Protocol
 *  Symbol:         ORN
 *  Decimals:       8
 *  Initial Supply: 0
 *  Max Supply:     100,000,000.00000000
 *  Features:       Capped, Mintable
 *  Minters:
 *
 */
contract OrionToken is ERC20Detailed, ERC20Capped {
    constructor()
        public
        ERC20Detailed("Orion Protocol", "ORN", 8)
        ERC20Capped(100e6 * 1e8)
    {}
}
