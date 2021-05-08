/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

pragma solidity 0.5.7;

/**
 * @title OracleAdapter
 * @author Nova DAO
 *
 * Coerces outputs from Chainlink oracles to uint256 and adapts value to 18 decimals.
 */
contract OracleAdapter {
    constructor()public{}
    /* ============ External ============ */
    /*
     * Reads value of oracle and coerces return to uint256 then applies price multiplier
     *
     * @returns         Chainlink oracle price in uint256
     */
      
    function read()
        external
        view
        returns (uint256)
    {
        // fixed price
        return 1000000;
    }
}