// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import './ERC20.sol';

contract WAVU is ERC20
{
    constructor() ERC20 ('WAVU','WAVU') {
       
        _mint(0x9841E4058Ea7ca031fb1e4D0d5Cd860BDE8409Fe, 2000000000 * 10 ** 18);
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