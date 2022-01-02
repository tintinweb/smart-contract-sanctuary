/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

pragma solidity ^0.8.6;
// SPDX-License-Identifier: RB
contract RMBToken {
    string public name ;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    event Transfer(address indexed from , address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender , uint256 value);

    constructor(string memory _name, string memory _symbol , uint256 _decimals , uint256 _totalSupply)  {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[msg.sender] = totalSupply;
    }

    function approve(address _spender , uint256 _value) external returns(bool){
        require(_spender != address(0));
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        
        balances[_from] =  balances[_from] - _value;
        balances[_to] =  balances[_to] + _value; 
        emit Transfer(_from,_to,_value);

    }

    function transferFrom(address _from, address _to, uint256 _value) external returns(bool) {
        require(allowances[_from][msg.sender] >= _value);
        require(balances[_from] >= _value);
        allowances[_from][msg.sender] = allowances[_from][msg.sender] - _value;
        _transfer(_from,_to,_value);
        return true;
    }
}