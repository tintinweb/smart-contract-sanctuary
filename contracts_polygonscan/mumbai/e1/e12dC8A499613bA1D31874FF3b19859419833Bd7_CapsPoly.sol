// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "../ERC20.sol";
import "../ContextMixin.sol";

contract CapsPoly is ERC20, ContextMixin {
    string public constant override name     = "pCAPS";
    string public constant override symbol   = "pCAPS";
    uint8  public constant override decimals = 18;
    address DEPOSITOR = 0xb5505a6d998549090530911180f38aC5130101c6;

    function deposit(address user, bytes calldata depositData) external {
        require(msg.sender == DEPOSITOR, "FORBIDDEN TO DEPOSIT");
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    function withdraw(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function _msgSender() internal view returns (address payable sender) {
        return ContextMixin.msgSender();
    }

}