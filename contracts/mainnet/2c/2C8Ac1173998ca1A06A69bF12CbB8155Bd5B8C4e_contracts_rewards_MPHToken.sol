pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract MPHToken is ERC20, ERC20Detailed, Ownable {
    constructor() public ERC20Detailed("88mph.app", "MPH", 18) {}

    function ownerMint(address account, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        _mint(account, amount);
        return true;
    }

    function ownerTransfer(
        address from,
        address to,
        uint256 amount
    ) public onlyOwner returns (bool) {
        _transfer(from, to, amount);
        return true;
    }
}
