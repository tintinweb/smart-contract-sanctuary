// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "@openzeppelin-solidity/contracts/access/Ownable.sol";
// import "@openzeppelin-solidity/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "Ownable.sol";
import "ERC20Burnable.sol";

contract ClassRegistrationToken is Ownable, ERC20Burnable {

    // constructor(address wallet) Ownable() ERC20("NFTify","N1") {
    //     _mint(wallet, (2 * (10 ** 8)) * (10 ** 18));
    //     transferOwnership(wallet);
    // }

    constructor(uint initialSupply) ERC20("ClassRegistation", "CRG") {
        _mint(msg.sender, initialSupply);
    }
}