/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

pragma solidity ^0.4.0;
interface ERC20 {
    // 方法
    function name() view returns (string name);
    function symbol() view returns (string symbol);
    function decimals() view returns (uint8 decimals);
    function totalSupply() view returns (uint256 totalSupply);
    function balanceOf(address _owner) view returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) view returns (uint256 remaining);
    // 事件
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract token is ERC20{
    mapping (address=>uint256)balanceof;
    mapping(address=>mapping(address=>uint))allow;
    function name() view returns (string name){
        return "wenqian";
    }
    function symbol() view returns (string symbol){
        return "wq";
    }
    function decimals() view returns (uint8 decimals){
        return 0;
    }
    function totalSupply() view returns (uint256 totalSupply){
        //  balanceOf[msg.sender]=1;
        return 1000000;
    }

   constructor (uint256 initialMoney)public{
        balanceof[msg.sender]=initialMoney;
    }
    function balanceOf(address _owner) view returns (uint256 balance){
        return balanceof[_owner];
    }
    function transfer(address _to, uint256 _value) returns (bool success){
        require(balanceof[msg.sender]>_value && balanceof[_to]+_value>=balanceof[_to] &&_to!=address(0));
        balanceof[msg.sender]-=_value;
        balanceof[_to]+=_value;
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
         require(balanceof[_from]>_value && balanceof[_to]+_value>=balanceof[_to] &&_to!=address(0));
         require(allow[_from][msg.sender]>_value);
        balanceof[_from]-=_value;
        balanceof[_to]+=_value;
        allow[_from][msg.sender]-=_value;
        emit Transfer(_from,_to,_value);
        return true;
    }
    function approve(address _spender, uint256 _value) returns (bool success){
        allow[msg.sender][_spender]=_value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    function allowance(address _owner, address _spender) view returns (uint256 remaining){
        return allow[_owner][_spender];
    }
    // 事件

}