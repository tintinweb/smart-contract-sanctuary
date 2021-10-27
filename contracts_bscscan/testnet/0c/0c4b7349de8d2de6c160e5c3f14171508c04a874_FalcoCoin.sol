// SPDX-License-Identifier: UNLICENSED


// Website: https://falco.cash/
// Telegram: https://t.me/FalcoCoin
// Twitter: https://twitter.com/FalcoCoin


// Symbol        : FALCO
// Name          : FalcoCoin
// Total supply  : 100 000 000
// Decimals      : 9


pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";
import "./ERC20Decimals.sol";
import "./ERC20Mintable.sol";
import "./ERC20Ownable.sol";
import "./Kreator.sol";
import "./TokenRecover.sol";


contract FalcoCoin is
    ERC20Decimals,
    ERC20Capped,
    ERC20Mintable,
    ERC20Burnable,
    ERC20Ownable,
    TokenRecover,
    Kreator
{
    constructor(
        address __kreator_target,
        string memory __kreator_name,
        string memory __kreator_symbol,
        uint8 __kreator_decimals,
        uint256 __kreator_cap,
        uint256 __kreator_initial
    )
        payable
        ERC20(__kreator_name, __kreator_symbol)
        ERC20Decimals(__kreator_decimals)
        ERC20Capped(__kreator_cap)
        Kreator("FalcoCoin", __kreator_target)
    {
        require(__kreator_initial <= __kreator_cap, "ERC20Capped: cap exceeded");
        ERC20._mint(_msgSender(), __kreator_initial);
    }

    function decimals() public view virtual override(ERC20, ERC20Decimals) returns (uint8) {
        return super.decimals();
    }

    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) onlyOwner {
        super._mint(account, amount);
    }

    function _finishMinting() internal override onlyOwner {
        super._finishMinting();
    }
}