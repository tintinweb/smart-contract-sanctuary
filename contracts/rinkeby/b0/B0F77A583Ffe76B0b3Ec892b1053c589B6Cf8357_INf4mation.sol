// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./ERC20PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

// mock class using ERC20
contract INf4mation is OwnableUpgradeable, ERC20PausableUpgradeable {

    uint256 private _cap;

    function __INf4mation_init(
        string memory name,
        string memory symbol,
        uint256 cap_
    ) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained(); 
        __ERC20_init_unchained(name, symbol);
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
        _cap = cap_;
    }

    /**
     * @dev Triggers stopped state.
     * @dev This function can only be called by the owner of the contract.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */

    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     * @dev This function can only be called by the owner of the contract.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Mint `amount` tokens to `account`.
     * @dev This function can only be called by the owner of the contract.
     */
    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
        require(totalSupply() + amount <= cap(), "INFormation: cap exceeded");
        _mint(account, amount);
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     */

    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }
   
    function cap() public view returns (uint256) {
        return _cap;
    }

}