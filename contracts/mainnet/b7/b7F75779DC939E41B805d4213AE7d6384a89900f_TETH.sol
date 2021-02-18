// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

/* Originally for ROOTKIT:
When KETH is trapped
You take the WETH back
Technically a wrapped WETH
So a wrapped wrapped ethereum
But also accepts raw ETH
Also functions exactly like WETH (deposit/withdraw/direct send)
*/

import "./ERC31337.sol";
import "./IWETH.sol";
import "./SafeMath.sol";

contract TETH is ERC31337, IWETH
{
    using SafeMath for uint256;

    constructor (IWETH _weth)
        ERC31337(_weth, "tETH", "tETH")
    {
    }

    receive() external payable
    {
        if (msg.sender != address(wrappedToken)) {
            deposit();
        }
    }

    function deposit() public payable override
    {
        uint256 amount = msg.value;
        IWETH(address(wrappedToken)).deposit{ value: amount }();
        _mint(msg.sender, amount);
        emit Deposit(msg.sender, amount); 
    }

    function withdraw(uint256 _amount) public override
    {
        _burn(msg.sender, _amount);
        IWETH(address(wrappedToken)).withdraw(_amount);
        emit Withdrawal(msg.sender, _amount);
        (bool success,) = msg.sender.call{ value: _amount }("");
        require (success, "Transfer failed");
    }
}