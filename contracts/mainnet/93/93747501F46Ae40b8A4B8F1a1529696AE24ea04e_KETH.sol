// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
Technically a wrapped WETH
So a wrapped wrapped ethereum
But also accepts raw ETH
Also functions exactly like WETH (deposit/withdraw/direct send)
*/

import "./ERC31337.sol";
import "./IWETH.sol";
import "./SafeMath.sol";

contract KETH is ERC31337, IWETH
{
    using SafeMath for uint256;

    mapping (address => bool) public freeParticipant;
    uint16 public burnRate; 

    constructor (IWETH _weth) ERC31337(_weth, "RootKit ETH", "KETH")
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

    function setFreeParticipant(address participant, bool free) public ownerOnly()
    {
        freeParticipant[participant] = free;
    }

    function setBurnRate(uint16 _burnRate) public ownerOnly()
    {
        require (_burnRate <= 2000 , "Dump tax rate should be less than or equal to 20%"); // protecting everyone from Ponzo
        
        burnRate = _burnRate;
    }
    
    function burn(uint256 amount) public
    {
        _burn(msg.sender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override 
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        if (burnRate > 0 && !freeParticipant[sender] && !freeParticipant[recipient]) {
            uint256 burnAmount = amount * burnRate / 10000;
            amount = amount.sub(burnAmount, "Burn too much");
            _burn(sender, burnAmount);
        }
        _balanceOf[sender] = _balanceOf[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balanceOf[recipient] = _balanceOf[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }
}