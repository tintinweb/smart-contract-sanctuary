pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

contract ERC20Mock is ERC20, ERC20Detailed("", "", 6) {
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}