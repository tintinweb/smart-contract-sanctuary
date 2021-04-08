// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract MaxCoin is ERC20, ERC20Burnable {

    address public owneraddress;
    mapping(address => bool) locked;

    constructor() ERC20("MaxCoin", "MAX") {
        owneraddress = msg.sender;
        _mint(msg.sender, 1_000_000 * (10 ** uint256(decimals())));
    }

    modifier onlyowner {
        require(owneraddress == msg.sender, "Only contract owner can call this function.");
        _;
    }

    modifier ownernottarget(address target) {
        require(owneraddress != target, "Cannot target contract owner.");
        _;
    }

    modifier notlocked(address sender) {
        require(locked[sender] != true, "Sender account is locked out.");
        _;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function mint(uint256 amount) public onlyowner {
        _mint(owneraddress, amount * (10 ** uint256(decimals())));
    }

    function transfer(address recipient, uint256 amount) public virtual override notlocked(_msgSender()) returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function lock(address target) public onlyowner ownernottarget(target) {
        locked[target] = true;
    }

    function isLocked(address queryAddress) public view returns (bool) {
        return locked[queryAddress];
    }
}