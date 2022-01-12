// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "./ChildMintableERC20.sol";

contract SecondMintable {
    bool secondMinted = false;

    modifier secondMinter() {
        require(!secondMinted, "Already second minted");
        _;
        secondMinted = true;
    }
}

contract LifeToken is ChildMintableERC20, SecondMintable
{

    constructor()
    public
    ChildMintableERC20("Kaka Racers World", "KARE", 18, 0xa34f18d9B2FC6b33D480582D2797204856076e07)
    {
        _mint(0xa34f18d9B2FC6b33D480582D2797204856076e07, 5000000000 * (10**18));
    }

    function secondMint()
    public 
    only(DEFAULT_ADMIN_ROLE)
    secondMinter
    {
        _mint(0xa34f18d9B2FC6b33D480582D2797204856076e07, 5000000000 * (10**18));
    }
}