// SPDX-License-Identifier: MIT

pragma solidity ^0.6.1;

import "./Ownable.sol";
import "./SafeMath.sol";

contract Allowance is Ownable {
    
    using SafeMath for uint;
    
    event AllowanceChanged(address indexed _forWho, address indexed _byWhom, uint _oldAmount, uint _newAmount);
    mapping(address => uint) public allowance;
    
    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }

    
    function setAllowance(address _who, uint _amount) public onlyOwner {
        emit AllowanceChanged(_who, msg.sender, allowance[_who], _amount);
        allowance[_who] = _amount;
    }
    
    modifier ownerOrAllowed(uint _amount) {
        require(isOwner() || allowance[msg.sender] >= _amount, "You are not allowed!");
        _;
    }
    
    function reduceAllowance(address _who, uint _amount) internal ownerOrAllowed(_amount) {
        emit AllowanceChanged(_who, msg.sender, allowance[_who], allowance[_who] - _amount);
        allowance[_who] -= _amount;
    }
    
    function renounceOwnership() public override virtual onlyOwner {
        revert("can't renounceOwnership here");
    }
}