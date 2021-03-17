pragma solidity ^0.5.0;

import "./ERC20Burnable.sol";
import "./ERC20Detailed.sol";
import "./ERC20Mintable.sol";
import "./ERC20Pausable.sol";

contract ACUGToken is ERC20Burnable, ERC20Detailed, ERC20Mintable, ERC20Pausable {

    constructor() public
        ERC20Detailed("ACU Gold", "ACUG", 18)
    {
        _initTotalSupply(10000000 * (10 ** uint256(decimals())));
    }

    function _initTotalSupply(uint256 value) internal {
        _totalSupply = _totalSupply.add(value);
        _balances[msg.sender] = _balances[msg.sender].add(value);
        emit Transfer(address(0), msg.sender, value);
    }
}