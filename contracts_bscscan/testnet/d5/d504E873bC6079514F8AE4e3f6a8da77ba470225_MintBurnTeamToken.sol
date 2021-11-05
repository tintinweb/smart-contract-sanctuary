// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;


import "./Ownable.sol";
import "./TeamToken.sol";
import "./BurnableToken.sol";

contract MintBurnTeamToken is TeamToken, ERC20Burnable, Ownable {
    constructor(
        string memory name,
        string memory symbol
    ) 
    public
    TeamToken(name, symbol, 9, 1000000000 * 10 ** 9, msg.sender, msg.sender) 
    {

    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}