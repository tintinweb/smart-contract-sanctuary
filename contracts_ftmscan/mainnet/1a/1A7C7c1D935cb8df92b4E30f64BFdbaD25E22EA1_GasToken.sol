// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";

contract GasToken is Ownable, ERC20Burnable, Pausable {
    constructor() ERC20("Meta Cars Land - Fuel", "GAS") {}

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}