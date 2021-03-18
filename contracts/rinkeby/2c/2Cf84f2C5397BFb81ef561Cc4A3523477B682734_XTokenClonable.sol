// SPDX-License-Identifier: MIT
pragma solidity 0.6.8;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20BurnableUpgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";

contract XTokenClonable is OwnableUpgradeable, ERC20BurnableUpgradeable {
    function initialize(string memory name, string memory symbol)
        public
        initializer
    {
        __Ownable_init();
        __ERC20_init(name, symbol);
        __ERC20Burnable_init_unchained();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function changeName(string memory name) public onlyOwner {}

    function changeSymbol(string memory symbol) public onlyOwner {}
}