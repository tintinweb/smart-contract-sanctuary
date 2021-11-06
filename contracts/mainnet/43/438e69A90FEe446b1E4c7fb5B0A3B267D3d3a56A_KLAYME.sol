// File: contracts/KLAYME.sol

pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract KLAYME is ERC20, Ownable {
    uint256 private _cap;

    /**
     * Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 cap
    ) public ERC20(name, symbol) {
        require(cap > 0, "Cap is zero.");
        _cap = cap;
    }

    /**
     * Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     */
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    /**
     * Destroys `amount` tokens, reducing the cap on the token's total supply.
     */
    function burn(uint256 amount) public onlyOwner {
        require(
            totalSupply().add(amount) <= _cap,
            "Total supply exceeded cap."
        );

        _cap = _cap.sub(amount);
    }

    /**
     * Minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        // require(from.balance > amount, "not enough balance");
        if (from == address(0)) {
            // When minting tokens
            require(totalSupply().add(amount) <= _cap, "Cap exceeded.");
        }
    }
}