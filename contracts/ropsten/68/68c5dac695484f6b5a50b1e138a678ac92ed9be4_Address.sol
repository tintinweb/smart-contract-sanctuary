/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

pragma solidity ^0.4.23;

contract Address {

    mapping(address => uint256) balances;
    
    uint256 totalSupply_;
    address owner_;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Burn(address indexed _from, uint256 _value);

    constructor(uint _totalSupply) public {
        totalSupply_ = _totalSupply;
        owner_ = msg.sender;
        // Assigns all tokens to the owner
        balances[owner_] = _totalSupply;
    }

    function totalSupply() public view returns (uint256) { 
        return totalSupply_; 
    }

    function balanceOf(address _target) public view returns (uint256) { 
        return balances[_target]; 
    }

    function addressThis() public view returns (address) { 
        return address(this); 
    }

    function mint(address _target, uint256 _amount) public {
        require(msg.sender == owner_);
        balances[_target] += _amount;
        totalSupply_ += _amount;
        emit Transfer(0, owner_, _amount);
        emit Transfer(owner_, _target, _amount);
    }

    function burn(uint256 _amount) public returns (bool success) {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] -= _amount;
        totalSupply_ -= _amount;
        emit Burn(msg.sender, _amount);
        return true;
    }

}