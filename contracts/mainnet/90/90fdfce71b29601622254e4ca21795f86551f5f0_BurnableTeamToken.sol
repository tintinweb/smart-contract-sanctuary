// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;


import "./TeamToken.sol";
import "./BurnableToken.sol";




contract BurnableTeamToken is TeamToken, ERC20Burnable {

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 supply,
        address owner,
        address feeWallet
    ) 
    public
    TeamToken(name, symbol, decimals, supply, owner, feeWallet) 
    {

    }
}