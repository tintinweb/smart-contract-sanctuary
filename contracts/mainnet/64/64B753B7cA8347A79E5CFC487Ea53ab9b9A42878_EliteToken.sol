// SPDX-License-Identifier: P-P-P-PONZO!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
A combination of ERC31337, wrapped ERC20, and
GatedERC20. Wrap any ERC20, control pools, access, 
fees of any type and sweep the underlying backing
when the proper conditions are met. Optionial one
time mint in the constructor to help with set up.

Contract owner can set a new calculator or transfer
gate at any time, giving them the ability to rug 
everything in a single function. Give ownership to
Stoneface.sol as a simple safety precaution, this
adds a time delay on the transfer ownership function.
Stoneface will always give you back ownership, but 
hes always slow to respond.

*/

import "./GatedERC31337.sol";
import "./IWETH.sol";
import "./SafeMath.sol";

contract EliteToken is GatedERC31337,  IWETH
{
    using SafeMath for uint256;

    constructor (IWETH _wrappedToken)
        GatedERC31337(_wrappedToken, "Root Wrapped ETH", "KETH")
    {
        _mint(msg.sender, 2000 ether);
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