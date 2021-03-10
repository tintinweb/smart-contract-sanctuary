// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;
import "./ERC20Upgradeable.sol";

contract Coldstack is ERC20Upgradeable {

     function initialize() initializer public {
         __ERC20_init("Coldstack", "CLS");
         uint256 totalSupply = 50000000 * (10 ** 18);
         _mint(_msgSender(), totalSupply);
     }
}