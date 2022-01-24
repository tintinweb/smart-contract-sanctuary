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
    address public constant CHILD_CHAIN_MANAGER = 0xa34f18d9B2FC6b33D480582D2797204856076e07;
    uint256 constant FIVE_BILLIONS = 5000000000 * (10**18);

    constructor()
    public
    ChildMintableERC20("Kaka Racers World", "KARE", 18, CHILD_CHAIN_MANAGER)
    {
        _mint(CHILD_CHAIN_MANAGER, FIVE_BILLIONS);
    }

    function secondMint()
    public 
    only(DEFAULT_ADMIN_ROLE)
    secondMinter
    {
        _mint(CHILD_CHAIN_MANAGER, FIVE_BILLIONS);
    }
    
    function burn(uint256 amount)
    public 
    only(BURNER_ROLE)
    {
        _burn(_msgSender(), amount);
    }
}