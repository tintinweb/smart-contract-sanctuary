// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

contract BagToken is ERC20 {
    uint256 public initialSupply = 400000000000000;
    uint8 public decimal = 2;

    constructor() ERC20("Brawl Army Gaming", "BAG") {
        _mint(msg.sender, initialSupply);
        decimals();
    }

    function decimals() public view virtual override returns (uint8) {
        return decimal;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        uint256 transAmount = _partialBurn(amount);
        _transfer(msg.sender, recipient, transAmount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 currentAllowance = allowance(sender, msg.sender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        amount = _partialBurn(amount);

        _transfer(sender, recipient, amount);

        return true;
    }

    function _partialBurn(uint256 amount) internal returns (uint256) {
        uint256 burnable = amount / 2000;
        if (burnable > 0) _burn(msg.sender, burnable);
        return amount - burnable;
    }
}