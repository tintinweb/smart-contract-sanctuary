pragma solidity ^0.6.0;
 
import "./Context.sol";
import "./ERC20.sol";
 
contract ERC20Burnable is Context, ERC20 {
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
 
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");
 
        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}