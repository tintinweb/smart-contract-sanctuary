//SPDX-License-Identifier: MIT
pragma solidity ^0.6.9;

import "./EIP20Interface.sol";

//Based on https://github.com/ConsenSys/Tokens. 
contract CartelFinance is EIP20Interface {
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    string public name = "cartel.finance";
    uint8 public decimals = 4;
    string public symbol = "CFI";
    uint256 constant private MAX_UINT256 = 2**256 - 1;

    constructor() public {
        balances[tx.origin] = 500000000; 
        totalSupply = 500000000;
    }

    //Simple transfer
    function transfer(address _to, uint256 _value) override public  returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    //Get balance of address
    function balanceOf(address _owner) override public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function approve(address _spender, uint256 _value) override public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
 
    function allowance(address _owner, address _spender) override public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) {
        uint256 tokenAllowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && tokenAllowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (tokenAllowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
}
