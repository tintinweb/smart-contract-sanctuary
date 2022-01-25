pragma solidity 0.5.10;

import "./ERC20Detailed.sol";
import "./ERC20Capped.sol";

/**
 * @title Depo Token Contract
 *
 * @author Depo ORN
 *
 *  Address:
 *  Name:           Depo ORN
 *  Symbol:         DEPO
 *  Decimals:       8
 *  Initial Supply: 0
 *  Max Supply:     100,000,000.00000000
 *  Features:       Capped, Mintable
 *  Minters:
 *
 */
contract DepoToken is ERC20Detailed, ERC20Capped {
    constructor()
        public
        ERC20Detailed("Depo ORN", "DEPO", 8)
        ERC20Capped(100e6 * 1e8)
    {}
}