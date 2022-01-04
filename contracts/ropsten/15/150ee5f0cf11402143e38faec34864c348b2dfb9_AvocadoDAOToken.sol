/*


*/

pragma solidity ^0.8.4;
import "./ERC20.sol";
import "./Ownable.sol";

contract AvocadoDAOToken is Ownable, ERC20 {
    constructor(string memory name_, string memory symbol_)
        Ownable()
        ERC20(name_, symbol_)
    {
        _mint(msg.sender, 1000000000);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}