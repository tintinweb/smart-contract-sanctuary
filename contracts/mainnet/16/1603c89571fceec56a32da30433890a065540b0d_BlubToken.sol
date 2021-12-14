// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.7;

import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";
import "./Ownable.sol";

contract BlubToken is ERC20Burnable, ERC20Capped, Ownable {
    // admin contracts are allowed to mint
    mapping (address => bool) isAdmin;
    event SetAdmin(address indexed addr, bool value);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection
     */
    constructor() 
        ERC20Capped(50000000 * 10**18)
        ERC20("Blubber", "BLUB")
    {}

    /*
     * @dev Override _mint because we're using both ERC20Burnable and ERC20Capped
     */
    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) {
        ERC20Capped._mint(account, amount);
    }

    /*
     * @dev Mint to wallet; callable by owner
     */
    function mintOwner(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /*
     * @dev Mint to wallets; callable by owner
     */
    function mintOwnerArray(address[] calldata accounts, uint256[] calldata amounts) external onlyOwner {
        require(accounts.length == amounts.length, "Bad array lengths");
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }

    /*
     * @dev Mint to wallet; callable by admin address
     */
    function mintAdminContract(address account, uint256 amount) external {
        require(isAdmin[msg.sender], "Not authorized");
        _mint(account, amount);
    }

    /*
     * @dev Set admin value for address
     */
    function setAdmin(address addr, bool value) external onlyOwner {
        isAdmin[addr] = value;
        emit SetAdmin(addr, value);
    }
}