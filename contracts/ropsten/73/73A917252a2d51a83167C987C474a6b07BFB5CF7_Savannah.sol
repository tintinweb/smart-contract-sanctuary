// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import './ERC20.sol';

contract Savannah is ERC20
{
    constructor() ERC20 ('SAVANNAH','SAVANA') {
       
        _mint(msg.sender, 1000000000 * 10 ** 18);
    }
   
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
   
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}