// contracts/ExampleToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract ExampleToken is ERC20, Ownable {

    constructor ()

    ERC20("ExampleToken", "EGT-01")
    {
        _mint(
            msg.sender,
            10000 * 10 ** decimals()
        );
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }

}