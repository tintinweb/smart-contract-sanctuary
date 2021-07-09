/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity ^0.4.17;

contract SimpleTokenNEO {
    string public name = 'NEO_Token';
    string public symbol = "NEO";
    uint8 public decimals = 18;
    uint256 totalSupply = 10;
    
    mapping(address => uint256) balances;
    event Tranfer(address indexed _from, address indexed _to, uint256 _value);
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    function tranfer(address _to, uint256 _value) public returns (bool) {
        balances[msg.sender] -= _value;
        balances[_to] +=  _value;
        return true;
    }
    
    
    function() public payable {
        balances[msg.sender] -= msg.value;
    }
}