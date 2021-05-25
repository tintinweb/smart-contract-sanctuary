// SPDX-License-Identifier: MIT

pragma solidity ^0.6.1;

import "./SafeMath.sol";
import "./Allowance.sol";

contract SharedWallet is Allowance { //Commutativity: Allowance is Ownable & SharedWallet is Allowance => SharedWallet is Ownable
    
    event MoneySent(address indexed _beneficiary, uint _amount);
    event MoneyReceived(address indexed _from, uint _amount);
    
    function withdrawMoney(address payable _to, uint _amount) public ownerOrAllowed(_amount) {
        require(_amount <= address(this).balance, "Contract doesn't have enough money");
        if(!isOwner()) {
            reduceAllowance(msg.sender, _amount);
        }
        emit MoneySent(_to, _amount);
        _to.transfer(_amount);
    }
    
    receive() external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }
    
    function renounceOwnership() public override onlyOwner {
        revert("can't renounceOwnership here");
    }
}